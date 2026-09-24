# ADR 0001 — The ESP32 is a raw sensor bridge; the phone does all interpretation

**Status:** accepted (2026-09-24)

## Context
Turning bike signals into rider-facing numbers needs calibration: tach pulses
per revolution, km/h per Hz of speed signal, the fuel sender curve, and gear ratios.
Most of these values are learned by comparing against GPS or the stock dash.

## Decision
The firmware measures and sends raw values (Hz, mV, lamp states, a cumulative
pulse count). `DashCore` on iOS converts them with a `Calibration` stored on
the phone.

## Consequences
- Recalibrating never requires re-flashing. Calibration flows (GPS speed match,
  gear learning) are ordinary app screens.
- The firmware stays small and has few ways to fail.
- **Odometer limitation:** distance only accumulates while the phone is
  connected. The ESP32 pulse counter resets on every ignition cycle, so rides without
  the phone aren't counted. If that matters later, persist the counter in ESP32
  NVS on power loss (this needs hold-up capacitance) and add it to protocol v2.
