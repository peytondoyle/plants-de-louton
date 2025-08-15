import SwiftUI

struct PlantDetailsView: View {
    @StateObject private var viewModel = PlantDetailsViewModel()
    @State private var showingSearchSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Plant Image Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    )
                
                // Plant Information
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.plant.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let scientificName = viewModel.plant.scientificName {
                            Text(scientificName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    // Plant Details Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        if let growthHabit = viewModel.plant.growthHabit {
                            PlantDetailCard(
                                icon: "leaf.fill",
                                title: "Growth Habit",
                                value: growthHabit
                            )
                        }
                        
                        if let sunExposure = viewModel.plant.sunExposure {
                            PlantDetailCard(
                                icon: "sun.max.fill",
                                title: "Sun Exposure",
                                value: sunExposure
                            )
                        }
                        
                        if let waterNeeds = viewModel.plant.waterNeeds {
                            PlantDetailCard(
                                icon: "drop.fill",
                                title: "Water Needs",
                                value: waterNeeds
                            )
                        }
                        
                        PlantDetailCard(
                            icon: "location.fill",
                            title: "Location",
                            value: "Bed \(viewModel.plant.bedId.uuidString.prefix(8))"
                        )
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingSearchSheet = true
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search Plant Info")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.blue)
                            )
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        }
                        
                        Button(action: {
                            Task {
                                try? await viewModel.savePlant()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Changes")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.green, lineWidth: 1)
                            )
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Plant Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSearchSheet) {
            PlantSearchSheet { aiPlant in
                viewModel.applyAISearchData(aiPlant)
            }
        }
    }
}

struct PlantDetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    NavigationView {
        PlantDetailsView()
    }
}
