# RunPulse UX, Connectivity & Icon Design

> **Date:** 2026-05-17
> **Status:** Approved for implementation
> **Scope:** Three independent subsystems — iOS UX fixes, Watch↔iOS connectivity, app icons

---

## Part 1: iOS UX Fixes (Approach B)

### Problem
On iPhone 16 Pro: `NavigationView` creates split-view layout (frame starts from middle), fonts appear too large, input elements have no interaction.

### Root Causes
1. **Deprecated `NavigationView`** — iOS 17+ `NavigationStack` replaces it. `NavigationView` triggers split-view on large screens.
2. **Nested `NavigationView`** — Every tab view (Dashboard, History, Settings, RunDetail) wraps itself in `NavigationView`, causing double navigation bars and broken interaction.
3. **Font sizes not scaled** — `title2` and `headline` are oversized on 16 Pro's larger display.
4. **Hardcoded dashboard stats** — Stat cards show "0" and "-- BPM" instead of real data.

### Design

#### 1.1 Single NavigationStack
- Move `NavigationStack` to `ContentView` as the sole navigation container
- Remove `NavigationView` from `DashboardView`, `HistoryView`, `SettingsView`, `RunDetailView`
- Use `NavigationLink(value:)` + `.navigationDestination()` pattern for History → Detail navigation

#### 1.2 Font & Layout Scaling
| Element | Current | New |
|---------|---------|-----|
| Section headers | `title2` | `title3` |
| Stat card titles | `caption` | `caption` (unchanged) |
| Stat card values | `title3` | `title3` + `.scaledToFit()` |
| Navigation title | default (large) | `.navigationBarTitleDisplayMode(.inline)` |
| LazyVGrid spacing | 12 | 16 |
| Stat card padding | `.padding()` | `.padding(.horizontal, 12).padding(.vertical, 10)` |

#### 1.3 Dashboard Real Data
- `quickStatCard` values bind to `storageManager.savedRuns`
- Runs today = filter by `Calendar.current.isDateInToday`
- Distance = sum of `totalDistanceKm` for today's runs
- Avg HR = average of `averageHeartRate` for today's runs (or "-- BPM" if none)

### Files Modified
- `RunPulse/Views/ContentView.swift` — add `NavigationStack` wrapper
- `RunPulse/Views/DashboardView.swift` — remove `NavigationView`, wire real data, font scaling
- `RunPulse/Views/HistoryView.swift` — remove `NavigationView`, use `NavigationLink(value:)`
- `RunPulse/Views/SettingsView.swift` — remove `NavigationView`, add `.navigationBarTitleDisplayMode(.inline)`
- `RunPulse/Views/RunDetailView.swift` — remove `NavigationView`, font scaling

---

## Part 2: Watch ↔ iOS Connectivity

### Problem
Watch has no `WCSession` — completed runs never sync to iOS. HR threshold hardcoded to 171 on Watch, not synced from iOS Settings.

### Design

#### 2.1 WatchConnectivityManager (new)
- Location: `RunPulseWatch/Services/WatchConnectivityManager.swift`
- Singleton, `@MainActor`, `ObservableObject`
- Implements `WCSessionDelegate`
- Methods:
  - `activate()` — calls `WCSession.default.activate()`
  - `sendRunSession(_ session: RunSession)` — encodes to JSON, sends via `sendMessage` (if reachable) or `updateApplicationContext` (fallback)
  - `sendSettingsUpdate(threshold: Int)` — sends current alert threshold to iOS
- Delegate handles:
  - `session(_:didReceiveMessage:)` — receives config updates from iOS (e.g., new threshold)
  - `session(_:didReceiveApplicationContext:)` — receives background config sync

#### 2.2 Wire into WorkoutManager
- In `endWorkout()`, after creating `RunSession`:
  ```swift
  let session = RunSession(...)
  currentSession = session
  await WatchConnectivityManager.shared.sendRunSession(session)
  ```

#### 2.3 Threshold Sync Flow
- iOS Settings → when `alertThreshold` changes → `WatchSessionManager.sendSettingsUpdate(threshold:)`
- Watch → `WatchConnectivityManager` receives threshold → updates `@AppStorage("alertThreshold")`
- `RunView` reads `@AppStorage("alertThreshold")` → passes to `HeartRateMonitor` and `AlertEngine`
- Remove hardcoded `171` from `RunView.init()` — use `@AppStorage` value

#### 2.4 iOS WatchSessionManager Updates
- Add `sendSettingsUpdate(threshold: Int)` method
- Add incoming message handler for `alertThreshold` key (future: iOS can receive Watch data too)

### Files Modified
- Create: `RunPulseWatch/Services/WatchConnectivityManager.swift`
- Modify: `RunPulseWatch/Services/WorkoutManager.swift` — call `sendRunSession` on end
- Modify: `RunPulseWatch/Views/RunView.swift` — use `@AppStorage` threshold, remove hardcoded 171
- Modify: `RunPulse/Services/WatchSessionManager.swift` — add `sendSettingsUpdate`
- Modify: `RunPulse/Views/SettingsView.swift` — send threshold to Watch on change

---

## Part 3: App Icons

### Problem
No `Assets.xcassets` for either target. App has no icon.

### Design

#### 3.1 iOS App Icon
- Create `RunPulse/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Single 1024x1024 PNG at `AppIcon.appiconset/AppIcon-1024.png`
- Design: heartbeat/pulse line (EKG waveform) centered on gradient background
  - Background: linear gradient from `#FF6B6B` (coral red) to `#4ECDC4` (teal)
  - Foreground: white heartbeat waveform, ~60% width, centered
- `project.yml` already has `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`

#### 3.2 Watch App Icon
- Create `RunPulseWatch/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Single 1024x1024 PNG at `AppIcon.appiconset/AppIcon-1024.png`
- Same design as iOS icon (watchOS 10+ uses single 1024x1024 icon)

#### 3.3 Icon Generation
- Use a Python script with `Pillow` to generate the PNG programmatically
- Script: `scripts/generate_icons.py`
- Dependencies: `pip install Pillow`
- Output: both PNGs placed in correct asset catalog directories

### Files Created
- `RunPulse/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `RunPulse/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- `RunPulseWatch/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `RunPulseWatch/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- `scripts/generate_icons.py`

---

## Implementation Order

1. **UX Fixes** — foundational, affects all user-facing views
2. **Watch Connectivity** — requires UX to be stable first (SettingsView changes)
3. **App Icons** — independent, can be done in parallel but sequenced last for clean commits

## Testing Strategy

- **UX:** Verify on iPhone 16 Pro simulator — no split view, fonts readable, all inputs interactive, dashboard shows real data
- **Connectivity:** Unit tests for `WatchConnectivityManager` encoding/decoding, mock WCSession for send/receive
- **Icons:** Build both targets, verify icons appear in simulator home screen
