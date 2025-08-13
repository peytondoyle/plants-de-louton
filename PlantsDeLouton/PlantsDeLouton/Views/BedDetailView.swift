import SwiftUI

struct BedDetailView: View {
    let bed: Bed
    
    var body: some View {
        List {
            Section(header: Text("Bed Info")) {
                LabeledContent("Name", value: bed.name)
                LabeledContent("Section", value: bed.section)
                LabeledContent("Plants", value: String(bed.plants.count))
            }
            
            Section(header: Text("Plants in this Bed")) {
                if bed.plants.isEmpty {
                    Text("No plants assigned yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(bed.plants) { plant in
                        HStack {
                            Image(systemName: "leaf")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(plant.name)
                                if let sci = plant.scientificName, !sci.isEmpty {
                                    Text(sci).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(bed.name)
    }
}


