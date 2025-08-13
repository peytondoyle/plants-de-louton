import Foundation

// MARK: - Plant Model
struct Plant: Identifiable, Codable {
    let id: UUID
    var name: String
    let bedId: UUID
    let x: Double
    let y: Double
    var scientificName: String?
    var growthHabit: String?
    var sunExposure: String?
    var waterNeeds: String?
    var notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        bedId: UUID,
        x: Double,
        y: Double,
        scientificName: String? = nil,
        growthHabit: String? = nil,
        sunExposure: String? = nil,
        waterNeeds: String? = nil,
        notes: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.bedId = bedId
        self.x = x
        self.y = y
        self.scientificName = scientificName
        self.growthHabit = growthHabit
        self.sunExposure = sunExposure
        self.waterNeeds = waterNeeds
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
