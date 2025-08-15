import SwiftUI
import PhotosUI

struct BedDetailView: View {
    let bed: Bed
    @StateObject private var viewModel: BedImageViewModel
    @State private var showingImagePicker = false
    @State private var showingPinEditor = false
    @State private var showingPinCreator = false
    @State private var selectedPin: Plant?
    @State private var newPinPosition: CGPoint?
    @StateObject private var supabaseService = SupabaseService.shared
    
    init(bed: Bed) {
        self.bed = bed
        self._viewModel = StateObject(wrappedValue: BedImageViewModel(bed: bed))
    }
    
    var body: some View {
        Group {
            if !supabaseService.isSignedIn {
                AuthRequiredView()
            } else {
                VStack(spacing: 0) {
                    // Main image area
                    GeometryReader { geometry in
                        ZStack {
                            // Background
                            Color(.systemGray6)
                            
                            if let image = viewModel.selectedImage {
                                // Image with pins overlay
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .onTapGesture { location in
                                        handleImageTap(at: location, in: geometry)
                                    }
                                    .overlay(
                                        // Pins overlay
                                        ForEach(viewModel.plants) { plant in
                                            PinView(plant: plant) {
                                                selectedPin = plant
                                                showingPinEditor = true
                                            }
                                            .position(
                                                x: plant.x * geometry.size.width,
                                                y: plant.y * geometry.size.height
                                            )
                                        }
                                    )
                            } else {
                                // Loading or placeholder state
                                VStack(spacing: 16) {
                                    if viewModel.isImageLoading {
                                        ProgressView("Loading image...")
                                            .scaleEffect(1.2)
                                    } else {
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                        
                                        Text("No image available")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        
                                        Button("Add Image") {
                                            showingImagePicker = true
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    
                                    if let error = viewModel.errorMessage {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    
                    // Pin list - web app style
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            Text("Plants in this Bed")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(viewModel.plants.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        
                        // Pin list
                        if viewModel.plants.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                Text("No plants yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Tap on the image above to add your first plant")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.plants) { plant in
                                        PinListItem(plant: plant) {
                                            selectedPin = plant
                                            showingPinEditor = true
                                        }
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                }
                .navigationTitle(bed.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add Image") {
                            showingImagePicker = true
                        }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(selectedImage: Binding(
                        get: { viewModel.selectedImage },
                        set: { newImage in
                            if let image = newImage {
                                Task {
                                    await viewModel.saveImage(image)
                                }
                            }
                        }
                    ))
                }
                .sheet(isPresented: $showingPinEditor) {
                    if let pin = selectedPin {
                        PinEditorView(plant: pin, viewModel: viewModel)
                    }
                }
                .sheet(isPresented: $showingPinCreator) {
                    if let position = newPinPosition {
                        PinCreatorView(position: position, viewModel: viewModel)
                    }
                }
                .task {
                    if supabaseService.isSignedIn {
                        await viewModel.loadPlants()
                        await viewModel.loadImage()
                    }
                }
                .onChange(of: supabaseService.isSignedIn) { oldValue, newValue in
                    if newValue {
                        Task { 
                            await viewModel.loadPlants()
                            await viewModel.loadImage()
                        }
                    }
                }
            }
        }
    }
    
    private func handleImageTap(at location: CGPoint, in geometry: GeometryProxy) {
        guard viewModel.selectedImage != nil else { return }
        
        // Convert tap location to relative coordinates (0-1)
        let relativeX = location.x / geometry.size.width
        let relativeY = location.y / geometry.size.height
        
        // Clamp coordinates to 0-1 range
        let clampedX = max(0, min(1, relativeX))
        let clampedY = max(0, min(1, relativeY))
        
        // Check if tap is on an existing pin
        for plant in viewModel.plants {
            let pinX = plant.x * geometry.size.width
            let pinY = plant.y * geometry.size.height
            let distance = sqrt(pow(location.x - pinX, 2) + pow(location.y - pinY, 2))
            
            if distance < 30 { // 30pt touch radius
                selectedPin = plant
                showingPinEditor = true
                return
            }
        }
        
        // Create new pin at tap location
        newPinPosition = CGPoint(x: clampedX, y: clampedY)
        showingPinCreator = true
    }
}

// MARK: - Pin View
struct PinView: View {
    let plant: Plant
    let onTap: () -> Void
    
    private var pinColor: Color {
        let colors: [Color] = [
            .green, .blue, .orange, .purple, .pink, 
            .yellow, .red, .mint, .indigo, .teal
        ]
        let index = abs(plant.name.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 20, height: 20)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pin List Item
struct PinListItem: View {
    let plant: Plant
    let onTap: () -> Void
    
    private var pinColor: Color {
        let colors: [Color] = [
            .green, .blue, .orange, .purple, .pink, 
            .yellow, .red, .mint, .indigo, .teal
        ]
        let index = abs(plant.name.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(pinColor)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let notes = plant.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 44)
    }
}

// MARK: - Pin Creator View
struct PinCreatorView: View {
    let position: CGPoint
    let viewModel: BedImageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var plantName = ""
    @State private var plantNotes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Plant Details") {
                    TextField("Plant name", text: $plantName)
                    TextField("Notes (optional)", text: $plantNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Plant")
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
                            await viewModel.addPlant(at: position, name: plantName, notes: plantNotes.isEmpty ? nil : plantNotes)
                            dismiss()
                        }
                    }
                    .disabled(plantName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Pin Editor View
struct PinEditorView: View {
    let plant: Plant
    let viewModel: BedImageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var plantName: String
    @State private var plantNotes: String
    
    init(plant: Plant, viewModel: BedImageViewModel) {
        self.plant = plant
        self.viewModel = viewModel
        self._plantName = State(initialValue: plant.name)
        self._plantNotes = State(initialValue: plant.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Plant Details") {
                    TextField("Plant name", text: $plantName)
                    TextField("Notes (optional)", text: $plantNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Delete Plant", role: .destructive) {
                        Task {
                            await viewModel.deletePlant(plant.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Edit Plant")
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
                            var updatedPlant = plant
                            updatedPlant.name = plantName
                            updatedPlant.notes = plantNotes.isEmpty ? nil : plantNotes
                            await viewModel.updatePlant(updatedPlant)
                            dismiss()
                        }
                    }
                    .disabled(plantName.isEmpty)
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        BedDetailView(bed: Bed(
            name: "Test Bed",
            section: "Back yard"
        ))
    }
}


