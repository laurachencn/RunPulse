# RunPulse Real Device Test Plan

> **Purpose:** Step-by-step checklist for validating RunPulse on physical Apple Watch + iPhone.
> **Last updated:** 2026-05-16

## Prerequisites

### Hardware
- [ ] iPhone running iOS 17.0 or later (physical device, not simulator)
- [ ] Apple Watch running watchOS 10.0 or later (physical device, not simulator), paired to the iPhone
- [ ] Both devices charged to at least 50% battery
- [ ] Bluetooth enabled on both devices
- [ ] Wi-Fi enabled on both devices (for WCSession fallback)

### Software
- [ ] Xcode 16.0+ installed on Mac
- [ ] Apple Developer account signed in to Xcode
- [ ] Valid provisioning profiles for both `com.laurachencn.RunPulse` and `com.laurachencn.RunPulse.watch`
- [ ] `WKCompanionAppBundleIdentifier` in `RunPulseWatch/Info.plist` set to `com.laurachencn.RunPulse` (not the placeholder `com.yourbundleid.RunPulse`)

### Pre-Test Setup
- [ ] Run `xcodegen generate` in `/Users/feichen/RunPulse` to regenerate the Xcode project
- [ ] Open `RunPulse.xcodeproj` in Xcode
- [ ] Select the `RunPulse` scheme
- [ ] Verify both devices appear in the destination picker
- [ ] Delete any existing RunPulse installs from both iPhone and Watch (long-press app icon > Remove App)
- [ ] Clear HealthKit data from previous test runs (iPhone: Settings > Privacy & Security > Health > RunPulse > Turn All Categories Off, then back On)

---

## Build & Install Steps

### Step 1: Build and Install iOS App
- [ ] In Xcode, select destination: your physical iPhone
- [ ] Build and run (`Cmd+R`) the `RunPulse` scheme
- [ ] Verify the app launches on iPhone and shows the TabView with Dashboard, History, and Settings tabs
- [ ] Note the bundle ID in console output: should be `com.laurachencn.RunPulse`

### Step 2: Build and Install Watch App
- [ ] In Xcode, select destination: your physical Apple Watch
- [ ] Build and run (`Cmd+R`) the `RunPulse` scheme (the Watch app is a dependency target)
- [ ] Alternatively, switch scheme to `RunPulseWatch` if available and run on Watch
- [ ] Verify the app appears on the Watch home screen and launches to the "Ready to Run?" screen
- [ ] Note the bundle ID: should be `com.laurachencn.RunPulse.watch`

### Step 3: Verify WCSession Pairing
- [ ] Open RunPulse on iPhone, go to Dashboard tab
- [ ] Check the connection indicator at the top:
  - Green dot + "Watch Connected" = WCSession active
  - Gray dot + "Watch Not Connected" = WCSession not yet established
- [ ] If not connected, keep both apps open and wait up to 30 seconds
- [ ] If still not connected, toggle Bluetooth off/on on iPhone

---

## Test Categories

### A. HealthKit Authorization (iPhone + Watch)

#### A1. iOS HealthKit Authorization
- [ ] Open RunPulse on iPhone
- [ ] Observe the "HealthKit Access Required" screen with "Grant Access" button
- [ ] Tap "Grant Access"
- [ ] Verify the iOS HealthKit permission dialog appears listing: Heart Rate, Active Energy, Distance, Workouts
- [ ] Tap "Turn On All" (or manually enable each category)
- [ ] Verify the Dashboard content replaces the authorization prompt
- [ ] Verify the green "Watch Connected" indicator appears (if Watch app is also installed)
- [ ] Go to iPhone Settings > Privacy & Security > Health > RunPulse and confirm all categories are enabled

#### A2. Watch HealthKit Authorization
- [ ] Open RunPulse on Apple Watch
- [ ] If HealthKit permission dialog appears on Watch, tap "Allow" / "Turn On All"
- [ ] Verify the "Ready to Run?" screen with the runner icon and green "Start" button is displayed
- [ ] Confirm no crash or error message appears

#### A3. Authorization Denial Recovery
- [ ] On iPhone, go to Settings > Privacy & Security > Health > RunPulse
- [ ] Turn OFF all HealthKit categories
- [ ] Kill and relaunch the RunPulse iOS app
- [ ] Verify the "HealthKit Access Required" screen reappears
- [ ] Tap "Grant Access" again and re-enable permissions
- [ ] Verify dashboard loads successfully

---

### B. Watch Workout — Basic Run

#### B1. Start a Workout
- [ ] On Apple Watch, open RunPulse
- [ ] Verify the "Ready to Run?" screen is shown with state `.notStarted`
- [ ] Tap the green "Start" button
- [ ] Verify the screen transitions to the active run view showing:
  - Heart rate display with heart icon (pink color)
  - Current BPM value (may show 0 initially until sensor reads)
  - Pace display showing "/km"
  - Distance showing "0 m"
  - Time counter starting from "0:00" and incrementing every second
  - Completed KM count showing "0"

#### B2. Verify Live Metrics During Run
- [ ] Walk or run outdoors for at least 100 meters (GPS signal required for outdoor workout)
- [ ] Verify distance increases from 0 m
- [ ] Verify heart rate value updates (may take 10-30 seconds for first reading)
- [ ] Verify the timer continues counting up
- [ ] Verify pace value updates once distance > 0

#### B3. Verify Kilometer Split Completion
- [ ] Continue moving until distance reaches 1000 meters (1 km)
  - **Note:** If outdoors is impractical, use a treadmill or simulate movement
- [ ] At the 1 km mark, verify:
  - Haptic "success" vibration on the Watch
  - Completed KM count increments to "1"
  - Distance display resets toward 0 for the next km
  - The split is recorded internally (verify later in summary)

#### B4. Pause and Resume
- [ ] During an active run, verify pause functionality:
  - **Note:** The current UI does not expose a pause button in RunView — this is a known gap
  - If a pause mechanism exists (e.g., Digital Crown press), test it
  - Otherwise, skip and note as a finding

#### B5. End a Workout
- [ ] After completing at least 1 km, end the workout:
  - **Note:** The current UI does not expose an end/stop button in RunView — this is a known gap
  - If ending is possible (e.g., swipe, long-press, or Digital Crown), test it
  - Otherwise, skip and note as a finding
- [ ] After ending, verify the SummaryView appears showing:
  - "Workout Complete!" header with green checkmark icon
  - Distance card showing total distance in km (e.g., "1.23 km")
  - Duration card showing total time (e.g., "8:45")
  - Avg Pace card showing pace (e.g., "7:05")
  - Avg HR card showing average BPM
  - If splits exist, a "Splits" section with per-km rows showing KM number, pace, and HR

#### B6. Verify Summary Data Accuracy
- [ ] Cross-check displayed values against expectations:
  - Distance should match approximate distance traveled
  - Duration should match wall-clock time of the run
  - Avg Pace = Duration / Distance(km) — verify manually
  - Avg HR should be a reasonable value between min and max observed HR
  - Each split row shows correct KM number (1, 2, 3...)
  - Split pace format is "M:SS" (e.g., "6:30")

---

### C. HR Alert Testing

> **Note:** The Watch app hardcodes `alertThreshold = 171` BPM in `RunView.swift` (both `@AppStorage` and `init()`). The iOS Settings app calculates threshold from user profile (`(220 - age) * 0.90`) but this value is NOT synced to the Watch.

#### C1. Verify Default Threshold
- [ ] On Apple Watch, start a workout
- [ ] Observe the heart rate icon color — should be pink (not red) when HR < 171
- [ ] Verify no "High HR! Slow down" banner appears when HR < 171

#### C2. Trigger HR Alert (If Possible)
- [ ] During a workout, elevate heart rate above 171 BPM (e.g., sprint, climb stairs)
- [ ] When HR exceeds 171 BPM, verify:
  - Heart icon changes from pink to red
  - "High HR! Slow down" red banner appears at the bottom of the run screen
  - Haptic "click" vibration fires on the Watch
  - The alert persists while HR > 171

#### C3. Verify Hysteresis (Alert Clear)
- [ ] After alert triggers, reduce heart rate below 166 BPM (171 - 5 hysteresis)
- [ ] Verify:
  - Red banner disappears
  - Heart icon returns to pink
  - No additional haptic fires on clear

#### C4. Alert Does Not Re-Trigger Immediately
- [ ] After alert clears (HR < 166), let HR rise back to 170 (below threshold)
- [ ] Verify no alert fires at 170 BPM
- [ ] Let HR rise above 171 again
- [ ] Verify alert re-triggers (new haptic, red banner, red icon)

#### C5. iOS Settings Threshold Display
- [ ] On iPhone, open RunPulse > Settings tab
- [ ] With default age=30, verify:
  - "Calculated Max HR" shows "190 BPM" (220 - 30)
  - "Alert Threshold (90%)" shows "171 BPM" (190 * 0.90) in red bold text
- [ ] Change age to 40 using the stepper
- [ ] Verify:
  - "Calculated Max HR" updates to "180 BPM"
  - "Alert Threshold (90%)" updates to "162 BPM"
- [ ] **Known Gap:** Verify whether this new threshold (162) syncs to the Watch — it currently does NOT. The Watch remains at hardcoded 171.

#### C6. Custom Max HR Override
- [ ] On iPhone Settings, toggle "Use Custom Max HR" ON
- [ ] Set custom Max HR to 200 BPM using the stepper
- [ ] Verify "Alert Threshold (90%)" shows "180 BPM"
- [ ] Toggle "Use Custom Max HR" OFF
- [ ] Verify threshold returns to calculated value based on age

---

### D. Watch → iOS Sync (WCSession)

#### D1. Verify WCSession Activation
- [ ] Open RunPulse on both iPhone and Watch simultaneously
- [ ] On iPhone Dashboard, verify green dot + "Watch Connected"
- [ ] On iPhone, check Xcode console for WCSession activation logs (no errors)

#### D2. Run Session Transfer After Workout
- [ ] Complete a workout on the Watch (at least 1 km)
- [ ] After the workout ends on the Watch, switch to iPhone
- [ ] Open RunPulse > History tab
- [ ] Verify the completed run appears in the history list showing:
  - Date of the run
  - Duration string
  - Distance in km
  - Average pace
  - Average HR
- [ ] **Note:** The current codebase has a gap — `WorkoutManager.endWorkout()` creates a `RunSession` but does NOT call `WCSessionManager` to transfer it to iOS. If the run does NOT appear, this is a known bug to fix.

#### D3. Run Detail View
- [ ] In History, tap on a completed run
- [ ] Verify RunDetailView shows:
  - Date and time header
  - Stats grid: Duration, Distance, Avg Pace, Avg HR, Max HR, Calories
  - "Kilometer Splits" section with per-km rows
  - Each split row shows: KM number, pace, avg HR
  - If any split's max HR exceeded the iOS alert threshold, a red exclamation triangle appears

#### D4. Run Deletion
- [ ] In History, swipe-to-delete (or use edit mode) on a run
- [ ] Verify the run is removed from the list
- [ ] Kill and relaunch the iOS app
- [ ] Verify the deleted run does NOT reappear (persistence check)

#### D5. Background Transfer
- [ ] Start a workout on the Watch
- [ ] Background the Watch app (press side button, return to watch face)
- [ ] Keep iPhone app in foreground on Dashboard
- [ ] End the workout on the Watch (via notification or reopening app)
- [ ] Verify the run eventually appears in iPhone History (may take up to 30 seconds via applicationContext)

---

### E. iOS Settings Persistence

#### E1. @AppStorage Persistence Across Launches
- [ ] On iPhone Settings, set age to 45, weight to 80.0 kg, height to 180 cm, resting HR to 65
- [ ] Kill the RunPulse app (swipe up from app switcher)
- [ ] Relaunch RunPulse
- [ ] Navigate to Settings tab
- [ ] Verify all values persist:
  - Age: 45
  - Weight: 80.0 kg
  - Height: 180 cm
  - Resting HR: 65 BPM

#### E2. Calculated Values Update Correctly
- [ ] With age=45, verify:
  - "Calculated Max HR" = 175 BPM (220 - 45)
  - "Alert Threshold (90%)" = 157 BPM (175 * 0.90)
- [ ] Change age to 25
- [ ] Verify:
  - "Calculated Max HR" = 195 BPM
  - "Alert Threshold (90%)" = 175 BPM

#### E3. Stepper Bounds Validation
- [ ] Test age stepper boundaries:
  - Try to decrease below 18 — should not go below 18
  - Try to increase above 100 — should not go above 100
- [ ] Test weight stepper boundaries:
  - Minimum: 30.0 kg
  - Maximum: 200.0 kg
  - Step increment: 0.5 kg
- [ ] Test height stepper boundaries:
  - Minimum: 100 cm
  - Maximum: 250 cm
  - Step increment: 1 cm
- [ ] Test resting HR stepper boundaries:
  - Minimum: 40 BPM
  - Maximum: 100 BPM
- [ ] Test custom Max HR stepper boundaries (when toggle is ON):
  - Minimum: 120 BPM
  - Maximum: 220 BPM

#### E4. JSON Storage Verification
- [ ] Complete a workout on the Watch that syncs to iOS
- [ ] On the Mac, locate the app's ApplicationSupportDirectory:
  ```
  ~/Library/Developer/Xcode/dvtcoredevices/<device-id>/Data/Application/<app-container>/Library/Application Support/RunPulseRuns/
  ```
  Or use a file browser app on the iPhone to check:
  ```
  /var/mobile/Containers/Data/Application/<app-container>/Library/Application Support/RunPulseRuns/
  ```
- [ ] Verify `.json` files exist with UUID filenames (e.g., `A1B2C3D4-....json`)
- [ ] Verify each JSON file contains valid RunSession data (open in a text editor)

---

### F. Edge Cases on Device

#### F1. No GPS Signal (Indoor)
- [ ] Start a workout indoors (no GPS)
- [ ] The workout configuration uses `.outdoor` location type — verify behavior:
  - Does the workout start without GPS lock?
  - Does distance remain at 0?
  - Does heart rate still stream?
  - Does the timer still run?
- [ ] Note any error messages or unexpected behavior

#### F2. No Heart Rate Sensor Reading
- [ ] Start a workout with a loose Watch band (sensor not contacting skin)
- [ ] Verify the app handles missing HR data gracefully:
  - HR display shows 0 or last known value
  - No crash or freeze
  - Timer and distance (if GPS available) continue working

#### F3. Watch App Killed During Workout
- [ ] Start a workout on the Watch
- [ ] Force-quit the Watch app (hold side button, hold Digital Crown until power off screen, then cancel — or use the app switcher to close)
- [ ] Reopen the Watch app
- [ ] Verify the app returns to the "Ready to Run?" state (not crashed)
- [ ] Note: The workout session in HealthKit may continue running independently

#### F4. iPhone App Not Running During Sync
- [ ] Ensure iPhone RunPulse app is fully closed (killed from app switcher)
- [ ] Complete a workout on the Watch
- [ ] Open the iPhone app
- [ ] Verify the run appears in History (WCSession should deliver applicationContext on launch)

#### F5. Bluetooth Off During Workout
- [ ] Start a workout on the Watch
- [ ] Turn off Bluetooth on iPhone
- [ ] Complete the workout on the Watch
- [ ] Turn Bluetooth back on
- [ ] Open iPhone app
- [ ] Verify the run eventually syncs to History

#### F6. Very Short Run (< 1 km)
- [ ] Start a workout, walk 200 meters, then end
- [ ] Verify the summary shows:
  - Distance < 1.00 km
  - 0 completed kilometers
  - No splits section (since no full km was completed)
  - Duration and HR data still present

#### F7. Rapid Start/Stop
- [ ] Start a workout and immediately end it (< 5 seconds)
- [ ] Verify no crash occurs
- [ ] Verify the session is handled gracefully (duration ~0, distance ~0)

#### F8. Multiple Consecutive Runs
- [ ] Complete Run 1 (walk 1 km, end)
- [ ] From the Summary screen, start a new run (if UI allows) or restart the app
- [ ] Complete Run 2 (walk 1 km, end)
- [ ] On iPhone History, verify BOTH runs appear
- [ ] Verify runs are sorted by date (most recent first)

---

### G. UI/UX Validation

#### G1. iPhone Tab Navigation
- [ ] Open RunPulse on iPhone
- [ ] Verify TabView shows three tabs: Dashboard, History, Settings
- [ ] Tap each tab and verify correct view loads
- [ ] Verify tab icons display correctly:
  - Dashboard: heart.circle
  - History: clock.fill
  - Settings: gearshape.fill

#### G2. iPhone Dashboard Layout
- [ ] With HealthKit authorized and Watch connected, verify:
  - Green connection indicator with "Watch Connected" text
  - "Today's Activity" section with three stat cards: Runs, Distance, Avg HR
  - Stat cards show placeholder values ("0", "0 km", "-- BPM") when no data exists

#### G3. iPhone History Empty State
- [ ] With no saved runs, verify History tab shows:
  - Large runner icon (figure.run, gray)
  - "No Runs Yet" title
  - "Start a run on your Apple Watch to see it here." description

#### G4. iPhone History List Items
- [ ] With at least one saved run, verify each list item shows:
  - Date (formatted)
  - Duration on the right
  - Distance with location icon
  - Pace with speedometer icon
  - Average HR with heart icon
- [ ] Tap a list item and verify navigation to RunDetailView

#### G5. iPhone Settings Layout
- [ ] Verify SettingsView renders as a Form with three sections:
  - "Profile": Age, Weight, Height, Resting HR steppers
  - "Heart Rate Zones": Custom Max HR toggle, calculated/custom max HR display, alert threshold in red
  - "About": Version "1.0.0"

#### G6. Watch Run Screen Layout
- [ ] During an active run, verify the layout is readable on the Watch screen:
  - HR display: large font (size 44), heart icon, BPM label
  - Pace display: medium font (size 32), "/km" label
  - Stats row: Distance, Time, KM — all visible without scrolling
  - Alert banner (when active): red background, white text, warning icon

#### G7. Watch Summary Screen Layout
- [ ] After completing a run, verify SummaryView:
  - Scrolls if content exceeds screen height
  - "Workout Complete!" header with green checkmark
  - Four stat cards in 2x2 grid
  - Splits list below (if any splits exist)

#### G8. Watch Dark/Light Mode
- [ ] Change Watch appearance to Light Mode (Settings > Display & Brightness)
- [ ] Verify RunPulse Watch app is readable in light mode
- [ ] Change back to Dark Mode
- [ ] Verify readability in dark mode

#### G9. iPhone Dynamic Type
- [ ] On iPhone, go to Settings > Display & Brightness > Text Size
- [ ] Increase text size to maximum
- [ ] Open RunPulse and verify UI does not break or overlap
- [ ] Check all three tabs for layout issues

---

## Troubleshooting

### Build Issues

| Problem | Solution |
|---------|----------|
| `xcodeproj` not found | Run `xcodegen generate` first — the project is gitignored |
| Provisioning profile errors | Check Xcode > Signing & Capabilities for both targets; ensure team is selected |
| Watch app won't install | Verify `WKCompanionAppBundleIdentifier` in Watch Info.plist matches iOS app bundle ID |
| "Team ID" placeholder in ExportOptions.plist | Replace `YOUR_TEAM_ID` with your actual Apple Developer team ID |

### HealthKit Issues

| Problem | Solution |
|---------|----------|
| HealthKit permission dialog doesn't appear | Check Info.plist has `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` keys |
| "HealthKit not available" error | HealthKit is not available on iPad or in Simulator — use physical iPhone |
| Heart rate stays at 0 | Ensure Watch is snug on wrist; check Settings > Privacy > Health > RunPulse has Heart Rate enabled |
| Authorization denied | Go to iPhone Settings > Privacy > Health > RunPulse and manually enable categories |

### WCSession Issues

| Problem | Solution |
|---------|----------|
| "Watch Not Connected" on iPhone Dashboard | Ensure both apps are open; toggle Bluetooth; wait 30 seconds |
| Run doesn't sync from Watch to iPhone | Check Xcode console for WCSession errors; verify both apps use same WCSession; note that `WorkoutManager.endWorkout()` may not trigger the transfer |
| Sync works on simulator but not device | WCSession requires physical devices; simulators have limited WCSession support |
| applicationContext not delivered | applicationContext is delivered when the receiving app launches — try killing and reopening the iPhone app |

### Workout Issues

| Problem | Solution |
|---------|----------|
| Workout won't start | Check HealthKit authorization; verify outdoor location permission |
| GPS distance stays at 0 | Must be outdoors with clear sky; indoor GPS is unreliable |
| Splits never trigger | Must travel 1000+ meters; GPS accuracy affects distance measurement |
| App crashes on workout end | Check console for errors; verify RunSession encoding is valid |
| No pause/stop button visible | **Known UI gap:** RunView lacks pause and end buttons — this needs to be implemented |

### Storage Issues

| Problem | Solution |
|---------|----------|
| Runs don't persist after app restart | Check console for "Failed to save run" errors; verify ApplicationSupportDirectory is writable |
| History shows stale data | Pull-to-refresh or navigate away and back to trigger `loadRuns()` |
| JSON files corrupted | Delete the `RunPulseRuns` directory and restart the app |

### Watch-Specific Issues

| Problem | Solution |
|---------|----------|
| Alert threshold mismatch between iOS and Watch | **Known gap:** Watch hardcodes 171 BPM; iOS calculates from profile. These are not synced. |
| Haptic alerts don't fire | Ensure Watch haptics are enabled in Settings > Sounds & Haptics |
| SummaryView shows empty splits | Splits only populate after completing full kilometers |
| Watch app shows old data after restart | `WatchRunState.idle` resets on each launch — this is expected behavior |

---

## Test Results Summary

| Category | Tests | Passed | Failed | Notes |
|----------|-------|--------|--------|-------|
| A. HealthKit Authorization | 3 | | | |
| B. Watch Workout — Basic Run | 6 | | | |
| C. HR Alert Testing | 6 | | | |
| D. Watch → iOS Sync | 5 | | | |
| E. iOS Settings Persistence | 4 | | | |
| F. Edge Cases | 8 | | | |
| G. UI/UX Validation | 9 | | | |
| **Total** | **41** | | | |

## Known Gaps Identified During Code Review

1. **No pause/end buttons in Watch RunView** — The active run screen has no UI controls to pause or end a workout. Users must rely on system workout controls (if any) or force-quit.

2. **Watch alert threshold is hardcoded to 171** — `RunView.swift` initializes `HeartRateMonitor` and `AlertEngine` with `threshold: 171` and reads `@AppStorage("alertThreshold")` with default 171. The iOS Settings threshold is not synced to the Watch.

3. **WorkoutManager has duplicate alert logic** — Both `WorkoutManager.processHeartRate()` and `AlertEngine.checkHeartRate()` implement HR alerting. `AlertEngine` is instantiated in `RunView` but may not be connected to the live HR stream from `WorkoutManager`.

4. **Run session may not auto-sync to iOS** — `WorkoutManager.endWorkout()` creates a `RunSession` and stores it in `currentSession`, but there is no visible call to `WatchSessionManager.sendRunSession()` to transfer it to the iPhone.

5. **`WKCompanionAppBundleIdentifier` placeholder** — The Watch Info.plist may still contain `com.yourbundleid.RunPulse` instead of `com.laurachencn.RunPulse`.

6. **No location permission handling** — The workout uses `.outdoor` configuration but there is no explicit `CLLocationManager` permission request in the Watch app.

---

## Quick Start Guide: Step-by-Step iPhone + Watch Test

### Prerequisites
- [ ] iPhone connected to Mac (USB or network via Xcode → Window → Devices and Simulators)
- [ ] Apple Watch paired to iPhone, both unlocked
- [ ] Developer Mode enabled on iPhone (Settings → Privacy & Security → Developer Mode)
- [ ] Team set in Xcode for both `RunPulse` and `RunPulseWatch` targets

### Phase 1: iPhone
1. **Build & Install** — Select `RunPulse` scheme + your iPhone → ▶ Run
2. **HealthKit Auth** — Tap "Grant Access" → enable all permissions → Allow
3. **Settings** — Set your real age → verify Max HR and Alert Threshold update → close app → reopen → verify persistence
4. **History** — Confirm empty state shows "No Runs Yet"

### Phase 2: Apple Watch
5. **Install** — Switch scheme to `RunPulseWatch` → select Watch destination → ▶ Run
6. **Start Workout** — Tap "Start" → verify HR, Pace, Distance, Time appear
7. **Walk 100m+** → verify distance increments, timer runs
8. **End Workout** → verify Summary screen with stats
9. **Sync Check** — Open iPhone app → History tab → verify run appears → tap for detail view

### Troubleshooting Quick Reference
| Issue | Fix |
|-------|-----|
| iPhone not in Xcode destinations | Plug in via USB, unlock phone, trust computer |
| Watch app won't install | Ensure Watch is paired, unlocked, on same WiFi |
| No HR data | Wear Watch snugly, wait 30s for sensor |
| Run doesn't sync | Wait 30-60s for WCSession background sync |
| HealthKit denied | iPhone Settings → Privacy → Health → RunPulse → enable all
