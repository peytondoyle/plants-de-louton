import SwiftUI

struct AuthRequiredView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.bottom, 16)
            
            Text("Welcome to Plants de Louton")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Sign in to manage your garden")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    // For now, use mock credentials
                    do {
                        try await supabaseService.signInWithApple(token: "mock-token", nonce: "mock-nonce")
                    } catch {
                        print("Sign in failed: \(error)")
                    }
                }
            }) {
                HStack {
                    Image(systemName: "apple.logo")
                    Text("Sign in with Apple")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AuthRequiredView()
}
