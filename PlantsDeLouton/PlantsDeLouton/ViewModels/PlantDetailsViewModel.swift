import Foundation

class PlantDetailsViewModel: ObservableObject {
    @Published var plant: Plant
    @Published var selectedPlantData: AIPlantSearchResult?
    @Published var isLoading = false
    @Published var error: String?
    
    init(plant: Plant = Plant(name: "New Plant", bedId: UUID(), x: 0.5, y: 0.5)) {
        self.plant = plant
    }
    
    func applyAISearchData(_ searchResult: AIPlantSearchResult) {
        selectedPlantData = searchResult
        
        // Update plant with AI data
        plant.name = searchResult.name
        
        if let scientificName = searchResult.scientificName {
            plant.scientificName = scientificName
        }
        
        // Update plant properties based on AI data
        plant.growthHabit = searchResult.growthHabit.rawValue
        plant.sunExposure = searchResult.sunExposure.rawValue
        plant.waterNeeds = searchResult.waterNeeds.rawValue
    }
    
    func savePlant() async throws {
        isLoading = true
        error = nil
        
        do {
            let savedPlant = try await DataService.shared.savePlant(plant)
            await MainActor.run {
                self.plant = savedPlant
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    func deletePlant() async throws {
        isLoading = true
        error = nil
        
        do {
            try await DataService.shared.deletePlant(plant.id)
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
}
