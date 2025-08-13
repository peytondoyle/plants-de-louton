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
            let fetched = try await dataService.fetchBeds()
            self.beds = fetched
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}


