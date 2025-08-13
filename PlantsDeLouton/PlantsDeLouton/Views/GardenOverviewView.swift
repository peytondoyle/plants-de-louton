import SwiftUI

struct GardenOverviewView: View {
    @StateObject private var viewModel = GardenViewModel()
    @StateObject private var weatherService = GardenWeatherService.shared
    // @StateObject private var notificationService = NotificationService.shared
    @State private var plants: [Plant] = []
    @State private var beds: [Bed] = []
    @State private var frontYardPlants: [Plant] = []
    @State private var backYardPlants: [Plant] = []
    @State private var sideYardPlants: [Plant] = []
    @State private var frontYardBeds: [Bed] = []
    @State private var backYardBeds: [Bed] = []
    @State private var sideYardBeds: [Bed] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var supabaseService = SupabaseService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                if !supabaseService.isSignedIn {
                    AuthRequiredView()
                } else if isLoading {
                    LoadingView()
                } else if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage)
                } else {
                    SectionCardsView(
                        frontYardPlants: frontYardPlants.count,
                        frontYardBeds: frontYardBeds.count,
                        backYardPlants: backYardPlants.count,
                        backYardBeds: backYardBeds.count,
                        sideYardPlants: sideYardPlants.count,
                        sideYardBeds: sideYardBeds.count
                    )
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Today's Garden")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            WeatherCard()
                            SmartCareRemindersCard(weatherService: weatherService)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                QuickActionCard(
                                    icon: "plus.circle.fill",
                                    title: "Add Plant",
                                    color: .green
                                )
                                
                                QuickActionCard(
                                    icon: "drop.circle.fill",
                                    title: "Log Watering",
                                    color: .blue
                                )
                                
                                QuickActionCard(
                                    icon: "camera.circle.fill",
                                    title: "Take Photo",
                                    color: .purple
                                )
                                
                                QuickActionCard(
                                    icon: "leaf.circle.fill",
                                    title: "Add Care Note",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if supabaseService.isSignedIn {
                await loadGardenData()
                weatherService.requestWeatherUpdate()
                
                // Request notification permissions and schedule reminders
                // if await notificationService.requestAuthorization() {
                //     await notificationService.rescheduleAllNotifications(weatherService: weatherService)
                // }
            }
        }
        .onChange(of: supabaseService.isSignedIn) { oldValue, newValue in
            if newValue {
                Task { 
                    await loadGardenData()
                    weatherService.requestWeatherUpdate()
                }
            } else {
                clearData()
            }
        }
        .refreshable {
            if supabaseService.isSignedIn {
                await loadGardenData()
                weatherService.requestWeatherUpdate()
            }
        }
    }
    
    private func loadGardenData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let plantsTask = DataService.shared.fetchPlants()
            async let bedsTask = DataService.shared.fetchBeds()
            
            let (plants, beds) = try await (plantsTask, bedsTask)
            
            self.plants = plants
            self.beds = beds
            
            // Organize by sections
            self.frontYardPlants = plants.filter { plant in
                beds.first { $0.id == plant.bedId }?.section.lowercased().contains("front") == true
            }
            self.backYardPlants = plants.filter { plant in
                beds.first { $0.id == plant.bedId }?.section.lowercased().contains("back") == true
            }
            self.sideYardPlants = plants.filter { plant in
                beds.first { $0.id == plant.bedId }?.section.lowercased().contains("side") == true
            }
            
            self.frontYardBeds = beds.filter { $0.section.lowercased().contains("front") }
            self.backYardBeds = beds.filter { $0.section.lowercased().contains("back") }
            self.sideYardBeds = beds.filter { $0.section.lowercased().contains("side") }
            
        } catch {
            errorMessage = "Failed to load garden data: \(error.localizedDescription)"
            print("Error loading garden data: \(error)")
        }
        
        isLoading = false
    }
    
    private func clearData() {
        plants = []
        beds = []
        frontYardPlants = []
        backYardPlants = []
        sideYardPlants = []
        frontYardBeds = []
        backYardBeds = []
        sideYardBeds = []
        errorMessage = nil
    }
}

struct SectionCardsView: View {
    let frontYardPlants: Int
    let frontYardBeds: Int
    let backYardPlants: Int
    let backYardBeds: Int
    let sideYardPlants: Int
    let sideYardBeds: Int
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: SectionDetailView(sectionName: "Front yard", sectionSlug: "front-yard", sectionColor: .green)) {
                SectionCard(
                    title: "Front yard",
                    plants: frontYardPlants,
                    beds: frontYardBeds,
                    icon: "house.fill",
                    color: .green
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: SectionDetailView(sectionName: "Back yard", sectionSlug: "back-yard", sectionColor: .blue)) {
                SectionCard(
                    title: "Back yard",
                    plants: backYardPlants,
                    beds: backYardBeds,
                    icon: "tree.fill",
                    color: .blue
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: SectionDetailView(sectionName: "Side yard", sectionSlug: "side-yard", sectionColor: .orange)) {
                SectionCard(
                    title: "Side yard",
                    plants: sideYardPlants,
                    beds: sideYardBeds,
                    icon: "leaf.fill",
                    color: .orange
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
    }
}

struct SectionCard: View {
    let title: String
    let plants: Int
    let beds: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section with icon and title
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(height: 20)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Stats section
            VStack(spacing: 4) {
                // Plants count
                VStack(spacing: 1) {
                    Text("\(plants)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    Text("plants")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                // Beds count
                VStack(spacing: 1) {
                    Text("\(beds)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("beds")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
        )
    }
}

struct QuickStatView: View {
    let title: String
    let value: Int
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.25), lineWidth: 0.5)
                )
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Helper Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your garden...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct QuickActionsView: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            NavigationLink(destination: PlantDetailsView()) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Add Plant",
                    color: .green
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: BedsListView()) {
                QuickActionCard(
                    icon: "square.grid.2x2",
                    title: "View Beds",
                    color: .blue
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
}






struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct WeatherCard: View {
    @StateObject private var weatherService = GardenWeatherService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            if weatherService.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .foregroundColor(.orange)
            } else {
                Text(weatherService.currentWeather?.weatherEmoji ?? "🌤️")
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(weatherService.currentWeather?.gardeningTip ?? "Loading weather...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(weatherDetails)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(wateringIcon)
                    .font(.title3)
                
                Text(wateringAdvice)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            weatherService.requestWeatherUpdate()
        }
    }
    
    private var weatherDetails: String {
        guard let weather = weatherService.currentWeather else {
            return "Fetching current conditions..."
        }
        
        return "\(weather.temperatureString) • \(weather.conditionDescription) • \(weather.main.humidity)% humidity"
    }
    
    private var wateringIcon: String {
        guard let weather = weatherService.currentWeather else {
            return "💧"
        }
        
        if weather.main.humidity > 70 {
            return "💧"
        } else if weather.main.temp > 85 {
            return "🌡️"
        } else {
            return "💧"
        }
    }
    
    private var wateringAdvice: String {
        guard let weather = weatherService.currentWeather else {
            return "Loading..."
        }
        
        if weather.main.humidity > 70 {
            return "Humid day\nwater less"
        } else if weather.main.temp > 85 {
            return "Hot day\nwater more"
        } else if weather.isGoodForGardening {
            return "Good day\nto water"
        } else {
            return "Check soil\nmoisture"
        }
    }
    
    private var borderColor: Color {
        guard let weather = weatherService.currentWeather else {
            return .orange
        }
        
        return weather.isGoodForGardening ? .green : .blue
    }
}

// MARK: - Smart Care Reminders Card
struct SmartCareRemindersCard: View {
    let weatherService: GardenWeatherService
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("Smart Care Recommendations")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(weatherService.careRecommendations.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(.purple))
            }
            
            if weatherService.careRecommendations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("All plants are well cared for!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(weatherService.careRecommendations.prefix(3)) { recommendation in
                        SmartCareRecommendationItem(recommendation: recommendation)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Smart Care Recommendation Item
struct SmartCareRecommendationItem: View {
    let recommendation: CareRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.type.icon)
                .font(.caption)
                .foregroundColor(colorForPriority(recommendation.priority))
                .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(recommendation.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if recommendation.isUrgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForPriority(_ priority: CarePriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Legacy Care Reminders Card (for backward compatibility)
struct CareRemindersCard: View {
    let viewModel: GardenViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Care Reminders")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.careEvents.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(.blue))
            }
            
            if viewModel.careEvents.isEmpty {
                Text("No upcoming care tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.careEvents.prefix(3)) { careEvent in
                        CareReminderItem(
                            icon: iconForCareType(careEvent.type),
                            task: careEvent.notes ?? careEvent.type.rawValue,
                            time: formatDate(careEvent.date),
                            color: colorForCareType(careEvent.type)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CareReminderItem: View {
    let icon: String
    let task: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 12)
            
            Text(task)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct HeroSectionCard: View {
    let title: String
    let plantCount: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("\(plantCount) plants")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.25), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter.string(from: date)
}

private func colorForCareType(_ careType: CareEvent.CareType) -> Color {
    switch careType {
    case .watering: return .blue
    case .fertilizing: return .green
    case .pruning: return .orange
    case .repotting: return .yellow
    case .other: return .gray
    }
}

private func iconForCareType(_ careType: CareEvent.CareType) -> String {
    switch careType {
    case .watering: return "drop.fill"
    case .fertilizing: return "leaf.fill"
    case .pruning: return "scissors"
    case .repotting: return "arrow.up.arrow.down"
    case .other: return "ellipsis.circle"
    }
}

struct AuthRequiredView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Sign In Required")
                .font(.headline)
            
            Text("Please sign in with Apple to view your garden")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: SettingsView()) {
                Text("Go to Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        GardenOverviewView()
    }
}
