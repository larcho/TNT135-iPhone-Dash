# TNT135 BLE Telemetry Protocol — v1

This folder defines the contract between the ESP32 firmware (`firmware/`) and
the iOS app (`ios/`). **It is the single source of truth.** Any change here must
be reflected in both implementations, and both test suites load
`test-vectors.json` to make sure they agree byte-for-byte.

## Design rule

The ESP32 is a **dumb, reliable sensor bridge**. It sends *raw measurements*
(pulse frequencies, millivolts, lamp states). All interpretation — km/h, RPM,
fuel %, gear inference, odometer — happens on the phone, where calibration
lives in one place and can be changed without re-flashing. See
[ADR 0001](../docs/decisions/0001-esp32-as-raw-sensor-bridge.md).

## GATT layout

| Item | UUID | Properties |
|---|---|---|
| Service `TNT135 Telemetry` | `5A463AEF-3E50-422C-BB65-71823EAA941A` | — |
| Characteristic `telemetry` | `E2362505-5861-44DD-A02D-186F6B8750F3` | read, notify |
| Characteristic `device-info` | `8B66B202-1392-4644-9FB1-650EDD5C4F19` | read (UTF-8 JSON) |

- Advertised name: `TNT135-Bridge`
- Notify rate: **20 Hz** (every 50 ms)
- The packet is 16 bytes and fits the default ATT MTU (23 → 20 payload bytes), so
  no MTU negotiation is required.

`device-info` example: `{"fw":"0.1.0","proto":1,"board":"waveshare-esp32-p4-wifi6"}`

## Telemetry packet v1 (16 bytes, little-endian)

| Offset | Type | Field | Unit / meaning |
|---|---|---|---|
| 0 | u8 | `version` | Always `1` for this layout |
| 1 | u8 | `seq` | Wraps 255 → 0. Lets the phone spot dropped packets |
| 2 | u16 | `tach_hz_x10` | Tach signal frequency × 10 (0.1 Hz resolution). 0 = engine stopped |
| 4 | u16 | `speed_hz_x10` | Speed-sensor pulse frequency × 10 |
| 6 | u16 | `fuel_mv` | Fuel sender voltage at the ADC pin, mV |
| 8 | u16 | `vbat_mv` | Battery voltage, mV (already scaled back from the divider) |
| 10 | u8 | `flags` | Bitfield, see below |
| 11 | u8 | `reserved` | Send `0`, ignore on receive |
| 12 | u32 | `speed_pulses` | Total speed-sensor pulses since ESP32 boot (for the odometer) |

### `flags`

| Bit | Name | Set when |
|---|---|---|
| 0 | `NEUTRAL` | Neutral switch closed (Gr wire pulled to ground) |
| 1 | `TURN_LEFT` | Left indicator lamp circuit (B/O) is live |
| 2 | `TURN_RIGHT` | Right indicator lamp circuit (W/O) is live |
| 3 | `HIGH_BEAM` | High-beam circuit (BL) is live |
| 4 | `MIL` | ECU trouble light (B/N) is on |
| 5 | `FUEL_FAULT` | Fuel sender reads open/short circuit |
| 6–7 | — | Reserved, send `0` |

## Rules for evolving the protocol

1. Adding a field to the end of the packet without moving existing ones is fine
   as long as the packet stays ≤ 20 bytes. Receivers must accept packets
   longer than they expect.
2. Changing or moving an existing field means bumping `version`. The phone
   rejects versions it doesn't know and shows "Firmware update required".
3. Add or update a case in `test-vectors.json` in the **same commit**.
