# RunPulse Phase 1: Notifications & Voice Design

> **Date:** 2026-05-17
> **Status:** Approved for implementation
> **Scope:** Full notification suite — haptic + voice during run, iOS push for threshold breaches, post-run voice summary on both devices

---

## Overview

RunPulse currently has haptic-only HR alerts on the Watch. Phase 1 adds a complete notification layer:

1. **Voice feedback** during runs (HR alerts spoken aloud on Watch)
2. **Post-run voice summaries** on both Watch and iOS
3. **iOS local notifications** for HR threshold breaches
4. **Settings toggle** to enable/disable voice feedback

## Architecture

```
Watch Side:
  AlertEngine → haptic + VoiceService.speak("Heart rate high, slow down")
  WorkoutManager.endWorkout() → VoiceService.speak(postRunSummary)

iOS Side:
  WatchSessionManager receives run → VoiceService.speak(postRunSummary)
  WatchSessionManager receives threshold breach → UNNotification

Shared Pattern:
  VoiceService (platform-specific)
    - AVSpeechSynthesizer wrapper
    - Rate: 0.5, Pitch: 1.0, Quality: .narration
    - Voice: AVSpeechSynthesisVoice(language: "en-US")
    - Queue management via speak() async
```

## VoiceService

### API

```swift
@MainActor
final class VoiceService {
    static let shared = VoiceService()
    
    func speak(_ text: String) async
    func stop()
    var isSpeaking: Bool { get }
}
```

### Behavior

- Checks `UserDefaults.standard.bool(forKey: "voiceEnabled")` before speaking (default: `true`)
- Uses `AVSpeechSynthesizer` with `AVSpeechUtterance`
- Rate: `0.5` (slower for clarity during exercise)
- Pitch: `1.0` (default)
- Quality: `.narration` (best for longer text)
- Voice: `AVSpeechSynthesisVoice(language: "en-US")`
- `speak()` is `async` — awaits `AVSpeechSynthesizerDelegate` callback
- `stop()` cancels any ongoing speech
- Does NOT interrupt haptic alerts — voice and haptic fire independently

### Platform-Specific Files

| Platform | File |
|----------|------|
| Watch | `RunPulseWatch/Services/VoiceService.swift` |
| iOS | `RunPulse/Services/VoiceService.swift` |

Both implementations are identical except for platform availability checks.

## Post-Run Voice Summary

### Content Template

```
"You ran {distance} kilometers in {duration}. Average heart rate: {avgHR} beats per minute. Max heart rate: {maxHR}. Average pace: {pace} per kilometer. You burned {calories} calories. Elevation gain: {elevation} meters."
```

### Formatting Rules

- Distance: `"%.1f"` (e.g., "5.2")
- Duration: `"X minutes and Y seconds"` (no hours unless > 60 min)
- HR values: integer
- Pace: `"X minutes Y seconds"` (e.g., "5 minutes 23 seconds")
- Calories: integer
- Elevation: integer (0 if unavailable)

### Trigger Points

| Platform | Trigger |
|----------|---------|
| Watch | `WorkoutManager.endWorkout()` after session is created |
| iOS | `WatchSessionManager` after receiving and saving run session |

## iOS Local Notifications

### Threshold Breach Notification

When `WatchSessionManager` receives a message from Watch containing an HR threshold breach:

1. Check if app is in background (`UIApplication.shared.applicationState == .background`)
2. If background, schedule a `UNNotification` with:
   - Title: "RunPulse"
   - Body: "Heart rate exceeded threshold — slow down"
   - Sound: `.defaultCritical` (bypasses silent mode)
3. If foreground, do nothing (user already sees the Watch alert)

### Notification Setup

- Request `UNAuthorizationOptions` (`.alert`, `.sound`, `.criticalAlert`) on app launch
- `AppDelegate` or `@main` struct handles notification registration
- No notification content extension needed

## Settings Toggle

### UI Addition

In `SettingsView.swift`, add a new section:

```swift
Section(header: Text("Notifications")) {
    Toggle("Voice Feedback", isOn: $voiceEnabled)
    Text("Spoken alerts and post-run summaries")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

### Storage

- `@AppStorage("voiceEnabled")` — defaults to `true`
- Watch uses same key via `UserDefaults.standard` (synced through WCSession if needed)

## Files Created

| File | Purpose |
|------|---------|
| `RunPulseWatch/Services/VoiceService.swift` | Watch voice synthesis |
| `RunPulse/Services/VoiceService.swift` | iOS voice synthesis |
| `RunPulseTests/VoiceServiceTests.swift` | Unit tests for VoiceService |

## Files Modified

| File | Change |
|------|--------|
| `RunPulseWatch/Services/AlertEngine.swift` | Call `VoiceService.speak()` when alert triggers |
| `RunPulseWatch/Services/WorkoutManager.swift` | Call `VoiceService.speak()` with summary after `endWorkout()` |
| `RunPulse/Services/WatchSessionManager.swift` | Schedule UNNotification on threshold breach; call VoiceService on run sync |
| `RunPulse/Views/SettingsView.swift` | Add Voice Feedback toggle |
| `RunPulse/Info.plist` | Add `UIBackgroundModes` for `audio` if needed for voice during background |
| `project.yml` | Add notification entitlement if critical alerts needed |

## Testing Strategy

### Unit Tests

- `VoiceServiceTests` — mock `AVSpeechSynthesizer`, verify `speak()` is called with correct text
- `AlertEngineTests` — verify voice is called alongside haptic on threshold breach
- `WatchSessionManagerTests` — verify notification scheduling on threshold message

### Manual Testing

- Run on Watch simulator: verify voice speaks HR alert when threshold exceeded
- Run on iPhone simulator: verify notification appears when Watch sends threshold breach
- Verify post-run summary speaks on both devices
- Toggle voice off in Settings: verify silence but haptics still fire

## Error Handling

- If `AVSpeechSynthesizer` fails to initialize: log error, silently skip voice (haptics still work)
- If notification permission denied: log warning, skip notifications (no crash)
- If WCSession message arrives malformed: log error, skip processing
- Voice service never throws — failures are logged and swallowed

## Constraints

- No cloud dependencies — all TTS is on-device via `AVSpeechSynthesizer`
- No network required for any notification feature
- Voice only works on devices with speaker/headphones (Watch speaker, iPhone speaker, or connected AirPods)
- Critical alert entitlement may require Apple review justification
