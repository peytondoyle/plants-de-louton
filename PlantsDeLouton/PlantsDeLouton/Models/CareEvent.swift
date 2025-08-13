import Foundation

struct CareEvent: Identifiable, Codable {
    let id: UUID
    var type: CareType
    var date: Date
    var notes: String?
    var plantId: UUID?
    
    enum CareType: String, Codable, CaseIterable {
        case watering = "Watering"
        case fertilizing = "Fertilizing"
        case pruning = "Pruning"
        case repotting = "Repotting"
        case other = "Other"
    }
    
    init(
        id: UUID = UUID(),
        type: CareType,
        date: Date = Date(),
        notes: String? = nil,
        plantId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.date = date
        self.notes = notes
        self.plantId = plantId
    }
}
