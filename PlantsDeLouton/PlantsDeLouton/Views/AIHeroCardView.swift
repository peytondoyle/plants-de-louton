import SwiftUI

struct AIHeroCardView: View {
    @Binding var showingSearch: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 32))
                .foregroundColor(.white)
            
            // Title and Subtitle
            VStack(spacing: 8) {
                Text("AI-Powered Plant Discovery")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Let our intelligent system automatically fill in comprehensive plant details for you")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Feature Cards Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                FeatureCard(icon: "🌱", title: "Growth Details", subtitle: "Height, width, growth habit")
                FeatureCard(icon: "☀️", title: "Care Requirements", subtitle: "Sun, water, soil preferences") 
                FeatureCard(icon: "🌸", title: "Blooming Info", subtitle: "Bloom time & characteristics")
                FeatureCard(icon: "📅", title: "Care Schedule", subtitle: "Planting & maintenance tips")
            }
            
            // Search Button
            Button(action: {
                showingSearch = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                    Text("Search for Your Plant")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .background(
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.4, blue: 1.0),  // Blue
                        Color(red: 0.4, green: 0.2, blue: 0.8)   // Purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        // Create a subtle grid pattern
                        for i in stride(from: 0, to: width, by: 40) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i, y: height))
                        }
                        for i in stride(from: 0, to: height, by: 40) {
                            path.move(to: CGPoint(x: 0, y: i))
                            path.addLine(to: CGPoint(x: width, y: i))
                        }
                    }
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AIHeroCardView(showingSearch: .constant(false))
        .padding()
        .background(Color.gray.opacity(0.1))
}
