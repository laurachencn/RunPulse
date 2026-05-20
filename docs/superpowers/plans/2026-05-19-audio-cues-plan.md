# Audio Cues Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add configurable periodic audio announcements during runs with Watch quick toggles and iOS full settings.

**Architecture:** New `AudioCueConfig` model (shared), `AudioCueManager` service (Watch), UI on both platforms. Settings sync via WCSession. Builds on existing `VoiceService`.

**Tech Stack:** Swift 5.9, SwiftUI, WatchKit, WatchConnectivity, AVFoundation (VoiceService), UserDefaults

---

## File Map

| File | Platform | Responsibility |
|------|----------|---------------|
| `RunPulse/Models/AudioCueConfig.swift` | Shared (iOS + Watch) | Codable config model with defaults, enums for intervals |
| `RunPulseWatch/Services/AudioCueManager.swift` | Watch | Monitors run metrics, fires cues at configured intervals |
| `RunPulseWatch/Views/AudioCueSettingsView.swift` | Watch | Quick toggle UI for audio cue configuration |
| `RunPulse/Views/AudioCuesSection.swift` | iOS | Settings section with full configuration UI |
| `RunPulseTests/AudioCueConfigTests.swift` | iOS test | Model encoding/decoding, defaults, enum tests |
| `RunPulseTests/AudioCueManagerTests.swift` | iOS test (Watch target) | Cue scheduling, trigger logic, metric collection |
| `RunPulse/Services/WatchSessionManager.swift` | iOS | Modified: add `sendAudioCueConfig()` method |
| `RunPulseWatch/Services/WatchConnectivityManager.swift` | Watch | Modified: handle incoming audio cue config |
| `RunPulseWatch/Services/WorkoutManager.swift` | Watch | Modified: integrate AudioCueManager into run loop |
| `RunPulseWatch/Views/RunView.swift` | Watch | Modified: add link to AudioCueSettingsView |
| `RunPulse/Views/SettingsView.swift` | iOS | Modified: add AudioCuesSection |
| `project.yml` | Build | Add new source and test files |

---

### Task 1: AudioCueConfig Model

**Files:**
- Create: `RunPulse/Models/AudioCueConfig.swift`
- Test: `RunPulseTests/AudioCueConfigTests.swift`
- Modify: `project.yml` (add model + test files)

- [ ] **Step 1.1: Add test file to project.yml**

Add `RunPulseTests/AudioCueConfigTests.swift` to the `RunPulseTests` sources list in `project.yml`. Find the `RunPulseTests` target and add the line:

```yaml
  RunPulseTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - RunPulseTests/HealthKitManagerTests.swift
      - RunPulseTests/WatchSessionManagerTests.swift
      - RunPulseTests/RunSessionTests.swift
      - RunPulseTests/StorageManagerTests.swift
      - RunPulseTests/AudioCueConfigTests.swift    # ADD THIS LINE
```

- [ ] **Step 1.2: Write the failing test**

Create `RunPulseTests/AudioCueConfigTests.swift`:

```swift
import XCTest
@testable import RunPulse

@MainActor
final class AudioCueConfigTests: XCTestCase {
    
    func testDefaultConfig() {
        let config = AudioCueConfig.default
        XCTAssertTrue(config.voiceEnabled)
        XCTAssertTrue(config.announcePace)
        XCTAssertTrue(config.announceHeartRate)
        XCTAssertTrue(config.announceDistance)
        XCTAssertFalse(config.announceCalories)
        XCTAssertEqual(config.distanceInterval, .km1)
        XCTAssertEqual(config.timeInterval, .off)
    }
    
    func testAudioCueConfigCodable() {
        var config = AudioCueConfig.default
        config.announceCalories = true
        config.distanceInterval = .km2
        config.timeInterval = .min5
        
        let data = try! JSONEncoder().encode(config)
        let decoded = try! JSONDecoder().decode(AudioCueConfig.self, from: data)
        
        XCTAssertEqual(decoded.announcePace, true)
        XCTAssertEqual(decoded.announceHeartRate, true)
        XCTAssertEqual(decoded.announceDistance, true)
        XCTAssertEqual(decoded.announceCalories, true)
        XCTAssertEqual(decoded.distanceInterval, .km2)
        XCTAssertEqual(decoded.timeInterval, .min5)
    }
    
    func testDistanceIntervalRawValues() {
        XCTAssertEqual(DistanceInterval.kmHalf.rawValue, 0.5)
        XCTAssertEqual(DistanceInterval.km1.rawValue, 1.0)
        XCTAssertEqual(DistanceInterval.km2.rawValue, 2.0)
        XCTAssertEqual(DistanceInterval.km5.rawValue, 5.0)
    }
    
    func testTimeIntervalRawValues() {
        XCTAssertEqual(TimeIntervalInterval.off.rawValue, 0)
        XCTAssertEqual(TimeIntervalInterval.min1.rawValue, 60)
        XCTAssertEqual(TimeIntervalInterval.min5.rawValue, 300)
        XCTAssertEqual(TimeIntervalInterval.min10.rawValue, 600)
        XCTAssertEqual(TimeIntervalInterval.min15.rawValue, 900)
    }
}
```

- [ ] **Step 1.3: Regenerate project and run test to verify it fails**

```bash
xcodegen generate && xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RunPulseTests/AudioCueConfigTests -quiet
```

Expected: FAIL with "AudioCueConfig not defined"

- [ ] **Step 1.4: Implement AudioCueConfig model**

Create `RunPulse/Models/AudioCueConfig.swift`:

```swift
import Foundation

enum DistanceInterval: Double, Codable, CaseIterable {
    case kmHalf = 0.5
    case km1 = 1.0
    case km2 = 2.0
    case km5 = 5.0
    
    var displayString: String {
        switch self {
        case .kmHalf: return "0.5 km"
        case .km1: return "1 km"
        case .km2: return "2 km"
        case .km5: return "5 km"
        }
    }
}

enum TimeIntervalInterval: Int, Codable, CaseIterable {
    case off = 0
    case min1 = 60
    case min5 = 300
    case min10 = 600
    case min15 = 900
    
    var displayString: String {
        switch self {
        case .off: return "Off"
        case .min1: return "1 min"
        case .min5: return "5 min"
        case .min10: return "10 min"
        case .min15: return "15 min"
        }
    }
}

struct AudioCueConfig: Codable, Equatable {
    var voiceEnabled: Bool
    var announcePace: Bool
    var announceHeartRate: Bool
    var announceDistance: Bool
    var announceCalories: Bool
    var distanceInterval: DistanceInterval
    var timeInterval: TimeIntervalInterval
    
    static let `default` = AudioCueConfig(
        voiceEnabled: true,
        announcePace: true,
        announceHeartRate: true,
        announceDistance: true,
        announceCalories: false,
        distanceInterval: .km1,
        timeInterval: .off
    )
}
```

- [ ] **Step 1.5: Run test to verify it passes**

```bash
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RunPulseTests/AudioCueConfigTests -quiet
```

Expected: PASS all 4 tests

- [ ] **Step 1.6: Commit**

```bash
git add RunPulse/Models/AudioCueConfig.swift RunPulseTests/AudioCueConfigTests.swift project.yml
git commit -m "feat(audio-cues): add AudioCueConfig model with enums and defaults"
```

---

### Task 2: AudioCueManager Service

**Files:**
- Create: `RunPulseWatch/Services/AudioCueManager.swift`
- Test: `RunPulseTests/AudioCueManagerTests.swift`
- Modify: `project.yml` (add test to Watch target)

- [ ] **Step 2.1: Add test file to project.yml Watch target**

Find the `RunPulseWatchTests` target in `project.yml` and add:

```yaml
  RunPulseWatchTests:
    type: bundle.unit-test
    platform: watchOS
    sources:
      - RunPulseTests/WorkoutManagerTests.swift
      - RunPulseTests/HeartRateMonitorTests.swift
      - RunPulseTests/PaceTrackerTests.swift
      - RunPulseTests/AlertEngineTests.swift
      - RunPulseTests/IntegrationTests.swift
      - RunPulseTests/WatchRunStateTests.swift
      - RunPulseTests/VoiceServiceTests.swift
      - RunPulseTests/AudioCueManagerTests.swift    # ADD THIS LINE
```

- [ ] **Step 2.2: Write the failing test**

Create `RunPulseTests/AudioCueManagerTests.swift`:

```swift
import XCTest
@testable import RunPulseWatch

@MainActor
final class AudioCueManagerTests: XCTestCase {
    
    var manager: AudioCueManager!
    var config: AudioCueConfig!
    
    override func setUp() {
        super.setUp()
        config = AudioCueConfig.default
        manager = AudioCueManager(config: config)
    }
    
    func testInitialState() {
        XCTAssertEqual(manager.totalDistanceAnnounced, 0)
        XCTAssertEqual(manager.lastTimeAnnouncement, nil)
    }
    
    func testNoCueWhenVoiceDisabled() {
        config.voiceEnabled = false
        manager.config = config
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
    
    func testDistanceCueAtFirstKilometer() {
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        XCTAssertEqual(manager.pendingCues.count, 1)
        XCTAssertTrue(manager.pendingCues.first?.contains("1 kilometer") == true)
    }
    
    func testDistanceCueAtSecondKilometer() {
        // First km
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        _ = manager.pendingCues
        manager.resetCues()
        
        // Second km
        manager.updateMetrics(
            distance: 2000,
            pace: 310,
            heartRate: 155,
            calories: 200,
            currentTime: Date()
        )
        XCTAssertEqual(manager.pendingCues.count, 1)
        XCTAssertTrue(manager.pendingCues.first?.contains("2 kilometers") == true)
    }
    
    func testNoDistanceCueBeforeInterval() {
        manager.updateMetrics(
            distance: 500,
            pace: 300,
            heartRate: 150,
            calories: 50,
            currentTime: Date()
        )
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
    
    func testTimeCueAtInterval() {
        config.timeInterval = .min5
        manager.config = config
        
        let startTime = Date()
        let fiveMinutesLater = startTime.addingTimeInterval(300)
        
        manager.updateMetrics(
            distance: 500,
            pace: 300,
            heartRate: 150,
            calories: 50,
            currentTime: fiveMinutesLater
        )
        XCTAssertEqual(manager.pendingCues.count, 1)
    }
    
    func testNoTimeCueWhenOff() {
        config.timeInterval = .off
        manager.config = config
        
        let startTime = Date()
        let tenMinutesLater = startTime.addingTimeInterval(600)
        
        manager.updateMetrics(
            distance: 500,
            pace: 300,
            heartRate: 150,
            calories: 50,
            currentTime: tenMinutesLater
        )
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
    
    func testMultipleCuesWhenBothIntervalsFire() {
        config.timeInterval = .min5
        manager.config = config
        
        let startTime = Date()
        let fiveMinutesLater = startTime.addingTimeInterval(300)
        
        // At exactly 1km AND 5 minutes — both should fire
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: fiveMinutesLater
        )
        XCTAssertGreaterThanOrEqual(manager.pendingCues.count, 2)
    }
    
    func testCueContainsEnabledMetrics() {
        config.announceCalories = true
        manager.config = config
        
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        let cue = manager.pendingCues.first ?? ""
        XCTAssertTrue(cue.contains("pace"))
        XCTAssertTrue(cue.contains("heart rate"))
        XCTAssertTrue(cue.contains("calories"))
    }
    
    func testCueExcludesDisabledMetrics() {
        config.announcePace = false
        manager.config = config
        
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        let cue = manager.pendingCues.first ?? ""
        XCTAssertFalse(cue.contains("pace"))
    }
    
    func testResetClearsAnnouncedState() {
        manager.updateMetrics(
            distance: 1000,
            pace: 300,
            heartRate: 150,
            calories: 100,
            currentTime: Date()
        )
        manager.reset()
        XCTAssertEqual(manager.totalDistanceAnnounced, 0)
        XCTAssertEqual(manager.lastTimeAnnouncement, nil)
        XCTAssertTrue(manager.pendingCues.isEmpty)
    }
}
```

- [ ] **Step 2.3: Run test to verify it fails**

```bash
xcodegen generate && xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RunPulseTests/AudioCueManagerTests -quiet
```

Expected: FAIL with "AudioCueManager not defined"

- [ ] **Step 2.4: Implement AudioCueManager**

Create `RunPulseWatch/Services/AudioCueManager.swift`:

```swift
import Foundation

@MainActor
final class AudioCueManager: ObservableObject {
    @Published var pendingCues: [String] = []
    
    var config: AudioCueConfig
    
    private(set) var totalDistanceAnnounced: Double = 0
    private(set) var lastTimeAnnouncement: Date?
    
    private var lastKnownDistance: Double = 0
    private var lastKnownPace: TimeInterval = 0
    private var lastKnownHeartRate: Double = 0
    private var lastKnownCalories: Double = 0
    
    init(config: AudioCueConfig) {
        self.config = config
    }
    
    func updateMetrics(
        distance: Double,
        pace: TimeInterval,
        heartRate: Double,
        calories: Double,
        currentTime: Date
    ) {
        guard config.voiceEnabled else {
            pendingCues = []
            return
        }
        
        pendingCues = []
        
        let distanceIntervalMeters = config.distanceInterval.rawValue * 1000.0
        if distance >= totalDistanceAnnounced + distanceIntervalMeters {
            let kmAnnounced = (totalDistanceAnnounced + distanceIntervalMeters) / 1000.0
            let cue = buildCue(
                distance: distance,
                pace: pace,
                heartRate: heartRate,
                calories: calories,
                distanceText: formatDistanceAnnouncement(kmAnnounced)
            )
            pendingCues.append(cue)
            totalDistanceAnnounced += distanceIntervalMeters
        }
        
        if config.timeInterval != .off {
            let intervalSeconds = TimeInterval(config.timeInterval.rawValue)
            if let lastAnnouncement = lastTimeAnnouncement {
                if currentTime.timeIntervalSince(lastAnnouncement) >= intervalSeconds {
                    let cue = buildCue(
                        distance: distance,
                        pace: pace,
                        heartRate: heartRate,
                        calories: calories,
                        distanceText: nil
                    )
                    pendingCues.append(cue)
                    lastTimeAnnouncement = currentTime
                }
            } else {
                // First time check — need a reference point
                lastTimeAnnouncement = currentTime
            }
        }
        
        lastKnownDistance = distance
        lastKnownPace = pace
        lastKnownHeartRate = heartRate
        lastKnownCalories = calories
    }
    
    func resetCues() {
        pendingCues = []
    }
    
    func reset() {
        totalDistanceAnnounced = 0
        lastTimeAnnouncement = nil
        pendingCues = []
    }
    
    private func buildCue(
        distance: Double,
        pace: TimeInterval,
        heartRate: Double,
        calories: Double,
        distanceText: String?
    ) -> String {
        var parts: [String] = []
        
        if let distanceText = distanceText {
            parts.append(distanceText)
        }
        
        if config.announcePace {
            parts.append("Your pace is \(formatPace(pace)) per kilometer")
        }
        
        if config.announceHeartRate {
            parts.append("Your heart rate is \(Int(heartRate)) beats per minute")
        }
        
        if config.announceCalories {
            parts.append("You've burned \(Int(calories)) calories")
        }
        
        return parts.joined(separator: ". ")
    }
    
    private func formatDistanceAnnouncement(_ km: Double) -> String {
        if km == 1.0 {
            return "You've run 1 kilometer"
        }
        return "You've run \(Int(km)) kilometers"
    }
    
    private func formatPace(_ pace: TimeInterval) -> String {
        guard pace > 0 else { return "not available" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        if minutes > 0 {
            return "\(minutes) minutes \(seconds) seconds"
        }
        return "\(seconds) seconds"
    }
}
```

- [ ] **Step 2.5: Run test to verify it passes**

```bash
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RunPulseTests/AudioCueManagerTests -quiet
```

Expected: PASS all 11 tests

- [ ] **Step 2.6: Commit**

```bash
git add RunPulseWatch/Services/AudioCueManager.swift RunPulseTests/AudioCueManagerTests.swift project.yml
git commit -m "feat(audio-cues): add AudioCueManager with distance and time interval triggers"
```

---

### Task 3: Watch Audio Cue Settings UI

**Files:**
- Create: `RunPulseWatch/Views/AudioCueSettingsView.swift`
- Modify: `project.yml` (add view to Watch sources — auto-included via directory)

- [ ] **Step 3.1: Create the Watch settings view**

Create `RunPulseWatch/Views/AudioCueSettingsView.swift`:

```swift
import SwiftUI

struct AudioCueSettingsView: View {
    @AppStorage("audioCueVoiceEnabled") private var voiceEnabled = AudioCueConfig.default.voiceEnabled
    @AppStorage("audioCueAnnouncePace") private var announcePace = AudioCueConfig.default.announcePace
    @AppStorage("audioCueAnnounceHR") private var announceHR = AudioCueConfig.default.announceHeartRate
    @AppStorage("audioCueAnnounceDistance") private var announceDistance = AudioCueConfig.default.announceDistance
    @AppStorage("audioCueAnnounceCalories") private var announceCalories = AudioCueConfig.default.announceCalories
    @AppStorage("audioCueDistanceInterval") private var distanceIntervalRaw = AudioCueConfig.default.distanceInterval.rawValue
    @AppStorage("audioCueTimeInterval") private var timeIntervalRaw = AudioCueConfig.default.timeInterval.rawValue
    
    var distanceInterval: DistanceInterval {
        get { DistanceInterval(rawValue: distanceIntervalRaw) ?? .km1 }
        set { distanceIntervalRaw = newValue.rawValue }
    }
    
    var timeInterval: TimeIntervalInterval {
        get { TimeIntervalInterval(rawValue: timeIntervalRaw) ?? .off }
        set { timeIntervalRaw = newValue.rawValue }
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Voice Cues", isOn: $voiceEnabled)
            }
            
            Section("Announcements") {
                Toggle("Pace", isOn: $announcePace)
                Toggle("Heart Rate", isOn: $announceHR)
                Toggle("Distance", isOn: $announceDistance)
                Toggle("Calories", isOn: $announceCalories)
            }
            
            Section("Frequency") {
                Picker("Distance", selection: $distanceInterval) {
                    ForEach(DistanceInterval.allCases, id: \.self) { interval in
                        Text(interval.displayString).tag(interval)
                    }
                }
                
                Picker("Time", selection: $timeInterval) {
                    ForEach(TimeIntervalInterval.allCases, id: \.self) { interval in
                        Text(interval.displayString).tag(interval)
                    }
                }
            }
        }
        .navigationTitle("Audio Cues")
    }
}

#Preview {
    AudioCueSettingsView()
}
```

- [ ] **Step 3.2: Regenerate project and build to verify compilation**

```bash
xcodegen generate && xcodebuild build -scheme RunPulseWatch -destination 'generic/platform=watchOS' -quiet
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3.3: Commit**

```bash
git add RunPulseWatch/Views/AudioCueSettingsView.swift
git commit -m "feat(audio-cues): add Watch AudioCueSettingsView with toggles and pickers"
```

---

### Task 4: iOS Audio Cues Settings Section

**Files:**
- Create: `RunPulse/Views/AudioCuesSection.swift`
- Modify: `RunPulse/Views/SettingsView.swift`

- [ ] **Step 4.1: Create the iOS settings section**

Create `RunPulse/Views/AudioCuesSection.swift`:

```swift
import SwiftUI

struct AudioCuesSection: View {
    @AppStorage("audioCueVoiceEnabled") private var voiceEnabled = AudioCueConfig.default.voiceEnabled
    @AppStorage("audioCueAnnouncePace") private var announcePace = AudioCueConfig.default.announcePace
    @AppStorage("audioCueAnnounceHR") private var announceHR = AudioCueConfig.default.announceHeartRate
    @AppStorage("audioCueAnnounceDistance") private var announceDistance = AudioCueConfig.default.announceDistance
    @AppStorage("audioCueAnnounceCalories") private var announceCalories = AudioCueConfig.default.announceCalories
    @AppStorage("audioCueDistanceInterval") private var distanceIntervalRaw = AudioCueConfig.default.distanceInterval.rawValue
    @AppStorage("audioCueTimeInterval") private var timeIntervalRaw = AudioCueConfig.default.timeInterval.rawValue
    
    var distanceInterval: DistanceInterval {
        get { DistanceInterval(rawValue: distanceIntervalRaw) ?? .km1 }
        set { distanceIntervalRaw = newValue.rawValue }
    }
    
    var timeInterval: TimeIntervalInterval {
        get { TimeIntervalInterval(rawValue: timeIntervalRaw) ?? .off }
        set { timeIntervalRaw = newValue.rawValue }
    }
    
    var body: some View {
        Section(header: Text("Audio Cues")) {
            Toggle("Enable Audio Cues", isOn: $voiceEnabled)
            Text("Spoken announcements during runs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Section(header: Text("Announcement Types")) {
            Toggle("Pace", isOn: $announcePace)
            Text("Announce current pace")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Heart Rate", isOn: $announceHR)
            Text("Announce current heart rate")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Distance Milestones", isOn: $announceDistance)
            Text("Announce at distance intervals")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("Calories", isOn: $announceCalories)
            Text("Announce calories burned")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Section(header: Text("Announcement Frequency")) {
            Picker("Distance Interval", selection: $distanceInterval) {
                ForEach(DistanceInterval.allCases, id: \.self) { interval in
                    Text(interval.displayString).tag(interval)
                }
            }
            
            Picker("Time Interval", selection: $timeInterval) {
                ForEach(TimeIntervalInterval.allCases, id: \.self) { interval in
                    Text(interval.displayString).tag(interval)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            AudioCuesSection()
        }
    }
}
```

- [ ] **Step 4.2: Integrate into SettingsView**

Modify `RunPulse/Views/SettingsView.swift`. Add the `AudioCuesSection` before the "About" section:

```swift
            Section(header: Text("Notifications")) {
                Toggle("Voice Feedback", isOn: $voiceEnabled)
                Text("Spoken alerts and post-run summaries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            AudioCuesSection()    // ADD THIS LINE

            Section(header: Text("About")) {
```

- [ ] **Step 4.3: Build to verify compilation**

```bash
xcodegen generate && xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4.4: Commit**

```bash
git add RunPulse/Views/AudioCuesSection.swift RunPulse/Views/SettingsView.swift
git commit -m "feat(audio-cues): add iOS AudioCuesSection and integrate into SettingsView"
```

---

### Task 5: WCSession Sync for Audio Cue Config

**Files:**
- Modify: `RunPulse/Services/WatchSessionManager.swift`
- Modify: `RunPulseWatch/Services/WatchConnectivityManager.swift`

- [ ] **Step 5.1: Add send method to WatchSessionManager**

Add this method to `WatchSessionManager.swift` (after `sendSettingsUpdate`):

```swift
    func sendAudioCueConfig(_ config: AudioCueConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            let message: [String: Any] = ["audioCueConfig": data]
            sendToWatch(message)
        } catch {
            print("Failed to encode audio cue config: \(error)")
        }
    }
```

- [ ] **Step 5.2: Add config sync trigger to SettingsView onChange**

In `SettingsView.swift`, add an `onChange` handler for the audio cue settings. Add this after the existing `onChange(of: alertThreshold)`:

```swift
        .onChange(of: audioCueConfigHash) { _, _ in
            let config = buildAudioCueConfig()
            WatchSessionManager.shared.sendAudioCueConfig(config)
        }
```

Add these computed properties to `SettingsView` (before `var body`):

```swift
    private var audioCueConfigHash: String {
        "\(voiceEnabled)-\(announcePace)-\(announceHR)-\(announceDistance)-\(announceCalories)-\(distanceIntervalRaw)-\(timeIntervalRaw)"
    }
    
    private func buildAudioCueConfig() -> AudioCueConfig {
        AudioCueConfig(
            voiceEnabled: voiceEnabled,
            announcePace: announcePace,
            announceHeartRate: announceHR,
            announceDistance: announceDistance,
            announceCalories: announceCalories,
            distanceInterval: DistanceInterval(rawValue: distanceIntervalRaw) ?? .km1,
            timeInterval: TimeIntervalInterval(rawValue: timeIntervalRaw) ?? .off
        )
    }
```

Also add the `@AppStorage` keys to SettingsView's property declarations (add after existing `@AppStorage` lines):

```swift
    @AppStorage("audioCueVoiceEnabled") private var voiceEnabled: Bool = AudioCueConfig.default.voiceEnabled
    @AppStorage("audioCueAnnouncePace") private var announcePace: Bool = AudioCueConfig.default.announcePace
    @AppStorage("audioCueAnnounceHR") private var announceHR: Bool = AudioCueConfig.default.announceHeartRate
    @AppStorage("audioCueAnnounceDistance") private var announceDistance: Bool = AudioCueConfig.default.announceDistance
    @AppStorage("audioCueAnnounceCalories") private var announceCalories: Bool = AudioCueConfig.default.announceCalories
    @AppStorage("audioCueDistanceInterval") private var distanceIntervalRaw: Double = AudioCueConfig.default.distanceInterval.rawValue
    @AppStorage("audioCueTimeInterval") private var timeIntervalRaw: Int = AudioCueConfig.default.timeInterval.rawValue
```

Note: `voiceEnabled` is already used for Phase 1 voice feedback. The `audioCueVoiceEnabled` key is separate — Phase 1's `voiceEnabled` controls the master voice toggle, while `audioCueVoiceEnabled` controls periodic cues. In practice they should share the same key. **Use the existing `voiceEnabled` key for the master toggle** and add `audioCueVoiceEnabled` only if you want independent control. For simplicity, share the key: change `@AppStorage("audioCueVoiceEnabled")` to use the existing `voiceEnabled` property.

- [ ] **Step 5.3: Handle incoming config on Watch side**

Read `RunPulseWatch/Services/WatchConnectivityManager.swift` to understand the current message handling pattern. Then add handling for `audioCueConfig` in the `didReceiveMessage` delegate method:

```swift
            if let audioCueConfigData = message["audioCueConfig"] as? Data {
                do {
                    let config = try JSONDecoder().decode(AudioCueConfig.self, from: audioCueConfigData)
                    UserDefaults.standard.set(config.voiceEnabled, forKey: "audioCueVoiceEnabled")
                    UserDefaults.standard.set(config.announcePace, forKey: "audioCueAnnouncePace")
                    UserDefaults.standard.set(config.announceHeartRate, forKey: "audioCueAnnounceHR")
                    UserDefaults.standard.set(config.announceDistance, forKey: "audioCueAnnounceDistance")
                    UserDefaults.standard.set(config.announceCalories, forKey: "audioCueAnnounceCalories")
                    UserDefaults.standard.set(config.distanceInterval.rawValue, forKey: "audioCueDistanceInterval")
                    UserDefaults.standard.set(config.timeInterval.rawValue, forKey: "audioCueTimeInterval")
                } catch {
                    print("Failed to decode audio cue config: \(error)")
                }
            }
```

- [ ] **Step 5.4: Build both targets to verify**

```bash
xcodegen generate && xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -quiet && xcodebuild build -scheme RunPulseWatch -destination 'generic/platform=watchOS' -quiet
```

Expected: BUILD SUCCEEDED for both

- [ ] **Step 5.5: Commit**

```bash
git add RunPulse/Services/WatchSessionManager.swift RunPulse/Views/SettingsView.swift RunPulseWatch/Services/WatchConnectivityManager.swift
git commit -m "feat(audio-cues): sync AudioCueConfig via WCSession between iOS and Watch"
```

---

### Task 6: Integrate AudioCueManager into WorkoutManager

**Files:**
- Modify: `RunPulseWatch/Services/WorkoutManager.swift`
- Modify: `RunPulseWatch/Views/RunView.swift`

- [ ] **Step 6.1: Add AudioCueManager to WorkoutManager**

Add this property to `WorkoutManager.swift` (after the existing properties):

```swift
    private var audioCueManager: AudioCueManager?
```

In `startWorkout()`, initialize the audio cue manager. Add this inside the `if success` block after `self.startTimer()`:

```swift
                        let config = self.loadAudioCueConfig()
                        self.audioCueManager = AudioCueManager(config: config)
```

Add the `loadAudioCueConfig` helper method to `WorkoutManager`:

```swift
    private func loadAudioCueConfig() -> AudioCueConfig {
        let voiceEnabled = UserDefaults.standard.object(forKey: "audioCueVoiceEnabled") as? Bool ?? AudioCueConfig.default.voiceEnabled
        let announcePace = UserDefaults.standard.object(forKey: "audioCueAnnouncePace") as? Bool ?? AudioCueConfig.default.announcePace
        let announceHR = UserDefaults.standard.object(forKey: "audioCueAnnounceHR") as? Bool ?? AudioCueConfig.default.announceHeartRate
        let announceDistance = UserDefaults.standard.object(forKey: "audioCueAnnounceDistance") as? Bool ?? AudioCueConfig.default.announceDistance
        let announceCalories = UserDefaults.standard.object(forKey: "audioCueAnnounceCalories") as? Bool ?? AudioCueConfig.default.announceCalories
        let distRaw = UserDefaults.standard.double(forKey: "audioCueDistanceInterval")
        let distInterval = DistanceInterval(rawValue: distRaw) ?? AudioCueConfig.default.distanceInterval
        let timeRaw = UserDefaults.standard.integer(forKey: "audioCueTimeInterval")
        let timeInterval = TimeIntervalInterval(rawValue: timeRaw) ?? AudioCueConfig.default.timeInterval
        
        return AudioCueConfig(
            voiceEnabled: voiceEnabled,
            announcePace: announcePace,
            announceHeartRate: announceHR,
            announceDistance: announceDistance,
            announceCalories: announceCalories,
            distanceInterval: distInterval,
            timeInterval: timeInterval
        )
    }
```

In `endWorkout()`, reset the audio cue manager. Add before `currentSession = session`:

```swift
        audioCueManager?.reset()
```

- [ ] **Step 6.2: Fire audio cues in the run loop**

The `updateDuration()` method is called every second by the timer. This is where we check for audio cues. Modify `updateDuration()` to:

```swift
    private func updateDuration() {
        guard let startTime = startDate else { return }
        runState.currentDuration = Date().timeIntervalSince(startTime)
        
        // Check audio cues
        if let audioCueManager = audioCueManager {
            audioCueManager.updateMetrics(
                distance: totalDistance,
                pace: runState.currentPace,
                heartRate: currentHeartRate,
                calories: runState.totalCalories,
                currentTime: Date()
            )
            
            for cue in audioCueManager.pendingCues {
                guard !VoiceService.shared.isSpeaking else { break }
                Task {
                    await VoiceService.shared.speak(cue)
                }
            }
            audioCueManager.resetCues()
        }
    }
```

- [ ] **Step 6.3: Add settings link to RunView**

In `RunView.swift`, add a navigation link to the audio cue settings on the start screen. Modify `startScreen` to include a settings button:

```swift
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
```

Note: RunView needs to be inside a NavigationStack for NavigationLink to work. If RunView is not already wrapped, wrap it in the Watch app's main view. Check `RunPulseWatch/RunPulseWatchApp.swift` and ensure the root view uses `NavigationStack`.

- [ ] **Step 6.4: Build both targets**

```bash
xcodegen generate && xcodebuild build -scheme RunPulseWatch -destination 'generic/platform=watchOS' -quiet
```

Expected: BUILD SUCCEEDED

- [ ] **Step 6.5: Run all tests**

```bash
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
```

Expected: ALL TESTS PASS

- [ ] **Step 6.6: Commit**

```bash
git add RunPulseWatch/Services/WorkoutManager.swift RunPulseWatch/Views/RunView.swift
git commit -m "feat(audio-cues): integrate AudioCueManager into workout run loop and add settings link"
```

---

### Task 7: Final Verification & Polish

**Files:** All modified files

- [ ] **Step 7.1: Run full test suite**

```bash
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
```

Expected: ALL TESTS PASS (including AudioCueConfigTests and AudioCueManagerTests)

- [ ] **Step 7.2: Build both targets for release**

```bash
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -configuration Release -quiet && xcodebuild build -scheme RunPulseWatch -destination 'generic/platform=watchOS' -configuration Release -quiet
```

Expected: BUILD SUCCEEDED for both

- [ ] **Step 7.3: Commit final state**

```bash
git add -A
git commit -m "feat(audio-cues): final verification and polish"
```

---

## Summary of Changes

| Task | Files Created | Files Modified | Tests |
|------|--------------|----------------|-------|
| 1 | `AudioCueConfig.swift` | `project.yml` | `AudioCueConfigTests.swift` |
| 2 | `AudioCueManager.swift` | `project.yml` | `AudioCueManagerTests.swift` |
| 3 | `AudioCueSettingsView.swift` | — | — |
| 4 | `AudioCuesSection.swift` | `SettingsView.swift` | — |
| 5 | — | `WatchSessionManager.swift`, `WatchConnectivityManager.swift`, `SettingsView.swift` | — |
| 6 | — | `WorkoutManager.swift`, `RunView.swift` | — |
| 7 | — | — | Full test suite |
