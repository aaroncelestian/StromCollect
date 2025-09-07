import SwiftUI
import SwiftData

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var workflowController = WorkflowController()
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressIndicatorView(currentState: workflowController.currentState)
                
                // Main content area
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
                
                Spacer()
                
                // Navigation controls
                NavigationControlsView(workflowController: workflowController)
            }
            .padding()
            .navigationTitle("Stromatolite Collector")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
