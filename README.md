# RunPulse

Apple Watch running app with real-time heart rate monitoring, per-kilometer pace tracking, and HR threshold alerts — paired with an iOS companion app for run history and settings.

## Features

- **Real-time heart rate monitoring** during runs via HealthKit
- **Per-kilometer pace splits** with duration and average/max HR
- **HR threshold alerts** — haptic feedback + visual warning when HR exceeds 90% of max
- **Run history** — browse past runs with detailed split analysis
- **User profile** — age-based max HR calculation with custom override support
- **Watch ↔ iOS sync** — completed runs sync automatically via WatchConnectivity

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Watch | WatchKit (watchOS 10) |
| Health | HealthKit |
| Sync | WatchConnectivity (WCSession) |
| Storage | JSON files (ApplicationSupport) |
| Build | XcodeGen |

## Quick Start

```bash
# 1. Generate Xcode project
xcodegen generate

# 2. Open in Xcode
open RunPulse.xcodeproj

# 3. Build and run on a physical device (HealthKit requires real hardware)
```

> **Note:** HealthKit APIs are not available in the simulator. Test on a real Apple Watch and iPhone.

## Project Structure

```
RunPulse/              # iOS companion app (dashboard, history, settings)
├── Models/            # RunSession, UserProfile, KilometerSplit
├── Services/          # HealthKitManager, WatchSessionManager, StorageManager
├── Views/             # ContentView, DashboardView, HistoryView, RunDetailView, SettingsView
└── Resources/         # Assets (app icons, launch screen)

RunPulseWatch/         # Apple Watch app (primary workout interface)
├── Models/            # WatchRunState
├── Services/          # WorkoutManager, HeartRateMonitor, PaceTracker, AlertEngine
└── Views/             # RunView, MetricsView, SummaryView

RunPulseTests/         # Unit tests
RunPulseUITests/       # UI tests
docs/                  # Architecture specs, implementation plans, deployment guides
```

## Architecture

```
Apple Watch                          iOS Companion
┌─────────────────────┐              ┌─────────────────────┐
│  HealthKit          │              │  WatchConnectivity   │
│  (HR, GPS, Calories)│──WCSession──▶│  (receives runs)     │
│                     │              │                      │
│  WorkoutManager     │              │  StorageManager      │
│  PaceTracker        │              │  (JSON files)        │
│  AlertEngine        │              │                      │
│                     │              │  Dashboard/History   │
└─────────────────────┘              └─────────────────────┘
```

**Data flow:** Watch starts workout → HealthKit streams HR/GPS → PaceTracker calculates splits → AlertEngine monitors HR threshold → on completion, run syncs to iOS via WCSession → iOS persists to JSON storage.

**HR alert logic:** `Max HR = 220 - age` → `Alert threshold = Max HR × 0.90` → clears at `threshold - 5 bpm` (hysteresis).

## Testing

```bash
# Run all tests
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15'

# Run a single test class
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:RunPulseTests/HeartRateMonitorTests
```

## Deployment

See deployment guides:
- [`docs/deployment/DEPLOYMENT_CHECKLIST.md`](docs/deployment/DEPLOYMENT_CHECKLIST.md) — pre-submission checklist
- [`docs/deployment/APP_STORE_SUBMISSION.md`](docs/deployment/APP_STORE_SUBMISSION.md) — archive and upload guide

### Before submitting to App Store

1. Update `WKCompanionAppBundleIdentifier` in `RunPulseWatch/Info.plist` to your actual bundle ID
2. Replace `YOUR_TEAM_ID` in `ExportOptions.plist`
3. Add app icons to both `Resources/` directories
4. Configure a launch screen

## License

[Add your license here]
