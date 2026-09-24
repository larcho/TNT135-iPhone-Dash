"""Board wiring and tuning. Everything hardware-specific lives here.

Pin numbers target the Waveshare ESP32-P4-WIFI6 header (see
MATERIALS/ESP32-P4). They are PROVISIONAL until checked against the board
schematic: on the ESP32-P4, ADC1 is on GPIO16-23, so the analog inputs must
stay in that range. See docs/hardware/wiring.md for the signal conditioning
between the bike harness and these pins. Never wire a 12 V bike signal
straight to a GPIO.
"""

BOARD = "waveshare-esp32-p4-wifi6"
BLE_NAME = "TNT135-Bridge"

# --- Pulse inputs (opto-isolated, output pulls GPIO low on each pulse) ---
TACH_PIN = 4  # ECU J1-6, Gr/W
SPEED_PIN = 5  # speed sensor signal, BL/O

# Edges closer together than this are treated as noise and ignored.
# Tach: 12 000 rpm at 1 pulse/rev = 200 Hz = 5 000 us, so 1 000 us leaves margin.
TACH_MIN_PERIOD_US = 1_000
SPEED_MIN_PERIOD_US = 300
# No edge for this long means the signal is at zero (engine stopped / bike still).
PULSE_TIMEOUT_MS = 600

# --- Lamp inputs (opto-isolated, active LOW at the GPIO) ---
LAMP_PINS = {
    "neutral": 26,  # Gr    (neutral switch to ground)
    "turn_left": 27,  # B/O
    "turn_right": 32,  # W/O
    "high_beam": 33,  # BL
    "mil": 46,  # B/N   (ECU trouble light)
}
LAMP_ACTIVE_LOW = True
LAMP_DEBOUNCE_SAMPLES = 2

# --- Analog inputs (ADC1 only: GPIO16-23 on ESP32-P4) ---
FUEL_ADC_PIN = 20  # W/BL via pull-up to 3V3, see wiring.md
VBAT_ADC_PIN = 21  # R/W via 100k / 22k divider
VBAT_DIVIDER_RATIO = (100 + 22) / 22
ADC_SAMPLES = 16
FUEL_FAULT_LOW_MV = 60  # sender shorted to ground
FUEL_FAULT_HIGH_MV = 3200  # sender open circuit / unplugged

# --- Timing ---
TELEMETRY_PERIOD_MS = 50  # 20 Hz notify
