# RunPulse Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Apple Watch running app with real-time heart rate monitoring, per-kilometer pace tracking, and HR threshold alerts, paired with an iOS companion app for history and settings.

**Architecture:** WatchKit app handles real-time workout tracking using HealthKit; iOS companion app provides dashboard, run history via CoreData, and user settings. Communication via WCSession.

**Tech Stack:** Swift 5.9+, SwiftUI, WatchKit, HealthKit, WatchConnectivity, CoreData, Xcode 15+

---

## Phase Overview

| Phase | Description | Estimated Time |
|-------|-------------|----------------|
| 1 | Project Setup & HealthKit Integration | 2-3 hours |
| Watch App | Core running functionality | 6-8 hours |
| iOS App | Companion app with history | 4-6 hours |
| Testing | Unit & UI tests | 3-4 hours |
| Deployment | App Store submission | 2-3 hours |

---

## Phase 1: Project Setup & HealthKit Integration

### Task 1: Create Xcode Project Structure

**Files:**
- Create: `/Users/feichen/RunPulse/RunPulse.xcodeproj/project.pbxproj`
- Create: `/Users/feichen/RunPulse/RunPulse/RunPulseApp.swift`
- Create: `/Users/feichen/RunPulse/RunPulseWatch/RunPulseWatchApp.swift`

- [ ] **Step 1: Create iOS app target**

Run in terminal:
```bash
cd /Users/feichen/RunPulse

# Create Xcode project using xcodeproj gem (install if needed)
gem install xcodeproj

ruby << 'RUBY'
require 'xcodeproj'

project = Xcodeproj::Project.new('./RunPulse.xcodeproj')

# iOS App Target
ios_target = project.new_target(:application, 'RunPulse', :ios, '17.0', :swift)
ios_target.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['INFOPLIST_FILE'] = 'RunPulse/Info.plist'
end

# Watch App Target
watch_target = project.new_target(:application, 'RunPulseWatch', :watchos, '10.0', :swift)
watch_target.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['INFOPLIST_FILE'] = 'RunPulseWatch/Info.plist'
  config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
end

project.save
puts "Project created successfully"
RUBY
```

Expected: "Project created successfully"

- [ ] **Step 2: Create iOS app entry point**

Create `RunPulse/RunPulseApp.swift`:
```swift
import SwiftUI

@main
struct RunPulseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 3: Create Watch app entry point**

Create `RunPulseWatch/RunPulseWatchApp.swift`:
```swift
import SwiftUI

@main
struct RunPulseWatchApp: App {
    var body: some Scene {
        WindowGroup {
            RunView()
        }
    }
}
```

- [ ] **Step 4: Create iOS Info.plist**

Create `RunPulse/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSHealthShareUsageDescription</key>
    <string>RunPulse needs access to your health data to display running metrics and heart rate information.</string>
    <key>NSHealthUpdateUsageDescription</key>
    <string>RunPulse saves your workout data to HealthKit for comprehensive fitness tracking.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>RunPulse uses your location to track running distance and pace accurately.</string>
</dict>
</plist>
```

- [ ] **Step 5: Create Watch Info.plist**

Create `RunPulseWatch/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSHealthShareUsageDescription</key>
    <string>RunPulse monitors your heart rate during runs to provide real-time feedback.</string>
    <key>NSHealthUpdateUsageDescription</key>
    <string>RunPulse saves your workout sessions to HealthKit.</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7k</string>
        <string>watchkit</string>
    </array>
    <key>WKCompanionAppBundleIdentifier</key>
    <string>com.yourbundleid.RunPulse</string>
    <key>WKWatchOnly</key>
    <false/>
</dict>
</plist>
```

- [ ] **Step 6: Initialize git repository**

```bash
cd /Users/feichen/RunPulse
git init
git add .
git commit -m "feat: initialize RunPulse project structure"
```

Expected: Commit created with message "feat: initialize RunPulse project structure"

---

### Task 2: Create Data Models

**Files:**
- Create: `RunPulse/Models/UserProfile.swift`
- Create: `RunPulse/Models/RunSession.swift`
- Create: `RunPulse/Models/KilometerSplit.swift`
- Create: `RunPulseWatch/Models/WatchRunState.swift`

- [ ] **Step 1: Create UserProfile model**

Create `RunPulse/Models/UserProfile.swift`:
```swift
import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var age: Int
    var weight: Double // in kg
    var height: Double // in cm
    var restingHeartRate: Int
    var maxHeartRateOverride: Int? // nil = calculated from age
    
    var calculatedMaxHeartRate: Int {
        220 - age
    }
    
    var alertThresholdHeartRate: Int {
        Int(Double(maxHeartRate) * 0.90)
    }
    
    var maxHeartRate: Int {
        maxHeartRateOverride ?? calculatedMaxHeartRate
    }
    
    static var `default`: UserProfile {
        UserProfile(
            id: UUID(),
            age: 30,
            weight: 70.0,
            height: 175.0,
            restingHeartRate: 60,
            maxHeartRateOverride: nil
        )
    }
}
```

- [ ] **Step 2: Create KilometerSplit model**

Create `RunPulse/Models/KilometerSplit.swift`:
```swift
import Foundation

struct KilometerSplit: Codable, Identifiable {
    let id: UUID
    let kilometerNumber: Int
    let duration: TimeInterval // seconds
    let averageHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double
    let pace: TimeInterval // seconds per km
    let distance: Double // meters (should be ~1000)
    let calories: Double
    let timestamp: Date
    
    var paceString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var exceededAlertThreshold: Bool {
        maxHeartRate > 190 // Default threshold, will be updated from profile
    }
}
```

- [ ] **Step 3: Create RunSession model**

Create `RunPulse/Models/RunSession.swift`:
```swift
import Foundation

struct RunSession: Codable, Identifiable {
    let id: UUID
    var startDate: Date
    var endDate: Date?
    var totalDuration: TimeInterval
    var totalDistance: Double // meters
    var totalCalories: Double
    var averageHeartRate: Double
    var maxHeartRate: Double
    var averagePace: TimeInterval // seconds per km
    var splits: [KilometerSplit]
    var isCompleted: Bool
    
    var totalDistanceKm: Double {
        totalDistance / 1000.0
    }
    
    var durationString: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var averagePaceString: String {
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    static func newSession() -> RunSession {
        RunSession(
            id: UUID(),
            startDate: Date(),
            endDate: nil,
            totalDuration: 0,
            totalDistance: 0,
            totalCalories: 0,
            averageHeartRate: 0,
            maxHeartRate: 0,
            averagePace: 0,
            splits: [],
            isCompleted: false
        )
    }
}
```

- [ ] **Step 4: Create WatchRunState model**

Create `RunPulseWatch/Models/WatchRunState.swift`:
```swift
import Foundation

enum RunState: String, Codable {
    case notStarted
    case running
    case paused
    case completed
}

struct WatchRunState: Codable {
    var state: RunState
    var currentHeartRate: Double
    var currentPace: TimeInterval
    var currentDistance: Double
    var currentDuration: TimeInterval
    var currentKilometer: Int
    var alertThreshold: Int
    var isAlerting: Bool
    var lastSplit: KilometerSplit?
    
    static var idle: WatchRunState {
        WatchRunState(
            state: .notStarted,
            currentHeartRate: 0,
            currentPace: 0,
            currentDistance: 0,
            currentDuration: 0,
            currentKilometer: 0,
            alertThreshold: 171, // Default for age 30
            isAlerting: false,
            lastSplit: nil
        )
    }
}
```

- [ ] **Step 5: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Models/ RunPulseWatch/Models/
git commit -m "feat: add data models for UserProfile, RunSession, KilometerSplit, and WatchRunState"
```

---

### Task 3: HealthKit Manager (iOS)

**Files:**
- Create: `RunPulse/Services/HealthKitManager.swift`
- Test: `RunPulseTests/HealthKitManagerTests.swift`

- [ ] **Step 1: Write failing test for HealthKit authorization**

Create `RunPulseTests/HealthKitManagerTests.swift`:
```swift
import XCTest
@testable import RunPulse

final class HealthKitManagerTests: XCTestCase {
    func testHealthKitAuthorizationStatusReturnsCorrectValue() {
        let manager = HealthKitManager()
        // Initial state should be not authorized
        XCTAssertFalse(manager.isAuthorized)
    }
    
    func testMaxHeartRateCalculation() {
        let profile = UserProfile.default
        XCTAssertEqual(profile.calculatedMaxHeartRate, 190) // 220 - 30
    }
    
    func testAlertThresholdCalculation() {
        let profile = UserProfile.default
        XCTAssertEqual(profile.alertThresholdHeartRate, 171) // 190 * 0.9
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RunPulseTests/HealthKitManagerTests
```

Expected: FAIL - HealthKitManager not defined

- [ ] **Step 3: Implement HealthKitManager**

Create `RunPulse/Services/HealthKitManager.swift`:
```swift
import HealthKit
import Foundation

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    
    // Types we want to read
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .walkingRunningCadence)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.workoutType()
    ]
    
    // Types we want to write
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        isAuthorized = true
    }
    
    func checkAuthorizationStatus() async {
        var authorized = true
        for type in typesToRead {
            let status = await healthStore.authorizationStatus(for: type)
            if status != .sharingAuthorized {
                authorized = false
                break
            }
        }
        isAuthorized = authorized
    }
}

enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RunPulseTests/HealthKitManagerTests
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Services/HealthKitManager.swift RunPulseTests/HealthKitManagerTests.swift
git commit -m "feat: implement HealthKitManager with authorization handling"
```

---

## Phase 2: Watch App - Core Running Functionality

### Task 4: Workout Manager (Watch)

**Files:**
- Create: `RunPulseWatch/Services/WorkoutManager.swift`
- Test: `RunPulseTests/WorkoutManagerTests.swift`

- [ ] **Step 1: Write failing tests for workout session**

Create `RunPulseTests/WorkoutManagerTests.swift`:
```swift
import XCTest
@testable import RunPulseWatch

final class WorkoutManagerTests: XCTestCase {
    var workoutManager: WorkoutManager!
    
    override func setUp() {
        super.setUp()
        workoutManager = WorkoutManager()
    }
    
    override func tearDown() {
        workoutManager = nil
        super.tearDown()
    }
    
    func testInitialStateIsNotRunning() {
        XCTAssertEqual(workoutManager.runState.state, .notStarted)
    }
    
    func testPaceCalculation() {
        // 5 minutes per km = 300 seconds
        let pace = workoutManager.calculatePace(duration: 300, distance: 1000)
        XCTAssertEqual(pace, 300.0, accuracy: 0.1)
    }
    
    func testDistanceToKilometers() {
        XCTAssertEqual(workoutManager.metersToKilometers(1500), 1.5)
    }
    
    func testCurrentKilometerFromDistance() {
        XCTAssertEqual(workoutManager.currentKilometer(for: 2500), 3) // 2.5km -> km 3
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/WorkoutManagerTests
```

Expected: FAIL - WorkoutManager not defined

- [ ] **Step 3: Implement WorkoutManager**

Create `RunPulseWatch/Services/WorkoutManager.swift`:
```swift
import Foundation
import HealthKit
import WatchKit
import CoreLocation

@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    @Published var runState = WatchRunState.idle
    @Published var splits: [KilometerSplit] = []
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var locationProvider = LocationProvider()
    
    // Tracking state
    private var currentKilometerDistance: Double = 0
    private var currentKilometerStartTime: Date?
    private var currentKilometerHeartRates: [Double] = []
    private var totalDistance: Double = 0
    private var lastLocation: CLLocation?
    
    // Heart rate tracking
    private var currentHeartRate: Double = 0
    private var allHeartRates: [Double] = []
    
    // Timer
    private var timer: Timer?
    private var startTime: Date?
    
    func calculatePace(duration: TimeInterval, distance: Double) -> TimeInterval {
        guard distance > 0 else { return 0 }
        let km = distance / 1000.0
        return duration / km
    }
    
    func metersToKilometers(_ meters: Double) -> Double {
        meters / 1000.0
    }
    
    func currentKilometer(for distance: Double) -> Int {
        Int(distance / 1000.0) + 1
    }
    
    func startWorkout() async {
        guard let runningType = HKObjectType.workoutType() as? HKWorkoutType else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if success {
                    Task { @MainActor in
                        self.runState.state = .running
                        self.startTime = Date()
                        self.currentKilometerStartTime = Date()
                        self.startTimer()
                    }
                }
            }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
    
    func pauseWorkout() {
        workoutSession?.end()
        runState.state = .paused
        timer?.invalidate()
    }
    
    func resumeWorkout() {
        runState.state = .running
        startTimer()
    }
    
    func endWorkout() async -> RunSession? {
        timer?.invalidate()
        workoutSession?.end()
        
        let endDate = Date()
        let duration = startDate.map { endDate.timeIntervalSince($0) } ?? 0
        
        let runSession = RunSession(
            id: UUID(),
            startDate: startDate ?? Date(),
            endDate: endDate,
            totalDuration: duration,
            totalDistance: totalDistance,
            totalCalories: 0,
            averageHeartRate: allHeartRates.isEmpty ? 0 : allHeartRates.reduce(0, +) / Double(allHeartRates.count),
            maxHeartRate: allHeartRates.max() ?? 0,
            averagePace: calculatePace(duration: duration, distance: totalDistance),
            splits: splits,
            isCompleted: true
        )
        
        runState.state = .completed
        return runSession
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDuration()
            }
        }
    }
    
    private func updateDuration() {
        guard let startTime = startTime else { return }
        runState.currentDuration = Date().timeIntervalSince(startTime)
    }
    
    func processHeartRate(_ heartRate: Double) {
        currentHeartRate = heartRate
        allHeartRates.append(heartRate)
        currentKilometerHeartRates.append(heartRate)
        runState.currentHeartRate = heartRate
        
        // Check alert threshold
        if heartRate > Double(runState.alertThreshold) && !runState.isAlerting {
            triggerHeartRateAlert()
        } else if heartRate < Double(runState.alertThreshold) - 5 && runState.isAlerting {
            runState.isAlerting = false
        }
        
        runState.averageHeartRate = allHeartRates.isEmpty ? 0 : allHeartRates.reduce(0, +) / Double(allHeartRates.count)
    }
    
    private func triggerHeartRateAlert() {
        runState.isAlerting = true
        // Haptic feedback
        WKInterfaceDevice.current().play(.heartbeat)
    }
    
    func processLocation(_ location: CLLocation) {
        guard let lastLocation = lastLocation else {
            self.lastLocation = location
            return
        }
        
        let distance = location.distance(from: lastLocation)
        totalDistance += distance
        currentKilometerDistance += distance
        
        runState.currentDistance = totalDistance
        runState.currentKilometer = currentKilometer(for: totalDistance)
        
        // Check if we completed a kilometer
        if currentKilometerDistance >= 1000 {
            completeKilometer()
        }
        
        // Calculate current pace
        if let startTime = currentKilometerStartTime {
            let kmDuration = Date().timeIntervalSince(startTime)
            runState.currentPace = calculatePace(duration: kmDuration, distance: currentKilometerDistance)
        }
        
        self.lastLocation = location
    }
    
    private func completeKilometer() {
        guard let kmStartTime = currentKilometerStartTime else { return }
        
        let kmDuration = Date().timeIntervalSince(kmStartTime)
        let avgHR = currentKilometerHeartRates.isEmpty ? 0 : currentKilometerHeartRates.reduce(0, +) / Double(currentKilometerHeartRates.count)
        let maxHR = currentKilometerHeartRates.max() ?? 0
        let minHR = currentKilometerHeartRates.min() ?? 0
        
        let split = KilometerSplit(
            id: UUID(),
            kilometerNumber: splits.count + 1,
            duration: kmDuration,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            minHeartRate: minHR,
            pace: kmDuration / (currentKilometerDistance / 1000.0),
            distance: currentKilometerDistance,
            calories: 0,
            timestamp: Date()
        )
        
        splits.append(split)
        runState.lastSplit = split
        
        // Haptic feedback for km complete
        WKInterfaceDevice.current().play(.notification(.success))
        
        // Reset for next km
        currentKilometerDistance = 0
        currentKilometerStartTime = Date()
        currentKilometerHeartRates = []
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            switch toState {
            case .running:
                runState.state = .running
            case .paused:
                runState.state = .paused
            case .ended:
                runState.state = .completed
            case .stopped:
                runState.state = .notStarted
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Process collected data
    }
}

// MARK: - Location Provider
class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var locationHandler: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // meters
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationHandler?(location)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/WorkoutManagerTests
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Services/WorkoutManager.swift RunPulseTests/WorkoutManagerTests.swift
git commit -m "feat: implement WorkoutManager with HKWorkoutSession integration"
```

---

### Task 5: Heart Rate Monitor (Watch)

**Files:**
- Create: `RunPulseWatch/Services/HeartRateMonitor.swift`
- Test: `RunPulseTests/HeartRateMonitorTests.swift`

- [ ] **Step 1: Write failing tests for heart rate processing**

Create `RunPulseTests/HeartRateMonitorTests.swift`:
```swift
import XCTest
@testable import RunPulseWatch

final class HeartRateMonitorTests: XCTestCase {
    var monitor: HeartRateMonitor!
    
    override func setUp() {
        super.setUp()
        monitor = HeartRateMonitor(alertThreshold: 171)
    }
    
    func testInitialState() {
        XCTAssertEqual(monitor.currentHeartRate, 0)
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testHeartRateBelowThreshold() {
        monitor.processHeartRate(150)
        XCTAssertEqual(monitor.currentHeartRate, 150)
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testHeartRateAboveThreshold() {
        monitor.processHeartRate(175)
        XCTAssertTrue(monitor.isAlerting)
    }
    
    func testAlertClearsWhenBelowThreshold() {
        monitor.processHeartRate(175) // Above threshold
        XCTAssertTrue(monitor.isAlerting)
        monitor.processHeartRate(160) // Below threshold - 5
        XCTAssertFalse(monitor.isAlerting)
    }
    
    func testAverageHeartRate() {
        monitor.processHeartRate(140)
        monitor.processHeartRate(160)
        monitor.processHeartRate(150)
        XCTAssertEqual(monitor.averageHeartRate, 150.0, accuracy: 0.1)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/HeartRateMonitorTests
```

Expected: FAIL - HeartRateMonitor not defined

- [ ] **Step 3: Implement HeartRateMonitor**

Create `RunPulseWatch/Services/HeartRateMonitor.swift`:
```swift
import Foundation
import HealthKit

@MainActor
final class HeartRateMonitor: ObservableObject {
    @Published var currentHeartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var maxHeartRate: Double = 0
    @Published var minHeartRate: Double = .infinity
    @Published var isAlerting: Bool = false
    
    private var heartRates: [Double] = []
    private let alertThreshold: Int
    
    init(alertThreshold: Int) {
        self.alertThreshold = alertThreshold
    }
    
    func processHeartRate(_ heartRate: Double) {
        currentHeartRate = heartRate
        heartRates.append(heartRate)
        
        // Update statistics
        averageHeartRate = heartRates.reduce(0, +) / Double(heartRates.count)
        maxHeartRate = heartRates.max() ?? 0
        minHeartRate = heartRates.min() ?? .infinity
        
        // Check alert conditions
        if heartRate > Double(alertThreshold) && !isAlerting {
            isAlerting = true
        } else if heartRate < Double(alertThreshold) - 5 && isAlerting {
            isAlerting = false
        }
    }
    
    func reset() {
        currentHeartRate = 0
        averageHeartRate = 0
        maxHeartRate = 0
        minHeartRate = .infinity
        isAlerting = false
        heartRates.removeAll()
    }
    
    func getHeartRateSamples() -> [Double] {
        Array(heartRates)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/HeartRateMonitorTests
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Services/HeartRateMonitor.swift RunPulseTests/HeartRateMonitorTests.swift
git commit -m "feat: implement HeartRateMonitor with threshold alerting"
```

---

### Task 6: Pace Tracker (Watch)

**Files:**
- Create: `RunPulseWatch/Services/PaceTracker.swift`
- Test: `RunPulseTests/PaceTrackerTests.swift`

- [ ] **Step 1: Write failing tests for pace calculation**

Create `RunPulseTests/PaceTrackerTests.swift`:
```swift
import XCTest
@testable import RunPulseWatch

final class PaceTrackerTests: XCTestCase {
    var tracker: PaceTracker!
    
    override func setUp() {
        super.setUp()
        tracker = PaceTracker()
    }
    
    func testInitialState() {
        XCTAssertEqual(tracker.currentPace, 0)
        XCTAssertEqual(tracker.totalDistance, 0)
    }
    
    func testPaceForExactKilometer() {
        // 5:00/km pace
        tracker.updateDistance(1000, at: Date().addingTimeInterval(-300))
        XCTAssertEqual(tracker.currentPace, 300.0, accuracy: 0.1)
    }
    
    func testPaceForHalfKilometer() {
        // 2:30 for 500m = 5:00/km pace
        tracker.updateDistance(500, at: Date().addingTimeInterval(-150))
        XCTAssertEqual(tracker.currentPace, 300.0, accuracy: 0.1)
    }
    
    func testKilometerCompletion() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(-300))
        XCTAssertNotNil(tracker.lastSplit)
        XCTAssertEqual(tracker.lastSplit?.kilometerNumber, 1)
    }
    
    func testMultipleKilometers() {
        tracker.updateDistance(1000, at: Date().addingTimeInterval(-300))
        tracker.updateDistance(2000, at: Date().addingTimeInterval(-600))
        XCTAssertEqual(tracker.completedKilometers, 2)
    }
    
    func testPaceStringFormatting() {
        XCTAssertEqual(PaceTracker.formatPace(300), "5:00")
        XCTAssertEqual(PaceTracker.formatPace(245), "4:05")
        XCTAssertEqual(PaceTracker.formatPace(3661), "61:01")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/PaceTrackerTests
```

Expected: FAIL - PaceTracker not defined

- [ ] **Step 3: Implement PaceTracker**

Create `RunPulseWatch/Services/PaceTracker.swift`:
```swift
import Foundation

@MainActor
final class PaceTracker: ObservableObject {
    @Published var currentPace: TimeInterval = 0
    @Published var totalDistance: Double = 0
    @Published var completedKilometers: Int = 0
    @Published var lastSplit: KilometerSplit?
    @Published var splits: [KilometerSplit] = []
    
    private var currentKilometerDistance: Double = 0
    private var currentKilometerStartTime: Date = Date()
    private var lastLocationDate: Date = Date()
    
    static func formatPace(_ pace: TimeInterval) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func updateDistance(_ distance: Double, at date: Date) {
        let delta = distance - totalDistance
        totalDistance = distance
        currentKilometerDistance += delta
        lastLocationDate = date
        
        // Calculate current pace
        let kmDuration = date.timeIntervalSince(currentKilometerStartTime)
        if currentKilometerDistance > 0 {
            let km = currentKilometerDistance / 1000.0
            currentPace = kmDuration / km
        }
        
        // Check for kilometer completion
        while currentKilometerDistance >= 1000 {
            completeKilometer(at: date)
        }
    }
    
    private func completeKilometer(at date: Date) {
        let kmDuration = date.timeIntervalSince(currentKilometerStartTime)
        let kmNumber = splits.count + 1
        
        let split = KilometerSplit(
            id: UUID(),
            kilometerNumber: kmNumber,
            duration: kmDuration,
            averageHeartRate: 0, // Will be updated by HeartRateMonitor
            maxHeartRate: 0,
            minHeartRate: 0,
            pace: kmDuration,
            distance: 1000,
            calories: 0,
            timestamp: date
        )
        
        splits.append(split)
        lastSplit = split
        completedKilometers = kmNumber
        
        // Reset for next km
        currentKilometerDistance -= 1000
        currentKilometerStartTime = date
    }
    
    func reset() {
        currentPace = 0
        totalDistance = 0
        completedKilometers = 0
        lastSplit = nil
        splits.removeAll()
        currentKilometerDistance = 0
        currentKilometerStartTime = Date()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/PaceTrackerTests
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Services/PaceTracker.swift RunPulseTests/PaceTrackerTests.swift
git commit -m "feat: implement PaceTracker with per-kilometer splits"
```

---

### Task 7: Alert Engine (Watch)

**Files:**
- Create: `RunPulseWatch/Services/AlertEngine.swift`
- Test: `RunPulseTests/AlertEngineTests.swift`

- [ ] **Step 1: Write failing tests for alert engine**

Create `RunPulseTests/AlertEngineTests.swift`:
```swift
import XCTest
@testable import RunPulseWatch

final class AlertEngineTests: XCTestCase {
    var engine: AlertEngine!
    
    override func setUp() {
        super.setUp()
        engine = AlertEngine(threshold: 171)
    }
    
    func testInitialState() {
        XCTAssertFalse(engine.isAlerting)
    }
    
    func testAlertTriggersAboveThreshold() {
        engine.checkHeartRate(175)
        XCTAssertTrue(engine.isAlerting)
    }
    
    func testNoAlertBelowThreshold() {
        engine.checkHeartRate(160)
        XCTAssertFalse(engine.isAlerting)
    }
    
    func testAlertClearsWithHysteresis() {
        engine.checkHeartRate(175) // Trigger alert
        XCTAssertTrue(engine.isAlerting)
        engine.checkHeartRate(167) // threshold - 5 + 1 = 167, should still alert
        XCTAssertTrue(engine.isAlerting)
        engine.checkHeartRate(165) // threshold - 5 = 166, should clear
        XCTAssertFalse(engine.isAlerting)
    }
    
    func testAlertCount() {
        engine.checkHeartRate(175)
        engine.checkHeartRate(160)
        engine.checkHeartRate(175)
        XCTAssertEqual(engine.alertCount, 2)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/AlertEngineTests
```

Expected: FAIL - AlertEngine not defined

- [ ] **Step 3: Implement AlertEngine**

Create `RunPulseWatch/Services/AlertEngine.swift`:
```swift
import Foundation
import WatchKit

@MainActor
final class AlertEngine: ObservableObject {
    @Published var isAlerting: Bool = false
    @Published var alertCount: Int = 0
    @Published var lastAlertTime: Date?
    
    private let threshold: Int
    private let hysteresis: Int = 5 // bpm buffer to prevent alert flickering
    
    init(threshold: Int) {
        self.threshold = threshold
    }
    
    func checkHeartRate(_ heartRate: Double) {
        let hr = Int(heartRate)
        
        if hr > threshold && !isAlerting {
            triggerAlert()
        } else if hr <= threshold - hysteresis && isAlerting {
            clearAlert()
        }
    }
    
    private func triggerAlert() {
        isAlerting = true
        alertCount += 1
        lastAlertTime = Date()
        
        // Haptic feedback pattern
        triggerHapticAlert()
    }
    
    private func clearAlert() {
        isAlerting = false
    }
    
    private func triggerHapticAlert() {
        // Three rapid taps pattern
        let device = WKInterfaceDevice.current()
        device.play(.heartbeat)
    }
    
    func reset() {
        isAlerting = false
        alertCount = 0
        lastAlertTime = nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -only-testing:RunPulseTests/AlertEngineTests
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Services/AlertEngine.swift RunPulseTests/AlertEngineTests.swift
git commit -m "feat: implement AlertEngine with hysteresis and haptic feedback"
```

---

### Task 8: Watch UI - Run View

**Files:**
- Create: `RunPulseWatch/Views/RunView.swift`
- Create: `RunPulseWatch/Views/MetricsView.swift`
- Create: `RunPulseWatch/Views/SummaryView.swift`

- [ ] **Step 1: Create main RunView**

Create `RunPulseWatch/Views/RunView.swift`:
```swift
import SwiftUI

struct RunView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var heartRateMonitor: HeartRateMonitor
    @StateObject private var paceTracker = PaceTracker()
    @StateObject private var alertEngine: AlertEngine
    
    init() {
        _heartRateMonitor = StateObject(wrappedValue: HeartRateMonitor(alertThreshold: 171))
        _alertEngine = StateObject(wrappedValue: AlertEngine(threshold: 171))
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
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Ready to Run?")
                .font(.headline)
            
            Button(action: {
                Task {
                    await workoutManager.startWorkout()
                }
            }) {
                Text("Start")
                    .font(.title2)
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
            // Heart Rate - Large display
            heartRateDisplay
            
            Divider()
            
            // Pace
            paceDisplay
            
            Divider()
            
            // Distance & Duration
            statsRow
            
            // Alert indicator
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
                .font(.system(size: 44, weight: .bold, design: .rounded))
            
            Text("BPM")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var paceDisplay: some View {
        VStack(spacing: 2) {
            Text("Pace")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(PaceTracker.formatPace(paceTracker.currentPace))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
            
            Text("/km")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var statsRow: some View {
        HStack {
            VStack {
                Text(formatDistance(paceTracker.totalDistance))
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Distance")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text(formatDuration(workoutManager.runState.currentDuration))
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text("\(paceTracker.completedKilometers)")
                    .font(.title3)
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
        .font(.caption)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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

- [ ] **Step 2: Create MetricsView**

Create `RunPulseWatch/Views/MetricsView.swift`:
```swift
import SwiftUI

struct MetricsView: View {
    let splits: [KilometerSplit]
    
    var body: some View {
        List(splits) { split in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("KM \(split.kilometerNumber)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(split.paceString)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("\(Int(split.averageHeartRate)) BPM", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink)
                    
                    Spacer()
                    
                    if split.maxHeartRate > 170 {
                        Label("High", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Splits")
    }
}

#Preview {
    MetricsView(splits: [
        KilometerSplit(
            id: UUID(),
            kilometerNumber: 1,
            duration: 300,
            averageHeartRate: 145,
            maxHeartRate: 155,
            minHeartRate: 135,
            pace: 300,
            distance: 1000,
            calories: 50,
            timestamp: Date()
        )
    ])
}
```

- [ ] **Step 3: Create SummaryView**

Create `RunPulseWatch/Views/SummaryView.swift`:
```swift
import SwiftUI

struct SummaryView: View {
    let runSession: RunSession?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Workout Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Summary stats
                summaryStats
                
                // Splits
                if let session = runSession, !session.splits.isEmpty {
                    Text("Splits")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(session.splits) { split in
                        splitRow(split)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
    }
    
    private var summaryStats: some View {
        Group {
            HStack {
                statCard(title: "Distance", value: runSession?.totalDistanceKmString ?? "0.00 km")
                statCard(title: "Duration", value: runSession?.durationString ?? "0:00")
            }
            
            HStack {
                statCard(title: "Avg Pace", value: runSession?.averagePaceString ?? "0:00")
                statCard(title: "Avg HR", value: "\(Int(runSession?.averageHeartRate ?? 0)) BPM")
            }
        }
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack {
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
    
    private func splitRow(_ split: KilometerSplit) -> some View {
        HStack {
            Text("KM \(split.kilometerNumber)")
                .fontWeight(.medium)
            Spacer()
            Text(split.paceString)
            Text("\(Int(split.averageHeartRate)) BPM")
                .foregroundColor(.pink)
        }
        .font(.caption)
        .padding(.vertical, 2)
    }
}

extension RunSession {
    var totalDistanceKmString: String {
        String(format: "%.2f km", totalDistanceKm)
    }
}

#Preview {
    SummaryView(runSession: RunSession.newSession())
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseWatch/Views/
git commit -m "feat: add Watch UI views for Run, Metrics, and Summary"
```

---

## Phase 3: iOS Companion App

### Task 9: Watch Connectivity Manager

**Files:**
- Create: `RunPulse/Services/WatchSessionManager.swift`
- Test: `RunPulseTests/WatchSessionManagerTests.swift`

- [ ] **Step 1: Write failing tests for session management**

Create `RunPulseTests/WatchSessionManagerTests.swift`:
```swift
import XCTest
@testable import RunPulse

final class WatchSessionManagerTests: XCTestCase {
    var manager: WatchSessionManager!
    
    override func setUp() {
        super.setUp()
        manager = WatchSessionManager()
    }
    
    func testInitialState() {
        XCTAssertFalse(manager.isPaired)
        XCTAssertFalse(manager.isReachable)
    }
    
    func testRunSessionEncoding() {
        let session = RunSession.newSession()
        let data = try? JSONEncoder().encode(session)
        XCTAssertNotNil(data)
        
        let decoded = try? JSONDecoder().decode(RunSession.self, from: data!)
        XCTAssertEqual(decoded?.id, session.id)
    }
}
```

- [ ] **Step 2: Implement WatchSessionManager**

Create `RunPulse/Services/WatchSessionManager.swift`:
```swift
import Foundation
import WatchConnectivity

@MainActor
final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var isPaired = false
    @Published var isReachable = false
    @Published var lastReceivedRun: RunSession?
    
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
    
    func sendToWatch(_ message: [String: Any]) {
        guard session.isReachable else {
            // Queue for later delivery
            session.updateApplicationContext(message)
            return
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error)")
        }
    }
    
    func sendRunSession(_ session: RunSession) {
        do {
            let data = try JSONEncoder().encode(session)
            let message = ["runSession": data]
            sendToWatch(message)
        } catch {
            print("Failed to encode run session: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle incoming messages from watch
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Handle app context updates
    }
}
```

- [ ] **Step 3: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Services/WatchSessionManager.swift RunPulseTests/WatchSessionManagerTests.swift
git commit -m "feat: implement WatchSessionManager for iOS-Watch communication"
```

---

### Task 10: iOS Views

**Files:**
- Create: `RunPulse/Views/ContentView.swift`
- Create: `RunPulse/Views/DashboardView.swift`
- Create: `RunPulse/Views/HistoryView.swift`
- Create: `RunPulse/Views/RunDetailView.swift`
- Create: `RunPulse/Views/SettingsView.swift`

- [ ] **Step 1: Create ContentView**

Create `RunPulse/Views/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
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

#Preview {
    ContentView()
}
```

- [ ] **Step 2: Create DashboardView**

Create `RunPulse/Views/DashboardView.swift`:
```swift
import SwiftUI

struct DashboardView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var watchSessionManager = WatchSessionManager.shared
    
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
            // Watch connection status
            HStack {
                Circle()
                    .fill(watchSessionManager.isReachable ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                
                Text(watchSessionManager.isReachable ? "Watch Connected" : "Watch Not Connected")
                    .font(.subheadline)
            }
            
            // Quick stats
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
```

- [ ] **Step 3: Create HistoryView**

Create `RunPulse/Views/HistoryView.swift`:
```swift
import SwiftUI

struct HistoryView: View {
    @State private var runSessions: [RunSession] = []
    
    var body: some View {
        NavigationView {
            Group {
                if runSessions.isEmpty {
                    emptyState
                } else {
                    runList
                }
            }
            .navigationTitle("Run History")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Runs Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start a run on your Apple Watch to see it here.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var runList: some View {
        List(runSessions) { session in
            NavigationLink(destination: RunDetailView(runSession: session)) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.startDate, style: .date)
                            .font(.headline)
                        Spacer()
                        Text(session.durationString)
                            .font(.subheadline)
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

- [ ] **Step 4: Create RunDetailView**

Create `RunPulse/Views/RunDetailView.swift`:
```swift
import SwiftUI

struct RunDetailView: View {
    let runSession: RunSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Stats grid
                statsGrid
                
                // Splits
                splitsSection
            }
            .padding()
        }
        .navigationTitle("Run Details")
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(runSession.startDate, style: .date)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(runSession.startDate, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kilometer Splits")
                .font(.headline)
            
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
                    
                    if split.maxHeartRate > 170 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        RunDetailView(runSession: RunSession.newSession())
    }
}
```

- [ ] **Step 5: Create SettingsView**

Create `RunPulse/Views/SettingsView.swift`:
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
        NavigationView {
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
        }
    }
}

#Preview {
    SettingsView()
}
```

- [ ] **Step 6: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulse/Views/
git commit -m "feat: add iOS app views for Dashboard, History, Run Details, and Settings"
```

---

## Phase 4: Testing

### Task 11: Integration Tests

**Files:**
- Create: `RunPulseTests/IntegrationTests.swift`
- Create: `RunPulseUITests/RunPulseUITests.swift`

- [ ] **Step 1: Create integration tests**

Create `RunPulseTests/IntegrationTests.swift`:
```swift
import XCTest
@testable import RunPulse
@testable import RunPulseWatch

final class IntegrationTests: XCTestCase {
    func testFullRunSessionFlow() {
        // Simulate a complete run session
        var session = RunSession.newSession()
        
        // Simulate 5km run with 5:00/km pace
        for km in 1...5 {
            let split = KilometerSplit(
                id: UUID(),
                kilometerNumber: km,
                duration: 300, // 5 minutes
                averageHeartRate: 150 + Double(km) * 2,
                maxHeartRate: 160 + Double(km) * 2,
                minHeartRate: 140 + Double(km) * 2,
                pace: 300,
                distance: 1000,
                calories: 60,
                timestamp: Date().addingTimeInterval(Double(km) * 300)
            )
            session.splits.append(split)
        }
        
        session.totalDistance = 5000
        session.totalDuration = 1500
        session.averageHeartRate = 160
        session.maxHeartRate = 170
        session.averagePace = 300
        session.isCompleted = true
        
        // Verify calculations
        XCTAssertEqual(session.totalDistanceKm, 5.0)
        XCTAssertEqual(session.durationString, "25:00")
        XCTAssertEqual(session.averagePaceString, "5:00")
        XCTAssertEqual(session.splits.count, 5)
    }
    
    func testHeartRateAlertIntegration() {
        let alertEngine = AlertEngine(threshold: 171)
        
        // Simulate increasing heart rate
        for hr in stride(from: 140, through: 180, by: 5) {
            alertEngine.checkHeartRate(Double(hr))
        }
        
        XCTAssertTrue(alertEngine.isAlerting)
        XCTAssertEqual(alertEngine.alertCount, 1)
    }
    
    func testUserProfileCalculations() {
        let profile = UserProfile(
            id: UUID(),
            age: 40,
            weight: 80,
            height: 180,
            restingHeartRate: 65,
            maxHeartRateOverride: nil
        )
        
        XCTAssertEqual(profile.calculatedMaxHeartRate, 180)
        XCTAssertEqual(profile.alertThresholdHeartRate, 162)
    }
}
```

- [ ] **Step 2: Create UI tests**

Create `RunPulseUITests/RunPulseUITests.swift`:
```swift
import XCTest

final class RunPulseUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testLaunchAndNavigate() throws {
        // Verify app launches
        XCTAssertTrue(app.staticTexts["Dashboard"].exists || app.staticTexts["RunPulse"].exists)
        
        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(app.staticTexts["Profile"].exists || app.staticTexts["Settings"].exists)
        }
    }
    
    func testSettingsViewElements() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            
            // Verify settings elements exist
            XCTAssertTrue(app.staticTexts["Age"].exists || app.steppers.count > 0)
        }
    }
}
```

- [ ] **Step 3: Run all tests**

```bash
cd /Users/feichen/RunPulse
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'
```

Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
cd /Users/feichen/RunPulse
git add RunPulseTests/IntegrationTests.swift RunPulseUITests/RunPulseUITests.swift
git commit -m "test: add integration and UI tests"
```

---

## Phase 5: Deployment

### Task 12: App Store Preparation

**Files:**
- Create: `docs/deployment/DEPLOYMENT_CHECKLIST.md`
- Create: `docs/deployment/APP_STORE_SUBMISSION.md`

- [ ] **Step 1: Create deployment checklist**

Create `docs/deployment/DEPLOYMENT_CHECKLIST.md`:
```markdown
# RunPulse Deployment Checklist

## Pre-Submission

- [ ] All tests pass (`xcodebuild test`)
- [ ] No compiler warnings
- [ ] App icons set for all sizes (iOS + Watch)
- [ ] Launch screen configured
- [ ] Info.plist permissions strings are complete
- [ ] Version number set (CFBundleShortVersionString)
- [ ] Build number set (CFBundleVersion)
- [ ] Minimum deployment targets correct
  - iOS: 17.0+
  - watchOS: 10.0+

## App Store Connect

- [ ] Create app record in App Store Connect
- [ ] Upload screenshots
  - iPhone 6.7" (3 screenshots minimum)
  - Apple Watch 45mm (3 screenshots minimum)
- [ ] Write app description
- [ ] Set keywords
- [ ] Set support URL
- [ ] Set privacy policy URL
- [ ] Select content rating
- [ ] Add export compliance info

## Build Submission

- [ ] Archive build in Xcode
- [ ] Upload to App Store Connect
- [ ] Wait for processing (10-30 minutes)
- [ ] Select build for submission
- [ ] Submit for review

## Post-Approval

- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Plan next update
```

- [ ] **Step 2: Create submission guide**

Create `docs/deployment/APP_STORE_SUBMISSION.md`:
```markdown
# App Store Submission Guide

## 1. Archive the Build

```bash
cd /Users/feichen/RunPulse

# Clean build
xcodebuild clean -scheme RunPulse -configuration Release

# Archive for iOS
xcodebuild archive -scheme RunPulse -configuration Release -archivePath build/RunPulse.xcarchive

# Archive for Watch
xcodebuild archive -scheme RunPulseWatch -configuration Release -archivePath build/RunPulseWatch.xcarchive
```

## 2. Upload to App Store Connect

### Using Xcode (Recommended)
1. Open Xcode
2. Product → Archive
3. In Organizer, select the archive
4. Click "Distribute App"
5. Select "App Store Connect"
6. Follow the wizard

### Using xcrun altool
```bash
# Export IPA first
xcodebuild -exportArchive -archivePath build/RunPulse.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist

# Upload
xcrun altool --upload-app -f build/export/RunPulse.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```

## 3. App Store Connect Setup

1. Go to https://appstoreconnect.apple.com
2. Create new app
3. Fill in:
   - Name: RunPulse
   - Primary Language: English
   - Bundle ID: com.yourbundleid.RunPulse
   - SKU: RUNPULSE001

## 4. Required Metadata

- **Description:** Track your runs with real-time heart rate monitoring and per-kilometer pace feedback on Apple Watch
- **Keywords:** running, heart rate, fitness, workout, apple watch, pace tracker
- **Support URL:** https://yoursupport.com
- **Privacy Policy URL:** https://yourprivacy.com

## 5. Review Guidelines

- Ensure HealthKit usage description is clear
- Verify all screenshots meet Apple requirements
- Test on physical devices before submission
- Review Apple Watch Human Interface Guidelines

## 6. Post-Submission

- Review typically takes 24-48 hours
- Monitor App Store Connect for status updates
- Be prepared to respond to reviewer questions
```

- [ ] **Step 3: Create export options plist**

Create `ExportOptions.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

- [ ] **Step 4: Final commit**

```bash
cd /Users/feichen/RunPulse
git add docs/deployment/ ExportOptions.plist
git commit -m "docs: add deployment checklist and App Store submission guide"

# Tag release
git tag -a v1.0.0 -m "Initial release of RunPulse"
git push origin main --tags
```

---

## Verification Commands

Run these commands to verify the project:

```bash
# Build iOS app
xcodebuild build -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15'

# Build Watch app
xcodebuild build -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

# Run all tests
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild test -scheme RunPulseWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)'

# Check code coverage
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
```

---

## Project Structure Summary

```
RunPulse/
├── RunPulse.xcodeproj/
├── RunPulse/                          # iOS App
│   ├── RunPulseApp.swift
│   ├── Info.plist
│   ├── Models/
│   │   ├── UserProfile.swift
│   │   ├── RunSession.swift
│   │   └── KilometerSplit.swift
│   ├── Services/
│   │   ├── HealthKitManager.swift
│   │   └── WatchSessionManager.swift
│   └── Views/
│       ├── ContentView.swift
│       ├── DashboardView.swift
│       ├── HistoryView.swift
│       ├── RunDetailView.swift
│       └── SettingsView.swift
├── RunPulseWatch/                     # Watch App
│   ├── RunPulseWatchApp.swift
│   ├── Info.plist
│   ├── Models/
│   │   └── WatchRunState.swift
│   ├── Services/
│   │   ├── WorkoutManager.swift
│   │   ├── HeartRateMonitor.swift
│   │   ├── PaceTracker.swift
│   │   └── AlertEngine.swift
│   └── Views/
│       ├── RunView.swift
│       ├── MetricsView.swift
│       └── SummaryView.swift
├── RunPulseTests/
│   ├── HealthKitManagerTests.swift
│   ├── WorkoutManagerTests.swift
│   ├── HeartRateMonitorTests.swift
│   ├── PaceTrackerTests.swift
│   ├── AlertEngineTests.swift
│   ├── WatchSessionManagerTests.swift
│   └── IntegrationTests.swift
├── RunPulseUITests/
│   └── RunPulseUITests.swift
├── docs/
│   ├── superpowers/
│   │   ├── specs/
│   │   └── plans/
│   └── deployment/
│       ├── DEPLOYMENT_CHECKLIST.md
│       └── APP_STORE_SUBMISSION.md
├── ExportOptions.plist
└── .gitignore
```
