# RunPulse - AGENTS.md

## Project Overview

Apple Watch + iOS companion running app with real-time heart rate monitoring, per-kilometer pace tracking, and HR threshold alerts.

**Tech stack:** Swift 5.9, SwiftUI, WatchKit, HealthKit, WatchConnectivity, JSON file storage, Xcode 16

## Build & Project Generation

- **Uses XcodeGen** — `*.xcodeproj/` is gitignored. Always run `xcodegen generate` before opening in Xcode or running `xcodebuild`.
- Project definition: `project.yml`
- Bundle ID prefix: `com.laurachencn`
- Deployment targets: iOS 17.0, watchOS 10.0

## Key Commands

```bash
# Regenerate Xcode project (required after any project.yml change)
xcodegen generate

# Run all iOS tests
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15'

# Run a single test class
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:RunPulseTests/HeartRateMonitorTests

# Archive for release
xcodebuild archive -scheme RunPulse -configuration Release -archivePath build/RunPulse.xcarchive
```

## Architecture

**Two app targets, one project:**

| Target | Platform | Purpose |
|--------|----------|---------|
| `RunPulse` | iOS 17 | Companion app: dashboard, run history (JSON files), settings, WCSession bridge |
| `RunPulseWatch` | watchOS 10 | Primary app: real-time workout tracking via HealthKit |
| `RunPulseTests` | iOS | Unit tests for both targets |
| `RunPulseUITests` | iOS | UI tests |

**Data flow:** Watch collects HealthKit data during runs → syncs to iOS via WCSession → iOS persists to JSON files in ApplicationSupportDirectory.

**HR alert logic:** Max HR = `220 - age`, Alert threshold = `Max HR × 0.90`, clears at `threshold - 5 bpm` (hysteresis).

## Directory Structure

```
RunPulse/           # iOS app — Models/, Services/, Views/, Helpers/, Resources/
RunPulseWatch/      # Watch app — Models/, Services/, Views/
RunPulseTests/      # Unit tests (shared iOS scheme)
RunPulseUITests/    # UI tests
docs/               # Architecture specs, implementation plans, deployment guides
```

## Important Conventions & Gotchas

- **HealthKit permissions** required on both targets. Info.plist must include `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`.
- **Watch companion bundle ID** in `RunPulseWatch/Info.plist` (`WKCompanionAppBundleIdentifier`) must match the iOS app's bundle ID. Currently set to placeholder `com.yourbundleid.RunPulse` — update before submission.
- **ExportOptions.plist** has `YOUR_TEAM_ID` placeholder — replace with actual team ID before archiving.
- **Storage** uses JSON files in `ApplicationSupportDirectory`, not CoreData. `StorageManager.swift` handles save/load/delete.
- **@MainActor** is used on all service classes — do not remove without verifying concurrency safety.
- Tests use the iOS simulator destination even for Watch-related logic (tests target the iOS scheme).

## Reference Docs

- `docs/superpowers/specs/2026-05-16-runpulse-architecture.md` — full architecture design
- `docs/superpowers/plans/2026-05-16-runpulse-implementation.md` — implementation plan with TDD steps
- `docs/deployment/DEPLOYMENT_CHECKLIST.md` — pre-submission checklist
- `docs/deployment/APP_STORE_SUBMISSION.md` — archive and upload guide
