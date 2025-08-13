import Foundation
import SwiftUI

@MainActor
class PlantDetailsViewModel: ObservableObject {
    @Published var plant: Plant = Plant(name: "", bedId: UUID(), x: 0.5, y: 0.5)
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
        plant = Plant(name: "", bedId: UUID(), x: 0.5, y: 0.5)
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
            name: "",
            bedId: UUID(),
            x: 0.5,
            y: 0.5
        )
        return viewModel
    }
}
