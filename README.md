# MLBB Pulse

Native SwiftUI starter for an **unofficial** Mobile Legends companion: server selection and transparent diagnostics.

## Current state

- Dark SwiftUI prototype with a demo-only server picker.
- It separates **selected item**, **VPN tunnel**, and **verified egress region**. Demo data never claims to be a real Smetargus node.
- No real VPN tunnel, server catalog API, game URL scheme, signing credentials, or App Store release is configured.
- The public status page's server-side ping is not a measurement from the player's iPhone and is not in-game ping.

## Build

Generate the Xcode project with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project MLBBPulse.xcodeproj -scheme MLBBPulse -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions runs simulator build and tests on pull requests and pushes to `main`. Signing and release are intentionally separate.

## Before real service integration

1. Obtain Smetargus's written permission and supported catalog / relay API documentation.
2. Confirm stable server identifiers, client-safe configuration, and a supported health-check endpoint. Never ship private relay credentials in the app.
3. Validate routing and region verification on a normal iPhone. iOS per-app VPN generally requires managed-device deployment; don't present destination-IP approximation as app-only filtering.
4. Confirm an officially supported Mobile Legends launch link; otherwise provide a manual-launch fallback.
5. Review Apple's Network Extension entitlement and App Review requirements before implementing a tunnel.
6. Create the production icon with Apple's Icon Composer and verify dark, tinted, and accessibility appearances.

This project is not affiliated with Moonton or Smetargus. Product names belong to their respective owners.
