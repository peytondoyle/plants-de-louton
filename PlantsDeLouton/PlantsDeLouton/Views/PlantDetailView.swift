import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    @StateObject private var viewModel = PlantDetailViewModel()
    @State private var showingEditSheet = false
    @State private var showingAddCareEvent = false
    @State private var activeTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with plant info
                PlantHeaderView(plant: plant, plantInfo: viewModel.plantInfo)
                
                // Tab Navigation
                TabNavigationView(activeTab: $activeTab)
                
                // Tab Content
                TabView(selection: $activeTab) {
                    // Plant Details Tab
                    PlantDetailsTabView(
                        plant: plant,
                        plantInfo: viewModel.plantInfo,
                        onEdit: { showingEditSheet = true }
                    )
                    .tag(0)
                    
                    // Care History Tab
                    CareHistoryTabView(
                        plant: plant,
                        careEvents: viewModel.careEvents,
                        onAddEvent: { showingAddCareEvent = true }
                    )
                    .tag(1)
                    
                    // Photos Tab
                    PhotosTabView(plant: plant)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                PlantDetailsView()
                    .navigationTitle("Edit Plant")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingEditSheet = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingAddCareEvent) {
            NavigationView {
                AddCareEventView(plant: plant) { event in
                    viewModel.addCareEvent(event)
                    showingAddCareEvent = false
                }
                .navigationTitle("Add Care Event")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showingAddCareEvent = false
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadPlantData(for: plant)
        }
    }
}

// MARK: - Plant Header View
struct PlantHeaderView: View {
    let plant: Plant
    let plantInfo: PlantInfo?
    
    var body: some View {
        VStack(spacing: 16) {
            // Plant Icon and Name
            VStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(plant.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let scientificName = plant.scientificName, !scientificName.isEmpty {
                    Text(scientificName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Quick Info Grid
            if let info = plantInfo {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    QuickInfoCard(
                        icon: "sun.max.fill",
                        title: "Sun",
                        value: info.sunExposure ?? "Unknown"
                    )
                    
                    QuickInfoCard(
                        icon: "drop.fill",
                        title: "Water",
                        value: info.waterNeeds ?? "Unknown"
                    )
                    
                    QuickInfoCard(
                        icon: "ruler.fill",
                        title: "Size",
                        value: info.matureHeight ?? "Unknown"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Quick Info Card
struct QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Tab Navigation
struct TabNavigationView: View {
    @Binding var activeTab: Int
    
    private let tabs = ["Details", "Care", "Photos"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tabs[index])
                            .font(.subheadline)
                            .fontWeight(activeTab == index ? .semibold : .medium)
                            .foregroundColor(activeTab == index ? .primary : .secondary)
                        
                        Rectangle()
                            .fill(activeTab == index ? Color.green : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

// MARK: - Plant Details Tab
struct PlantDetailsTabView: View {
    let plant: Plant
    let plantInfo: PlantInfo?
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // AI Success Card (if we have AI data)
            if let info = plantInfo {
                AISuccessCard(plantInfo: info)
            }
            
            // Plant Information
            VStack(spacing: 16) {
                SectionHeader(title: "Plant Information", action: onEdit)
                
                VStack(spacing: 12) {
                    InfoRow(title: "Name", value: plant.name)
                    if let scientificName = plant.scientificName, !scientificName.isEmpty {
                        InfoRow(title: "Scientific Name", value: scientificName)
                    }
                    if let growthHabit = plant.growthHabit, !growthHabit.isEmpty {
                        InfoRow(title: "Growth Habit", value: growthHabit)
                    }
                    if let sunExposure = plant.sunExposure, !sunExposure.isEmpty {
                        InfoRow(title: "Sun Exposure", value: sunExposure)
                    }
                    if let waterNeeds = plant.waterNeeds, !waterNeeds.isEmpty {
                        InfoRow(title: "Water Needs", value: waterNeeds)
                    }
                    if let notes = plant.notes, !notes.isEmpty {
                        InfoRow(title: "Notes", value: notes)
                    }
                }
            }
            
            // Plant Instance Details
            VStack(spacing: 16) {
                SectionHeader(title: "This Plant Instance")
                
                VStack(spacing: 12) {
                    InfoRow(title: "Location", value: "Bed \(plant.bedId.uuidString.prefix(8))")
                    InfoRow(title: "Position", value: "X: \(String(format: "%.1f", plant.x)), Y: \(String(format: "%.1f", plant.y))")
                    InfoRow(title: "Created", value: plant.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                }
            }
        }
        .padding()
    }
}

// MARK: - Care History Tab
struct CareHistoryTabView: View {
    let plant: Plant
    let careEvents: [CareEvent]
    let onAddEvent: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Care Events")
                    .font(.headline)
                Spacer()
                Button(action: onAddEvent) {
                    Label("Add Event", systemImage: "plus")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            // Care Events List
            if careEvents.isEmpty {
                EmptyCareEventsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(careEvents) { event in
                        CareEventCard(event: event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Empty Care Events View
struct EmptyCareEventsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No care events yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add your first care event to start tracking plant health")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Care Event Card
struct CareEventCard: View {
    let event: CareEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: eventTypeIcon)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text(event.eventType.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(event.description)
                .font(.body)
            
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let cost = event.cost {
                Text("Cost: $\(cost, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var eventTypeIcon: String {
        switch event.eventType {
        case "watering": return "drop.fill"
        case "fertilizing": return "leaf.fill"
        case "pruning": return "scissors"
        case "pest_treatment": return "ant.fill"
        case "disease_treatment": return "cross.fill"
        case "transplanting": return "arrow.triangle.2.circlepath"
        case "harvesting": return "hand.raised.fill"
        default: return "note.text"
        }
    }
}

// MARK: - Photos Tab
struct PhotosTabView: View {
    let plant: Plant
    
    var body: some View {
        VStack(spacing: 16) {
            // Placeholder for photos
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("No photos yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Add photos to track your plant's growth")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - Helper Views
struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    
    init(title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            if let action = action {
                Button("Edit", action: action)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Care Event View
struct AddCareEventView: View {
    let plant: Plant
    let onSave: (CareEvent) -> Void
    
    @State private var eventType = "watering"
    @State private var eventDate = Date()
    @State private var description = ""
    @State private var notes = ""
    @State private var cost: Double?
    @State private var showingCostInput = false
    
    private let eventTypes = [
        "watering", "fertilizing", "pruning", "pest_treatment",
        "disease_treatment", "transplanting", "harvesting", "other"
    ]
    
    var body: some View {
        Form {
            Section("Event Details") {
                Picker("Event Type", selection: $eventType) {
                    ForEach(eventTypes, id: \.self) { type in
                        Text(type.capitalized).tag(type)
                    }
                }
                
                DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                
                TextField("Description", text: $description)
                
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Cost (Optional)") {
                Toggle("Add Cost", isOn: $showingCostInput)
                
                if showingCostInput {
                    HStack {
                        Text("$")
                        TextField("0.00", value: $cost, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }
        }
        .navigationTitle("Add Care Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveEvent()
                }
                .disabled(description.isEmpty)
            }
        }
    }
    
    private func saveEvent() {
        let event = CareEvent(
            id: UUID(),
            plantId: plant.id,
            eventType: eventType,
            eventDate: eventDate,
            description: description,
            notes: notes.isEmpty ? nil : notes,
            cost: cost,
            createdAt: Date(),
            updatedAt: Date()
        )
        onSave(event)
    }
}

#Preview {
    NavigationView {
        PlantDetailView(plant: Plant(
            name: "Tomato",
            bedId: UUID(),
            x: 0.5,
            y: 0.5,
            scientificName: "Solanum lycopersicum",
            growthHabit: "Annual",
            sunExposure: "Full Sun",
            waterNeeds: "Moderate",
            notes: "Planted in spring"
        ))
    }
}
