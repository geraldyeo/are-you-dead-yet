import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CheckInView()
                .tabItem {
                    Label("Check In", systemImage: "heart.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
        .environmentObject(CheckInManager())
        .environmentObject(NotificationService())
        .environmentObject(LocationService())
}
