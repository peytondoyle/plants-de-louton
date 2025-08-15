import Foundation
import SwiftUI

@MainActor
class BedImageViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage?
    @Published var isImageLoading = false
    
    private let bed: Bed
    private let dataService = DataService.shared
    private let supabaseService = SupabaseService.shared
    
    init(bed: Bed) {
        self.bed = bed
    }
    
    func loadPlants() async {
        isLoading = true
        errorMessage = nil
        
        do {
            plants = try await dataService.plants(inBed: bed.id)
            
            // Debug: Print plant coordinates
            print("🔍 Loaded \(plants.count) plants:")
            for plant in plants {
                print("  - \(plant.name): x=\(plant.x), y=\(plant.y)")
            }
        } catch {
            errorMessage = "Failed to load plants: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadImage() async {
        print("🔍 BedImageViewModel: loadImage() called")
        print("🔍 Bed imageURL: \(bed.imageURL ?? "nil")")
        
        guard let imageURL = bed.imageURL else { 
            print("🔍 No imageURL found, returning early")
            return 
        }
        
        isImageLoading = true
        errorMessage = nil
        
        print("🔍 Attempting to download image from: \(imageURL)")
        
        do {
            let image = try await supabaseService.downloadImage(from: imageURL)
            print("🔍 Image downloaded successfully")
            selectedImage = image
        } catch {
            print("🔍 Image download failed: \(error)")
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
        
        isImageLoading = false
    }
    
    func saveImage(_ image: UIImage) async {
        isImageLoading = true
        errorMessage = nil
        
        do {
            let imageURL = try await supabaseService.uploadImage(image, forBed: bed.id)
            // Update the bed with the new image URL
            var updatedBed = bed
            updatedBed.imageURL = imageURL
            try await dataService.updateBed(updatedBed)
            selectedImage = image
        } catch {
            errorMessage = "Failed to save image: \(error.localizedDescription)"
        }
        
        isImageLoading = false
    }
    
    func addPlant(at position: CGPoint, name: String, notes: String? = nil) async {
        // Position is already in relative coordinates (0-1) from the tap handler
        let newPlant = Plant(
            name: name,
            bedId: bed.id,
            x: position.x,
            y: position.y,
            notes: notes
        )
        
        do {
            let savedPlant = try await dataService.createPlant(newPlant)
            plants.append(savedPlant)
        } catch {
            errorMessage = "Failed to add plant: \(error.localizedDescription)"
        }
    }
    
    func updatePlant(_ plant: Plant) async {
        do {
            let updatedPlant = try await dataService.updatePlant(plant)
            if let index = plants.firstIndex(where: { $0.id == plant.id }) {
                plants[index] = updatedPlant
            }
        } catch {
            errorMessage = "Failed to update plant: \(error.localizedDescription)"
        }
    }
    
    func deletePlant(_ plantId: UUID) async {
        do {
            try await dataService.deletePlant(plantId)
            plants.removeAll { $0.id == plantId }
        } catch {
            errorMessage = "Failed to delete plant: \(error.localizedDescription)"
        }
    }
    
    func movePlant(_ plant: Plant, to position: CGPoint) async {
        var updatedPlant = plant
        updatedPlant.x = Double(position.x)
        updatedPlant.y = Double(position.y)
        
        await updatePlant(updatedPlant)
    }
}
