import SwiftUI

struct WeatherWidgetView: View {
    @StateObject private var weatherService = SimpleWeatherService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            if weatherService.isLoading {
                LoadingWeatherView()
            } else if let error = weatherService.error {
                WeatherErrorView(error: error)
            } else if let weather = weatherService.currentWeather {
                WeatherDisplayView(weather: weather)
            } else {
                WeatherPlaceholderView()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            weatherService.requestWeatherUpdate()
        }
        .onTapGesture {
            // Allow manual refresh by tapping
            weatherService.requestWeatherUpdate()
        }
    }
}

struct LoadingWeatherView: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Loading weather...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Getting current conditions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct WeatherErrorView: View {
    let error: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather unavailable")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

struct WeatherDisplayView: View {
    let weather: SimpleWeatherData
    
    var body: some View {
        HStack(spacing: 16) {
            // Weather icon and emoji
            VStack(spacing: 4) {
                Image(systemName: weather.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text(weather.weatherEmoji)
                    .font(.title2)
            }
            
            // Temperature and condition
            VStack(alignment: .leading, spacing: 4) {
                Text(weather.temperatureString)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(weather.conditionDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Humidity and location
            VStack(alignment: .trailing, spacing: 4) {
                Text(weather.humidityString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(weather.locationName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct WeatherPlaceholderView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cloud.fill")
                .foregroundColor(.gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("Tap to refresh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WeatherWidgetView()
        
        // Preview different states
        LoadingWeatherView()
        WeatherErrorView(error: "Location access denied")
        WeatherDisplayView(weather: SimpleWeatherData.mock())
        WeatherPlaceholderView()
    }
    .padding()
}
