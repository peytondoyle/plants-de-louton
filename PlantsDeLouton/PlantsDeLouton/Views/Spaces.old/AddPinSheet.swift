import SwiftUI

struct AddPinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gardenAPI: GardenAPI
    let bed: Bed
    let position: CGPoint
    @State private var plantName = ""
    @State private var plantType: PlantType = .vegetable
    @State private var notes = ""
    @State private var isCreating = false
    
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
                        Text("\(Int(position.x))")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Y Position")
                        Spacer()
                        Text("\(Int(position.y))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Plant Pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPin()
                    }
                    .disabled(plantName.isEmpty || isCreating)
                }
            }
        }
    }
    
    private func createPin() {
        guard !plantName.isEmpty else { return }
        
        isCreating = true
        
        Task {
            do {
                let newPin = Pin(
                    bedId: bed.id,
                    name: plantName,
                    type: plantType,
                    x: position.x,
                    y: position.y,
                    notes: notes.isEmpty ? nil : notes
                )
                
                try await gardenAPI.createPin(newPin)
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    print("Error creating pin: \(error)")
                }
            }
        }
    }
}
