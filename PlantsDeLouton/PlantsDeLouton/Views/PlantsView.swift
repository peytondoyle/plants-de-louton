import SwiftUI

struct PlantsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.mint)
                
                Text("Plant Library")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming soon! This will show all your plants, their care requirements, and growth tracking.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Plants")
        }
    }
}
