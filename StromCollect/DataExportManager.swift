import Foundation
import SwiftData
import UIKit

// MARK: - Export Data Structures
struct ExportableCollection: Codable {
    let id: String
    let locality: String
    let collectionDate: String
    let collectorName: String
    let isComplete: Bool
    let specimens: [ExportableSpecimen]
    let drawerOverviewImageFilename: String?
    let exportDate: String
    let exportVersion: String
    
    init(from collection: SpecimenCollection) {
        self.id = collection.id.uuidString
        self.locality = collection.locality
        self.collectionDate = ISO8601DateFormatter().string(from: collection.collectionDate)
        self.collectorName = collection.collectorName
        self.isComplete = collection.isComplete
        self.specimens = collection.specimens.map { ExportableSpecimen(from: $0) }
        self.drawerOverviewImageFilename = collection.drawerOverviewImageData != nil ? "drawer_overview_\(collection.id.uuidString).jpg" : nil
        self.exportDate = ISO8601DateFormatter().string(from: Date())
        self.exportVersion = "1.0"
    }
}

struct ExportableSpecimen: Codable {
    let id: String
    let specimenID: String
    let stromatoliteAge: String
    let structureType: String
    let ocrText: String
    let ocrConfidence: Float
    let notes: String
    let isComplete: Bool
    let qualityScore: Double
    let specimenImageFilenames: [String] // Multiple photos
    let fieldBookImageFilenames: [String] // Multiple field book pages
    let fieldBookImageFilename: String? // Legacy single field book image
    let voiceNoteFilename: String?
    let voiceNoteTranscription: String // Transcribed text for searching
    
    init(from specimen: SpecimenRecord) {
        self.id = specimen.id.uuidString
        self.specimenID = specimen.specimenID
        self.stromatoliteAge = specimen.stromatoliteAge
        self.structureType = specimen.structureType
        self.ocrText = specimen.ocrText
        self.ocrConfidence = specimen.ocrConfidence
        self.notes = specimen.notes
        self.isComplete = specimen.isComplete
        self.qualityScore = specimen.qualityScore
        
        // Handle multiple specimen images
        var imageFilenames: [String] = []
        for (index, _) in specimen.specimenImages.enumerated() {
            imageFilenames.append("specimen_\(specimen.id.uuidString)_\(index + 1).jpg")
        }
        // Legacy support for single image
        if let _ = specimen.specimenImageData, imageFilenames.isEmpty {
            imageFilenames.append("specimen_\(specimen.id.uuidString).jpg")
        }
        self.specimenImageFilenames = imageFilenames
        
        // Handle multiple field book images
        var fieldBookFilenames: [String] = []
        for (index, _) in specimen.fieldBookImages.enumerated() {
            fieldBookFilenames.append("fieldbook_\(specimen.id.uuidString)_\(index + 1).jpg")
        }
        self.fieldBookImageFilenames = fieldBookFilenames
        
        // Legacy support for single field book image
        self.fieldBookImageFilename = specimen.fieldBookImageData != nil ? "fieldbook_\(specimen.id.uuidString).jpg" : nil
        self.voiceNoteFilename = specimen.voiceNoteData != nil ? "voice_\(specimen.id.uuidString).m4a" : nil
        self.voiceNoteTranscription = specimen.voiceNoteTranscription
    }
}

// MARK: - Export Result
struct ExportResult {
    let success: Bool
    let exportPath: URL?
    let error: String?
    let filesExported: Int
    let totalSize: Int64
}

// MARK: - Data Export Manager
class DataExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastExportResult: ExportResult?
    
    private let fileManager = FileManager.default
    
    /// Export a single collection to the Documents directory
    func exportCollection(_ collection: SpecimenCollection) async -> ExportResult {
        await MainActor.run {
            isExporting = true
            exportProgress = 0.0
        }
        
        do {
            // Create export directory
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let exportFolderName = "StromCollect_Export_\(collection.locality.replacingOccurrences(of: " ", with: "_"))_\(formatDateForFilename(collection.collectionDate))"
            let exportURL = documentsURL.appendingPathComponent(exportFolderName)
            
            // Remove existing export if it exists
            if fileManager.fileExists(atPath: exportURL.path) {
                try fileManager.removeItem(at: exportURL)
            }
            
            try fileManager.createDirectory(at: exportURL, withIntermediateDirectories: true)
            
            await MainActor.run { exportProgress = 0.1 }
            
            // Create subdirectories
            let imagesURL = exportURL.appendingPathComponent("images")
            let audioURL = exportURL.appendingPathComponent("audio")
            try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: audioURL, withIntermediateDirectories: true)
            
            await MainActor.run { exportProgress = 0.2 }
            
            var filesExported = 0
            var totalSize: Int64 = 0
            
            // Export drawer overview image if exists
            if let drawerImageData = collection.drawerOverviewImageData {
                let filename = "drawer_overview_\(collection.id.uuidString).jpg"
                let imageURL = imagesURL.appendingPathComponent(filename)
                try drawerImageData.write(to: imageURL)
                filesExported += 1
                totalSize += Int64(drawerImageData.count)
            }
            
            await MainActor.run { exportProgress = 0.3 }
            
            // Export specimen files
            let totalSpecimens = collection.specimens.count
            for (index, specimen) in collection.specimens.enumerated() {
                // Export multiple specimen images
                for (imageIndex, imageData) in specimen.specimenImages.enumerated() {
                    let filename = "specimen_\(specimen.id.uuidString)_\(imageIndex + 1).jpg"
                    let imageURL = imagesURL.appendingPathComponent(filename)
                    try imageData.write(to: imageURL)
                    filesExported += 1
                    totalSize += Int64(imageData.count)
                }
                
                // Legacy support: Export single specimen image if exists and no multiple images
                if let imageData = specimen.specimenImageData, specimen.specimenImages.isEmpty {
                    let filename = "specimen_\(specimen.id.uuidString).jpg"
                    let imageURL = imagesURL.appendingPathComponent(filename)
                    try imageData.write(to: imageURL)
                    filesExported += 1
                    totalSize += Int64(imageData.count)
                }
                
                // Export field book images (multiple pages)
                if !specimen.fieldBookImages.isEmpty {
                    for (index, imageData) in specimen.fieldBookImages.enumerated() {
                        if let image = UIImage(data: imageData) {
                            let filename = "fieldbook_\(specimen.id.uuidString)_\(index + 1).jpg"
                            let imageURL = imagesURL.appendingPathComponent(filename)
                            
                            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                                try jpegData.write(to: imageURL)
                                filesExported += 1
                                totalSize += Int64(jpegData.count)
                            }
                        }
                    }
                } else if let fieldBookImageData = specimen.fieldBookImageData,
                          let fieldBookImage = UIImage(data: fieldBookImageData) {
                    // Legacy single field book image support
                    let fieldBookFilename = "fieldbook_\(specimen.id.uuidString).jpg"
                    let fieldBookURL = imagesURL.appendingPathComponent(fieldBookFilename)
                    
                    if let jpegData = fieldBookImage.jpegData(compressionQuality: 0.8) {
                        try jpegData.write(to: fieldBookURL)
                        filesExported += 1
                        totalSize += Int64(jpegData.count)
                    }
                }
                
                // Export voice note
                if let voiceData = specimen.voiceNoteData {
                    let filename = "voice_\(specimen.id.uuidString).m4a"
                    let voiceURL = audioURL.appendingPathComponent(filename)
                    try voiceData.write(to: voiceURL)
                    filesExported += 1
                    totalSize += Int64(voiceData.count)
                }
                
                // Update progress
                let specimenProgress = 0.3 + (0.6 * Double(index + 1) / Double(totalSpecimens))
                await MainActor.run { exportProgress = specimenProgress }
            }
            
            // Export JSON metadata
            let exportableCollection = ExportableCollection(from: collection)
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try jsonEncoder.encode(exportableCollection)
            
            let jsonURL = exportURL.appendingPathComponent("collection_data.json")
            try jsonData.write(to: jsonURL)
            filesExported += 1
            totalSize += Int64(jsonData.count)
            
            await MainActor.run { exportProgress = 0.95 }
            
            // Create README file
            let readmeContent = createReadmeContent(for: exportableCollection)
            let readmeURL = exportURL.appendingPathComponent("README.txt")
            try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)
            filesExported += 1
            
            await MainActor.run { 
                exportProgress = 1.0
                isExporting = false
            }
            
            let result = ExportResult(
                success: true,
                exportPath: exportURL,
                error: nil,
                filesExported: filesExported,
                totalSize: totalSize
            )
            
            await MainActor.run {
                lastExportResult = result
            }
            
            return result
            
        } catch {
            await MainActor.run {
                isExporting = false
                exportProgress = 0.0
            }
            
            let result = ExportResult(
                success: false,
                exportPath: nil,
                error: error.localizedDescription,
                filesExported: 0,
                totalSize: 0
            )
            
            await MainActor.run {
                lastExportResult = result
            }
            
            return result
        }
    }
    
    /// Export all collections from SwiftData
    func exportAllCollections(modelContext: ModelContext) async -> ExportResult {
        do {
            let descriptor = FetchDescriptor<SpecimenCollection>()
            let collections = try modelContext.fetch(descriptor)
            
            if collections.isEmpty {
                let result = ExportResult(
                    success: false,
                    exportPath: nil,
                    error: "No collections found to export",
                    filesExported: 0,
                    totalSize: 0
                )
                
                await MainActor.run {
                    lastExportResult = result
                }
                
                return result
            }
            
            // Create master export directory
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let masterExportURL = documentsURL.appendingPathComponent("StromCollect_Complete_Export_\(formatDateForFilename(Date()))")
            
            if fileManager.fileExists(atPath: masterExportURL.path) {
                try fileManager.removeItem(at: masterExportURL)
            }
            
            try fileManager.createDirectory(at: masterExportURL, withIntermediateDirectories: true)
            
            var totalFilesExported = 0
            var totalSizeExported: Int64 = 0
            
            // Export each collection to its own subdirectory
            for (index, collection) in collections.enumerated() {
                let collectionResult = await exportCollection(collection)
                
                if collectionResult.success, let sourcePath = collectionResult.exportPath {
                    // Move the collection export into the master directory
                    let destinationPath = masterExportURL.appendingPathComponent(sourcePath.lastPathComponent)
                    try fileManager.moveItem(at: sourcePath, to: destinationPath)
                    
                    totalFilesExported += collectionResult.filesExported
                    totalSizeExported += collectionResult.totalSize
                }
                
                let progress = Double(index + 1) / Double(collections.count)
                await MainActor.run { exportProgress = progress }
            }
            
            // Create master index file
            let indexContent = createMasterIndexContent(collections: collections)
            let indexURL = masterExportURL.appendingPathComponent("EXPORT_INDEX.txt")
            try indexContent.write(to: indexURL, atomically: true, encoding: .utf8)
            
            let result = ExportResult(
                success: true,
                exportPath: masterExportURL,
                error: nil,
                filesExported: totalFilesExported,
                totalSize: totalSizeExported
            )
            
            await MainActor.run {
                lastExportResult = result
                isExporting = false
            }
            
            return result
            
        } catch {
            let result = ExportResult(
                success: false,
                exportPath: nil,
                error: error.localizedDescription,
                filesExported: 0,
                totalSize: 0
            )
            
            await MainActor.run {
                lastExportResult = result
                isExporting = false
            }
            
            return result
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }
    
    private func createReadmeContent(for collection: ExportableCollection) -> String {
        return """
        StromCollect Data Export
        ========================
        
        Export Date: \(collection.exportDate)
        Export Version: \(collection.exportVersion)
        
        Collection Information:
        - ID: \(collection.id)
        - Locality: \(collection.locality)
        - Collector: \(collection.collectorName)
        - Collection Date: \(collection.collectionDate)
        - Complete: \(collection.isComplete ? "Yes" : "No")
        - Number of Specimens: \(collection.specimens.count)
        
        File Structure:
        ===============
        
        collection_data.json    - Complete collection metadata in JSON format
        images/                 - All photographs (specimen images, field book pages, drawer overview)
        audio/                  - All voice note recordings
        README.txt             - This file
        
        File Naming Convention:
        ======================
        
        Images:
        - drawer_overview_[UUID].jpg    - Drawer overview photograph
        - specimen_[UUID]_[N].jpg       - Individual specimen photographs (up to 5 per specimen)
        - fieldbook_[UUID]_[N].jpg      - Field book page photographs (multiple pages per specimen)
        - fieldbook_[UUID].jpg          - Legacy single field book photograph
        
        Audio:
        - voice_[UUID].m4a              - Voice note recordings
        
        Processing Notes:
        ================
        
        - All images are in JPEG format, suitable for OCR processing
        - Audio files are in M4A format, suitable for speech-to-text processing
        - JSON file contains all metadata including OCR text already extracted
        - UUIDs in filenames correspond to specimen IDs in the JSON data
        - All timestamps are in ISO8601 format (UTC)
        
        Recommended Processing:
        ======================
        
        1. Parse collection_data.json for metadata and existing OCR text
        2. Process images in images/ folder for additional OCR if needed
        3. Process audio files in audio/ folder for speech-to-text conversion
        4. Cross-reference filenames with specimen IDs in JSON for data correlation
        
        """
    }
    
    private func createMasterIndexContent(collections: [SpecimenCollection]) -> String {
        var content = """
        StromCollect Complete Export Index
        ==================================
        
        Export Date: \(ISO8601DateFormatter().string(from: Date()))
        Total Collections: \(collections.count)
        
        Collections Included:
        ====================
        
        """
        
        for collection in collections {
            content += """
            
            Locality: \(collection.locality)
            Collector: \(collection.collectorName)
            Date: \(ISO8601DateFormatter().string(from: collection.collectionDate))
            Specimens: \(collection.specimens.count)
            Complete: \(collection.isComplete ? "Yes" : "No")
            Directory: StromCollect_Export_\(collection.locality.replacingOccurrences(of: " ", with: "_"))_\(formatDateForFilename(collection.collectionDate))
            
            """
        }
        
        content += """
        
        Processing Instructions:
        =======================
        
        Each collection is exported to its own directory with the following structure:
        - collection_data.json: Complete metadata
        - images/: All photographs
        - audio/: All voice recordings
        - README.txt: Collection-specific information
        
        For batch processing, iterate through each collection directory and process
        the files according to the individual README files.
        """
        
        return content
    }
}
