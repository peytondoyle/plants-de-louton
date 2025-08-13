import Foundation

class PlantsViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService = DataService.shared
    
    @MainActor
    func loadPlants() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await dataService.fetchPlants()
            self.plants = fetched
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
