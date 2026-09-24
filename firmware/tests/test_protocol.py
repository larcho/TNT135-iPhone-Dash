import json
from pathlib import Path

import pytest

from tnt import protocol

VECTORS = json.loads(
    (Path(__file__).resolve().parents[2] / "protocol" / "test-vectors.json").read_text()
)


def test_vectors_match_protocol_version():
    assert VECTORS["protocol_version"] == protocol.VERSION


@pytest.mark.parametrize("case", VECTORS["cases"], ids=lambda c: c["name"])
def test_encode_matches_shared_vectors(case):
    f = case["fields"]
    packet = protocol.encode(
        f["seq"], f["tach_hz_x10"], f["speed_hz_x10"], f["fuel_mv"], f["vbat_mv"], f["flags"],
        f["speed_pulses"],
    )
    assert len(packet) == protocol.SIZE
    assert packet.hex() == case["hex"]


def test_out_of_range_values_are_clamped_not_raised():
    packet = protocol.encode(256, -5, 70_000, 1, 1, 0xFF, 2**32 + 3)
    assert packet[1] == 0  # seq wraps
    assert packet[2:4] == b"\x00\x00"  # negative clamps to 0
    assert packet[4:6] == b"\xff\xff"  # overflow clamps to max
    assert packet[10] == 0x3F  # reserved flag bits cleared
    assert packet[12:16] == (3).to_bytes(4, "little")  # pulse counter wraps
