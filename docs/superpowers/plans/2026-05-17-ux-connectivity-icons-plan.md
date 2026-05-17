# RunPulse UX, Connectivity & Icons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix iOS UX (split-view, fonts, interactions), add Watch↔iOS connectivity for run sync and threshold sharing, and generate app icons for both targets.

**Architecture:** Three independent phases executed sequentially: (1) Replace NavigationView with NavigationStack, scale fonts, wire real dashboard data; (2) Create WatchConnectivityManager on Watch side, wire into WorkoutManager.endWorkout(), sync HR threshold from iOS Settings; (3) Generate 1024x1024 app icons via Python script with heartbeat waveform on gradient background.

**Tech Stack:** Swift 5.9, SwiftUI (NavigationStack, NavigationLink value-based), WatchConnectivity, XcodeGen, Python 3 + Pillow

---

## Phase 1: iOS UX Fixes

### Task 1: ContentView — Single NavigationStack wrapper

**Files:**
- Modify: `RunPulse/Views/ContentView.swift`

- [ ] **Step 1: Replace ContentView with NavigationStack wrapper**

Replace the entire file content:

```swift
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
```

- [ ] **Step 2: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Views/ContentView.swift
git commit -m "refactor: replace NavigationView with single NavigationStack in ContentView"
```

---

### Task 2: DashboardView — Remove NavigationView, wire real data, scale fonts

**Files:**
- Modify: `RunPulse/Views/DashboardView.swift`

- [ ] **Step 1: Replace DashboardView with NavigationView removed, real data wired, fonts scaled**

Replace the entire file content:

```swift
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
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Views/DashboardView.swift
git commit -m "feat: wire real dashboard data, remove NavigationView, scale fonts"
```

---

### Task 3: HistoryView — Remove NavigationView, use NavigationLink(value:)

**Files:**
- Modify: `RunPulse/Views/HistoryView.swift`

- [ ] **Step 1: Replace HistoryView**

Replace the entire file content:

```swift
import SwiftUI

struct HistoryView: View {
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some View {
        Group {
            if storageManager.savedRuns.isEmpty {
                emptyState
            } else {
                runList
            }
        }
        .navigationTitle("Run History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await storageManager.loadRuns()
        }
        .navigationDestination(for: RunSession.self) { session in
            RunDetailView(runSession: session)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Runs Yet")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Start a run on your Apple Watch to see it here.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var runList: some View {
        List(storageManager.savedRuns) { session in
            NavigationLink(value: session) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.startDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(session.durationString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(String(format: "%.2f km", session.totalDistanceKm), systemImage: "location.fill")
                        Spacer()
                        Label(session.averagePaceString + "/km", systemImage: "speedometer")
                        Spacer()
                        Label("\(Int(session.averageHeartRate)) BPM", systemImage: "heart.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    HistoryView()
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Views/HistoryView.swift
git commit -m "feat: remove NavigationView from HistoryView, use NavigationLink(value:)"
```

---

### Task 4: SettingsView — Remove NavigationView, add inline title mode

**Files:**
- Modify: `RunPulse/Views/SettingsView.swift`

- [ ] **Step 1: Replace SettingsView**

Replace the entire file content:

```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("userAge") private var userAge: Int = 30
    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @AppStorage("userHeight") private var userHeight: Double = 175.0
    @AppStorage("restingHeartRate") private var restingHeartRate: Int = 60
    @AppStorage("useCustomMaxHR") private var useCustomMaxHR: Bool = false
    @AppStorage("customMaxHR") private var customMaxHR: Int = 190
    
    var calculatedMaxHR: Int {
        220 - userAge
    }
    
    var alertThreshold: Int {
        Int(Double(activeMaxHR) * 0.90)
    }
    
    var activeMaxHR: Int {
        useCustomMaxHR ? customMaxHR : calculatedMaxHR
    }
    
    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                Stepper("Age: \(userAge)", value: $userAge, in: 18...100)
                Stepper("Weight: \(userWeight, specifier: "%.1f") kg", value: $userWeight, in: 30...200, step: 0.5)
                Stepper("Height: \(userHeight, specifier: "%.0f") cm", value: $userHeight, in: 100...250, step: 1)
                Stepper("Resting HR: \(restingHeartRate) BPM", value: $restingHeartRate, in: 40...100)
            }
            
            Section(header: Text("Heart Rate Zones")) {
                Toggle("Use Custom Max HR", isOn: $useCustomMaxHR)
                
                if useCustomMaxHR {
                    Stepper("Max HR: \(customMaxHR) BPM", value: $customMaxHR, in: 120...220)
                } else {
                    HStack {
                        Text("Calculated Max HR")
                        Spacer()
                        Text("\(calculatedMaxHR) BPM")
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Alert Threshold (90%)")
                    Spacer()
                    Text("\(alertThreshold) BPM")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Views/SettingsView.swift
git commit -m "feat: remove NavigationView from SettingsView, add inline title mode"
```

---

### Task 5: RunDetailView — Remove NavigationView, scale fonts, adjust spacing

**Files:**
- Modify: `RunPulse/Views/RunDetailView.swift`

- [ ] **Step 1: Replace RunDetailView**

Replace the entire file content:

```swift
import SwiftUI

struct RunDetailView: View {
    let runSession: RunSession
    @AppStorage("userAge") private var userAge: Int = 30
    
    var alertThreshold: Int {
        Int(Double(220 - userAge) * 0.90)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsGrid
                splitsSection
            }
            .padding()
        }
        .navigationTitle("Run Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(runSession.startDate, style: .date)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(runSession.startDate, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(title: "Duration", value: runSession.durationString, icon: "stopwatch")
            statCard(title: "Distance", value: String(format: "%.2f km", runSession.totalDistanceKm), icon: "location.fill")
            statCard(title: "Avg Pace", value: runSession.averagePaceString, icon: "speedometer")
            statCard(title: "Avg HR", value: "\(Int(runSession.averageHeartRate)) BPM", icon: "heart.fill")
            statCard(title: "Max HR", value: "\(Int(runSession.maxHeartRate)) BPM", icon: "heart.fill")
            statCard(title: "Calories", value: "\(Int(runSession.totalCalories))", icon: "flame.fill")
        }
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .scaledToFit()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kilometer Splits")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(runSession.splits) { split in
                HStack {
                    Text("KM \(split.kilometerNumber)")
                        .fontWeight(.medium)
                        .frame(width: 50, alignment: .leading)
                    
                    Spacer()
                    
                    Text(split.paceString)
                        .monospacedDigit()
                    
                    Text("\(Int(split.averageHeartRate)) BPM")
                        .foregroundColor(.pink)
                        .frame(width: 70, alignment: .trailing)
                    
                    if split.maxHeartRate > Double(alertThreshold) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RunDetailView(runSession: RunSession.newSession())
}
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Views/RunDetailView.swift
git commit -m "feat: remove NavigationView from RunDetailView, scale fonts, increase grid spacing"
```

---

### Task 6: Run all iOS tests to verify no regressions

- [ ] **Step 1: Run all iOS tests**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(Test Case|Executed|TEST)"
```
Expected: All tests pass (19+ unit tests + 2 UI tests)

---

## Phase 2: Watch ↔ iOS Connectivity

### Task 7: Create WatchConnectivityManager

**Files:**
- Create: `RunPulseWatch/Services/WatchConnectivityManager.swift`

- [ ] **Step 1: Create WatchConnectivityManager**

Create the file with this content:

```swift
import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isPaired = false
    @Published var isReachable = false
    
    private let session = WCSession.default
    
    override init() {
        super.init()
        session.delegate = self
        session.activate()
        updateSessionState()
    }
    
    private func updateSessionState() {
        isPaired = session.isPaired
        isReachable = session.isReachable
    }
    
    func sendRunSession(_ session: RunSession) {
        do {
            let data = try JSONEncoder().encode(session)
            let message: [String: Any] = ["runSession": data]
            sendToWatch(message)
        } catch {
            print("Failed to encode run session: \(error)")
        }
    }
    
    func sendSettingsUpdate(threshold: Int) {
        let message: [String: Any] = ["alertThreshold": threshold]
        sendToWatch(message)
    }
    
    private func sendToWatch(_ message: [String: Any]) {
        guard session.isReachable else {
            try? session.updateApplicationContext(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message to iPhone: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if let threshold = message["alertThreshold"] as? Int {
                UserDefaults.standard.set(threshold, forKey: "alertThreshold")
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let threshold = applicationContext["alertThreshold"] as? Int {
                UserDefaults.standard.set(threshold, forKey: "alertThreshold")
            }
        }
    }
}
```

- [ ] **Step 2: Add to project.yml**

In `project.yml`, add the new file to `RunPulseWatchTests` sources (it needs to be in the Watch target sources, not tests). Actually, it goes in the Watch app target. Add it to the `RunPulseWatch` target sources section:

```yaml
  RunPulseWatch:
    type: application
    platform: watchOS
    sources:
      - path: RunPulseWatch
      - path: RunPulse/Models
        buildPhase: sources
    settings:
```

The file is inside `RunPulseWatch/Services/` which is already covered by `- path: RunPulseWatch`. No project.yml change needed.

- [ ] **Step 3: Build Watch target to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Services/WatchConnectivityManager.swift
git commit -m "feat: add WatchConnectivityManager for WCSession on Watch side"
```

---

### Task 8: Wire WatchConnectivityManager into WorkoutManager.endWorkout()

**Files:**
- Modify: `RunPulseWatch/Services/WorkoutManager.swift`

- [ ] **Step 1: Add import and sendRunSession call**

In `WorkoutManager.swift`, add `import WatchConnectivity` at the top (line 1):

```swift
import Foundation
import HealthKit
import WatchKit
import CoreLocation
import WatchConnectivity
```

In `endWorkout()`, after `currentSession = session` (line 116), add the send call. Replace the `endWorkout` method's ending:

```swift
    func endWorkout() async -> RunSession? {
        timer?.invalidate()
        workoutSession?.end()
        
        let endDate = Date()
        let duration = startDate.map { endDate.timeIntervalSince($0) } ?? 0
        
        let session = RunSession(
            id: UUID(),
            startDate: startDate ?? Date(),
            endDate: endDate,
            totalDuration: duration,
            totalDistance: totalDistance,
            totalCalories: runState.totalCalories,
            averageHeartRate: allHeartRates.isEmpty ? 0 : allHeartRates.reduce(0, +) / Double(allHeartRates.count),
            maxHeartRate: allHeartRates.max() ?? 0,
            averagePace: calculatePace(duration: duration, distance: totalDistance),
            splits: splits,
            isCompleted: true
        )
        
        currentSession = session
        runState.state = .completed
        
        await WatchConnectivityManager.shared.sendRunSession(session)
        
        return session
    }
```

Note: Also changed `totalCalories: 0` to `totalCalories: runState.totalCalories` to wire up the real calorie data from HealthKit.

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Services/WorkoutManager.swift
git commit -m "feat: send completed run to iOS via WatchConnectivityManager on endWorkout"
```

---

### Task 9: RunView — Use @AppStorage threshold, remove hardcoded 171

**Files:**
- Modify: `RunPulseWatch/Views/RunView.swift`

- [ ] **Step 1: Replace RunView init to use @AppStorage value**

Replace the entire file:

```swift
import SwiftUI

struct RunView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var heartRateMonitor: HeartRateMonitor
    @StateObject private var paceTracker = PaceTracker()
    @StateObject private var alertEngine: AlertEngine
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
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -quiet
```
Expected: BUILD SUCCEEDED

Note: Threshold is read from `@AppStorage` at init time. `WatchConnectivityManager` updates `UserDefaults` on the Watch side, which takes effect on the next app launch. Runtime threshold changes during an active run are not supported (acceptable for v1).

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Views/RunView.swift
git commit -m "feat: use @AppStorage threshold in RunView, remove hardcoded 171"
```

---

### Task 10: iOS WatchSessionManager — Add sendSettingsUpdate

**Files:**
- Modify: `RunPulse/Services/WatchSessionManager.swift`

- [ ] **Step 1: Add sendSettingsUpdate method**

Add this method after `sendRunSession`:

```swift
    func sendSettingsUpdate(threshold: Int) {
        let message: [String: Any] = ["alertThreshold": threshold]
        sendToWatch(message)
    }
```

Also add incoming handler for threshold (in case Watch sends it back). In `session(_:didReceiveMessage:)`, add a case for `alertThreshold`:

```swift
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let runSessionData = message["runSession"] as? Data {
                do {
                    let runSession = try JSONDecoder().decode(RunSession.self, from: runSessionData)
                    lastReceivedRun = runSession
                    await StorageManager.shared.saveRun(runSession)
                } catch {
                    print("Failed to decode run session: \(error)")
                }
            }
            // Threshold updates from Watch are handled by @AppStorage on Watch side
        }
    }
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Services/WatchSessionManager.swift
git commit -m "feat: add sendSettingsUpdate to WatchSessionManager for threshold sync"
```

---

### Task 11: SettingsView — Send threshold to Watch on change

**Files:**
- Modify: `RunPulse/Views/SettingsView.swift`

- [ ] **Step 1: Add threshold sync on Settings change**

Add a `.onChange` modifier to the Form that sends the threshold to Watch whenever `userAge`, `useCustomMaxHR`, or `customMaxHR` changes. Add this after `.navigationBarTitleDisplayMode(.inline)`:

```swift
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: alertThreshold) { newThreshold in
            WatchSessionManager.shared.sendSettingsUpdate(threshold: newThreshold)
        }
```

- [ ] **Step 2: Build to verify**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Views/SettingsView.swift
git commit -m "feat: send alert threshold to Watch when Settings change"
```

---

### Task 12: Run all tests to verify connectivity changes

- [ ] **Step 1: Run iOS tests**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(Executed|TEST)"
```
Expected: All tests pass

- [ ] **Step 2: Run watchOS tests**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' 2>&1 | grep -E "(Executed|TEST)"
```
Expected: All tests pass (46+ tests)

---

## Phase 3: App Icons

### Task 13: Create icon generation script

**Files:**
- Create: `scripts/generate_icons.py`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /Users/feichen/RunPulse/scripts
mkdir -p /Users/feichen/RunPulse/RunPulse/Resources/Assets.xcassets/AppIcon.appiconset
mkdir -p /Users/feichen/RunPulse/RunPulseWatch/Resources/Assets.xcassets/AppIcon.appiconset
```

- [ ] **Step 2: Create generate_icons.py**

```python
#!/usr/bin/env python3
"""Generate RunPulse app icons: heartbeat waveform on gradient background."""

import json
import math
import os
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Installing Pillow...")
    os.system("pip install Pillow")
    from PIL import Image, ImageDraw

SIZE = 1024
BG_TOP = (255, 107, 107)    # #FF6B6B coral red
BG_BOTTOM = (78, 205, 196)  # #4ECDC4 teal
WAVE_COLOR = (255, 255, 255)
WAVE_WIDTH = 12

def create_gradient(size, top_color, bottom_color):
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * y / size)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * y / size)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * y / size)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    return img

def draw_heartbeat(draw, size, color, width):
    """Draw a heartbeat/EKG waveform centered on the image."""
    margin = int(size * 0.15)
    wave_width = int(size * 0.7)
    center_y = size // 2
    amplitude = int(size * 0.2)
    
    points = []
    steps = 200
    
    for i in range(steps):
        x = margin + int(wave_width * i / steps)
        t = i / steps
        
        # EKG waveform pattern: flat, P wave, QRS complex, T wave, flat
        if t < 0.15:
            y = center_y
        elif t < 0.22:
            # P wave (small bump)
            y = center_y - int(amplitude * 0.15 * math.sin((t - 0.15) / 0.07 * math.pi))
        elif t < 0.30:
            # Flat between P and QRS
            y = center_y
        elif t < 0.33:
            # Q dip
            y = center_y + int(amplitude * 0.1)
        elif t < 0.38:
            # R spike (tall)
            y = center_y - amplitude
        elif t < 0.42:
            # S dip
            y = center_y + int(amplitude * 0.2)
        elif t < 0.50:
            # Flat between QRS and T
            y = center_y
        elif t < 0.65:
            # T wave (medium bump)
            y = center_y - int(amplitude * 0.35 * math.sin((t - 0.50) / 0.15 * math.pi))
        else:
            y = center_y
        
        points.append((x, y))
    
    draw.line(points, fill=color, width=width, joint='curve')

def create_contents_json():
    return {
        "images": [
            {
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # Create icon
    img = create_gradient(SIZE, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)
    draw_heartbeat(draw, SIZE, WAVE_COLOR, WAVE_WIDTH)
    
    # Save for iOS
    ios_dir = os.path.join(base, "RunPulse", "Resources", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(ios_dir, exist_ok=True)
    img.save(os.path.join(ios_dir, "AppIcon-1024.png"))
    with open(os.path.join(ios_dir, "Contents.json"), 'w') as f:
        json.dump(create_contents_json(), f, indent=2)
    print(f"iOS icon saved to {ios_dir}")
    
    # Save for Watch (same icon, watchOS 10+ uses 1024x1024)
    watch_dir = os.path.join(base, "RunPulseWatch", "Resources", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(watch_dir, exist_ok=True)
    img.save(os.path.join(watch_dir, "AppIcon-1024.png"))
    
    # Watch-specific Contents.json
    watch_contents = {
        "images": [
            {
                "idiom": "universal",
                "platform": "watchos",
                "size": "1024x1024"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    with open(os.path.join(watch_dir, "Contents.json"), 'w') as f:
        json.dump(watch_contents, f, indent=2)
    print(f"Watch icon saved to {watch_dir}")
    
    print("Icons generated successfully")

if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Run the script**

```bash
cd /Users/feichen/RunPulse
pip install Pillow
python3 scripts/generate_icons.py
```
Expected: "iOS icon saved to...", "Watch icon saved to...", "Icons generated successfully"

- [ ] **Step 4: Verify files exist**

```bash
ls -la /Users/feichen/RunPulse/RunPulse/Resources/Assets.xcassets/AppIcon.appiconset/
ls -la /Users/feichen/RunPulse/RunPulseWatch/Resources/Assets.xcassets/AppIcon.appiconset/
```
Expected: Both directories contain `AppIcon-1024.png` and `Contents.json`

- [ ] **Step 5: Commit**

```bash
cd /Users/feichen/RunPulse
git add scripts/generate_icons.py RunPulse/Resources/Assets.xcassets/ RunPulseWatch/Resources/Assets.xcassets/
git commit -m "feat: add app icons for iOS and Watch targets"
```

---

### Task 14: Build both targets to verify icons are recognized

- [ ] **Step 1: Build iOS target**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```
Expected: BUILD SUCCEEDED, no asset catalog warnings

- [ ] **Step 2: Build Watch target**

```bash
cd /Users/feichen/RunPulse
xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -quiet
```
Expected: BUILD SUCCEEDED, no asset catalog warnings

---

### Task 15: Final verification — run all tests

- [ ] **Step 1: Run all iOS tests**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(Executed|TEST)"
```
Expected: All tests pass

- [ ] **Step 2: Run all watchOS tests**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' 2>&1 | grep -E "(Executed|TEST)"
```
Expected: All tests pass
