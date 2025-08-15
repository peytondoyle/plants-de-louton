import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    @Published var isSignedIn = false
    @Published var currentUser: User?
    
    private init() {
        // Initialize with your Supabase URL and anon key
        let supabaseURL = "https://edhyajfowwcgrdrazkwf.supabase.co"
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkaHlhamZvd3djZ3JkcmF6a3dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMTIzNDMsImV4cCI6MjA2OTc4ODM0M30.6E-0-_FoyYKd46scjUexd41miiU-EZJg2LlZGogDgHU"
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
        
        // Check if user is already signed in
        Task {
            await checkAuthSession()
        }
    }
    
    // MARK: - Authentication
    
    private func checkAuthSession() async {
        do {
            // For development, auto-sign in with a test user
            // In production, check actual Supabase session
            await MainActor.run {
                self.isSignedIn = true
                self.currentUser = User(
                    id: "test-user-id",
                    email: "test@plants.com",
                    fullName: "Test User",
                    avatarUrl: nil
                )
            }
        } catch {
            print("No active session")
        }
    }
    
    func signInWithApple(token: String, nonce: String) async throws {
        // For development, mock the sign in
        // In production, this would use actual Supabase Auth
        try await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            self.isSignedIn = true
            self.currentUser = User(
                id: "apple-user-id",
                email: "user@icloud.com",
                fullName: "Apple User",
                avatarUrl: nil
            )
        }
    }
    
    func signOut() async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        
        await MainActor.run {
            self.isSignedIn = false
            self.currentUser = nil
        }
    }
}

// MARK: - Supporting Types

struct User {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
}

enum SupabaseError: Error {
    case notAuthenticated
    case unexpectedResponse
}
