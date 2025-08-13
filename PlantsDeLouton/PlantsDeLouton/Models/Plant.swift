import Foundation

struct Plant: Identifiable, Codable {
    let id: UUID
    var name: String
    var scientificName: String?
    var growthHabit: String
    var sunExposure: String
    var waterNeeds: String
    var plantedDate: Date?
    var healthStatus: String
    
    init(
        id: UUID = UUID(),
        name: String,
        scientificName: String? = nil,
        growthHabit: String = "unknown",
        sunExposure: String = "full_sun",
        waterNeeds: String = "moderate",
        plantedDate: Date? = nil,
        healthStatus: String = "Healthy"
    ) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.growthHabit = growthHabit
        self.sunExposure = sunExposure
        self.waterNeeds = waterNeeds
        self.plantedDate = plantedDate
        self.healthStatus = healthStatus
    }
}
