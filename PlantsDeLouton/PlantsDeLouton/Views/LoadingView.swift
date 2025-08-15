import SwiftUI

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct LoadingCard: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct LoadingRow: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.6)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView("Loading garden data...")
        LoadingCard("Loading weather...")
        LoadingRow("Loading plants...")
    }
    .padding()
}
