"""TNT135 sensor bridge: reads the bike harness and streams raw telemetry over BLE."""

import asyncio
import time

import config
from tnt import FIRMWARE_VERSION, protocol
from tnt.ble import TelemetryPeripheral
from tnt.sensors import AnalogMv, Lamps, PulseMeter

LAMP_FLAGS = {
    "neutral": protocol.FLAG_NEUTRAL,
    "turn_left": protocol.FLAG_TURN_LEFT,
    "turn_right": protocol.FLAG_TURN_RIGHT,
    "high_beam": protocol.FLAG_HIGH_BEAM,
    "mil": protocol.FLAG_MIL,
}


async def telemetry_loop(peripheral):
    tach = PulseMeter(config.TACH_PIN, config.TACH_MIN_PERIOD_US, config.PULSE_TIMEOUT_MS)
    speed = PulseMeter(config.SPEED_PIN, config.SPEED_MIN_PERIOD_US, config.PULSE_TIMEOUT_MS)
    lamps = Lamps(config.LAMP_PINS, LAMP_FLAGS, config.LAMP_ACTIVE_LOW, config.LAMP_DEBOUNCE_SAMPLES)
    fuel = AnalogMv(config.FUEL_ADC_PIN, config.ADC_SAMPLES)
    vbat = AnalogMv(config.VBAT_ADC_PIN, config.ADC_SAMPLES, config.VBAT_DIVIDER_RATIO)

    seq = 0
    while True:
        started = time.ticks_ms()
        tach_x10, _ = tach.sample()
        speed_x10, speed_total = speed.sample()
        fuel_mv = fuel.read_mv()
        flags = lamps.flags()
        if not config.FUEL_FAULT_LOW_MV <= fuel_mv <= config.FUEL_FAULT_HIGH_MV:
            flags |= protocol.FLAG_FUEL_FAULT

        peripheral.publish(
            protocol.encode(seq, tach_x10, speed_x10, fuel_mv, vbat.read_mv(), flags, speed_total)
        )
        seq = (seq + 1) & 0xFF

        elapsed = time.ticks_diff(time.ticks_ms(), started)
        await asyncio.sleep_ms(max(0, config.TELEMETRY_PERIOD_MS - elapsed))


async def main():
    peripheral = TelemetryPeripheral(
        config.BLE_NAME,
        {"fw": FIRMWARE_VERSION, "proto": protocol.VERSION, "board": config.BOARD},
    )
    await asyncio.gather(peripheral.advertise_forever(), telemetry_loop(peripheral))


asyncio.run(main())
