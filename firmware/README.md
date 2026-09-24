# Firmware — TNT135 sensor bridge (MicroPython)

Reads the bike harness through signal conditioning ([wiring](../docs/hardware/wiring.md))
and streams raw telemetry over BLE ([protocol](../protocol/README.md)).

## Layout
```
src/
  main.py          asyncio entry point: sample at 20 Hz → encode → BLE notify
  config.py        ALL pins and tuning (hardware-specific)
  tnt/
    protocol.py    packet encoder        (pure, tested on CPython)
    pulsemath.py   frequency + debounce  (pure, tested on CPython)
    sensors.py     PulseMeter / Lamps / AnalogMv (machine.*)
    ble.py         aioble GATT peripheral
tests/             pytest, runs on the host
```

## First-time setup
1. `make venv` (installs mpremote, esptool, pytest and ruff into `.venv`)
2. Download the **ESP32_GENERIC_P4 → "C6 WiFi/BLE"** firmware (v1.29+) from
   <https://micropython.org/download/ESP32_GENERIC_P4/> and flash it with the
   `esptool` command given on that page. Hold **BOOT** while plugging in USB-C if the
   board isn't detected.
3. `make deps` installs `aioble` onto the board.
4. `make deploy`

## Everyday
| Command | What |
|---|---|
| `make test` | Host unit tests (protocol vectors shared with iOS) |
| `make lint` | ruff |
| `make run` | Push the library + run `main.py` with output in the terminal |
| `make deploy` | Copy everything and reboot (runs on power-up) |
| `make repl` | Interactive REPL |

`PORT=/dev/cu.usbmodemXXXX make deploy` selects a specific board.
