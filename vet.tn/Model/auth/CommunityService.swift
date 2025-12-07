//
//  CommunityService.swift
//  vet.tn
//
//  Community/Posts API service

import Foundation

final class CommunityService {
    static let shared = CommunityService()
    
    private let api = APIClient.auth
    
    private init() {}
    
    // MARK: - Get Posts Feed
    
    func getPosts(limit: Int = 20, offset: Int = 0, accessToken: String) async throws -> PostsResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        var path = "/community/posts"
        var queryItems: [String] = []
        
        // Backend uses page/limit, not offset
        let page = (offset / limit) + 1
        queryItems.append("page=\(page)")
        queryItems.append("limit=\(limit)")
        
        if !queryItems.isEmpty {
            path += "?" + queryItems.joined(separator: "&")
        }
        
        return try await api.request(
            "GET",
            path: path,
            headers: headers,
            responseType: PostsResponse.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Get My Posts
    
    func getMyPosts(page: Int = 1, limit: Int = 20, accessToken: String) async throws -> PostsResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        var path = "/community/my-posts"
        var queryItems: [String] = []
        
        if page != 1 {
            queryItems.append("page=\(page)")
        }
        if limit != 20 {
            queryItems.append("limit=\(limit)")
        }
        
        if !queryItems.isEmpty {
            path += "?" + queryItems.joined(separator: "&")
        }
        
        return try await api.request(
            "GET",
            path: path,
            headers: headers,
            responseType: PostsResponse.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Create Post
    
    func createPost(imageData: Data, caption: String?, accessToken: String) async throws -> CommunityPost {
        // Backend expects multipart/form-data with file field "petImage"
        func url(from key: String) -> URL? {
            guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
                  let url = URL(string: raw) else { return nil }
            return url
        }
        
        let base = url(from: "AUTH_BASE_URL") ?? url(from: "API_BASE_URL")
        guard var url = base else {
            throw NSError(domain: "CommunityService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing AUTH_BASE_URL/API_BASE_URL in Info.plist"])
        }
        url.append(path: "/community/posts")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Create multipart/form-data body
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add caption field if provided
        if let caption = caption, !caption.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(caption)\r\n".data(using: .utf8)!)
        }
        
        // Add image file field (backend expects field name "petImage")
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"petImage\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        #if DEBUG
        print("➡️ POST \(url.absoluteString)")
        print("   Multipart body size: \(body.count) bytes")
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "CommunityService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        #if DEBUG
        print("⬅️ \(httpResponse.statusCode) \(url.absoluteString)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Resp: \(responseString.prefix(500))")
        }
        #endif
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "CommunityService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Backend returns { message: "...", post: {...} }
        // We need to extract the post from the response
        struct CreatePostResponse: Codable {
            let message: String?
            let post: CommunityPost
        }
        
        let responseObj = try JSONDecoder().decode(CreatePostResponse.self, from: data)
        return responseObj.post
    }
    
    // MARK: - React to Post (Like/Unlike)
    
    func reactToPost(postId: String, reactionType: String, accessToken: String) async throws -> CommunityPost {
        // Backend uses /posts/:postId/react with body { reactionType: "like" | "love" | "haha" | "angry" | "cry" }
        struct ReactRequest: Codable {
            let reactionType: String
        }
        
        let request = ReactRequest(reactionType: reactionType)
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        // Backend returns { message: "...", post: {...} }
        struct ReactResponse: Codable {
            let message: String?
            let post: CommunityPost
        }
        
        let response = try await api.request(
            "POST",
            path: "/community/posts/\(postId)/react",
            headers: headers,
            body: request,
            responseType: ReactResponse.self,
            timeout: 30,
            retries: 1
        )
        
        return response.post
    }
    
    func removeReaction(postId: String, reactionType: String, accessToken: String) async throws -> CommunityPost {
        // Backend uses DELETE /posts/:postId/react?reactionType=...
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        struct RemoveReactionResponse: Codable {
            let message: String?
            let post: CommunityPost
        }
        
        let response = try await api.request(
            "DELETE",
            path: "/community/posts/\(postId)/react?reactionType=\(reactionType)",
            headers: headers,
            responseType: RemoveReactionResponse.self,
            timeout: 30,
            retries: 1
        )
        
        return response.post
    }
    
    // MARK: - Get Post Comments
    
    func getComments(postId: String, page: Int = 1, limit: Int = 50, accessToken: String) async throws -> CommentsResponse {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        var path = "/community/posts/\(postId)/comments"
        
        var queryItems: [String] = []
        if page != 1 {
            queryItems.append("page=\(page)")
        }
        if limit != 50 {
            queryItems.append("limit=\(limit)")
        }
        
        if !queryItems.isEmpty {
            path += "?" + queryItems.joined(separator: "&")
        }
        
        // Backend returns { comments: [...], total: number, page: number, totalPages: number }
        struct BackendCommentsResponse: Codable {
            let comments: [PostComment]
            let total: Int
            let page: Int
            let totalPages: Int
        }
        
        let response = try await api.request(
            "GET",
            path: path,
            headers: headers,
            responseType: BackendCommentsResponse.self,
            timeout: 30,
            retries: 1
        )
        
        // Convert to our CommentsResponse format
        return CommentsResponse(comments: response.comments, total: response.total)
    }
    
    // MARK: - Create Comment
    
    func createComment(postId: String, request: CreateCommentRequest, accessToken: String) async throws -> PostComment {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        // Backend returns { message: "...", comment: {...} }
        struct CreateCommentResponse: Codable {
            let message: String?
            let comment: PostComment
        }
        
        let response = try await api.request(
            "POST",
            path: "/community/posts/\(postId)/comments",
            headers: headers,
            body: request,
            responseType: CreateCommentResponse.self,
            timeout: 30,
            retries: 1
        )
        
        return response.comment
    }
    
    // MARK: - Delete Comment
    
    func deleteComment(postId: String, commentId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        _ = try await api.request(
            "DELETE",
            path: "/community/posts/\(postId)/comments/\(commentId)",
            headers: headers,
            responseType: EmptyResponse.self,
            timeout: 30,
            retries: 1
        )
    }
    
    // MARK: - Update Post (owner only)
    
    func updatePost(postId: String, caption: String?, accessToken: String) async throws -> CommunityPost {
        struct UpdatePostRequest: Codable {
            let caption: String?
        }
        
        let request = UpdatePostRequest(caption: caption)
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        // Backend returns { message: "...", post: {...} }
        struct UpdatePostResponse: Codable {
            let message: String?
            let post: CommunityPost
        }
        
        let response = try await api.request(
            "PUT",
            path: "/community/posts/\(postId)",
            headers: headers,
            body: request,
            responseType: UpdatePostResponse.self,
            timeout: 30,
            retries: 1
        )
        
        return response.post
    }
    
    // MARK: - Delete Post (owner only)
    
    func deletePost(postId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        _ = try await api.request(
            "DELETE",
            path: "/community/posts/\(postId)",
            headers: headers,
            responseType: EmptyResponse.self,
            timeout: 30,
            retries: 1
        )
    }
}

// Empty response for DELETE requests
struct EmptyResponse: Codable {}

