import SwiftUI

struct BedsListView: View {
    @StateObject private var viewModel = BedsViewModel()
    @StateObject private var supabaseService = SupabaseService.shared
    
    var body: some View {
        Group {
            if !supabaseService.isSignedIn {
                AuthRequiredView()
            } else {
                // Beds List
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
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text("Error Loading Beds")
                                .font(.headline)
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else if viewModel.beds.isEmpty {
                        BedsEmptyState {
                            // For now, this will be handled by the user manually
                            // In the future, we could add a "Create Bed" button here
                        }
                    }
                }
            }
        }
        .task {
            if supabaseService.isSignedIn {
                await viewModel.loadBeds()
            }
        }
        .onChange(of: supabaseService.isSignedIn) { oldValue, newValue in
            if newValue {
                Task {
                    await viewModel.loadBeds()
                }
            } else {
                viewModel.beds = []
                viewModel.errorMessage = nil
            }
        }
        .navigationTitle("Beds")
    }
}


