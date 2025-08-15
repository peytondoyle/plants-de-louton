import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GardenOverviewView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Garden")
            }
            .tag(0)
            
            NavigationStack {
                PlantsView()
            }
            .tabItem {
                Image(systemName: "leaf")
                Text("Plants")
            }
            .tag(1)
            
            NavigationStack {
                BedsListView()
            }
            .tabItem {
                Image(systemName: "square.grid.2x2")
                Text("Beds")
            }
            .tag(2)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(3)
        }
    }
}

struct PlantsView: View {
    @State private var plants: [Plant] = []
    @StateObject private var supabaseService = SupabaseService.shared
    
    var body: some View {
        VStack {
            if !supabaseService.isSignedIn {
                AuthRequiredView()
            } else {
                PlantListView(plants: plants)
            }
        }
        .navigationTitle("Plants")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: PlantDetailsView()) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .task {
            if supabaseService.isSignedIn {
                await loadPlants()
            }
        }
    }
    
    private func loadPlants() async {
        do {
            plants = try await DataService.shared.fetchPlants()
        } catch {
            print("Error loading plants: \(error)")
        }
    }
}



struct PlantListView: View {
    let plants: [Plant]
    
    var body: some View {
        VStack {
            if plants.isEmpty {
                PlantsEmptyState {
                    // This will be handled by the navigation link in the toolbar
                }
            } else {
                List {
                    ForEach(plants) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            HStack(spacing: 12) {
                                Image(systemName: "leaf.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plant.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let scientificName = plant.scientificName, !scientificName.isEmpty {
                                        Text(scientificName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "pencil")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("Add details")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}



// SettingsView is defined in Views/SettingsView.swift

#Preview {
    ContentView()
}