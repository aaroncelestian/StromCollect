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

enum MineralogyType: String, CaseIterable, Identifiable {
    case quartz = "Quartz"
    case calcite = "Calcite"
    case dolomite = "Dolomite"
    case ironOxide = "Iron Oxide"
    case mixture = "Mixture"
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
    var specimenID: String = "" // Specimen ID/label
    var stromatoliteAge: String = "" // Age in Mya
    var structureType: String = StromatoliteType.unknown.rawValue
    
    // Locality information
    var localityCountry: String = ""
    var localityStateProvince: String = ""
    var localityNearestCity: String = ""
    var latitude: Double? = nil
    var longitude: Double? = nil
    
    // Mineralogy
    var mineralogy: String = MineralogyType.unknown.rawValue
    
    // Additional notes
    var additionalNotes: String = ""
    
    var specimenImageData: Data? // Legacy - kept for backward compatibility
    @Attribute(.externalStorage) var specimenImages: [Data] = [] // New multi-photo storage
    var fieldBookImageData: Data? // Legacy - kept for backward compatibility
    @Attribute(.externalStorage) var fieldBookImages: [Data] = [] // New multi-photo storage for field book pages
    var voiceNoteData: Data?
    var voiceNoteTranscription: String = "" // Transcribed text from voice notes
    var ocrText: String = ""
    var ocrConfidence: Float = 0.0
    var notes: String = "" // Legacy notes field - kept for backward compatibility
    var isComplete: Bool = false
    var qualityScore: Double = 0.0
    
    init() {
        // SwiftData will handle initialization
    }
    
    var structureTypeEnum: StromatoliteType {
        get { StromatoliteType(rawValue: structureType) ?? .unknown }
        set { structureType = newValue.rawValue }
    }
    
    var mineralogyEnum: MineralogyType {
        get { MineralogyType(rawValue: mineralogy) ?? .unknown }
        set { mineralogy = newValue.rawValue }
    }
    
    // Computed property for full locality description
    var fullLocality: String {
        let components = [localityNearestCity, localityStateProvince, localityCountry].filter { !$0.isEmpty }
        return components.joined(separator: ", ")
    }
    
    // Computed property for coordinate display
    var coordinateString: String {
        guard let lat = latitude, let lon = longitude else { return "No coordinates" }
        return String(format: "%.6f, %.6f", lat, lon)
    }
    
    // Helper methods for managing multiple photos
    func addSpecimenImage(_ imageData: Data) {
        if specimenImages.count < 5 {
            specimenImages.append(imageData)
        }
    }
    
    func removeSpecimenImage(at index: Int) {
        if index >= 0 && index < specimenImages.count {
            specimenImages.remove(at: index)
        }
    }
    
    func replaceSpecimenImage(at index: Int, with imageData: Data) {
        if index >= 0 && index < specimenImages.count {
            specimenImages[index] = imageData
        }
    }
    
    var canAddMoreImages: Bool {
        return specimenImages.count < 5
    }
    
    var hasSpecimenImages: Bool {
        return !specimenImages.isEmpty || specimenImageData != nil
    }
    
    // Helper methods for managing field book photos
    func addFieldBookImage(_ imageData: Data) {
        fieldBookImages.append(imageData)
    }
    
    func removeFieldBookImage(at index: Int) {
        if index >= 0 && index < fieldBookImages.count {
            fieldBookImages.remove(at: index)
        }
    }
    
    func replaceFieldBookImage(at index: Int, with imageData: Data) {
        if index >= 0 && index < fieldBookImages.count {
            fieldBookImages[index] = imageData
        }
    }
    
    var hasFieldBookImages: Bool {
        return !fieldBookImages.isEmpty || fieldBookImageData != nil
    }
    
    // Helper methods for managing voice notes
    func setVoiceNote(audioData: Data, transcription: String) {
        voiceNoteData = audioData
        voiceNoteTranscription = transcription
    }
    
    func clearVoiceNote() {
        voiceNoteData = nil
        voiceNoteTranscription = ""
    }
    
    var hasVoiceNote: Bool {
        return voiceNoteData != nil
    }
    
    var voiceNotePreview: String {
        if voiceNoteTranscription.isEmpty {
            return hasVoiceNote ? "Audio recorded (no transcription)" : "No voice note"
        }
        return String(voiceNoteTranscription.prefix(100)) + (voiceNoteTranscription.count > 100 ? "..." : "")
    }
}
