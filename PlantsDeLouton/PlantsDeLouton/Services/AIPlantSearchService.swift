import Foundation
import UIKit

// MARK: - Plant Information Models
struct PlantInfo: Codable {
    let name: String
    let scientificName: String
    let family: String?
    let growthHabit: String?
    let sunExposure: String?
    let waterNeeds: String?
    let matureHeight: String?
    let matureWidth: String?
    let bloomTime: String?
    let flowerColor: String?
    let foliageColor: String?
    let soilType: String?
    let soilPH: String?
    let hardinessZones: String?
    let careInstructions: String?
    let commonNames: [String]?
    let description: String?
}

// MARK: - AI Plant Search Service
@MainActor
class AIPlantSearchService: ObservableObject {
    static let shared = AIPlantSearchService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Get Plant Information from ChatGPT
    
    /// Get detailed plant information using ChatGPT API
    func getPlantInfo(for plantName: String) async throws -> PlantInfo {
        isLoading = true
        errorMessage = nil
        
        // TODO: Replace with actual OpenAI API key
        // For now, return mock data to demonstrate the flow
        // In production, this would make a real API call to ChatGPT
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock response - in real implementation, this would come from ChatGPT
        let mockPlantInfo = PlantInfo(
            name: plantName,
            scientificName: getScientificName(for: plantName),
            family: getFamily(for: plantName),
            growthHabit: "Perennial",
            sunExposure: "Full sun to partial shade",
            waterNeeds: "Moderate",
            matureHeight: "12-24 inches",
            matureWidth: "12-18 inches",
            bloomTime: "Spring to fall",
            flowerColor: "Various",
            foliageColor: "Green",
            soilType: "Well-draining, fertile",
            soilPH: "6.0-7.0",
            hardinessZones: "3-9",
            careInstructions: "Water regularly, deadhead spent flowers, fertilize monthly during growing season",
            commonNames: getCommonNames(for: plantName),
            description: "A beautiful flowering plant that adds color and interest to any garden."
        )
        
        isLoading = false
        return mockPlantInfo
    }
    
    // MARK: - Plant Name Suggestions
    
    /// Get plant name suggestions based on partial input
    func getPlantSuggestions(for query: String) async throws -> [String] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        // Common garden plants for suggestions
        let commonPlants = [
            "Tomato", "Basil", "Lavender", "Sunflower", "Marigold", "Zinnia",
            "Pepper", "Cucumber", "Carrot", "Lettuce", "Spinach", "Kale",
            "Broccoli", "Cauliflower", "Onion", "Garlic", "Potato", "Beet",
            "Radish", "Mint", "Rosemary", "Thyme", "Sage", "Oregano",
            "Parsley", "Cilantro", "Dill", "Chives", "Strawberry", "Blueberry",
            "Raspberry", "Blackberry", "Grape", "Lemon Tree", "Apple Tree",
            "Peach Tree", "Cherry Tree", "Calendula", "Nasturtium", "Alyssum",
            "Petunia", "Geranium", "Cosmos", "Snapdragon", "Pansy", "Viola"
        ]
        
        let queryLower = query.lowercased()
        let suggestions = commonPlants.filter { plant in
            plant.lowercased().contains(queryLower) ||
            plant.lowercased().hasPrefix(queryLower)
        }
        
        return Array(suggestions.prefix(10)) // Limit to 10 suggestions
    }
    
    // MARK: - Helper Methods (Mock Data)
    
    private func getScientificName(for plantName: String) -> String {
        let scientificNames: [String: String] = [
            "tomato": "Solanum lycopersicum",
            "basil": "Ocimum basilicum",
            "lavender": "Lavandula",
            "sunflower": "Helianthus annuus",
            "marigold": "Tagetes",
            "zinnia": "Zinnia elegans",
            "pepper": "Capsicum annuum",
            "cucumber": "Cucumis sativus",
            "carrot": "Daucus carota",
            "lettuce": "Lactuca sativa",
            "spinach": "Spinacia oleracea",
            "kale": "Brassica oleracea",
            "broccoli": "Brassica oleracea",
            "cauliflower": "Brassica oleracea",
            "onion": "Allium cepa",
            "garlic": "Allium sativum",
            "potato": "Solanum tuberosum",
            "beet": "Beta vulgaris",
            "radish": "Raphanus sativus",
            "mint": "Mentha",
            "rosemary": "Salvia rosmarinus",
            "thyme": "Thymus vulgaris",
            "sage": "Salvia officinalis",
            "oregano": "Origanum vulgare",
            "parsley": "Petroselinum crispum",
            "cilantro": "Coriandrum sativum",
            "dill": "Anethum graveolens",
            "chives": "Allium schoenoprasum",
            "strawberry": "Fragaria × ananassa",
            "blueberry": "Vaccinium",
            "raspberry": "Rubus idaeus",
            "blackberry": "Rubus fruticosus",
            "grape": "Vitis vinifera",
            "lemon tree": "Citrus limon",
            "apple tree": "Malus domestica",
            "peach tree": "Prunus persica",
            "cherry tree": "Prunus avium",
            "calendula": "Calendula officinalis",
            "nasturtium": "Tropaeolum majus",
            "alyssum": "Lobularia maritima",
            "petunia": "Petunia",
            "geranium": "Pelargonium",
            "cosmos": "Cosmos bipinnatus"
        ]
        
        return scientificNames[plantName.lowercased()] ?? "Species unknown"
    }
    
    private func getFamily(for plantName: String) -> String {
        let families: [String: String] = [
            "tomato": "Solanaceae",
            "basil": "Lamiaceae",
            "lavender": "Lamiaceae",
            "sunflower": "Asteraceae",
            "marigold": "Asteraceae",
            "zinnia": "Asteraceae",
            "pepper": "Solanaceae",
            "cucumber": "Cucurbitaceae",
            "carrot": "Apiaceae",
            "lettuce": "Asteraceae",
            "spinach": "Amaranthaceae",
            "kale": "Brassicaceae",
            "broccoli": "Brassicaceae",
            "cauliflower": "Brassicaceae",
            "onion": "Amaryllidaceae",
            "garlic": "Amaryllidaceae",
            "potato": "Solanaceae",
            "beet": "Amaranthaceae",
            "radish": "Brassicaceae",
            "mint": "Lamiaceae",
            "rosemary": "Lamiaceae",
            "thyme": "Lamiaceae",
            "sage": "Lamiaceae",
            "oregano": "Lamiaceae",
            "parsley": "Apiaceae",
            "cilantro": "Apiaceae",
            "dill": "Apiaceae",
            "chives": "Amaryllidaceae",
            "strawberry": "Rosaceae",
            "blueberry": "Ericaceae",
            "raspberry": "Rosaceae",
            "blackberry": "Rosaceae",
            "grape": "Vitaceae",
            "lemon tree": "Rutaceae",
            "apple tree": "Rosaceae",
            "peach tree": "Rosaceae",
            "cherry tree": "Rosaceae",
            "calendula": "Asteraceae",
            "nasturtium": "Tropaeolaceae",
            "alyssum": "Brassicaceae",
            "petunia": "Solanaceae",
            "geranium": "Geraniaceae",
            "cosmos": "Asteraceae"
        ]
        
        return families[plantName.lowercased()] ?? "Unknown"
    }
    
    private func getCommonNames(for plantName: String) -> [String] {
        let commonNames: [String: [String]] = [
            "tomato": ["Love apple", "Wolf peach"],
            "basil": ["Sweet basil", "Common basil"],
            "lavender": ["English lavender", "Common lavender"],
            "sunflower": ["Common sunflower", "Annual sunflower"],
            "marigold": ["French marigold", "African marigold"],
            "zinnia": ["Youth and old age", "Common zinnia"],
            "calendula": ["Pot marigold", "English marigold", "Scotch marigold"]
        ]
        
        return commonNames[plantName.lowercased()] ?? []
    }
}

// MARK: - Error Types
enum AIError: Error, LocalizedError {
    case apiKeyMissing
    case networkError
    case invalidResponse
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "OpenAI API key not configured"
        case .networkError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .rateLimitExceeded:
            return "Rate limit exceeded, please try again later"
        }
    }
}
