# WatchConnectivity Protocol

## Overview

RunPulse uses `WCSession` to transfer completed run data from the Apple Watch to the iOS companion app. The Watch app is the primary data producer; the iOS app is the consumer.

## Architecture

```
Watch (Producer)                    iOS (Consumer)
┌──────────────────────┐            ┌──────────────────────┐
│ WatchConnectivityManager│         │ WatchSessionManager  │
│                      │            │                      │
│  sendMessage /       │───────────▶│  session:didReceive │
│  transferUserInfo    │            │  Message / UserInfo  │
│                      │            │                      │
│                      │◀───────────│  sendMessage (ack)   │
└──────────────────────┘            └──────────────────────┘
```

## Message Types

### 1. Run Data Transfer (`transferUserInfo`)

Used for completed runs. Sent as background-transfer so it works even if the iOS app is not foregrounded.

**Payload:**
```json
{
  "type": "runData",
  "runId": "UUID string",
  "startTime": "ISO 8601 timestamp",
  "endTime": "ISO 8601 timestamp",
  "duration": 1800.5,
  "distance": 5000.0,
  "averageHeartRate": 155,
  "maxHeartRate": 178,
  "totalCalories": 350,
  "splits": [
    {
      "kilometer": 1,
      "duration": 360.5,
      "averageHeartRate": 145,
      "maxHeartRate": 158
    }
  ]
}
```

### 2. Session State Messages (`sendMessage`)

Used for real-time communication when both apps are active.

| Message | Direction | Purpose |
|---------|-----------|---------|
| `{"type": "ping"}` | iOS → Watch | Check if Watch app is reachable |
| `{"type": "pong"}` | Watch → iOS | Acknowledge ping |
| `{"type": "runStarted"}` | Watch → iOS | Notify iOS that a workout has begun |
| `{"type": "runCancelled"}` | Watch → iOS | Notify iOS that a workout was cancelled |

## Sync Behavior

### Successful Sync

1. Watch completes workout → `WatchConnectivityManager` serializes `RunSession` to JSON
2. Data sent via `transferUserInfo(_:)` for reliable background delivery
3. iOS `WatchSessionManager` receives in `session:didReceiveUserInfo:`
4. iOS `StorageManager` persists to JSON file in `ApplicationSupportDirectory`
5. iOS app posts notification to refresh UI

### Retry Logic

- `transferUserInfo` is queued by the system and retried automatically if the iOS app is not reachable
- If a transfer fails permanently, the data remains in the Watch's local state until the next successful sync
- The Watch app does not delete run data until a successful ack is received from iOS

### Conflict Resolution

- Each run has a unique UUID generated on the Watch
- The iOS app uses the run ID as the filename, preventing duplicates
- If the same run ID is received twice, the iOS app overwrites (idempotent)

## Session Activation

Both sides must activate their `WCSession`:

**iOS (`WatchSessionManager`):**
```swift
if WCSession.isSupported() {
    WCSession.default.activate()
}
```

**watchOS (`WatchConnectivityManager`):**
```swift
WCSession.default.activate()
```

Session state is monitored via `WCSessionDelegate`:
- `sessionDidBecomeReachable` — iOS app is foregrounded, can send real-time messages
- `sessionDidDeactivate` — session ended, queue transfers for later
- `session:activationDidCompleteWith:error:` — activation result

## Testing Connectivity

1. Install both apps on paired devices
2. Start a workout on the Watch
3. Cancel or complete the workout
4. Open the iOS app — the run should appear in history
5. Check console logs for `WCSession` state transitions
