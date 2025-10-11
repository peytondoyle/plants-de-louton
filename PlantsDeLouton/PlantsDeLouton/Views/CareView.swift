import SwiftUI

struct CareView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Care Schedule")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming soon! This will show watering schedules, fertilizing reminders, and care history.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Care")
        }
    }
}
