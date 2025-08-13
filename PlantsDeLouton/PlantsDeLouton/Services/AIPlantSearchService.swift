import Foundation

// MARK: - Models matching the TypeScript interface
struct AIPlantSearchResult: Codable, Identifiable {
    let id = UUID()
    let name: String
    let scientificName: String
    let commonNames: [String]
    let family: String
    let genus: String
    let species: String
    let growthHabit: GrowthHabit
    let hardinessZones: [Int]
    let sunExposure: SunExposure
    let waterNeeds: WaterNeeds
    let matureHeight: Double
    let matureWidth: Double
    let bloomTime: BloomTime
    let bloomDuration: Double
    let flowerColor: [String]
    let foliageColor: [String]
    let soilType: SoilType
    let soilPH: SoilPH
    let fertilizerNeeds: FertilizerNeeds
    let pruningNeeds: PruningNeeds
    let plantingSeason: PlantingSeason
    let plantingDepth: Double
    let spacing: Double
    
    enum CodingKeys: String, CodingKey {
        case name
        case scientificName = "scientific_name"
        case commonNames = "common_names"
        case family, genus, species
        case growthHabit = "growth_habit"
        case hardinessZones = "hardiness_zones"
        case sunExposure = "sun_exposure"
        case waterNeeds = "water_needs"
        case matureHeight = "mature_height"
        case matureWidth = "mature_width"
        case bloomTime = "bloom_time"
        case bloomDuration = "bloom_duration"
        case flowerColor = "flower_color"
        case foliageColor = "foliage_color"
        case soilType = "soil_type"
        case soilPH = "soil_ph"
        case fertilizerNeeds = "fertilizer_needs"
        case pruningNeeds = "pruning_needs"
        case plantingSeason = "planting_season"
        case plantingDepth = "planting_depth"
        case spacing
    }
}

// MARK: - Enums
enum GrowthHabit: String, Codable, CaseIterable {
    case annual = "annual"
    case perennial = "perennial"
    case biennial = "biennial"
    case shrub = "shrub"
    case tree = "tree"
    case vine = "vine"
    case groundcover = "groundcover"
}

enum SunExposure: String, Codable, CaseIterable {
    case fullSun = "full_sun"
    case partialSun = "partial_sun"
    case partialShade = "partial_shade"
    case fullShade = "full_shade"
}

enum WaterNeeds: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
}

enum BloomTime: String, Codable, CaseIterable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"
    case yearRound = "year_round"
}

enum SoilType: String, Codable, CaseIterable {
    case clay = "clay"
    case loam = "loam"
    case sandy = "sandy"
    case wellDraining = "well_draining"
}

enum SoilPH: String, Codable, CaseIterable {
    case acidic = "acidic"
    case neutral = "neutral"
    case alkaline = "alkaline"
}

enum FertilizerNeeds: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
}

enum PruningNeeds: String, Codable, CaseIterable {
    case minimal = "minimal"
    case moderate = "moderate"
    case heavy = "heavy"
}

enum PlantingSeason: String, Codable, CaseIterable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"
}

// MARK: - Service
@MainActor
class AIPlantSearchService: ObservableObject {
    static let shared = AIPlantSearchService()
    
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func searchPlants(query: String) async throws -> [AIPlantSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isSearching = true
        errorMessage = nil
        
        defer {
            isSearching = false
        }
        
        do {
            // Use Supabase service for real database search
            let searchResults = try await supabaseService.searchPlants(query: query)
            
            // Convert PlantSearchResult to AIPlantSearchResult for UI compatibility
            let results = searchResults.map { result in
                AIPlantSearchResult(
                    name: result.name,
                    scientificName: result.scientificName ?? "",
                    commonNames: result.commonNames ?? [],
                    family: result.family ?? "",
                    genus: result.genus ?? "",
                    species: result.species ?? "",
                    growthHabit: GrowthHabit(rawValue: result.growthHabit) ?? .annual,
                    hardinessZones: result.hardinessZones ?? [],
                    sunExposure: SunExposure(rawValue: result.sunExposure) ?? .fullSun,
                    waterNeeds: WaterNeeds(rawValue: result.waterNeeds) ?? .moderate,
                    matureHeight: result.matureHeight ?? 0,
                    matureWidth: result.matureWidth ?? 0,
                    bloomTime: BloomTime(rawValue: result.bloomTime ?? "spring") ?? .spring,
                    bloomDuration: Double(result.bloomDuration ?? 0),
                    flowerColor: result.flowerColor ?? [],
                    foliageColor: result.foliageColor ?? [],
                    soilType: SoilType(rawValue: result.soilType ?? "well_draining") ?? .wellDraining,
                    soilPH: SoilPH(rawValue: result.soilPH ?? "neutral") ?? .neutral,
                    fertilizerNeeds: FertilizerNeeds(rawValue: result.fertilizerNeeds ?? "moderate") ?? .moderate,
                    pruningNeeds: PruningNeeds(rawValue: result.pruningNeeds ?? "moderate") ?? .moderate,
                    plantingSeason: PlantingSeason(rawValue: result.plantingSeason ?? "spring") ?? .spring,
                    plantingDepth: result.plantingDepth ?? 0,
                    spacing: result.spacing ?? 0
                )
            }
            
            return results
        } catch {
            // Fallback to mock data if Supabase fails (for development)
            print("Supabase search failed, using mock data: \(error)")
            let results = try await searchMockAPI(query: query)
            return results
        }
    }
    
    // Mock API implementation matching your TypeScript mock data
    private func searchMockAPI(query: String) async throws -> [AIPlantSearchResult] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let mockPlants: [String: AIPlantSearchResult] = [
            "calendula": AIPlantSearchResult(
                name: "Calendula",
                scientificName: "Calendula officinalis",
                commonNames: ["Pot Marigold", "English Marigold"],
                family: "Asteraceae",
                genus: "Calendula",
                species: "officinalis",
                growthHabit: .annual,
                hardinessZones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
                sunExposure: .fullSun,
                waterNeeds: .moderate,
                matureHeight: 24,
                matureWidth: 12,
                bloomTime: .spring,
                bloomDuration: 16,
                flowerColor: ["orange", "yellow"],
                foliageColor: ["green"],
                soilType: .wellDraining,
                soilPH: .neutral,
                fertilizerNeeds: .low,
                pruningNeeds: .minimal,
                plantingSeason: .spring,
                plantingDepth: 0.25,
                spacing: 12
            ),
            "tomato": AIPlantSearchResult(
                name: "Tomato",
                scientificName: "Solanum lycopersicum",
                commonNames: ["Tomato", "Love Apple"],
                family: "Solanaceae",
                genus: "Solanum",
                species: "lycopersicum",
                growthHabit: .annual,
                hardinessZones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
                sunExposure: .fullSun,
                waterNeeds: .moderate,
                matureHeight: 60,
                matureWidth: 24,
                bloomTime: .summer,
                bloomDuration: 12,
                flowerColor: ["yellow"],
                foliageColor: ["green"],
                soilType: .wellDraining,
                soilPH: .neutral,
                fertilizerNeeds: .moderate,
                pruningNeeds: .moderate,
                plantingSeason: .spring,
                plantingDepth: 0.25,
                spacing: 24
            ),
            "basil": AIPlantSearchResult(
                name: "Basil",
                scientificName: "Ocimum basilicum",
                commonNames: ["Sweet Basil", "Common Basil"],
                family: "Lamiaceae",
                genus: "Ocimum",
                species: "basilicum",
                growthHabit: .annual,
                hardinessZones: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
                sunExposure: .fullSun,
                waterNeeds: .moderate,
                matureHeight: 18,
                matureWidth: 12,
                bloomTime: .summer,
                bloomDuration: 8,
                flowerColor: ["white", "pink"],
                foliageColor: ["green"],
                soilType: .wellDraining,
                soilPH: .neutral,
                fertilizerNeeds: .low,
                pruningNeeds: .minimal,
                plantingSeason: .spring,
                plantingDepth: 0.25,
                spacing: 12
            ),
            "rose": AIPlantSearchResult(
                name: "Rose",
                scientificName: "Rosa",
                commonNames: ["Rose", "Garden Rose"],
                family: "Rosaceae",
                genus: "Rosa",
                species: "",
                growthHabit: .shrub,
                hardinessZones: [3, 4, 5, 6, 7, 8, 9, 10],
                sunExposure: .fullSun,
                waterNeeds: .moderate,
                matureHeight: 48,
                matureWidth: 36,
                bloomTime: .spring,
                bloomDuration: 16,
                flowerColor: ["red", "pink", "white", "yellow", "orange"],
                foliageColor: ["green"],
                soilType: .wellDraining,
                soilPH: .neutral,
                fertilizerNeeds: .moderate,
                pruningNeeds: .moderate,
                plantingSeason: .spring,
                plantingDepth: 1,
                spacing: 36
            ),
            "lavender": AIPlantSearchResult(
                name: "Lavender",
                scientificName: "Lavandula angustifolia",
                commonNames: ["English Lavender", "Common Lavender"],
                family: "Lamiaceae",
                genus: "Lavandula",
                species: "angustifolia",
                growthHabit: .perennial,
                hardinessZones: [5, 6, 7, 8, 9],
                sunExposure: .fullSun,
                waterNeeds: .low,
                matureHeight: 24,
                matureWidth: 18,
                bloomTime: .summer,
                bloomDuration: 8,
                flowerColor: ["purple", "blue"],
                foliageColor: ["silver", "green"],
                soilType: .wellDraining,
                soilPH: .alkaline,
                fertilizerNeeds: .low,
                pruningNeeds: .minimal,
                plantingSeason: .spring,
                plantingDepth: 0.5,
                spacing: 18
            )
        ]
        
        // Search through mock plants
        var results: [AIPlantSearchResult] = []
        let searchTerm = query.lowercased()
        
        for (key, plant) in mockPlants {
            if key.contains(searchTerm) ||
               plant.name.lowercased().contains(searchTerm) ||
               plant.scientificName.lowercased().contains(searchTerm) ||
               plant.commonNames.contains(where: { $0.lowercased().contains(searchTerm) }) {
                results.append(plant)
            }
        }
        
        return Array(results.prefix(5))
    }
}

// MARK: - Extensions for display
extension SunExposure {
    var displayName: String {
        switch self {
        case .fullSun: return "Full Sun"
        case .partialSun: return "Partial Sun"
        case .partialShade: return "Partial Shade"
        case .fullShade: return "Full Shade"
        }
    }
    
    var icon: String {
        switch self {
        case .fullSun: return "sun.max.fill"
        case .partialSun: return "sun.max"
        case .partialShade: return "cloud.sun.fill"
        case .fullShade: return "cloud.fill"
        }
    }
}

extension WaterNeeds {
    var displayName: String {
        switch self {
        case .low: return "Low Water"
        case .moderate: return "Moderate Water"
        case .high: return "High Water"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "drop"
        case .moderate: return "drop.fill"
        case .high: return "water.waves"
        }
    }
}

extension GrowthHabit {
    var displayName: String {
        switch self {
        case .annual: return "Annual"
        case .perennial: return "Perennial"
        case .biennial: return "Biennial"
        case .shrub: return "Shrub"
        case .tree: return "Tree"
        case .vine: return "Vine"
        case .groundcover: return "Groundcover"
        }
    }
}
