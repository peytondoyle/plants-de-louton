import SwiftUI

struct GardenView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Garden Overview")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming soon! This will show your garden statistics, recent activity, and quick actions.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Garden")
        }
    }
}
