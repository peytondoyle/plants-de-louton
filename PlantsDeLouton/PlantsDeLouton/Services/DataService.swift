import Foundation

class DataService {
    static let shared = DataService()
    
    private init() {}
    
    func fetchPlants() async throws -> [Plant] {
        // Simple mock data
        let mockBedId = UUID()
        return [
            Plant(name: "Rose", bedId: mockBedId, x: 0.5, y: 0.5, scientificName: "Rosa"),
            Plant(name: "Tomato", bedId: mockBedId, x: 0.3, y: 0.7, scientificName: "Solanum lycopersicum"),
            Plant(name: "Lavender", bedId: mockBedId, x: 0.7, y: 0.3, scientificName: "Lavandula")
        ]
    }
    
    func fetchBeds() async throws -> [Bed] {
        // Simple mock data
        return [
            Bed(name: "North Bed", section: "Front Garden"),
            Bed(name: "South Bed", section: "Front Garden")
        ]
    }
    
    func savePlant(_ plant: Plant) async throws -> Plant {
        // Mock save - just delay and return the plant
        try await Task.sleep(nanoseconds: 100_000_000)
        return plant
    }
    
    func saveBed(_ bed: Bed) async throws -> Bed {
        // Mock save - just delay and return the bed
        try await Task.sleep(nanoseconds: 100_000_000)
        return bed
    }
    
    func deletePlant(_ id: UUID) async throws {
        // Mock delete - just delay
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    
    func plants(inBed bedId: UUID) async throws -> [Plant] {
        // Mock plants in bed
        return [
            Plant(name: "Rose", bedId: bedId, x: 0.5, y: 0.5, scientificName: "Rosa"),
            Plant(name: "Tomato", bedId: bedId, x: 0.3, y: 0.7, scientificName: "Solanum lycopersicum")
        ]
    }
    
    func beds(inSection section: String) async throws -> [Bed] {
        // Mock beds for section
        if section == "front-yard" {
            return [
                Bed(id: UUID(), name: "Rose Garden", section: section),
                Bed(id: UUID(), name: "Herb Garden", section: section)
            ]
        } else if section == "back-yard" {
            return [
                Bed(id: UUID(), name: "Vegetable Patch", section: section),
                Bed(id: UUID(), name: "Fruit Trees", section: section)
            ]
        }
        return []
    }
}
