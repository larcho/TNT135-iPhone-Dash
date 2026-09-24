# iOS app — TNT135 Dash

SwiftUI, iOS 26+, Swift 6 (default MainActor isolation). Target: iPhone 17 Pro, landscape.

```
project.yml             XcodeGen spec (the .xcodeproj is generated and gitignored)
Config/                 Base.xcconfig + your Local.xcconfig (Team ID, gitignored)
Packages/DashCore/      Pure logic: frame decoding, calibration, gear inference, odometer
TNT135Dash/
  App/                  App entry, DashboardModel (@Observable), SettingsStore
  BLE/                  TelemetrySource protocol, CoreBluetooth + simulated sources
  Views/                SwiftUI (DashboardView is a placeholder until the Figma design lands)
```

## Setup
```sh
brew install xcodegen
cp Config/Local.xcconfig.example Config/Local.xcconfig   # set DEVELOPMENT_TEAM
make open
```

| Command | What |
|---|---|
| `make test` | `swift test` on DashCore (macOS, fast; includes the shared protocol vectors) |
| `make build-sim` | Generate the project and build for the simulator |
| `make open` | Generate the project and open it in Xcode |

In the **simulator** the app uses `SimulatedTelemetrySource`, a scripted 40 s ride
with gear changes and indicators. On a device, pass the launch argument `-simulate`
to do the same.
