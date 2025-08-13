import Foundation
import Supabase
import AuthenticationServices
import Auth

// MARK: - Error Types

enum SupabaseError: LocalizedError {
    case networkError(Error)
    case unexpectedResponse
    case decodingError(Error)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unexpectedResponse:
            return "Unexpected response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .notAuthenticated:
            return "User not authenticated. Please sign in."
        }
    }
}

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    @Published var isSignedIn: Bool = false
    @Published var currentUser: User?
    
    private init() {
        // For now, we'll use environment variables or hardcoded values
        // In production, you would load these from a secure config file
        let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String ?? ""
        let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? ""
        
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            fatalError("Supabase URL and Anon Key must be configured")
        }
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
        
        // Check initial session status
        Task { @MainActor in
            await checkSessionStatus()
        }
    }
    
    // MARK: - Authentication Status
    
    @MainActor
    private func checkSessionStatus() async {
        do {
            let session = try await client.auth.session
            self.isSignedIn = true
            self.currentUser = User(
                id: session.user.id.uuidString,
                email: session.user.email,
                fullName: session.user.userMetadata["full_name"] as? String,
                avatarUrl: session.user.userMetadata["avatar_url"] as? String
            )
        } catch {
            self.isSignedIn = false
            self.currentUser = nil
        }
    }
    
    // MARK: - Plant Search Cache Methods
    
    /// Search for plants in the cache first, then external API if needed
    func searchPlants(query: String) async throws -> [PlantSearchResult] {
        // First check cache
        if let cachedResults = try await getCachedSearch(query: query) {
            return cachedResults
        }
        
        // If no cache, search external API and cache results
        let results = try await searchExternalAPI(query: query)
        try await cacheSearchResults(query: query, results: results)
        return results
    }
    
    /// Get cached search results
    private func getCachedSearch(query: String) async throws -> [PlantSearchResult]? {
        do {
            let cacheEntry: PlantSearchCacheEntry = try await client
                .from("plant_search_cache")
                .select()
                .eq("query", value: query.lowercased())
                .single()
                .execute()
                .value
            
            // Check if cache is still fresh (within 7 days)
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            if cacheEntry.createdAt < weekAgo {
                return nil
            }
            
            return cacheEntry.results
        } catch {
            // Cache miss is normal, return nil
            return nil
        }
    }
    
    /// Cache search results
    private func cacheSearchResults(query: String, results: [PlantSearchResult]) async throws {
        let cacheEntry = PlantSearchCacheEntry(
            query: query.lowercased(),
            results: results,
            createdAt: Date()
        )
        
        try await client
            .from("plant_search_cache")
            .upsert(cacheEntry)
            .execute()
    }
    
    /// Search external API (mock for now, can be replaced with real Trefle API)
    private func searchExternalAPI(query: String) async throws -> [PlantSearchResult] {
        // This would connect to your existing Trefle API or other plant database
        // For now, return empty array - implement when external API is ready
        return []
    }
    
    // MARK: - Plant Details Methods (now using pins table)
    
    /// Get plant details by ID
    func getPlantDetails(id: UUID) async throws -> Plant? {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let pinRow: PinRow = try await client
                .from("pins")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            return Plant(
                id: pinRow.id,
                name: pinRow.name,
                bedId: pinRow.bed_id,
                x: pinRow.x,
                y: pinRow.y
            )
        } catch {
            return nil
        }
    }
    
    /// Create or update plant (pin)
    func savePlant(_ plant: Plant) async throws -> Plant {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        let pinRow = PinRow(
            id: plant.id,
            bed_id: plant.bedId,
            x: plant.x,
            y: plant.y,
            name: plant.name
        )
        
        let savedPin: PinRow = try await client
            .from("pins")
            .upsert(pinRow)
            .select()
            .single()
            .execute()
            .value
        
        return Plant(
            id: savedPin.id,
            name: savedPin.name,
            bedId: savedPin.bed_id,
            x: savedPin.x,
            y: savedPin.y
        )
    }
    
    /// List all plants (pins)
    func listPlants() async throws -> [Plant] {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        let pins: [PinRow] = try await client
            .from("pins")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
        
        return pins.map { pin in
            Plant(
                id: pin.id,
                name: pin.name,
                bedId: pin.bed_id,
                x: pin.x,
                y: pin.y
            )
        }
    }

    // MARK: - Beds Methods

    struct BedRow: Codable {
        let id: UUID
        let name: String
        let section: String
    }

    /// List all beds
    func listBeds() async throws -> [Bed] {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        let rows: [BedRow] = try await client
            .from("beds")
            .select()
            .order("name", ascending: true)
            .execute()
            .value

        return rows.map { Bed(id: $0.id, name: $0.name, section: $0.section, plants: []) }
    }

    /// Create or update a bed
    func saveBed(_ bed: Bed) async throws -> Bed {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        let row = BedRow(id: bed.id, name: bed.name, section: bed.section)
        let saved: BedRow = try await client
            .from("beds")
            .upsert(row)
            .select()
            .single()
            .execute()
            .value
        return Bed(id: saved.id, name: saved.name, section: saved.section, plants: bed.plants)
    }

    /// Delete a bed by id
    func deleteBed(id: UUID) async throws {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        _ = try await client
            .from("beds")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Bed ↔︎ Plant Assignment (simplified - pins already have bed_id)

    /// List plants in a bed (direct query since pins have bed_id)
    func listPlants(inBed bedId: UUID) async throws -> [Plant] {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        let pins: [PinRow] = try await client
            .from("pins")
            .select()
            .eq("bed_id", value: bedId.uuidString)
            .order("name", ascending: true)
            .execute()
            .value

        return pins.map { pin in
            Plant(
                id: pin.id,
                name: pin.name,
                bedId: pin.bed_id,
                x: pin.x,
                y: pin.y
            )
        }
    }

    /// Assign a plant to a bed (update the pin's bed_id)
    func assignPlant(plantId: UUID, toBed bedId: UUID) async throws {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        _ = try await client
            .from("pins")
            .update(["bed_id": bedId.uuidString])
            .eq("id", value: plantId.uuidString)
            .execute()
    }

    /// Remove a plant from a bed (delete the pin)
    func removePlant(plantId: UUID, fromBed bedId: UUID) async throws {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        _ = try await client
            .from("pins")
            .delete()
            .eq("id", value: plantId.uuidString)
            .execute()
    }

    // MARK: - Authentication (Sign in with Apple)

    func signInWithApple(idToken: String, nonce: String) async throws {
        let credentials = Auth.OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
        _ = try await client.auth.signInWithIdToken(credentials: credentials)
        await checkSessionStatus()
    }

    func signOut() async {
        do { 
            try await client.auth.signOut() 
        } catch { 
            print("Sign out error: \(error)")
        }
        await checkSessionStatus()
    }
    
    // MARK: - Section-based queries
    
    /// List beds in a specific section
    func listBeds(inSection section: String) async throws -> [Bed] {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        let rows: [BedRow] = try await client
            .from("beds")
            .select()
            .eq("section", value: section)
            .order("name", ascending: true)
            .execute()
            .value

        return rows.map { Bed(id: $0.id, name: $0.name, section: $0.section, plants: []) }
    }
    
    /// List plants in a specific section (joins beds and pins)
    func listPlants(inSection section: String) async throws -> [Plant] {
        // Check authentication first
        guard isSignedIn else {
            throw SupabaseError.notAuthenticated
        }
        
        // First get all beds in the section
        let sectionBeds = try await listBeds(inSection: section)
        let bedIds = sectionBeds.map { $0.id.uuidString }
        
        // Then get all plants in those beds
        var allPlants: [Plant] = []
        for bedId in bedIds {
            if let uuid = UUID(uuidString: bedId) {
                let plantsInBed = try await listPlants(inBed: uuid)
                allPlants.append(contentsOf: plantsInBed)
            }
        }
        
        return allPlants
    }

    // MARK: - Care Events Methods

    /// Fetch all care events for the current user
    func fetchCareEvents() async throws -> [CareEvent] {
        let response: [CareEventRow] = try await client
            .from("care_events")
            .select()
            .order("event_date", ascending: false)
            .execute()
            .value
        
        return response.map { row in
            CareEvent(
                id: row.id,
                type: CareEvent.CareType(rawValue: row.event_type) ?? .other,
                date: row.event_date,
                notes: row.description,
                plantId: row.plant_instance_id
            )
        }
    }

    /// Save a care event
    func saveCareEvent(_ careEvent: CareEvent) async throws -> CareEvent {
        let careEventRow = CareEventRow(
            id: careEvent.id,
            plant_instance_id: careEvent.plantId ?? UUID(),
            event_type: careEvent.type.rawValue,
            event_date: careEvent.date,
            description: careEvent.notes ?? "",
            notes: careEvent.notes,
            cost: nil,
            images: nil,
            created_at: careEvent.date,
            updated_at: careEvent.date
        )
        
        let response: CareEventRow = try await client
            .from("care_events")
            .insert(careEventRow)
            .select()
            .single()
            .execute()
            .value
        
        return CareEvent(
            id: response.id,
            type: CareEvent.CareType(rawValue: response.event_type) ?? .other,
            date: response.event_date,
            notes: response.description,
            plantId: response.plant_instance_id
        )
    }

    /// Update a care event
    func updateCareEvent(_ careEvent: CareEvent) async throws -> CareEvent {
        let careEventRow = CareEventRow(
            id: careEvent.id,
            plant_instance_id: careEvent.plantId ?? UUID(),
            event_type: careEvent.type.rawValue,
            event_date: careEvent.date,
            description: careEvent.notes ?? "",
            notes: careEvent.notes,
            cost: nil,
            images: nil,
            created_at: careEvent.date,
            updated_at: careEvent.date
        )
        
        let response: CareEventRow = try await client
            .from("care_events")
            .update(careEventRow)
            .eq("id", value: careEvent.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return CareEvent(
            id: response.id,
            type: CareEvent.CareType(rawValue: response.event_type) ?? .other,
            date: response.event_date,
            notes: response.description,
            plantId: response.plant_instance_id
        )
    }

    /// Delete a care event
    func deleteCareEvent(_ careEventId: UUID) async throws {
        try await client
            .from("care_events")
            .delete()
            .eq("id", value: careEventId.uuidString)
            .execute()
    }

    /// Fetch care events for a specific plant instance
    func fetchCareEvents(forPlantInstance plantInstanceId: UUID) async throws -> [CareEvent] {
        let response: [CareEventRow] = try await client
            .from("care_events")
            .select()
            .eq("plant_instance_id", value: plantInstanceId.uuidString)
            .order("event_date", ascending: false)
            .execute()
            .value
        
        return response.map { row in
            CareEvent(
                id: row.id,
                type: CareEvent.CareType(rawValue: row.event_type) ?? .other,
                date: row.event_date,
                notes: row.description,
                plantId: row.plant_instance_id
            )
        }
    }
}

// MARK: - Data Models

struct User: Codable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
}

struct PinRow: Codable {
    let id: UUID
    let bed_id: UUID
    let x: Double
    let y: Double
    let name: String
}

struct PlantSearchCacheEntry: Codable {
    let query: String
    let results: [PlantSearchResult]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case query
        case results
        case createdAt = "created_at"
    }
}

struct PlantSearchResult: Identifiable, Codable {
    let id: UUID
    let name: String
    let scientificName: String?
    let commonNames: [String]?
    let family: String?
    let genus: String?
    let species: String?
    let growthHabit: String
    let hardinessZones: [Int]?
    let sunExposure: String
    let waterNeeds: String
    let matureHeight: Double?
    let matureWidth: Double?
    let bloomTime: String?
    let bloomDuration: Int?
    let flowerColor: [String]?
    let foliageColor: [String]?
    let soilType: String?
    let soilPH: String?
    let fertilizerNeeds: String?
    let pruningNeeds: String?
    let plantingSeason: String?
    let plantingDepth: Double?
    let spacing: Double?
    
    init(
        id: UUID = UUID(),
        name: String,
        scientificName: String? = nil,
        commonNames: [String]? = nil,
        family: String? = nil,
        genus: String? = nil,
        species: String? = nil,
        growthHabit: String,
        hardinessZones: [Int]? = nil,
        sunExposure: String,
        waterNeeds: String,
        matureHeight: Double? = nil,
        matureWidth: Double? = nil,
        bloomTime: String? = nil,
        bloomDuration: Int? = nil,
        flowerColor: [String]? = nil,
        foliageColor: [String]? = nil,
        soilType: String? = nil,
        soilPH: String? = nil,
        fertilizerNeeds: String? = nil,
        pruningNeeds: String? = nil,
        plantingSeason: String? = nil,
        plantingDepth: Double? = nil,
        spacing: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.commonNames = commonNames
        self.family = family
        self.genus = genus
        self.species = species
        self.growthHabit = growthHabit
        self.hardinessZones = hardinessZones
        self.sunExposure = sunExposure
        self.waterNeeds = waterNeeds
        self.matureHeight = matureHeight
        self.matureWidth = matureWidth
        self.bloomTime = bloomTime
        self.bloomDuration = bloomDuration
        self.flowerColor = flowerColor
        self.foliageColor = foliageColor
        self.soilType = soilType
        self.soilPH = soilPH
        self.fertilizerNeeds = fertilizerNeeds
        self.pruningNeeds = pruningNeeds
        self.plantingSeason = plantingSeason
        self.plantingDepth = plantingDepth
        self.spacing = spacing
    }
    
    init(from plant: Plant) {
        self.id = plant.id
        self.name = plant.name
        self.scientificName = plant.scientificName
        self.commonNames = nil // Plant model doesn't have this
        self.family = nil // Plant model doesn't have this
        self.genus = nil // Plant model doesn't have this
        self.species = nil // Plant model doesn't have this
        self.growthHabit = plant.growthHabit ?? "unknown"
        self.hardinessZones = nil // Plant model doesn't have this
        self.sunExposure = plant.sunExposure ?? "full_sun"
        self.waterNeeds = plant.waterNeeds ?? "moderate"
        self.matureHeight = nil // Plant model doesn't have this
        self.matureWidth = nil // Plant model doesn't have this
        self.bloomTime = nil // Plant model doesn't have this
        self.bloomDuration = nil // Plant model doesn't have this
        self.flowerColor = nil // Plant model doesn't have this
        self.foliageColor = nil // Plant model doesn't have this
        self.soilType = nil // Plant model doesn't have this
        self.soilPH = nil // Plant model doesn't have this
        self.fertilizerNeeds = nil // Plant model doesn't have this
        self.pruningNeeds = nil // Plant model doesn't have this
        self.plantingSeason = nil // Plant model doesn't have this
        self.plantingDepth = nil // Plant model doesn't have this
        self.spacing = nil // Plant model doesn't have this
    }
}

// MARK: - External API Integration

private func searchExternalAPI(query: String) async throws -> [PlantSearchResult] {
    // This would connect to your existing Trefle API or other plant database
    // For now, return empty array - implement when external API is ready
    return []
}

// MARK: - Care Event Row Structure
private struct CareEventRow: Codable {
    let id: UUID
    let plant_instance_id: UUID
    let event_type: String
    let event_date: Date
    let description: String
    let notes: String?
    let cost: Decimal?
    let images: [String]?
    let created_at: Date?
    let updated_at: Date?
}
