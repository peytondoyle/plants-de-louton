import Foundation
import SwiftUI

@MainActor
class GardenViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var beds: [Bed] = []
    @Published var careEvents: [CareEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService = DataService.shared
    private let supabaseService = SupabaseService.shared
    
    init() {
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let plantsTask = dataService.fetchPlants()
            async let bedsTask = dataService.fetchBeds()
            async let careEventsTask = supabaseService.fetchCareEvents()
            
            let (plants, beds, careEvents) = try await (plantsTask, bedsTask, careEventsTask)
            
            self.plants = plants
            self.beds = beds
            self.careEvents = careEvents
        } catch {
            errorMessage = "Failed to load garden data: \(error.localizedDescription)"
            print("Error loading garden data: \(error)")
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadData()
    }
    
    func addPlant(_ plant: Plant) async {
        do {
            try await dataService.savePlant(plant)
            await loadData()
        } catch {
            errorMessage = "Failed to add plant: \(error.localizedDescription)"
        }
    }
    
    func addBed(_ bed: Bed) async {
        do {
            try await dataService.saveBed(bed)
            await loadData()
        } catch {
            errorMessage = "Failed to add bed: \(error.localizedDescription)"
        }
    }
    
    func addCareEvent(_ careEvent: CareEvent) async {
        do {
            try await supabaseService.saveCareEvent(careEvent)
            await loadData()
        } catch {
            errorMessage = "Failed to add care event: \(error.localizedDescription)"
        }
    }
}
