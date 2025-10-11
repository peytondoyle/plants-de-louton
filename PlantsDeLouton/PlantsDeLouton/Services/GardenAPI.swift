import Foundation

// MARK: - Simple Garden API Service
// This replaces the 883-line SupabaseService.swift monster!

class GardenAPI: ObservableObject {
    static let shared = GardenAPI()
    
    // TODO: Replace with your actual Supabase URL and anon key
    private let supabaseURL = "https://edhyajfowwcgrdrazkwf.supabase.co"
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkaHlhamZvd3djZ3JkcmF6a3dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMTIzNDMsImV4cCI6MjA2OTc4ODM0M30.6E-0-_FoyYKd46scjUexd41miiU-EZJg2LlZGogDgHU" // Get from https://app.supabase.com/project/edhyajfowwcgrdrazkwf/settings/api
    
    private init() {}
    
    // MARK: - Spaces
    func loadSpaces() async throws -> [Space] {
        let url = URL(string: "\(supabaseURL)/rest/v1/spaces?select=*")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Space].self, from: data)
    }
    
    func createSpace(_ space: Space) async throws -> Space {
        let url = URL(string: "\(supabaseURL)/rest/v1/spaces")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(space)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Space.self, from: data)
    }
    
    func updateSpace(_ space: Space) async throws -> Space {
        let url = URL(string: "\(supabaseURL)/rest/v1/spaces?id=eq.\(space.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(space)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let spaces = try JSONDecoder().decode([Space].self, from: data)
        return spaces.first ?? space
    }
    
    // MARK: - Beds
    func loadBeds(forSpace spaceId: UUID) async throws -> [Bed] {
        let url = URL(string: "\(supabaseURL)/rest/v1/beds?select=*&space_id=eq.\(spaceId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Bed].self, from: data)
    }
    
    func createBed(_ bed: Bed) async throws -> Bed {
        let url = URL(string: "\(supabaseURL)/rest/v1/beds")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(bed)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Bed.self, from: data)
    }
    
    func updateBed(_ bed: Bed) async throws -> Bed {
        let url = URL(string: "\(supabaseURL)/rest/v1/beds?id=eq.\(bed.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(bed)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let beds = try JSONDecoder().decode([Bed].self, from: data)
        return beds.first ?? bed
    }
    
    // MARK: - Pins
    func loadPins(forBed bedId: UUID) async throws -> [Pin] {
        let url = URL(string: "\(supabaseURL)/rest/v1/pins?select=*&bed_id=eq.\(bedId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Pin].self, from: data)
    }
    
    func createPin(_ pin: Pin) async throws -> Pin {
        let url = URL(string: "\(supabaseURL)/rest/v1/pins")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(pin)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Pin.self, from: data)
    }
    
    func updatePin(_ pin: Pin) async throws -> Pin {
        let url = URL(string: "\(supabaseURL)/rest/v1/pins?id=eq.\(pin.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(pin)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let pins = try JSONDecoder().decode([Pin].self, from: data)
        return pins.first ?? pin
    }
    
    func deletePin(_ pinId: UUID) async throws {
        let url = URL(string: "\(supabaseURL)/rest/v1/pins?id=eq.\(pinId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    // MARK: - Stats
    func loadGardenStats() async throws -> GardenStats {
        async let spaces = loadSpaces()
        async let allBeds = loadAllBeds()
        async let allPins = loadAllPins()
        
        let (spacesResult, bedsResult, pinsResult) = try await (spaces, allBeds, allPins)
        
        return GardenStats(
            spaceCount: spacesResult.count,
            bedCount: bedsResult.count,
            pinCount: pinsResult.count,
            plantCount: pinsResult.filter { $0.type == .plant }.count
        )
    }
    
    // MARK: - Helper Methods
    private func loadAllBeds() async throws -> [Bed] {
        let url = URL(string: "\(supabaseURL)/rest/v1/beds?select=*")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Bed].self, from: data)
    }
    
    private func loadAllPins() async throws -> [Pin] {
        let url = URL(string: "\(supabaseURL)/rest/v1/pins?select=*")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Pin].self, from: data)
    }
}

// MARK: - Error Handling
enum GardenAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
