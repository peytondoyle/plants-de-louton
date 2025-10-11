// View for a specific space showing its beds
// This is where users manage beds and navigate to pin placement

import SwiftUI

struct SpaceDetailView: View {
    let space: Space
    @StateObject private var api = GardenAPI.shared
    @State private var beds: [Bed] = []
    @State private var isLoading = false
    @State private var showingAddBed = false
    @State private var newBedName = ""
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading beds...")
            } else if beds.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Beds Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Create garden beds to start planting")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create Bed") {
                        showingAddBed = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List(beds) { bed in
                    NavigationLink(destination: BedPinView(bed: bed)) {
                        HStack {
                            if let imageURL = bed.imageURL {
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bed.name)
                                    .font(.headline)
                                
                                if let description = bed.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(Int(bed.width))\" × \(Int(bed.height))\"")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(space.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddBed = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
                    .sheet(isPresented: $showingAddBed) {
                AddBedSheet(gardenAPI: api, space: space)
            }
        .task {
            await loadBeds()
        }
    }
    
    private func loadBeds() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            beds = try await api.loadBeds(for: space.id)
        } catch {
            print("Error loading beds: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SpaceDetailView(space: Space(name: "Front Yard"))
    }
}
