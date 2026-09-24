# Design brief — TNT135 iPhone dash (Figma)

## Canvas
- Device: **iPhone 17 Pro**, **landscape only**. 874 × 402 pt (2622 × 1206 px @3x).
  Leave room for the Dynamic Island on the left or right edge.
- Mounted with a Quad Lock mount, about 60–80 cm from the rider's eyes, often in direct sun.

## Principles
1. **Glanceable in under 0.5 s.** Speed is the hero element, then gear, then RPM.
   Everything else is secondary.
2. **Dark background, high contrast.** It has to stay readable when iOS thermally
   dims the display.
3. **No interaction while riding.** Settings and calibration only when stopped.
   Touch targets ≥ 60 pt, because riders wear gloves.
4. **Tell-tales follow motorcycle convention:** turn = green, blinking in sync with the
   flasher; high beam = blue; neutral = green "N"; engine malfunction = amber.
5. Always show the connection state. The dash must never show stale numbers as if
   they were live.

## Screens / frames
1. **Ride**: speed, gear (N / 1–4 / –), RPM (bar or arc, redline ~10 500),
   fuel, tell-tales, clock, odometer and trip, battery voltage (small).
2. **Ride: disconnected / searching**: the same layout with values dimmed and a clear status.
3. **Ride: firmware mismatch** error state.
4. **Calibration hub**: speed (GPS match), tach (compare with stock dash), fuel
   (empty/full), gears (learn 1–4), odometer offset.
5. **Gear learning flow**: "Hold 1st gear at steady throttle…", with progress and a
   confidence indicator.
6. **Settings**: units, redline, shift light, trip reset.

## Data available (from `DashState`)
`speedKmh`, `rpm`, `gear`, `fuelPercent` (optional), `batteryVolts`,
`indicators` (left, right, high beam, neutral, MIL, fuel fault), `odometerKm`,
connection status.

## Handoff to code
- Put colours, type and spacing in **Figma variables** so they map directly to
  SwiftUI tokens.
- Connect the Figma MCP server to Claude Code so frames can be read directly:
  `claude mcp add --transport http figma https://mcp.figma.com/mcp`, then share the
  frame links.
- The current `DashboardView.swift` is a **placeholder** that only exists to test
  the data pipeline.
