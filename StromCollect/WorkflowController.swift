import SwiftUI
import SwiftData

// MARK: - Workflow Controller
class WorkflowController: ObservableObject {
    @Published var currentState: CollectionWorkflowState = .setup
    @Published var collection: SpecimenCollection = SpecimenCollection()
    @Published var currentSpecimen: SpecimenRecord?
    @Published var specimenIndex: Int = 0
    @Published var validationResults: [String] = []
    
    func progressToNext() {
        let states = CollectionWorkflowState.allCases
        if let currentIndex = states.firstIndex(of: currentState),
           currentIndex < states.count - 1 {
            currentState = states[currentIndex + 1]
        }
    }
    
    func progressToPrevious() {
        let states = CollectionWorkflowState.allCases
        if let currentIndex = states.firstIndex(of: currentState),
           currentIndex > 0 {
            currentState = states[currentIndex - 1]
        }
    }
    
    func startNewSpecimen() {
        let newSpecimen = SpecimenRecord()
        collection.specimens.append(newSpecimen)
        currentSpecimen = newSpecimen
        specimenIndex = collection.specimens.count - 1
        currentState = .specimenDocumentation
    }
    
    func validateCurrentStep() -> Bool {
        switch currentState {
        case .setup:
            return !collection.locality.isEmpty && !collection.collectorName.isEmpty
        case .drawerOverview:
            return collection.drawerOverviewImageData != nil
        case .specimenDocumentation:
            return currentSpecimen?.specimenImageData != nil && !(currentSpecimen?.specimenID.isEmpty ?? true)
        case .qualityReview:
            return collection.specimens.allSatisfy { $0.qualityScore > 0.5 }
        default:
            return true
        }
    }
}
