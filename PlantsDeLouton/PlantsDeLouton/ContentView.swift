import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GardenOverviewView()
            }
            .tabItem {
                Image(systemName: "leaf.fill")
                Text("Garden")
            }
            .tag(0)
            
            NavigationStack {
                PlantsView()
            }
            .tabItem {
                Image(systemName: "plant.fill")
                Text("Plants")
            }
            .tag(1)
            
            NavigationStack {
                CareView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Care")
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
    var body: some View {
        Text("Plants List")
            .navigationTitle("Plants")
    }
}

struct CareView: View {
    var body: some View {
        Text("Care Schedule")
            .navigationTitle("Care")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .navigationTitle("Settings")
    }
}

#Preview {
    ContentView()
}