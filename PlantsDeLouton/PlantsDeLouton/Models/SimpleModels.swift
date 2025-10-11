import SwiftUI

// MARK: - Core Models
struct Space: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    var imageURL: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageURL = "image_url"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), name: String, description: String? = nil, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.createdAt = Date()
    }
}

struct Bed: Identifiable, Codable {
    let id: UUID
    var spaceId: UUID
    var name: String
    var description: String?
    var imageURL: String?
    var width: Double
    var height: Double
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case spaceId = "space_id"
        case name
        case description
        case imageURL = "image_url"
        case width
        case height
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), spaceId: UUID, name: String, description: String? = nil, imageURL: String? = nil, width: Double = 100, height: Double = 100) {
        self.id = id
        self.spaceId = spaceId
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.width = width
        self.height = height
        self.createdAt = Date()
    }
}

struct Pin: Identifiable, Codable {
    let id: UUID
    var bedId: UUID
    var name: String
    var type: PlantType
    var health: PlantHealth
    var x: Double
    var y: Double
    var notes: String?
    var sunNeeds: SunLevel?
    var waterNeeds: WaterLevel?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case bedId = "bed_id"
        case name
        case type
        case health
        case x
        case y
        case notes
        case sunNeeds = "sun_needs"
        case waterNeeds = "water_needs"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), bedId: UUID, name: String, type: PlantType, health: PlantHealth = .healthy, x: Double, y: Double, notes: String? = nil, sunNeeds: SunLevel? = nil, waterNeeds: WaterLevel? = nil) {
        self.id = id
        self.bedId = bedId
        self.name = name
        self.type = type
        self.health = health
        self.x = x
        self.y = y
        self.notes = notes
        self.sunNeeds = sunNeeds
        self.waterNeeds = waterNeeds
        self.createdAt = Date()
    }
}

// MARK: - Enums
enum PlantType: String, CaseIterable, Codable {
    case plant = "plant"
    case tree = "tree"
    case shrub = "shrub"
    case flower = "flower"
    case herb = "herb"
    case vegetable = "vegetable"
    case fruit = "fruit"
    
    var icon: String {
        switch self {
        case .plant: return "leaf.fill"
        case .tree: return "tree.fill"
        case .shrub: return "leaf.circle.fill"
        case .flower: return "flower"
        case .herb: return "leaf"
        case .vegetable: return "carrot.fill"
        case .fruit: return "applelogo"
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum PlantHealth: String, CaseIterable, Codable {
    case healthy = "healthy"
    case needsWater = "needs_water"
    case needsSun = "needs_sun"
    case needsPruning = "needs_pruning"
    case diseased = "diseased"
    case dead = "dead"
    
    var color: String {
        switch self {
        case .healthy: return "green"
        case .needsWater: return "blue"
        case .needsSun: return "orange"
        case .needsPruning: return "yellow"
        case .diseased: return "red"
        case .dead: return "gray"
        }
    }
    
    var displayName: String {
        switch self {
        case .healthy: return "Healthy"
        case .needsWater: return "Needs Water"
        case .needsSun: return "Needs Sun"
        case .needsPruning: return "Needs Pruning"
        case .diseased: return "Diseased"
        case .dead: return "Dead"
        }
    }
}

enum SunLevel: String, CaseIterable, Codable {
    case full = "full"
    case partial = "partial"
    case shade = "shade"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .full: return "sun.max.fill"
        case .partial: return "sun.max"
        case .shade: return "cloud.sun"
        }
    }
}

enum WaterLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .low: return "drop"
        case .medium: return "drop.fill"
        case .high: return "drop.triangle.fill"
        }
    }
}

// MARK: - API Response Models
struct GardenStats: Codable {
    let spaceCount: Int
    let bedCount: Int
    let pinCount: Int
    let plantCount: Int
}

struct APIResponse<T: Codable>: Codable {
    let data: T?
    let error: String?
}

// MARK: - Extensions
extension Color {
    init(_ hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
