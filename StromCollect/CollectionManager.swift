import SwiftUI
import SwiftData
import Foundation

// MARK: - Collection Manager
@MainActor
class CollectionManager: ObservableObject {
    @Published var currentCollection: SpecimenCollection?
    @Published var availableCollections: [SpecimenCollection] = []
    @Published var isLoadingCollections = false
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCollections()
    }
    
    func loadCollections() {
        guard let context = modelContext else { return }
        
        isLoadingCollections = true
        
        do {
            let descriptor = FetchDescriptor<SpecimenCollection>(
                sortBy: [SortDescriptor(\.collectionDate, order: .reverse)]
            )
            availableCollections = try context.fetch(descriptor)
            
            // If we have collections but no current collection, set the most recent incomplete one
            if currentCollection == nil {
                currentCollection = availableCollections.first { !$0.isComplete }
            }
            
        } catch {
            print("Failed to load collections: \(error)")
        }
        
        isLoadingCollections = false
    }
    
    func createNewCollection(locality: String, collectorName: String) {
        guard let context = modelContext else { return }
        
        let newCollection = SpecimenCollection(locality: locality, collectorName: collectorName)
        context.insert(newCollection)
        
        do {
            try context.save()
            currentCollection = newCollection
            loadCollections() // Refresh the list
        } catch {
            print("Failed to save new collection: \(error)")
        }
    }
    
    func selectCollection(_ collection: SpecimenCollection) {
        currentCollection = collection
    }
    
    func deleteCollection(_ collection: SpecimenCollection) {
        guard let context = modelContext else { return }
        
        context.delete(collection)
        
        do {
            try context.save()
            
            // If we deleted the current collection, clear it
            if currentCollection?.id == collection.id {
                currentCollection = nil
            }
            
            loadCollections()
        } catch {
            print("Failed to delete collection: \(error)")
        }
    }
    
    func markCollectionComplete(_ collection: SpecimenCollection) {
        guard let context = modelContext else { return }
        
        collection.isComplete = true
        
        do {
            try context.save()
            loadCollections()
        } catch {
            print("Failed to mark collection complete: \(error)")
        }
    }
    
    var hasActiveCollection: Bool {
        currentCollection != nil && !(currentCollection?.isComplete ?? true)
    }
    
    var needsNewCollection: Bool {
        availableCollections.isEmpty || !hasActiveCollection
    }
}

// MARK: - Collection Selection View
struct CollectionSelectionView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var workflowController: WorkflowController
    @State private var showingNewCollectionSheet = false
    @State private var showingFirstDeleteAlert = false
    @State private var showingSecondDeleteAlert = false
    @State private var collectionToDelete: SpecimenCollection?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Stromatolite Collections")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Select an existing collection to continue working, or create a new one.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if collectionManager.isLoadingCollections {
                    ProgressView("Loading collections...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if collectionManager.availableCollections.isEmpty {
                    VStack(spacing: 16) {
                        Text("No collections yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Create your first stromatolite collection to get started.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(collectionManager.availableCollections, id: \.id) { collection in
                                CollectionRowView(
                                    collection: collection,
                                    isSelected: collectionManager.currentCollection?.id == collection.id,
                                    onSelect: {
                                        collectionManager.selectCollection(collection)
                                        workflowController.collection = collection
                                        
                                        // Set appropriate workflow state
                                        if collection.isComplete {
                                            workflowController.currentState = .completion
                                        } else if !collection.locality.isEmpty && !collection.collectorName.isEmpty {
                                            // Skip setup if collection info is already filled
                                            workflowController.currentState = .drawerOverview
                                        } else {
                                            workflowController.currentState = .setup
                                        }
                                    },
                                    onDelete: {
                                        collectionToDelete = collection
                                        showingFirstDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Button(action: {
                    showingNewCollectionSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create New Collection")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionView(collectionManager: collectionManager, workflowController: workflowController)
        }
        .alert("Delete Collection?", isPresented: $showingFirstDeleteAlert) {
            Button("Cancel", role: .cancel) { 
                collectionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                showingSecondDeleteAlert = true
            }
        } message: {
            if let collection = collectionToDelete {
                Text("Are you sure you want to delete the collection '\(collection.locality)'?\n\nThis collection contains \(collection.specimens.count) specimen(s) and all data will be permanently lost.")
            }
        }
        .alert("Final Confirmation", isPresented: $showingSecondDeleteAlert) {
            Button("Cancel", role: .cancel) { 
                collectionToDelete = nil
            }
            Button("Delete Forever", role: .destructive) {
                if let collection = collectionToDelete {
                    collectionManager.deleteCollection(collection)
                    collectionToDelete = nil
                }
            }
        } message: {
            if let collection = collectionToDelete {
                Text("This is your final warning!\n\nDeleting '\(collection.locality)' will permanently remove:\n• All specimen records\n• All photographs\n• All voice notes\n• All field book images\n\nThis action CANNOT be undone.")
            }
        }
    }
}

// MARK: - Collection Row View
struct CollectionRowView: View {
    let collection: SpecimenCollection
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(collection.locality)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if collection.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle.dashed")
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Label(collection.collectorName, systemImage: "person")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(collection.collectionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(collection.specimens.count) specimens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(collection.isComplete ? "Complete" : "In Progress")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(collection.isComplete ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(collection.isComplete ? .green : .orange)
                        .cornerRadius(4)
                }
            }
            
            VStack(spacing: 8) {
                Button(action: onSelect) {
                    Text(isSelected ? "Selected" : "Select")
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(isSelected)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(6)
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - New Collection View
struct NewCollectionView: View {
    @ObservedObject var collectionManager: CollectionManager
    @ObservedObject var workflowController: WorkflowController
    @Environment(\.dismiss) private var dismiss
    
    @State private var locality = ""
    @State private var collectorName = ""
    @State private var collectionDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("New Collection")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter the basic information for this collection session.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Locality/Location")
                            .font(.headline)
                        TextField("Enter collection locality", text: $locality)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.next)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Collector Name")
                            .font(.headline)
                        TextField("Enter collector name", text: $collectorName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.done)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Collection Date")
                            .font(.headline)
                        DatePicker("", selection: $collectionDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: {
                    collectionManager.createNewCollection(locality: locality, collectorName: collectorName)
                    workflowController.collection = collectionManager.currentCollection ?? SpecimenCollection()
                    workflowController.collection.collectionDate = collectionDate
                    workflowController.currentState = .drawerOverview
                    dismiss()
                }) {
                    Text("Create Collection")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canCreateCollection ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canCreateCollection)
            }
            .padding()
            .navigationTitle("New Collection")
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
    
    private var canCreateCollection: Bool {
        !locality.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !collectorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
