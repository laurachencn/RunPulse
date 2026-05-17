import SwiftUI

struct DashboardView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var watchSessionManager = WatchSessionManager()
    @StateObject private var storageManager = StorageManager.shared
    
    private var todayRuns: [RunSession] {
        storageManager.savedRuns.filter { Calendar.current.isDateInToday($0.startDate) }
    }
    
    private var todayRunCount: Int {
        todayRuns.count
    }
    
    private var todayDistance: Double {
        todayRuns.reduce(0) { $0 + $1.totalDistanceKm }
    }
    
    private var todayAvgHR: Double? {
        let hrs = todayRuns.map(\.averageHeartRate).filter { $0 > 0 }
        guard !hrs.isEmpty else { return nil }
        return hrs.reduce(0, +) / Double(hrs.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !healthKitManager.isAuthorized {
                authorizationPrompt
            } else {
                dashboardContent
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
    
    private var authorizationPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("HealthKit Access Required")
                .font(.title3)
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
                    .frame(width: 10, height: 10)
                
                Text(watchSessionManager.isReachable ? "Watch Connected" : "Watch Not Connected")
                    .font(.caption)
            }
            
            VStack(spacing: 12) {
                Text("Today's Activity")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    quickStatCard(title: "Runs", value: "\(todayRunCount)", icon: "figure.run")
                    quickStatCard(title: "Distance", value: String(format: "%.1f km", todayDistance), icon: "location.fill")
                    quickStatCard(title: "Avg HR", value: todayAvgHR.map { String(format: "%.0f BPM", $0) } ?? "-- BPM", icon: "heart.fill")
                }
            }
            
            Spacer()
        }
    }
    
    private func quickStatCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .scaledToFit()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
}
