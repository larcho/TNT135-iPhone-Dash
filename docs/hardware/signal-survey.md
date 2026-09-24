# Phase 0 — Signal survey (do this BEFORE removing the original dash)

The circuit diagram (`MATERIALS/benelli-tnt125:135-circuit-diagram.pdf`) shows
*which* wires reach the instrument cluster, but not the 18-pin connector
pin numbers or the electrical shape of each signal. The firmware and the
signal conditioning both depend on these answers, so measure them with the
**original dash still plugged in and working**. Back-probe the harness connector
with thin probes or T-pins, and don't pierce the insulation.

Tools: a multimeter. An oscilloscope helps (a cheap DSO138 or a USB logic analyser
is enough) for the tach and speed signals.

## Expected wires at the dash (from the diagram)

| Colour | Expected function | Source on diagram | Needed by new dash |
|---|---|---|---|
| R | Battery +12 V, constant (clock/odometer memory) | battery | no (use R/W) |
| R/W | Ignition-switched +12 V | key switch | **yes**: power + opto supply |
| B | Ground | chassis | **yes** |
| Gr/W | Tachometer signal | ECU J1-6 | **yes** |
| BL/O | Speed sensor signal | speed sensor | **yes** |
| R/BL | Speed sensor **supply, provided by the dash** | "meter" block | **yes**: the bridge must supply it |
| W/BL | Fuel level sender (resistive to ground) | fuel level sensor | **yes** |
| Gr | Neutral switch (closes to ground in neutral) | "gear position sensor" | **yes** |
| B/N | ECU trouble light (MIL), low-side driven | ECU J1-3 | **yes** |
| B/O | Left turn indicator | turn switch / flasher | **yes** |
| W/O | Right turn indicator | turn switch / flasher | **yes** |
| BL | High-beam indicator | dimmer switch | **yes** |

That accounts for about 12 of the 18 pins. **Record the other pins too**, even if they
look unused.

> ⚠️ The part labelled "gear position sensor" on the diagram has **one wire (Gr)
> to ground**, so it is only a neutral switch. That's why the stock dash only
> shows "N", and why the new dash infers the gear in software
> ([ADR 0003](../decisions/0003-gear-inference.md)).

## Fill this in

Measure against B (ground). Conditions: **OFF** = key off, **ON** = key on with engine off,
**RUN** = engine idling.

| Pin | Colour | OFF | ON | RUN | Notes |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |
| 6 | | | | | |
| 7 | | | | | |
| 8 | | | | | |
| 9 | | | | | |
| 10 | | | | | |
| 11 | | | | | |
| 12 | | | | | |
| 13 | | | | | |
| 14 | | | | | |
| 15 | | | | | |
| 16 | | | | | |
| 17 | | | | | |
| 18 | | | | | |

## Specific questions to answer

1. **Tach (Gr/W)**: does it swing 0↔12 V (push-pull) or does it only pull down
   (open collector)? Check the amplitude and duty cycle. Record the frequency at
   idle next to the RPM the dash shows. That gives `tachPulsesPerRevolution`.
2. **Speed sensor supply (R/BL)**: is it 12 V or 5 V? The bridge must provide the
   same voltage once the dash is gone.
3. **Speed signal (BL/O)**: is it open collector or push-pull, and what are its high
   and low levels? With the bike on the stand in gear, count pulses per wheel
   revolution. That's only a sanity check, because final calibration uses GPS.
4. **Fuel (W/BL)**: unplug the sender and measure its resistance at full and at
   reserve (check the manual, or measure with the tank full and nearly empty).
   Also note the voltage the dash puts on it. That sets the pull-up resistor.
5. **Neutral (Gr)**: confirm it reads about 0 V in neutral and floats or reads
   about 12 V in gear.
6. **MIL (B/N)**: confirm it's pulled low with key ON (bulb check) and released
   when the engine is running.
7. **Turn/high beam**: confirm they're +12 V when active (high-side). Check whether
   the turn signals flash at the same rate when the dash is unplugged: some
   flasher relays count the dash bulb as part of their load.
8. Write down the original odometer reading (1 102 km in the 2026-09 photos) for
   `Calibration.odometerOffsetKm`.

Commit the completed table. Then update `firmware/src/config.py`,
`docs/hardware/wiring.md` and the `uncalibrated` defaults in
`ios/Packages/DashCore/Sources/DashCore/Calibration.swift`.
