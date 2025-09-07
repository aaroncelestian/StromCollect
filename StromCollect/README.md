# Stromatolite Collector App

A comprehensive iOS application for systematic collection and documentation of stromatolite specimens, built with SwiftUI and designed for field research and museum collection workflows.

## Overview

The Stromatolite Collector App provides a structured, step-by-step workflow for documenting stromatolite specimens with high-quality photography, OCR text recognition, voice annotations, and automated quality validation. The app ensures consistent data collection standards and integrates with Core Data for local storage and CloudKit for synchronization.

## Features

### 🔄 Guided Workflow System
- **8-step collection process**: Setup → Drawer Overview → Specimen Identification → Documentation → Field Book Capture → Voice Notes → Quality Review → Completion
- **Progress tracking** with visual indicators
- **Validation checks** at each step to ensure data completeness
- **Navigation controls** with step-by-step progression

### 📸 Advanced Photography System
- **High-resolution specimen photography** with optimized camera settings
- **Automated quality assessment** using sharpness and brightness analysis
- **Real-time quality feedback** with improvement recommendations
- **Drawer overview photography** for specimen context
- **Field book page capture** for associated documentation

### 🔍 Intelligent Text Recognition (OCR)
- **Vision framework integration** for specimen label recognition
- **Confidence scoring** for OCR results
- **Verification flagging** for low-confidence text
- **Language correction** for improved accuracy

### 🎙️ Voice Annotation System
- **High-quality audio recording** (AAC format, 12kHz sample rate)
- **Audio quality validation** with amplitude and clarity metrics
- **Voice note integration** with specimen records
- **Automatic audio session management**

### 📊 Data Management
- **Core Data integration** for local storage
- **CloudKit synchronization** for multi-device access
- **Structured data models** for specimens and collections
- **UUID-based record identification**
- **Sync status tracking**

### 🏷️ Specimen Classification
Support for multiple stromatolite structure types:
- Columnar
- Domal
- Stratiform
- Branching
- Conical
- Unknown

## Technical Architecture

### Core Components

#### Data Models
- **`SpecimenCollection`**: Container for collection metadata and specimens
- **`SpecimenRecord`**: Individual specimen data with images, OCR text, and voice notes
- **`StromatoliteType`**: Enumeration of structure classifications

#### Controllers
- **`SpecimenCameraController`**: Camera management with quality validation
- **`OCRProcessor`**: Text recognition using Vision framework
- **`AudioRecorder`**: Voice recording with quality metrics
- **`WorkflowController`**: State management for collection workflow

#### Views
- **`ContentView`**: Main navigation and workflow orchestration
- **`SetupView`**: Collection metadata input
- **`DrawerOverviewView`**: Specimen drawer photography
- **`CameraView`**: Full-screen camera interface with controls
- **Quality and progress indicator components**

### Quality Assurance Features
- **Image sharpness analysis** using edge detection algorithms
- **Brightness validation** with exposure recommendations
- **Audio quality metrics** for voice recordings
- **Step validation** ensuring data completeness
- **Real-time feedback** for quality improvements

## Requirements

- **iOS 15.0+**
- **Xcode 13.0+**
- **Swift 5.5+**
- **Camera access** for specimen photography
- **Microphone access** for voice annotations
- **Storage permissions** for data persistence

### Frameworks Used
- SwiftUI (User Interface)
- AVFoundation (Camera and Audio)
- Vision (OCR Processing)
- Core Data (Local Storage)
- CloudKit (Synchronization)
- Combine (Reactive Programming)
- PhotosUI (Photo Selection)

## Installation

1. Clone or download the project
2. Open `main.swift` in Xcode
3. Ensure your development team is set in project settings
4. Add required permissions to `Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access required for specimen photography</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Microphone access required for voice annotations</string>
   ```
5. Build and run on a physical iOS device (camera functionality requires hardware)

## Usage

### Starting a Collection
1. Launch the app and begin with **Setup**
2. Enter collection locality, collector name, and date
3. Progress through the guided workflow

### Specimen Documentation
1. Take a **drawer overview** photo showing all specimens
2. **Identify specimens** using the classification system
3. **Document each specimen** with high-resolution photography
4. **Capture field book pages** for additional context
5. **Record voice annotations** for detailed observations
6. **Review quality** of all captured data
7. **Complete** the collection session

### Quality Guidelines
- Ensure good lighting for photography
- Hold device steady for sharp images
- Speak clearly for voice recordings
- Verify OCR text accuracy
- Follow validation recommendations

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
└── syncStatus: String
```

### Specimen Record
```
SpecimenRecord
├── id: UUID
├── specimenID: String
├── stromatoliteAge: String
├── structureType: StromatoliteType
├── specimenImageData: Data?
├── fieldBookImageData: Data?
├── voiceNoteData: Data?
├── ocrText: String
├── ocrConfidence: Float
├── notes: String
├── isComplete: Bool
└── qualityScore: Double
```

## Development Status

### Implemented Features ✅
- Core workflow system
- Camera integration with quality validation
- OCR text recognition
- Audio recording system
- Data models and persistence
- Progress tracking and navigation

### Planned Features 🚧
- Specimen identification interface
- Enhanced specimen documentation views
- Field book capture interface
- Voice annotation interface
- Comprehensive quality review system
- CloudKit synchronization
- Export functionality
- Advanced image analysis

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
