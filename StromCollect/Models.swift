import SwiftUI
import SwiftData
import Foundation

// MARK: - Data Models
enum StromatoliteType: String, CaseIterable, Identifiable {
    case columnar = "Columnar"
    case domal = "Domal"
    case stratiform = "Stratiform"
    case branching = "Branching"
    case conical = "Conical"
    case unknown = "Unknown"
    
    var id: String { self.rawValue }
}

enum CollectionWorkflowState: String, CaseIterable {
    case setup = "Setup Collection"
    case drawerOverview = "Drawer Overview"
    case specimenIdentification = "Specimen Identification"
    case specimenDocumentation = "Specimen Documentation"
    case fieldBookCapture = "Field Book Pages"
    case voiceAnnotation = "Voice Notes"
    case qualityReview = "Quality Review"
    case completion = "Complete"
}

struct QualityMetrics {
    let sharpness: Double
    let brightness: Double
    let isAcceptable: Bool
    let recommendations: [String]
}

struct OCRResult {
    let text: String
    let confidence: Float
    let needsVerification: Bool
}

struct AudioQualityMetrics {
    let amplitude: Double
    let clarity: Double
    let isAcceptable: Bool
}

// MARK: - SwiftData Model Classes
@Model
class SpecimenCollection {
    var id: UUID = UUID()
    var locality: String = ""
    var collectionDate: Date = Date()
    var collectorName: String = ""
    var drawerOverviewImageData: Data?
    var specimens: [SpecimenRecord] = []
    var isComplete: Bool = false
    var syncStatus: String = "local"
    
    init(locality: String = "", collectorName: String = "") {
        self.locality = locality
        self.collectorName = collectorName
    }
}

@Model
class SpecimenRecord {
    var id: UUID = UUID()
    var specimenID: String = ""
    var stromatoliteAge: String = ""
    var structureType: String = StromatoliteType.unknown.rawValue
    var specimenImageData: Data?
    var fieldBookImageData: Data?
    var voiceNoteData: Data?
    var ocrText: String = ""
    var ocrConfidence: Float = 0.0
    var notes: String = ""
    var isComplete: Bool = false
    var qualityScore: Double = 0.0
    
    init() {
        // SwiftData will handle initialization
    }
    
    var structureTypeEnum: StromatoliteType {
        get { StromatoliteType(rawValue: structureType) ?? .unknown }
        set { structureType = newValue.rawValue }
    }
}
