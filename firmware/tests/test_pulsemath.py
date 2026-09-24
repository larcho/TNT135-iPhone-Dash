from tnt.pulsemath import LampFilter, frequency_x10


def test_frequency_needs_at_least_one_period():
    assert frequency_x10(0, 1000) is None
    assert frequency_x10(3, 0) is None


def test_frequency_from_periods_and_span():
    # 25 periods of 5 ms each = 200 Hz (12 000 rpm at 1 pulse/rev)
    assert frequency_x10(25, 125_000) == 2000
    # 1 period of 43 ms ~= 23.3 Hz (1 400 rpm idle)
    assert frequency_x10(1, 43_000) == 233


def test_frequency_clamps_to_u16():
    assert frequency_x10(1000, 1) == 0xFFFF


def test_lamp_filter_ignores_single_sample_glitch():
    f = LampFilter(samples=2)
    assert f.update(True) is False
    assert f.update(False) is False
    assert f.update(True) is False
    assert f.update(True) is True
    assert f.update(False) is True
    assert f.update(False) is False
