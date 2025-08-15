import Foundation
import CoreLocation
import WeatherKit

// MARK: - Simple Weather Models
struct SimpleWeatherData: Codable {
    let temperature: Double
    let humidity: Double
    let condition: String
    let icon: String
    let locationName: String
    
    // Direct conversion from WeatherKit
    init(from weather: Weather, locationName: String) {
        let current = weather.currentWeather
        self.temperature = current.temperature.value
        self.humidity = current.humidity * 100
        self.condition = current.condition.description
        self.icon = current.symbolName
        self.locationName = locationName
    }
    
    // MARK: - Computed Properties for UI
    
    var temperatureString: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: NSNumber(value: temperature)) ?? "\(Int(temperature))")°F"
    }
    
    var humidityString: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: NSNumber(value: humidity)) ?? "\(Int(humidity))")%"
    }
    
    var conditionDescription: String {
        return condition
    }
    
    var weatherEmoji: String {
        switch icon {
        case "sun.max.fill", "sun.max":
            return "☀️"
        case "cloud.sun.fill", "cloud.sun":
            return "⛅"
        case "cloud.fill", "cloud":
            return "☁️"
        case "cloud.rain.fill", "cloud.rain":
            return "🌧️"
        case "cloud.snow.fill", "cloud.snow":
            return "❄️"
        case "wind":
            return "💨"
        default:
            return "🌤️"
        }
    }
    
    var gardeningTip: String {
        if temperature > 85 {
            return "Hot day - water early morning"
        } else if temperature < 50 {
            return "Cool day - protect sensitive plants"
        } else if humidity > 70 {
            return "Humid day - reduce watering"
        } else if humidity < 30 {
            return "Dry day - increase watering"
        } else {
            return "Perfect day for gardening"
        }
    }
    
    var isGoodForGardening: Bool {
        return temperature >= 50 && temperature <= 85 && humidity >= 30 && humidity <= 70
    }
}

// MARK: - Simple Weather Service
@MainActor
class SimpleWeatherService: NSObject, ObservableObject {
    static let shared = SimpleWeatherService()
    
    @Published var currentWeather: SimpleWeatherData?
    @Published var isLoading = false
    @Published var error: String?
    
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
        if let cachedData = getCachedWeather(), !isCacheExpired(cachedData) {
            print("Using cached weather data")
            self.currentWeather = cachedData
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
        
        Task {
            do {
                let location = CLLocation(latitude: latitude, longitude: longitude)
                let weather = try await WeatherService.shared.weather(for: location)
                
                // Get location name
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                let locationName = placemarks.first?.locality ?? "Current Location"
                
                let weatherData = SimpleWeatherData(from: weather, locationName: locationName)
                
                // Cache the data
                cacheWeather(weatherData)
                
                self.currentWeather = weatherData
                self.error = nil
            } catch {
                print("Weather fetch error: \(error)")
                self.error = "Failed to load weather: \(error.localizedDescription)"
            }
            
            self.isLoading = false
        }
    }
    
    // MARK: - Caching
    
    private func cacheWeather(_ weather: SimpleWeatherData) {
        do {
            let encoded = try JSONEncoder().encode(weather)
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        } catch {
            print("Failed to cache weather: \(error)")
        }
    }
    
    private func getCachedWeather() -> SimpleWeatherData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(SimpleWeatherData.self, from: data)
        } catch {
            print("Failed to decode cached weather: \(error)")
            return nil
        }
    }
    
    private func isCacheExpired(_ data: SimpleWeatherData) -> Bool {
        // For now, always consider cache expired to ensure fresh data
        // TODO: Add timestamp to SimpleWeatherData for proper cache management
        return true
    }
}

// MARK: - Location Manager Delegate
extension SimpleWeatherService: CLLocationManagerDelegate {
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


