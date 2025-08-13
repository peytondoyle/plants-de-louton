import Foundation

actor DataService {
    static let shared = DataService()
    
    private init() {}
    
    func fetchPlants() async throws -> [Plant] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Plant(name: "Rose", scientificName: "Rosa"),
            Plant(name: "Tomato", scientificName: "Solanum lycopersicum"),
            Plant(name: "Lavender", scientificName: "Lavandula")
        ]
    }
    
    func fetchBeds() async throws -> [Bed] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Bed(name: "North Bed", section: "Front Garden"),
            Bed(name: "South Bed", section: "Front Garden")
        ]
    }
    
    func savePlant(_ plant: Plant) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    
    func saveBed(_ bed: Bed) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }
}
