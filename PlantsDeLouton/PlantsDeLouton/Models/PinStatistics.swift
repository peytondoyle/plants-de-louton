import Foundation

struct PinStatistics: Codable, Equatable {
    let totalPins: Int
    let activePins: Int
    let pinsNeedingCare: Int
    let overduePins: Int
    
    var activePercentage: Double {
        guard totalPins > 0 else { return 0 }
        return Double(activePins) / Double(totalPins) * 100
    }
    
    var carePercentage: Double {
        guard totalPins > 0 else { return 0 }
        return Double(pinsNeedingCare) / Double(totalPins) * 100
    }
    
    var overduePercentage: Double {
        guard totalPins > 0 else { return 0 }
        return Double(overduePins) / Double(totalPins) * 100
    }
    
    var hasOverduePins: Bool {
        return overduePins > 0
    }
    
    var hasPinsNeedingCare: Bool {
        return pinsNeedingCare > 0
    }
    
    var isHealthy: Bool {
        return overduePins == 0 && pinsNeedingCare == 0
    }
    
    var healthStatus: GardenHealthStatus {
        if overduePins > 0 {
            return .critical
        } else if pinsNeedingCare > 0 {
            return .warning
        } else if activePercentage >= 80 {
            return .excellent
        } else if activePercentage >= 60 {
            return .good
        } else {
            return .poor
        }
    }
}

enum GardenHealthStatus: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case poor = "poor"
    case warning = "warning"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .poor: return "Poor"
        case .warning: return "Needs Attention"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .poor: return "orange"
        case .warning: return "yellow"
        case .critical: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "leaf.fill"
        case .good: return "leaf"
        case .poor: return "leaf.badge.minus"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}
