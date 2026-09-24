# ADR 0002 — BLE GATT transport, MicroPython firmware

**Status:** accepted (2026-09-24)

## Decision
- **Transport: BLE GATT notifications** at 20 Hz. The packet is 16 bytes, which fits
  the default MTU. iOS supports background reconnection and state restoration for
  BLE centrals (`bluetooth-central` background mode). Wi-Fi would take over the
  phone's network connection, and Classic Bluetooth requires MFi.
- **Firmware: MicroPython** with `aioble`. MicroPython v1.27 added the ESP32-P4, and
  micropython.org publishes an `ESP32_GENERIC_P4` **"C6 WiFi/BLE"** build (v1.29.0,
  2026-08-24) that exposes BLE through the on-board ESP32-C6 co-processor.

## Risks
- BLE on the P4 goes through the C6 co-processor over SDIO (ESP-Hosted), which is
  newer and less proven than BLE on single-chip ESP32s. **The first
  hardware task is a BLE spike:** flash the C6 build, advertise, connect from the
  app, and check that 20 Hz notifications stay stable for 30 minutes.
- **Fallback:** the firmware only uses `machine.Pin`, `machine.ADC` and `aioble`,
  so it ports to a cheaper **ESP32-S3 or ESP32-C6** board with native BLE by
  changing `config.py`. The P4's main strengths (MIPI display/camera) aren't
  used in this project, because the iPhone is the display.
