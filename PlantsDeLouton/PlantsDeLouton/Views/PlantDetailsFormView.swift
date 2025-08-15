import SwiftUI

struct PlantDetailsFormView: View {
    @Binding var plant: Plant
    let plantSearchData: AIPlantSearchResult?
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let searchData = plantSearchData {
                // AI Success Card
                AISuccessCard(plantData: searchData)
            }
            
            // Plant Photo Section
            VStack(spacing: 16) {
                Text("Plant Photo")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let image = selectedImage {
                    VStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .cornerRadius(12)
                        
                        Button("Change Photo") {
                            showingActionSheet = true
                        }
                        .foregroundColor(.blue)
                    }
                } else {
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Add Photo")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                        
                        Button("Add Photo") {
                            showingActionSheet = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Plant Information Form
            VStack(spacing: 16) {
                Text("Plant Information")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Basic Information
                VStack(spacing: 12) {
                    FormField(title: "Plant Name") {
                        TextField("Enter plant name", text: Binding(
                            get: { plant.name },
                            set: { plant.name = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if let searchData = plantSearchData {
                        FormField(title: "Scientific Name") {
                            TextField("Scientific name", text: .constant(searchData.scientificName ?? ""))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.secondary)
                        }
                        
                        FormField(title: "Growth Habit") {
                            TextField("Growth habit", text: .constant(searchData.growthHabit.displayName))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.secondary)
                        }
                        
                        FormField(title: "Sun Exposure") {
                            HStack {
                                Image(systemName: searchData.sunExposure.icon)
                                    .foregroundColor(.orange)
                                TextField("Sun exposure", text: .constant(searchData.sunExposure.displayName))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        FormField(title: "Water Needs") {
                            HStack {
                                Image(systemName: searchData.waterNeeds.icon)
                                    .foregroundColor(.blue)
                                TextField("Water needs", text: .constant(searchData.waterNeeds.displayName))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Plant Size Information
                        HStack(spacing: 12) {
                            FormField(title: "Mature Height") {
                                TextField("Height", text: .constant("\(Int(searchData.matureHeight ?? 0))\""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                            
                            FormField(title: "Mature Width") {
                                TextField("Width", text: .constant("\(Int(searchData.matureWidth ?? 0))\""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Care Information
                        FormField(title: "Planting Season") {
                            TextField("Season", text: .constant("Spring"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                                .foregroundColor(.secondary)
                        }
                        
                        FormField(title: "Bloom Time") {
                            HStack {
                                Text("🌸")
                                TextField("Bloom time", text: .constant(searchData.bloomTime ?? "Unknown"))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Flower Colors
                        if let flowerColors = searchData.flowerColor, !flowerColors.isEmpty {
                            FormField(title: "Flower Colors") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(flowerColors, id: \.self) { color in
                                            Text(color.capitalized)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(colorForName(color).opacity(0.2))
                                                )
                                                .foregroundColor(colorForName(color))
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                    }
                    
                    // Notes (user editable)
                    FormField(title: "Notes") {
                        TextField("Plant notes", text: Binding(
                            get: { plant.notes ?? "" },
                            set: { plant.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Notes (user editable)
                    FormField(title: "Notes") {
                        TextField("Plant notes", text: Binding(
                            get: { plant.notes ?? "" },
                            set: { plant.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Add Plant Photo"),
                message: Text("Choose how you'd like to add a photo"),
                buttons: [
                    .default(Text("Take Photo")) {
                        showingCamera = true
                    },
                    .default(Text("Choose from Library")) {
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedImage)
        }
    }
    
    private func colorForName(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "pink": return .pink
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "white": return .gray
        default: return .gray
        }
    }
}

struct AISuccessCard: View {
    let plantData: AIPlantSearchResult
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Search Complete!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Found detailed information for \(plantData.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick Summary
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickInfoCard(
                    icon: "info.circle.fill",
                    title: "Family",
                    value: plantData.family ?? "",
                    color: .blue
                )
                QuickInfoCard(
                    icon: "calendar",
                    title: "Growth Type",
                    value: plantData.growthHabit.displayName,
                    color: .green
                )
                QuickInfoCard(
                    icon: plantData.sunExposure.icon,
                    title: "Sun Needs",
                    value: plantData.sunExposure.displayName,
                    color: .orange
                )
                QuickInfoCard(
                    icon: plantData.waterNeeds.icon,
                    title: "Water Needs",
                    value: plantData.waterNeeds.displayName,
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct FormField<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            content
        }
    }
}

#Preview {
    PlantDetailsFormView(
        plant: .constant(Plant(name: "New Plant", bedId: UUID(), x: 0.5, y: 0.5)),
        plantSearchData: nil
    )
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
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
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
