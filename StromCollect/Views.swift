import SwiftUI
import VisionKit
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var cameraController = SpecimenCameraController()
    @State private var showingPermissionAlert = false
    @State private var permissionMessage = ""
    @State private var cameraPermissionGranted = false
    @State private var microphonePermissionGranted = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if horizontalSizeClass != .regular {
                    Text("Collection Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                if horizontalSizeClass == .regular {
                    // iPad layout - use a form-style layout with more space
                    VStack(spacing: 24) {
                        FormSection(title: "Collection Information") {
                            VStack(spacing: 16) {
                                FormField(title: "Locality/Location", icon: "location") {
                                    TextField("Enter collection locality", text: $workflowController.collection.locality)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .submitLabel(.next)
                                        .disableAutocorrection(false)
                                }
                                
                                FormField(title: "Collector Name", icon: "person") {
                                    TextField("Enter collector name", text: $workflowController.collection.collectorName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .submitLabel(.done)
                                        .disableAutocorrection(false)
                                }
                                
                                FormField(title: "Collection Date", icon: "calendar") {
                                    DatePicker("", selection: $workflowController.collection.collectionDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                }
                            }
                        }
                        
                        InstructionCard(
                            title: "Setup Instructions",
                            content: "Enter the basic information for this collection session. Make sure the locality and collector name are accurate as they will be included in all specimen records."
                        )
                        
                        if !cameraPermissionGranted || !microphonePermissionGranted {
                            Button(action: {
                                requestPermissions()
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Image(systemName: "mic")
                                    Text("Request Camera & Microphone Access")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Camera & Microphone Access Granted")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: 600)
                } else {
                    // iPhone layout - compact form
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Locality/Location")
                                .font(.headline)
                            TextField("Enter collection locality", text: $workflowController.collection.locality)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.next)
                                .disableAutocorrection(false)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Collector Name")
                                .font(.headline)
                            TextField("Enter collector name", text: $workflowController.collection.collectorName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .disableAutocorrection(false)
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
                    
                    if !cameraPermissionGranted || !microphonePermissionGranted {
                        Button(action: {
                            requestPermissions()
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Image(systemName: "mic")
                                Text("Request Camera & Microphone Access")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Camera & Microphone Access Granted")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            checkCurrentPermissions()
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert("Permissions", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(permissionMessage)
        }
    }
    
    private func requestPermissions() {
        cameraController.requestAllPermissions { cameraGranted, micGranted in
            // Update state variables
            self.cameraPermissionGranted = cameraGranted
            self.microphonePermissionGranted = micGranted
            
            var messages: [String] = []
            
            if !cameraGranted {
                messages.append("Camera access is required for photographing specimens")
            }
            
            if !micGranted {
                messages.append("Microphone access is required for voice annotations")
            }
            
            if !messages.isEmpty {
                permissionMessage = messages.joined(separator: "\n\n") + "\n\nYou can enable these permissions in Settings."
                showingPermissionAlert = true
            } else {
                permissionMessage = "All permissions granted! You can now use the camera and microphone features."
                showingPermissionAlert = true
            }
        }
    }
    
    private func checkCurrentPermissions() {
        // Check camera permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionGranted = (cameraStatus == .authorized)
        
        // Check microphone permission
        if #available(iOS 17.0, *) {
            let micStatus = AVAudioApplication.shared.recordPermission
            microphonePermissionGranted = (micStatus == .granted)
        } else {
            let micStatus = AVAudioSession.sharedInstance().recordPermission
            microphonePermissionGranted = (micStatus == .granted)
        }
    }
}

// MARK: - Reusable Components
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            content
        }
        .padding(24)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FormField<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
    }
}

struct InstructionCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Specimen Identification View
struct SpecimenIdentificationView: View {
    @ObservedObject var workflowController: WorkflowController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentSpecimen: SpecimenRecord?
    @State private var showingAddSpecimen = false
    @State private var selectedSpecimenIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if horizontalSizeClass != .regular {
                    Text("Specimen Identification")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // Specimen selector
                if !workflowController.collection.specimens.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Specimen")
                            .font(.headline)
                        
                        Picker("Specimen", selection: $selectedSpecimenIndex) {
                            ForEach(0..<workflowController.collection.specimens.count, id: \.self) { index in
                                let specimen = workflowController.collection.specimens[index]
                                Text(specimen.specimenID.isEmpty ? "Specimen \(index + 1)" : specimen.specimenID)
                                    .tag(index)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedSpecimenIndex) { _, newIndex in
                            if newIndex < workflowController.collection.specimens.count {
                                currentSpecimen = workflowController.collection.specimens[newIndex]
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Add new specimen button
                Button(action: {
                    showingAddSpecimen = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add New Specimen")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Specimen identification form
                if let specimen = currentSpecimen {
                    SpecimenIdentificationFormView(specimen: specimen)
                } else if !workflowController.collection.specimens.isEmpty {
                    Text("Select a specimen above to edit its identification details")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "fossil.shell")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Specimens Added")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add your first specimen to begin identification")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .onAppear {
            if !workflowController.collection.specimens.isEmpty {
                currentSpecimen = workflowController.collection.specimens[selectedSpecimenIndex]
            }
        }
        .sheet(isPresented: $showingAddSpecimen) {
            AddSpecimenView(collection: workflowController.collection) { newSpecimen in
                workflowController.collection.specimens.append(newSpecimen)
                selectedSpecimenIndex = workflowController.collection.specimens.count - 1
                currentSpecimen = newSpecimen
                showingAddSpecimen = false
            }
        }
    }
}

// MARK: - Specimen Identification Form
struct SpecimenIdentificationFormView: View {
    @Bindable var specimen: SpecimenRecord
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var latitudeText = ""
    @State private var longitudeText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if horizontalSizeClass == .regular {
                // iPad layout - two columns
                VStack(spacing: 24) {
                    FormSection(title: "Basic Information") {
                        VStack(spacing: 16) {
                            FormField(title: "Specimen ID/Label", icon: "tag") {
                                TextField("Enter specimen ID", text: $specimen.specimenID)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .submitLabel(.next)
                            }
                            
                            HStack(spacing: 16) {
                                FormField(title: "Structure Type", icon: "fossil.shell") {
                                    Picker("Structure Type", selection: $specimen.structureTypeEnum) {
                                        ForEach(StromatoliteType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                                
                                FormField(title: "Age (Mya)", icon: "clock") {
                                    TextField("e.g., 2500", text: $specimen.stromatoliteAge)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .submitLabel(.next)
                                }
                            }
                            
                            FormField(title: "Mineralogy", icon: "diamond") {
                                Picker("Mineralogy", selection: $specimen.mineralogyEnum) {
                                    ForEach(MineralogyType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    }
                    
                    FormSection(title: "Locality Information") {
                        VStack(spacing: 16) {
                            FormField(title: "Country", icon: "globe") {
                                TextField("Enter country", text: $specimen.localityCountry)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .submitLabel(.next)
                            }
                            
                            HStack(spacing: 16) {
                                FormField(title: "State/Province", icon: "map") {
                                    TextField("Enter state/province", text: $specimen.localityStateProvince)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .submitLabel(.next)
                                }
                                
                                FormField(title: "Nearest City", icon: "building.2") {
                                    TextField("Enter nearest city", text: $specimen.localityNearestCity)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .submitLabel(.next)
                                }
                            }
                            
                            FormField(title: "Coordinates", icon: "location") {
                                HStack(spacing: 8) {
                                    TextField("Latitude", text: $latitudeText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .onChange(of: latitudeText) { _, newValue in
                                            specimen.latitude = Double(newValue)
                                        }
                                    
                                    TextField("Longitude", text: $longitudeText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .onChange(of: longitudeText) { _, newValue in
                                            specimen.longitude = Double(newValue)
                                        }
                                }
                            }
                        }
                    }
                    
                    FormSection(title: "Additional Notes") {
                        FormField(title: "Notes", icon: "note.text") {
                            TextField("Enter additional notes", text: $specimen.additionalNotes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                }
                .frame(maxWidth: 800)
            } else {
                // iPhone layout - single column
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Specimen ID/Label")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter specimen ID", text: $specimen.specimenID)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Structure Type")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Picker("Structure Type", selection: $specimen.structureTypeEnum) {
                                    ForEach(StromatoliteType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age (Mya)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("e.g., 2500", text: $specimen.stromatoliteAge)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mineralogy")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("Mineralogy", selection: $specimen.mineralogyEnum) {
                                ForEach(MineralogyType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Locality Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Locality Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Country")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter country", text: $specimen.localityCountry)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("State/Province")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter state/province", text: $specimen.localityStateProvince)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearest City")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter nearest city", text: $specimen.localityNearestCity)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Coordinates")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            VStack(spacing: 8) {
                                TextField("Latitude", text: $latitudeText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onChange(of: latitudeText) { _, newValue in
                                        specimen.latitude = Double(newValue)
                                    }
                                
                                TextField("Longitude", text: $longitudeText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onChange(of: longitudeText) { _, newValue in
                                        specimen.longitude = Double(newValue)
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Additional Notes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter additional notes", text: $specimen.additionalNotes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .onAppear {
            // Initialize coordinate text fields
            if let lat = specimen.latitude {
                latitudeText = String(lat)
            }
            if let lon = specimen.longitude {
                longitudeText = String(lon)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside text fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Add Specimen View
struct AddSpecimenView: View {
    let collection: SpecimenCollection
    let onSpecimenAdded: (SpecimenRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var specimenID = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "fossil.shell")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Add New Specimen")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Create a new specimen record for identification and documentation.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Specimen ID/Label")
                        .font(.headline)
                    
                    TextField("Enter specimen ID", text: $specimenID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.done)
                    
                    Text("You can leave this blank and fill it in later during identification.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button(action: {
                    let newSpecimen = SpecimenRecord()
                    newSpecimen.specimenID = specimenID
                    onSpecimenAdded(newSpecimen)
                }) {
                    Text("Create Specimen")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Specimen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Drawer Overview View
struct DrawerOverviewView: View {
    @ObservedObject var workflowController: WorkflowController
    @StateObject private var cameraController = SpecimenCameraController()
    @State private var showingCamera = false
    @State private var showingHelp = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Drawer Overview")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingHelp = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
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
        .sheet(isPresented: $showingHelp) {
            DrawerOverviewHelpView()
        }
    }
}

// MARK: - Drawer Overview Help View
struct DrawerOverviewHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("Drawer Overview Photography")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Follow these guidelines to capture the perfect drawer overview photo for your stromatolite collection.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HelpSection(
                            icon: "viewfinder",
                            title: "Camera Position",
                            content: "Position your camera at a 45-degree angle above the drawer. This angle provides the optimal view of both the drawer label and the specimen contents."
                        )
                        
                        HelpSection(
                            icon: "tag",
                            title: "Include the Label",
                            content: "Ensure the front drawer label is clearly visible and readable in the photograph. The label contains important collection information that must be documented."
                        )
                        
                        HelpSection(
                            icon: "eye",
                            title: "Show All Contents",
                            content: "Capture the entire contents of the drawer so all specimens are visible. This overview helps identify and count specimens during later analysis."
                        )
                        
                        HelpSection(
                            icon: "lightbulb",
                            title: "Lighting Tips",
                            content: "Use even lighting to avoid shadows that might obscure specimens or labels. Natural light or overhead fluorescent lighting works best."
                        )
                        
                        HelpSection(
                            icon: "hand.raised",
                            title: "Avoid Obstructions",
                            content: "Keep your hands, shadows, and any equipment out of the frame. The photo should show only the drawer and its contents."
                        )
                        
                        HelpSection(
                            icon: "camera.macro",
                            title: "Focus and Clarity",
                            content: "Ensure the entire drawer is in focus. Tap on the screen to focus if needed. A sharp, clear image is essential for documentation."
                        )
                    }
                    
                    VStack(spacing: 12) {
                        Text("Quick Checklist")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ChecklistItem(text: "Camera positioned at 45-degree angle")
                            ChecklistItem(text: "Drawer label clearly visible and readable")
                            ChecklistItem(text: "All specimens in drawer are visible")
                            ChecklistItem(text: "Even lighting with no harsh shadows")
                            ChecklistItem(text: "No hands or obstructions in frame")
                            ChecklistItem(text: "Image is sharp and in focus")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Photography Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ChecklistItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
                .font(.body)
            
            Text(text)
                .font(.body)
            
            Spacer()
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
                HStack {
                    Spacer()
                    
                    if cameraController.canSwitchCamera {
                        Button(action: {
                            cameraController.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing)
                    }
                }
                .padding(.top, 50)
                
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
                            .fill(cameraController.isSessionReady ? Color.white : Color.gray)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .disabled(cameraController.isCapturing || !cameraController.isSessionReady)
                    
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
        previewLayer.videoGravity = .resizeAspectFill
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
    @ObservedObject var collectionManager: CollectionManager
    
    var body: some View {
        HStack {
            Button("Previous") {
                workflowController.progressToPrevious()
            }
            .disabled(workflowController.currentState == .setup)
            
            Spacer()
            
            Button("Next") {
                if workflowController.currentState == .completion {
                    collectionManager.markCollectionComplete(workflowController.collection)
                }
                workflowController.progressToNext()
            }
            .disabled(!workflowController.validateCurrentStep())
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - iPad-Optimized Views
struct WorkflowSidebarView: View {
    @ObservedObject var workflowController: WorkflowController
    @ObservedObject var collectionManager: CollectionManager
    @StateObject private var exportManager = DataExportManager()
    @State private var showingExportSheet = false
    
    var body: some View {
        List {
            Section("Collection Progress") {
                ForEach(CollectionWorkflowState.allCases, id: \.self) { state in
                    HStack {
                        Image(systemName: iconForState(state))
                            .foregroundColor(workflowController.currentState == state ? .blue : .secondary)
                        
                        VStack(alignment: .leading) {
                            Text(state.rawValue)
                                .font(.headline)
                            if state == workflowController.currentState {
                                Text("Current Step")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        if isStateCompleted(state) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        workflowController.jumpToState(state)
                    }
                }
            }
            
            Section("Collection Info") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Locality", systemImage: "location")
                    Text(workflowController.collection.locality.isEmpty ? "Not set" : workflowController.collection.locality)
                        .foregroundColor(.secondary)
                    
                    Label("Collector", systemImage: "person")
                    Text(workflowController.collection.collectorName.isEmpty ? "Not set" : workflowController.collection.collectorName)
                        .foregroundColor(.secondary)
                    
                    Label("Date", systemImage: "calendar")
                    Text(workflowController.collection.collectionDate, style: .date)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Actions") {
                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Export Collection")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
                
                NavigationLink(destination: CollectionBrowserView(collectionManager: collectionManager)) {
                    HStack {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundColor(.blue)
                        Text("View All Collections")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
                
                NavigationLink(destination: SearchView(collectionManager: collectionManager)) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                        Text("Search Collections")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
                
                Button(action: {
                    collectionManager.currentCollection = nil
                }) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.blue)
                        Text("Switch Collection")
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Workflow")
        .frame(minWidth: 300)
        .sheet(isPresented: $showingExportSheet) {
            ExportView(
                collection: workflowController.collection,
                exportManager: exportManager
            )
        }
    }
    
    private func iconForState(_ state: CollectionWorkflowState) -> String {
        switch state {
        case .setup: return "gear"
        case .drawerOverview: return "photo.on.rectangle"
        case .specimenIdentification: return "magnifyingglass"
        case .specimenDocumentation: return "camera"
        case .fieldBookCapture: return "book"
        case .voiceAnnotation: return "mic"
        case .qualityReview: return "checkmark.seal"
        case .completion: return "flag.checkered"
        }
    }
    
    private func isStateCompleted(_ state: CollectionWorkflowState) -> Bool {
        let currentIndex = CollectionWorkflowState.allCases.firstIndex(of: workflowController.currentState) ?? 0
        let stateIndex = CollectionWorkflowState.allCases.firstIndex(of: state) ?? 0
        return stateIndex < currentIndex
    }
}

struct WorkflowDetailView: View {
    @ObservedObject var workflowController: WorkflowController
    @ObservedObject var collectionManager: CollectionManager
    
    var body: some View {
        VStack {
            WorkflowContentView(workflowController: workflowController)
            
            Spacer()
            
            NavigationControlsView(workflowController: workflowController, collectionManager: collectionManager)
                .padding()
        }
        .navigationTitle(workflowController.currentState.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WorkflowContentView: View {
    @ObservedObject var workflowController: WorkflowController
    
    var body: some View {
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
    }
}

// MARK: - Placeholder Views (to be implemented)

struct SpecimenDocumentationView: View {
    @ObservedObject var workflowController: WorkflowController
    @StateObject private var cameraController = SpecimenCameraController()
    @State private var showingCamera = false
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var showingDeleteAlert = false
    @State private var imageToDelete: Int?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Specimen Documentation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let currentSpecimen = workflowController.currentSpecimen {
                    VStack(spacing: 20) {
                        // Specimen Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Specimen Information")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Specimen ID:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(currentSpecimen.specimenID.isEmpty ? "Not set" : currentSpecimen.specimenID)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Structure Type:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(currentSpecimen.structureTypeEnum.rawValue)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Photo Gallery Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Specimen Photos")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(currentSpecimen.specimenImages.count)/5")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if currentSpecimen.specimenImages.isEmpty {
                                // Empty state
                                VStack(spacing: 16) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 200)
                                        .overlay(
                                            VStack(spacing: 12) {
                                                Image(systemName: "camera")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(.secondary)
                                                Text("No photos yet")
                                                    .font(.headline)
                                                    .foregroundColor(.secondary)
                                                Text("Add up to 5 photos of this specimen")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                            }
                                        )
                                }
                            } else {
                                // Photo grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                    ForEach(Array(currentSpecimen.specimenImages.enumerated()), id: \.offset) { index, imageData in
                                        if let image = UIImage(data: imageData) {
                                            SpecimenPhotoThumbnail(
                                                image: image,
                                                index: index,
                                                onTap: {
                                                    selectedImageIndex = index
                                                    showingImageViewer = true
                                                },
                                                onDelete: {
                                                    imageToDelete = index
                                                    showingDeleteAlert = true
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Add Photo Button
                            if currentSpecimen.canAddMoreImages {
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera.badge.plus")
                                        Text("Add Photo (\(currentSpecimen.specimenImages.count)/5)")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Maximum photos reached (5/5)")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    Text("No specimen selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(cameraController: cameraController) { image in
                if let imageData = image.jpegData(compressionQuality: 0.8),
                   let specimen = workflowController.currentSpecimen {
                    specimen.addSpecimenImage(imageData)
                }
                showingCamera = false
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            if let specimen = workflowController.currentSpecimen,
               selectedImageIndex < specimen.specimenImages.count,
               let image = UIImage(data: specimen.specimenImages[selectedImageIndex]) {
                SpecimenImageViewer(
                    images: specimen.specimenImages.compactMap { UIImage(data: $0) },
                    selectedIndex: selectedImageIndex,
                    onRetake: { index in
                        selectedImageIndex = index
                        showingImageViewer = false
                        showingCamera = true
                    },
                    onDelete: { index in
                        imageToDelete = index
                        showingImageViewer = false
                        showingDeleteAlert = true
                    }
                )
            }
        }
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                imageToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let index = imageToDelete,
                   let specimen = workflowController.currentSpecimen {
                    specimen.removeSpecimenImage(at: index)
                }
                imageToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
}

// MARK: - Specimen Photo Thumbnail
struct SpecimenPhotoThumbnail: View {
    let image: UIImage
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
                .onTapGesture {
                    onTap()
                }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Specimen Image Viewer
struct SpecimenImageViewer: View {
    let images: [UIImage]
    @State var selectedIndex: Int
    let onRetake: (Int) -> Void
    let onDelete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if !images.isEmpty && selectedIndex < images.count {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            VStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .tag(index)
                                
                                HStack(spacing: 20) {
                                    Button(action: {
                                        onRetake(index)
                                    }) {
                                        HStack {
                                            Image(systemName: "camera.rotate")
                                            Text("Retake")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        onDelete(index)
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Photo \(selectedIndex + 1) of \(images.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FieldBookCaptureView: View {
    @ObservedObject var workflowController: WorkflowController
    @StateObject private var cameraController = SpecimenCameraController()
    @State private var showingCameraModeSelection = false
    @State private var showingRegularCamera = false
    @State private var showingDocumentScanner = false
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var showingDeleteAlert = false
    @State private var imageToDelete: Int?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Field Book Capture")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let currentSpecimen = workflowController.currentSpecimen {
                    VStack(spacing: 20) {
                        // Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Field Book Pages")
                                .font(.headline)
                            
                            Text("Capture pages from your field book that relate to this specimen. You can add as many pages as needed.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Photo Gallery Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Captured Pages")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(currentSpecimen.fieldBookImages.count) pages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if currentSpecimen.fieldBookImages.isEmpty {
                                // Empty state
                                VStack(spacing: 16) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 200)
                                        .overlay(
                                            VStack(spacing: 12) {
                                                Image(systemName: "book")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(.secondary)
                                                Text("No field book pages yet")
                                                    .font(.headline)
                                                    .foregroundColor(.secondary)
                                                Text("Add pages from your field book related to this specimen")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                            }
                                        )
                                }
                            } else {
                                // Photo grid - 2 columns for field book pages
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                                    ForEach(Array(currentSpecimen.fieldBookImages.enumerated()), id: \.offset) { index, imageData in
                                        if let image = UIImage(data: imageData) {
                                            FieldBookPageThumbnail(
                                                image: image,
                                                index: index,
                                                onTap: {
                                                    selectedImageIndex = index
                                                    showingImageViewer = true
                                                },
                                                onDelete: {
                                                    imageToDelete = index
                                                    showingDeleteAlert = true
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Add Page Buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    showingCameraModeSelection = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add Field Book Page")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                                
                                if !currentSpecimen.fieldBookImages.isEmpty {
                                    Text("Tip: Use Document Scanner mode for best text recognition results")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    Text("No specimen selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingCameraModeSelection) {
            CameraModeSelectionView(
                onRegularCamera: {
                    showingCameraModeSelection = false
                    showingRegularCamera = true
                },
                onDocumentScanner: {
                    showingCameraModeSelection = false
                    if VNDocumentCameraViewController.isSupported {
                        showingDocumentScanner = true
                    } else {
                        // Fallback to regular camera if document scanner not supported
                        showingRegularCamera = true
                    }
                },
                onCancel: {
                    showingCameraModeSelection = false
                }
            )
        }
        .sheet(isPresented: $showingRegularCamera) {
            CameraView(cameraController: cameraController) { image in
                if let imageData = image.jpegData(compressionQuality: 0.8),
                   let specimen = workflowController.currentSpecimen {
                    specimen.addFieldBookImage(imageData)
                }
                showingRegularCamera = false
            }
        }
        .sheet(isPresented: $showingDocumentScanner) {
            if #available(iOS 13.0, *), VNDocumentCameraViewController.isSupported {
                DocumentScannerView(
                    onScanComplete: { images in
                        if let specimen = workflowController.currentSpecimen {
                            for image in images {
                                if let imageData = image.jpegData(compressionQuality: 0.8) {
                                    specimen.addFieldBookImage(imageData)
                                }
                            }
                        }
                        showingDocumentScanner = false
                    },
                    onCancel: {
                        showingDocumentScanner = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            if let specimen = workflowController.currentSpecimen,
               selectedImageIndex < specimen.fieldBookImages.count {
                FieldBookImageViewer(
                    images: specimen.fieldBookImages.compactMap { UIImage(data: $0) },
                    selectedIndex: selectedImageIndex,
                    onRetake: { index in
                        selectedImageIndex = index
                        showingImageViewer = false
                        showingCameraModeSelection = true
                    },
                    onDelete: { index in
                        imageToDelete = index
                        showingImageViewer = false
                        showingDeleteAlert = true
                    }
                )
            }
        }
        .alert("Delete Page", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                imageToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let index = imageToDelete,
                   let specimen = workflowController.currentSpecimen {
                    specimen.removeFieldBookImage(at: index)
                }
                imageToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this field book page? This action cannot be undone.")
        }
    }
}

// MARK: - Field Book Page Thumbnail
struct FieldBookPageThumbnail: View {
    let image: UIImage
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 140)
                .clipped()
                .cornerRadius(8)
                .onTapGesture {
                    onTap()
                }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(4)
            
            // Page number indicator
            VStack {
                Spacer()
                HStack {
                    Text("Page \(index + 1)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Field Book Image Viewer
struct FieldBookImageViewer: View {
    let images: [UIImage]
    @State var selectedIndex: Int
    let onRetake: (Int) -> Void
    let onDelete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if !images.isEmpty && selectedIndex < images.count {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            VStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .tag(index)
                                
                                HStack(spacing: 20) {
                                    Button(action: {
                                        onRetake(index)
                                    }) {
                                        HStack {
                                            Image(systemName: "camera.rotate")
                                            Text("Retake")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        onDelete(index)
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Page \(selectedIndex + 1) of \(images.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VoiceAnnotationView: View {
    @ObservedObject var workflowController: WorkflowController
    @StateObject private var audioRecorder = AudioRecorder()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingPermissionAlert = false
    @State private var permissionMessage = ""
    @State private var selectedSpecimen: SpecimenRecord?
    @State private var showingSpecimenPicker = false
    @State private var editingTranscription = false
    @State private var editedTranscription = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if horizontalSizeClass != .regular {
                    Text("Voice Notes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // Instructions for elderly users
                InstructionCard(
                    title: "Record Historical Stories",
                    content: "Share your knowledge and stories about each specimen. The app will record your voice and automatically convert it to text for easy searching later. Speak clearly and at a comfortable pace."
                )
                
                // Specimen Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Specimen")
                        .font(.headline)
                    
                    if workflowController.collection.specimens.isEmpty {
                        Text("No specimens available. Please add specimens first.")
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        Button(action: {
                            showingSpecimenPicker = true
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text(selectedSpecimen?.specimenID.isEmpty == false ? 
                                     "Specimen: \(selectedSpecimen!.specimenID)" : 
                                     "Choose a specimen...")
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                if let specimen = selectedSpecimen {
                    // Voice Recording Section
                    VStack(spacing: 16) {
                        // Recording Controls
                        VStack(spacing: 12) {
                            // Large, accessible recording button
                            Button(action: {
                                if audioRecorder.isRecording {
                                    stopRecording()
                                } else {
                                    startRecording()
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                                    
                                    Text(audioRecorder.isRecording ? "Stop Recording" : "Start Recording")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(audioRecorder.isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                .cornerRadius(16)
                            }
                            .disabled(audioRecorder.speechPermissionStatus != .authorized && !audioRecorder.isRecording)
                            
                            // Permission status
                            if audioRecorder.speechPermissionStatus != .authorized {
                                Button(action: {
                                    requestSpeechPermission()
                                }) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                        Text("Enable Speech Recognition")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // Live Transcription Display
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Live Transcription")
                                    .font(.headline)
                                
                                if audioRecorder.isTranscribing {
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 6, height: 6)
                                                .scaleEffect(audioRecorder.isTranscribing ? 1.0 : 0.5)
                                                .animation(
                                                    Animation.easeInOut(duration: 0.6)
                                                        .repeatForever()
                                                        .delay(Double(index) * 0.2),
                                                    value: audioRecorder.isTranscribing
                                                )
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if !audioRecorder.transcribedText.isEmpty {
                                    Button(action: {
                                        editedTranscription = audioRecorder.transcribedText
                                        editingTranscription = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            ScrollView {
                                Text(audioRecorder.transcribedText.isEmpty ? 
                                     "Transcribed text will appear here as you speak..." : 
                                     audioRecorder.transcribedText)
                                    .font(.body)
                                    .foregroundColor(audioRecorder.transcribedText.isEmpty ? .secondary : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                            .frame(minHeight: 120)
                        }
                        
                        // Existing Voice Note Display
                        if specimen.hasVoiceNote {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Current Voice Note")
                                    .font(.headline)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(specimen.voiceNotePreview)
                                        .font(.body)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    
                                    HStack {
                                        Button(action: {
                                            // Play existing audio
                                            playExistingVoiceNote(specimen)
                                        }) {
                                            HStack {
                                                Image(systemName: "play.circle")
                                                Text("Play")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            specimen.clearVoiceNote()
                                        }) {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Delete")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Save Button
                        if audioRecorder.audioData != nil {
                            Button(action: {
                                saveVoiceNote()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Save Voice Note")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Select first specimen if available
            if selectedSpecimen == nil && !workflowController.collection.specimens.isEmpty {
                selectedSpecimen = workflowController.collection.specimens.first
            }
        }
        .sheet(isPresented: $showingSpecimenPicker) {
            SpecimenPickerView(
                specimens: workflowController.collection.specimens,
                selectedSpecimen: $selectedSpecimen
            )
        }
        .sheet(isPresented: $editingTranscription) {
            TranscriptionEditorView(
                transcription: $editedTranscription,
                onSave: {
                    audioRecorder.transcribedText = editedTranscription
                    editingTranscription = false
                }
            )
        }
        .alert("Speech Recognition", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(permissionMessage)
        }
    }
    
    private func startRecording() {
        if audioRecorder.speechPermissionStatus == .authorized {
            audioRecorder.startRecording()
        } else {
            requestSpeechPermission()
        }
    }
    
    private func stopRecording() {
        audioRecorder.stopRecording()
    }
    
    private func requestSpeechPermission() {
        Task {
            let granted = await audioRecorder.requestSpeechPermission()
            if !granted {
                permissionMessage = "Speech recognition permission is required to transcribe your voice notes automatically. You can enable this in Settings > Privacy & Security > Speech Recognition."
                showingPermissionAlert = true
            }
        }
    }
    
    private func saveVoiceNote() {
        guard let specimen = selectedSpecimen,
              let audioData = audioRecorder.audioData else { return }
        
        let transcription = audioRecorder.getTranscribedText()
        specimen.setVoiceNote(audioData: audioData, transcription: transcription)
        
        // Clear the recorder for next recording
        audioRecorder.audioData = nil
        audioRecorder.clearTranscription()
    }
    
    private func playExistingVoiceNote(_ specimen: SpecimenRecord) {
        // TODO: Implement audio playback
        // This would use AVAudioPlayer to play the existing voice note
    }
}

// MARK: - Supporting Views for Voice Annotation

struct SpecimenPickerView: View {
    let specimens: [SpecimenRecord]
    @Binding var selectedSpecimen: SpecimenRecord?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(specimens, id: \.id) { specimen in
                    Button(action: {
                        selectedSpecimen = specimen
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(specimen.specimenID.isEmpty ? "Unnamed Specimen" : specimen.specimenID)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !specimen.stromatoliteAge.isEmpty {
                                    Text("Age: \(specimen.stromatoliteAge)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Type: \(specimen.structureTypeEnum.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if specimen.hasVoiceNote {
                                    HStack {
                                        Image(systemName: "mic.fill")
                                            .foregroundColor(.blue)
                                        Text("Has voice note")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if selectedSpecimen?.id == specimen.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Specimen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TranscriptionEditorView: View {
    @Binding var transcription: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Edit the transcription to correct any errors or add additional details.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextEditor(text: $transcription)
                    .focused($isTextFieldFocused)
                    .font(.body)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                HStack {
                    Text("\(transcription.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        transcription = ""
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Focus the text editor when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

struct QualityReviewView: View {
    @ObservedObject var workflowController: WorkflowController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if horizontalSizeClass != .regular {
                    Text("Quality Review")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // Collection Statistics Overview
                CollectionStatisticsView(collection: workflowController.collection)
                
                // Data Quality Metrics
                DataQualityMetricsView(collection: workflowController.collection)
                
                // Specimen Breakdown
                SpecimenBreakdownView(collection: workflowController.collection)
                
                // Completion Status
                CompletionStatusView(collection: workflowController.collection)
            }
            .padding()
        }
    }
}

// MARK: - Statistics Components

struct CollectionStatisticsView: View {
    let collection: SpecimenCollection
    
    private var totalSpecimens: Int {
        collection.specimens.count
    }
    
    private var totalImages: Int {
        collection.specimens.reduce(0) { total, specimen in
            total + specimen.specimenImages.count + specimen.fieldBookImages.count + (specimen.specimenImageData != nil ? 1 : 0) + (specimen.fieldBookImageData != nil ? 1 : 0)
        } + (collection.drawerOverviewImageData != nil ? 1 : 0)
    }
    
    private var totalVoiceNotes: Int {
        collection.specimens.filter { $0.hasVoiceNote }.count
    }
    
    private var totalTranscribedText: Int {
        collection.specimens.reduce(0) { total, specimen in
            total + specimen.voiceNoteTranscription.count + specimen.ocrText.count
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Collection Statistics")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "Total Specimens",
                    value: "\(totalSpecimens)",
                    icon: "fossil.shell",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Total Images",
                    value: "\(totalImages)",
                    icon: "photo.stack",
                    color: .green
                )
                
                StatisticCard(
                    title: "Voice Notes",
                    value: "\(totalVoiceNotes)",
                    icon: "mic.fill",
                    color: .orange
                )
                
                StatisticCard(
                    title: "Text Characters",
                    value: "\(totalTranscribedText)",
                    icon: "text.alignleft",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct DataQualityMetricsView: View {
    let collection: SpecimenCollection
    
    private var completedSpecimens: Int {
        collection.specimens.filter { $0.isComplete }.count
    }
    
    private var specimensWithImages: Int {
        collection.specimens.filter { $0.hasSpecimenImages }.count
    }
    
    private var specimensWithFieldBook: Int {
        collection.specimens.filter { $0.hasFieldBookImages }.count
    }
    
    private var specimensWithVoiceNotes: Int {
        collection.specimens.filter { $0.hasVoiceNote }.count
    }
    
    private var averageQualityScore: Double {
        let scores = collection.specimens.map { $0.qualityScore }
        return scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private var specimensWithCompleteIdentification: Int {
        collection.specimens.filter { specimen in
            // Check that essential identification fields are populated
            !specimen.specimenID.isEmpty &&
            !specimen.structureType.isEmpty &&
            specimen.structureType != StromatoliteType.unknown.rawValue &&
            !specimen.mineralogy.isEmpty &&
            specimen.mineralogy != MineralogyType.unknown.rawValue
        }.count
    }
    
    private var databaseValidationScore: Double {
        guard !collection.specimens.isEmpty else { return 0.0 }
        
        var validationPoints = 0
        let totalPossiblePoints = collection.specimens.count * 6 // 6 validation checks per specimen
        
        for specimen in collection.specimens {
            // Check specimen ID
            if !specimen.specimenID.isEmpty { validationPoints += 1 }
            
            // Check structure type is set
            if specimen.structureType != StromatoliteType.unknown.rawValue { validationPoints += 1 }
            
            // Check mineralogy is set
            if specimen.mineralogy != MineralogyType.unknown.rawValue { validationPoints += 1 }
            
            // Check locality information
            if !specimen.localityCountry.isEmpty || !specimen.localityStateProvince.isEmpty || !specimen.localityNearestCity.isEmpty { validationPoints += 1 }
            
            // Check coordinates if provided
            if specimen.latitude != nil && specimen.longitude != nil { validationPoints += 1 }
            
            // Check age information
            if !specimen.stromatoliteAge.isEmpty { validationPoints += 1 }
        }
        
        return Double(validationPoints) / Double(totalPossiblePoints) * 10.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Data Quality Metrics")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                QualityMetricRow(
                    title: "Completed Specimens",
                    current: completedSpecimens,
                    total: collection.specimens.count,
                    icon: "checkmark.circle"
                )
                
                QualityMetricRow(
                    title: "Specimens with Photos",
                    current: specimensWithImages,
                    total: collection.specimens.count,
                    icon: "camera"
                )
                
                QualityMetricRow(
                    title: "Field Book Documentation",
                    current: specimensWithFieldBook,
                    total: collection.specimens.count,
                    icon: "book"
                )
                
                QualityMetricRow(
                    title: "Voice Annotations",
                    current: specimensWithVoiceNotes,
                    total: collection.specimens.count,
                    icon: "mic"
                )
                
                QualityMetricRow(
                    title: "Complete Identification Data",
                    current: specimensWithCompleteIdentification,
                    total: collection.specimens.count,
                    icon: "checkmark.circle.fill"
                )
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Average Quality Score")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f/10", averageQualityScore))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(averageQualityScore >= 7.0 ? .green : averageQualityScore >= 5.0 ? .orange : .red)
                }
                
                HStack {
                    Image(systemName: "externaldrive.fill.badge.checkmark")
                        .foregroundColor(.blue)
                    Text("Database Validation Score")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f/10", databaseValidationScore))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(databaseValidationScore >= 7.0 ? .green : databaseValidationScore >= 5.0 ? .orange : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct SpecimenBreakdownView: View {
    let collection: SpecimenCollection
    
    private var stromatoliteTypeCounts: [StromatoliteType: Int] {
        var counts: [StromatoliteType: Int] = [:]
        for specimen in collection.specimens {
            let type = specimen.structureTypeEnum
            counts[type, default: 0] += 1
        }
        return counts
    }
    
    private var ageDistribution: [String: Int] {
        var distribution: [String: Int] = [:]
        for specimen in collection.specimens {
            let age = specimen.stromatoliteAge.isEmpty ? "Unknown" : specimen.stromatoliteAge
            distribution[age, default: 0] += 1
        }
        return distribution
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.indigo)
                Text("Specimen Breakdown")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Structure Types")
                    .font(.headline)
                    .fontWeight(.medium)
                
                ForEach(Array(stromatoliteTypeCounts.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { type in
                    let count = stromatoliteTypeCounts[type] ?? 0
                    let percentage = collection.specimens.isEmpty ? 0.0 : Double(count) / Double(collection.specimens.count) * 100
                    
                    HStack {
                        Text(type.rawValue)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(count) (\(String(format: "%.1f", percentage))%)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(count), total: Double(collection.specimens.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: colorForType(type)))
                }
            }
            
            if ageDistribution.count > 1 {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Age Distribution")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(ageDistribution.keys.sorted()), id: \.self) { age in
                        let count = ageDistribution[age] ?? 0
                        let percentage = collection.specimens.isEmpty ? 0.0 : Double(count) / Double(collection.specimens.count) * 100
                        
                        HStack {
                            Text(age)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(count) (\(String(format: "%.1f", percentage))%)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func colorForType(_ type: StromatoliteType) -> Color {
        switch type {
        case .columnar: return .blue
        case .domal: return .green
        case .stratiform: return .orange
        case .branching: return .purple
        case .conical: return .red
        case .unknown: return .gray
        }
    }
}

struct CompletionStatusView: View {
    let collection: SpecimenCollection
    
    private var completionPercentage: Double {
        guard !collection.specimens.isEmpty else { return 0.0 }
        let completedCount = collection.specimens.filter { $0.isComplete }.count
        return Double(completedCount) / Double(collection.specimens.count) * 100
    }
    
    private var missingDataItems: [String] {
        var items: [String] = []
        
        let specimensWithoutImages = collection.specimens.filter { !$0.hasSpecimenImages }.count
        if specimensWithoutImages > 0 {
            items.append("\(specimensWithoutImages) specimens missing photos")
        }
        
        let specimensWithoutFieldBook = collection.specimens.filter { !$0.hasFieldBookImages }.count
        if specimensWithoutFieldBook > 0 {
            items.append("\(specimensWithoutFieldBook) specimens missing field book pages")
        }
        
        let specimensWithoutVoice = collection.specimens.filter { !$0.hasVoiceNote }.count
        if specimensWithoutVoice > 0 {
            items.append("\(specimensWithoutVoice) specimens missing voice notes")
        }
        
        if collection.drawerOverviewImageData == nil {
            items.append("Drawer overview photo missing")
        }
        
        return items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.checkered.circle.fill")
                    .foregroundColor(.green)
                Text("Completion Status")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 16) {
                // Overall completion
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Overall Completion")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", completionPercentage))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(completionPercentage >= 80 ? .green : completionPercentage >= 50 ? .orange : .red)
                    }
                    
                    ProgressView(value: completionPercentage, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: completionPercentage >= 80 ? .green : completionPercentage >= 50 ? .orange : .red))
                }
                
                // Missing data items
                if !missingDataItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Items Needing Attention")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ForEach(missingDataItems, id: \.self) { item in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("All data collection complete!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Components

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QualityMetricRow: View {
    let title: String
    let current: Int
    let total: Int
    let icon: String
    
    private var percentage: Double {
        total == 0 ? 0.0 : Double(current) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(current)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(percentage >= 0.8 ? .green : percentage >= 0.5 ? .orange : .red)
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: percentage >= 0.8 ? .green : percentage >= 0.5 ? .orange : .red))
        }
    }
}

// MARK: - Collection Browser View

struct CollectionBrowserView: View {
    @ObservedObject var collectionManager: CollectionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var collectionToDelete: SpecimenCollection?
    @State private var sortOption: CollectionSortOption = .dateNewest
    @State private var filterOption: CollectionFilterOption = .all
    
    private var filteredAndSortedCollections: [SpecimenCollection] {
        let filtered = collectionManager.availableCollections.filter { collection in
            switch filterOption {
            case .all:
                return true
            case .completed:
                return collection.isComplete
            case .inProgress:
                return !collection.isComplete
            }
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .dateNewest:
                return first.collectionDate > second.collectionDate
            case .dateOldest:
                return first.collectionDate < second.collectionDate
            case .localityAZ:
                return first.locality < second.locality
            case .localityZA:
                return first.locality > second.locality
            case .specimenCount:
                return first.specimens.count > second.specimens.count
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter and Sort Controls
            VStack(spacing: 12) {
                HStack {
                    Text("Collections")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(filteredAndSortedCollections.count) of \(collectionManager.availableCollections.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    Menu {
                        ForEach(CollectionFilterOption.allCases, id: \.self) { option in
                            Button(action: { filterOption = option }) {
                                HStack {
                                    Text(option.displayName)
                                    if filterOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filter: \(filterOption.displayName)")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Menu {
                        ForEach(CollectionSortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                HStack {
                                    Text(option.displayName)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down.circle")
                            Text("Sort: \(sortOption.displayName)")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Collections List
            if filteredAndSortedCollections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No collections found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Try adjusting your filter settings or create a new collection.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAndSortedCollections, id: \.id) { collection in
                            DetailedCollectionRowView(
                                collection: collection,
                                onSelect: {
                                    collectionManager.selectCollection(collection)
                                    dismiss()
                                },
                                onDelete: {
                                    collectionToDelete = collection
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("All Collections")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Collection?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { 
                collectionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let collection = collectionToDelete {
                    collectionManager.deleteCollection(collection)
                    collectionToDelete = nil
                }
            }
        } message: {
            if let collection = collectionToDelete {
                Text("Are you sure you want to delete '\(collection.locality)'? This will permanently remove all data including \(collection.specimens.count) specimens.")
            }
        }
    }
}

struct DetailedCollectionRowView: View {
    let collection: SpecimenCollection
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    private var completionPercentage: Double {
        guard !collection.specimens.isEmpty else { return 0.0 }
        let completedCount = collection.specimens.filter { $0.isComplete }.count
        return Double(completedCount) / Double(collection.specimens.count)
    }
    
    private var totalImages: Int {
        collection.specimens.reduce(0) { total, specimen in
            total + specimen.specimenImages.count + specimen.fieldBookImages.count
        } + (collection.drawerOverviewImageData != nil ? 1 : 0)
    }
    
    private var totalVoiceNotes: Int {
        collection.specimens.filter { $0.hasVoiceNote }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.locality)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("by \(collection.collectorName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        if collection.isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Complete")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle.dashed")
                                .foregroundColor(.orange)
                            Text("In Progress")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(collection.collectionDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Statistics
            HStack(spacing: 16) {
                StatBadge(icon: "fossil.shell", value: "\(collection.specimens.count)", label: "Specimens")
                StatBadge(icon: "photo", value: "\(totalImages)", label: "Images")
                StatBadge(icon: "mic", value: "\(totalVoiceNotes)", label: "Voice Notes")
                
                Spacer()
            }
            
            // Progress Bar
            if !collection.specimens.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Completion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(completionPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(completionPercentage >= 0.8 ? .green : completionPercentage >= 0.5 ? .orange : .red)
                    }
                    
                    ProgressView(value: completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: completionPercentage >= 0.8 ? .green : completionPercentage >= 0.5 ? .orange : .red))
                }
            }
            
            // Actions
            HStack {
                Button(action: onSelect) {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        Text("Open")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.blue)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Search View

struct SearchView: View {
    @ObservedObject var collectionManager: CollectionManager
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .all
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                    TextField("Search collections, specimens, or notes...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                // Search Scope Picker
                Picker("Search Scope", selection: $searchScope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.displayName).tag(scope)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Search Results
            if isSearching {
                VStack {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Search Your Collections")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You can search for:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SearchTipRow(icon: "location", text: "Collection localities")
                        SearchTipRow(icon: "person", text: "Collector names")
                        SearchTipRow(icon: "fossil.shell", text: "Specimen IDs and types")
                        SearchTipRow(icon: "mic", text: "Voice note transcriptions")
                        SearchTipRow(icon: "doc.text", text: "OCR text from images")
                        SearchTipRow(icon: "calendar", text: "Collection dates")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if searchResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.folder")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Results Found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Try different keywords or check your search scope.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults, id: \.id) { result in
                            SearchResultRowView(result: result, collectionManager: collectionManager)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { _, _ in
            if !searchText.isEmpty {
                performSearch()
            }
        }
        .onChange(of: searchScope) { _, _ in
            if !searchText.isEmpty {
                performSearch()
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Simulate search delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let results = searchInCollections()
            searchResults = results
            isSearching = false
        }
    }
    
    private func searchInCollections() -> [SearchResult] {
        let query = searchText.lowercased()
        var results: [SearchResult] = []
        
        for collection in collectionManager.availableCollections {
            // Search collection metadata
            if searchScope == .all || searchScope == .collections {
                if collection.locality.lowercased().contains(query) ||
                   collection.collectorName.lowercased().contains(query) {
                    results.append(SearchResult(
                        id: UUID(),
                        type: .collection,
                        title: collection.locality,
                        subtitle: "Collection by \(collection.collectorName)",
                        matchText: query,
                        collection: collection,
                        specimen: nil
                    ))
                }
            }
            
            // Search specimens
            if searchScope == .all || searchScope == .specimens {
                for specimen in collection.specimens {
                    var matchFound = false
                    var matchText = ""
                    
                    if specimen.specimenID.lowercased().contains(query) {
                        matchFound = true
                        matchText = "Specimen ID: \(specimen.specimenID)"
                    } else if specimen.stromatoliteAge.lowercased().contains(query) {
                        matchFound = true
                        matchText = "Age: \(specimen.stromatoliteAge)"
                    } else if specimen.structureType.lowercased().contains(query) {
                        matchFound = true
                        matchText = "Type: \(specimen.structureType)"
                    } else if specimen.mineralogy.lowercased().contains(query) {
                        matchFound = true
                        matchText = "Mineralogy: \(specimen.mineralogy)"
                    } else if specimen.localityCountry.lowercased().contains(query) {
                        matchFound = true
                        matchText = "Country: \(specimen.localityCountry)"
                    } else if specimen.localityStateProvince.lowercased().contains(query) {
                        matchFound = true
                        matchText = "State/Province: \(specimen.localityStateProvince)"
                    } else if specimen.localityNearestCity.lowercased().contains(query) {
                        matchFound = true
                        matchText = "City: \(specimen.localityNearestCity)"
                    } else if specimen.additionalNotes.lowercased().contains(query) {
                        matchFound = true
                        matchText = "Notes: \(String(specimen.additionalNotes.prefix(50)))"
                    }
                    
                    if matchFound {
                        results.append(SearchResult(
                            id: UUID(),
                            type: .specimen,
                            title: specimen.specimenID.isEmpty ? "Unnamed Specimen" : specimen.specimenID,
                            subtitle: "in \(collection.locality)",
                            matchText: matchText,
                            collection: collection,
                            specimen: specimen
                        ))
                    }
                }
            }
            
            // Search voice notes and OCR text
            if searchScope == .all || searchScope == .text {
                for specimen in collection.specimens {
                    if specimen.voiceNoteTranscription.lowercased().contains(query) {
                        results.append(SearchResult(
                            id: UUID(),
                            type: .voiceNote,
                            title: "Voice Note",
                            subtitle: "in \(specimen.specimenID.isEmpty ? "Unnamed Specimen" : specimen.specimenID)",
                            matchText: String(specimen.voiceNoteTranscription.prefix(100)),
                            collection: collection,
                            specimen: specimen
                        ))
                    }
                    
                    if specimen.ocrText.lowercased().contains(query) {
                        results.append(SearchResult(
                            id: UUID(),
                            type: .ocrText,
                            title: "OCR Text",
                            subtitle: "in \(specimen.specimenID.isEmpty ? "Unnamed Specimen" : specimen.specimenID)",
                            matchText: String(specimen.ocrText.prefix(100)),
                            collection: collection,
                            specimen: specimen
                        ))
                    }
                }
            }
        }
        
        return results
    }
}

struct SearchTipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SearchResultRowView: View {
    let result: SearchResult
    let collectionManager: CollectionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.type.icon)
                    .foregroundColor(result.type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(result.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    collectionManager.selectCollection(result.collection)
                    dismiss()
                }) {
                    Text("Open")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            
            if !result.matchText.isEmpty {
                Text(result.matchText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

enum CollectionSortOption: CaseIterable {
    case dateNewest, dateOldest, localityAZ, localityZA, specimenCount
    
    var displayName: String {
        switch self {
        case .dateNewest: return "Date (Newest)"
        case .dateOldest: return "Date (Oldest)"
        case .localityAZ: return "Locality (A-Z)"
        case .localityZA: return "Locality (Z-A)"
        case .specimenCount: return "Specimen Count"
        }
    }
}

enum CollectionFilterOption: CaseIterable {
    case all, completed, inProgress
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .completed: return "Completed"
        case .inProgress: return "In Progress"
        }
    }
}

enum SearchScope: CaseIterable {
    case all, collections, specimens, text
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .collections: return "Collections"
        case .specimens: return "Specimens"
        case .text: return "Text"
        }
    }
}

struct SearchResult {
    let id: UUID
    let type: SearchResultType
    let title: String
    let subtitle: String
    let matchText: String
    let collection: SpecimenCollection
    let specimen: SpecimenRecord?
}

enum SearchResultType {
    case collection, specimen, voiceNote, ocrText
    
    var icon: String {
        switch self {
        case .collection: return "folder"
        case .specimen: return "fossil.shell"
        case .voiceNote: return "mic"
        case .ocrText: return "doc.text"
        }
    }
    
    var color: Color {
        switch self {
        case .collection: return .blue
        case .specimen: return .green
        case .voiceNote: return .orange
        case .ocrText: return .purple
        }
    }
}

struct CompletionView: View {
    @ObservedObject var workflowController: WorkflowController
    @StateObject private var exportManager = DataExportManager()
    @State private var showingExportSheet = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Collection Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Your stromatolite collection has been successfully documented.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Text("Collection Summary")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Locality:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(workflowController.collection.locality)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Collector:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(workflowController.collection.collectorName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(workflowController.collection.collectionDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Specimens:")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(workflowController.collection.specimens.count)")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Collection Data")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                if let lastResult = exportManager.lastExportResult, lastResult.success {
                    Button(action: {
                        if let url = lastResult.exportPath {
                            exportURL = url
                            showingShareSheet = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Share Last Export")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingExportSheet) {
            ExportView(
                collection: workflowController.collection,
                exportManager: exportManager
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    let collection: SpecimenCollection
    @ObservedObject var exportManager: DataExportManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingResult = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Export Collection")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Export all collection data including photos, audio recordings, and metadata to your device's Files app.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("What will be exported:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ExportItemRow(icon: "doc.text", title: "Collection metadata (JSON)", description: "Structured data for external processing")
                        ExportItemRow(icon: "photo", title: "All photographs", description: "Specimen images, field book pages, drawer overview")
                        ExportItemRow(icon: "mic", title: "Voice recordings", description: "Audio files ready for speech-to-text processing")
                        ExportItemRow(icon: "doc.plaintext", title: "Documentation", description: "README files with processing instructions")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if exportManager.isExporting {
                    VStack(spacing: 12) {
                        ProgressView(value: exportManager.exportProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        Text("Exporting... \(Int(exportManager.exportProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: {
                        Task {
                            let _ = await exportManager.exportCollection(collection)
                            showingResult = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Start Export")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Export Complete", isPresented: $showingResult) {
            if let result = exportManager.lastExportResult {
                if result.success {
                    Button("Open in Files") {
                        if let url = result.exportPath {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("OK") { }
                } else {
                    Button("OK") { }
                }
            }
        } message: {
            if let result = exportManager.lastExportResult {
                if result.success {
                    Text("Successfully exported \(result.filesExported) files (\(ByteCountFormatter().string(fromByteCount: result.totalSize)))")
                } else {
                    Text("Export failed: \(result.error ?? "Unknown error")")
                }
            }
        }
    }
}

struct ExportItemRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
