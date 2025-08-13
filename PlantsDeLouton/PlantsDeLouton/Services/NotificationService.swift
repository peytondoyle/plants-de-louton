import Foundation
import UserNotifications
import CoreLocation

// MARK: - Notification Service
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Care Reminders
    
    /// Schedule a care reminder for a specific plant
    func scheduleCareReminder(
        for plant: Plant,
        type: CareType,
        date: Date,
        notes: String? = nil
    ) async {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Care Reminder"
        content.body = "Time to \(type.rawValue.lowercased()) your \(plant.name)"
        content.sound = .default
        content.badge = 1
        
        // Add plant info to user info
        content.userInfo = [
            "plantId": plant.id.uuidString,
            "plantName": plant.name,
            "careType": type.rawValue,
            "notes": notes ?? ""
        ]
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            ),
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "care-\(plant.id.uuidString)-\(type.rawValue)-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled care reminder for \(plant.name)")
        } catch {
            print("Failed to schedule care reminder: \(error)")
        }
    }
    
    /// Schedule smart care reminders based on weather and plant needs
    func scheduleSmartCareReminders(
        for plant: Plant,
        weatherService: GardenWeatherService
    ) async {
        guard let weather = weatherService.currentWeather else { return }
        
        // Get plant care history
        let supabaseService = SupabaseService.shared
        let careEvents = try? await supabaseService.fetchCareEvents()
        let plantCareEvents = careEvents?.filter { $0.plantId == plant.id } ?? []
        
        // Calculate next watering date based on weather and plant type
        let lastWatering = plantCareEvents
            .filter { $0.type == .watering }
            .max { $0.date < $1.date }?.date
        
        let daysSinceWatering = lastWatering.map { 
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 
        } ?? 7
        
        // Determine next watering date
        let baseWateringDays: Int
        switch plant.waterNeeds?.lowercased() {
        case "low": baseWateringDays = 7
        case "high": baseWateringDays = 2
        default: baseWateringDays = 4
        }
        
        // Adjust for weather conditions
        var adjustedDays = baseWateringDays
        let temp = weather.main.temp
        let humidity = weather.main.humidity
        
        if temp > 80 { adjustedDays -= 1 }
        if temp > 90 { adjustedDays -= 1 }
        if humidity < 30 { adjustedDays -= 1 }
        if humidity < 20 { adjustedDays -= 1 }
        
        if weather.weather.contains(where: { $0.main.lowercased().contains("rain") }) {
            adjustedDays += 2
        }
        
        // Schedule watering reminder
        if daysSinceWatering >= adjustedDays {
            let nextWateringDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            await scheduleCareReminder(
                for: plant,
                type: .watering,
                date: nextWateringDate,
                notes: "Based on weather conditions and plant needs"
            )
        }
        
        // Schedule other care reminders
        await scheduleFertilizingReminder(for: plant)
        await schedulePruningReminder(for: plant)
    }
    
    private func scheduleFertilizingReminder(for plant: Plant) async {
        // Schedule fertilizing every 2-4 weeks depending on plant type
        let fertilizingInterval = plant.fertilizerNeeds == "high" ? 14 : 28 // days
        
        let nextFertilizingDate = Calendar.current.date(
            byAdding: .day,
            value: fertilizingInterval,
            to: Date()
        ) ?? Date()
        
        await scheduleCareReminder(
            for: plant,
            type: .fertilizing,
            date: nextFertilizingDate
        )
    }
    
    private func schedulePruningReminder(for plant: Plant) async {
        // Schedule pruning based on plant type and season
        let pruningInterval = plant.pruningNeeds == "heavy" ? 30 : 60 // days
        
        let nextPruningDate = Calendar.current.date(
            byAdding: .day,
            value: pruningInterval,
            to: Date()
        ) ?? Date()
        
        await scheduleCareReminder(
            for: plant,
            type: .pruning,
            date: nextPruningDate
        )
    }
    
    // MARK: - Weather Alerts
    
    /// Schedule weather-based alerts
    func scheduleWeatherAlerts(weatherService: GardenWeatherService) async {
        guard let weather = weatherService.currentWeather else { return }
        
        let temp = weather.main.temp
        
        // Frost alert
        if temp < 32 {
            await scheduleFrostAlert(temperature: temp)
        }
        
        // Heat alert
        if temp > 95 {
            await scheduleHeatAlert(temperature: temp)
        }
        
        // Drought alert
        if weather.main.humidity < 20 {
            await scheduleDroughtAlert(humidity: weather.main.humidity)
        }
    }
    
    private func scheduleFrostAlert(temperature: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "🌨️ Frost Alert"
        content.body = "Temperature is \(Int(temperature))°F. Protect your plants from frost!"
        content.sound = .defaultCritical
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "frost-alert-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule frost alert: \(error)")
        }
    }
    
    private func scheduleHeatAlert(temperature: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "🌡️ Heat Alert"
        content.body = "Temperature is \(Int(temperature))°F. Provide extra water and shade for your plants!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "heat-alert-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule heat alert: \(error)")
        }
    }
    
    private func scheduleDroughtAlert(humidity: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "💧 Drought Alert"
        content.body = "Humidity is \(humidity)%. Your plants need extra water!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "drought-alert-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule drought alert: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    /// Get all pending notifications
    func fetchPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingNotifications = requests
    }
    
    /// Cancel all notifications for a specific plant
    func cancelNotifications(for plantId: UUID) async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let plantNotifications = requests.filter { request in
            request.content.userInfo["plantId"] as? String == plantId.uuidString
        }
        
        let identifiers = plantNotifications.map { $0.identifier }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        await fetchPendingNotifications()
    }
    
    /// Cancel all notifications
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await fetchPendingNotifications()
    }
    
    /// Reschedule all notifications for all plants
    func rescheduleAllNotifications(weatherService: GardenWeatherService) async {
        guard isAuthorized else { return }
        
        // Cancel existing notifications
        await cancelAllNotifications()
        
        // Get all plants
        let supabaseService = SupabaseService.shared
        do {
            let plants = try await supabaseService.listPlants()
            
            // Schedule smart reminders for each plant
            for plant in plants {
                await scheduleSmartCareReminders(for: plant, weatherService: weatherService)
            }
            
            // Schedule weather alerts
            await scheduleWeatherAlerts(weatherService: weatherService)
            
            // Fetch updated notifications
            await fetchPendingNotifications()
            
        } catch {
            print("Failed to reschedule notifications: \(error)")
        }
    }
}

// MARK: - Notification Delegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let plantIdString = userInfo["plantId"] as? String,
           let plantId = UUID(uuidString: plantIdString) {
            // Navigate to plant details or mark care as completed
            print("Notification tapped for plant: \(plantId)")
            
            // TODO: Implement navigation to plant details
            // This could be handled by a coordinator or navigation service
        }
        
        completionHandler()
    }
}
