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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Collection Setup")
                .font(.largeTitle)
                .fontWeight(.bold)
            
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
        }
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
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .disabled(cameraController.isCapturing)
                    
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
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
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
