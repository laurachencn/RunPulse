# Audio Cues Design Spec

> **Date:** 2026-05-19
> **Status:** Approved
> **Phase:** Phase 2 — Smart Run Features
> **Feature:** Audio Cues

## Overview

Extends RunPulse's existing voice feedback (Phase 1) with configurable, periodic audio announcements during runs. Users can choose which metrics to hear and how often, configured via both Watch and iOS.

## Configuration Model

### Location: Both Watch + iOS

| Platform | Purpose |
|----------|---------|
| Watch | Quick toggles before/during run |
| iOS | Full configuration with descriptions in SettingsView |

Settings sync via WCSession.

## Metrics Scope: Standard

Four announcement types, each independently toggleable:

| Metric | Voice Template |
|--------|---------------|
| Pace | "Your pace is X minutes Y seconds per kilometer" |
| Heart Rate | "Your heart rate is X beats per minute" |
| Distance Milestones | "You've run X kilometers" |
| Calories | "You've burned X calories" |

## Trigger Model: Distance + Time Intervals

Users configure both independently:

| Interval Type | Default | Options |
|--------------|---------|---------|
| Distance | Every 1 km | 0.5 km, 1 km, 2 km, 5 km |
| Time | Off | Off, 1 min, 5 min, 10 min, 15 min |

Both can be active simultaneously. HR threshold alerts (Phase 1) always fire independently.

## Architecture

### New Components

| Component | Platform | Purpose |
|-----------|----------|---------|
| `AudioCueConfig` | Shared (model) | Codable settings, synced via WCSession |
| `AudioCueManager` | Watch | Schedules and fires cues based on config |
| `AudioCueSettingsView` | Watch | Quick toggle UI on Watch |
| `AudioCuesSection` | iOS | Settings section in SettingsView |

### Existing Components Used

| Component | Usage |
|-----------|-------|
| `VoiceService.speak()` | All announcements |
| `WatchConnectivityManager` | Sync config iOS ↔ Watch |
| `WorkoutManager` | Provides live metrics for cue generation |

### Data Flow

```
iOS Settings → AudioCueConfig → WCSession → Watch
                                          ↓
                              AudioCueManager (monitors metrics)
                                          ↓
                              Trigger fires (distance/time)
                                          ↓
                              VoiceService.speak(cue message)
```

## Settings Persistence

- iOS: `UserDefaults.standard` with `AppStorage` wrappers
- Watch: `UserDefaults.standard` (same keys, synced via WCSession)
- Config model is `Codable` for WCSession message transport

## Error Handling

- VoiceService failures: logged, silently skipped (haptics unaffected)
- WCSession sync failures: config falls back to last known good state
- Missing metrics during cue: skip that metric in announcement, don't fail

## Files Created

| File | Purpose |
|------|---------|
| `RunPulse/Models/AudioCueConfig.swift` | Shared config model |
| `RunPulseWatch/Services/AudioCueManager.swift` | Cue scheduling and firing |
| `RunPulseWatch/Views/AudioCueSettingsView.swift` | Watch settings UI |
| `RunPulse/Views/AudioCuesSection.swift` | iOS settings section |
| `RunPulseTests/AudioCueConfigTests.swift` | Model tests |
| `RunPulseTests/AudioCueManagerTests.swift` | Manager tests |

## Files Modified

| File | Change |
|------|--------|
| `RunPulseWatch/Services/WorkoutManager.swift` | Integrate AudioCueManager into run loop |
| `RunPulseWatch/Views/RunView.swift` | Link to AudioCueSettingsView |
| `RunPulse/Views/SettingsView.swift` | Add AudioCuesSection |
| `RunPulse/Services/WatchSessionManager.swift` | Sync AudioCueConfig via WCSession |
| `project.yml` | Add new source files to targets |
