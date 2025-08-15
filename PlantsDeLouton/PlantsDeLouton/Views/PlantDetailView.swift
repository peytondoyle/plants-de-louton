import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    @StateObject private var viewModel = PlantDetailViewModel()
    @State private var showingEditSheet = false
    @State private var showingAddCareEvent = false
    @State private var activeTab = 0
    @State private var showingPhotoPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Enhanced Header with plant info
                EnhancedPlantHeaderView(plant: plant, plantInfo: viewModel.plantInfo)
                
                // Quick Actions Bar
                QuickActionsBar(
                    onEdit: { showingEditSheet = true },
                    onAddCare: { showingAddCareEvent = true },
                    onAddPhoto: { showingPhotoPicker = true }
                )
                
                // Tab Navigation
                EnhancedTabNavigationView(activeTab: $activeTab)
                
                // Tab Content
                TabView(selection: $activeTab) {
                    // Enhanced Plant Details Tab
                    EnhancedPlantDetailsTabView(
                        plant: plant,
                        plantInfo: viewModel.plantInfo,
                        onEdit: { showingEditSheet = true }
                    )
                    .tag(0)
                    
                    // Enhanced Care History Tab
                    EnhancedCareHistoryTabView(
                        plant: plant,
                        careEvents: viewModel.careEvents,
                        onAddEvent: { showingAddCareEvent = true }
                    )
                    .tag(1)
                    
                    // Enhanced Photos Tab
                    EnhancedPhotosTabView(plant: plant)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit Plant", systemImage: "pencil")
                    }
                    Button(action: { showingAddCareEvent = true }) {
                        Label("Add Care Event", systemImage: "plus.circle")
                    }
                    Button(action: { showingPhotoPicker = true }) {
                        Label("Add Photo", systemImage: "camera")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
        .sheet(isPresented: $showingPhotoPicker) {
            // TODO: Implement photo picker
            Text("Photo picker coming soon")
        }
        .task {
            await viewModel.loadPlantData(for: plant)
        }
    }
}

// MARK: - Enhanced Plant Header View
struct EnhancedPlantHeaderView: View {
    let plant: Plant
    let plantInfo: PlantInfo?
    
    var body: some View {
        VStack(spacing: 20) {
            // Plant Icon and Name with gradient background
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.2), .mint.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 4) {
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
            }
            
            // Enhanced Quick Info Grid
            if let info = plantInfo {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    EnhancedQuickInfoCard(
                        icon: "sun.max.fill",
                        title: "Sun",
                        value: info.sunExposure ?? "Unknown",
                        color: .orange
                    )
                    
                    EnhancedQuickInfoCard(
                        icon: "drop.fill",
                        title: "Water",
                        value: info.waterNeeds ?? "Unknown",
                        color: .blue
                    )
                    
                    EnhancedQuickInfoCard(
                        icon: "ruler.fill",
                        title: "Size",
                        value: info.matureHeight ?? "Unknown",
                        color: .green
                    )
                }
            }
            
            // Plant Status Card
            PlantStatusCard(plant: plant, plantInfo: plantInfo)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Enhanced Quick Info Card
struct EnhancedQuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Plant Status Card
struct PlantStatusCard: View {
    let plant: Plant
    let plantInfo: PlantInfo?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Plant Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatusItem(
                    icon: "calendar",
                    title: "Created",
                    value: plant.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
                )
                
                Divider()
                
                StatusItem(
                    icon: "location.fill",
                    title: "Location",
                    value: "Bed \(plant.bedId.uuidString.prefix(8))"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Status Item
struct StatusItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Actions Bar
struct QuickActionsBar: View {
    let onEdit: () -> Void
    let onAddCare: () -> Void
    let onAddPhoto: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "pencil",
                title: "Edit",
                color: .blue,
                action: onEdit
            )
            
            QuickActionButton(
                icon: "plus.circle",
                title: "Care",
                color: .green,
                action: onAddCare
            )
            
            QuickActionButton(
                icon: "camera",
                title: "Photo",
                color: .orange,
                action: onAddPhoto
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Tab Navigation
struct EnhancedTabNavigationView: View {
    @Binding var activeTab: Int
    
    private let tabs = [
        ("Details", "info.circle"),
        ("Care", "heart.fill"),
        ("Photos", "photo.on.rectangle")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tabs[index].1)
                            .font(.system(size: 16))
                            .foregroundColor(activeTab == index ? .green : .secondary)
                        
                        Text(tabs[index].0)
                            .font(.caption)
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
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Enhanced Plant Details Tab
struct EnhancedPlantDetailsTabView: View {
    let plant: Plant
    let plantInfo: PlantInfo?
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // AI Success Card (if we have AI data)
            if let info = plantInfo {
                EnhancedAISuccessCard(plantInfo: info)
            }
            
            // Plant Information
            VStack(spacing: 16) {
                SectionHeader(title: "Plant Information", action: onEdit)
                
                VStack(spacing: 12) {
                    EnhancedInfoRow(title: "Name", value: plant.name, icon: "leaf.fill")
                    if let scientificName = plant.scientificName, !scientificName.isEmpty {
                        EnhancedInfoRow(title: "Scientific Name", value: scientificName, icon: "textformat.abc")
                    }
                    if let growthHabit = plant.growthHabit, !growthHabit.isEmpty {
                        EnhancedInfoRow(title: "Growth Habit", value: growthHabit, icon: "arrow.up.right")
                    }
                    if let sunExposure = plant.sunExposure, !sunExposure.isEmpty {
                        EnhancedInfoRow(title: "Sun Exposure", value: sunExposure, icon: "sun.max.fill")
                    }
                    if let waterNeeds = plant.waterNeeds, !waterNeeds.isEmpty {
                        EnhancedInfoRow(title: "Water Needs", value: waterNeeds, icon: "drop.fill")
                    }
                    if let notes = plant.notes, !notes.isEmpty {
                        EnhancedInfoRow(title: "Notes", value: notes, icon: "note.text")
                    }
                }
            }
            
            // Plant Instance Details
            VStack(spacing: 16) {
                SectionHeader(title: "This Plant Instance")
                
                VStack(spacing: 12) {
                    EnhancedInfoRow(title: "Location", value: "Bed \(plant.bedId.uuidString.prefix(8))", icon: "location.fill")
                    EnhancedInfoRow(title: "Position", value: "X: \(String(format: "%.1f", plant.x)), Y: \(String(format: "%.1f", plant.y))", icon: "crosshairs")
                    EnhancedInfoRow(title: "Created", value: plant.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown", icon: "calendar")
                }
            }
        }
        .padding()
    }
}

// MARK: - Enhanced AI Success Card
struct EnhancedAISuccessCard: View {
    let plantInfo: PlantInfo
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Plant Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Powered by intelligent plant recognition")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let description = plantInfo.description {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let careInstructions = plantInfo.careInstructions {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Care Instructions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(careInstructions)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Enhanced Info Row
struct EnhancedInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enhanced Care History Tab
struct EnhancedCareHistoryTabView: View {
    let plant: Plant
    let careEvents: [CareEvent]
    let onAddEvent: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with stats
            VStack(spacing: 12) {
                HStack {
                    Text("Care History")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: onAddEvent) {
                        Label("Add Event", systemImage: "plus")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Care Stats
                if !careEvents.isEmpty {
                    CareStatsView(careEvents: careEvents)
                }
            }
            .padding(.horizontal)
            
            // Care Events List
            if careEvents.isEmpty {
                EnhancedEmptyCareEventsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(careEvents) { event in
                        EnhancedCareEventCard(event: event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Care Stats View
struct CareStatsView: View {
    let careEvents: [CareEvent]
    
    private var totalEvents: Int { careEvents.count }
    private var lastEventDate: Date? { careEvents.first?.eventDate }
    private var wateringCount: Int { careEvents.filter { $0.eventType == "watering" }.count }
    
    var body: some View {
        HStack(spacing: 16) {
            CareStatCard(title: "Total Events", value: "\(totalEvents)", icon: "list.bullet")
            CareStatCard(title: "Waterings", value: "\(wateringCount)", icon: "drop.fill")
            CareStatCard(title: "Last Event", value: lastEventDate?.formatted(date: .abbreviated, time: .omitted) ?? "None", icon: "calendar")
        }
    }
}

// MARK: - Care Stat Card
struct CareStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.green)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Enhanced Empty Care Events View
struct EnhancedEmptyCareEventsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("No care events yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Start tracking your plant's care routine by adding your first event")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Enhanced Care Event Card
struct EnhancedCareEventCard: View {
    let event: CareEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(eventTypeColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: eventTypeIcon)
                        .font(.caption)
                        .foregroundColor(eventTypeColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.eventType.capitalized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let cost = event.cost {
                    Text("$\(cost, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            Text(event.description)
                .font(.body)
            
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
    
    private var eventTypeColor: Color {
        switch event.eventType {
        case "watering": return .blue
        case "fertilizing": return .green
        case "pruning": return .orange
        case "pest_treatment": return .red
        case "disease_treatment": return .purple
        case "transplanting": return .mint
        case "harvesting": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Enhanced Photos Tab
struct EnhancedPhotosTabView: View {
    let plant: Plant
    
    var body: some View {
        VStack(spacing: 20) {
            // Photo Gallery Placeholder
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No photos yet")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("Add photos to track your plant's growth and health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal)
            
            // Photo Actions
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Implement photo picker
                }) {
                    Label("Add Photo", systemImage: "camera")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // TODO: Implement camera
                }) {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
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
                .fontWeight(.semibold)
            Spacer()
            if let action = action {
                Button("Edit", action: action)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Add Care Event View (keeping existing implementation)
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
