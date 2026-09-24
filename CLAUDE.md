# CLAUDE.md

A replacement head unit for a **Benelli TNT135** motorcycle: an **ESP32-P4**
(MicroPython) reads the bike's 12 V signals from the stock 18-pin dash
connector and streams them over **BLE** to an **iOS app** on an iPhone 17 Pro
in a Quad Lock mount. The owner is a software engineer with a personal
Apple Developer account. The UI is designed in Figma together with Claude.

## Repo map
- `protocol/`: BLE GATT contract (`README.md`) + `test-vectors.json`. **Single source of truth.**
- `firmware/`: MicroPython. `src/config.py` holds all pins and tuning; `src/tnt/` is the library.
- `ios/`: `project.yml` (XcodeGen), `Packages/DashCore` (pure Swift logic), `TNT135Dash/` (app).
- `docs/hardware/`: signal survey, wiring, power, BOM. `docs/decisions/`: ADRs. `docs/design/`: Figma brief.
- `MATERIALS/`: owner's research (circuit diagram PDF, photos). Treat it as read-only reference.

## Commands
- All tests: `make test`
- Firmware: `cd firmware && make test | lint | run | deploy | repl` (needs `make venv` once)
- iOS logic tests: `make -C ios test` (runs `swift test` on macOS; no simulator)
- iOS build: `make -C ios build-sim`. Regenerate the project after adding or removing files: `make -C ios project`

## Invariants (don't break these)
1. **Protocol changes touch four places in one commit:** `protocol/README.md`,
   `protocol/test-vectors.json`, `firmware/src/tnt/protocol.py`,
   `ios/Packages/DashCore/Sources/DashCore/TelemetryFrame.swift`. Both test
   suites load the vectors. Never change the layout without bumping `version`.
2. **The ESP32 sends raw measurements only** (Hz, mV, flags, pulse count).
   Unit conversion, calibration, smoothing, gear inference and odometer all live in
   `DashCore` (ADR 0001).
3. **No 12 V signal ever goes directly to a GPIO.** Any wiring suggestion must go
   through the conditioning in `docs/hardware/wiring.md`.
4. Firmware modules that are pure logic (`protocol.py`, `pulsemath.py`) must not import
   `machine`, `bluetooth` or `aioble`, so they stay testable under CPython.
   Hardware code goes in `sensors.py` and `ble.py`.
5. The `.xcodeproj` is generated. Edit `ios/project.yml`, never the project file. Signing
   comes from the gitignored `ios/Config/Local.xcconfig`.
6. `DashCore` has no UIKit or CoreBluetooth dependency.

## Conventions
- **MicroPython:** asyncio + `aioble`. Keep IRQ handlers allocation-light and
  lock-free (see `PulseMeter`). No `dataclasses`, `typing` or `enum`. Integer math in
  hot paths. The stdlib is limited, so check that a module exists in MicroPython before using it.
- **Swift:** Swift 6, strict concurrency, default MainActor isolation in the app target.
  CoreBluetooth delegates use `@MainActor` isolated conformances (the queue is `.main`).
  Swift Testing (`@Test`, `#expect`) for tests.
- Keep tests next to logic: new logic in `DashCore` or the pure firmware modules gets tests.

## Facts vs. assumptions
Facts from the circuit diagram:
- Dash wires: R (batt), R/W (ign), B (gnd), Gr/W (tach, ECU J1-6), BL/O (speed signal),
  R/BL (speed sensor supply **from the dash**), W/BL (fuel sender), Gr (neutral
  switch), B/N (MIL, ECU J1-3), B/O and W/O (turns), BL (high beam).
- The "gear position sensor" is a **single-wire neutral switch**, so the gear must be inferred (ADR 0003).
- The ECU diagnostic connector (N/BL, R/P, LR, R/N, B) might expose K-line data
  (coolant temperature etc.). That's a possible future extension.

**Not yet verified** (see `docs/hardware/signal-survey.md`). Don't state these as fact:
- 18-pin connector pin numbers, tach pulses per revolution, tach/speed signal type
  (push-pull vs open collector), speed-sensor supply voltage, fuel sender resistance
  range, gear ratios, whether BLE through the P4's C6 co-processor is stable under
  MicroPython, and the final GPIO assignment (`config.py` is provisional).
