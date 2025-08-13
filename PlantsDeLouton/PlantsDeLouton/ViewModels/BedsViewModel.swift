import Foundation

class BedsViewModel: ObservableObject {
    @Published var beds: [Bed] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService = DataService.shared
    
    @MainActor
    func loadBeds() async {
        isLoading = true
        errorMessage = nil
        do {
            var fetchedBeds = try await dataService.fetchBeds()
            
            // Load plants for each bed to get accurate counts
            for i in 0..<fetchedBeds.count {
                do {
                    let plantsInBed = try await dataService.plants(inBed: fetchedBeds[i].id)
                    fetchedBeds[i].plants = plantsInBed
                } catch {
                    print("Failed to load plants for bed \(fetchedBeds[i].name): \(error)")
                    fetchedBeds[i].plants = []
                }
            }
            
            self.beds = fetchedBeds
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}


