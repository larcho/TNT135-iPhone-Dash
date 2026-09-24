# ADR 0003 — Infer the gear from the rpm / speed ratio

**Status:** accepted (2026-09-24)

## Context
The TNT135 has no gear position sensor, only a single-wire neutral switch
(the part labelled "gear position sensor" on the diagram, wire Gr). The stock dash can
therefore only show "N".

## Decision
In a given gear, `rpm / speed` is constant (the primary × gear × final drive ratio).
`DashCore.GearEstimator`:

1. Shows `N` immediately when the neutral switch is closed.
2. Otherwise compares `rpm / km/h` with the learned ratio for each gear, in log space,
   with ±8 % tolerance.
3. Shows nothing ("–") below 5 km/h or 1 500 rpm, or when the ratio falls between
   gears (clutch pulled or slipping, mid-shift).
4. Needs 3 consecutive matching frames (150 ms) before changing the display.

Gear ratios are **learned, not hard-coded**. A calibration screen records the
median ratio while the rider holds each gear. Published gearbox specs can seed
the initial values, but tyre wear and sprocket changes shift them.

## Consequences
- The gear is unknown when stopped in gear with the clutch pulled. That's acceptable,
  since the neutral light still works.
- A clutch-switch input (the TNT has one for the start interlock) could suppress
  wrong readings while the clutch is pulled. It isn't in v1, but can be added as flag bit 6.
