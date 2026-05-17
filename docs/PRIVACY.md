# Privacy Policy

## HealthKit Data

RunPulse uses Apple's HealthKit framework to access heart rate, workout, and location data during runs.

### Data Collected

- **Heart rate** — read during active workouts for real-time monitoring and threshold alerts
- **Workout data** — distance, duration, calories burned (written by the app)
- **Location data** — GPS coordinates for pace calculation (read during workouts)

### Data Usage

All HealthKit data is used locally on your device for:
- Real-time heart rate display and pace tracking during runs
- HR threshold alerts when heart rate exceeds 90% of your calculated maximum
- Run history and split analysis in the iOS companion app

### Data Storage

Run data is stored locally as JSON files in the app's `ApplicationSupportDirectory`. No data is transmitted to external servers or third parties.

### Data Sharing

- RunPulse does **not** share HealthKit data with any third parties
- Data is not used for advertising or analytics
- Watch-to-iPhone sync happens via Apple's WatchConnectivity framework — data never leaves your paired devices

### Permissions

The app requests the following HealthKit permissions:
- **Read:** Heart rate, active energy burned, distance, location during workout
- **Write:** Workout data, active energy burned, distance

You can revoke these permissions at any time in the Health app settings.

### App Store Privacy Nutrition Labels

| Data Type | Linked to User | Used for Tracking |
|-----------|---------------|-------------------|
| Health & Fitness | Yes | No |
| Location | Yes | No |

## Contact

For privacy questions, contact the app developer through the App Store listing.
