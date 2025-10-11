import SwiftUI

// CONSOLIDATED SPACES VIEW - Replaces 9 separate files with one cohesive view
// Handles all space, bed, and pin management in a clean, organized way

struct SpacesView: View {
    @StateObject private var api = GardenAPI.shared
    @State private var spaces: [Space] = []
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading spaces...")
                } else if spaces.isEmpty {
                    EmptySpacesView(showingAddSheet: $showingAddSheet)
                } else {
                    SpacesList(spaces: spaces, editMode: $editMode)
                }
            }
            .navigationTitle("Garden Spaces")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        showingAddSheet = true
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddSheet) {
                AddEditSpaceSheet(spaces: $spaces)
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

// MARK: - Empty State
struct EmptySpacesView: View {
    @Binding var showingAddSheet: Bool
    
    var body: some View {
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
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Spaces List
struct SpacesList: View {
    let spaces: [Space]
    @Binding var editMode: EditMode
    
    var body: some View {
        List {
            ForEach(spaces) { space in
                NavigationLink(destination: SpaceDetailView(space: space)) {
                    SpaceRow(space: space)
                }
            }
            .onDelete { indexSet in
                // Handle deletion
            }
            .onMove { source, destination in
                // Handle reordering
            }
        }
    }
}

// MARK: - Space Row
struct SpaceRow: View {
    let space: Space
    
    var body: some View {
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
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Space Detail View (Consolidated beds and pins)
struct SpaceDetailView: View {
    let space: Space
    @StateObject private var api = GardenAPI.shared
    @State private var beds: [Bed] = []
    @State private var selectedBed: Bed?
    @State private var showingAddBed = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Space Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(space.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let description = space.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Beds Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Beds")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Add Bed", systemImage: "plus.circle") {
                            showingAddBed = true
                        }
                        .font(.callout)
                    }
                    .padding(.horizontal)
                    
                    if beds.isEmpty {
                        EmptyBedsView(showingAddBed: $showingAddBed)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(beds) { bed in
                                BedCard(bed: bed, selectedBed: $selectedBed)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddBed) {
            AddEditBedSheet(spaceId: space.id, beds: $beds)
        }
        .sheet(item: $selectedBed) { bed in
            BedDetailSheet(bed: bed)
        }
        .task {
            await loadBeds()
        }
    }
    
    private func loadBeds() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            beds = try await api.loadBeds(forSpace: space.id)
        } catch {
            print("Error loading beds: \(error)")
        }
    }
}

// MARK: - Bed Card
struct BedCard: View {
    let bed: Bed
    @Binding var selectedBed: Bed?
    
    var body: some View {
        Button {
            selectedBed = bed
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.2))
                    .frame(height: 100)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                    )
                
                Text(bed.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(Int(bed.width))x\(Int(bed.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

// MARK: - Empty Beds View
struct EmptyBedsView: View {
    @Binding var showingAddBed: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.dashed")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No beds yet")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Button("Add First Bed") {
                showingAddBed = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Bed Detail Sheet (Handles pins)
struct BedDetailSheet: View {
    let bed: Bed
    @StateObject private var api = GardenAPI.shared
    @State private var pins: [Pin] = []
    @State private var showingAddPin = false
    @State private var selectedPin: Pin?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Bed Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(bed.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Size: \(Int(bed.width)) × \(Int(bed.height))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        if let description = bed.description {
                            Text(description)
                                .font(.body)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Visual Bed Layout
                    BedVisualization(bed: bed, pins: pins, selectedPin: $selectedPin)
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    // Pins List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Plants & Features")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Add", systemImage: "plus.circle") {
                                showingAddPin = true
                            }
                        }
                        
                        if pins.isEmpty {
                            Text("No plants or features added yet")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            ForEach(pins) { pin in
                                PinListItem(pin: pin) {
                                    selectedPin = pin
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddPin) {
                AddEditPinSheet(bedId: bed.id, pins: $pins)
            }
            .sheet(item: $selectedPin) { pin in
                AddEditPinSheet(bedId: bed.id, pins: $pins, editingPin: pin)
            }
        }
        .task {
            await loadPins()
        }
    }
    
    private func loadPins() async {
        do {
            pins = try await api.loadPins(forBed: bed.id)
        } catch {
            print("Error loading pins: \(error)")
        }
    }
}

// MARK: - Bed Visualization
struct BedVisualization: View {
    let bed: Bed
    let pins: [Pin]
    @Binding var selectedPin: Pin?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Bed background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brown.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.brown, lineWidth: 2)
                    )
                
                // Pins
                ForEach(pins) { pin in
                    PinMarker(pin: pin, isSelected: selectedPin?.id == pin.id)
                        .position(
                            x: geometry.size.width * (pin.x / 100),
                            y: geometry.size.height * (pin.y / 100)
                        )
                        .onTapGesture {
                            selectedPin = pin
                        }
                }
            }
        }
    }
}

// MARK: - Pin Marker
struct PinMarker: View {
    let pin: Pin
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(pin.health.color))
                .frame(width: 30, height: 30)
            
            Image(systemName: pin.type.icon)
                .foregroundColor(.white)
                .font(.caption)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Pin List Item
struct PinListItem: View {
    let pin: Pin
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: pin.type.icon)
                    .foregroundColor(Color(pin.health.color))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pin.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        if let sun = pin.sunNeeds {
                            Label(sun.rawValue, systemImage: "sun.max")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let water = pin.waterNeeds {
                            Label(water.rawValue, systemImage: "drop")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
    }
}

// MARK: - Universal Add/Edit Sheet
struct AddEditSpaceSheet: View {
    @Binding var spaces: [Space]
    var editingSpace: Space? = nil
    @Environment(\.dismiss) var dismiss
    @StateObject private var api = GardenAPI.shared
    
    @State private var name = ""
    @State private var description = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Space Details") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(editingSpace == nil ? "New Space" : "Edit Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveSpace()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            if let space = editingSpace {
                name = space.name
                description = space.description ?? ""
            }
        }
    }
    
    private func saveSpace() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            if let editingSpace = editingSpace {
                // Update existing
                var updated = editingSpace
                updated.name = name
                updated.description = description.isEmpty ? nil : description
                _ = try await api.updateSpace(updated)
            } else {
                // Create new
                let newSpace = Space(name: name, description: description.isEmpty ? nil : description)
                let created = try await api.createSpace(newSpace)
                spaces.append(created)
            }
            dismiss()
        } catch {
            print("Error saving space: \(error)")
        }
    }
}

// MARK: - Add/Edit Bed Sheet
struct AddEditBedSheet: View {
    let spaceId: UUID
    @Binding var beds: [Bed]
    var editingBed: Bed? = nil
    @Environment(\.dismiss) var dismiss
    @StateObject private var api = GardenAPI.shared
    
    @State private var name = ""
    @State private var description = ""
    @State private var width: Double = 100
    @State private var height: Double = 100
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Bed Details") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Dimensions") {
                    HStack {
                        Text("Width:")
                        Slider(value: $width, in: 50...500, step: 10)
                        Text("\(Int(width))")
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Height:")
                        Slider(value: $height, in: 50...500, step: 10)
                        Text("\(Int(height))")
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle(editingBed == nil ? "New Bed" : "Edit Bed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveBed()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            if let bed = editingBed {
                name = bed.name
                description = bed.description ?? ""
                width = bed.width
                height = bed.height
            }
        }
    }
    
    private func saveBed() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            if let editingBed = editingBed {
                // Update existing
                var updated = editingBed
                updated.name = name
                updated.description = description.isEmpty ? nil : description
                updated.width = width
                updated.height = height
                _ = try await api.updateBed(updated)
            } else {
                // Create new
                let newBed = Bed(
                    spaceId: spaceId,
                    name: name,
                    description: description.isEmpty ? nil : description,
                    width: width,
                    height: height
                )
                let created = try await api.createBed(newBed)
                beds.append(created)
            }
            dismiss()
        } catch {
            print("Error saving bed: \(error)")
        }
    }
}

// MARK: - Add/Edit Pin Sheet
struct AddEditPinSheet: View {
    let bedId: UUID
    @Binding var pins: [Pin]
    var editingPin: Pin? = nil
    @Environment(\.dismiss) var dismiss
    @StateObject private var api = GardenAPI.shared
    
    @State private var name = ""
    @State private var type: PlantType = .plant
    @State private var health: PlantHealth = .healthy
    @State private var notes = ""
    @State private var sunNeeds: SunLevel = .partial
    @State private var waterNeeds: WaterLevel = .medium
    @State private var x: Double = 50
    @State private var y: Double = 50
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach([PlantType.plant, .vegetable, .herb, .flower], id: \.self) { type in
                            Label(type.rawValue.capitalized, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    Picker("Health", selection: $health) {
                        ForEach([PlantHealth.healthy, .needsWater, .needsSun, .diseased], id: \.self) { health in
                            Text(health.displayName)
                                .tag(health)
                        }
                    }
                }
                
                if type == .plant {
                    Section("Care Needs") {
                        Picker("Sun", selection: $sunNeeds) {
                            ForEach([SunLevel.full, .partial, .shade], id: \.self) { level in
                                Text(level.displayName)
                                    .tag(level)
                            }
                        }
                        
                        Picker("Water", selection: $waterNeeds) {
                            ForEach([WaterLevel.low, .medium, .high], id: \.self) { level in
                                Text(level.displayName)
                                    .tag(level)
                            }
                        }
                    }
                }
                
                Section("Position") {
                    HStack {
                        Text("X Position:")
                        Slider(value: $x, in: 0...100)
                        Text("\(Int(x))%")
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Y Position:")
                        Slider(value: $y, in: 0...100)
                        Text("\(Int(y))%")
                            .monospacedDigit()
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(editingPin == nil ? "Add \(type.rawValue.capitalized)" : "Edit \(type.rawValue.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await savePin()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            if let pin = editingPin {
                name = pin.name
                type = pin.type
                health = pin.health
                notes = pin.notes ?? ""
                sunNeeds = pin.sunNeeds ?? .partial
                waterNeeds = pin.waterNeeds ?? .medium
                x = pin.x
                y = pin.y
            }
        }
    }
    
    private func savePin() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            if let editingPin = editingPin {
                // Update existing
                var updated = editingPin
                updated.name = name
                updated.type = type
                updated.health = health
                updated.notes = notes.isEmpty ? nil : notes
                updated.sunNeeds = type == .plant ? sunNeeds : nil
                updated.waterNeeds = type == .plant ? waterNeeds : nil
                updated.x = x
                updated.y = y
                _ = try await api.updatePin(updated)
                
                // Update local array
                if let index = pins.firstIndex(where: { $0.id == editingPin.id }) {
                    pins[index] = updated
                }
            } else {
                // Create new
                let newPin = Pin(
                    bedId: bedId,
                    name: name,
                    type: type,
                    health: health,
                    x: x,
                    y: y,
                    notes: notes.isEmpty ? nil : notes,
                    sunNeeds: type == .plant ? sunNeeds : nil,
                    waterNeeds: type == .plant ? waterNeeds : nil
                )
                let created = try await api.createPin(newPin)
                pins.append(created)
            }
            dismiss()
        } catch {
            print("Error saving pin: \(error)")
        }
    }
}

#Preview {
    SpacesView()
}