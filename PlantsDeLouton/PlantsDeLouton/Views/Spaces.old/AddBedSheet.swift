import SwiftUI

struct AddBedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gardenAPI: GardenAPI
    let space: Space
    @State private var bedName = ""
    @State private var bedDescription = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Bed Details") {
                    TextField("Bed Name", text: $bedName)
                    TextField("Description (optional)", text: $bedDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Space") {
                    HStack {
                        Text("Space")
                        Spacer()
                        Text(space.name)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Bed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createBed()
                    }
                    .disabled(bedName.isEmpty || isCreating)
                }
            }
        }
    }
    
    private func createBed() {
        guard !bedName.isEmpty else { return }
        
        isCreating = true
        
        Task {
            do {
                let newBed = Bed(
                    spaceId: space.id,
                    name: bedName,
                    description: bedDescription.isEmpty ? nil : bedDescription,
                    imageURL: nil
                )
                
                try await gardenAPI.createBed(newBed)
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    print("Error creating bed: \(error)")
                }
            }
        }
    }
}
