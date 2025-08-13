import Foundation
import SwiftUI

@MainActor
class PlantDetailsViewModel: ObservableObject {
    @Published var plant: Plant = Plant(name: "")
    @Published var selectedPlantData: AIPlantSearchResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {}
    
    init(plant: Plant) {
        self.plant = plant
    }
    
    // Check if we have comprehensive plant data from AI search
    var hasPlantData: Bool {
        selectedPlantData != nil
    }
    
    // Apply AI search data to the plant
    func applyAISearchData(_ searchResult: AIPlantSearchResult) {
        selectedPlantData = searchResult
        
        // Update basic plant information
        if plant.name.isEmpty {
            plant.name = searchResult.name
        }
        
        // Update other plant properties from AI data
        plant.scientificName = searchResult.scientificName
        plant.growthHabit = searchResult.growthHabit.rawValue
        plant.sunExposure = searchResult.sunExposure.rawValue
        plant.waterNeeds = searchResult.waterNeeds.rawValue
    }
    
    // Save plant data
    func savePlant() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Connect to your actual save service
            try await DataService.shared.savePlant(plant)
        } catch {
            errorMessage = "Failed to save plant: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Reset to empty state
    func reset() {
        plant = Plant(name: "")
        selectedPlantData = nil
        errorMessage = nil
    }
    
    // Validation
    var isValid: Bool {
        !plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var validationMessage: String? {
        if plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Plant name is required"
        }
        return nil
    }
}

// MARK: - Preview Helpers
extension PlantDetailsViewModel {
    static func withMockData() -> PlantDetailsViewModel {
        let viewModel = PlantDetailsViewModel()
        viewModel.plant = Plant(
            name: "Tomato",
            scientificName: "Solanum lycopersicum",
            growthHabit: "annual",
            sunExposure: "full_sun",
            waterNeeds: "moderate",
            plantedDate: Date(),
            healthStatus: "Healthy"
        )
        
        viewModel.selectedPlantData = AIPlantSearchResult(
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
        
        return viewModel
    }
}
