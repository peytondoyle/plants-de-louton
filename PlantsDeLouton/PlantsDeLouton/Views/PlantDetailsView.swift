import SwiftUI

struct PlantDetailsView: View {
    @StateObject private var viewModel = PlantDetailsViewModel()
    @State private var showingSaveSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // AI Hero Card (shown when no plant data)
                if !viewModel.hasPlantData {
                    AIHeroCardView()
                }
                
                // Plant Details Form
                PlantDetailsFormView(
                    plant: $viewModel.plant,
                    plantInfo: viewModel.plantInfo
                )
                
                // Save Button
                VStack(spacing: 12) {
                    Button(action: savePlant) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text(viewModel.isLoading ? "Saving..." : "Save Plant")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.isValid ? Color.green : Color.gray)
                        )
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Add New Plant")
        .navigationBarTitleDisplayMode(.large)
        .alert("Plant Saved!", isPresented: $showingSaveSuccess) {
            Button("OK") {
                viewModel.reset()
            }
        } message: {
            Text("Your plant has been saved successfully.")
        }
    }
    
    private func savePlant() {
        Task {
            await viewModel.savePlant()
            if viewModel.errorMessage == nil {
                showingSaveSuccess = true
            }
        }
    }
}

// MARK: - AI Hero Card View
struct AIHeroCardView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Hero Background
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.1), .mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Pattern overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.05), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 16) {
                    // Icon
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Title
                    Text("AI-Powered Plant Discovery")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Subtitle
                    Text("Let our intelligent system automatically fill in comprehensive plant details for you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Feature Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        FeatureCard(icon: "🌱", title: "Growth Details", subtitle: "Height, width, growth habit")
                        FeatureCard(icon: "☀️", title: "Care Requirements", subtitle: "Sun, water, soil preferences")
                        FeatureCard(icon: "🌸", title: "Blooming Info", subtitle: "Bloom time & characteristics")
                        FeatureCard(icon: "📅", title: "Care Schedule", subtitle: "Planting & maintenance tips")
                    }
                }
                .padding(24)
            }
        }
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        PlantDetailsView()
    }
}
