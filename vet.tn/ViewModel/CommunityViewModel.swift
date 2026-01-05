//
//  CommunityViewModel.swift
//  vet.tn
//
//  Community feed view model

import Foundation
import SwiftUI
import Combine

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isCreatingPost: Bool = false
    
    private let communityService = CommunityService.shared
    weak var sessionManager: SessionManager?
    
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    var hasMorePosts: Bool = true
    
    // MARK: - Load Posts
    
    func loadPosts(refresh: Bool = false) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return
        }
        
        if refresh {
            currentPage = 0
            hasMorePosts = true
        }
        
        guard hasMorePosts else { return }
        
        isLoading = true
        error = nil
        
        do {
            let offset = currentPage * pageSize
            let response = try await communityService.getPosts(
                limit: pageSize,
                offset: offset,
                accessToken: accessToken
            )
            
            if refresh {
                posts = response.posts
            } else {
                posts.append(contentsOf: response.posts)
            }
            
            hasMorePosts = response.posts.count >= pageSize
            currentPage += 1
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load posts: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Create Post
    
    func createPost(petId: String?, imageData: Data, caption: String?) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return false
        }
        
        isCreatingPost = true
        error = nil
        
        // Ensure we have valid image data
        guard !imageData.isEmpty else {
            error = "Invalid image data"
            isCreatingPost = false
            return false
        }
        
        #if DEBUG
        print("📸 Creating post with image data: \(imageData.count) bytes")
        #endif
        
        do {
            // Backend expects multipart/form-data with file field "petImage"
            let newPost = try await communityService.createPost(
                imageData: imageData,
                caption: caption?.trimmingCharacters(in: .whitespacesAndNewlines),
                accessToken: accessToken
            )
            
            // Add new post at the beginning
            posts.insert(newPost, at: 0)
            return true
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to create post: \(error)")
            #endif
            return false
        }
        
        isCreatingPost = false
    }
    
    // MARK: - Toggle Like
    
    func toggleLike(postId: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        // Find the post to check current reaction
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else {
            return
        }
        let post = posts[postIndex]
        
        do {
            let updatedPost: CommunityPost
            if post.isLiked {
                // Remove reaction
                updatedPost = try await communityService.removeReaction(
                    postId: postId,
                    reactionType: post.userReaction ?? "like",
                    accessToken: accessToken
                )
            } else {
                // Add reaction
                updatedPost = try await communityService.reactToPost(
                    postId: postId,
                    reactionType: "like",
                    accessToken: accessToken
                )
            }
            
            // Update post in list
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index] = updatedPost
            }
        } catch {
            #if DEBUG
            print("❌ Failed to toggle like: \(error)")
            #endif
        }
    }
    
    // MARK: - React to Post
    
    func reactToPost(postId: String, reactionType: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        // Find the post to check current reaction
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else {
            return
        }
        let post = posts[postIndex]
        
        do {
            let updatedPost: CommunityPost
            
            // If user already has this reaction, remove it
            if post.userReaction == reactionType {
                updatedPost = try await communityService.removeReaction(
                    postId: postId,
                    reactionType: reactionType,
                    accessToken: accessToken
                )
            } else if post.userReaction != nil {
                // User has a different reaction, first remove old reaction
                _ = try await communityService.removeReaction(
                    postId: postId,
                    reactionType: post.userReaction!,
                    accessToken: accessToken
                )
                // Then add new reaction
                updatedPost = try await communityService.reactToPost(
                    postId: postId,
                    reactionType: reactionType,
                    accessToken: accessToken
                )
            } else {
                // User has no reaction, add new one
                updatedPost = try await communityService.reactToPost(
                    postId: postId,
                    reactionType: reactionType,
                    accessToken: accessToken
                )
            }
            
            // Update post in list
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index] = updatedPost
            }
        } catch {
            #if DEBUG
            print("❌ Failed to react to post: \(error)")
            #endif
        }
    }
    
    // MARK: - Load My Posts
    
    func loadMyPosts(refresh: Bool = false) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            error = "Not authenticated"
            return
        }
        
        if refresh {
            currentPage = 0
            hasMorePosts = true
        }
        
        guard hasMorePosts else { return }
        
        isLoading = true
        error = nil
        
        do {
            let page = currentPage + 1
            let response = try await communityService.getMyPosts(
                page: page,
                limit: pageSize,
                accessToken: accessToken
            )
            
            if refresh {
                posts = response.posts
            } else {
                posts.append(contentsOf: response.posts)
            }
            
            // Check if there are more pages
            let totalPages = response.totalPages ?? 1
            hasMorePosts = page < totalPages
            currentPage = page
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load my posts: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Update Post
    
    func updatePost(postId: String, caption: String?) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return false
        }
        
        do {
            let updatedPost = try await communityService.updatePost(
                postId: postId,
                caption: caption?.trimmingCharacters(in: .whitespacesAndNewlines),
                accessToken: accessToken
            )
            
            // Update post in list
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index] = updatedPost
            }
            return true
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to update post: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Delete Post
    
    func deletePost(postId: String) async -> Bool {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return false
        }
        
        do {
            try await communityService.deletePost(
                postId: postId,
                accessToken: accessToken
            )
            
            // Remove post from list
            posts.removeAll { $0.id == postId }
            return true
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to delete post: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Report Post
    
    func reportPost(postId: String) async {
        guard let session = sessionManager,
              let accessToken = session.tokens?.accessToken else {
            return
        }
        
        do {
            try await communityService.reportPost(
                postId: postId,
                accessToken: accessToken
            )
            
            // Remove post from list if it was deleted
            posts.removeAll { $0.id == postId }
            
            #if DEBUG
            print("✅ Post reported successfully")
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to report post: \(error)")
            #endif
        }
    }
}
