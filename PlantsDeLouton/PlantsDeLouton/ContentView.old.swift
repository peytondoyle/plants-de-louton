// New simplified tab navigation - replace ContentView.swift with this!
// Clean, focused on what matters

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Garden Overview Tab
            NavigationStack {
                VStack(spacing: 20) {
                    Text("🌱 Garden Overview")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                            Text("Total Plants: 0")
                                .font(.headline)
                        }
                        
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("Watering Due: 0")
                                .font(.headline)
                        }
                        
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.orange)
                            Text("Sunlight Issues: 0")
                                .font(.headline)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Garden")
            }
            .tabItem {
                Image(systemName: "leaf.fill")
                Text("Garden")
            }
            
            // Spaces Tab
            SpacesView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Spaces")
                }
            
            // All Plants Tab
            AllPlantsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Plants")
                }
            
            // Care Tasks Tab
            CareTasksView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Care")
                }
            
            // More Tab
            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis.circle")
                    Text("More")
                }
        }
    }
}

// MARK: - Placeholder Views (implement as needed)
struct AllPlantsView: View {
    @State private var pins: [Pin] = []
    
    var body: some View {
        NavigationStack {
            List(pins) { pin in
                HStack {
                    Image(systemName: pin.type.icon)
                        .foregroundColor(Color(pin.health.color))
                    
                    VStack(alignment: .leading) {
                        Text(pin.name)
                            .font(.headline)
                        
                        if pin.type == .plant {
                            HStack(spacing: 12) {
                                if let sun = pin.sunNeeds {
                                    Label("\(sun)", systemImage: "sun.max")
                                        .font(.caption)
                                }
                                
                                if let water = pin.waterNeeds {
                                    Label("\(water)", systemImage: "drop")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text(pin.health.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(pin.health.color).opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .navigationTitle("All Plants")
        }
    }
}

struct CareTasksView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🌿 Care Tasks")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("Water All Plants")
                        Spacer()
                        Button("Water") {
                            // Water all plants
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Image(systemName: "scissors")
                            .foregroundColor(.green)
                        Text("Prune Overgrown Plants")
                        Spacer()
                        Button("Prune") {
                            // Prune plants
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.orange)
                        Text("Fertilize Monthly")
                        Spacer()
                        Button("Fertilize") {
                            // Fertilize plants
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Care Tasks")
        }
    }
}

#Preview {
    ContentView()
}
