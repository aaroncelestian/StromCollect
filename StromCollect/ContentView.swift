import SwiftUI
import SwiftData

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var workflowController = WorkflowController()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad layout with sidebar navigation
            NavigationSplitView {
                WorkflowSidebarView(workflowController: workflowController)
            } detail: {
                WorkflowDetailView(workflowController: workflowController)
            }
        } else {
            // iPhone layout with traditional navigation
            NavigationView {
                VStack {
                    // Progress indicator
                    ProgressIndicatorView(currentState: workflowController.currentState)
                    
                    // Main content area
                    WorkflowContentView(workflowController: workflowController)
                    
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
}
