import Foundation

actor DataService {
    static let shared = DataService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func fetchPlants() async throws -> [Plant] {
        return try await supabaseService.listPlants()
    }
    
    func fetchBeds() async throws -> [Bed] {
        return try await supabaseService.listBeds()
    }
    
    func savePlant(_ plant: Plant) async throws {
        let savedPlant = try await supabaseService.savePlant(plant)
        print("Plant saved successfully: \(savedPlant.name)")
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
    
    // MARK: - Section-based queries
    func beds(inSection section: String) async throws -> [Bed] {
        try await supabaseService.listBeds(inSection: section)
    }
    
    func plants(inSection section: String) async throws -> [Plant] {
        try await supabaseService.listPlants(inSection: section)
    }
}
