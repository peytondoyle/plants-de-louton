import Foundation
import UIKit

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

// MARK: - AI Plant Search Service
@MainActor
class AIPlantSearchService: ObservableObject {
    static let shared = AIPlantSearchService()
    
    @Published var searchResults: [AIPlantSearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // TODO: Add OpenAI integration when API key is available
    // private let openAI = OpenAI(apiToken: "your-openai-api-key")
    
    private init() {}
    
    // MARK: - Text-Based Plant Search
    
    /// Search for plants using text query
    func searchPlants(query: String) async throws -> [AIPlantSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement ChatGPT search when OpenAI is integrated
        // For now, return empty results
        isLoading = false
        return []
    }
    
    // MARK: - Image-Based Plant Identification
    
    /// Identify plant from photo using ChatGPT Vision
    func identifyPlantFromImage(_ image: UIImage) async throws -> AIPlantSearchResult {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement ChatGPT Vision when OpenAI is integrated
        // For now, return a mock result
        isLoading = false
        
        // Return a mock plant for demonstration
        return AIPlantSearchResult(
            name: "Unknown Plant",
            scientificName: "Species unknown",
            commonNames: ["Unknown"],
            family: "Unknown",
            genus: "Unknown",
            species: "unknown",
            growthHabit: .annual,
            hardinessZones: [5, 6, 7, 8],
            sunExposure: .fullSun,
            waterNeeds: .moderate,
            matureHeight: 24.0,
            matureWidth: 18.0,
            bloomTime: .summer,
            bloomDuration: 4,
            flowerColor: ["Unknown"],
            foliageColor: ["Green"],
            soilType: .wellDraining,
            soilPH: .neutral,
            fertilizerNeeds: .moderate,
            pruningNeeds: .moderate,
            plantingSeason: .spring,
            plantingDepth: 1.0,
            spacing: 12.0
        )
    }
    
    // MARK: - ChatGPT Text Search
    
    /// Search for plants using ChatGPT
    private func searchWithChatGPT(query: String) async throws -> [AIPlantSearchResult] {
        // TODO: Implement ChatGPT search when OpenAI is integrated
        // For now, return empty results
        return []
    }
    
    // MARK: - Health Analysis
    
    /// Analyze plant health from photo
    func analyzePlantHealth(_ image: UIImage) async throws -> PlantHealthAnalysis {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement ChatGPT Vision health analysis when OpenAI is integrated
        // For now, return a mock health analysis
        isLoading = false
        
        return PlantHealthAnalysis(
            overallHealth: .good,
            healthScore: 85,
            issues: ["Slight yellowing on lower leaves"],
            recommendations: ["Ensure proper watering", "Check for pests", "Consider fertilizing"],
            diseases: [],
            pests: [],
            nutrientDeficiencies: ["Possible nitrogen deficiency"],
            confidence: 75
        )
    }
    
    // Real API implementation - replace with actual plant database
    private func searchMockAPI(query: String) async throws -> [AIPlantSearchResult] {
        // This will be replaced with real plant database integration
        // For now, return empty array - implement when external API is ready
        return []
    }
}

// MARK: - Response Models

struct ChatGPTPlantResponse: Codable {
    let name: String
    let scientificName: String
    let commonNames: [String]
    let family: String
    let genus: String
    let species: String
    let growthHabit: String
    let hardinessZones: [Int]
    let sunExposure: String
    let waterNeeds: String
    let matureHeight: Double
    let matureWidth: Double
    let bloomTime: String
    let bloomDuration: Int
    let flowerColor: [String]
    let foliageColor: [String]
    let soilType: String
    let soilPH: String
    let fertilizerNeeds: String
    let pruningNeeds: String
    let plantingSeason: String
    let plantingDepth: Double
    let spacing: Double
    let careInstructions: String?
    let identificationConfidence: Int?
}

struct ChatGPTHealthResponse: Codable {
    let overallHealth: String
    let healthScore: Int
    let issues: [String]
    let recommendations: [String]
    let diseases: [String]
    let pests: [String]
    let nutrientDeficiencies: [String]
    let confidence: Int
}

// MARK: - Plant Health Models

struct PlantHealthAnalysis: Codable {
    let overallHealth: PlantHealth
    let healthScore: Int
    let issues: [String]
    let recommendations: [String]
    let diseases: [String]
    let pests: [String]
    let nutrientDeficiencies: [String]
    let confidence: Int
}

enum PlantHealth: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .critical: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .fair: return "exclamationmark.triangle"
        case .poor: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
}

// MARK: - Error Types

enum AIError: Error, LocalizedError {
    case imageProcessingFailed
    case parsingFailed
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .parsingFailed:
            return "Failed to parse AI response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
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
