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
                Image(systemName: "tree")
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
        VStack(spacing: 20) {
            Text("Manage your plants")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            NavigationLink(destination: PlantDetailsView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Add New Plant")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
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