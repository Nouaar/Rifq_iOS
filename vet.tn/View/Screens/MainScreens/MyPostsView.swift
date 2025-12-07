//
//  MyPostsView.swift
//  vet.tn
//
//  View showing user's own posts with edit and delete functionality

import SwiftUI

struct MyPostsView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = CommunityViewModel()
    @State private var showEditSheet = false
    @State private var selectedPost: CommunityPost?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView()
                        .tint(.vetCanyon)
                } else if viewModel.posts.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                MyPostCard(
                                    post: post,
                                    onEdit: {
                                        selectedPost = post
                                        showEditSheet = true
                                    },
                                    onDelete: {
                                        Task {
                                            let success = await viewModel.deletePost(postId: post.id)
                                            if success {
                                                // Show success feedback
                                            }
                                        }
                                    }
                                )
                            }
                            
                            if viewModel.hasMorePosts && !viewModel.isLoading {
                                Button {
                                    Task {
                                        await viewModel.loadMyPosts()
                                    }
                                } label: {
                                    Text("Load More")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.vetCanyon)
                                        .padding()
                                }
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("My Posts")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadMyPosts(refresh: true)
            }
            .sheet(isPresented: $showEditSheet) {
                if let post = selectedPost {
                    EditPostView(
                        post: post,
                        onSave: { caption in
                            Task {
                                let success = await viewModel.updatePost(
                                    postId: post.id,
                                    caption: caption
                                )
                                if success {
                                    selectedPost = nil
                                    showEditSheet = false
                                }
                            }
                        },
                        onCancel: {
                            selectedPost = nil
                            showEditSheet = false
                        }
                    )
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
        .task {
            viewModel.sessionManager = session
            await viewModel.loadMyPosts(refresh: true)
        }
        .onChange(of: session.user?.id) { _, _ in
            Task {
                await viewModel.loadMyPosts(refresh: true)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.vetSubtitle.opacity(0.5))
            
            Text("No Posts Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.vetTitle)
            
            Text("Start sharing your pet moments with the community!")
                .font(.system(size: 14))
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - My Post Card

struct MyPostCard: View {
    let post: CommunityPost
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: post.imageUrl.isEmpty ? nil : URL(string: post.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(12)
            }
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundColor(.vetTitle)
                    .padding(.horizontal, 4)
            }
            
            // Actions
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(post.isLiked ? .red : .vetSubtitle)
                    Text("\(post.likesCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .foregroundColor(.vetSubtitle)
                    Text("\(post.commentsCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.vetSubtitle)
                }
                
                Spacer()
                
                // Edit and Delete buttons
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.vetCanyon)
                        .padding(8)
                        .background(Color.vetCanyon.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            // Date
            Text(formatDate(post.createdAt))
                .font(.system(size: 12))
                .foregroundColor(.vetSubtitle)
                .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.vetCardBackground)
        .cornerRadius(16)
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Edit Post View

struct EditPostView: View {
    let post: CommunityPost
    let onSave: (String?) -> Void
    let onCancel: () -> Void
    
    @State private var caption: String
    @State private var isSaving = false
    @FocusState private var isCaptionFocused: Bool
    
    init(post: CommunityPost, onSave: @escaping (String?) -> Void, onCancel: @escaping () -> Void) {
        self.post = post
        self.onSave = onSave
        self.onCancel = onCancel
        _caption = State(initialValue: post.caption ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Post Image
                    AsyncImage(url: post.imageUrl.isEmpty ? nil : URL(string: post.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Caption Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.vetTitle)
                        
                        TextEditor(text: $caption)
                            .font(.system(size: 16))
                            .foregroundColor(.vetTitle)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.vetCardBackground)
                            .cornerRadius(12)
                            .focused($isCaptionFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isCaptionFocused ? Color.vetCanyon : Color.clear, lineWidth: 2)
                            )
                        
                        Text("\(caption.count)/1000")
                            .font(.system(size: 12))
                            .foregroundColor(.vetSubtitle)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
            .navigationTitle("Edit Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.vetCanyon)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isSaving = true
                        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmedCaption.isEmpty ? nil : trimmedCaption)
                        isSaving = false
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.vetCanyon)
                    .cornerRadius(8)
                }
            }
        }
    }
}

