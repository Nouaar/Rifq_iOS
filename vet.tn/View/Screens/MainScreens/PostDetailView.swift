//
//  PostDetailView.swift
//  vet.tn
//
//  Post detail view with comments

import SwiftUI

struct PostDetailView: View {
    let post: CommunityPost
    let viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    
    @State private var comments: [PostComment] = []
    @State private var isLoadingComments = false
    @State private var commentText = ""
    @State private var isPostingComment = false
    @State private var showDeleteAlert = false
    @State private var isLiking = false
    @State private var localPost: CommunityPost
    
    private let communityService = CommunityService.shared
    private var isOwner: Bool {
        guard let userId = session.user?.id else { return false }
        return post.userId == userId
    }
    
    init(post: CommunityPost, viewModel: CommunityViewModel) {
        self.post = post
        self.viewModel = viewModel
        _localPost = State(initialValue: post)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Post Card
                        PostDetailCard(
                            post: post,
                            isLiking: isLiking,
                            onLike: {
                                guard !isLiking else { return }
                                isLiking = true
                                Task {
                                    await viewModel.toggleLike(postId: post.id)
                                    isLiking = false
                                }
                            },
                            onDelete: isOwner ? {
                                showDeleteAlert = true
                            } : nil
                        )
                        .padding(.bottom, 20)
                        
                        Divider()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                        // Comments Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Comments")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.vetTitle)
                                
                                if !comments.isEmpty {
                                    Text("(\(comments.count))")
                                        .font(.system(size: 16))
                                        .foregroundColor(.vetSubtitle)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            if isLoadingComments {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                            } else if comments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.vetSubtitle.opacity(0.5))
                                    Text("No comments yet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.vetTitle)
                                    Text("Be the first to comment")
                                        .font(.system(size: 14))
                                        .foregroundColor(.vetSubtitle)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(comments) { comment in
                                        CommentRow(
                                            comment: comment,
                                            onDelete: {
                                                guard let userId = session.user?.id,
                                                      comment.userId == userId else { return }
                                                Task {
                                                    await deleteComment(comment)
                                                }
                                            }
                                        )
                                        .environmentObject(session)
                                        
                                        if comment.id != comments.last?.id {
                                            Divider()
                                                .padding(.leading, 60)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100) // Space for comment input
                    }
                }
                
                // Comment Input - pinned at bottom
                VStack {
                    Spacer()
                    CommentInputView(
                        text: $commentText,
                        isPosting: isPostingComment,
                        onSubmit: {
                            Task {
                                await postComment()
                            }
                        }
                    )
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.vetTitle)
                    }
                }
            }
            .task {
                // Load comments from the post data we already have
                if let postComments = localPost.comments {
                    comments = postComments
                }
                
                // Refresh post to get latest comments
                await refreshPost()
            }
            .alert("Delete Post", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        let success = await viewModel.deletePost(postId: post.id)
                        if success {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
        }
    }
    
    private func refreshPost() async {
        // Find the updated post in the viewModel's posts array
        if let updatedPost = viewModel.posts.first(where: { $0.id == post.id }) {
            localPost = updatedPost
            if let postComments = updatedPost.comments {
                comments = postComments
            }
        }
    }
    
    private func postComment() async {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let accessToken = session.tokens?.accessToken else { return }
        
        isPostingComment = true
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        commentText = ""
        
        do {
            let request = CreateCommentRequest(text: text)
            let response = try await communityService.createComment(
                postId: post.id,
                request: request,
                accessToken: accessToken
            )
            
            // Add the new comment to the beginning of the list
            if let newComment = response.comment {
                comments.insert(newComment, at: 0)
            }
            
            // Refresh the post to get updated data
            await viewModel.loadPosts(refresh: true)
            await refreshPost()
        } catch {
            #if DEBUG
            print("❌ Failed to post comment: \(error)")
            #endif
            commentText = text // Restore text on error
        }
        
        isPostingComment = false
    }
    
    private func deleteComment(_ comment: PostComment) async {
        guard let accessToken = session.tokens?.accessToken else { return }
        
        do {
            try await communityService.deleteComment(
                postId: post.id,
                commentId: comment.id,
                accessToken: accessToken
            )
            comments.removeAll { $0.id == comment.id }
        } catch {
            #if DEBUG
            print("❌ Failed to delete comment: \(error)")
            #endif
        }
    }
}

// MARK: - Post Detail Card

struct PostDetailCard: View {
    let post: CommunityPost
    let isLiking: Bool
    let onLike: () -> Void
    let onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: post.userAvatarUrl ?? post.petPhotoUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.vetCanyon.opacity(0.2))
                        .overlay(
                            Text(post.displayName.prefix(1).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.vetCanyon)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.vetTitle)
                    
                    if let userName = post.userName, let petName = post.petName {
                        Text("\(userName) • \(petName)")
                            .font(.system(size: 13))
                            .foregroundColor(.vetSubtitle)
                    }
                }
                
                Spacer()
                
                if let onDelete = onDelete {
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.vetTitle)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Image
            AsyncImage(url: post.imageUrl.isEmpty ? nil : URL(string: post.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 400)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 400)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            
            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(post.isLiked ? .red : .vetTitle)
                        
                        Text("\(post.likesCount)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.vetTitle)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLiking)
                
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .font(.system(size: 24))
                        .foregroundColor(.vetTitle)
                    
                    Text("\(post.commentsCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vetTitle)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 15))
                    .foregroundColor(.vetTitle)
                    .padding(.horizontal, 16)
            }
        }
        .background(Color.vetCardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: PostComment
    var onDelete: (() -> Void)? = nil
    @EnvironmentObject private var session: SessionManager
    @State private var showDeleteAlert = false
    @State private var showUserProfile = false
    
    private var isOwner: Bool {
        guard let userId = session.user?.id else { return false }
        return comment.userId == userId
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                showUserProfile = true
            } label: {
                AsyncImage(url: URL(string: comment.userAvatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.vetCanyon.opacity(0.2))
                        .overlay(
                            Text((comment.userName ?? "?").prefix(1).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.vetCanyon)
                        )
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Button {
                        showUserProfile = true
                    } label: {
                        Text(comment.userName ?? "Unknown")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.vetTitle)
                    }
                    .buttonStyle(.plain)
                    
                    if let role = comment.userRole {
                        if role == "veterinarian" || role == "pet-sitter" {
                            Text("• \(role == "veterinarian" ? "Vet" : "Sitter")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.vetCanyon)
                        }
                    }
                    
                    Spacer()
                    
                    if isOwner, let onDelete = onDelete {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(.vetTitle)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                Text(formatDate(comment.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.vetSubtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(
                userId: comment.userId,
                userName: comment.userName,
                userAvatarUrl: comment.userAvatarUrl,
                userRole: comment.userRole
            )
            .environmentObject(session)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let hoursAgo = Int(now.timeIntervalSince(date) / 3600)
            if hoursAgo < 1 {
                let minutesAgo = Int(now.timeIntervalSince(date) / 60)
                return "\(minutesAgo)m ago"
            }
            return "\(hoursAgo)h ago"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
    }
}

// MARK: - Comment Input View

struct CommentInputView: View {
    @Binding var text: String
    let isPosting: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Add a comment...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.vetCardBackground)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.vetStroke.opacity(0.3))
                )
                .lineLimit(1...4)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSubmit()
                    }
                }
            
            Button(action: onSubmit) {
                if isPosting {
                    ProgressView()
                        .tint(.vetCanyon)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
            .frame(width: 44, height: 44)
            .background(
                text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting
                    ? Color.gray.opacity(0.3)
                    : Color.vetCanyon
            )
            .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color.vetBackground
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
        )
    }
}

