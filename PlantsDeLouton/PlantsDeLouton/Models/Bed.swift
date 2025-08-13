import Foundation

struct Bed: Identifiable, Codable {
    let id: UUID
    var name: String
    var section: String
    var plants: [Plant]
    
    init(
        id: UUID = UUID(),
        name: String,
        section: String,
        plants: [Plant] = []
    ) {
        self.id = id
        self.name = name
        self.section = section
        self.plants = plants
    }
}
