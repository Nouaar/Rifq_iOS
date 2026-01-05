//
//  CommunityFeedView.swift
//  vet.tn
//
//  Community feed view - shows posts from users about their pets

import SwiftUI

struct CommunityFeedView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var petViewModel = PetViewModel()
    @Binding var tabSelection: VetTab
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreatePost = false
    @State private var selectedPost: CommunityPost?
    @State private var selectedTab = 0 // 0 = All Posts, 1 = My Posts
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar - Fixed
            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.vetCanyon)
                    }
                    
                    Text("Community")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.vetTitle)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            if selectedTab == 0 {
                                await viewModel.loadPosts(refresh: true)
                            } else {
                                await viewModel.loadMyPosts(refresh: true)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.vetCanyon)
                    }
                    
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.vetCanyon)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // Tab Row
                HStack(spacing: 0) {
                    Button {
                        selectedTab = 0
                        Task {
                            await viewModel.loadPosts(refresh: true)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text("All Posts")
                                .font(.system(size: 16, weight: selectedTab == 0 ? .semibold : .regular))
                                .foregroundColor(selectedTab == 0 ? .vetCanyon : .vetSubtitle)
                            
                            Rectangle()
                                .fill(selectedTab == 0 ? Color.vetCanyon : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        selectedTab = 1
                        Task {
                            await viewModel.loadMyPosts(refresh: true)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text("My Posts")
                                .font(.system(size: 16, weight: selectedTab == 1 ? .semibold : .regular))
                                .foregroundColor(selectedTab == 1 ? .vetCanyon : .vetSubtitle)
                            
                            Rectangle()
                                .fill(selectedTab == 1 ? Color.vetCanyon : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
            }
            .background(Color.vetBackground)
            
            // Content - Scrollable
            ZStack {
                Color.vetBackground.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.posts.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.vetCanyon)
                    Text("Loading community posts...")
                        .font(.system(size: 14))
                        .foregroundColor(.vetSubtitle)
                }
            } else if let error = viewModel.error, viewModel.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red.opacity(0.6))
                    
                    Text("Error loading posts")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vetTitle)
                    
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.vetSubtitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        Task {
                            await viewModel.loadPosts(refresh: true)
                        }
                    } label: {
                        Text("Retry")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.vetCanyon)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 8)
                }
                .padding()
            } else if viewModel.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.vetSubtitle.opacity(0.5))
                    
                    Text("No posts yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.vetTitle)
                    
                    Text("Be the first to share your pet with the community!")
                        .font(.system(size: 14))
                        .foregroundColor(.vetSubtitle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        showCreatePost = true
                    } label: {
                        Label("Create Post", systemImage: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.vetCanyon)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 8)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.posts) { post in
                            PostCard(post: post, viewModel: viewModel)
                                .onTapGesture {
                                    selectedPost = post
                                }
                        }
                        
                        if viewModel.hasMorePosts && !viewModel.isLoading {
                            ProgressView()
                                .padding()
                                .task {
                                    await viewModel.loadPosts()
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.sessionManager = session
            Task {
                await petViewModel.loadPets()
                await viewModel.loadPosts(refresh: true)
            }
        }
        .refreshable {
            await viewModel.loadPosts(refresh: true)
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(
                pets: petViewModel.pets,
                onPostCreated: {
                    Task {
                        await viewModel.loadPosts(refresh: true)
                    }
                }
            )
            .environmentObject(session)
        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post, viewModel: viewModel)
                .environmentObject(session)
        }
    }
}

// MARK: - Post Card

struct PostCard: View {
    let post: CommunityPost
    let viewModel: CommunityViewModel
    @EnvironmentObject private var session: SessionManager
    @State private var isLiking = false
    @State private var showReactionPicker = false
    @State private var showReportAlert = false
    @State private var showUserProfile = false
    
    private var isOwner: Bool {
        guard let userId = session.user?.id else { return false }
        return post.userId == userId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // User/Pet Avatar
                Button {
                    showUserProfile = true
                } label: {
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
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Button {
                        showUserProfile = true
                    } label: {
                        Text(post.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.vetTitle)
                    }
                    .buttonStyle(.plain)
                    
                    if let userName = post.userName, let petName = post.petName {
                        Text("\(userName) • \(petName)")
                            .font(.system(size: 13))
                            .foregroundColor(.vetSubtitle)
                    } else if let userName = post.userName {
                        Text(userName)
                            .font(.system(size: 13))
                            .foregroundColor(.vetSubtitle)
                    }
                }
                
                Spacer()
                
                // Report/Delete button
                Menu {
                    if isOwner {
                        Button(role: .destructive) {
                            Task {
                                _ = await viewModel.deletePost(postId: post.id)
                            }
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } else {
                        Button(role: .destructive) {
                            showReportAlert = true
                        } label: {
                            Label("Report Post", systemImage: "exclamationmark.triangle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.vetSubtitle)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Caption (before image, like Android)
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundColor(.vetTitle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            
            // Image
            AsyncImage(url: post.imageUrl.isEmpty ? nil : URL(string: post.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            ProgressView()
                                .tint(.vetCanyon)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 400)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            
            // Reactions summary
            if post.likes > 0 || post.loves > 0 || post.hahas > 0 || post.angries > 0 || post.cries > 0 {
                HStack(spacing: 8) {
                    if post.likes > 0 {
                        ReactionCountView(emoji: "👍", count: post.likes)
                    }
                    if post.loves > 0 {
                        ReactionCountView(emoji: "❤️", count: post.loves)
                    }
                    if post.hahas > 0 {
                        ReactionCountView(emoji: "😂", count: post.hahas)
                    }
                    if post.angries > 0 {
                        ReactionCountView(emoji: "😠", count: post.angries)
                    }
                    if post.cries > 0 {
                        ReactionCountView(emoji: "😢", count: post.cries)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Actions with reaction picker
            ZStack(alignment: .bottom) {
                HStack(spacing: 20) {
                    ReactionButton(
                        currentReaction: post.userReaction,
                        onClick: {
                            showReactionPicker.toggle()
                        }
                    )
                    
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .font(.system(size: 22))
                            .foregroundColor(.vetTitle)
                        
                        Text("\(post.commentsCount)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.vetTitle)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Reaction picker popup
                if showReactionPicker {
                    VStack {
                        Spacer()
                        ReactionPicker(
                            onReactionSelected: { reactionType in
                                guard !isLiking else { return }
                                isLiking = true
                                showReactionPicker = false
                                Task {
                                    await viewModel.reactToPost(postId: post.id, reactionType: reactionType.rawValue)
                                    isLiking = false
                                }
                            },
                            onDismiss: {
                                showReactionPicker = false
                            }
                        )
                        .offset(y: -50)
                    }
                }
            }
            
            // Spacing at bottom
            Spacer(minLength: 12)
        }
        .background(Color.vetCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .alert("Report Post", isPresented: $showReportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Report", role: .destructive) {
                Task {
                    await viewModel.reportPost(postId: post.id)
                }
            }
        } message: {
            Text("Are you sure you want to report this post? It will be reviewed by moderators.")
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(
                userId: post.userId,
                userName: post.userName,
                userAvatarUrl: post.userAvatarUrl,
                userRole: nil
            )
            .environmentObject(session)
        }
    }
}

struct CommunityFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CommunityFeedView(tabSelection: .constant(.home))
                .environmentObject(SessionManager())
        }
    }
}}
