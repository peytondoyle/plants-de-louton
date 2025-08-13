import SwiftUI
import PhotosUI

struct PlantSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIPlantSearchService.shared
    @State private var searchText = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var identifiedPlant: AIPlantSearchResult?
    @State private var plantHealth: PlantHealthAnalysis?
    @State private var isAnalyzingHealth = false
    @State private var showingHealthAnalysis = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Find Your Plant")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Done") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    
                    // Camera and Search Options
                    HStack(spacing: 12) {
                        // Camera Button
                        Button(action: {
                            showingCamera = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("Take Photo")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.blue)
                            )
                        }
                        
                        // Photo Library Button
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("Choose Photo")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green)
                            )
                        }
                    }
                    
                    // Search Text Field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search for plants...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .padding(.top, 20)
                
                // Content Area
                if aiService.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let identifiedPlant = identifiedPlant {
                    // Show identified plant
                    IdentifiedPlantView(
                        plant: identifiedPlant,
                        health: plantHealth,
                        onAddPlant: { plant in
                            // Handle adding plant to garden
                            dismiss()
                        },
                        onAnalyzeHealth: {
                            if let selectedImage = selectedImage {
                                Task {
                                    await analyzePlantHealth(selectedImage)
                                }
                            }
                        },
                        isAnalyzingHealth: isAnalyzingHealth
                    )
                } else if !aiService.searchResults.isEmpty {
                    // Show search results
                    SearchResultsView(
                        results: aiService.searchResults,
                        onSelectPlant: { plant in
                            identifiedPlant = plant
                        }
                    )
                } else if !searchText.isEmpty && !aiService.isLoading {
                    // No results
                    NoResultsView(searchText: searchText)
                } else {
                    // Initial state
                    InitialSearchView(
                        onSearch: {
                            Task {
                                await performSearch()
                            }
                        }
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                Task {
                    await identifyPlantFromImage(image)
                }
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            if !newValue.isEmpty && newValue.count > 2 {
                Task {
                    await performSearch()
                }
            }
        }
    }
    
    private func performSearch() async {
        do {
            _ = try await aiService.searchPlants(query: searchText)
        } catch {
            print("Search failed: \(error)")
        }
    }
    
    private func identifyPlantFromImage(_ image: UIImage) async {
        do {
            let plant = try await aiService.identifyPlantFromImage(image)
            identifiedPlant = plant
        } catch {
            print("Plant identification failed: \(error)")
        }
    }
    
    private func analyzePlantHealth(_ image: UIImage) async {
        isAnalyzingHealth = true
        do {
            let health = try await aiService.analyzePlantHealth(image)
            plantHealth = health
            showingHealthAnalysis = true
        } catch {
            print("Health analysis failed: \(error)")
        }
        isAnalyzingHealth = false
    }
}

// MARK: - Identified Plant View
struct IdentifiedPlantView: View {
    let plant: AIPlantSearchResult
    let health: PlantHealthAnalysis?
    let onAddPlant: (AIPlantSearchResult) -> Void
    let onAnalyzeHealth: () -> Void
    let isAnalyzingHealth: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Plant Image Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    )
                
                // Plant Information
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plant.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(plant.scientificName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    // Plant Details Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        PlantDetailCard(
                            icon: "thermometer",
                            title: "Hardiness",
                            value: "Zones \(plant.hardinessZones.map(String.init).joined(separator: ", "))"
                        )
                        
                        PlantDetailCard(
                            icon: "sun.max.fill",
                            title: "Sun Exposure",
                            value: plant.sunExposure.displayName
                        )
                        
                        PlantDetailCard(
                            icon: "drop.fill",
                            title: "Water Needs",
                            value: plant.waterNeeds.displayName
                        )
                        
                        PlantDetailCard(
                            icon: "leaf.fill",
                            title: "Growth Habit",
                            value: plant.growthHabit.displayName
                        )
                    }
                    
                    // Health Analysis Section
                    if let health = health {
                        PlantHealthView(health: health)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            onAddPlant(plant)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Garden")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.blue)
                            )
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        }
                        
                        Button(action: onAnalyzeHealth) {
                            HStack {
                                if isAnalyzingHealth {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "heart.fill")
                                }
                                Text(isAnalyzingHealth ? "Analyzing..." : "Analyze Health")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.green, lineWidth: 1)
                            )
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        }
                        .disabled(isAnalyzingHealth)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Plant Detail Card
struct PlantDetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Plant Health View
struct PlantHealthView: View {
    let health: PlantHealthAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: health.overallHealth.icon)
                    .foregroundColor(Color(health.overallHealth.color))
                
                Text("Plant Health")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(health.healthScore)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(health.overallHealth.color))
            }
            
            if !health.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(health.recommendations.prefix(3), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(health.overallHealth.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let results: [AIPlantSearchResult]
    let onSelectPlant: (AIPlantSearchResult) -> Void
    
    var body: some View {
        List(results, id: \.id) { plant in
            Button(action: {
                onSelectPlant(plant)
            }) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(plant.scientificName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - No Results View
struct NoResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No plants found")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Try searching for something else or take a photo to identify a plant.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Initial Search View
struct InitialSearchView: View {
    let onSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Find Your Plant")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Search by name or take a photo to identify any plant in your garden.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onSearch) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Start Searching")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue)
                )
                .foregroundColor(.white)
                .fontWeight(.medium)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
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
            picker.dismiss(animated: true)
            
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

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
