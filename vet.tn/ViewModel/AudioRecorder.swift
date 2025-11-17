//
//  AudioRecorder.swift
//  vet.tn
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

@MainActor
final class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioURL: URL?
    @Published var error: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingSession: AVAudioSession?
    
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func startRecording() async {
        // Request permission first
        let hasPermission = await requestPermission()
        guard hasPermission else {
            error = "Microphone permission denied"
            return
        }
        
        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            self.recordingSession = session
        } catch {
            self.error = "Failed to setup audio recording: \(error.localizedDescription)"
            return
        }
        
        // Create temporary file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
        self.audioURL = audioFilename
        
        // Audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        // Start recording
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            error = nil
            
            // Start timer to update recording time
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recordingTime += 0.1
                }
            }
        } catch {
            self.error = "Failed to start recording: \(error.localizedDescription)"
            self.audioURL = nil
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        recordingSession = nil
        
        return audioURL
    }
    
    func cancelRecording() {
        stopRecording()
        
        // Delete the recording file
        if let url = audioURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        audioURL = nil
        recordingTime = 0
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

