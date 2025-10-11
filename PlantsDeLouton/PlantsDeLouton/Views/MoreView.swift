import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("More Options")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming soon! This will show settings, help, and additional features.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("More")
        }
    }
}
