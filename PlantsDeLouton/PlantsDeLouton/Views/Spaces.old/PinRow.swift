import SwiftUI

struct PinRow: View {
    let pin: Pin
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Plant type icon
            Image(systemName: plantTypeIcon)
                .font(.title2)
                .foregroundColor(pinColor)
                .frame(width: 30)
            
            // Plant details
            VStack(alignment: .leading, spacing: 2) {
                Text(pin.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(pin.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = pin.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Position info
            VStack(alignment: .trailing, spacing: 2) {
                Text("Position")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("(\(Int(pin.x)), \(Int(pin.y)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var plantTypeIcon: String {
        switch pin.type {
        case .plant:
            return "leaf.fill"
        case .tree:
            return "tree.fill"
        case .shrub:
            return "leaf.circle.fill"
        case .flower:
            return "flower"
        case .herb:
            return "leaf"
        case .vegetable:
            return "carrot.fill"
        case .fruit:
            return "applelogo"
        }
    }
    
    private var pinColor: Color {
        switch pin.type {
        case .plant:
            return .green
        case .tree:
            return .brown
        case .shrub:
            return .mint
        case .flower:
            return .pink
        case .herb:
            return .mint
        case .vegetable:
            return .green
        case .fruit:
            return .red
        }
    }
}
