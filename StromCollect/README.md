# StromCollect

A comprehensive iOS application for systematic collection and documentation of stromatolite specimens, built with SwiftUI and SwiftData. Designed specifically for university professors and researchers conducting field research and museum collection workflows.

## Overview

StromCollect provides a structured, step-by-step workflow for documenting stromatolite specimens with high-quality photography, real-time speech-to-text transcription, comprehensive specimen identification, and automated quality validation. The app ensures consistent scientific data collection standards with local storage and structured export capabilities for external processing.

## Features

### 🔄 Guided Workflow System
- **8-step collection process**: Setup → Drawer Overview → Specimen Identification → Documentation → Field Book Capture → Voice Notes → Quality Review → Completion
- **Persistent collection management** - resume work across app launches
- **Progress tracking** with visual indicators and iPad sidebar navigation
- **Validation checks** at each step to ensure data completeness
- **Multi-collection support** - switch between active collections
- **Workflow state persistence** - never lose your progress

### 📸 Advanced Photography System
- **High-resolution specimen photography** with optimized camera settings
- **Automated quality assessment** using sharpness and brightness analysis
- **Real-time quality feedback** with improvement recommendations
- **Drawer overview photography** for specimen context
- **Field book page capture** for associated documentation
- **Front/back camera switching** with device capability detection
- **Mock camera support** for simulator testing and development
- **Robust permission handling** with graceful fallback modes
- **Thread-safe camera operations** with comprehensive error handling

### 🔍 Intelligent Text Recognition (OCR)
- **Vision framework integration** for specimen label recognition
- **Confidence scoring** for OCR results
- **Verification flagging** for low-confidence text
- **Language correction** for improved accuracy

### 🎙️ Voice Annotation System with Live Transcription
- **Real-time speech-to-text transcription** using Apple's Speech framework
- **Simultaneous audio recording and live transcription** display
- **High-quality audio recording** (M4A format) with quality validation
- **Searchable transcription storage** for historical specimen stories
- **Large accessible controls** designed for elderly users
- **Optional workflow integration** - voice notes don't block progression
- **Edit transcription capability** for accuracy corrections
- **Automatic audio session management** with proper permissions

### 📊 Data Management & Export
- **SwiftData integration** for modern local storage
- **Comprehensive data export system** to Documents directory
- **Structured JSON metadata** with all collection/specimen data
- **Organized file structure** - separate folders for images (JPEG) and audio (M4A)
- **UUID-based cross-referencing** for external processing
- **README files** with processing instructions included
- **Share functionality** to access exported files
- **Progress tracking** and error handling for exports
- **No cloud dependency** - all data remains local unless explicitly shared

### 🏷️ Comprehensive Specimen Identification
**Scientific Classification Fields:**
- **Specimen ID/Label** (text field)
- **Locality Information**: Country, State/Province, Nearest City (separate fields)
- **GPS Coordinates**: Latitude/Longitude with decimal validation
- **Mineralogy Classification**: Quartz, Calcite, Dolomite, Iron Oxide, Mixture, Unknown
- **Structure Types**: Columnar, Domal, Stratiform, Branching, Conical, Unknown
- **Geological Age** in Mya (millions of years ago)
- **Additional Notes** (multi-line text field)

**Advanced Features:**
- **Multiple specimen management** - add/select multiple specimens per collection
- **Responsive UI** supporting both iPad and iPhone layouts
- **Enhanced search functionality** across all identification fields
- **SwiftData model binding** with @Bindable for real-time updates
- **Scientific rigor** while maintaining accessibility for elderly users

## Technical Architecture

### Core Components

#### Data Models (SwiftData)
- **`SpecimenCollection`**: Container for collection metadata, locality, date, collector info
- **`SpecimenRecord`**: Individual specimen with comprehensive scientific fields, images, OCR text, voice notes, and transcriptions
- **`StromatoliteType`**: Enumeration of structure classifications
- **`MineralogyType`**: Enumeration for mineralogy dropdown options
- **`CollectionManager`**: Handles persistent state and collection switching

#### Controllers
- **`SpecimenCameraController`**: Advanced camera management with quality validation, mock support, and robust error handling
- **`OCRProcessor`**: Text recognition using Vision framework
- **`AudioRecorder`**: Enhanced voice recording with Speech framework integration for live transcription
- **`CollectionManager`**: Persistent collection state management across app launches
- **Export System**: Comprehensive data export with structured file organization

#### Views
- **`ContentView`**: Main navigation with iPad sidebar and iPhone traditional navigation
- **`CollectionSelectionView`**: Manage multiple collections and create new ones
- **`SetupView`**: Collection metadata input (shown once per collection)
- **`SpecimenIdentificationView`**: Comprehensive specimen identification with scientific fields
- **`SpecimenIdentificationFormView`**: Responsive form supporting iPad/iPhone layouts
- **`AddSpecimenView`**: Modal for creating new specimens
- **`VoiceAnnotationView`**: Voice recording with live transcription display
- **`DrawerOverviewView`**: Specimen drawer photography
- **`CameraView`**: Full-screen camera interface with advanced controls
- **Export and completion views** with progress tracking

### Quality Assurance Features
- **Image sharpness analysis** using edge detection algorithms
- **Brightness validation** with exposure recommendations
- **Audio quality metrics** for voice recordings
- **Step validation** ensuring data completeness
- **Real-time feedback** for quality improvements

## Requirements

- **iOS 16.0+** (iOS 17.0+ recommended for enhanced speech recognition)
- **Xcode 15.0+**
- **Swift 5.9+**
- **Camera access** for specimen photography
- **Microphone access** for voice annotations
- **Storage permissions** for data persistence

### Frameworks Used
- **SwiftUI** (User Interface)
- **SwiftData** (Modern Local Storage)
- **AVFoundation** (Camera and Audio)
- **Speech** (Real-time Speech-to-Text)
- **Vision** (OCR Processing)
- **Combine** (Reactive Programming)
- **PhotosUI** (Photo Selection)

## Installation

1. Clone or download the project
2. Open `StromCollect.xcodeproj` in Xcode
3. Ensure your development team is set in project settings
4. Add required permissions to `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access required for specimen photography</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Microphone access required for voice annotations</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>Speech recognition required for live transcription of voice notes</string>
   ```
5. Build and run on a physical iOS device (camera functionality requires hardware)

## Usage

### Starting a Collection
1. Launch the app - you'll see existing collections or be prompted to create a new one
2. **Create New Collection** or **Resume Existing** collection from the selection screen
3. For new collections, complete **Setup** with locality, collector name, and date
4. Progress through the guided workflow with persistent state tracking

### Specimen Documentation Workflow
1. Take a **drawer overview** photo showing all specimens
2. **Identify specimens** with comprehensive scientific fields:
   - Specimen ID, locality details, GPS coordinates
   - Mineralogy classification, structure type, geological age
   - Additional notes and observations
3. **Document each specimen** with high-resolution photography and quality validation
4. **Capture field book pages** for additional context and OCR processing
5. **Record voice annotations** with live speech-to-text transcription
6. **Review quality** of all captured data with automated recommendations
7. **Export data** to structured folders for external processing
8. **Complete** the collection session with full data preservation

### Quality Guidelines
- **Photography**: Ensure good lighting, hold device steady for sharp images
- **Voice Recording**: Speak clearly for accurate live transcription
- **Text Recognition**: Verify OCR text accuracy and confidence scores
- **Scientific Data**: Complete all relevant identification fields for research quality
- **Validation**: Follow automated quality recommendations throughout workflow
- **Accessibility**: Large touch targets and clear instructions designed for elderly users

## Data Structure

### Collection Record
```
SpecimenCollection
├── id: UUID
├── locality: String
├── collectionDate: Date
├── collectorName: String
├── drawerOverviewImageData: Data?
├── specimens: [SpecimenRecord]
├── isComplete: Bool
├── currentStep: WorkflowStep
└── createdAt: Date
```

### Specimen Record
```
SpecimenRecord
├── id: UUID
├── specimenLabel: String
├── country: String
├── stateProvince: String
├── nearestCity: String
├── latitude: Double
├── longitude: Double
├── mineralogy: MineralogyType
├── structureType: StromatoliteType
├── ageInMya: Double
├── additionalNotes: String
├── specimenImageData: Data?
├── fieldBookImageData: Data?
├── voiceNoteData: Data?
├── voiceNoteTranscription: String
├── ocrText: String
├── ocrConfidence: Float
├── isComplete: Bool
└── qualityScore: Double
```

## Development Status

### Implemented Features ✅
- **Complete workflow system** with persistent state management
- **Advanced camera integration** with quality validation and mock support
- **Real-time speech-to-text** transcription with live display
- **Comprehensive specimen identification** with all scientific fields
- **Multi-collection management** with resume capability
- **iPad sidebar navigation** with always-visible workflow progress
- **Structured data export system** with organized file structure
- **OCR text recognition** with confidence scoring
- **Audio recording system** with quality validation
- **SwiftData persistence** with modern data management
- **Responsive UI design** supporting iPad and iPhone layouts
- **Accessibility features** designed for elderly users
- **Robust error handling** and permission management

### Future Enhancements 🚧
- **Advanced image analysis** with machine learning
- **Cloud synchronization options** (currently local-only by design)
- **Batch processing capabilities** for large collections
- **Enhanced search and filtering** across collections
- **Integration with external databases** and research platforms

## Contributing

This application is designed for scientific research and museum collection workflows. Contributions should maintain the focus on data quality, user experience, and scientific accuracy.

### Development Guidelines
- Follow SwiftUI best practices
- Maintain comprehensive error handling
- Ensure accessibility compliance
- Test on physical devices for camera/audio features
- Validate data integrity throughout the workflow

## License

MIT

## Contact

Aaron Celestian, PhD   acelestian@nhm.org

---

*Built for stromatolite research and specimen collection workflows*
