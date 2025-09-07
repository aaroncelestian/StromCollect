import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Audio Recorder
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioData: Data?
    @Published var qualityMetrics: AudioQualityMetrics?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.record, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Error starting recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        if let url = audioRecorder?.url {
            do {
                audioData = try Data(contentsOf: url)
                qualityMetrics = validateAudioQuality(audioData!)
            } catch {
                print("Error reading audio data: \(error)")
            }
        }
    }
    
    private func validateAudioQuality(_ data: Data) -> AudioQualityMetrics {
        // Mock audio quality validation
        // In production, implement proper audio analysis
        let amplitude = Double.random(in: 0.3...1.0)
        let clarity = Double.random(in: 0.5...1.0)
        
        return AudioQualityMetrics(
            amplitude: amplitude,
            clarity: clarity,
            isAcceptable: amplitude > 0.4 && clarity > 0.6
        )
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}
