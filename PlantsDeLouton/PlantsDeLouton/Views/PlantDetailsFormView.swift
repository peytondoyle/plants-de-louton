import SwiftUI

struct PlantDetailsFormView: View {
    @Binding var plant: Plant
    let plantSearchData: AIPlantSearchResult?
    
    var body: some View {
        VStack(spacing: 20) {
            if let searchData = plantSearchData {
                // AI Success Card
                AISuccessCard(plantData: searchData)
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
                    
                    if let searchData = plantSearchData {
                        FormField(title: "Scientific Name") {
                            TextField("Scientific name", text: .constant(searchData.scientificName))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.secondary)
                        }
                        
                        FormField(title: "Growth Habit") {
                            TextField("Growth habit", text: .constant(searchData.growthHabit.displayName))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.secondary)
                        }
                        
                        FormField(title: "Sun Exposure") {
                            HStack {
                                Image(systemName: searchData.sunExposure.icon)
                                    .foregroundColor(.orange)
                                TextField("Sun exposure", text: .constant(searchData.sunExposure.displayName))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        FormField(title: "Water Needs") {
                            HStack {
                                Image(systemName: searchData.waterNeeds.icon)
                                    .foregroundColor(.blue)
                                TextField("Water needs", text: .constant(searchData.waterNeeds.displayName))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Plant Size Information
                        HStack(spacing: 12) {
                            FormField(title: "Mature Height") {
                                TextField("Height", text: .constant("\(Int(searchData.matureHeight))\""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                            
                            FormField(title: "Mature Width") {
                                TextField("Width", text: .constant("\(Int(searchData.matureWidth))\""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Care Information
                        FormField(title: "Planting Season") {
                            TextField("Season", text: .constant(searchData.plantingSeason.rawValue.capitalized))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.secondary)
                        }
                        
                        FormField(title: "Bloom Time") {
                            HStack {
                                Text("🌸")
                                TextField("Bloom time", text: .constant(searchData.bloomTime.rawValue.capitalized))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Flower Colors
                        if !searchData.flowerColor.isEmpty {
                            FormField(title: "Flower Colors") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(searchData.flowerColor, id: \.self) { color in
                                            Text(color.capitalized)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(colorForName(color).opacity(0.2))
                                                )
                                                .foregroundColor(colorForName(color))
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                    }
                    
                    // Health Status (user editable)
                    FormField(title: "Health Status") {
                        TextField("Health status", text: Binding(
                            get: { plant.healthStatus },
                            set: { plant.healthStatus = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Planted Date (user editable)
                    FormField(title: "Planted Date") {
                        DatePicker(
                            "Planted Date",
                            selection: Binding(
                                get: { plant.plantedDate ?? Date() },
                                set: { plant.plantedDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private func colorForName(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "pink": return .pink
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "white": return .gray
        default: return .gray
        }
    }
}

struct AISuccessCard: View {
    let plantData: AIPlantSearchResult
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Search Complete!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Found detailed information for \(plantData.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick Summary
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickInfoCard(
                    icon: "info.circle.fill",
                    title: "Family",
                    value: plantData.family,
                    color: .blue
                )
                QuickInfoCard(
                    icon: "calendar",
                    title: "Growth Type",
                    value: plantData.growthHabit.displayName,
                    color: .green
                )
                QuickInfoCard(
                    icon: plantData.sunExposure.icon,
                    title: "Sun Needs",
                    value: plantData.sunExposure.displayName,
                    color: .orange
                )
                QuickInfoCard(
                    icon: plantData.waterNeeds.icon,
                    title: "Water Needs",
                    value: plantData.waterNeeds.displayName,
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct FormField<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            content
        }
    }
}

#Preview {
    ScrollView {
        PlantDetailsFormView(
            plant: .constant(Plant(name: "Test Plant")),
            plantSearchData: AIPlantSearchResult(
                name: "Tomato",
                scientificName: "Solanum lycopersicum",
                commonNames: ["Tomato", "Love Apple"],
                family: "Solanaceae",
                genus: "Solanum",
                species: "lycopersicum",
                growthHabit: .annual,
                hardinessZones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
                sunExposure: .fullSun,
                waterNeeds: .moderate,
                matureHeight: 60,
                matureWidth: 24,
                bloomTime: .summer,
                bloomDuration: 12,
                flowerColor: ["yellow"],
                foliageColor: ["green"],
                soilType: .wellDraining,
                soilPH: .neutral,
                fertilizerNeeds: .moderate,
                pruningNeeds: .moderate,
                plantingSeason: .spring,
                plantingDepth: 0.25,
                spacing: 24
            )
        )
        .padding()
    }
}
