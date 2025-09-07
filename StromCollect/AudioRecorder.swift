import SwiftUI
import SwiftData
import AVFoundation
import Speech

// MARK: - Audio Recorder with Speech Recognition
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioData: Data?
    @Published var qualityMetrics: AudioQualityMetrics?
    @Published var transcribedText = ""
    @Published var isTranscribing = false
    @Published var speechRecognitionAvailable = false
    @Published var speechPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        setupAudioSession()
        setupSpeechRecognition()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession?.setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognitionAvailable = speechRecognizer?.isAvailable ?? false
        speechPermissionStatus = SFSpeechRecognizer.authorizationStatus()
        
        // Don't automatically request permission on init - wait for user action
        // This prevents crashes when the app launches
    }
    
    func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.speechPermissionStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    func startRecording() {
        // Clear previous transcription
        transcribedText = ""
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            
            // Start real-time speech recognition if available
            if speechPermissionStatus == .authorized && speechRecognitionAvailable {
                startSpeechRecognition()
            }
        } catch {
            print("Error starting recording: \(error)")
        }
    }
    
    private func startSpeechRecognition() {
        // Cancel any previous recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }
        
        do {
            // Configure the audio session for recognition
            try audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                print("Unable to create recognition request")
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // Configure audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isTranscribing = true
            
            // Start recognition task
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        self?.transcribedText = result.bestTranscription.formattedString
                    }
                    
                    if error != nil || result?.isFinal == true {
                        self?.stopSpeechRecognition()
                    }
                }
            }
        } catch {
            print("Error starting speech recognition: \(error)")
            stopSpeechRecognition()
        }
    }
    
    private func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        stopSpeechRecognition()
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
    
    func getTranscribedText() -> String {
        return transcribedText
    }
    
    func clearTranscription() {
        transcribedText = ""
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
