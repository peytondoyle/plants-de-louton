import Foundation

struct Bed: Identifiable, Codable {
    let id: UUID
    var name: String
    var section: String
    var plants: [Plant]
    var imageURL: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        section: String,
        plants: [Plant] = [],
        imageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.section = section
        self.plants = plants
        self.imageURL = imageURL
    }
}
