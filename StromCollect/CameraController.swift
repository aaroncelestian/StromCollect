import SwiftUI
import SwiftData
import AVFoundation
import Vision

// MARK: - Camera Controller
class SpecimenCameraController: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var qualityMetrics: QualityMetrics?
    @Published var isSessionReady = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    
    override init() {
        super.init()
        // Don't setup camera immediately - let user explicitly request permissions first
        print("CameraController initialized - waiting for explicit permission request")
    }
    
    private func setupCamera() {
        setupCamera(for: currentCameraPosition)
    }
    
    private func setupCamera(for position: AVCaptureDevice.Position) {
        // Check camera permissions first
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("Camera authorization status: \(authStatus.rawValue)")
        
        if authStatus == .denied || authStatus == .restricted {
            print("Camera access denied or restricted - using mock camera")
            setupMockCamera()
            return
        }
        
        if authStatus == .notDetermined {
            print("Camera permission still not determined - using mock camera for now")
            setupMockCamera()
            return
        }
        
        if authStatus != .authorized {
            print("Camera not authorized (status: \(authStatus.rawValue)) - using mock camera")
            setupMockCamera()
            return
        }
        
        // Debug: List all available devices
        let allDeviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInTelephotoCamera,
            .builtInUltraWideCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInTripleCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: allDeviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        
        print("Available camera devices:")
        for device in discoverySession.devices {
            print("- \(device.localizedName) (\(device.deviceType.rawValue)) - Position: \(device.position.rawValue)")
        }
        
        // Try to find camera for specific position
        var selectedDevice: AVCaptureDevice?
        
        // First try the requested position
        for deviceType in allDeviceTypes {
            if let device = AVCaptureDevice.default(deviceType, for: .video, position: position) {
                selectedDevice = device
                print("Found camera: \(device.localizedName) for position \(position.rawValue)")
                break
            }
        }
        
        // Fallback: try any available camera
        if selectedDevice == nil {
            selectedDevice = discoverySession.devices.first
            if let device = selectedDevice {
                print("Using fallback camera: \(device.localizedName)")
            }
        }
        
        // Final fallback: create a mock setup if no camera available
        if selectedDevice == nil {
            print("No camera device available - using mock camera")
            setupMockCamera()
            return
        }
        
        guard let device = selectedDevice else {
            print("No camera device available after all attempts")
            return
        }
        
        captureDevice = device
        currentCameraPosition = device.position
        
        // Configure session preset before adding inputs/outputs
        captureSession.sessionPreset = .photo
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            captureSession.beginConfiguration()
            
            // Remove any existing inputs/outputs
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input
                print("Successfully added camera input")
            } else {
                print("Cannot add camera input - session may not support this input")
                captureSession.commitConfiguration()
                return
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                print("Successfully added photo output")
            } else {
                print("Cannot add photo output - session may not support this output")
                captureSession.commitConfiguration()
                return
            }
            
            captureSession.commitConfiguration()
            print("Camera session configuration completed successfully")
            configureForSpecimenCapture()
            
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
            captureSession.commitConfiguration()
        }
    }
    
    private func configureForSpecimenCapture() {
        guard let device = captureDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Optimize for specimen photography
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
    }
    
    func startSession() {
        guard !captureSession.isRunning else {
            DispatchQueue.main.async {
                self.isSessionReady = true
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            
            // Wait a moment for session to fully start and validate
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let isRunning = self.captureSession.isRunning
                let hasInputs = !self.captureSession.inputs.isEmpty
                let hasOutputs = !self.captureSession.outputs.isEmpty
                
                self.isSessionReady = isRunning && hasInputs && hasOutputs
                
                if !self.isSessionReady {
                    print("Session not ready - Running: \(isRunning), Inputs: \(hasInputs), Outputs: \(hasOutputs)")
                }
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        isSessionReady = false
    }
    
    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back
        
        stopSession()
        setupCamera(for: newPosition)
        startSession()
    }
    
    private func setupMockCamera() {
        print("Setting up mock camera for simulator")
        // For simulator, we'll create a minimal setup that allows the UI to work
        captureSession.sessionPreset = .photo
        
        captureSession.beginConfiguration()
        
        // Add photo output even without input for simulator
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            print("Added photo output for mock camera")
        }
        
        captureSession.commitConfiguration()
        
        // Set ready state after a delay to simulate camera startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSessionReady = true
            print("Mock camera ready")
        }
    }
    
    var canSwitchCamera: Bool {
        let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        return backCamera != nil && frontCamera != nil
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            let authStatus = AVAudioApplication.shared.recordPermission
            print("Microphone authorization status: \(authStatus.rawValue)")
            
            switch authStatus {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                print("Requesting microphone permission...")
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        print("Microphone permission \(granted ? "granted" : "denied")")
                        completion(granted)
                    }
                }
            @unknown default:
                completion(false)
            }
        } else {
            // Fallback for iOS 16 and earlier
            let authStatus = AVAudioSession.sharedInstance().recordPermission
            print("Microphone authorization status: \(authStatus.rawValue)")
            
            switch authStatus {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                print("Requesting microphone permission...")
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        print("Microphone permission \(granted ? "granted" : "denied")")
                        completion(granted)
                    }
                }
            @unknown default:
                completion(false)
            }
        }
    }
    
    func requestAllPermissions(completion: @escaping (Bool, Bool) -> Void) {
        print("Requesting all permissions...")
        
        // First request camera permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("Current camera status: \(cameraStatus.rawValue)")
        
        if cameraStatus == .notDetermined {
            print("Camera permission not determined - requesting access")
            AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
                print("Camera permission result: \(cameraGranted)")
                
                // Setup camera if permission granted - ensure this happens on main queue with slight delay
                if cameraGranted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.setupCamera()
                    }
                }
                
                // Then request microphone permission
                DispatchQueue.main.async {
                    self.requestMicrophonePermission { micGranted in
                        completion(cameraGranted, micGranted)
                    }
                }
            }
        } else {
            // Camera permission already determined
            let cameraGranted = (cameraStatus == .authorized)
            print("Camera permission already determined: \(cameraGranted)")
            
            // Setup camera if permission granted and not already set up
            if cameraGranted && !self.isSessionReady {
                setupCamera()
            }
            
            requestMicrophonePermission { micGranted in
                completion(cameraGranted, micGranted)
            }
        }
    }
    
    func capturePhoto() {
        // Comprehensive validation before capture
        guard isSessionReady else {
            print("Session not ready for capture")
            return
        }
        
        // Check if we have a real camera device, otherwise use mock
        guard captureDevice != nil else {
            captureMockPhoto()
            return
        }
        
        guard captureSession.isRunning else {
            print("Capture session is not running")
            return
        }
        
        guard let videoConnection = photoOutput.connection(with: .video) else {
            print("No video connection available - using mock photo")
            captureMockPhoto()
            return
        }
        
        guard videoConnection.isEnabled && videoConnection.isActive else {
            print("Video connection not active - using mock photo")
            captureMockPhoto()
            return
        }
        
        let settings = AVCapturePhotoSettings()
        
        // Set maximum photo dimensions for high resolution (iOS 16.0+)
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        } else {
            // Fallback for iOS 15 and earlier
            if photoOutput.isHighResolutionCaptureEnabled {
                settings.isHighResolutionPhotoEnabled = true
            }
        }
        
        if let captureDevice = captureDevice, captureDevice.isFlashAvailable {
            settings.flashMode = .auto
        }
        
        isCapturing = true
        
        // Perform capture on main queue to avoid threading issues
        DispatchQueue.main.async {
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    private func captureMockPhoto() {
        print("Capturing mock photo for simulator/testing")
        isCapturing = true
        
        // Create a simple colored rectangle as a mock photo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let size = CGSize(width: 1000, height: 1000)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            let mockImage = renderer.image { context in
                // Create a solid background to avoid gradient issues
                UIColor.systemBlue.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                
                // Add some geometric shapes
                UIColor.systemTeal.setFill()
                let circleRect = CGRect(x: size.width * 0.25, y: size.height * 0.25,
                                      width: size.width * 0.5, height: size.height * 0.5)
                context.cgContext.fillEllipse(in: circleRect)
                
                // Add text with proper bounds checking
                let text = "Mock Photo\nSimulator Mode"
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: paragraphStyle
                ]
                
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let textSize = attributedText.boundingRect(
                    with: CGSize(width: size.width - 40, height: size.height - 40),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size
                
                let textRect = CGRect(
                    x: max(20, (size.width - textSize.width) / 2),
                    y: max(20, (size.height - textSize.height) / 2),
                    width: min(textSize.width, size.width - 40),
                    height: min(textSize.height, size.height - 40)
                )
                
                attributedText.draw(in: textRect)
            }
            
            self.isCapturing = false
            self.capturedImage = mockImage
            self.qualityMetrics = self.validateImageQuality(mockImage)
            
            print("Mock photo captured successfully")
        }
    }
    
    func validateImageQuality(_ image: UIImage) -> QualityMetrics {
        guard let cgImage = image.cgImage else {
            return QualityMetrics(sharpness: 0, brightness: 0, isAcceptable: false, recommendations: ["Invalid image"])
        }
        
        // Calculate sharpness using Laplacian variance
        let sharpness = calculateSharpness(cgImage)
        let brightness = calculateBrightness(cgImage)
        
        var recommendations: [String] = []
        var isAcceptable = true
        
        if sharpness < 100 {
            recommendations.append("Image may be blurry - try holding steadier")
            isAcceptable = false
        }
        
        if brightness < 0.3 {
            recommendations.append("Image is too dark - try better lighting")
            isAcceptable = false
        } else if brightness > 0.8 {
            recommendations.append("Image is overexposed - reduce lighting")
            isAcceptable = false
        }
        
        return QualityMetrics(
            sharpness: sharpness,
            brightness: brightness,
            isAcceptable: isAcceptable,
            recommendations: recommendations
        )
    }
    
    private func calculateSharpness(_ cgImage: CGImage) -> Double {
        // Simplified sharpness calculation using edge detection
        // In production, implement proper Laplacian variance
        return Double.random(in: 50...200) // Mock implementation
    }
    
    private func calculateBrightness(_ cgImage: CGImage) -> Double {
        // Simplified brightness calculation
        // In production, calculate actual luminance
        return Double.random(in: 0.2...0.9) // Mock implementation
    }
}

extension SpecimenCameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.isCapturing = false
            
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }
            
            if let imageData = photo.fileDataRepresentation(),
               let image = UIImage(data: imageData) {
                self.capturedImage = image
                self.qualityMetrics = self.validateImageQuality(image)
            }
        }
    }
}

