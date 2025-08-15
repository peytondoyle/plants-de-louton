import Foundation
import CryptoKit

// MARK: - AI Plant Search Service

class AIPlantSearchService: ObservableObject {
    static let shared = AIPlantSearchService()
    
    @Published var searchResults: [AIPlantSearchResult] = []
    @Published var isSearching = false
    @Published var error: String?
    
    private let openAIAPIKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {
        self.openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        
        if openAIAPIKey.isEmpty {
            // In production, this should be handled more gracefully
            self.error = "OpenAI API key not configured"
        }
    }
    
    // MARK: - Search Methods
    
    func searchPlants(query: String) async throws -> [AIPlantSearchResult] {
        guard !openAIAPIKey.isEmpty else {
            throw AIPlantSearchError.configurationError("OpenAI API key not configured")
        }
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        await MainActor.run {
            self.isSearching = true
            self.error = nil
        }
        
        defer {
            Task { @MainActor in
                self.isSearching = false
            }
        }
        
        do {
            let results = try await performAISearch(query: query)
            await MainActor.run {
                self.searchResults = results
            }
            return results
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    private func performAISearch(query: String) async throws -> [AIPlantSearchResult] {
        let prompt = createSearchPrompt(for: query)
        
        let requestBody = ChatCompletionRequest(
            model: "gpt-4o",
            messages: [
                ChatMessage(role: "system", content: "You are a helpful gardening assistant that provides accurate plant information."),
                ChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.3,
            maxTokens: 2000
        )
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIPlantSearchError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIPlantSearchError.apiError("API request failed with status: \(httpResponse.statusCode)")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        
        guard let content = chatResponse.choices.first?.message.content else {
            throw AIPlantSearchError.parsingError("No content in response")
        }
        
        let contentString: String
        switch content {
        case .text(let text):
            contentString = text
        case .array(let array):
            contentString = array.compactMap { item in
                switch item {
                case .text(let text): return text
                case .array: return nil
                }
            }.joined(separator: " ")
        }
        
        return try parsePlantResults(from: contentString)
    }
    
    private func createSearchPrompt(for query: String) -> String {
        return """
        Search for plants matching "\(query)" and return the results as a JSON array. Each plant should have these fields:
        - name: Common name
        - scientificName: Scientific name (genus species)
        - family: Plant family
        - growthHabit: "tree", "shrub", "vine", "herb", "grass", "succulent", or "other"
        - sunExposure: "full_sun", "partial_shade", "full_shade", or "variable"
        - waterNeeds: "low", "moderate", "high", or "variable"
        - matureHeight: Height in feet (number or null)
        - matureWidth: Width in feet (number or null)
        - hardinessZones: Array of USDA zones (numbers or null)
        - bloomTime: When it blooms (string or null)
        - flowerColor: Array of colors (strings or null)
        - description: Brief description
        
        Return exactly 5 plants in this JSON format:
        [
          {
            "name": "Plant Name",
            "scientificName": "Genus species",
            "family": "Family Name",
            "growthHabit": "shrub",
            "sunExposure": "full_sun",
            "waterNeeds": "moderate",
            "matureHeight": 6,
            "matureWidth": 4,
            "hardinessZones": [5, 6, 7, 8],
            "bloomTime": "Spring to Summer",
            "flowerColor": ["pink", "white"],
            "description": "A beautiful flowering shrub..."
          }
        ]
        """
    }
    
    private func parsePlantResults(from responseText: String) throws -> [AIPlantSearchResult] {
        let cleanedResponse = cleanJSONResponse(responseText)
        
        do {
            let plantArray = try JSONDecoder().decode([AIPlantSearchResult].self, from: Data(cleanedResponse.utf8))
            return plantArray
        } catch {
            throw AIPlantSearchError.parsingError("Failed to parse plant results: \(error.localizedDescription)")
        }
    }
    
    private func cleanJSONResponse(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the first [ and last ]
        if let firstBracket = cleaned.firstIndex(of: "["),
           let lastBracket = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[firstBracket...lastBracket])
        }
        
        // Remove any markdown code blocks
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Plant Identification
    
    func identifyPlant(from imageData: Data) async throws -> AIPlantSearchResult {
        guard !openAIAPIKey.isEmpty else {
            throw AIPlantSearchError.configurationError("OpenAI API key not configured")
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody = ChatCompletionRequest(
            model: "gpt-4o",
            messages: [
                ChatMessage(role: "system", content: "You are a plant identification expert. Analyze the image and provide plant information."),
                ChatMessage(role: "user", content: [
                    .text("Identify this plant and provide details in JSON format with the same structure as the search results."),
                    .text("data:image/jpeg;base64,\(base64Image)")
                ])
            ],
            temperature: 0.3,
            maxTokens: 1000
        )
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIPlantSearchError.apiError("Plant identification failed")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        
        guard let content = chatResponse.choices.first?.message.content else {
            throw AIPlantSearchError.parsingError("No content in identification response")
        }
        
        let contentString: String
        switch content {
        case .text(let text):
            contentString = text
        case .array(let array):
            contentString = array.compactMap { item in
                switch item {
                case .text(let text): return text
                case .array: return nil
                }
            }.joined(separator: " ")
        }
        let results = try parsePlantResults(from: contentString)
        return results.first ?? AIPlantSearchResult(name: "Unknown Plant", scientificName: nil, family: nil, growthHabit: .other, sunExposure: .variable, waterNeeds: .variable, matureHeight: nil, matureWidth: nil, hardinessZones: nil, bloomTime: nil, flowerColor: nil, description: "Unable to identify this plant")
    }
    
    // MARK: - Health Analysis
    
    func analyzePlantHealth(from imageData: Data) async throws -> PlantHealthAnalysis {
        guard !openAIAPIKey.isEmpty else {
            throw AIPlantSearchError.configurationError("OpenAI API key not configured")
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody = ChatCompletionRequest(
            model: "gpt-4o",
            messages: [
                ChatMessage(role: "system", content: "You are a plant health expert. Analyze the image for signs of disease, pests, or health issues."),
                ChatMessage(role: "user", content: [
                    .text("Analyze this plant's health and return a JSON response with: overallHealth (excellent/good/fair/poor), issues (array of problems), recommendations (array of suggestions), confidence (0-1)."),
                    .text("data:image/jpeg;base64,\(base64Image)")
                ])
            ],
            temperature: 0.3,
            maxTokens: 800
        )
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIPlantSearchError.apiError("Health analysis failed")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        
        guard let content = chatResponse.choices.first?.message.content else {
            throw AIPlantSearchError.parsingError("No content in health analysis response")
        }
        
        let contentString: String
        switch content {
        case .text(let text):
            contentString = text
        case .array(let array):
            contentString = array.compactMap { item in
                switch item {
                case .text(let text): return text
                case .array: return nil
                }
            }.joined(separator: " ")
        }
        let cleanedResponse = cleanJSONResponse(contentString)
        
        do {
            let analysis = try JSONDecoder().decode(PlantHealthAnalysis.self, from: Data(cleanedResponse.utf8))
            return analysis
        } catch {
            throw AIPlantSearchError.parsingError("Failed to parse health analysis: \(error.localizedDescription)")
        }
    }
}

// MARK: - Data Models

struct AIPlantSearchResult: Identifiable, Codable {
    let id = UUID()
    let name: String
    let scientificName: String?
    let family: String?
    let growthHabit: GrowthHabit
    let sunExposure: SunExposure
    let waterNeeds: WaterNeeds
    let matureHeight: Double?
    let matureWidth: Double?
    let hardinessZones: [Int]?
    let bloomTime: String?
    let flowerColor: [String]?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case name, scientificName, family, growthHabit, sunExposure, waterNeeds
        case matureHeight, matureWidth, hardinessZones, bloomTime, flowerColor, description
    }
}

enum GrowthHabit: String, Codable, CaseIterable {
    case tree = "tree"
    case shrub = "shrub"
    case vine = "vine"
    case herb = "herb"
    case grass = "grass"
    case succulent = "succulent"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .tree: return "Tree"
        case .shrub: return "Shrub"
        case .vine: return "Vine"
        case .herb: return "Herb"
        case .grass: return "Grass"
        case .succulent: return "Succulent"
        case .other: return "Other"
        }
    }
}

enum SunExposure: String, Codable, CaseIterable {
    case fullSun = "full_sun"
    case partialShade = "partial_shade"
    case fullShade = "full_shade"
    case variable = "variable"
    
    var displayName: String {
        switch self {
        case .fullSun: return "Full Sun"
        case .partialShade: return "Partial Shade"
        case .fullShade: return "Full Shade"
        case .variable: return "Variable"
        }
    }
    
    var icon: String {
        switch self {
        case .fullSun: return "sun.max.fill"
        case .partialShade: return "sun.min.fill"
        case .fullShade: return "cloud.fill"
        case .variable: return "sun.and.cloud.fill"
        }
    }
}

enum WaterNeeds: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case variable = "variable"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .variable: return "Variable"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "drop.slash"
        case .moderate: return "drop"
        case .high: return "drop.fill"
        case .variable: return "drop.degreesign"
        }
    }
}

struct PlantHealthAnalysis: Codable {
    let overallHealth: String
    let issues: [String]
    let recommendations: [String]
    let confidence: Double
}

// MARK: - API Request/Response Models

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: ChatMessageContent
    
    init(role: String, content: String) {
        self.role = role
        self.content = .text(content)
    }
    
    init(role: String, content: [ChatMessageContent]) {
        self.role = role
        self.content = .array(content)
    }
}

enum ChatMessageContent: Codable {
    case text(String)
    case array([ChatMessageContent])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .text(string)
        } else if let array = try? container.decode([ChatMessageContent].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(ChatMessageContent.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Array"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .text(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        }
    }
}

struct ImageURL: Codable {
    let url: String
}

struct ChatCompletionResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

// MARK: - Error Types

enum AIPlantSearchError: LocalizedError {
    case configurationError(String)
    case networkError(String)
    case apiError(String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
