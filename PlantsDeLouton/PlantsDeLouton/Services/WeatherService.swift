import Foundation
import CoreLocation
import WeatherKit

// MARK: - Weather Models
struct WeatherResponse: Codable {
    let weather: [WeatherInfo]
    let main: MainWeather
    let name: String
}

struct WeatherInfo: Codable {
    let main: String
    let description: String
    let icon: String
}

struct MainWeather: Codable {
    let temp: Double
    let humidity: Int
    let temp_min: Double
    let temp_max: Double
}

struct CachedWeatherData: Codable {
    let weatherResponse: WeatherResponse
    let timestamp: Date
    let cacheExpiryMinutes: Int
    
    init(weatherResponse: WeatherResponse, timestamp: Date) {
        self.weatherResponse = weatherResponse
        self.timestamp = timestamp
        self.cacheExpiryMinutes = 30
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > TimeInterval(cacheExpiryMinutes * 60)
    }
}

// MARK: - Care Recommendation Models
struct CareRecommendation: Identifiable, Codable {
    let id: UUID
    let plantId: UUID
    let type: CareRecommendationType
    let priority: CarePriority
    let reason: String
    let recommendedDate: Date
    let weatherContext: WeatherContext
    let isUrgent: Bool
    
    init(
        id: UUID = UUID(),
        plantId: UUID,
        type: CareRecommendationType,
        priority: CarePriority,
        reason: String,
        recommendedDate: Date,
        weatherContext: WeatherContext,
        isUrgent: Bool = false
    ) {
        self.id = id
        self.plantId = plantId
        self.type = type
        self.priority = priority
        self.reason = reason
        self.recommendedDate = recommendedDate
        self.weatherContext = weatherContext
        self.isUrgent = isUrgent
    }
}

enum CareRecommendationType: String, CaseIterable, Codable {
    case watering = "watering"
    case fertilizing = "fertilizing"
    case pruning = "pruning"
    case frostProtection = "frost_protection"
    case heatProtection = "heat_protection"
    case transplanting = "transplanting"
    case harvesting = "harvesting"
    
    var displayName: String {
        switch self {
        case .watering: return "Watering"
        case .fertilizing: return "Fertilizing"
        case .pruning: return "Pruning"
        case .frostProtection: return "Frost Protection"
        case .heatProtection: return "Heat Protection"
        case .transplanting: return "Transplanting"
        case .harvesting: return "Harvesting"
        }
    }
    
    var icon: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.fill"
        case .pruning: return "scissors"
        case .frostProtection: return "thermometer.snowflake"
        case .heatProtection: return "thermometer.sun"
        case .transplanting: return "arrow.up.arrow.down"
        case .harvesting: return "basket.fill"
        }
    }
}

enum CarePriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

struct WeatherContext: Codable {
    let temperature: Double
    let humidity: Int
    let precipitation: Double
    let forecast: [WeatherForecast]
    let lastWatering: Date?
    let soilMoisture: SoilMoistureLevel
    
    enum SoilMoistureLevel: String, Codable {
        case dry = "dry"
        case moist = "moist"
        case wet = "wet"
    }
}

struct WeatherForecast: Codable {
    let date: Date
    let temperature: Double
    let precipitation: Double
    let humidity: Int
    let condition: String
}

// MARK: - Garden Weather Service  
@MainActor
class GardenWeatherService: NSObject, ObservableObject {
    static let shared = GardenWeatherService()
    
    @Published var currentWeather: WeatherResponse?
    @Published var isLoading = false
    @Published var error: String?
    @Published var careRecommendations: [CareRecommendation] = []
    
    private let locationManager = CLLocationManager()
    private let cacheKey = "cached_weather_data"
    
    // Default location (San Francisco) if location access is denied
    private let defaultLatitude: Double = 37.7749
    private let defaultLongitude: Double = -122.4194
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestWeatherUpdate() {
        // Check cache first
        if let cachedData = getCachedWeather(), !cachedData.isExpired {
            print("Using cached weather data")
            self.currentWeather = cachedData.weatherResponse
            return
        }
        
        // Request location permission and fetch weather
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            // Use default location
            fetchWeather(latitude: defaultLatitude, longitude: defaultLongitude)
        @unknown default:
            fetchWeather(latitude: defaultLatitude, longitude: defaultLongitude)
        }
    }
    
    private func fetchWeather(latitude: Double, longitude: Double) {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        // Use Apple's WeatherKit API
        fetchAppleWeather(latitude: latitude, longitude: longitude)
    }
    
    private func fetchAppleWeather(latitude: Double, longitude: Double) {
        Task {
            do {
                let location = CLLocation(latitude: latitude, longitude: longitude)
                let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
                
                // Convert Apple's weather data to our format
                let weatherResponse = convertAppleWeather(weather, locationName: "Current Location")
                
                // Cache the weather data
                let cachedData = CachedWeatherData(weatherResponse: weatherResponse, timestamp: Date())
                cacheWeatherData(cachedData)
                
                self.currentWeather = weatherResponse
                self.isLoading = false
                
                // Generate care recommendations based on new weather data
                await generateCareRecommendations()
                
            } catch {
                print("Weather fetch error: \(error)")
                self.error = "Failed to fetch weather: \(error.localizedDescription)"
                self.isLoading = false
                
                // Fallback to simulation for development
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    self.currentWeather = createSimulatedWeather()
                }
            }
        }
    }
    
    // MARK: - Smart Care Scheduling
    
    /// Generate care recommendations based on current weather and plant data
    func generateCareRecommendations() async {
        guard let weather = currentWeather else { return }
        
        // Get plants from Supabase
        let supabaseService = SupabaseService.shared
        do {
            let plants = try await supabaseService.listPlants()
            var recommendations: [CareRecommendation] = []
            
            for plant in plants {
                let plantRecommendations = await generateRecommendationsForPlant(plant, weather: weather)
                recommendations.append(contentsOf: plantRecommendations)
            }
            
            // Sort by priority and urgency
            recommendations.sort { first, second in
                if first.isUrgent != second.isUrgent {
                    return first.isUrgent
                }
                return first.priority.rawValue > second.priority.rawValue
            }
            
            self.careRecommendations = recommendations
            
        } catch {
            print("Failed to generate care recommendations: \(error)")
        }
    }
    
    /// Generate care recommendations for a specific plant
    private func generateRecommendationsForPlant(_ plant: Plant, weather: WeatherResponse) async -> [CareRecommendation] {
        var recommendations: [CareRecommendation] = []
        
        // Get plant care history
        let supabaseService = SupabaseService.shared
        let careEvents = try? await supabaseService.fetchCareEvents()
        let plantCareEvents = careEvents?.filter { $0.plantId == plant.id } ?? []
        
        // Analyze weather conditions
        let temp = weather.main.temp
        let humidity = weather.main.humidity
        let isHot = temp > 85
        let isCold = temp < 32
        let isDry = humidity < 30
        
        // Watering recommendations
        let lastWatering = plantCareEvents
            .filter { $0.type == .watering }
            .max { $0.date < $1.date }?.date
        
        let daysSinceWatering = lastWatering.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 } ?? 7
        
        // Determine if watering is needed
        let needsWatering = shouldWaterPlant(plant, daysSinceWatering: daysSinceWatering, weather: weather)
        if needsWatering {
            let priority: CarePriority = daysSinceWatering > 5 ? .high : .medium
            let reason = generateWateringReason(plant, daysSinceWatering: daysSinceWatering, weather: weather)
            
            recommendations.append(CareRecommendation(
                plantId: plant.id,
                type: .watering,
                priority: priority,
                reason: reason,
                recommendedDate: Date(),
                weatherContext: createWeatherContext(weather),
                isUrgent: priority == .high
            ))
        }
        
        // Frost protection
        if isCold {
            recommendations.append(CareRecommendation(
                plantId: plant.id,
                type: .frostProtection,
                priority: .critical,
                reason: "Temperature is \(Int(temp))°F - protect from frost",
                recommendedDate: Date(),
                weatherContext: createWeatherContext(weather),
                isUrgent: true
            ))
        }
        
        // Heat protection
        if isHot {
            recommendations.append(CareRecommendation(
                plantId: plant.id,
                type: .heatProtection,
                priority: .high,
                reason: "Temperature is \(Int(temp))°F - provide shade and extra water",
                recommendedDate: Date(),
                weatherContext: createWeatherContext(weather),
                isUrgent: false
            ))
        }
        
        return recommendations
    }
    
    /// Determine if a plant needs watering based on weather and plant type
    private func shouldWaterPlant(_ plant: Plant, daysSinceWatering: Int, weather: WeatherResponse) -> Bool {
        let temp = weather.main.temp
        let humidity = weather.main.humidity
        
        // Base watering frequency by plant type
        let baseWateringDays: Int
        switch plant.waterNeeds?.lowercased() {
        case "low": baseWateringDays = 7
        case "high": baseWateringDays = 2
        default: baseWateringDays = 4
        }
        
        // Adjust for weather conditions
        var adjustedDays = baseWateringDays
        
        // Hot weather increases water needs
        if temp > 80 { adjustedDays -= 1 }
        if temp > 90 { adjustedDays -= 1 }
        
        // Low humidity increases water needs
        if humidity < 30 { adjustedDays -= 1 }
        if humidity < 20 { adjustedDays -= 1 }
        
        // Rain reduces water needs
        if weather.weather.contains(where: { $0.main.lowercased().contains("rain") }) {
            adjustedDays += 2
        }
        
        return daysSinceWatering >= adjustedDays
    }
    
    /// Generate a human-readable reason for watering recommendation
    private func generateWateringReason(_ plant: Plant, daysSinceWatering: Int, weather: WeatherResponse) -> String {
        let temp = weather.main.temp
        let humidity = weather.main.humidity
        
        var reasons: [String] = []
        
        if daysSinceWatering > 5 {
            reasons.append("Hasn't been watered in \(daysSinceWatering) days")
        }
        
        if temp > 80 {
            reasons.append("High temperature (\(Int(temp))°F)")
        }
        
        if humidity < 30 {
            reasons.append("Low humidity (\(humidity)%)")
        }
        
        if reasons.isEmpty {
            reasons.append("Regular watering schedule")
        }
        
        return reasons.joined(separator: ", ")
    }
    
    /// Create weather context for recommendations
    private func createWeatherContext(_ weather: WeatherResponse) -> WeatherContext {
        return WeatherContext(
            temperature: weather.main.temp,
            humidity: weather.main.humidity,
            precipitation: 0, // Would need to extract from weather data
            forecast: [], // Would need to fetch forecast data
            lastWatering: nil, // Would need to get from care events
            soilMoisture: .moist // Would need soil moisture sensors or estimation
        )
    }
    
    // MARK: - Weather Data Conversion
    
    private func convertAppleWeather(_ weather: Weather, locationName: String) -> WeatherResponse {
        let current = weather.currentWeather
        
        let weatherInfo = WeatherInfo(
            main: current.condition.description,
            description: current.condition.description,
            icon: "sun.max.fill" // Simplified for now
        )
        
        let mainWeather = MainWeather(
            temp: current.temperature.value,
            humidity: Int(current.humidity * 100),
            temp_min: current.temperature.value,
            temp_max: current.temperature.value
        )
        
        return WeatherResponse(
            weather: [weatherInfo],
            main: mainWeather,
            name: locationName
        )
    }
    
    private func createSimulatedWeather() -> WeatherResponse {
        let weatherInfo = WeatherInfo(
            main: "Clear",
            description: "Clear sky",
            icon: "sun.max.fill"
        )
        
        let mainWeather = MainWeather(
            temp: 72.0,
            humidity: 45,
            temp_min: 65.0,
            temp_max: 78.0
        )
        
        return WeatherResponse(
            weather: [weatherInfo],
            main: mainWeather,
            name: "Simulated Location"
        )
    }
    
    // MARK: - Caching
    
    private func getCachedWeather() -> CachedWeatherData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cachedData = try? JSONDecoder().decode(CachedWeatherData.self, from: data) else {
            return nil
        }
        return cachedData
    }
    
    private func cacheWeatherData(_ data: CachedWeatherData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
}

// MARK: - Weather Helper Extensions
extension WeatherResponse {
    var temperatureString: String {
        return "\(Int(main.temp))°F"
    }
    
    var conditionDescription: String {
        return weather.first?.description.capitalized ?? "Unknown"
    }
    
    var weatherEmoji: String {
        guard let condition = weather.first?.main.lowercased() else { return "☀️" }
        
        switch condition {
        case let c where c.contains("clear"): return "☀️"
        case let c where c.contains("cloud"): return "⛅"
        case let c where c.contains("rain"): return "🌧️"
        case let c where c.contains("storm"): return "⛈️"
        case let c where c.contains("snow"): return "🌨️"
        case let c where c.contains("mist"), let c where c.contains("fog"): return "🌫️"
        default: return "🌤️"
        }
    }
    
    var isGoodForGardening: Bool {
        guard let condition = weather.first?.main.lowercased() else { return true }
        
        // Good gardening weather
        let goodConditions = ["clear", "clouds"]
        let badConditions = ["rain", "storm", "snow"]
        
        return goodConditions.contains { condition.contains($0) } && 
               !badConditions.contains { condition.contains($0) }
    }
    
    var gardeningTip: String {
        if isGoodForGardening {
            if main.humidity > 70 {
                return "Great humidity for your plants!"
            } else if main.temp > 80 {
                return "Perfect weather, but provide shade"
            } else {
                return "Perfect day for gardening!"
            }
        } else {
            return "Indoor plant care day"
        }
    }
}

// MARK: - Location Manager Delegate
extension GardenWeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        // Fall back to default location
        Task { @MainActor in
            fetchWeather(latitude: defaultLatitude, longitude: defaultLongitude)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Task { @MainActor in
                locationManager.requestLocation()
            }
        case .denied, .restricted:
            Task { @MainActor in
                fetchWeather(latitude: defaultLatitude, longitude: defaultLongitude)
            }
        default:
            break
        }
    }
}
