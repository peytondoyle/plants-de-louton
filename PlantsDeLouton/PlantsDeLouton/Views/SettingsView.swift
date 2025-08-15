import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @State private var showingAppleSignInError: String?
    @ObservedObject private var supabase = SupabaseService.shared
    // @StateObject private var notificationService = NotificationService.shared
    @StateObject private var weatherService = SimpleWeatherService.shared
    
    var body: some View {
        List {
            Section("Account") {
                if supabase.isSignedIn {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if let user = supabase.currentUser, let fullName = user.fullName {
                                    Text(fullName)
                                        .font(.headline)
                                } else {
                                    Text("Signed in with Apple")
                                        .font(.headline)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "applelogo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Apple ID")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Sign Out") {
                                Task { await supabase.signOut() }
                            }
                            .foregroundColor(.red)
                        }
                        
                        if let user = supabase.currentUser, let email = user.email {
                            HStack {
                                Image(systemName: "envelope")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    SignInWithAppleButtonView { result in
                        switch result {
                        case .success(let token, let nonce):
                            Task {
                                do {
                                    try await supabase.signInWithApple(idToken: token, nonce: nonce)
                                } catch {
                                    showingAppleSignInError = error.localizedDescription
                                }
                            }
                        case .failure(let error):
                            showingAppleSignInError = error.localizedDescription
                        }
                    }
                }
            }
            
            Section("Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.slash")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Push Notifications")
                                .font(.headline)
                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smart Care Reminders")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Get notified when your plants need care based on weather conditions and plant type.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Weather Alerts")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Receive alerts for frost, heat, and drought conditions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .alert("Sign in failed", isPresented: .constant(showingAppleSignInError != nil)) {
            Button("OK") { showingAppleSignInError = nil }
        } message: {
            Text(showingAppleSignInError ?? "")
        }
    }
}

private struct SignInWithAppleButtonView: View {
    enum SignInResult {
        case success(token: String, nonce: String)
        case failure(Error)
    }
    var onComplete: (SignInResult) -> Void
    @State private var currentNonce: String = ""
    
    var body: some View {
        SignInWithAppleButton(.signIn, onRequest: { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
        }, onCompletion: { result in
            switch result {
            case .success(let auth):
                guard
                    let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                    let tokenData = credential.identityToken,
                    let token = String(data: tokenData, encoding: .utf8)
                else {
                    onComplete(.failure(NSError(domain: "apple", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Apple ID token"])));
                    return
                }
                onComplete(.success(token: token, nonce: currentNonce))
            case .failure(let error):
                onComplete(.failure(error))
            }
        })
        .signInWithAppleButtonStyle(.black)
        .frame(height: 44)
    }
}

// MARK: - Nonce utils
import CryptoKit

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)") }
        if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
        }
    }
    return result
}


