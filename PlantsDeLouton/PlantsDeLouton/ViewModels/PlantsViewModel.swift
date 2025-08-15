import Foundation
import SwiftUI

@MainActor
class PlantsViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""
    
    private let dataService = DataService.shared
    
    var filteredPlants: [Plant] {
        if searchText.isEmpty {
            return plants
        }
        return plants.filter { plant in
            plant.name.localizedCaseInsensitiveContains(searchText) ||
            plant.scientificName?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    func loadPlants() async {
        isLoading = true
        error = nil
        
        do {
            plants = try await dataService.fetchPlants()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deletePlant(_ plant: Plant) async {
        do {
            try await dataService.deletePlant(plant.id)
            plants.removeAll { $0.id == plant.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshPlants() async {
        await loadPlants()
    }
}