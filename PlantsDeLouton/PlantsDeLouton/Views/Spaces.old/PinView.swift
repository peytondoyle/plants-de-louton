import SwiftUI

struct PinView: View {
    let pin: Pin
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Image(systemName: plantTypeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(pin.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(4)
            .background(
                Circle()
                    .fill(pinColor)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
