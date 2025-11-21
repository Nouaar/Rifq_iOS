//
//  GeminiService.swift
//  vet.tn
//
//  Google Gemini AI Service for pet-specific tips, recommendations, and reminders
//

import Foundation

// MARK: - Gemini API Models

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig?
    
    struct GeminiContent: Encodable {
        let parts: [GeminiPart]
    }
    
    struct GeminiPart: Encodable {
        let text: String
    }
    
    struct GenerationConfig: Encodable {
        let temperature: Double?
        let topK: Int?
        let topP: Double?
        let maxOutputTokens: Int?
    }
}

struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    
    struct Candidate: Decodable {
        let content: Content?
        let finishReason: String?
        
        struct Content: Decodable {
            let parts: [Part]?
            
            struct Part: Decodable {
                let text: String?
            }
        }
    }
    
    var text: String? {
        candidates?.first?.content?.parts?.first?.text
    }
}

// MARK: - Gemini Service

final class GeminiService {
    static let shared = GeminiService()
    
    // Get your API key from: https://makersuite.google.com/app/apikey
    // Add it to Info.plist as "GEMINI_API_KEY"
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !key.isEmpty else {
            print("❌ GEMINI_API_KEY not found in Info.plist")
            print("📋 Available keys in Info.plist:")
            if let infoDict = Bundle.main.infoDictionary {
                for (key, _) in infoDict {
                    print("   - \(key)")
                }
            }
            #if DEBUG
            fatalError("GEMINI_API_KEY not found in Info.plist. Get your key from https://makersuite.google.com/app/apikey")
            #else
            return ""
            #endif
        }
        print("✅ Gemini API key loaded (length: \(key.count))")
        return key
    }
    
    private var cachedModelName: String?
    private let session: URLSession
    
    // Rate limiting: Free tier allows 2 requests per minute per model
    private var lastAPICallTimes: [Date] = []
    private let rateLimitLock = NSLock()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Rate Limiting
    
    private func waitForRateLimit() async {
        rateLimitLock.lock()
        defer { rateLimitLock.unlock() }
        
        let now = Date()
        // Keep only calls from the last minute
        lastAPICallTimes = lastAPICallTimes.filter { now.timeIntervalSince($0) < 60.0 }
        
        // If we've made 2 calls in the last minute, wait
        if lastAPICallTimes.count >= 2 {
            let timeSinceOldest = now.timeIntervalSince(lastAPICallTimes.first!)
            let waitTime = max(35.0, 60.0 - timeSinceOldest + 2.0) // Minimum 35 seconds, add 2 second buffer
            print("⏳ Rate limiter: Waiting \(Int(waitTime)) seconds before API call...")
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            // Update timestamps after waiting
            let afterWait = Date()
            lastAPICallTimes.removeAll { afterWait.timeIntervalSince($0) >= 60.0 }
        } else if lastAPICallTimes.count == 1 {
            // Ensure at least 35 seconds between calls
            let timeSinceLast = now.timeIntervalSince(lastAPICallTimes.last!)
            if timeSinceLast < 35.0 {
                let waitTime = 35.0 - timeSinceLast
                print("⏳ Rate limiter: Ensuring minimum delay: Waiting \(Int(waitTime)) seconds...")
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        
        // Record this API call
        lastAPICallTimes.append(Date())
        // Keep only last 2
        if lastAPICallTimes.count > 2 {
            lastAPICallTimes.removeFirst()
        }
    }
    
    // MARK: - List Available Models
    
    private func getAvailableModel() async throws -> String {
        // Return cached model if available
        if let cached = cachedModelName {
            return cached
        }
        
        print("🔍 Discovering available Gemini models...")
        
        let listURLString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        guard let listURL = URL(string: listURLString) else {
            throw GeminiError.invalidURL
        }
        
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        
        do {
            let (data, response) = try await session.data(for: listRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("⚠️ Failed to list models, using fallback")
                // Fallback to common model names
                let fallbackModels = ["gemini-pro", "models/gemini-pro", "gemini-1.5-pro", "models/gemini-1.5-pro"]
                for model in fallbackModels {
                    if await testModel(model) {
                        cachedModelName = model
                        return model
                    }
                }
                throw GeminiError.apiError("Could not discover available models")
            }
            
            // Parse models list
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                print("📋 Found \(models.count) available models")
                
                // Look for models that support generateContent
                let preferredNames = ["gemini-pro", "gemini-1.5-pro", "gemini-1.5-flash", "gemini-1.0-pro"]
                for preferredName in preferredNames {
                    if let model = models.first(where: { 
                        let name = ($0["name"] as? String) ?? ""
                        return name.contains(preferredName) || name.contains(preferredName.replacingOccurrences(of: "-", with: "_"))
                    }) {
                        if let name = model["name"] as? String {
                            // Extract just the model name part (e.g., "models/gemini-pro" -> "gemini-pro")
                            let modelName = name.components(separatedBy: "/").last ?? name
                            print("✅ Using model: \(modelName)")
                            cachedModelName = modelName
                            return modelName
                        }
                    }
                }
                
                // Use first available model
                if let firstModel = models.first,
                   let name = firstModel["name"] as? String {
                    let modelName = name.components(separatedBy: "/").last ?? name
                    print("✅ Using first available model: \(modelName)")
                    cachedModelName = modelName
                    return modelName
                }
            }
            
            // Fallback
            print("⚠️ Could not parse models list, using fallback")
            cachedModelName = "gemini-pro"
            return "gemini-pro"
        } catch {
            print("⚠️ Error listing models: \(error.localizedDescription)")
            cachedModelName = "gemini-pro"
            return "gemini-pro"
        }
    }
    
    private func testModel(_ modelName: String) async -> Bool {
        let testURLString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let testURL = URL(string: testURLString) else { return false }
        
        let testRequest = GeminiRequest(
            contents: [GeminiRequest.GeminiContent(
                parts: [GeminiRequest.GeminiPart(text: "test")]
            )],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.7,
                topK: nil,
                topP: nil,
                maxOutputTokens: 10
            )
        )
        
        var urlRequest = URLRequest(url: testURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(testRequest)
        
        do {
            let (_, response) = try await session.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
        } catch {
            return false
        }
        return false
    }
    
    // MARK: - Generate Text
    
    func generateText(prompt: String, temperature: Double = 0.7, maxTokens: Int = 1000, maxRetries: Int = 3) async throws -> String {
        guard !apiKey.isEmpty else {
            print("❌ Gemini API key is missing")
            throw GeminiError.apiKeyMissing
        }
        
        print("🌐 Calling Gemini API...")
        print("📝 Prompt length: \(prompt.count) characters")
        
        // Get available model
        let modelName = try await getAvailableModel()
        let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
        let urlString = "\(baseURL)?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid Gemini API URL: \(urlString)")
            throw GeminiError.invalidURL
        }
        
        print("🌐 Using model: \(modelName)")
        
        // Retry logic with exponential backoff
        var lastError: Error?
        var currentMaxTokens = maxTokens // Mutable token limit for retries
        
        for attempt in 0..<maxRetries {
            // Wait for rate limit before each attempt (including first)
            await waitForRateLimit()
            
            if attempt > 0 {
                // Additional delay for retries (beyond rate limit wait)
                let delay = min(Double(attempt) * 2.0, 10.0) // Small additional delay, max 10 seconds
                if delay > 0 {
                    print("⏳ Additional retry delay: \(delay) seconds (attempt \(attempt + 1)/\(maxRetries))...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
            
            // Create request with current token limit
            let request = GeminiRequest(
                contents: [GeminiRequest.GeminiContent(
                    parts: [GeminiRequest.GeminiPart(text: prompt)]
                )],
                generationConfig: GeminiRequest.GenerationConfig(
                    temperature: temperature,
                    topK: nil,
                    topP: nil,
                    maxOutputTokens: currentMaxTokens
                )
            )
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = GeminiError.invalidResponse
                continue
            }
            
            // Success case
            if (200...299).contains(httpResponse.statusCode) {
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                // Check for MAX_TOKENS finish reason
                if let finishReason = geminiResponse.candidates?.first?.finishReason,
                   finishReason == "MAX_TOKENS" {
                    print("⚠️ Response hit MAX_TOKENS limit (current limit: \(currentMaxTokens))")
                    // If we have partial text, use it; otherwise retry with higher limit
                    if let partialText = geminiResponse.text, !partialText.isEmpty {
                        print("✅ Using partial response (\(partialText.count) characters)")
                        return partialText
                    } else if attempt < maxRetries - 1 {
                        // Retry with higher token limit
                        currentMaxTokens = currentMaxTokens * 2
                        print("🔄 Retrying with increased token limit: \(currentMaxTokens)")
                        continue
                    }
                }
                
                guard let text = geminiResponse.text, !text.isEmpty else {
                    print("⚠️ Gemini returned empty response")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Full response: \(responseString)")
                    }
                    throw GeminiError.emptyResponse
                }
                
                print("✅ Gemini API response received (\(text.count) characters)")
                return text
            }
            
            // Error case - parse error details
            print("❌ Gemini API HTTP error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            
            // Parse error message from JSON response
            var errorMessage: String?
            var retryDelay: Double?
            
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any] {
                errorMessage = error["message"] as? String
                
                // Extract retry delay from error details (for 429 rate limit errors)
                if httpResponse.statusCode == 429,
                   let details = error["details"] as? [[String: Any]] {
                    for detail in details {
                        if let retryInfo = detail["@type"] as? String,
                           retryInfo.contains("RetryInfo"),
                           let retryDelayString = detail["retryDelay"] as? String {
                            // Parse "5s" or "5.126990018s" format
                            let delayString = retryDelayString.replacingOccurrences(of: "s", with: "")
                            if let delay = Double(delayString) {
                                retryDelay = delay
                                print("⏰ API suggests retry after \(delay) seconds")
                            }
                        }
                    }
                }
            }
            
            // Handle rate limiting (429) with suggested retry delay
            if httpResponse.statusCode == 429 {
                // Use API suggestion, but ensure minimum delay
                let suggestedDelay = retryDelay ?? 30.0
                let delay = max(suggestedDelay, 30.0) // Minimum 30 seconds for rate limit errors
                print("⏳ Rate limit exceeded. Waiting \(delay) seconds before retry...")
                
                if attempt < maxRetries - 1 {
                    // Wait for the suggested delay
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    // Clear recent call times since we've waited
                    rateLimitLock.lock()
                    lastAPICallTimes.removeAll()
                    rateLimitLock.unlock()
                    continue // Retry (will wait for rate limit again in next iteration)
                } else {
                    lastError = GeminiError.apiError(errorMessage ?? "Rate limit exceeded. Please try again later.")
                    break
                }
            }
            
            // For other errors, throw immediately or retry based on error type
            if let message = errorMessage {
                lastError = GeminiError.apiError(message)
            } else {
                lastError = GeminiError.httpError(httpResponse.statusCode)
            }
            
            // Don't retry on client errors (4xx) except 429
            if httpResponse.statusCode >= 400 && httpResponse.statusCode < 500 && httpResponse.statusCode != 429 {
                break
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? GeminiError.apiError("Failed to generate text after \(maxRetries) attempts")
    }
}

// MARK: - Gemini Errors

enum GeminiError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Gemini API key is missing. Please add GEMINI_API_KEY to Info.plist"
        case .invalidURL:
            return "Invalid Gemini API URL"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "Gemini API error: \(message)"
        case .emptyResponse:
            return "Empty response from Gemini API"
        }
    }
}

