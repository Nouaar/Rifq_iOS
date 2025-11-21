//
//  PetAIViewModel.swift
//  vet.tn
//
//  ViewModel for AI-powered pet tips, recommendations, and reminders
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PetAIViewModel: ObservableObject {
    @Published var tips: [String] = []
    @Published var recommendations: [String] = []
    @Published var reminders: [String] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Per-pet data for HomeView
    @Published var petTips: [String: [PetTip]] = [:] // petId -> tips
    @Published var petStatuses: [String: PetStatus] = [:] // petId -> status
    @Published var petReminders: [String: [PetReminder]] = [:] // petId -> reminders
    
    private let aiService = AIService.shared
    private let geminiService = GeminiService.shared // Keep as fallback
    weak var sessionManager: SessionManager?
    
    // MARK: - Generate Pet Tips
    
    func generateTips(for pet: Pet) async {
        isLoading = true
        error = nil
        
        let prompt = buildTipsPrompt(for: pet)
        
        do {
            let response = try await geminiService.generateText(prompt: prompt, temperature: 0.8, maxTokens: 500)
            tips = parseListResponse(response)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Error generating tips: \(error)")
        }
    }
    
    // MARK: - Generate Recommendations
    
    func generateRecommendations(for pet: Pet) async {
        isLoading = true
        error = nil
        
        let prompt = buildRecommendationsPrompt(for: pet)
        
        do {
            let response = try await geminiService.generateText(prompt: prompt, temperature: 0.7, maxTokens: 800)
            recommendations = parseListResponse(response)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Error generating recommendations: \(error)")
        }
    }
    
    // MARK: - Generate Reminders
    
    func generateReminders(for pet: Pet) async {
        isLoading = true
        error = nil
        
        let prompt = buildRemindersPrompt(for: pet)
        
        do {
            let response = try await geminiService.generateText(prompt: prompt, temperature: 0.6, maxTokens: 600)
            reminders = parseListResponse(response)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Error generating reminders: \(error)")
        }
    }
    
    // MARK: - Prompt Builders
    
    private func buildTipsPrompt(for pet: Pet) -> String {
        var prompt = """
        You are a veterinary assistant AI. Provide 3-5 daily care tips specifically for this pet:
        
        Pet Information:
        - Name: \(pet.name)
        - Species: \(pet.species)
        - Breed: \(pet.breed ?? "Unknown")
        - Age: \(pet.ageText)
        - Gender: \(pet.gender ?? "Unknown")
        """
        
        if let weight = pet.weight {
            prompt += "\n- Weight: \(String(format: "%.1f", weight)) kg"
        }
        
        if let medicalHistory = pet.medicalHistory {
            prompt += "\n\nMedical History:"
            
            if let vaccinations = medicalHistory.vaccinations, !vaccinations.isEmpty {
                prompt += "\n- Vaccinations: \(vaccinations.joined(separator: ", "))"
            }
            
            if let conditions = medicalHistory.chronicConditions, !conditions.isEmpty {
                prompt += "\n- Chronic Conditions: \(conditions.joined(separator: ", "))"
            }
            
            if let medications = medicalHistory.currentMedications, !medications.isEmpty {
                let medList = medications.map { "\($0.name) (\($0.dosage))" }.joined(separator: ", ")
                prompt += "\n- Current Medications: \(medList)"
            }
        }
        
        prompt += """
        
        Provide practical, actionable daily care tips based on this pet's specific needs. 
        Format as a numbered list (1., 2., 3., etc.). Keep each tip concise (1-2 sentences).
        Focus on health, nutrition, exercise, and general well-being.
        """
        
        return prompt
    }
    
    private func buildRecommendationsPrompt(for pet: Pet) -> String {
        var prompt = """
        You are a veterinary assistant AI. Provide personalized recommendations for this pet:
        
        Pet Information:
        - Name: \(pet.name)
        - Species: \(pet.species)
        - Breed: \(pet.breed ?? "Unknown")
        - Age: \(pet.ageText)
        """
        
        if let medicalHistory = pet.medicalHistory {
            prompt += "\n\nMedical History:"
            
            if let vaccinations = medicalHistory.vaccinations, !vaccinations.isEmpty {
                prompt += "\n- Vaccinations: \(vaccinations.joined(separator: ", "))"
            } else {
                prompt += "\n- Vaccinations: None recorded"
            }
            
            if let conditions = medicalHistory.chronicConditions, !conditions.isEmpty {
                prompt += "\n- Chronic Conditions: \(conditions.joined(separator: ", "))"
            }
            
            if let medications = medicalHistory.currentMedications, !medications.isEmpty {
                let medList = medications.map { "\($0.name) (\($0.dosage))" }.joined(separator: ", ")
                prompt += "\n- Current Medications: \(medList)"
            }
        }
        
        prompt += """
        
        Provide recommendations for:
        1. Next vaccination schedule (if applicable)
        2. Medication reminders and timing
        3. Health check-ups
        4. Preventive care measures
        
        Format as a numbered list. Be specific and actionable. If vaccinations are missing, recommend core vaccines.
        """
        
        return prompt
    }
    
    private func buildRemindersPrompt(for pet: Pet) -> String {
        var prompt = """
        You are a veterinary assistant AI. Generate personalized reminders for this pet:
        
        Pet Information:
        - Name: \(pet.name)
        - Species: \(pet.species)
        - Breed: \(pet.breed ?? "Unknown")
        - Age: \(pet.ageText)
        """
        
        if let medicalHistory = pet.medicalHistory {
            if let medications = medicalHistory.currentMedications, !medications.isEmpty {
                prompt += "\n\nCurrent Medications:"
                for med in medications {
                    prompt += "\n- \(med.name): \(med.dosage)"
                }
            }
            
            if let vaccinations = medicalHistory.vaccinations, !vaccinations.isEmpty {
                prompt += "\n\nVaccinations: \(vaccinations.joined(separator: ", "))"
            }
        }
        
        prompt += """
        
        Generate 3-5 specific reminders for:
        - Medication schedules (if applicable)
        - Vaccination due dates
        - Regular health checks
        - Preventive care tasks
        
        Format as a numbered list. Include specific times/frequencies when relevant.
        """
        
        return prompt
    }
    
    // MARK: - Response Parsing
    
    private func parseListResponse(_ response: String) -> [String] {
        // Parse numbered list (1., 2., 3. or 1), 2), 3) or -)
        let lines = response.components(separatedBy: .newlines)
        var items: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Match patterns like "1. ", "1) ", "- ", "• "
            if trimmed.range(of: #"^[\d]+[\.\)]\s+"#, options: .regularExpression) != nil ||
               trimmed.hasPrefix("- ") ||
               trimmed.hasPrefix("• ") {
                let cleaned = trimmed
                    .replacingOccurrences(of: #"^[\d]+[\.\)]\s+"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"^[-•]\s+"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleaned.isEmpty {
                    items.append(cleaned)
                }
            }
        }
        
        // If no numbered list found, try to extract meaningful sentences
        if items.isEmpty {
            // First try splitting by periods and filtering
            let sentences = response.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.count > 15 && !$0.lowercased().hasPrefix("here") && !$0.lowercased().hasPrefix("based") }
            
            if !sentences.isEmpty {
                items = Array(sentences.prefix(5))
            } else {
                // Last resort: use the whole response if it's reasonable
                let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count > 20 && cleaned.count < 500 {
                    items = [cleaned]
                } else {
                    // Split by newlines and filter
                    items = lines
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty && $0.count > 10 }
                }
            }
        }
        
        return items.isEmpty ? ["No recommendations available"] : items
    }
    
    // MARK: - HomeView Methods (with Calendar Integration)
    
    /// Generate tips for a pet with calendar context - returns formatted tip with pet name
    func generateHomeTips(for pet: Pet, calendarEvents: [PetCalendarEvent] = []) async -> PetTip? {
        print("💡 generateHomeTips called for \(pet.name)")
        isLoading = true
        error = nil
        
        // Try backend first, fallback to direct Gemini if no session
        if let session = sessionManager,
           let accessToken = session.tokens?.accessToken {
            do {
                print("🌐 Calling backend AI service for tip...")
                let response = try await aiService.getTips(petId: pet.id, accessToken: accessToken)
                print("✅ Received response from backend")
                
                if let firstTip = response.tips.first {
                    isLoading = false
                    let tip = PetTip(
                        id: UUID(),
                        emoji: firstTip.emoji,
                        title: firstTip.title,
                        detail: firstTip.detail
                    )
                    print("✅ Returning tip: \(tip.title)")
                    return tip
                }
                print("⚠️ No tips in backend response")
                isLoading = false
                return nil
            } catch {
                // Check if it's a timeout error - don't fallback, just return nil
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    print("⚠️ Backend AI call timed out (likely rate-limited). Please try again later.")
                    isLoading = false
                    return nil
                }
                
                // Check if it's a 401 Unauthorized error
                if let apiError = error as? APIClient.APIError,
                   case .http(let status, _) = apiError {
                    if status == 401 {
                        print("⚠️ Authentication failed (401), session may need refresh.")
                    } else if status == 503 {
                        print("⚠️ Backend AI service temporarily unavailable (rate-limited). Please try again later.")
                        isLoading = false
                        return nil
                    } else {
                        print("⚠️ Backend AI call failed with status \(status)")
                    }
                } else {
                    print("⚠️ Backend AI call failed: \(error)")
                }
                
                // Only fallback to direct Gemini if we have a valid API key
                // Check if we should try direct Gemini (only if not a timeout or 503)
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    // Don't fallback on timeout
                    isLoading = false
                    return nil
                }
            }
        } else {
            print("⚠️ No session or access token available")
            isLoading = false
            return nil
        }
        
        // Fallback to direct Gemini API (only if backend failed and it's not a timeout)
        let prompt = buildHomeTipsPrompt(for: pet, calendarEvents: calendarEvents)
        print("📝 Tip prompt built (\(prompt.count) chars)")
        
        do {
            print("🌐 Calling Gemini API directly for tip...")
            let response = try await geminiService.generateText(prompt: prompt, temperature: 0.8, maxTokens: 800)
            print("✅ Received response: \(response.prefix(100))...")
            let tips = parseListResponse(response)
            print("📋 Parsed \(tips.count) tips")
            
            if let firstTip = tips.first {
                isLoading = false
                let tip = PetTip(
                    id: UUID(),
                    emoji: getEmojiForPet(pet),
                    title: "Tips about \(pet.name)",
                    detail: firstTip
                )
                print("✅ Returning tip: \(tip.title)")
                return tip
            }
            print("⚠️ No tips parsed from response")
            isLoading = false
            return nil
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Error generating home tips for \(pet.name): \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Generate status for a pet based on medical history and calendar
    func generatePetStatus(for pet: Pet, calendarEvents: [PetCalendarEvent] = []) async -> PetStatus {
        print("📊 generatePetStatus called for \(pet.name)")
        isLoading = true
        error = nil
        
        // Try backend first, fallback to direct Gemini if no session
        if let session = sessionManager,
           let accessToken = session.tokens?.accessToken {
            do {
                print("🌐 Calling backend AI service for status...")
                let response = try await aiService.getStatus(petId: pet.id, accessToken: accessToken)
                print("✅ Received status response from backend:")
                print("   Status: \(response.status)")
                print("   Summary: \(response.summary)")
                print("   Pills: \(response.pills.map { $0.text }.joined(separator: ", "))")
                
                isLoading = false
                
                // Convert backend response to PetStatus
                var pills = response.pills.map { pill in
                    StatusPillData(
                        text: pill.text,
                        bg: Color(hex: pill.bg) ?? Color.green.opacity(0.12),
                        fg: Color(hex: pill.fg) ?? Color.green.darker()
                    )
                }
                
                // Add "Due Soon" pill if there are upcoming calendar events for THIS pet
                let upcomingEvents = calendarEvents.filter { 
                    $0.date >= Date() && 
                    $0.date <= Date().addingTimeInterval(86400 * 7) 
                }
                if !upcomingEvents.isEmpty {
                    // Check if "Due Soon" already exists in pills
                    let hasDueSoon = pills.contains { $0.text == "Due Soon" }
                    if !hasDueSoon {
                        pills.append(StatusPillData(
                            text: "Due Soon",
                            bg: Color.vetCanyon.opacity(0.14),
                            fg: Color.vetCanyon
                        ))
                        print("  📅 Added 'Due Soon' pill for \(pet.name) (\(upcomingEvents.count) upcoming events)")
                    }
                } else {
                    print("  📅 No upcoming events for \(pet.name) - not adding 'Due Soon' pill")
                }
                
                print("✅ Generated status: \(response.status) with \(pills.count) pills")
                return PetStatus(
                    status: response.status,
                    pills: pills,
                    summary: response.summary
                )
            } catch {
                print("⚠️ Backend AI call failed, falling back to direct Gemini: \(error)")
                // Fall through to direct Gemini call
            }
        }
        
        // Fallback to direct Gemini API
        let prompt = buildStatusPrompt(for: pet, calendarEvents: calendarEvents)
        print("📝 Status prompt built (\(prompt.count) chars)")
        
        do {
            print("🌐 Calling Gemini API directly for status...")
            let response = try await geminiService.generateText(prompt: prompt, temperature: 0.6, maxTokens: 400)
            print("✅ Received status response: \(response)")
            let statusText = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            isLoading = false
            
            // Parse status (should be short like "Healthy", "Needs Attention", "Due for Checkup")
            let status = parseStatus(statusText)
            var pills = generateStatusPills(for: pet, calendarEvents: calendarEvents, status: status)
            
            // Ensure "Due Soon" only shows if there are actual upcoming events
            let upcomingEvents = calendarEvents.filter { 
                $0.date >= Date() && 
                $0.date <= Date().addingTimeInterval(86400 * 7) 
            }
            if upcomingEvents.isEmpty {
                // Remove "Due Soon" if it was added but there are no events
                pills = pills.filter { $0.text != "Due Soon" }
            }
            
            print("✅ Generated status: \(status) with \(pills.count) pills")
            return PetStatus(
                status: status,
                pills: pills,
                summary: generateStatusSummary(for: pet, calendarEvents: calendarEvents)
            )
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Error generating status for \(pet.name): \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return PetStatus(status: "Healthy", pills: [], summary: "All good")
        }
    }
    
    /// Generate reminders for a pet based on calendar and medical history
    func generateHomeReminders(for pet: Pet, calendarEvents: [PetCalendarEvent] = []) async -> [PetReminder] {
        print("🔔 generateHomeReminders called for \(pet.name)")
        isLoading = true
        error = nil
        
        // Try backend first, fallback to direct Gemini if no session
        if let session = sessionManager,
           let accessToken = session.tokens?.accessToken {
            do {
                print("🌐 Calling backend AI service for reminders...")
                let response = try await aiService.getReminders(petId: pet.id, accessToken: accessToken)
                print("✅ Received reminders response from backend")
                
                print("📋 Backend returned \(response.reminders.count) reminders")
                
                // Convert backend reminders to PetReminder
                let reminders = response.reminders.map { reminder in
                    let dateFormatter = ISO8601DateFormatter()
                    let date = dateFormatter.date(from: reminder.date) ?? Date()
                    
                    print("   - Reminder: \(reminder.title) - \(reminder.detail.prefix(50))")
                    
                    return PetReminder(
                        id: UUID(),
                        icon: reminder.icon,
                        title: reminder.title,
                        detail: reminder.detail,
                        date: date,
                        tint: Color(hex: reminder.tint) ?? Color.purple
                    )
                }
                
                // Merge with calendar events
                let calendarReminders = calendarEvents
                    .filter { $0.date >= Date() }
                    .sorted { $0.date < $1.date }
                    .prefix(3)
                    .map { event in
                        PetReminder(
                            id: UUID(),
                            icon: event.type.icon,
                            title: "\(pet.name) • \(event.title)",
                            detail: event.type.displayName,
                            date: event.date,
                            tint: getColorForEventType(event.type)
                        )
                    }
                
                let allReminders = (reminders + calendarReminders).sorted { $0.date < $1.date }
                
                print("✅ Parsed \(allReminders.count) total reminders (\(reminders.count) AI + \(calendarReminders.count) calendar)")
                isLoading = false
                return allReminders
            } catch {
                print("⚠️ Backend AI call failed, falling back to direct Gemini: \(error)")
                // Fall through to direct Gemini call
            }
        }
        
        // Fallback to direct Gemini API
        let prompt = buildHomeRemindersPrompt(for: pet, calendarEvents: calendarEvents)
        print("📝 Reminders prompt built (\(prompt.count) chars)")
        
        do {
            print("🌐 Calling Gemini API directly for reminders...")
            let response = try await geminiService.generateText(prompt: prompt, temperature: 0.7, maxTokens: 800)
            print("✅ Received reminders response: \(response.prefix(200))...")
            let reminders = parseRemindersResponse(response, pet: pet, calendarEvents: calendarEvents)
            print("✅ Parsed \(reminders.count) reminders")
            
            isLoading = false
            return reminders
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Error generating reminders for \(pet.name): \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - HomeView Prompt Builders
    
    private func buildHomeTipsPrompt(for pet: Pet, calendarEvents: [PetCalendarEvent]) -> String {
        var prompt = """
        You are a veterinary assistant AI. Provide ONE concise, actionable daily care tip for \(pet.name):
        
        Pet Information:
        - Name: \(pet.name)
        - Species: \(pet.species)
        - Breed: \(pet.breed ?? "Unknown")
        - Age: \(pet.ageText)
        """
        
        if let weight = pet.weight {
            prompt += "\n- Weight: \(String(format: "%.1f", weight)) kg"
        }
        
        if let medicalHistory = pet.medicalHistory {
            prompt += "\n\nMedical History:"
            
            if let vaccinations = medicalHistory.vaccinations, !vaccinations.isEmpty {
                prompt += "\n- Vaccinations: \(vaccinations.joined(separator: ", "))"
            }
            
            if let conditions = medicalHistory.chronicConditions, !conditions.isEmpty {
                prompt += "\n- Chronic Conditions: \(conditions.joined(separator: ", "))"
            }
            
            if let medications = medicalHistory.currentMedications, !medications.isEmpty {
                let medList = medications.map { "\($0.name) (\($0.dosage))" }.joined(separator: ", ")
                prompt += "\n- Current Medications: \(medList)"
            }
        }
        
        if !calendarEvents.isEmpty {
            prompt += "\n\nUpcoming Calendar Events:"
            let upcoming = calendarEvents.filter { $0.date >= Date() }.prefix(3)
            for event in upcoming {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                prompt += "\n- \(event.type.displayName): \(event.title) on \(formatter.string(from: event.date))"
            }
        }
        
        prompt += """
        
        Provide ONE practical, actionable tip (1-2 sentences max) based on \(pet.name)'s current needs, upcoming events, and health status.
        Make it specific and helpful. Do not include the pet's name in the tip text itself.
        """
        
        return prompt
    }
    
    private func buildStatusPrompt(for pet: Pet, calendarEvents: [PetCalendarEvent]) -> String {
        var prompt = """
        Analyze the health status of \(pet.name) and provide a brief status:
        
        Pet Information:
        - Name: \(pet.name)
        - Species: \(pet.species)
        - Breed: \(pet.breed ?? "Unknown")
        - Age: \(pet.ageText)
        """
        
        if let medicalHistory = pet.medicalHistory {
            if let vaccinations = medicalHistory.vaccinations, !vaccinations.isEmpty {
                prompt += "\n- Vaccinations: \(vaccinations.joined(separator: ", "))"
            } else {
                prompt += "\n- Vaccinations: None recorded (may need core vaccines)"
            }
            
            if let conditions = medicalHistory.chronicConditions, !conditions.isEmpty {
                prompt += "\n- Chronic Conditions: \(conditions.joined(separator: ", "))"
            }
            
            if let medications = medicalHistory.currentMedications, !medications.isEmpty {
                let medList = medications.map { "\($0.name) (\($0.dosage))" }.joined(separator: ", ")
                prompt += "\n- Current Medications: \(medList)"
            }
        }
        
        if !calendarEvents.isEmpty {
            let upcoming = calendarEvents.filter { $0.date >= Date() }.sorted { $0.date < $1.date }
            if !upcoming.isEmpty {
                prompt += "\n\nUpcoming Events:"
                for event in upcoming.prefix(3) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    prompt += "\n- \(event.type.displayName): \(event.title) on \(formatter.string(from: event.date))"
                }
            }
        }
        
        prompt += """
        
        Provide a brief health status (one word or short phrase): "Healthy", "Needs Attention", "Due for Checkup", "On Medication", etc.
        Only return the status word/phrase, nothing else.
        """
        
        return prompt
    }
    
    private func buildHomeRemindersPrompt(for pet: Pet, calendarEvents: [PetCalendarEvent]) -> String {
        var prompt = """
        Generate personalized reminders for \(pet.name):
        
        Pet Information:
        - Name: \(pet.name)
        - Species: \(pet.species)
        - Age: \(pet.ageText)
        """
        
        if let medicalHistory = pet.medicalHistory {
            if let medications = medicalHistory.currentMedications, !medications.isEmpty {
                prompt += "\n\nCurrent Medications:"
                for med in medications {
                    prompt += "\n- \(med.name): \(med.dosage)"
                }
            }
            
            if let vaccinations = medicalHistory.vaccinations, !vaccinations.isEmpty {
                prompt += "\n\nVaccinations: \(vaccinations.joined(separator: ", "))"
            } else {
                prompt += "\n\nVaccinations: None recorded"
            }
        }
        
        if !calendarEvents.isEmpty {
            let upcoming = calendarEvents.filter { $0.date >= Date() }.sorted { $0.date < $1.date }
            if !upcoming.isEmpty {
                prompt += "\n\nUpcoming Calendar Events:"
                for event in upcoming.prefix(5) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, h:mm a"
                    prompt += "\n- \(event.type.displayName): \(event.title) on \(formatter.string(from: event.date))"
                }
            }
        }
        
        prompt += """
        
        Generate 2-3 specific, actionable reminders for \(pet.name). Include:
        - Medication schedules (if applicable)
        - Upcoming calendar events
        - Vaccination needs
        - Health check recommendations
        
        Format as a numbered list. Be specific with dates/times when available.
        """
        
        return prompt
    }
    
    // MARK: - Helper Methods
    
    private func getEmojiForPet(_ pet: Pet) -> String {
        switch pet.species.lowercased() {
        case "dog": return "🐕"
        case "cat": return "🐈"
        case "bird": return "🐦"
        default: return "🐾"
        }
    }
    
    private func parseStatus(_ response: String) -> String {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        // Extract first meaningful word/phrase
        let words = cleaned.components(separatedBy: .whitespaces)
        if words.count <= 3 {
            return cleaned
        }
        return words.prefix(3).joined(separator: " ")
    }
    
    private func generateStatusPills(for pet: Pet, calendarEvents: [PetCalendarEvent], status: String) -> [StatusPillData] {
        var pills: [StatusPillData] = []
        
        // Health status pill
        if status.lowercased().contains("healthy") {
            pills.append(StatusPillData(text: "Healthy", bg: Color.green.opacity(0.12), fg: Color.green.darker()))
        } else if status.lowercased().contains("attention") || status.lowercased().contains("checkup") {
            pills.append(StatusPillData(text: "Needs Attention", bg: Color.orange.opacity(0.12), fg: Color.orange.darker()))
        } else {
            pills.append(StatusPillData(text: status, bg: Color.vetCanyon.opacity(0.14), fg: Color.vetCanyon))
        }
        
        // Check for upcoming events
        let upcomingEvents = calendarEvents.filter { $0.date >= Date() && $0.date <= Date().addingTimeInterval(86400 * 7) }
        if !upcomingEvents.isEmpty {
            pills.append(StatusPillData(text: "Due Soon", bg: Color.vetCanyon.opacity(0.14), fg: Color.vetCanyon))
        }
        
        return pills
    }
    
    private func generateStatusSummary(for pet: Pet, calendarEvents: [PetCalendarEvent]) -> String {
        var parts: [String] = []
        
        // Vaccination status
        if let vaccinations = pet.medicalHistory?.vaccinations, !vaccinations.isEmpty {
            parts.append("✓ Up-to-date")
        } else {
            parts.append("⚠ Needs vaccines")
        }
        
        // Medication count
        let medCount = pet.medsCount
        if medCount > 0 {
            parts.append("\(medCount) med")
        }
        
        // Weight
        parts.append(pet.weightText)
        
        return parts.joined(separator: " | ")
    }
    
    private func parseRemindersResponse(_ response: String, pet: Pet, calendarEvents: [PetCalendarEvent]) -> [PetReminder] {
        let lines = response.components(separatedBy: .newlines)
        var reminders: [PetReminder] = []
        
        // First, add actual calendar events as reminders
        let upcomingEvents = calendarEvents
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
            .prefix(3)
        
        for event in upcomingEvents {
            reminders.append(PetReminder(
                id: UUID(),
                icon: event.type.icon,
                title: "\(pet.name) • \(event.title)",
                detail: event.type.displayName,
                date: event.date,
                tint: getColorForEventType(event.type)
            ))
        }
        
        // Then parse AI-generated reminders
        var reminderIndex = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.range(of: #"^[\d]+[\.\)]\s+"#, options: .regularExpression) != nil ||
               trimmed.hasPrefix("- ") ||
               trimmed.hasPrefix("• ") {
                let cleaned = trimmed
                    .replacingOccurrences(of: #"^[\d]+[\.\)]\s+"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"^[-•]\s+"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleaned.isEmpty && reminderIndex < 3 {
                    // Try to extract date from reminder text
                    let date = extractDateFromText(cleaned) ?? Date().addingTimeInterval(86400 * Double(reminderIndex + 2))
                    
                    reminders.append(PetReminder(
                        id: UUID(),
                        icon: getIconForReminder(cleaned),
                        title: "\(pet.name) • \(getReminderTitle(cleaned))",
                        detail: cleaned,
                        date: date,
                        tint: getTintForReminder(cleaned)
                    ))
                    reminderIndex += 1
                }
            }
        }
        
        return reminders.sorted { $0.date < $1.date }
    }
    
    private func extractDateFromText(_ text: String) -> Date? {
        // Simple date extraction - can be improved
        let calendar = Calendar.current
        let now = Date()
        
        if text.lowercased().contains("today") {
            return now
        } else if text.lowercased().contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        } else if text.lowercased().contains("week") {
            return calendar.date(byAdding: .day, value: 7, to: now)
        }
        
        return nil
    }
    
    private func getIconForReminder(_ text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("vaccin") {
            return "syringe.fill"
        } else if lower.contains("medic") || lower.contains("pill") {
            return "pills.fill"
        } else if lower.contains("appointment") || lower.contains("check") {
            return "calendar.badge.clock"
        } else if lower.contains("groom") {
            return "scissors"
        }
        return "bell.fill"
    }
    
    private func getReminderTitle(_ text: String) -> String {
        // Extract key phrase from reminder
        let words = text.components(separatedBy: .whitespaces)
        if words.count > 5 {
            return words.prefix(4).joined(separator: " ")
        }
        return text
    }
    
    private func getTintForReminder(_ text: String) -> Color {
        let lower = text.lowercased()
        if lower.contains("vaccin") {
            return .green
        } else if lower.contains("medic") || lower.contains("pill") {
            return .blue
        } else if lower.contains("appointment") {
            return .vetCanyon
        }
        return .purple
    }
    
    private func getColorForEventType(_ type: CalendarEventType) -> Color {
        switch type {
        case .medication: return .blue
        case .vaccination: return .green
        case .appointment: return .vetCanyon
        case .reminder: return .purple
        }
    }
}

// MARK: - HomeView Models

struct PetTip: Identifiable {
    let id: UUID
    let emoji: String
    let title: String
    let detail: String
}

struct PetStatus {
    let status: String
    let pills: [StatusPillData]
    let summary: String
}

struct StatusPillData {
    let text: String
    let bg: Color
    let fg: Color
}

struct PetReminder: Identifiable {
    let id: UUID
    let icon: String
    let title: String
    let detail: String
    let date: Date
    let tint: Color
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: date)
    }
}

