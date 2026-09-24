# TNT135 Screen

Replacing the Benelli TNT135's instrument cluster with an **iPhone 17 Pro** on a
**Quad Lock** mount. An **ESP32-P4** plugs into the stock 18-pin dash connector,
reads the bike's signals, and streams them over **BLE** to a SwiftUI app. The app
adds a **gear indicator** that the stock dash doesn't have.

```
bike harness ──18-pin──► signal conditioning ──► ESP32-P4 (MicroPython) ──BLE 20 Hz──► iPhone app
 (12 V world)            opto / dividers         raw Hz, mV, lamp flags               calibration, gear, UI
```

| Path | What |
|---|---|
| [`protocol/`](protocol/README.md) | BLE contract + shared test vectors (source of truth) |
| [`firmware/`](firmware/README.md) | MicroPython sensor bridge |
| [`ios/`](ios/README.md) | SwiftUI app + `DashCore` Swift package |
| [`docs/hardware/`](docs/hardware) | [Signal survey](docs/hardware/signal-survey.md), [wiring](docs/hardware/wiring.md), [power](docs/hardware/power.md), [BOM](docs/hardware/bom.md) |
| [`docs/decisions/`](docs/decisions) | Architecture decision records |
| [`docs/design/`](docs/design/figma-brief.md) | Figma design brief |
| `MATERIALS/` | Research: circuit diagram, photos, part references |

## Quick start
```sh
make test                 # firmware (pytest) + DashCore (swift test)
make -C ios open          # simulator runs a fake ride
```

## Roadmap
1. **Signal survey** on the bike with the stock dash still connected.
2. **BLE spike**: MicroPython C6 build on the P4 streaming to the app for 30 min.
3. Bench rig: conditioning board on protoboard, fed from a bench PSU and function generator.
4. Design the Ride screen in Figma, then implement it in SwiftUI.
5. Calibration screens: GPS speed match, gear learning, fuel curve, odometer offset.
6. On-bike testing with the stock dash stored as a fallback.
7. Carrier PCB with the 18-pin header, then enclosure and waterproofing.

> Check your local rules before removing the stock speedometer. Many jurisdictions
> require a working one.
