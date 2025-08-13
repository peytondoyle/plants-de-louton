import Foundation
import SwiftUI

@MainActor
class GardenViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var beds: [Bed] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        plants = [
            Plant(name: "Rose", scientificName: "Rosa", growthHabit: "Shrub"),
            Plant(name: "Tomato", scientificName: "Solanum lycopersicum", growthHabit: "Annual"),
            Plant(name: "Lavender", scientificName: "Lavandula", growthHabit: "Perennial")
        ]
        
        beds = [
            Bed(name: "North Bed", section: "Front Garden"),
            Bed(name: "South Bed", section: "Front Garden"),
            Bed(name: "Vegetable Patch", section: "Back Garden")
        ]
    }
    
    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadMockData()
        isLoading = false
    }
}
