import SwiftUI

struct SectionDetailView: View {
    let sectionName: String
    let sectionSlug: String
    let sectionColor: Color
    
    @State private var beds: [Bed] = []
    @State private var plants: [Plant] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var supabaseService = SupabaseService.shared
    
    var body: some View {
        VStack {
            if !supabaseService.isSignedIn {
                AuthRequiredView()
            } else if isLoading {
                LoadingView()
            } else if let errorMessage = errorMessage {
                ErrorView(message: errorMessage)
            } else {
                SectionContentView(
                    sectionName: sectionName,
                    beds: beds,
                    plants: plants,
                    sectionColor: sectionColor
                )
            }
        }
        .navigationTitle(sectionName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            if supabaseService.isSignedIn {
                await loadSectionData()
            }
        }
        .onChange(of: supabaseService.isSignedIn) { oldValue, newValue in
            if newValue {
                Task {
                    await loadSectionData()
                }
            } else {
                beds = []
                plants = []
                isLoading = true
                errorMessage = nil
            }
        }
    }
    
    private func loadSectionData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load beds for this section
            let sectionBeds = try await DataService.shared.beds(inSection: sectionSlug)
            
            // Load all plants for these beds
            var allPlants: [Plant] = []
            for bed in sectionBeds {
                let bedPlants = try await DataService.shared.plants(inBed: bed.id)
                allPlants.append(contentsOf: bedPlants)
            }
            
            await MainActor.run {
                self.beds = sectionBeds
                self.plants = allPlants
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load section data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct SectionContentView: View {
    let sectionName: String
    let beds: [Bed]
    let plants: [Plant]
    let sectionColor: Color
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SectionOverviewCard(
                    sectionName: sectionName,
                    bedCount: beds.count,
                    plantCount: plants.count,
                    sectionColor: sectionColor
                )
                
                BedsGridSection(beds: beds, plants: plants, sectionName: sectionName, sectionColor: sectionColor)
                
                if !plants.isEmpty {
                    RecentPlantsSection(plants: plants, sectionColor: sectionColor)
                }
            }
            .padding(.vertical, 20)
        }
    }
}

struct BedsGridSection: View {
    let beds: [Bed]
    let plants: [Plant]
    let sectionName: String
    let sectionColor: Color
    
    var body: some View {
        Group {
            if !beds.isEmpty {
                BedsGridContent(beds: beds, plants: plants, sectionName: sectionName, sectionColor: sectionColor)
            } else {
                EmptyBedsView(sectionName: sectionName, sectionColor: sectionColor)
            }
        }
    }
}

struct BedsGridContent: View {
    let beds: [Bed]
    let plants: [Plant]
    let sectionName: String
    let sectionColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(sectionName: sectionName)
            BedsGrid(beds: beds, plants: plants, sectionColor: sectionColor)
        }
    }
}

struct SectionHeaderView: View {
    let sectionName: String
    
    var body: some View {
        Text("Beds in \(sectionName)")
            .font(.title2)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}

struct BedsGrid: View {
    let beds: [Bed]
    let plants: [Plant]
    let sectionColor: Color
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(beds) { bed in
                BedNavigationLink(bed: bed, plants: plants, sectionColor: sectionColor)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct BedNavigationLink: View {
    let bed: Bed
    let plants: [Plant]
    let sectionColor: Color
    
    var body: some View {
        NavigationLink(destination: BedDetailView(bed: bed)) {
            BedSectionCard(
                bed: bed,
                plantCount: plants.filter { $0.bedId == bed.id }.count,
                sectionColor: sectionColor
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentPlantsSection: View {
    let plants: [Plant]
    let sectionColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Plants")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(plants.prefix(5)) { plant in
                        NavigationLink(destination: PlantDetailsView()) {
                            PlantPreviewCard(plant: plant, sectionColor: sectionColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct SectionOverviewCard: View {
    let sectionName: String
    let bedCount: Int
    let plantCount: Int
    let sectionColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sectionName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(plantCount) plants in \(bedCount) \(bedCount == 1 ? "bed" : "beds")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: sectionName.lowercased().contains("front") ? "house.fill" : "tree.fill")
                    .font(.title)
                    .foregroundColor(sectionColor)
            }
            
            HStack(spacing: 16) {
                SectionStatView(title: "Beds", value: bedCount, icon: "square.grid.2x2", color: sectionColor)
                SectionStatView(title: "Plants", value: plantCount, icon: "leaf", color: sectionColor)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(sectionColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

struct SectionStatView: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BedSectionCard: View {
    let bed: Bed
    let plantCount: Int
    let sectionColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.title2)
                .foregroundColor(sectionColor)
            
            Text(bed.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("\(plantCount) plants")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(sectionColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PlantPreviewCard: View {
    let plant: Plant
    let sectionColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundColor(sectionColor)
            
            Text(plant.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(sectionColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct EmptyBedsView: View {
    let sectionName: String
    let sectionColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No beds in \(sectionName)")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Create your first bed to start organizing your plants")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: NewBedModal()) {
                Text("Create Bed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(sectionColor)
                    )
            }
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
}

// Placeholder for NewBedModal - this would need to be implemented
struct NewBedModal: View {
    var body: some View {
        Text("Create New Bed")
            .navigationTitle("New Bed")
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(sectionName: "Front yard", sectionSlug: "front-yard", sectionColor: .green)
    }
}
