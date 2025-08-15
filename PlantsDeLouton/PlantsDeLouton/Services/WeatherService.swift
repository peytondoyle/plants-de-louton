import Foundation
import CoreLocation

// MARK: - Weather Service
// Simplified version without WeatherKit for now

class GardenWeatherService: ObservableObject {
    static let shared = GardenWeatherService()
    
    @Published var currentWeather: WeatherData?
    @Published var forecast: [WeatherData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var careRecommendations: [CareRecommendation] = []
    
    private init() {}
    
    // MARK: - Weather Fetching
    
    func fetchWeather() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // For now, use mock data until WeatherKit is properly configured
            let mockWeather = createMockWeatherData()
            
            await MainActor.run {
                self.currentWeather = mockWeather.current
                self.forecast = mockWeather.forecast
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            print("Weather fetch error: \(error)")
        }
    }
    
    func requestWeatherUpdate() {
        Task {
            await fetchWeather()
        }
    }
    
    private func createMockWeatherData() -> (current: WeatherData, forecast: [WeatherData]) {
        let current = WeatherData(
            temperature: Measurement(value: 72, unit: .fahrenheit),
            condition: "Partly Cloudy",
            humidity: 0.65,
            windSpeed: Measurement(value: 10, unit: .milesPerHour),
            precipitation: nil,
            date: Date()
        )
        
        let forecast = (0..<7).map { dayOffset in
            WeatherData(
                temperature: Measurement(value: Double.random(in: 65...80), unit: .fahrenheit),
                condition: ["Sunny", "Partly Cloudy", "Cloudy", "Light Rain"].randomElement()!,
                humidity: nil,
                windSpeed: nil,
                precipitation: nil,
                date: Date().addingTimeInterval(Double(dayOffset) * 24 * 60 * 60)
            )
        }
        
        return (current: current, forecast: forecast)
    }

    
    // MARK: - Care Recommendations
    
    func generateCareRecommendations(for plants: [Plant]) async throws -> [CareRecommendation] {
        guard let currentWeather = currentWeather else {
            throw WeatherError.noWeatherData
        }
        
        var recommendations: [CareRecommendation] = []
        
        for plant in plants {
            let recommendation = CareRecommendation(
                plantId: plant.id,
                plantName: plant.name,
                recommendation: generateRecommendation(for: plant, weather: currentWeather),
                priority: determinePriority(for: plant, weather: currentWeather),
                date: Date()
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    private func generateRecommendation(for plant: Plant, weather: WeatherData) -> String {
        let temp = weather.temperature.value
        let condition = weather.condition.lowercased()
        
        var recommendations: [String] = []
        
        // Temperature-based recommendations
        if temp < 32 {
            recommendations.append("Protect from frost")
        } else if temp > 90 {
            recommendations.append("Provide extra water and shade")
        }
        
        // Weather condition-based recommendations
        if condition.contains("rain") {
            recommendations.append("Reduce watering - natural precipitation")
        } else if condition.contains("sunny") && temp > 75 {
            recommendations.append("Increase watering frequency")
        }
        
        // Plant-specific recommendations
        if let waterNeeds = plant.waterNeeds {
            switch waterNeeds {
            case "high":
                if !condition.contains("rain") {
                    recommendations.append("Water thoroughly - high water needs")
                }
            case "low":
                if condition.contains("rain") {
                    recommendations.append("Skip watering - low water needs")
                }
            default:
                break
            }
        }
        
        return recommendations.isEmpty ? "No special care needed" : recommendations.joined(separator: ". ")
    }
    
    private func determinePriority(for plant: Plant, weather: WeatherData) -> CarePriority {
        let temp = weather.temperature.value
        let condition = weather.condition.lowercased()
        
        // High priority for extreme conditions
        if temp < 32 || temp > 95 {
            return .high
        }
        
        // Medium priority for moderate stress
        if temp < 40 || temp > 85 {
            return .medium
        }
        
        // Low priority for normal conditions
        return .low
    }
}

// MARK: - Data Models

struct WeatherData {
    let temperature: Measurement<UnitTemperature>
    let condition: String
    let humidity: Double?
    let windSpeed: Measurement<UnitSpeed>?
    let precipitation: Measurement<UnitLength>?
    let date: Date
    
    // Computed properties for compatibility
    var temperatureString: String {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(from: temperature)
    }
    
    var conditionDescription: String {
        return condition
    }
    
    var weatherEmoji: String {
        switch condition.lowercased() {
        case let c where c.contains("sunny") || c.contains("clear"):
            return "☀️"
        case let c where c.contains("cloudy") || c.contains("overcast"):
            return "☁️"
        case let c where c.contains("rain") || c.contains("drizzle"):
            return "🌧️"
        case let c where c.contains("snow"):
            return "❄️"
        case let c where c.contains("storm") || c.contains("thunder"):
            return "⛈️"
        case let c where c.contains("fog") || c.contains("mist"):
            return "🌫️"
        default:
            return "🌤️"
        }
    }
    
    var isGoodForGardening: Bool {
        let temp = temperature.value
        return temp >= 50 && temp <= 85 && !condition.lowercased().contains("storm")
    }
    
    var gardeningTip: String {
        let temp = temperature.value
        if temp < 32 {
            return "Protect plants from frost"
        } else if temp > 90 {
            return "Provide extra water and shade"
        } else if condition.lowercased().contains("rain") {
            return "Reduce watering - natural precipitation"
        } else {
            return "Good conditions for gardening"
        }
    }
}

struct CareRecommendation: Identifiable {
    let id = UUID()
    let plantId: UUID
    let plantName: String
    let recommendation: String
    let priority: CarePriority
    let date: Date
    let type: CareType
    
    init(plantId: UUID, plantName: String, recommendation: String, priority: CarePriority, date: Date, type: CareType = .watering) {
        self.plantId = plantId
        self.plantName = plantName
        self.recommendation = recommendation
        self.priority = priority
        self.date = date
        self.type = type
    }
}

enum CareType {
    case watering
    case fertilizing
    case pruning
    case protection
    
    var icon: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.fill"
        case .pruning: return "scissors"
        case .protection: return "shield.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .watering: return "Watering"
        case .fertilizing: return "Fertilizing"
        case .pruning: return "Pruning"
        case .protection: return "Protection"
        }
    }
}

enum CarePriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        case .critical: return "red"
        }
    }
}

// MARK: - Error Types

enum WeatherError: LocalizedError {
    case noWeatherData
    case locationError
    case weatherKitError
    case locationManagerNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .noWeatherData:
            return "No weather data available"
        case .locationError:
            return "Unable to determine location"
        case .weatherKitError:
            return "Weather service unavailable"
        case .locationManagerNotConfigured:
            return "Location manager not configured"
        }
    }
}
