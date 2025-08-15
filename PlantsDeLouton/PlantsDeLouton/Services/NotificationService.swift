import Foundation
import UserNotifications

// MARK: - Notification Service

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var error: String?
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                if !granted {
                    self.error = "Notification permission denied"
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to request notification permission: \(error.localizedDescription)"
            }
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
    
    func scheduleCareReminder(for plant: Plant, type: CareReminderType, date: Date) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Plant Care Reminder"
        content.body = createReminderMessage(for: plant, type: type)
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "care-\(plant.id.uuidString)-\(type.rawValue)-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    private func createReminderMessage(for plant: Plant, type: CareReminderType) -> String {
        switch type {
        case .watering:
            return "Time to water your \(plant.name)"
        case .fertilizing:
            return "Time to fertilize your \(plant.name)"
        case .pruning:
            return "Time to prune your \(plant.name)"
        case .repotting:
            return "Time to repot your \(plant.name)"
        }
    }
    
    // MARK: - Weather Alerts
    
    func scheduleFrostAlert(for plants: [Plant], date: Date) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Frost Alert"
        content.body = "Protect your \(plants.count) plant(s) from frost tonight"
        content.sound = .defaultCritical
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "frost-alert-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleHeatAlert(for plants: [Plant], date: Date) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Heat Alert"
        content.body = "Provide extra water and shade for your \(plants.count) plant(s)"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "heat-alert-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDroughtAlert(for plants: [Plant], date: Date) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Drought Alert"
        content.body = "Increase watering for your \(plants.count) plant(s) due to dry conditions"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "drought-alert-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Notification Management
    
    func cancelAllNotifications() async {
        await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(for plantId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        
        let plantRequests = requests.filter { request in
            request.identifier.contains(plantId.uuidString)
        }
        
        let identifiers = plantRequests.map { $0.identifier }
        await center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func rescheduleNotifications(for plants: [Plant]) async throws {
        // Cancel existing notifications
        await cancelAllNotifications()
        
        // Schedule new notifications based on current plant data
        for plant in plants {
            // Schedule watering reminders based on plant water needs
            if let waterNeeds = plant.waterNeeds {
                let interval: TimeInterval
                switch waterNeeds.lowercased() {
                case "low":
                    interval = 7 * 24 * 60 * 60 // 7 days
                case "high":
                    interval = 2 * 24 * 60 * 60 // 2 days
                default:
                    interval = 4 * 24 * 60 * 60 // 4 days
                }
                
                let nextWatering = Date().addingTimeInterval(interval)
                try await scheduleCareReminder(for: plant, type: .watering, date: nextWatering)
            }
        }
    }
    
    // MARK: - Notification Handling
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let identifier = response.notification.request.identifier
        
        if identifier.contains("care-") {
            // Extract plant ID from notification identifier
            let components = identifier.split(separator: "-")
            if components.count >= 2 {
                let plantIdString = String(components[1])
                if let plantId = UUID(uuidString: plantIdString) {
                    // Handle care reminder tap
                    handleCareReminderTap(plantId: plantId)
                }
            }
        }
    }
    
    private func handleCareReminderTap(plantId: UUID) {
        // In a real app, you would navigate to the plant detail view
        // For now, we'll just log the action
        // This could be handled by a delegate or callback
    }
}

// MARK: - Supporting Types

enum CareReminderType: String, CaseIterable {
    case watering = "watering"
    case fertilizing = "fertilizing"
    case pruning = "pruning"
    case repotting = "repotting"
    
    var displayName: String {
        switch self {
        case .watering: return "Watering"
        case .fertilizing: return "Fertilizing"
        case .pruning: return "Pruning"
        case .repotting: return "Repotting"
        }
    }
    
    var icon: String {
        switch self {
        case .watering: return "drop.fill"
        case .fertilizing: return "leaf.fill"
        case .pruning: return "scissors"
        case .repotting: return "arrow.up.arrow.down"
        }
    }
}

enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permission not granted"
        case .schedulingFailed:
            return "Failed to schedule notification"
        }
    }
}
