import SwiftUI

struct AddSpaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gardenAPI: GardenAPI
    @State private var spaceName = ""
    @State private var spaceDescription = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Space Details") {
                    TextField("Space Name", text: $spaceName)
                    TextField("Description (optional)", text: $spaceDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSpace()
                    }
                    .disabled(spaceName.isEmpty || isCreating)
                }
            }
        }
    }
    
    private func createSpace() {
        guard !spaceName.isEmpty else { return }
        
        isCreating = true
        
        Task {
            do {
                let newSpace = Space(
                    name: spaceName,
                    description: spaceDescription.isEmpty ? nil : spaceDescription
                )
                
                try await gardenAPI.createSpace(newSpace)
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    print("Error creating space: \(error)")
                }
            }
        }
    }
}
