# App Store Submission Guide

## 1. Archive the Build

```bash
cd /Users/feichen/RunPulse

# Clean build
xcodebuild clean -scheme RunPulse -configuration Release

# Archive for iOS
xcodebuild archive -scheme RunPulse -configuration Release -archivePath build/RunPulse.xcarchive
```

## 2. Upload to App Store Connect

### Using Xcode (Recommended)
1. Open Xcode
2. Product → Archive
3. In Organizer, select the archive
4. Click "Distribute App"
5. Select "App Store Connect"
6. Follow the wizard

### Using xcrun altool
```bash
# Export IPA first
xcodebuild -exportArchive -archivePath build/RunPulse.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist

# Upload
xcrun altool --upload-app -f build/export/RunPulse.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```

## 3. App Store Connect Setup

1. Go to https://appstoreconnect.apple.com
2. Create new app
3. Fill in:
   - Name: RunPulse
   - Primary Language: English
   - Bundle ID: com.yourbundleid.RunPulse
   - SKU: RUNPULSE001

## 4. Required Metadata

- **Description:** Track your runs with real-time heart rate monitoring and per-kilometer pace feedback on Apple Watch
- **Keywords:** running, heart rate, fitness, workout, apple watch, pace tracker
- **Support URL:** https://yoursupport.com
- **Privacy Policy URL:** https://yourprivacy.com

## 5. Review Guidelines

- Ensure HealthKit usage description is clear
- Verify all screenshots meet Apple requirements
- Test on physical devices before submission
- Review Apple Watch Human Interface Guidelines

## 6. Post-Submission

- Review typically takes 24-48 hours
- Monitor App Store Connect for status updates
- Be prepared to respond to reviewer questions
