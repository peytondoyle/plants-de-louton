import Foundation
import SwiftUI

@MainActor
class PlantDetailViewModel: ObservableObject {
    @Published var plantInfo: PlantInfo?
    @Published var careEvents: [CareEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let aiService = AIPlantSearchService.shared
    private let dataService = DataService.shared
    
    // Load plant data including AI info and care events
    func loadPlantData(for plant: Plant) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load AI plant information if we have a scientific name
            if let scientificName = plant.scientificName, !scientificName.isEmpty {
                let info = try await aiService.getPlantInfo(for: plant.name)
                plantInfo = info
            }
            
            // Load care events for this plant
            await loadCareEvents(for: plant.id)
            
        } catch {
            errorMessage = "Failed to load plant data: \(error.localizedDescription)"
            print("Error loading plant data: \(error)")
        }
        
        isLoading = false
    }
    
    // Load care events for a plant
    private func loadCareEvents(for plantId: UUID) async {
        do {
            // TODO: Implement care events loading from Supabase
            // For now, we'll use empty array
            careEvents = []
        } catch {
            print("Error loading care events: \(error)")
            careEvents = []
        }
    }
    
    // Add a new care event
    func addCareEvent(_ event: CareEvent) {
        careEvents.insert(event, at: 0) // Add to beginning of list
        
        // TODO: Save to Supabase
        Task {
            do {
                // await dataService.saveCareEvent(event)
                print("Care event added: \(event.description)")
            } catch {
                print("Error saving care event: \(error)")
                // Remove from local array if save failed
                await MainActor.run {
                    careEvents.removeAll { $0.id == event.id }
                }
            }
        }
    }
    
    // Delete a care event
    func deleteCareEvent(_ event: CareEvent) {
        careEvents.removeAll { $0.id == event.id }
        
        // TODO: Delete from Supabase
        Task {
            do {
                // await dataService.deleteCareEvent(event.id)
                print("Care event deleted: \(event.description)")
            } catch {
                print("Error deleting care event: \(error)")
                // Re-add to local array if delete failed
                await MainActor.run {
                    careEvents.append(event)
                }
            }
        }
    }
}
