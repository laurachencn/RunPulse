import SwiftUI

struct RunView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var heartRateMonitor: HeartRateMonitor
    @StateObject private var paceTracker = PaceTracker()
    @StateObject private var alertEngine: AlertEngine
    @State private var showingError = false
    @AppStorage("alertThreshold") private var alertThreshold: Int = 171
    
    init() {
        let threshold = UserDefaults.standard.integer(forKey: "alertThreshold")
        let effectiveThreshold = threshold > 0 ? threshold : 171
        _heartRateMonitor = StateObject(wrappedValue: HeartRateMonitor(alertThreshold: effectiveThreshold))
        _alertEngine = StateObject(wrappedValue: AlertEngine(threshold: effectiveThreshold))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            switch workoutManager.runState.state {
            case .notStarted:
                startScreen
            case .running, .paused:
                activeRunScreen
            case .completed:
                SummaryView(runSession: workoutManager.currentSession)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                workoutManager.errorMessage = nil
            }
        } message: {
            Text(workoutManager.errorMessage ?? "Unknown error")
        }
        .onChange(of: workoutManager.errorMessage) { newValue in
            if newValue != nil {
                showingError = true
            }
        }
    }
    
    private var startScreen: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Ready to Run?")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Button(action: {
                Task {
                    await workoutManager.startWorkout()
                }
            }) {
                Text("Start")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            NavigationLink(destination: AudioCueSettingsView()) {
                Label("Audio Cues", systemImage: "mic.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    private var activeRunScreen: some View {
        VStack(spacing: 4) {
            heartRateDisplay
            Divider()
            paceDisplay
            Divider()
            statsRow
            if alertEngine.isAlerting {
                alertBanner
            }
        }
        .padding(.horizontal)
    }
    
    private var heartRateDisplay: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(alertEngine.isAlerting ? .red : .pink)
                .animation(.easeInOut, value: alertEngine.isAlerting)
            
            Text("\(Int(heartRateMonitor.currentHeartRate))")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            Text("BPM")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var paceDisplay: some View {
        VStack(spacing: 2) {
            Text("Pace")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(PaceTracker.formatPace(paceTracker.currentPace))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
            
            Text("/km")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var statsRow: some View {
        HStack {
            VStack {
                Text(formatDistance(paceTracker.totalDistance))
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Distance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text(formatDuration(workoutManager.runState.currentDuration))
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text("\(paceTracker.completedKilometers)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("KM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var alertBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("High HR! Slow down")
        }
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.red)
        .cornerRadius(8)
        .padding(.top, 4)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    RunView()
}
