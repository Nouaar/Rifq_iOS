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
    
    @State private var showCreatePost = false
    @State private var selectedPost: CommunityPost?
    
    var body: some View {
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
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreatePost = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.vetCanyon)
                }
            }
        }
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
    @State private var isLiking = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // User/Pet Avatar
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
                    } else if let userName = post.userName {
                        Text(userName)
                            .font(.system(size: 13))
                            .foregroundColor(.vetSubtitle)
                    }
                }
                
                Spacer()
                
                Text(formatDate(post.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.vetSubtitle)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
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
                        .scaledToFill()
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
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    guard !isLiking else { return }
                    isLiking = true
                    Task {
                        await viewModel.toggleLike(postId: post.id)
                        isLiking = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 22))
                            .foregroundColor(post.isLiked ? .red : .vetTitle)
                        
                        if post.likesCount > 0 {
                            Text("\(post.likesCount)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.vetTitle)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLiking)
                
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .font(.system(size: 22))
                        .foregroundColor(.vetTitle)
                    
                    if post.commentsCount > 0 {
                        Text("\(post.commentsCount)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.vetTitle)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundColor(.vetTitle)
                    .padding(.horizontal, 16)
            }
            
            // Spacing at bottom
            Spacer(minLength: 8)
        }
        .background(Color.vetCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
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
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let daysAgo = Int(now.timeIntervalSince(date) / 86400)
            if daysAgo < 7 {
                return "\(daysAgo)d ago"
            } else {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .short
                return displayFormatter.string(from: date)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CommunityFeedView()
            .environmentObject(SessionManager())
    }
}

