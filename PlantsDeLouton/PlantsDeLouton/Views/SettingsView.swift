import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @State private var showingAppleSignInError: String?
    @ObservedObject private var supabase = SupabaseService.shared
    
    var body: some View {
        List {
            Section("Account") {
                if supabase.isSignedIn {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Signed in as:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(supabase.currentUser?.email ?? "Unknown")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    Button("Sign Out") {
                        Task {
                            try? await supabase.signOut()
                        }
                    }
                    .foregroundColor(.red)
                } else {
                    SignInWithAppleButtonView { result in
                        Task {
                            switch result {
                            case .success(let token, let nonce):
                                do {
                                    try await supabase.signInWithApple(token: token, nonce: nonce)
                                } catch {
                                    showingAppleSignInError = error.localizedDescription
                                }
                            case .failure(let error):
                                showingAppleSignInError = error.localizedDescription
                            }
                        }
                    }
                }
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


