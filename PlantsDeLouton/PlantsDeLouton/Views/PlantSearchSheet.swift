import SwiftUI

struct PlantSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIPlantSearchService.shared
    
    @State private var searchText = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isIdentifyingPlant = false
    @State private var identifiedPlant: AIPlantSearchResult?
    @State private var showingHealthAnalysis = false
    @State private var healthAnalysis: PlantHealthAnalysis?
    
    let onAddPlant: (AIPlantSearchResult) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    TextField("Search for plants...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { oldValue, newValue in
                            handleSearchTextChange(oldValue: oldValue, newValue: newValue)
                        }
                    
                    // Image Upload Buttons
                    HStack(spacing: 12) {
                        Button(action: { showingCamera = true }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Take Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Content Area
                if aiService.isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Searching for plants...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = aiService.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Search Error")
                            .font(.headline)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !aiService.searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(aiService.searchResults) { plant in
                                PlantSearchResultCard(plant: plant) {
                                    onAddPlant(plant)
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                } else if !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No plants found")
                            .font(.headline)
                        Text("Try a different search term or upload a photo")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "leaf")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("Search for Plants")
                            .font(.headline)
                        Text("Enter a plant name or upload a photo to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                identifyPlant(from: image)
            }
        }
    }
    
    private func handleSearchTextChange(oldValue: String, newValue: String) {
        // Debounce search
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            if searchText == newValue {
                if newValue.isEmpty {
                    aiService.searchResults = []
                } else {
                    await performSearch(query: newValue)
                }
            }
        }
    }
    
    private func performSearch(query: String) async {
        do {
            let results = try await aiService.searchPlants(query: query)
            await MainActor.run {
                aiService.searchResults = results
            }
        } catch {
            await MainActor.run {
                aiService.error = error.localizedDescription
            }
        }
    }
    
    private func identifyPlant(from image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        isIdentifyingPlant = true
        
        Task {
            do {
                let plant = try await aiService.identifyPlant(from: imageData)
                await MainActor.run {
                    identifiedPlant = plant
                    isIdentifyingPlant = false
                }
            } catch {
                await MainActor.run {
                    aiService.error = "Plant identification failed: \(error.localizedDescription)"
                    isIdentifyingPlant = false
                }
            }
        }
    }
}

struct PlantSearchResultCard: View {
    let plant: AIPlantSearchResult
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let scientificName = plant.scientificName {
                        Text(scientificName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Text("Add to Garden")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            
            if let description = plant.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Plant Details
            HStack(spacing: 16) {
                PlantDetailBadge(
                    icon: "sun.max",
                    text: plant.sunExposure.displayName,
                    color: .orange
                )
                
                PlantDetailBadge(
                    icon: "drop",
                    text: plant.waterNeeds.displayName,
                    color: .blue
                )
                
                PlantDetailBadge(
                    icon: "leaf",
                    text: plant.growthHabit.displayName,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PlantDetailBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
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

struct CameraPicker: UIViewControllerRepresentable {
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
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
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


