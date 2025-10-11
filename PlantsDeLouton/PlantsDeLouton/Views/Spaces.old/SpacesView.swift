// The new main navigation view - replaces complex section management
// Simple list of customizable spaces

import SwiftUI

struct SpacesView: View {
    @StateObject private var api = GardenAPI.shared
    @State private var spaces: [Space] = []
    @State private var isLoading = false
    @State private var showingAddSpace = false
    @State private var newSpaceName = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading spaces...")
                } else if spaces.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Spaces Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create your first garden space to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Create Space") {
                            showingAddSpace = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(spaces) { space in
                        NavigationLink(destination: SpaceDetailView(space: space)) {
                            HStack {
                                Image(systemName: "square.grid.2x2.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(space.name)
                                        .font(.headline)
                                    
                                    if let description = space.description {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Spaces")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSpace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSpace) {
                AddSpaceSheet(gardenAPI: api)
            }
            .task {
                await loadSpaces()
            }
        }
    }
    
    private func loadSpaces() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            spaces = try await api.loadSpaces()
        } catch {
            print("Error loading spaces: \(error)")
        }
    }
}

#Preview {
    SpacesView()
}
