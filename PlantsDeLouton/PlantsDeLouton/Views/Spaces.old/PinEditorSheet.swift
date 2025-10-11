import SwiftUI

struct PinEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gardenAPI: GardenAPI
    @State var pin: Pin
    @State private var plantName: String
    @State private var plantType: PlantType
    @State private var notes: String
    @State private var isUpdating = false
    
    init(pin: Pin, gardenAPI: GardenAPI) {
        self._pin = State(initialValue: pin)
        self._plantName = State(initialValue: pin.name)
        self._plantType = State(initialValue: pin.type)
        self._notes = State(initialValue: pin.notes ?? "")
        self.gardenAPI = gardenAPI
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Plant Details") {
                    TextField("Plant Name", text: $plantName)
                    
                    Picker("Plant Type", selection: $plantType) {
                        ForEach(PlantType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized)
                                .tag(type)
                        }
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Position") {
                    HStack {
                        Text("X Position")
                        Spacer()
                        Text("\(Int(pin.x))")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Y Position")
                        Spacer()
                        Text("\(Int(pin.y))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Plant Pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updatePin()
                    }
                    .disabled(plantName.isEmpty || isUpdating)
                }
            }
        }
    }
    
    private func updatePin() {
        guard !plantName.isEmpty else { return }
        
        isUpdating = true
        
        Task {
            do {
                let updatedPin = Pin(
                    id: pin.id,
                    bedId: pin.bedId,
                    name: plantName,
                    type: plantType,
                    health: pin.health,
                    x: pin.x,
                    y: pin.y,
                    notes: notes.isEmpty ? nil : notes,
                    sunNeeds: pin.sunNeeds,
                    waterNeeds: pin.waterNeeds
                )
                
                try await gardenAPI.updatePin(updatedPin)
                
                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    print("Error updating pin: \(error)")
                }
            }
        }
    }
}
