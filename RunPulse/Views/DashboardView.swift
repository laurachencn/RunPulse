import SwiftUI

struct DashboardView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var watchSessionManager = WatchSessionManager()
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !healthKitManager.isAuthorized {
                    authorizationPrompt
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Dashboard")
            .padding()
        }
    }
    
    private var authorizationPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("HealthKit Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("RunPulse needs access to your health data to track heart rate and workouts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Grant Access") {
                Task {
                    try? await healthKitManager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var dashboardContent: some View {
        VStack(spacing: 24) {
            HStack {
                Circle()
                    .fill(watchSessionManager.isReachable ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                
                Text(watchSessionManager.isReachable ? "Watch Connected" : "Watch Not Connected")
                    .font(.subheadline)
            }
            
            VStack(spacing: 12) {
                Text("Today's Activity")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    quickStatCard(title: "Runs", value: "0", icon: "figure.run")
                    quickStatCard(title: "Distance", value: "0 km", icon: "location.fill")
                    quickStatCard(title: "Avg HR", value: "-- BPM", icon: "heart.fill")
                }
            }
            
            Spacer()
        }
    }
    
    private func quickStatCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
}
