import Foundation

class BedsViewModel: ObservableObject {
    @Published var beds: [Bed] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadBeds() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            var fetchedBeds = try await DataService.shared.fetchBeds()
            
            // Load plants for each bed
            for i in 0..<fetchedBeds.count {
                do {
                    let plants = try await DataService.shared.plants(inBed: fetchedBeds[i].id)
                    fetchedBeds[i].plants = plants
                } catch {
                    // Handle error appropriately in production
                    fetchedBeds[i].plants = []
                }
            }
            
            await MainActor.run {
                self.beds = fetchedBeds
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}


