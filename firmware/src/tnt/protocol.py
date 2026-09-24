"""Telemetry packet encoder — see protocol/README.md (the source of truth).

Pure module: no `machine` imports, so it runs under CPython for tests.
"""

import struct

VERSION = 1
FORMAT = "<BBHHHHBBI"
SIZE = 16

FLAG_NEUTRAL = 1 << 0
FLAG_TURN_LEFT = 1 << 1
FLAG_TURN_RIGHT = 1 << 2
FLAG_HIGH_BEAM = 1 << 3
FLAG_MIL = 1 << 4
FLAG_FUEL_FAULT = 1 << 5

_U16_MAX = 0xFFFF
_U32_MAX = 0xFFFFFFFF


def _u16(value):
    return 0 if value < 0 else (_U16_MAX if value > _U16_MAX else int(value))


def encode(seq, tach_hz_x10, speed_hz_x10, fuel_mv, vbat_mv, flags, speed_pulses):
    """Pack one telemetry frame. Out-of-range values are clamped, never raised,
    so a bad sensor reading can't crash the main loop."""
    return struct.pack(
        FORMAT,
        VERSION,
        seq & 0xFF,
        _u16(tach_hz_x10),
        _u16(speed_hz_x10),
        _u16(fuel_mv),
        _u16(vbat_mv),
        flags & 0x3F,
        0,
        speed_pulses & _U32_MAX,
    )
