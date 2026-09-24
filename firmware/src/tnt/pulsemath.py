"""Pure pulse-frequency math, shared by the hardware PulseMeter and tests."""


def frequency_x10(periods, span_us):
    """Frequency in 0.1 Hz units from `periods` full signal periods lasting
    `span_us` microseconds in total (edge-to-edge, not window length).

    Measuring edge-to-edge instead of counting pulses per fixed window removes
    most of the quantisation error at low RPM / low speed.
    Returns None when there isn't enough data to measure a period.
    """
    if periods < 1 or span_us <= 0:
        return None
    return min(0xFFFF, (periods * 10_000_000 + span_us // 2) // span_us)


class LampFilter:
    """Debounces a digital lamp input: the state changes only after
    `samples` consecutive identical reads."""

    def __init__(self, samples=2):
        self._needed = samples
        self._streak = 0
        self._candidate = False
        self.state = False

    def update(self, raw):
        if raw == self.state:
            self._streak = 0
            return self.state
        if raw == self._candidate:
            self._streak += 1
        else:
            self._candidate = raw
            self._streak = 1
        if self._streak >= self._needed:
            self.state = raw
            self._streak = 0
        return self.state
