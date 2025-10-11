import SwiftUI

// SIMPLIFIED CONTENT VIEW - Clean tab navigation without mixed implementations
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Garden Overview - Quick stats and overview
            GardenOverviewTab()
                .tabItem {
                    Label("Garden", systemImage: "leaf.fill")
                }
                .tag(0)
            
            // Spaces - Main garden management
            SpacesView()
                .tabItem {
                    Label("Spaces", systemImage: "square.grid.2x2")
                }
                .tag(1)
            
            // Plants - All plants list
            AllPlantsTab()
                .tabItem {
                    Label("Plants", systemImage: "list.bullet")
                }
                .tag(2)
            
            // Care - Tasks and reminders
            CareTasksTab()
                .tabItem {
                    Label("Care", systemImage: "heart.fill")
                }
                .tag(3)
            
            // Settings
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
    }
}

// MARK: - Garden Overview Tab
struct GardenOverviewTab: View {
    @StateObject private var api = GardenAPI.shared
    @State private var plantCount = 0
    @State private var spaceCount = 0
    @State private var healthyCount = 0
    @State private var needsAttentionCount = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Here's your garden at a glance")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Plants",
                            value: "\(plantCount)",
                            icon: "leaf.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Garden Spaces",
                            value: "\(spaceCount)",
                            icon: "square.grid.2x2",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Healthy",
                            value: "\(healthyCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Needs Care",
                            value: "\(needsAttentionCount)",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            QuickActionButton(
                                title: "Add New Plant",
                                icon: "plus.circle.fill",
                                color: .green
                            ) {
                                // Navigate to add plant
                            }
                            
                            QuickActionButton(
                                title: "Water All Plants",
                                icon: "drop.fill",
                                color: .blue
                            ) {
                                // Water action
                            }
                            
                            QuickActionButton(
                                title: "View Care Schedule",
                                icon: "calendar",
                                color: .purple
                            ) {
                                // Navigate to care
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ActivityRow(text: "Watered tomatoes", time: "2 hours ago", icon: "drop.fill")
                            ActivityRow(text: "Added new basil plant", time: "Yesterday", icon: "leaf.fill")
                            ActivityRow(text: "Fertilized herb garden", time: "3 days ago", icon: "sparkles")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Garden")
            .task {
                await loadStats()
            }
        }
    }
    
    private func loadStats() async {
        // Load statistics from API
        do {
            let spaces = try await api.loadSpaces()
            spaceCount = spaces.count
            
            // Load all pins to count plants
            var allPins: [Pin] = []
            for space in spaces {
                let beds = try await api.loadBeds(forSpace: space.id)
                for bed in beds {
                    let pins = try await api.loadPins(forBed: bed.id)
                    allPins.append(contentsOf: pins)
                }
            }
            
            plantCount = allPins.filter { $0.type == .plant }.count
            healthyCount = allPins.filter { $0.health == .healthy }.count
            needsAttentionCount = allPins.filter { $0.health != .healthy }.count
        } catch {
            print("Error loading stats: \(error)")
        }
    }
}

// MARK: - All Plants Tab
struct AllPlantsTab: View {
    @StateObject private var api = GardenAPI.shared
    @State private var allPlants: [(plant: Pin, bedName: String, spaceName: String)] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    var filteredPlants: [(plant: Pin, bedName: String, spaceName: String)] {
        if searchText.isEmpty {
            return allPlants
        }
        return allPlants.filter { 
            $0.plant.name.localizedCaseInsensitiveContains(searchText) ||
            $0.spaceName.localizedCaseInsensitiveContains(searchText) ||
            $0.bedName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading plants...")
                } else if allPlants.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "leaf")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Plants Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add plants to your garden spaces to see them here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredPlants, id: \.plant.id) { item in
                            PlantRow(
                                plant: item.plant,
                                location: "\(item.spaceName) › \(item.bedName)"
                            )
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search plants")
                }
            }
            .navigationTitle("All Plants")
            .task {
                await loadAllPlants()
            }
            .refreshable {
                await loadAllPlants()
            }
        }
    }
    
    private func loadAllPlants() async {
        isLoading = true
        defer { isLoading = false }
        
        var plants: [(plant: Pin, bedName: String, spaceName: String)] = []
        
        do {
            let spaces = try await api.loadSpaces()
            
            for space in spaces {
                let beds = try await api.loadBeds(forSpace: space.id)
                
                for bed in beds {
                    let pins = try await api.loadPins(forBed: bed.id)
                    let plantPins = pins.filter { $0.type == .plant }
                    
                    for pin in plantPins {
                        plants.append((plant: pin, bedName: bed.name, spaceName: space.name))
                    }
                }
            }
            
            allPlants = plants.sorted { $0.plant.name < $1.plant.name }
        } catch {
            print("Error loading plants: \(error)")
        }
    }
}

// MARK: - Care Tasks Tab
struct CareTasksTab: View {
    @State private var todayTasks: [CareTask] = []
    @State private var upcomingTasks: [CareTask] = []
    @State private var completedTasks: [CareTask] = []
    
    var body: some View {
        NavigationStack {
            List {
                // Today's Tasks
                Section("Today") {
                    if todayTasks.isEmpty {
                        Text("No tasks for today")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(todayTasks) { task in
                            CareTaskRow(task: task)
                        }
                    }
                }
                
                // Upcoming Tasks
                Section("Upcoming") {
                    if upcomingTasks.isEmpty {
                        Text("No upcoming tasks")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(upcomingTasks) { task in
                            CareTaskRow(task: task)
                        }
                    }
                }
                
                // Completed Tasks
                if !completedTasks.isEmpty {
                    Section("Completed") {
                        ForEach(completedTasks) { task in
                            CareTaskRow(task: task)
                                .opacity(0.6)
                        }
                    }
                }
            }
            .navigationTitle("Care Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task", systemImage: "plus") {
                        // Add new task
                    }
                }
            }
        }
    }
}

// MARK: - Settings Tab
struct SettingsTab: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("measurementUnit") private var measurementUnit = "metric"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Text("Notification settings can be configured in iOS Settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Preferences") {
                    Picker("Measurement Unit", selection: $measurementUnit) {
                        Text("Metric").tag("metric")
                        Text("Imperial").tag("imperial")
                    }
                }
                
                Section("Data") {
                    Button("Export Garden Data") {
                        // Export data
                    }
                    
                    Button("Backup to iCloud") {
                        // Backup data
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        // Sign out
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct ActivityRow: View {
    let text: String
    let time: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.callout)
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PlantRow: View {
    let plant: Pin
    let location: String
    
    var body: some View {
        HStack {
            Image(systemName: plant.type.icon)
                .foregroundColor(Color(plant.health.color))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                
                Text(location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    if let sun = plant.sunNeeds {
                        Label(sun.rawValue, systemImage: "sun.max")
                            .font(.caption2)
                    }
                    
                    if let water = plant.waterNeeds {
                        Label(water.rawValue, systemImage: "drop")
                            .font(.caption2)
                    }
                }
            }
            
            Spacer()
            
            Text(plant.health.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(plant.health.color).opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Care Task Model
struct CareTask: Identifiable {
    let id = UUID()
    var title: String
    var plantName: String
    var dueDate: Date
    var isCompleted: Bool
    var type: CareType
    
    enum CareType {
        case water, fertilize, prune, repot
        
        var icon: String {
            switch self {
            case .water: return "drop.fill"
            case .fertilize: return "leaf.fill"
            case .prune: return "scissors"
            case .repot: return "arrow.up.and.down.square"
            }
        }
        
        var color: Color {
            switch self {
            case .water: return .blue
            case .fertilize: return .green
            case .prune: return .orange
            case .repot: return .purple
            }
        }
    }
}

struct CareTaskRow: View {
    let task: CareTask
    
    var body: some View {
        HStack {
            Image(systemName: task.type.icon)
                .foregroundColor(task.type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                Text(task.plantName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Text(task.dueDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}