import Foundation

struct Pin: Identifiable, Codable, Equatable {
    let id: String
    let bedId: String
    let imageId: String?
    let name: String?
    let notes: String?
    let x: Double
    let y: Double
    let createdAt: Date
    let updatedAt: Date?
    let plantId: String?
    let imageUrl: String?
    
    // Enhanced fields for plant management
    let plantInstanceId: String?
    let plantDetailsId: String?
    let status: PinStatus
    let lastCareDate: Date?
    let nextCareDate: Date?
    
    init(
        id: String = UUID().uuidString,
        bedId: String,
        imageId: String? = nil,
        name: String? = nil,
        notes: String? = nil,
        x: Double,
        y: Double,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        plantId: String? = nil,
        imageUrl: String? = nil,
        plantInstanceId: String? = nil,
        plantDetailsId: String? = nil,
        status: PinStatus = .active,
        lastCareDate: Date? = nil,
        nextCareDate: Date? = nil
    ) {
        self.id = id
        self.bedId = bedId
        self.imageId = imageId
        self.name = name
        self.notes = notes
        self.x = x
        self.y = y
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.plantId = plantId
        self.imageUrl = imageUrl
        self.plantInstanceId = plantInstanceId
        self.plantDetailsId = plantDetailsId
        self.status = status
        self.lastCareDate = lastCareDate
        self.nextCareDate = nextCareDate
    }
}

enum PinStatus: String, Codable, CaseIterable {
    case active = "active"
    case dormant = "dormant"
    case removed = "removed"
    case dead = "dead"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .dormant: return "Dormant"
        case .removed: return "Removed"
        case .dead: return "Dead"
        }
    }
    
    var color: String {
        switch self {
        case .active: return "green"
        case .dormant: return "orange"
        case .removed: return "gray"
        case .dead: return "red"
        }
    }
}

// MARK: - Pin Extensions
extension Pin {
    var displayName: String {
        return name ?? "Unnamed Plant"
    }
    
    var hasNotes: Bool {
        return notes?.isEmpty == false
    }
    
    var isActive: Bool {
        return status == .active
    }
    
    var needsCare: Bool {
        guard let nextCareDate = nextCareDate else { return false }
        return nextCareDate <= Date()
    }
    
    var careOverdue: Bool {
        guard let nextCareDate = nextCareDate else { return false }
        return nextCareDate < Date().addingTimeInterval(-24 * 60 * 60) // 1 day ago
    }
}
