import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "heart.circle")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
