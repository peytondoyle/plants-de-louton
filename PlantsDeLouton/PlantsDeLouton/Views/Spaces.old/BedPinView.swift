import SwiftUI

struct BedPinView: View {
    @ObservedObject var gardenAPI: GardenAPI
    let bed: Bed
    @State private var pins: [Pin] = []
    @State private var isLoading = false
    @State private var showingAddPin = false
    @State private var selectedPin: Pin?
    @State private var showingPinEditor = false
    @State private var tapLocation: CGPoint = .zero
    
    var body: some View {
        NavigationView {
            VStack {
                if let imageUrl = bed.imageURL {
                    ZStack {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        }
                        .onTapGesture { location in
                            tapLocation = location
                            showingAddPin = true
                        }
                        
                        // Display existing pins
                        ForEach(pins) { pin in
                            PinView(pin: pin) {
                                selectedPin = pin
                                showingPinEditor = true
                            }
                            .position(x: CGFloat(pin.x_position), y: CGFloat(pin.y_position))
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Image")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap to add an image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .onTapGesture { location in
                        tapLocation = location
                        showingAddPin = true
                    }
                }
                
                // Pins list
                List {
                    ForEach(pins) { pin in
                        PinRow(pin: pin) {
                            selectedPin = pin
                            showingPinEditor = true
                        } onDelete: {
                            deletePin(pin)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(bed.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        tapLocation = CGPoint(x: 100, y: 100) // Default position
                        showingAddPin = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPin) {
                AddPinSheet(gardenAPI: gardenAPI, bed: bed, position: tapLocation)
            }
            .sheet(isPresented: $showingPinEditor) {
                if let pin = selectedPin {
                    PinEditorSheet(pin: pin, gardenAPI: gardenAPI)
                }
            }
            .task {
                await loadPins()
            }
        }
    }
    
    private func loadPins() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            pins = try await gardenAPI.loadPins(for: bed.id)
        } catch {
            print("Error loading pins: \(error)")
        }
    }
    
    private func deletePin(_ pin: Pin) {
        Task {
            do {
                try await gardenAPI.deletePin(pin.id)
                if let index = pins.firstIndex(where: { $0.id == pin.id }) {
                    pins.remove(at: index)
                }
            } catch {
                print("Error deleting pin: \(error)")
            }
        }
    }
}
