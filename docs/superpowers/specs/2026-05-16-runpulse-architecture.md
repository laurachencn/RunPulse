# RunPulse Architecture Design

## Overview
RunPulse is an Apple Watch + iOS companion app that monitors running metrics in real-time, provides per-kilometer heart rate and pace feedback, and alerts when heart rate exceeds safe thresholds.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Apple Watch App                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    WatchKit Extension                    │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │   │
│  │  │  RunView    │  │ MetricsView  │  │ AlertView     │  │   │
│  │  │ (Main UI)   │  │ (Per-KM Data)│  │ (HR Warning)  │  │   │
│  │  └──────┬──────┘  └──────┬───────┘  └──────┬────────┘  │   │
│  │         │                │                 │            │   │
│  │  ┌──────┴────────────────┴─────────────────┴────────┐   │   │
│  │  │              RunSessionManager                    │   │   │
│  │  │  ┌─────────────┐  ┌──────────────┐  ┌─────────┐ │   │   │
│  │  │  │ HeartRate   │  │ PaceTracker  │  │ Alert   │ │   │   │
│  │  │  │ Monitor     │  │ (Per KM)     │  │ Engine  │ │   │   │
│  │  │  └─────────────┘  └──────────────┘  └─────────┘ │   │   │
│  │  └────────────────────────┬────────────────────────┘   │   │
│  │                           │                             │   │
│  │  ┌────────────────────────┴────────────────────────┐   │   │
│  │  │           HealthKit Service                     │   │   │
│  │  │  • HKHeartRateSample                            │   │   │
│  │  │  • HKWorkoutSession                             │   │   │
│  │  │  • HKStatisticsQuery                            │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │ WCSession (Watch Connectivity)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        iOS Companion App                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    UIKit/SwiftUI                        │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │   │
│  │  │ Dashboard   │  │ HistoryView  │  │ SettingsView  │  │   │
│  │  │ (Live Sync) │  │ (Past Runs)  │  │ (Age/HR Zones)│  │   │
│  │  └─────────────┘  └──────────────┘  └───────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Local Storage (CoreData)                   │   │
│  │  • RunHistory  • UserProfile  • HRZoneConfig            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
User Starts Run
      │
      ▼
┌──────────────────┐
│ HealthKit Auth   │ → Request heart rate, workout, location permissions
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│ HKWorkoutSession │────▶│ GPS Location     │
│ Start            │     │ Updates          │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         ▼                        ▼
┌──────────────────────────────────────────┐
│           RunSessionManager              │
│  • Calculate distance from GPS           │
│  • Track pace per kilometer              │
│  • Monitor heart rate continuously       │
│  • Check HR against max threshold        │
└────────┬─────────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌──────────────┐
│ Haptic │ │ Per-KM       │
│ Alert  │ │ Summary      │
│ (HR>90%)│ │ Display      │
└────────┘ └──────────────┘
```

## Heart Rate Alert Logic

```
Max HR = 220 - Age
Alert Threshold = Max HR × 0.90

IF currentHR > AlertThreshold:
    Trigger haptic pattern (3 rapid taps)
    Show red warning on screen
    Voice feedback (optional): "Heart rate high, slow down"
    Continue monitoring every 5 seconds
    Clear alert when HR < (AlertThreshold - 5 bpm)
```

## Key Metrics Tracked

| Metric | Source | Update Frequency |
|--------|--------|------------------|
| Heart Rate | HKHeartRateSample | Every 1-5 seconds |
| Distance | HKWorkoutRoute / GPS | Every 1 second |
| Pace | Calculated (time/distance) | Per kilometer |
| Duration | Workout session timer | Every 1 second |
| Calories | HKEnergyBurned | Every 60 seconds |
| Cadence | HKWalkingRunningCadence | Every 1 second |
| Elevation | HKAltitude | Every 10 seconds |

## File Structure

```
RunPulse/
├── RunPulse.xcodeproj/
├── RunPulse/                          # iOS App Target
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Models/
│   │   ├── RunSession.swift           # Run data model
│   │   ├── UserProfile.swift          # Age, weight, HR zones
│   │   └── KilometerSplit.swift       # Per-KM metrics
│   ├── Services/
│   │   ├── HealthKitManager.swift     # HK authorization & queries
│   │   ├── WatchSessionManager.swift  # WCSession delegate
│   │   └── StorageManager.swift       # CoreData operations
│   ├── Views/
│   │   ├── ContentView.swift          # Tab view
│   │   ├── DashboardView.swift        # Live run sync
│   │   ├── HistoryView.swift          # Past runs list
│   │   ├── RunDetailView.swift        # Single run analysis
│   │   └── SettingsView.swift         # Profile & preferences
│   └── Resources/
│       └── Assets.xcassets/
├── RunPulseWatch/                     # Watch App Target
│   ├── Info.plist
│   ├── RunPulseWatchApp.swift
│   ├── Views/
│   │   ├── RunView.swift              # Main running screen
│   │   ├── MetricsView.swift          # Per-KM display
│   │   └── SummaryView.swift          # Post-run summary
│   ├── Services/
│   │   ├── RunSessionManager.swift    # Core run logic
│   │   ├── HeartRateMonitor.swift     # HR sampling
│   │   ├── PaceTracker.swift          # KM pace calculation
│   │   ├── AlertEngine.swift          # HR threshold alerts
│   │   └── WorkoutManager.swift       # HKWorkoutSession
│   └── Resources/
│       └── Assets.xcassets/
├── RunPulseTests/                     # Unit Tests
│   ├── HeartRateMonitorTests.swift
│   ├── PaceTrackerTests.swift
│   ├── AlertEngineTests.swift
│   └── RunSessionManagerTests.swift
├── RunPulseUITests/                   # UI Tests
│   └── RunPulseUITests.swift
└── docs/
    └── superpowers/
        ├── specs/
        └── plans/
```

## Deployment Pipeline

```
Development → Testing → App Store Connect → Review → Release
     │            │            │              │          │
     ▼            ▼            ▼              ▼          ▼
  Xcode Build  TestFlight   Upload IPA    Apple Review  Public
  (Debug)      (Beta)       (Archive)     (24-48h)     Release
```

## Security & Privacy

- All health data stored locally on device
- No cloud sync by default (user opt-in only)
- HealthKit permissions requested on first launch
- Clear privacy policy in App Store listing
