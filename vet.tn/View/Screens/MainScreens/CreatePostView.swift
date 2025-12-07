//
//  CreatePostView.swift
//  vet.tn
//
//  View for creating a new community post

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel = CommunityViewModel()
    
    let pets: [Pet]
    let onPostCreated: () -> Void
    
    @State private var selectedPet: Pet?
    @State private var selectedImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var caption: String = ""
    @State private var isPosting = false
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vetBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image picker/display
                        VStack(spacing: 12) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        Button {
                                            selectedImage = nil
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .padding(8),
                                        alignment: .topTrailing
                                    )
                            } else {
                                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                    VStack(spacing: 16) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 48))
                                            .foregroundColor(.vetCanyon)
                                        
                                        Text("Add Photo")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.vetTitle)
                                        
                                        Text("Choose a photo of your pet")
                                            .font(.system(size: 14))
                                            .foregroundColor(.vetSubtitle)
                                    }
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.vetCardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(Color.vetStroke.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Pet selection (optional)
                        if !pets.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Pet (Optional)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.vetTitle)
                                    .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // None option
                                        PetSelectionCard(
                                            isSelected: selectedPet == nil,
                                            title: "No pet",
                                            emoji: "📷"
                                        ) {
                                            selectedPet = nil
                                        }
                                        
                                        ForEach(pets) { pet in
                                            PetSelectionCard(
                                                isSelected: selectedPet?.id == pet.id,
                                                title: pet.name,
                                                emoji: petEmoji(for: pet.species),
                                                imageUrl: pet.photo
                                            ) {
                                                selectedPet = pet
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        // Caption
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Caption (Optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vetTitle)
                            
                            TextEditor(text: $caption)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color.vetCardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.vetStroke.opacity(0.3))
                                )
                                .overlay(
                                    Group {
                                        if caption.isEmpty {
                                            Text("Write a caption...")
                                                .foregroundColor(.vetSubtitle.opacity(0.5))
                                                .padding(.top, 20)
                                                .padding(.leading, 16)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.vetCanyon)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await postContent()
                        }
                    } label: {
                        if isPosting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(selectedImage == nil || isPosting)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedImage != nil && !isPosting
                            ? Color.vetCanyon
                            : Color.gray.opacity(0.3)
                    )
                    .cornerRadius(8)
                }
            }
            .onChange(of: photoPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        // Compress and resize image
                        if let compressed = compressImage(uiImage) {
                            selectedImage = compressed
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error ?? "Failed to create post")
            }
        }
    }
    
    private func postContent() async {
        guard let image = selectedImage else {
            return
        }
        
        // Compress image to reduce file size (backend limit is 100KB)
        guard let imageData = compressImageToData(image, maxSizeInMB: 0.1) else {
            showError = true
            viewModel.error = "Failed to compress image"
            return
        }
        
        #if DEBUG
        let sizeInMB = Double(imageData.count) / (1024 * 1024)
        print("📸 Image compressed to \(String(format: "%.2f", sizeInMB)) MB")
        #endif
        
        isPosting = true
        viewModel.sessionManager = session
        
        let success = await viewModel.createPost(
            petId: selectedPet?.id,
            imageData: imageData,
            caption: caption.isEmpty ? nil : caption
        )
        
        isPosting = false
        
        if success {
            onPostCreated()
            dismiss()
        } else {
            showError = true
        }
    }
    
    private func compressImage(_ image: UIImage) -> UIImage? {
        // Resize to max 800px width for display
        let maxWidth: CGFloat = 800
        let size = image.size
        
        if size.width <= maxWidth {
            return image
        }
        
        let ratio = maxWidth / size.width
        let newSize = CGSize(width: maxWidth, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func compressImageToData(_ image: UIImage, maxSizeInMB: Double) -> Data? {
        // Backend limit is 100KB (102,400 bytes), use that as hard limit
        let maxSizeInBytes = Int(maxSizeInMB * 1024 * 1024) // Convert MB to bytes
        let hardLimit = 95 * 1024 // 95KB to stay safely under 100KB backend limit
        
        // Start with more aggressive resizing - backend limit is very strict
        let maxDimension: CGFloat = 600 // Start smaller for better compression
        let size = image.size
        let maxSize = max(size.width, size.height)
        
        var resizedImage = image
        if maxSize > maxDimension {
            let ratio = maxDimension / maxSize
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.8) // Lower scale factor
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        
        // Start with lower quality and reduce aggressively
        var compressionQuality: CGFloat = 0.5 // Start at 50% quality
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        let targetLimit = min(maxSizeInBytes, hardLimit)
        
        // Reduce quality progressively if still too large
        while let data = imageData, data.count > targetLimit && compressionQuality > 0.05 {
            compressionQuality -= 0.05 // Reduce by 5% each time
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
            
            #if DEBUG
            if let currentData = imageData {
                let currentSizeKB = Double(currentData.count) / 1024
                print("🔧 Compression quality: \(String(format: "%.2f", compressionQuality)), size: \(String(format: "%.1f", currentSizeKB)) KB")
            }
            #endif
        }
        
        // If still too large after compression, resize even more aggressively
        if let data = imageData, data.count > targetLimit {
            #if DEBUG
            print("⚠️ Still too large (\(data.count) bytes), resizing more aggressively...")
            #endif
            
            // Reduce to 400px max dimension
            var finalImage = resizedImage
            let aggressiveMaxDimension: CGFloat = 400
            let currentMax = max(resizedImage.size.width, resizedImage.size.height)
            
            if currentMax > aggressiveMaxDimension {
                let aggressiveRatio = aggressiveMaxDimension / currentMax
                let aggressiveSize = CGSize(
                    width: resizedImage.size.width * aggressiveRatio,
                    height: resizedImage.size.height * aggressiveRatio
                )
                
                UIGraphicsBeginImageContextWithOptions(aggressiveSize, false, 0.7) // Lower scale
                resizedImage.draw(in: CGRect(origin: .zero, size: aggressiveSize))
                finalImage = UIGraphicsGetImageFromCurrentImageContext() ?? resizedImage
                UIGraphicsEndImageContext()
            }
            
            // Try compression again starting from very low quality
            compressionQuality = 0.3
            imageData = finalImage.jpegData(compressionQuality: compressionQuality)
            
            while let data = imageData, data.count > targetLimit && compressionQuality > 0.05 {
                compressionQuality -= 0.05
                imageData = finalImage.jpegData(compressionQuality: compressionQuality)
                
                #if DEBUG
                if let currentData = imageData {
                    let currentSizeKB = Double(currentData.count) / 1024
                    print("🔧 Aggressive compression: quality \(String(format: "%.2f", compressionQuality)), size: \(String(format: "%.1f", currentSizeKB)) KB")
                }
                #endif
            }
            
            // Last resort: if still too large, resize to 300px
            if let data = imageData, data.count > targetLimit {
                #if DEBUG
                print("⚠️ Final aggressive resize to 300px...")
                #endif
                
                let finalMaxDimension: CGFloat = 300
                let finalMax = max(finalImage.size.width, finalImage.size.height)
                if finalMax > finalMaxDimension {
                    let finalRatio = finalMaxDimension / finalMax
                    let finalSize = CGSize(
                        width: finalImage.size.width * finalRatio,
                        height: finalImage.size.height * finalRatio
                    )
                    
                    UIGraphicsBeginImageContextWithOptions(finalSize, false, 0.6)
                    finalImage.draw(in: CGRect(origin: .zero, size: finalSize))
                    finalImage = UIGraphicsGetImageFromCurrentImageContext() ?? finalImage
                    UIGraphicsEndImageContext()
                }
                
                // Try with very low quality
                compressionQuality = 0.2
                imageData = finalImage.jpegData(compressionQuality: compressionQuality)
                
                while let data = imageData, data.count > targetLimit && compressionQuality > 0.05 {
                    compressionQuality -= 0.05
                    imageData = finalImage.jpegData(compressionQuality: compressionQuality)
                }
            }
        }
        
        // Final check - if still too large, we've done our best
        if let finalData = imageData, finalData.count > hardLimit {
            #if DEBUG
            let finalSizeKB = Double(finalData.count) / 1024
            print("❌ Warning: Image still \(String(format: "%.1f", finalSizeKB)) KB after aggressive compression. Backend limit is 100KB.")
            #endif
        }
        
        return imageData
    }
    
    private func petEmoji(for species: String) -> String {
        switch species.lowercased() {
        case "dog": return "🐕"
        case "cat": return "🐈"
        case "bird": return "🐦"
        case "rabbit": return "🐰"
        case "hamster": return "🐹"
        case "fish": return "🐠"
        default: return "🐾"
        }
    }
}

// MARK: - Pet Selection Card

struct PetSelectionCard: View {
    let isSelected: Bool
    let title: String
    let emoji: String
    var imageUrl: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let imageUrl = imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.vetCanyon : Color.clear, lineWidth: 3)
                    )
                } else {
                    Text(emoji)
                        .font(.system(size: 32))
                        .frame(width: 60, height: 60)
                        .background(Color.vetCanyon.opacity(0.1))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(isSelected ? Color.vetCanyon : Color.clear, lineWidth: 3)
                        )
                }
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.vetTitle)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected ? Color.vetCanyon.opacity(0.1) : Color.vetCardBackground
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.vetCanyon : Color.vetStroke.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

