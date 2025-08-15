import Foundation
import SwiftUI

@MainActor
class PlantDetailsViewModel: ObservableObject {
    @Published var plant: Plant = Plant(name: "", bedId: UUID(), x: 0.5, y: 0.5)
    @Published var plantInfo: PlantInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAISearch = false
    
    private let aiService = AIPlantSearchService.shared
    private let dataService = DataService.shared
    
    init() {}
    
    init(plant: Plant) {
        self.plant = plant
    }
    
    // Check if we have comprehensive plant data from AI
    var hasPlantData: Bool {
        plantInfo != nil
    }
    
    // Check if the plant is valid for saving
    var isValid: Bool {
        !plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Apply AI plant information to the plant
    func applyPlantInfo(_ info: PlantInfo) {
        plantInfo = info
        
        // Update basic plant information
        if plant.name.isEmpty {
            plant.name = info.name
        }
        
        // Update other plant properties from AI data
        plant.scientificName = info.scientificName
        plant.growthHabit = info.growthHabit
        plant.sunExposure = info.sunExposure
        plant.waterNeeds = info.waterNeeds
        plant.notes = info.careInstructions
    }
    
    // Get plant information from AI service
    func fetchPlantInfo(for plantName: String) async {
        guard !plantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let info = try await aiService.getPlantInfo(for: plantName)
            applyPlantInfo(info)
        } catch {
            errorMessage = "Failed to get plant information: \(error.localizedDescription)"
            print("Error fetching plant info: \(error)")
        }
        
        isLoading = false
    }
    
    // Save plant data
    func savePlant() async {
        guard isValid else {
            errorMessage = "Please enter a plant name"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // First, save the basic plant to the database
            try await dataService.savePlant(plant)
            
            // If we have AI plant info, we could also save additional details
            // to a separate table or extend the plant model
            if let info = plantInfo {
                // TODO: Save additional AI plant info to plant_details table
                print("AI plant info available for plant: \(info.name)")
                print("Scientific name: \(info.scientificName)")
                print("Care instructions: \(info.careInstructions ?? "None")")
            }
            
            // Reset form after successful save
            reset()
        } catch {
            errorMessage = "Failed to save plant: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Reset to empty state
    func reset() {
        plant = Plant(name: "", bedId: UUID(), x: 0.5, y: 0.5)
        plantInfo = nil
        errorMessage = nil
    }
    
    // Update plant name and fetch AI info
    func updatePlantName(_ name: String) {
        plant.name = name
        
        // If we have a valid plant name, fetch AI information
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                await fetchPlantInfo(for: name)
            }
        } else {
            // Clear AI info if name is empty
            plantInfo = nil
        }
    }
}

// MARK: - Preview Helpers
extension PlantDetailsViewModel {
    static func withMockData() -> PlantDetailsViewModel {
        let viewModel = PlantDetailsViewModel()
        viewModel.plant = Plant(
            name: "",
            bedId: UUID(),
            x: 0.5,
            y: 0.5
        )
        return viewModel
    }
}
