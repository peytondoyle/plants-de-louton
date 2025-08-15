import Foundation

struct CareEvent: Identifiable, Codable {
    let id: UUID
    let plantId: UUID
    let eventType: String // "watering", "fertilizing", "pruning", etc.
    let eventDate: Date
    let description: String
    let notes: String?
    let cost: Double?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        plantId: UUID,
        eventType: String,
        eventDate: Date,
        description: String,
        notes: String? = nil,
        cost: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.plantId = plantId
        self.eventType = eventType
        self.eventDate = eventDate
        self.description = description
        self.notes = notes
        self.cost = cost
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Care Event Types
extension CareEvent {
    static let eventTypes = [
        "watering",
        "fertilizing", 
        "pruning",
        "pest_treatment",
        "disease_treatment",
        "transplanting",
        "harvesting",
        "other"
    ]
    
    static func displayName(for eventType: String) -> String {
        switch eventType {
        case "watering": return "Watering"
        case "fertilizing": return "Fertilizing"
        case "pruning": return "Pruning"
        case "pest_treatment": return "Pest Treatment"
        case "disease_treatment": return "Disease Treatment"
        case "transplanting": return "Transplanting"
        case "harvesting": return "Harvesting"
        default: return eventType.capitalized
        }
    }
    
    static func iconName(for eventType: String) -> String {
        switch eventType {
        case "watering": return "drop.fill"
        case "fertilizing": return "leaf.fill"
        case "pruning": return "scissors"
        case "pest_treatment": return "ant.fill"
        case "disease_treatment": return "cross.fill"
        case "transplanting": return "arrow.triangle.2.circlepath"
        case "harvesting": return "hand.raised.fill"
        default: return "note.text"
        }
    }
}
