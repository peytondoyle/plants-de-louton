import SwiftUI

struct GardenOverviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeroCardView()
                
                Text("Garden Sections")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Your Garden")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct HeroCardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Your Garden")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Track, manage, and nurture your plants with ease")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Plants", value: "24", icon: "leaf.fill")
                StatCard(title: "Beds", value: "6", icon: "square.grid.2x2.fill")
                StatCard(title: "Sections", value: "3", icon: "folder.fill")
                StatCard(title: "Recent", value: "2", icon: "clock.fill")
            }
            
            NavigationLink(destination: BedsListView()) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                    Text("Manage Beds")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        GardenOverviewView()
    }
}
