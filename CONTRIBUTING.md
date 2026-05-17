# Contributing to RunPulse

Thank you for your interest in contributing to RunPulse!

## Branch Strategy

- `main` — stable, production-ready code
- Feature branches — branch off `main` with the pattern `feature/<description>` or `fix/<description>`
- Documentation branches — use `docs/<description>`

## Development Setup

1. Install [XcodeGen](https://github.com/CreatorKit/XcodeGen): `brew install xcodegen`
2. Generate the Xcode project: `xcodegen generate`
3. Open `RunPulse.xcodeproj` in Xcode
4. Build and run on a physical device (HealthKit requires real hardware)

## Code Conventions

- Swift 5.9, SwiftUI throughout
- Follow existing file structure: `Models/`, `Services/`, `Views/`, `Helpers/`
- Use `@MainActor` on service classes
- JSON file storage in `ApplicationSupportDirectory` (no CoreData)
- HealthKit permission descriptions required in both `Info.plist` files

## Testing

```bash
# Run all tests
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15'

# Run a single test class
xcodebuild test -scheme RunPulse -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:RunPulseTests/HeartRateMonitorTests
```

## Pull Requests

1. Ensure all tests pass
2. Update `CHANGELOG.md` with your changes
3. Request a review from a maintainer
4. Squash merge into `main`

## Documentation

- Update relevant docs in `docs/` when changing architecture or behavior
- Keep `README.md` user-facing and `AGENTS.md` focused on developer/AI tooling
