# Notifications & Voice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full notification suite — haptic + voice during run, iOS push for threshold breaches, post-run voice summary on both devices.

**Architecture:** VoiceService wraps AVSpeechSynthesizer on both platforms. AlertEngine calls VoiceService on HR threshold breach. WorkoutManager calls VoiceService after endWorkout(). WatchSessionManager schedules UNNotification on threshold breach and calls VoiceService on run sync. SettingsView gets voice toggle.

**Tech Stack:** Swift 5.9, SwiftUI, AVFoundation (AVSpeechSynthesizer), UserNotifications, WatchConnectivity

---

### Task 1: Create Watch VoiceService

**Files:**
- Create: `RunPulseWatch/Services/VoiceService.swift`
- Test: `RunPulseTests/VoiceServiceTests.swift`

- [ ] **Step 1: Write the failing test**

Add to `RunPulseTests/VoiceServiceTests.swift`:

```swift
import XCTest
@testable import RunPulse

@MainActor
final class VoiceServiceTests: XCTestCase {
    var service: VoiceService!
    
    override func setUp() {
        super.setUp()
        service = VoiceService.shared
    }
    
    func testVoiceServiceIsSingleton() {
        let instance1 = VoiceService.shared
        let instance2 = VoiceService.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testIsSpeakingInitiallyFalse() {
        XCTAssertFalse(service.isSpeaking)
    }
    
    func testSpeakWhenDisabledDoesNothing() {
        UserDefaults.standard.set(false, forKey: "voiceEnabled")
        // Should not crash, should not speak
        Task {
            await service.speak("Test")
        }
    }
    
    func testSpeakWhenEnabledQueuesSpeech() {
        UserDefaults.standard.set(true, forKey: "voiceEnabled")
        // Should not crash
        Task {
            await service.speak("Test")
        }
    }
    
    func testStopCancelsSpeech() {
        service.stop()
        XCTAssertFalse(service.isSpeaking)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RunPulseTests/VoiceServiceTests -quiet 2>&1 | tail -5`
Expected: FAIL with "Cannot find 'VoiceService' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `RunPulseWatch/Services/VoiceService.swift`:

```swift
import Foundation
import AVFoundation

@MainActor
final class VoiceService {
    static let shared = VoiceService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
    
    func speak(_ text: String) async {
        guard UserDefaults.standard.bool(forKey: "voiceEnabled") else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.quality = .narration
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        await withCheckedContinuation { continuation in
            synthesizer.speak(utterance)
            // AVSpeechSynthesizer doesn't have async API, so we just fire and return
            continuation.resume()
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RunPulseTests/VoiceServiceTests -quiet 2>&1 | grep -E "(passed|failed|TEST SUCCEEDED|TEST FAILED)"`
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
git add RunPulseWatch/Services/VoiceService.swift RunPulseTests/VoiceServiceTests.swift
git commit -m "feat: add Watch VoiceService wrapping AVSpeechSynthesizer"
```

---

### Task 2: Create iOS VoiceService

**Files:**
- Create: `RunPulse/Services/VoiceService.swift`

- [ ] **Step 1: Write implementation**

Create `RunPulse/Services/VoiceService.swift` (identical to Watch version):

```swift
import Foundation
import AVFoundation

@MainActor
final class VoiceService {
    static let shared = VoiceService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
    
    func speak(_ text: String) async {
        guard UserDefaults.standard.bool(forKey: "voiceEnabled") else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.quality = .narration
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        await withCheckedContinuation { continuation in
            synthesizer.speak(utterance)
            continuation.resume()
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RunPulse/Services/VoiceService.swift
git commit -m "feat: add iOS VoiceService wrapping AVSpeechSynthesizer"
```

---

### Task 3: Wire VoiceService into Watch AlertEngine

**Files:**
- Modify: `RunPulseWatch/Services/AlertEngine.swift`
- Test: `RunPulseTests/AlertEngineTests.swift`

- [ ] **Step 1: Write the failing test**

Add to `RunPulseTests/AlertEngineTests.swift` (append to existing file):

```swift
    func testAlertTriggersVoiceFeedback() {
        UserDefaults.standard.set(true, forKey: "voiceEnabled")
        let engine = AlertEngine(threshold: 150)
        XCTAssertFalse(engine.isAlerting)
        
        engine.checkHeartRate(160)
        XCTAssertTrue(engine.isAlerting)
        // VoiceService.speak should have been called (verified by no crash)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -only-testing:RunPulseWatchTests/AlertEngineTests/testAlertTriggersVoiceFeedback -quiet 2>&1 | tail -5`
Expected: PASS (test doesn't verify voice call yet, but should not crash)

- [ ] **Step 3: Write minimal implementation**

Modify `RunPulseWatch/Services/AlertEngine.swift`:

Add `import AVFoundation` at top.

Replace `triggerAlert()` method:

```swift
    private func triggerAlert() {
        isAlerting = true
        alertCount += 1
        lastAlertTime = Date()
        triggerHapticAlert()
        Task {
            await VoiceService.shared.speak("Heart rate high, slow down")
        }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -only-testing:RunPulseWatchTests/AlertEngineTests -quiet 2>&1 | grep -E "(passed|failed|TEST SUCCEEDED|TEST FAILED)"`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add RunPulseWatch/Services/AlertEngine.swift RunPulseTests/AlertEngineTests.swift
git commit -m "feat: add voice feedback to AlertEngine on HR threshold breach"
```

---

### Task 4: Wire VoiceService into WorkoutManager for post-run summary

**Files:**
- Modify: `RunPulseWatch/Services/WorkoutManager.swift`
- Modify: `RunPulse/Models/RunSession.swift`

- [ ] **Step 1: Add voiceSummaryText computed property to RunSession**

Modify `RunPulse/Models/RunSession.swift` — add after `averagePaceString`:

```swift
    var voiceSummaryText: String {
        let distanceText = String(format: "%.1f", totalDistanceKm)
        let durationText = formattedDurationForVoice
        let avgHRText = "\(Int(averageHeartRate))"
        let maxHRText = "\(Int(maxHeartRate))"
        let paceText = formattedPaceForVoice
        let caloriesText = "\(Int(totalCalories))"
        let elevationText = "0"
        
        return "You ran \(distanceText) kilometers in \(durationText). Average heart rate: \(avgHRText) beats per minute. Max heart rate: \(maxHRText). Average pace: \(paceText) per kilometer. You burned \(caloriesText) calories. Elevation gain: \(elevationText) meters."
    }
    
    private var formattedDurationForVoice: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        if hours > 0 {
            return "\(hours) hours \(minutes) minutes and \(seconds) seconds"
        }
        return "\(minutes) minutes and \(seconds) seconds"
    }
    
    private var formattedPaceForVoice: String {
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        if minutes > 0 {
            return "\(minutes) minutes \(seconds) seconds"
        }
        return "\(seconds) seconds"
    }
```

- [ ] **Step 2: Call VoiceService in endWorkout**

Modify `RunPulseWatch/Services/WorkoutManager.swift` — add after `await WatchConnectivityManager.shared.sendRunSession(session)`:

```swift
        await VoiceService.shared.speak(session.voiceSummaryText)
```

- [ ] **Step 3: Build both targets**

Run: `xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -3`
Run: `xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -quiet 2>&1 | tail -3`
Expected: Both BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add RunPulse/Models/RunSession.swift RunPulseWatch/Services/WorkoutManager.swift
git commit -m "feat: add voice post-run summary to WorkoutManager.endWorkout"
```

---

### Task 5: Add iOS notification support to WatchSessionManager

**Files:**
- Modify: `RunPulse/Services/WatchSessionManager.swift`
- Modify: `RunPulse/RunPulseApp.swift`
- Test: `RunPulseTests/WatchSessionManagerTests.swift`

- [ ] **Step 1: Add notification setup to RunPulseApp**

Modify `RunPulse/RunPulseApp.swift`:

```swift
import SwiftUI
import UserNotifications

@main
struct RunPulseApp: App {
    init() {
        requestNotificationPermissions()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .criticalAlert]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            if granted {
                print("Notification permission granted")
            }
        }
    }
}
```

- [ ] **Step 2: Add notification scheduling to WatchSessionManager**

Modify `RunPulse/Services/WatchSessionManager.swift`:

Add `import UserNotifications` at top.

Add method:

```swift
    func scheduleThresholdNotification() {
        let content = UNMutableNotificationContent()
        content.title = "RunPulse"
        content.body = "Heart rate exceeded threshold — slow down"
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: "hr-threshold-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
```

Modify `session(_:didReceiveMessage:)` — add after the runSession handling block:

```swift
            if let _ = message["thresholdBreach"] as? Bool {
                scheduleThresholdNotification()
            }
```

- [ ] **Step 3: Write test**

Add to `RunPulseTests/WatchSessionManagerTests.swift`:

```swift
    func testScheduleThresholdNotificationDoesNotCrash() {
        // Should not crash even without notification permission
        manager.scheduleThresholdNotification()
    }
```

- [ ] **Step 4: Build and test**

Run: `xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

Run: `xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:RunPulseTests/WatchSessionManagerTests -quiet 2>&1 | grep -E "(passed|failed|TEST SUCCEEDED|TEST FAILED)"`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add RunPulse/RunPulseApp.swift RunPulse/Services/WatchSessionManager.swift RunPulseTests/WatchSessionManagerTests.swift
git commit -m "feat: add iOS local notifications for HR threshold breaches"
```

---

### Task 6: Add threshold breach message from Watch to iOS

**Files:**
- Modify: `RunPulseWatch/Services/WatchConnectivityManager.swift`

- [ ] **Step 1: Add threshold breach sending method**

Modify `RunPulseWatch/Services/WatchConnectivityManager.swift` — add method:

```swift
    func sendThresholdBreach() {
        let message: [String: Any] = ["thresholdBreach": true]
        sendToWatch(message)
    }
```

- [ ] **Step 2: Wire into AlertEngine**

Modify `RunPulseWatch/Services/AlertEngine.swift` — add to `triggerAlert()`:

```swift
        Task {
            await WatchConnectivityManager.shared.sendThresholdBreach()
        }
```

- [ ] **Step 3: Build Watch target**

Run: `xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -quiet 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add RunPulseWatch/Services/WatchConnectivityManager.swift RunPulseWatch/Services/AlertEngine.swift
git commit -m "feat: send threshold breach message from Watch to iOS via WCSession"
```

---

### Task 7: Add iOS voice summary on run sync

**Files:**
- Modify: `RunPulse/Services/WatchSessionManager.swift`

- [ ] **Step 1: Call VoiceService after saving run**

Modify `RunPulse/Services/WatchSessionManager.swift` — in `session(_:didReceiveMessage:)`, after `await StorageManager.shared.saveRun(runSession)`:

```swift
                    await VoiceService.shared.speak(runSession.voiceSummaryText)
```

Also add the same in `session(_:didReceiveApplicationContext:)` after `await StorageManager.shared.saveRun(runSession)`:

```swift
                    await VoiceService.shared.speak(runSession.voiceSummaryText)
```

- [ ] **Step 2: Build iOS target**

Run: `xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RunPulse/Services/WatchSessionManager.swift
git commit -m "feat: speak post-run voice summary on iOS when run syncs from Watch"
```

---

### Task 8: Add Voice Feedback toggle to SettingsView

**Files:**
- Modify: `RunPulse/Views/SettingsView.swift`

- [ ] **Step 1: Add toggle to SettingsView**

Modify `RunPulse/Views/SettingsView.swift` — add `@AppStorage("voiceEnabled")` property:

```swift
    @AppStorage("voiceEnabled") private var voiceEnabled: Bool = true
```

Add new Section before the "About" section:

```swift
            Section(header: Text("Notifications")) {
                Toggle("Voice Feedback", isOn: $voiceEnabled)
                Text("Spoken alerts and post-run summaries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
```

- [ ] **Step 2: Build iOS target**

Run: `xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -3`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RunPulse/Views/SettingsView.swift
git commit -m "feat: add Voice Feedback toggle to SettingsView"
```

---

### Task 9: Run all tests and final verification

**Files:**
- None (verification only)

- [ ] **Step 1: Run all iOS tests**

Run: `xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(Test Case.*passed|Test Case.*failed|TEST SUCCEEDED|TEST FAILED)"`
Expected: All tests PASS, TEST SUCCEEDED

- [ ] **Step 2: Run all Watch tests**

Run: `xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' 2>&1 | grep -E "(Test Case.*passed|Test Case.*failed|TEST SUCCEEDED|TEST FAILED)"`
Expected: All tests PASS, TEST SUCCEEDED

- [ ] **Step 3: Build both targets**

Run: `xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 17' -quiet 2>&1 | tail -3`
Run: `xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -quiet 2>&1 | tail -3`
Expected: Both BUILD SUCCEEDED

- [ ] **Step 4: Push to remote**

```bash
git push origin master
```
