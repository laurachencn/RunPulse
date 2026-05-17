# Troubleshooting

## HealthKit

### "HealthKit is not available in the Simulator"

HealthKit APIs require a physical device. You cannot test heart rate or workout functionality in the simulator. Use a real Apple Watch and iPhone for testing.

### HealthKit permission dialog doesn't appear

1. Ensure `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` are set in both `Info.plist` files
2. On the iPhone, go to Settings > Health > Data Access & Devices and check that RunPulse has permission
3. Delete and reinstall the app if permissions were previously denied

### No heart rate data during workout

1. Ensure the Apple Watch is snug on your wrist
2. Check that Heart Rate permission was granted in the Health app
3. Verify that the WorkoutManager has successfully started the workout session

## WatchConnectivity

### Runs not syncing from Watch to iPhone

1. Ensure both devices have Bluetooth enabled and are paired
2. Open the RunPulse iOS app — WCSession activates when the app is foregrounded
3. Check `WatchConnectivityManager.swift` logs for session state changes
4. If sync fails, completed runs are queued and will sync on next successful connection

### WCSession activation fails

1. Verify both apps are installed (Watch app requires the iOS companion app)
2. Restart both devices if the session remains inactive
3. Check that `WCSessionDelegate` is properly set in both `WatchSessionManager.swift` (iOS) and `WatchConnectivityManager.swift` (watchOS)

## Build Issues

### "No such module" errors after pulling changes

Run `xcodegen generate` to regenerate the Xcode project. The `*.xcodeproj/` directory is gitignored and managed by XcodeGen.

### Code signing fails

1. Open `ExportOptions.plist` and replace `YOUR_TEAM_ID` with your actual Apple Developer team ID
2. In Xcode, select your team in Signing & Capabilities for both targets

### Watch app doesn't appear on paired Apple Watch

1. Ensure `WKCompanionAppBundleIdentifier` in `RunPulseWatch/Info.plist` matches the iOS app's bundle ID (`com.laurachencn.RunPulse`)
2. Install via Xcode's Devices window or the Watch app on iPhone
3. Check that both devices are on the same Apple ID

## Performance

### High battery usage during runs

- Heart rate sampling and GPS are the primary battery consumers
- The app samples HR at HealthKit's default workout frequency (approximately every 1-2 seconds)
- Consider reducing GPS accuracy if pace precision is less critical

### App feels sluggish on older Apple Watch models

- The watch app uses SwiftUI, which has higher memory overhead on Series 4 and earlier
- Close other background apps before starting a run
