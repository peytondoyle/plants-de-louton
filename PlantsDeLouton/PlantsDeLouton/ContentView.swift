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
            // Handle error appropriately in production
            plants = []
        }
    }
}

struct PlantListView: View {
    let plants: [Plant]
    
    var body: some View {
        List {
            ForEach(plants) { plant in
                NavigationLink(destination: PlantDetailsView()) {
                    VStack(alignment: .leading) {
                        Text(plant.name)
                            .font(.headline)
                        Text(plant.scientificName ?? "No scientific name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}