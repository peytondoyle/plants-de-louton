import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        // For now, we'll use environment variables or hardcoded values
        // In production, you would load these from a secure config file
        let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String ?? ""
        let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? ""
        
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            fatalError("Supabase URL and Anon Key must be configured")
        }
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
    
    // MARK: - Plant Search Cache Methods
    
    /// Search for plants in the cache first, then external API if needed
    func searchPlants(query: String) async throws -> [PlantSearchResult] {
        // First check cache
        if let cachedResults = try await getCachedSearch(query: query) {
            return cachedResults
        }
        
        // If no cache, search external API and cache results
        let results = try await searchExternalAPI(query: query)
        try await cacheSearchResults(query: query, results: results)
        return results
    }
    
    /// Get cached search results
    private func getCachedSearch(query: String) async throws -> [PlantSearchResult]? {
        do {
            let cacheEntry: PlantSearchCacheEntry = try await client
                .from("plant_search_cache")
                .select()
                .eq("query", value: query.lowercased())
                .single()
                .execute()
                .value
            
            // Check if cache is still fresh (within 7 days)
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            if cacheEntry.createdAt < weekAgo {
                return nil
            }
            
            return cacheEntry.results
        } catch {
            // Cache miss is normal, return nil
            return nil
        }
    }
    
    /// Cache search results
    private func cacheSearchResults(query: String, results: [PlantSearchResult]) async throws {
        let cacheEntry = PlantSearchCacheEntry(
            query: query.lowercased(),
            results: results,
            createdAt: Date()
        )
        
        try await client
            .from("plant_search_cache")
            .upsert(cacheEntry)
            .execute()
    }
    
    /// Search external API (mock for now, can be replaced with real Trefle API)
    private func searchExternalAPI(query: String) async throws -> [PlantSearchResult] {
        // This would connect to your existing Trefle API or other plant database
        // For now, return mock data based on query
        return generateMockResults(for: query)
    }
    
    // MARK: - Plant Details Methods
    
    /// Get plant details by ID
    func getPlantDetails(id: UUID) async throws -> PlantDetails? {
        do {
            let plantDetails: PlantDetails = try await client
                .from("plant_details")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            return plantDetails
        } catch {
            return nil
        }
    }
    
    /// Create or update plant details
    func savePlantDetails(_ plant: PlantDetails) async throws -> PlantDetails {
        let savedPlant: PlantDetails = try await client
            .from("plant_details")
            .upsert(plant)
            .select()
            .single()
            .execute()
            .value
        
        return savedPlant
    }
    
    /// List all plant details
    func listPlantDetails() async throws -> [PlantDetails] {
        let plants: [PlantDetails] = try await client
            .from("plant_details")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
        
        return plants
    }

    // MARK: - Beds Methods

    struct BedRow: Codable {
        let id: UUID
        let name: String
        let section: String
    }

    /// List all beds (plants joined later)
    func listBeds() async throws -> [Bed] {
        let rows: [BedRow] = try await client
            .from("beds")
            .select()
            .order("name", ascending: true)
            .execute()
            .value

        // For now, return beds without joined plants; plant assignment will be added later
        return rows.map { Bed(id: $0.id, name: $0.name, section: $0.section, plants: []) }
    }

    /// Create or update a bed
    func saveBed(_ bed: Bed) async throws -> Bed {
        // Persist only fields present in BedRow
        let row = BedRow(id: bed.id, name: bed.name, section: bed.section)
        let saved: BedRow = try await client
            .from("beds")
            .upsert(row)
            .select()
            .single()
            .execute()
            .value
        return Bed(id: saved.id, name: saved.name, section: saved.section, plants: bed.plants)
    }

    /// Delete a bed by id
    func deleteBed(id: UUID) async throws {
        _ = try await client
            .from("beds")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Data Models

struct PlantSearchCacheEntry: Codable {
    let query: String
    let results: [PlantSearchResult]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case query
        case results
        case createdAt = "created_at"
    }
}

struct PlantSearchResult: Identifiable, Codable {
    let id: UUID
    let name: String
    let scientificName: String?
    let commonNames: [String]?
    let family: String?
    let genus: String?
    let species: String?
    let growthHabit: String
    let hardinessZones: [Int]?
    let sunExposure: String
    let waterNeeds: String
    let matureHeight: Double?
    let matureWidth: Double?
    let bloomTime: String?
    let bloomDuration: Int?
    let flowerColor: [String]?
    let foliageColor: [String]?
    let soilType: String?
    let soilPH: String?
    let fertilizerNeeds: String?
    let pruningNeeds: String?
    let plantingSeason: String?
    let plantingDepth: Double?
    let spacing: Double?
    
    init(
        id: UUID = UUID(),
        name: String,
        scientificName: String? = nil,
        commonNames: [String]? = nil,
        family: String? = nil,
        genus: String? = nil,
        species: String? = nil,
        growthHabit: String,
        hardinessZones: [Int]? = nil,
        sunExposure: String,
        waterNeeds: String,
        matureHeight: Double? = nil,
        matureWidth: Double? = nil,
        bloomTime: String? = nil,
        bloomDuration: Int? = nil,
        flowerColor: [String]? = nil,
        foliageColor: [String]? = nil,
        soilType: String? = nil,
        soilPH: String? = nil,
        fertilizerNeeds: String? = nil,
        pruningNeeds: String? = nil,
        plantingSeason: String? = nil,
        plantingDepth: Double? = nil,
        spacing: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.commonNames = commonNames
        self.family = family
        self.genus = genus
        self.species = species
        self.growthHabit = growthHabit
        self.hardinessZones = hardinessZones
        self.sunExposure = sunExposure
        self.waterNeeds = waterNeeds
        self.matureHeight = matureHeight
        self.matureWidth = matureWidth
        self.bloomTime = bloomTime
        self.bloomDuration = bloomDuration
        self.flowerColor = flowerColor
        self.foliageColor = foliageColor
        self.soilType = soilType
        self.soilPH = soilPH
        self.fertilizerNeeds = fertilizerNeeds
        self.pruningNeeds = pruningNeeds
        self.plantingSeason = plantingSeason
        self.plantingDepth = plantingDepth
        self.spacing = spacing
    }
    
    init(from plant: Plant) {
        self.id = plant.id
        self.name = plant.name
        self.scientificName = plant.scientificName
        self.commonNames = nil // Plant model doesn't have this
        self.family = nil // Plant model doesn't have this
        self.genus = nil // Plant model doesn't have this
        self.species = nil // Plant model doesn't have this
        self.growthHabit = plant.growthHabit
        self.hardinessZones = nil // Plant model doesn't have this
        self.sunExposure = plant.sunExposure
        self.waterNeeds = plant.waterNeeds
        self.matureHeight = nil // Plant model doesn't have this
        self.matureWidth = nil // Plant model doesn't have this
        self.bloomTime = nil // Plant model doesn't have this
        self.bloomDuration = nil // Plant model doesn't have this
        self.flowerColor = nil // Plant model doesn't have this
        self.foliageColor = nil // Plant model doesn't have this
        self.soilType = nil // Plant model doesn't have this
        self.soilPH = nil // Plant model doesn't have this
        self.fertilizerNeeds = nil // Plant model doesn't have this
        self.pruningNeeds = nil // Plant model doesn't have this
        self.plantingSeason = nil // Plant model doesn't have this
        self.plantingDepth = nil // Plant model doesn't have this
        self.spacing = nil // Plant model doesn't have this
    }
}

struct PlantDetails: Identifiable, Codable {
    let id: UUID
    var name: String
    var scientificName: String?
    var commonNames: [String]?
    var family: String?
    var genus: String?
    var species: String?
    var cultivar: String?
    
    // Growth Characteristics
    var growthHabit: String?
    var hardinessZones: [Int]?
    var sunExposure: String?
    var waterNeeds: String?
    var matureHeight: Int?
    var matureWidth: Int?
    
    // Blooming & Seasons
    var bloomTime: String?
    var bloomDuration: Int?
    var flowerColor: [String]?
    var foliageColor: [String]?
    
    // Care Requirements
    var soilType: String?
    var soilPH: String?
    var fertilizerNeeds: String?
    var pruningNeeds: String?
    
    // Planting Info
    var plantingSeason: String?
    var plantingDepth: Int?
    var spacing: Int?
    
    let createdAt: Date
    let updatedAt: Date
    
    init(from plant: Plant) {
        self.id = plant.id
        self.name = plant.name
        self.scientificName = plant.scientificName
        self.commonNames = nil // Plant model doesn't have this
        self.family = nil // Plant model doesn't have this
        self.genus = nil // Plant model doesn't have this
        self.species = nil // Plant model doesn't have this
        self.cultivar = nil // Not in Plant model
        self.growthHabit = plant.growthHabit
        self.hardinessZones = nil // Plant model doesn't have this
        self.sunExposure = plant.sunExposure
        self.waterNeeds = plant.waterNeeds
        self.matureHeight = nil // Plant model doesn't have this
        self.matureWidth = nil // Plant model doesn't have this
        self.bloomTime = nil // Plant model doesn't have this
        self.bloomDuration = nil // Plant model doesn't have this
        self.flowerColor = nil // Plant model doesn't have this
        self.foliageColor = nil // Plant model doesn't have this
        self.soilType = nil // Plant model doesn't have this
        self.soilPH = nil // Plant model doesn't have this
        self.fertilizerNeeds = nil // Plant model doesn't have this
        self.pruningNeeds = nil // Plant model doesn't have this
        self.plantingSeason = nil // Plant model doesn't have this
        self.plantingDepth = nil // Plant model doesn't have this
        self.spacing = nil // Plant model doesn't have this
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum SupabaseError: LocalizedError {
    case unexpectedResponse
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return "Unexpected response from database"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Data Generation

private func generateMockResults(for query: String) -> [PlantSearchResult] {
    let mockResults = [
        PlantSearchResult(
            id: UUID(),
            name: "Tomato",
            scientificName: "Solanum lycopersicum",
            commonNames: ["Tomato", "Garden Tomato"],
            family: "Solanaceae",
            genus: "Solanum",
            species: "lycopersicum",
            growthHabit: "annual",
            hardinessZones: [9, 10, 11],
            sunExposure: "full_sun",
            waterNeeds: "moderate",
            matureHeight: 48.0,
            matureWidth: 24.0,
            bloomTime: "summer",
            bloomDuration: 12,
            flowerColor: ["yellow"],
            foliageColor: ["green"],
            soilType: "well_draining",
            soilPH: "neutral",
            fertilizerNeeds: "moderate",
            pruningNeeds: "moderate",
            plantingSeason: "spring",
            plantingDepth: 0.25,
            spacing: 18.0
        ),
        PlantSearchResult(
            id: UUID(),
            name: "Rose",
            scientificName: "Rosa rubiginosa",
            commonNames: ["Rose", "Garden Rose", "Sweet Briar"],
            family: "Rosaceae",
            genus: "Rosa",
            species: "rubiginosa",
            growthHabit: "shrub",
            hardinessZones: [4, 5, 6, 7, 8, 9],
            sunExposure: "full_sun",
            waterNeeds: "moderate",
            matureHeight: 60.0,
            matureWidth: 48.0,
            bloomTime: "summer",
            bloomDuration: 8,
            flowerColor: ["pink", "red", "white"],
            foliageColor: ["green"],
            soilType: "well_draining",
            soilPH: "neutral",
            fertilizerNeeds: "moderate",
            pruningNeeds: "heavy",
            plantingSeason: "spring",
            plantingDepth: 2.0,
            spacing: 36.0
        )
    ]
    
    return mockResults.filter { result in
        result.name.lowercased().contains(query.lowercased()) || 
        result.scientificName?.lowercased().contains(query.lowercased()) == true
    }
}
