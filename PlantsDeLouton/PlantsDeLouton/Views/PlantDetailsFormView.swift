import SwiftUI

struct PlantDetailsFormView: View {
    @Binding var plant: Plant
    let plantInfo: PlantInfo?
    @StateObject private var bedsViewModel = BedsViewModel()
    @State private var showingBedSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let info = plantInfo {
                // AI Success Card
                AISuccessCard(plantInfo: info)
            }
            
            // Plant Information Form
            VStack(spacing: 16) {
                Text("Plant Information")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Basic Information
                VStack(spacing: 12) {
                    FormField(title: "Plant Name") {
                        TextField("Enter plant name", text: Binding(
                            get: { plant.name },
                            set: { plant.name = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Bed Assignment
                    FormField(title: "Assigned Bed") {
                        Button(action: { showingBedSelection = true }) {
                            HStack {
                                if let bedName = getBedName(for: plant.bedId) {
                                    Text(bedName)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select a bed")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .sheet(isPresented: $showingBedSelection) {
                            BedSelectionSheet(selectedBedId: $plant.bedId)
                        }
                    }
                    
                    // Scientific Name (from AI)
                    if let scientificName = plant.scientificName, !scientificName.isEmpty {
                        FormField(title: "Scientific Name") {
                            Text(scientificName)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Growth Habit (from AI)
                    if let growthHabit = plant.growthHabit, !growthHabit.isEmpty {
                        FormField(title: "Growth Habit") {
                            Text(growthHabit)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Sun Exposure (from AI)
                    if let sunExposure = plant.sunExposure, !sunExposure.isEmpty {
                        FormField(title: "Sun Exposure") {
                            Text(sunExposure)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Water Needs (from AI)
                    if let waterNeeds = plant.waterNeeds, !waterNeeds.isEmpty {
                        FormField(title: "Water Needs") {
                            Text(waterNeeds)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Notes
                    FormField(title: "Notes") {
                        TextField("Add notes about this plant", text: Binding(
                            get: { plant.notes ?? "" },
                            set: { plant.notes = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .task {
            await bedsViewModel.loadBeds()
        }
    }
    
    // Helper methods
    private func getBedName(for bedId: UUID) -> String? {
        bedsViewModel.beds.first { $0.id == bedId }?.name
    }
}

// MARK: - AI Success Card
struct AISuccessCard: View {
    let plantInfo: PlantInfo
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI Plant Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                if let description = plantInfo.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                if let careInstructions = plantInfo.careInstructions {
                    Text("Care: \(careInstructions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Form Field Helper
struct FormField<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            content
        }
    }
}

// MARK: - Bed Selection Sheet
struct BedSelectionSheet: View {
    @Binding var selectedBedId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bedsViewModel = BedsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bedsViewModel.beds) { bed in
                    Button(action: {
                        selectedBedId = bed.id
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(bed.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !bed.section.isEmpty {
                                    Text(bed.section)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedBedId == bed.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Bed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await bedsViewModel.loadBeds()
        }
    }
}
