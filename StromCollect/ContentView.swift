import SwiftUI
import SwiftData

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var workflowController = WorkflowController()
    @StateObject private var collectionManager = CollectionManager()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if collectionManager.needsNewCollection {
                // Show collection selection/creation screen
                CollectionSelectionView(
                    collectionManager: collectionManager,
                    workflowController: workflowController
                )
            } else {
                // Show main workflow interface
                if horizontalSizeClass == .regular {
                    // iPad layout with sidebar navigation - always show sidebar
                    NavigationSplitView {
                        WorkflowSidebarView(
                            workflowController: workflowController,
                            collectionManager: collectionManager
                        )
                    } detail: {
                        WorkflowDetailView(workflowController: workflowController, collectionManager: collectionManager)
                    }
                    .navigationSplitViewStyle(.prominentDetail)
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
                            NavigationControlsView(
                                workflowController: workflowController,
                                collectionManager: collectionManager
                            )
                        }
                        .padding()
                        .navigationTitle("Stromatolite Collector")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Collections") {
                                    // Reset to show collection selection
                                    collectionManager.currentCollection = nil
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            collectionManager.setModelContext(modelContext)
        }
    }
}
