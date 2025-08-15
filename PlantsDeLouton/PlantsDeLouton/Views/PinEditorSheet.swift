import SwiftUI

struct PinEditorSheet: View {
    let pin: Pin
    let bedId: String
    let onSave: (Pin) -> Void
    
    @StateObject private var aiService = AIPlantSearchService.shared
    @State private var name: String
    @State private var notes: String
    @State private var status: PinStatus
    @State private var showingAISearch = false
    @State private var identifiedPlant: AIPlantSearchResult?
    @State private var showingDeleteConfirmation = false
    @State private var isSaving = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(pin: Pin, bedId: String, onSave: @escaping (Pin) -> Void) {
        self.pin = pin
        self.bedId = bedId
        self.onSave = onSave
        self._name = State(initialValue: pin.name ?? "")
        self._notes = State(initialValue: pin.notes ?? "")
        self._status = State(initialValue: pin.status)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Plant Information Section
                Section("Plant Information") {
                    TextField("Plant Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Status Section
                Section("Status") {
                    Picker("Plant Status", selection: $status) {
                        ForEach(PinStatus.allCases, id: \.self) { status in
                            HStack {
                                Image(systemName: statusIcon(for: status))
                                    .foregroundColor(statusColor(for: status))
                                Text(status.displayName)
                            }
                            .tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // AI Plant Search Section
                Section("AI Plant Identification") {
                    Button(action: {
                        showingAISearch = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Identify Plant with AI")
                        }
                    }
                    
                    if let identifiedPlant = identifiedPlant {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Identified: \(identifiedPlant.name)")
                                    .font(.headline)
                            }
                            
                            Text(identifiedPlant.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let careInstructions = identifiedPlant.careInstructions {
                                Text("Care: \(careInstructions)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Pin Details Section
                Section("Pin Details") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(pin.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    if let updatedAt = pin.updatedAt {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(updatedAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Position")
                        Spacer()
                        Text("(\(String(format: "%.1f", pin.x * 100))%, \(String(format: "%.1f", pin.y * 100))%)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Care Schedule Section
                Section("Care Schedule") {
                    if let lastCareDate = pin.lastCareDate {
                        HStack {
                            Text("Last Care")
                            Spacer()
                            Text(lastCareDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let nextCareDate = pin.nextCareDate {
                        HStack {
                            Text("Next Care")
                            Spacer()
                            Text(nextCareDate, style: .date)
                                .foregroundColor(pin.needsCare ? .red : .secondary)
                        }
                    }
                    
                    Button("Schedule Care") {
                        // TODO: Implement care scheduling
                    }
                    .disabled(true) // TODO: Implement this feature
                }
                
                // Danger Zone Section
                Section {
                    Button("Delete Pin") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePin()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
        .sheet(isPresented: $showingAISearch) {
            PlantSearchSheet { aiPlant in
                identifiedPlant = aiPlant
                name = aiPlant.name
                notes = aiPlant.description
            }
        }
        .alert("Delete Pin", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deletePin()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this pin? This action cannot be undone.")
        }
    }
    
    private func savePin() {
        isSaving = true
        
        let updatedPin = Pin(
            id: pin.id,
            bedId: pin.bedId,
            imageId: pin.imageId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            x: pin.x,
            y: pin.y,
            createdAt: pin.createdAt,
            updatedAt: Date(),
            plantId: identifiedPlant?.id ?? pin.plantId,
            imageUrl: pin.imageUrl,
            plantInstanceId: pin.plantInstanceId,
            plantDetailsId: pin.plantDetailsId,
            status: status,
            lastCareDate: pin.lastCareDate,
            nextCareDate: pin.nextCareDate
        )
        
        onSave(updatedPin)
        dismiss()
    }
    
    private func deletePin() {
        // TODO: Implement pin deletion
        dismiss()
    }
    
    private func statusIcon(for status: PinStatus) -> String {
        switch status {
        case .active: return "leaf.fill"
        case .dormant: return "leaf"
        case .removed: return "minus.circle.fill"
        case .dead: return "xmark.circle.fill"
        }
    }
    
    private func statusColor(for status: PinStatus) -> Color {
        switch status {
        case .active: return .green
        case .dormant: return .orange
        case .removed: return .gray
        case .dead: return .red
        }
    }
}

#Preview {
    PinEditorSheet(
        pin: Pin(
            id: UUID().uuidString,
            bedId: UUID().uuidString,
            imageId: nil,
            name: "New Plant",
            notes: "Plant notes",
            x: 0.5,
            y: 0.5,
            createdAt: Date(),
            updatedAt: nil,
            plantId: nil,
            imageUrl: nil,
            plantInstanceId: nil,
            plantDetailsId: nil,
            status: .active,
            lastCareDate: nil,
            nextCareDate: nil
        )
    ) { _ in }
}
