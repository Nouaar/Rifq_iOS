//
//  CommunityModels.swift
//  vet.tn
//
//  Community post models

import Foundation

// MARK: - Community Post

struct CommunityPost: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let userName: String?
    let userAvatarUrl: String?
    let petId: String?
    let petName: String?
    let petPhotoUrl: String?
    let imageUrl: String
    let caption: String?
    let likesCount: Int
    let commentsCount: Int
    let isLiked: Bool
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case userId
        case user_id
        case userName
        case user_name
        case userAvatarUrl
        case user_avatar_url
        case userProfileImage
        case user_profile_image
        case petId
        case pet_id
        case petName
        case pet_name
        case petPhotoUrl
        case pet_photo_url
        case petImage
        case pet_image
        case imageUrl
        case image_url
        case image
        case photo
        case photoUrl
        case photo_url
        case photoURL
        case caption
        case likesCount
        case likes_count
        case likes
        case loves
        case hahas
        case angries
        case cries
        case commentsCount
        case comments_count
        case isLiked
        case is_liked
        case userReaction
        case user_reaction
        case createdAt
        case created_at
        case updatedAt
        case updated_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle both id and _id
        if let id = try? container.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? container.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing both id and _id"))
        }
        
        // Handle userId
        if let userId = try? container.decode(String.self, forKey: .userId) {
            self.userId = userId
        } else if let userId = try? container.decode(String.self, forKey: .user_id) {
            self.userId = userId
        } else {
            throw DecodingError.keyNotFound(CodingKeys.userId, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing userId"))
        }
        
        userName = (try? container.decode(String.self, forKey: .userName)) ?? (try? container.decode(String.self, forKey: .user_name))
        userAvatarUrl = (try? container.decode(String.self, forKey: .userAvatarUrl)) 
            ?? (try? container.decode(String.self, forKey: .user_avatar_url))
            ?? (try? container.decode(String.self, forKey: .userProfileImage))
            ?? (try? container.decode(String.self, forKey: .user_profile_image))
        petId = (try? container.decode(String.self, forKey: .petId)) ?? (try? container.decode(String.self, forKey: .pet_id))
        petName = (try? container.decode(String.self, forKey: .petName)) ?? (try? container.decode(String.self, forKey: .pet_name))
        petPhotoUrl = (try? container.decode(String.self, forKey: .petPhotoUrl)) ?? (try? container.decode(String.self, forKey: .pet_photo_url))
        
        // Handle imageUrl - try multiple variants in order of likelihood
        // Backend uses "petImage" as the field name
        var foundImageUrl: String? = nil
        
        // Try petImage first (backend uses this)
        if let url = try? container.decode(String.self, forKey: .petImage) { foundImageUrl = url }
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .pet_image) { foundImageUrl = url }
        
        // Try camelCase variants
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .imageUrl) { foundImageUrl = url }
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .photoUrl) { foundImageUrl = url }
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .photoURL) { foundImageUrl = url }
        
        // Try snake_case variants
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .image_url) { foundImageUrl = url }
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .photo_url) { foundImageUrl = url }
        
        // Try simple field names
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .image) { foundImageUrl = url }
        if foundImageUrl == nil, let url = try? container.decode(String.self, forKey: .photo) { foundImageUrl = url }
        
        // If still not found, use empty string as fallback (don't throw error to allow decoding to continue)
        self.imageUrl = foundImageUrl ?? ""
        
        caption = try? container.decode(String.self, forKey: .caption)
        
        // Handle likesCount - backend provides individual reaction counts
        // Sum up all reactions (likes, loves, hahas, etc.)
        let likes = (try? container.decode(Int.self, forKey: .likes)) ?? 0
        let loves = (try? container.decode(Int.self, forKey: .loves)) ?? 0
        let hahas = (try? container.decode(Int.self, forKey: .hahas)) ?? 0
        let angries = (try? container.decode(Int.self, forKey: .angries)) ?? 0
        let cries = (try? container.decode(Int.self, forKey: .cries)) ?? 0
        
        // Total reactions count
        if let likesCount = try? container.decode(Int.self, forKey: .likesCount) {
            self.likesCount = likesCount
        } else if let likesCount = try? container.decode(Int.self, forKey: .likes_count) {
            self.likesCount = likesCount
        } else {
            // Sum all reactions if likesCount is not provided
            self.likesCount = likes + loves + hahas + angries + cries
        }
        
        // Handle commentsCount - backend doesn't seem to provide this in the response
        if let commentsCount = try? container.decode(Int.self, forKey: .commentsCount) {
            self.commentsCount = commentsCount
        } else if let commentsCount = try? container.decode(Int.self, forKey: .comments_count) {
            self.commentsCount = commentsCount
        } else {
            self.commentsCount = 0 // Default to 0 if not found
        }
        
        // Handle isLiked - backend uses userReaction instead
        if let userReaction = try? container.decode(String?.self, forKey: .userReaction) ?? (try? container.decode(String?.self, forKey: .user_reaction)) {
            // If userReaction is not null, user has reacted
            self.isLiked = userReaction != nil && !userReaction.isEmpty
        } else if let isLiked = try? container.decode(Bool.self, forKey: .isLiked) {
            self.isLiked = isLiked
        } else if let isLiked = try? container.decode(Bool.self, forKey: .is_liked) {
            self.isLiked = isLiked
        } else {
            self.isLiked = false // Default to false if not found
        }
        
        // Handle createdAt
        if let createdAt = try? container.decode(String.self, forKey: .createdAt) {
            self.createdAt = createdAt
        } else if let createdAt = try? container.decode(String.self, forKey: .created_at) {
            self.createdAt = createdAt
        } else {
            throw DecodingError.keyNotFound(CodingKeys.createdAt, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing createdAt"))
        }
        
        updatedAt = (try? container.decode(String.self, forKey: .updatedAt)) ?? (try? container.decode(String.self, forKey: .updated_at))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userAvatarUrl, forKey: .userAvatarUrl)
        try container.encodeIfPresent(petId, forKey: .petId)
        try container.encodeIfPresent(petName, forKey: .petName)
        try container.encodeIfPresent(petPhotoUrl, forKey: .petPhotoUrl)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(caption, forKey: .caption)
        try container.encode(likesCount, forKey: .likesCount)
        try container.encode(commentsCount, forKey: .commentsCount)
        try container.encode(isLiked, forKey: .isLiked)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // Computed property for display
    var displayName: String {
        if let petName = petName {
            return petName
        }
        return userName ?? "Unknown User"
    }
}

// MARK: - Create Post Request

struct CreatePostRequest: Codable {
    let petId: String?
    let petImage: String // Backend expects this field name (required, not optional)
    let image: String? // Also send as "image" for compatibility
    let caption: String?
    
    enum CodingKeys: String, CodingKey {
        case petId
        case petImage
        case image
        case caption
    }
    
    init(petId: String?, imageData: String, caption: String?) {
        self.petId = petId
        self.petImage = imageData // Backend expects petImage
        self.image = imageData // Also send as image for compatibility
        self.caption = caption
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(petId, forKey: .petId)
        try container.encode(petImage, forKey: .petImage) // Always encode petImage (required)
        try container.encodeIfPresent(image, forKey: .image) // Also send as image
        try container.encodeIfPresent(caption, forKey: .caption)
    }
}

// MARK: - Post Comment

struct PostComment: Identifiable, Codable, Hashable {
    let id: String
    let postId: String
    let userId: String
    let userName: String?
    let userAvatarUrl: String?
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case postId
        case post_id
        case userId
        case user_id
        case userName
        case user_name
        case userAvatarUrl
        case user_avatar_url
        case content
        case createdAt
        case created_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle both id and _id
        if let id = try? container.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? container.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing both id and _id"))
        }
        
        // Handle postId
        if let postId = try? container.decode(String.self, forKey: .postId) {
            self.postId = postId
        } else if let postId = try? container.decode(String.self, forKey: .post_id) {
            self.postId = postId
        } else {
            throw DecodingError.keyNotFound(CodingKeys.postId, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing postId"))
        }
        
        // Handle userId
        if let userId = try? container.decode(String.self, forKey: .userId) {
            self.userId = userId
        } else if let userId = try? container.decode(String.self, forKey: .user_id) {
            self.userId = userId
        } else {
            throw DecodingError.keyNotFound(CodingKeys.userId, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing userId"))
        }
        
        userName = (try? container.decode(String.self, forKey: .userName)) ?? (try? container.decode(String.self, forKey: .user_name))
        userAvatarUrl = (try? container.decode(String.self, forKey: .userAvatarUrl)) ?? (try? container.decode(String.self, forKey: .user_avatar_url))
        
        content = try container.decode(String.self, forKey: .content)
        
        // Handle createdAt
        if let createdAt = try? container.decode(String.self, forKey: .createdAt) {
            self.createdAt = createdAt
        } else if let createdAt = try? container.decode(String.self, forKey: .created_at) {
            self.createdAt = createdAt
        } else {
            throw DecodingError.keyNotFound(CodingKeys.createdAt, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing createdAt"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(postId, forKey: .postId)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userAvatarUrl, forKey: .userAvatarUrl)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Create Comment Request

struct CreateCommentRequest: Codable {
    let content: String
}

// MARK: - Post Response

struct PostsResponse: Codable {
    let posts: [CommunityPost]
    let total: Int
    let page: Int?
    let limit: Int?
    let totalPages: Int?
    
    enum CodingKeys: String, CodingKey {
        case posts
        case total
        case page
        case limit
        case totalPages
        case total_pages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        posts = try container.decode([CommunityPost].self, forKey: .posts)
        total = try container.decode(Int.self, forKey: .total)
        page = try? container.decode(Int.self, forKey: .page)
        limit = try? container.decode(Int.self, forKey: .limit)
        totalPages = (try? container.decode(Int.self, forKey: .totalPages)) ?? (try? container.decode(Int.self, forKey: .total_pages))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(posts, forKey: .posts)
        try container.encode(total, forKey: .total)
        try container.encodeIfPresent(page, forKey: .page)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(totalPages, forKey: .totalPages)
    }
}

// MARK: - Comments Response

struct CommentsResponse: Codable {
    let comments: [PostComment]
    let total: Int
}

