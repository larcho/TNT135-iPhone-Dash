# Power

## Does the ESP32 need a 12 V adapter? Yes.

The Waveshare ESP32-P4-WIFI6 runs on **5 V** (USB-C, or the VBUS pin). The bike's
electrical system is nominally 12 V, but in practice it's messy:

- 13.8–14.5 V while the engine is running (rectifier/regulator charging)
- dips to about 9 V while cranking
- spikes and load-dump transients from the starter, horn and flasher

What you need:

1. **Automotive DC-DC buck converter, 12 V → 5 V**, rated for a wide input
   (**8–36 V or better**) and **≥ 2 A** output. The ESP32-P4 and C6 draw well under
   1 A; the headroom keeps the converter cool. Buy a **potted/waterproof**
   one, since it will live in the headlight shell.
2. **Inline fuse, 2 A**, on the converter's input, as close to the tap point as possible.
3. **TVS diode** across the converter input (for example SMBJ20A). It clamps spikes the
   converter isn't rated for. Some converters include one; check the datasheet.
4. Feed it from **R/W (ignition-switched +12 V)**, not R (constant). The bridge then
   turns off with the key and can't drain the battery. The phone shows "Searching for
   bike…" while the key is off, and iOS reconnects on its own when the key turns on.

Grounds: the buck converter is non-isolated, so ESP32 GND = bike ground (B). That's
intended, because the fuel sender measurement needs a common ground.

## Quad Lock wireless charging head

The Quad Lock head comes in a **12 V hard-wired** version (bare red/black leads) and a
**USB** version (see `MATERIALS/quadlock-wirless-charging-head`). For this build:

- **12 V version (recommended):** wire it to R/W through its own fuse. It then
  charges only with the ignition on.
- **USB version:** it would need its own 5 V/3 A USB-C PD-capable supply. Don't share
  the ESP32's buck unless that converter is rated for both loads.

A 125–135 cc stator doesn't have a lot of spare power. Wireless charging draws about
15 W, which is fine on the charging system but noticeable at idle with the lights on.
Watch the battery voltage the dash reports (the `vbat` field) during the first rides.

## iPhone safety notes

- **Vibration:** Apple warns that high-amplitude motorcycle vibration can damage
  iPhone camera OIS/autofocus, and recommends a vibration-dampening mount. Quad Lock
  sells a vibration dampener for its motorcycle mounts. Use one.
- **Heat:** direct sun, wireless charging and a bright screen all heat the phone.
  iOS will dim the display and may pause charging. The UI design should stay readable
  when dimmed (see the design brief).
