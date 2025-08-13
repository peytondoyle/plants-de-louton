import SwiftUI

struct PlantSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = AIPlantSearchService.shared
    @State private var searchText = ""
    @State private var searchResults: [AIPlantSearchResult] = []
    @State private var hasSearched = false
    
    let onPlantSelected: (AIPlantSearchResult) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    Text("🔍 AI Plant Search")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter the name of your plant and let AI find detailed information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Enter plant name (e.g., \"Tomato\", \"Rose\")", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                    )
                    
                    // Search Button
                    Button(action: performSearch) {
                        HStack {
                            if searchService.isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(searchService.isSearching ? "Searching..." : "Search with AI")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(searchText.isEmpty ? Color.gray : Color.blue)
                        )
                    }
                    .disabled(searchText.isEmpty || searchService.isSearching)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                Divider()
                
                // Results
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if searchService.isSearching {
                            // Loading State
                            VStack(spacing: 16) {
                                Spacer().frame(height: 40)
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Searching for plant information...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else if hasSearched && searchResults.isEmpty {
                            // Empty State
                            VStack(spacing: 16) {
                                Spacer().frame(height: 40)
                                Image(systemName: "leaf.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No plants found")
                                    .font(.headline)
                                Text("Try a different search term like \"Tomato\", \"Rose\", or \"Basil\"")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                        } else if !searchResults.isEmpty {
                            // Results
                            ForEach(searchResults) { plant in
                                PlantResultCard(plant: plant) {
                                    onPlantSelected(plant)
                                    dismiss()
                                }
                            }
                        } else {
                            // Initial State
                            VStack(spacing: 24) {
                                Spacer().frame(height: 40)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue)
                                
                                VStack(spacing: 8) {
                                    Text("AI Plant Discovery")
                                        .font(.headline)
                                    Text("Enter a plant name above to get detailed information powered by AI")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                // Example searches
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Try searching for:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                        ForEach(["Tomato", "Rose", "Basil", "Lavender"], id: \.self) { example in
                                            Button(action: {
                                                searchText = example
                                                performSearch()
                                            }) {
                                                Text(example)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.blue.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                
                // Error Message
                if let errorMessage = searchService.errorMessage {
                    VStack {
                        Divider()
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        hasSearched = true
        Task {
            do {
                searchResults = try await searchService.searchPlants(query: searchText)
            } catch {
                // Error is handled by the service
            }
        }
    }
}

struct PlantResultCard: View {
    let plant: AIPlantSearchResult
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(plant.scientificName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Quick Info Tags
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    InfoTag(icon: plant.sunExposure.icon, text: plant.sunExposure.displayName)
                    InfoTag(icon: plant.waterNeeds.icon, text: plant.waterNeeds.displayName)
                    InfoTag(icon: "ruler", text: "\(Int(plant.matureHeight))\" tall")
                }
                
                // Common Names
                if !plant.commonNames.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Also known as:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(plant.commonNames.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

#Preview {
    PlantSearchSheet { plant in
        print("Selected: \(plant.name)")
    }
}
