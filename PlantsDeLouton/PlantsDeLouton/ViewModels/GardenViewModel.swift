import Foundation
import SwiftUI

@MainActor
class GardenViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var beds: [Bed] = []
    @Published var careEvents: [CareEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        let mockBedId = UUID()
        
        plants = [
            Plant(name: "Rose", bedId: mockBedId, x: 0.5, y: 0.5, scientificName: "Rosa", growthHabit: "Shrub"),
            Plant(name: "Tomato", bedId: mockBedId, x: 0.3, y: 0.7, scientificName: "Solanum lycopersicum", growthHabit: "Annual"),
            Plant(name: "Lavender", bedId: mockBedId, x: 0.7, y: 0.3, scientificName: "Lavandula", growthHabit: "Perennial")
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
