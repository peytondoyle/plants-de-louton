import SwiftUI

struct BedDetailView: View {
    let bed: Bed
    @State private var plants: [Plant] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            Section(header: Text("Bed Info")) {
                LabeledContent("Name", value: bed.name)
                LabeledContent("Section", value: bed.section)
                LabeledContent("Plants", value: String(plants.count))
            }
            
            Section(header: Text("Plants in this Bed")) {
                if plants.isEmpty {
                    Text("No plants assigned yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(plants) { plant in
                        HStack {
                            Image(systemName: "leaf")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(plant.name)
                                if let sci = plant.scientificName, !sci.isEmpty {
                                    Text(sci).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(bed.name)
        .overlay {
            if isLoading { ProgressView("Loading plants...") }
            if let msg = errorMessage { Text(msg).foregroundColor(.red).padding() }
        }
        .task { await loadPlants() }
    }

    private func loadPlants() async {
        isLoading = true
        errorMessage = nil
        do {
            plants = try await DataService.shared.plants(inBed: bed.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}


