//
//  AudioMessageBubble.swift
//  vet.tn
//

import SwiftUI
import AVFoundation

struct AudioMessageBubble: View {
    let audioURL: URL
    let isFromCurrentUser: Bool
    let duration: TimeInterval?
    
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackTimer: Timer?
    @State private var playbackDelegate: PlaybackDelegate?
    @State private var totalDuration: TimeInterval = 0
    @State private var waveformHeights: [CGFloat] = []
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Other person's audio on the left
            if !isFromCurrentUser {
                Button {
                    togglePlayback()
                } label: {
                    HStack(spacing: 10) {
                        // Play/Pause Button
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vetCanyon)
                            .frame(width: 32, height: 32)
                        
                        // Waveform visualization
                        HStack(spacing: 2.5) {
                            ForEach(0..<min(30, waveformHeights.count), id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.vetCanyon.opacity(0.7))
                                    .frame(width: 3, height: waveformHeight(at: index))
                                    .animation(
                                        isPlaying ? .easeInOut(duration: 0.3).repeatForever() : .default,
                                        value: isPlaying
                                    )
                            }
                        }
                        .frame(height: 32)
                        
                        // Duration
                        Text(formatTime(totalDuration > 0 ? totalDuration : (duration ?? 0)))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.vetTitle)
                            .monospacedDigit()
                            .frame(minWidth: 45, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.vetCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.vetStroke.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 50)
            } else {
                // My audio on the right
                Spacer(minLength: 50)
                
                Button {
                    togglePlayback()
                } label: {
                    HStack(spacing: 10) {
                        // Play/Pause Button
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                        
                        // Waveform visualization
                        HStack(spacing: 2.5) {
                            ForEach(0..<min(30, waveformHeights.count), id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 3, height: waveformHeight(at: index))
                                    .animation(
                                        isPlaying ? .easeInOut(duration: 0.3).repeatForever() : .default,
                                        value: isPlaying
                                    )
                            }
                        }
                        .frame(height: 32)
                        
                        // Duration
                        Text(formatTime(totalDuration > 0 ? totalDuration : (duration ?? 0)))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .monospacedDigit()
                            .frame(minWidth: 45, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.vetCanyon)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.clear, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .onAppear {
            loadAudioDuration()
            generateWaveform()
        }
        .onDisappear {
            stopPlayback()
        }
        .onChange(of: isPlaying) { _ in
            if isPlaying {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func loadAudioDuration() {
        // Check if this is a remote URL
        let isRemoteURL = audioURL.scheme == "http" || audioURL.scheme == "https"
        
        if isRemoteURL {
            // For remote URLs, download temporarily to get duration
            Task {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let cacheFileName = audioURL.lastPathComponent.isEmpty ? audioURL.absoluteString.hash.description + ".m4a" : audioURL.lastPathComponent
                let cachedFileURL = documentsPath.appendingPathComponent("audio_cache_\(cacheFileName)")
                
                // Check cache first
                if FileManager.default.fileExists(atPath: cachedFileURL.path) {
                    await MainActor.run {
                        loadDurationFromURL(cachedFileURL)
                    }
                    return
                }
                
                // Download to get duration
                do {
                    let (data, _) = try await URLSession.shared.data(from: audioURL)
                    try data.write(to: cachedFileURL)
                    await MainActor.run {
                        loadDurationFromURL(cachedFileURL)
                    }
                } catch {
                    print("❌ Failed to load audio duration: \(error)")
                }
            }
        } else {
            // For local files
            if FileManager.default.fileExists(atPath: audioURL.path) {
                loadDurationFromURL(audioURL)
            }
        }
    }
    
    private func loadDurationFromURL(_ url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            totalDuration = player.duration
        } catch {
            print("❌ Failed to load audio duration: \(error)")
        }
    }
    
    private func generateWaveform() {
        // Generate random waveform heights if not already set
        if waveformHeights.isEmpty {
            waveformHeights = (0..<30).map { _ in
                CGFloat.random(in: 4...28)
            }
        }
    }
    
    private func waveformHeight(at index: Int) -> CGFloat {
        guard index < waveformHeights.count else { return 8 }
        
        if isPlaying {
            // Animate waveform during playback
            let baseHeight = waveformHeights[index]
            let variation = sin(animationPhase + Double(index) * 0.3) * 4
            return max(4, min(32, baseHeight + variation))
        } else {
            return waveformHeights[index]
        }
    }
    
    private func startAnimation() {
        // Animate waveform during playback
        let animation = Animation.linear(duration: 0.5).repeatForever(autoreverses: false)
        withAnimation(animation) {
            animationPhase += .pi * 2
        }
    }
    
    private func stopAnimation() {
        // Stop animation when playback stops
        withAnimation(.default) {
            animationPhase = 0
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        // Check if this is a remote URL (http/https)
        let isRemoteURL = audioURL.scheme == "http" || audioURL.scheme == "https"
        
        if isRemoteURL {
            // For remote URLs, download and play
            Task {
                await downloadAndPlayAudio(from: audioURL)
            }
        } else {
            // For local files, check if they exist
            guard FileManager.default.fileExists(atPath: audioURL.path) else {
                print("❌ Audio file does not exist at: \(audioURL.path)")
                return
            }
            playLocalAudio(at: audioURL)
        }
    }
    
    private func downloadAndPlayAudio(from url: URL) async {
        // Check cache first
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cacheFileName = url.lastPathComponent.isEmpty ? url.absoluteString.hash.description + ".m4a" : url.lastPathComponent
        let cachedFileURL = documentsPath.appendingPathComponent("audio_cache_\(cacheFileName)")
        
        // Use cached file if it exists
        if FileManager.default.fileExists(atPath: cachedFileURL.path) {
            await MainActor.run {
                playLocalAudio(at: cachedFileURL)
            }
            return
        }
        
        // Download the audio file
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Save to cache
            try data.write(to: cachedFileURL)
            
            // Play the downloaded file
            await MainActor.run {
                playLocalAudio(at: cachedFileURL)
            }
        } catch {
            await MainActor.run {
                print("❌ Failed to download audio: \(error.localizedDescription)")
                try? AVAudioSession.sharedInstance().setActive(false)
            }
        }
    }
    
    private func playLocalAudio(at url: URL) {
        // Configure audio session for playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            return
        }
        
        // Create and configure audio player
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            guard let player = audioPlayer else {
                print("❌ Failed to create audio player")
                return
            }
            
            // Update total duration if not already set
            if totalDuration == 0 {
                totalDuration = player.duration
            }
            
            // Prepare the player
            guard player.prepareToPlay() else {
                print("❌ Failed to prepare audio player")
                return
            }
            
            let delegate = PlaybackDelegate {
                Task { @MainActor in
                    isPlaying = false
                    currentTime = 0
                    playbackTimer?.invalidate()
                    playbackTimer = nil
                    // Deactivate audio session when done
                    try? AVAudioSession.sharedInstance().setActive(false)
                }
            }
            playbackDelegate = delegate
            player.delegate = delegate
            
            // Start playback
            guard player.play() else {
                print("❌ Failed to start audio playback")
                try? AVAudioSession.sharedInstance().setActive(false)
                return
            }
            
            isPlaying = true
            
            // Update current time and waveform animation
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                Task { @MainActor in
                    if let player = audioPlayer, player.isPlaying {
                        currentTime = player.currentTime
                        // Update duration display
                        totalDuration = player.duration
                        // Update animation phase for waveform
                        animationPhase += 0.3
                    } else {
                        isPlaying = false
                        currentTime = 0
                        playbackTimer?.invalidate()
                        playbackTimer = nil
                    }
                }
            }
        } catch {
            print("❌ Failed to play audio: \(error.localizedDescription)")
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
        currentTime = 0
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private class PlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

