import SwiftUI

struct PlantDetailsView: View {
    @StateObject private var viewModel = PlantDetailsViewModel()
    @State private var showingAISearch = false
    @State private var showingSaveSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // AI Hero Card (shown when no plant data)
                if !viewModel.hasPlantData {
                    AIHeroCardView(showingSearch: $showingAISearch)
                }
                
                // Plant Details Form
                PlantDetailsFormView(
                    plant: $viewModel.plant,
                    plantSearchData: viewModel.selectedPlantData
                )
                
                // Save Button
                VStack(spacing: 12) {
                    Button(action: savePlant) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text(viewModel.isLoading ? "Saving..." : "Save Plant")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.isValid ? Color.green : Color.gray)
                        )
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    
                    // Validation Message
                    if let validationMessage = viewModel.validationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Plant Details")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAISearch) {
            PlantSearchSheet { searchResult in
                viewModel.applyAISearchData(searchResult)
            }
        }
        .alert("Plant Saved!", isPresented: $showingSaveSuccess) {
            Button("OK") {
                // Could navigate back or reset form
            }
        } message: {
            Text("Your plant has been saved successfully!")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAISearch = true }) {
                        Label("Search with AI", systemImage: "magnifyingglass")
                    }
                    
                    Button(action: { viewModel.reset() }) {
                        Label("Reset Form", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func savePlant() {
        Task {
            await viewModel.savePlant()
            if viewModel.errorMessage == nil {
                showingSaveSuccess = true
            }
        }
    }
}

#Preview("Empty State") {
    NavigationView {
        PlantDetailsView()
    }
}

#Preview("With Data") {
    NavigationView {
        PlantDetailsView()
    }
    .onAppear {
        // This won't work in preview, but shows the structure
    }
}
