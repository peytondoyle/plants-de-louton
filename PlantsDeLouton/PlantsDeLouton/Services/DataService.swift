import Foundation

actor DataService {
    static let shared = DataService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func fetchPlants() async throws -> [Plant] {
        // For now, return mock data since we haven't implemented plant_instances queries yet
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            Plant(name: "Rose", scientificName: "Rosa"),
            Plant(name: "Tomato", scientificName: "Solanum lycopersicum"),
            Plant(name: "Lavender", scientificName: "Lavandula")
        ]
    }
    
    func fetchBeds() async throws -> [Bed] {
        // Supabase-backed beds
        do {
            return try await supabaseService.listBeds()
        } catch {
            // Fallback to mock if DB unavailable
            try await Task.sleep(nanoseconds: 250_000_000)
            return [
                Bed(name: "North Bed", section: "Front Garden"),
                Bed(name: "South Bed", section: "Front Garden")
            ]
        }
    }
    
    func savePlant(_ plant: Plant) async throws {
        do {
            // Convert Plant to PlantDetails format for Supabase
            let plantDetails = PlantDetails(from: plant)
            let savedPlant = try await supabaseService.savePlantDetails(plantDetails)
            print("Plant saved successfully: \(savedPlant.name)")
        } catch {
            print("Failed to save plant to Supabase: \(error)")
            // For development, we'll fallback to mock behavior
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    func saveBed(_ bed: Bed) async throws {
        _ = try await supabaseService.saveBed(bed)
    }

    // MARK: - Bed ↔︎ Plant Assignment
    func assignPlant(_ plantId: UUID, toBed bedId: UUID) async throws {
        try await supabaseService.assignPlant(plantId: plantId, toBed: bedId)
    }

    func removePlant(_ plantId: UUID, fromBed bedId: UUID) async throws {
        try await supabaseService.removePlant(plantId: plantId, fromBed: bedId)
    }

    func plants(inBed bedId: UUID) async throws -> [Plant] {
        try await supabaseService.listPlants(inBed: bedId)
    }
}
