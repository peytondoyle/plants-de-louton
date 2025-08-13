import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color = .green,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Main illustration
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(iconColor.opacity(0.8))
                    .frame(height: 80)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            
            // Action button if provided
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                        Text(actionTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(iconColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Predefined Empty States

struct PlantsEmptyState: View {
    let onAddPlant: () -> Void
    
    var body: some View {
        EmptyStateView(
            title: "No Plants Yet",
            subtitle: "Start building your garden by adding your first plant. Track growth, care schedules, and watch your garden flourish!",
            icon: "leaf.circle",
            iconColor: .green,
            actionTitle: "Add Your First Plant",
            action: onAddPlant
        )
    }
}

struct BedsEmptyState: View {
    let onAddBed: () -> Void
    
    var body: some View {
        EmptyStateView(
            title: "No Garden Beds",
            subtitle: "Create garden beds to organize your plants by location. Perfect for tracking different areas of your garden!",
            icon: "square.grid.2x2.circle",
            iconColor: .blue,
            actionTitle: "Create Your First Bed",
            action: onAddBed
        )
    }
}

struct BedPlantsEmptyState: View {
    let bedName: String
    let onAddPlant: () -> Void
    
    var body: some View {
        EmptyStateView(
            title: "No Plants in \(bedName)",
            subtitle: "This bed is ready for plants! Add some greenery to start growing your garden in this area.",
            icon: "leaf.circle",
            iconColor: .green,
            actionTitle: "Add Plants to Bed",
            action: onAddPlant
        )
    }
}

struct SearchEmptyState: View {
    let hasSearched: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSearched ? "magnifyingglass.circle" : "leaf.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
                .frame(height: 72)
            
            VStack(spacing: 8) {
                Text(hasSearched ? "No Plants Found" : "Search for Plants")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasSearched ? "Try a different search term or browse our plant database" : "Discover new plants and add them to your garden")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack(spacing: 40) {
        PlantsEmptyState {
            print("Add plant tapped")
        }
        
        BedsEmptyState {
            print("Add bed tapped")
        }
        
        BedPlantsEmptyState(bedName: "Front Garden") {
            print("Add plant to bed tapped")
        }
        
        SearchEmptyState(hasSearched: false)
    }
    .padding()
}
