import SwiftUI

struct BedsListView: View {
    @StateObject private var viewModel = BedsViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.beds) { bed in
                NavigationLink(destination: BedDetailView(bed: bed)) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bed.name)
                                .font(.headline)
                            Text(bed.section)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "leaf")
                                .foregroundColor(.green)
                            Text("\(bed.plants.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading beds...")
            } else if let message = viewModel.errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.beds.isEmpty {
                Text("No beds yet. Add one from Settings or later from Plants.")
                    .foregroundColor(.secondary)
            }
        }
        .task { await viewModel.loadBeds() }
        .navigationTitle("Beds")
    }
}


