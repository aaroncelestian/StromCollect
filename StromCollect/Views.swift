import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Progress Indicator
struct ProgressIndicatorView: View {
    let currentState: CollectionWorkflowState
    
    var body: some View {
        let states = CollectionWorkflowState.allCases
        let currentIndex = states.firstIndex(of: currentState) ?? 0
        let progress = Double(currentIndex) / Double(states.count - 1)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(currentIndex + 1) of \(states.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text(currentState.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Setup View
struct SetupView: View {
    @ObservedObject var workflowController: WorkflowController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var cameraController = SpecimenCameraController()
    @State private var showingPermissionAlert = false
    @State private var permissionMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if horizontalSizeClass != .regular {
                    Text("Collection Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                if horizontalSizeClass == .regular {
                    // iPad layout - use a form-style layout with more space
                    VStack(spacing: 24) {
                        FormSection(title: "Collection Information") {
                            VStack(spacing: 16) {
                                FormField(title: "Locality/Location", icon: "location") {
                                    TextField("Enter collection locality", text: $workflowController.collection.locality)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                FormField(title: "Collector Name", icon: "person") {
                                    TextField("Enter collector name", text: $workflowController.collection.collectorName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                FormField(title: "Collection Date", icon: "calendar") {
                                    DatePicker("", selection: $workflowController.collection.collectionDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                }
                            }
                        }
                        
                        InstructionCard(
                            title: "Setup Instructions",
                            content: "Enter the basic information for this collection session. Make sure the locality and collector name are accurate as they will be included in all specimen records."
                        )
                        
                        Button(action: {
                            requestPermissions()
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Image(systemName: "mic")
                                Text("Request Camera & Microphone Access")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: 600)
                } else {
                    // iPhone layout - compact form
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Locality/Location")
                                .font(.headline)
                            TextField("Enter collection locality", text: $workflowController.collection.locality)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Collector Name")
                                .font(.headline)
                            TextField("Enter collector name", text: $workflowController.collection.collectorName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Collection Date")
                                .font(.headline)
                            DatePicker("", selection: $workflowController.collection.collectionDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Text("Enter the basic information for this collection session. Make sure the locality and collector name are accurate as they will be included in all specimen records.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        requestPermissions()
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Image(systemName: "mic")
                            Text("Request Camera & Microphone Access")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .alert("Permissions", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(permissionMessage)
        }
    }
    
    private func requestPermissions() {
        cameraController.requestAllPermissions { cameraGranted, micGranted in
            var messages: [String] = []
            
            if !cameraGranted {
                messages.append("Camera access is required for photographing specimens")
            }
            
            if !micGranted {
                messages.append("Microphone access is required for voice annotations")
            }
            
            if !messages.isEmpty {
                permissionMessage = messages.joined(separator: "\n\n") + "\n\nYou can enable these permissions in Settings."
                showingPermissionAlert = true
            } else {
                permissionMessage = "All permissions granted! You can now use the camera and microphone features."
                showingPermissionAlert = true
            }
        }
    }
}

// MARK: - Reusable Components
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            content
        }
        .padding(24)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FormField<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
    }
}

struct InstructionCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Drawer Overview View
struct DrawerOverviewView: View {
    @ObservedObject var workflowController: WorkflowController
    @StateObject private var cameraController = SpecimenCameraController()
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Drawer Overview")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let imageData = workflowController.collection.drawerOverviewImageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                
                if let qualityMetrics = cameraController.qualityMetrics {
                    QualityIndicatorView(metrics: qualityMetrics)
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "camera")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Take drawer overview photo")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            Button(action: {
                showingCamera = true
            }) {
                Label("Take Overview Photo", systemImage: "camera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            Text("Take a clear overview photo of the entire drawer showing all specimens and their arrangement.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(cameraController: cameraController) { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    workflowController.collection.drawerOverviewImageData = imageData
                }
                showingCamera = false
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: View {
    @ObservedObject var cameraController: SpecimenCameraController
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            CameraPreview(cameraController: cameraController)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    
                    if cameraController.canSwitchCamera {
                        Button(action: {
                            cameraController.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing)
                    }
                }
                .padding(.top, 50)
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        cameraController.capturePhoto()
                    }) {
                        Circle()
                            .fill(cameraController.isSessionReady ? Color.white : Color.gray)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .disabled(cameraController.isCapturing || !cameraController.isSessionReady)
                    
                    Spacer()
                    
                    Button("Retake") {
                        cameraController.capturedImage = nil
                    }
                    .foregroundColor(.white)
                    .padding()
                    .opacity(cameraController.capturedImage != nil ? 1 : 0)
                }
                .padding(.bottom, 50)
            }
            
            if let image = cameraController.capturedImage {
                VStack {
                    HStack {
                        Button("Use Photo") {
                            onImageCaptured(image)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        
                        Button("Retake") {
                            cameraController.capturedImage = nil
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            cameraController.startSession()
        }
        .onDisappear {
            cameraController.stopSession()
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let cameraController: SpecimenCameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraController.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Quality Indicator View
struct QualityIndicatorView: View {
    let metrics: QualityMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metrics.isAcceptable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(metrics.isAcceptable ? .green : .orange)
                Text("Quality: \(metrics.isAcceptable ? "Good" : "Needs Attention")")
                    .font(.headline)
            }
            
            if !metrics.recommendations.isEmpty {
                ForEach(metrics.recommendations, id: \.self) { recommendation in
                    Text("• \(recommendation)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Navigation Controls
struct NavigationControlsView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        HStack {
            Button("Previous") {
                workflowController.progressToPrevious()
            }
            .disabled(workflowController.currentState == .setup)
            
            Spacer()
            
            Button("Next") {
                workflowController.progressToNext()
            }
            .disabled(!workflowController.validateCurrentStep())
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - iPad-Optimized Views
struct WorkflowSidebarView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        List {
            Section("Collection Progress") {
                ForEach(CollectionWorkflowState.allCases, id: \.self) { state in
                    HStack {
                        Image(systemName: iconForState(state))
                            .foregroundColor(workflowController.currentState == state ? .blue : .secondary)
                        
                        VStack(alignment: .leading) {
                            Text(state.rawValue)
                                .font(.headline)
                            if state == workflowController.currentState {
                                Text("Current Step")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        if isStateCompleted(state) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        workflowController.jumpToState(state)
                    }
                }
            }
            
            Section("Collection Info") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Locality", systemImage: "location")
                    Text(workflowController.collection.locality.isEmpty ? "Not set" : workflowController.collection.locality)
                        .foregroundColor(.secondary)
                    
                    Label("Collector", systemImage: "person")
                    Text(workflowController.collection.collectorName.isEmpty ? "Not set" : workflowController.collection.collectorName)
                        .foregroundColor(.secondary)
                    
                    Label("Date", systemImage: "calendar")
                    Text(workflowController.collection.collectionDate, style: .date)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Workflow")
        .frame(minWidth: 300)
    }
    
    private func iconForState(_ state: CollectionWorkflowState) -> String {
        switch state {
        case .setup: return "gear"
        case .drawerOverview: return "photo.on.rectangle"
        case .specimenIdentification: return "magnifyingglass"
        case .specimenDocumentation: return "camera"
        case .fieldBookCapture: return "book"
        case .voiceAnnotation: return "mic"
        case .qualityReview: return "checkmark.seal"
        case .completion: return "flag.checkered"
        }
    }
    
    private func isStateCompleted(_ state: CollectionWorkflowState) -> Bool {
        let currentIndex = CollectionWorkflowState.allCases.firstIndex(of: workflowController.currentState) ?? 0
        let stateIndex = CollectionWorkflowState.allCases.firstIndex(of: state) ?? 0
        return stateIndex < currentIndex
    }
}

struct WorkflowDetailView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        VStack {
            WorkflowContentView(workflowController: workflowController)
            
            Spacer()
            
            NavigationControlsView(workflowController: workflowController)
                .padding()
        }
        .navigationTitle(workflowController.currentState.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WorkflowContentView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        switch workflowController.currentState {
        case .setup:
            SetupView(workflowController: workflowController)
        case .drawerOverview:
            DrawerOverviewView(workflowController: workflowController)
        case .specimenIdentification:
            SpecimenIdentificationView(workflowController: workflowController)
        case .specimenDocumentation:
            SpecimenDocumentationView(workflowController: workflowController)
        case .fieldBookCapture:
            FieldBookCaptureView(workflowController: workflowController)
        case .voiceAnnotation:
            VoiceAnnotationView(workflowController: workflowController)
        case .qualityReview:
            QualityReviewView(workflowController: workflowController)
        case .completion:
            CompletionView(workflowController: workflowController)
        }
    }
}

// MARK: - Placeholder Views (to be implemented)
struct SpecimenIdentificationView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        Text("Specimen Identification - Coming Soon")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

struct SpecimenDocumentationView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        Text("Specimen Documentation - Coming Soon")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

struct FieldBookCaptureView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        Text("Field Book Capture - Coming Soon")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

struct VoiceAnnotationView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        Text("Voice Annotation - Coming Soon")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

struct QualityReviewView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        Text("Quality Review - Coming Soon")
            .font(.title)
            .foregroundColor(.secondary)
    }
}

struct CompletionView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
        Text("Collection Complete!")
            .font(.title)
            .foregroundColor(.green)
    }
}
