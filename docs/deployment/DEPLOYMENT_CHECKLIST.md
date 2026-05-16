# RunPulse Deployment Checklist

## Pre-Submission

- [ ] All tests pass (`xcodebuild test`)
- [ ] No compiler warnings
- [ ] App icons set for all sizes (iOS + Watch)
- [ ] Launch screen configured
- [ ] Info.plist permissions strings are complete
- [ ] Version number set (CFBundleShortVersionString)
- [ ] Build number set (CFBundleVersion)
- [ ] Minimum deployment targets correct
  - iOS: 17.0+
  - watchOS: 10.0+

## App Store Connect

- [ ] Create app record in App Store Connect
- [ ] Upload screenshots
  - iPhone 6.7" (3 screenshots minimum)
  - Apple Watch 45mm (3 screenshots minimum)
- [ ] Write app description
- [ ] Set keywords
- [ ] Set support URL
- [ ] Set privacy policy URL
- [ ] Select content rating
- [ ] Add export compliance info

## Build Submission

- [ ] Archive build in Xcode
- [ ] Upload to App Store Connect
- [ ] Wait for processing (10-30 minutes)
- [ ] Select build for submission
- [ ] Submit for review

## Post-Approval

- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Plan next update
