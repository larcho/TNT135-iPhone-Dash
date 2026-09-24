# Wiring & signal conditioning

**Rule #1: no bike signal ever connects directly to an ESP32 GPIO.** The bike runs
at 12–14.5 V with spikes, and the ESP32-P4 pins are 3.3 V and not 5 V-tolerant.

Status: **provisional** until the [signal survey](signal-survey.md) is done.
The GPIO numbers match `firmware/src/config.py`.

## Voltage domains

There are three voltages in this build, and only the conditioning circuits cross between them:

| Domain | Where | What lives there |
|---|---|---|
| **12 V** (9–15 V + spikes) | All 18 connector pins, fuse, TVS, buck **input**, opto **input** side, divider top | Bike harness |
| **5 V** | Buck **output** → ESP32 board VBUS/5V pin | Board power only, no signals |
| **3.3 V** | ESP32 GPIOs, opto **output** side, pull-ups, fuel pull-up, divider bottom | Everything the ESP32 reads |

The ESP32 board makes its own 3.3 V from the 5 V input. **No 12 V or 5 V net may touch a GPIO.**
Only the fuse, buck and opto inputs connect to the 18-pin header's 12 V pins.

## Block diagram

Visual version (FigJam): [TNT135 18-pin to ESP32-P4 wiring](https://www.figma.com/board/ngvpqFNMf41GJRG7fQoVx4)

```
 18-pin dash connector (bike harness)
 ┌────────────────────────┐
 │ R/W  (ign +12V) ───────┼──[2A fuse]──[TVS]──► 12→5 V buck ──► ESP32 5V/VBUS
 │                        │                 └──► opto input supply (low-side signals)
 │                        │                 └──► 100k/22k divider ──► GPIO21 (ADC, vbat)
 │ B    (ground) ─────────┼──────────────────────► GND (common)
 │ B/O  left turn  ───────┼──► opto ch1 (high-side) ──► GPIO27
 │ W/O  right turn ───────┼──► opto ch2 (high-side) ──► GPIO32
 │ BL   high beam  ───────┼──► opto ch3 (high-side) ──► GPIO33
 │ Gr   neutral sw ───────┼──► opto ch4 (low-side)  ──► GPIO26
 │ B/N  MIL        ───────┼──► opto ch5 (low-side)  ──► GPIO46
 │ Gr/W tach       ───────┼──► opto ch6 (TBD by survey) ──► GPIO4
 │ BL/O speed sig  ───────┼──► opto ch7 (TBD by survey) ──► GPIO5
 │ R/BL speed supply ◄────┼── 12 V or 5 V, whatever the dash supplied (survey Q2)
 │ W/BL fuel sender ──────┼──► pull-up + RC filter ──► GPIO20 (ADC)
 └────────────────────────┘
```

## Input circuits

### Opto-isolated digital inputs (PC817)

A multi-channel **PC817 optocoupler module** does the level shifting and protects the
ESP32. Output side: the phototransistor pulls the GPIO to GND and the GPIO's internal
pull-up (or the module's pull-up to **3V3, not 5 V**) pulls it high. So every input
is **active-low** at the ESP32 (`LAMP_ACTIVE_LOW = True`).

- **High-side signals** (turn L/R, high beam): the wire is +12 V when active.
  `signal → IN+`, `IN− → GND`.
- **Low-side signals** (neutral, MIL): the switch or ECU pulls the wire to ground
  when active. `R/W (+12 V) → IN+`, `IN− → signal`. The opto LED also replaces the
  lamp load the stock dash used to provide.
- Check the module's input resistor suits 12 V, aiming for about 5–10 mA of LED current.
  Many modules come in 3.3 V, 5 V, 12 V and 24 V input variants, so order the 12 V one.

### Tach & speed (pulse inputs)

A PC817 handles these frequencies (tach ≤ 200 Hz, speed ≤ ~1 kHz) with a 1–4.7 kΩ
pull-up. Wire the input side as high-side or low-side depending on the survey
results (push-pull vs open collector). The firmware counts falling edges and
ignores edges closer together than `*_MIN_PERIOD_US`.

### Fuel sender (analog, not isolated)

The sender is a variable resistor to chassis ground:

```
3V3 ──[R_pu]──┬──[1k]──┬── GPIO20 (ADC1)
              │        └──[100nF]── GND
           W/BL (sender) ── chassis
```

Choose `R_pu` once you know the sender's range, so the ADC swing is as large as
possible within 0.1–3.0 V. A lower `R_pu` means a bigger swing but more current;
keep it under about 15 mA. Map the voltage to a percentage on the phone (`Calibration.fuelCurve`).

### Battery voltage

`R/W ──[100k]──┬── GPIO21 (ADC1) ──[22k]── GND`, with 100 nF from the ADC pin to GND.
At 16 V the pin sees 2.9 V. A 3.3 V zener across the 22 kΩ resistor is cheap insurance.

## ADC pins on the ESP32-P4

On the ESP32-P4, ADC1 is on GPIO16–23. Keep both analog inputs there. Check the
Waveshare schematic to see which of GPIO20–23 are free on the header (the pinout
image in `MATERIALS/ESP32-P4` shows GPIO20–23 on the right-hand side).
