"""Hardware-facing sensor readers (MicroPython only)."""

import time

from machine import ADC, Pin

from tnt.pulsemath import LampFilter, frequency_x10


class PulseMeter:
    """Measures the frequency of a pulse train on a GPIO.

    The IRQ handler only bumps cumulative counters and never resets them, so
    `sample()` needs no locking: it reads (count, last_edge) consistently and
    works on deltas since its previous call.
    """

    def __init__(self, pin_no, min_period_us, timeout_ms):
        self._min_period_us = min_period_us
        self._timeout_us = timeout_ms * 1000
        self.total = 0
        self._last_us = time.ticks_us()
        self._prev_total = 0
        self._prev_last_us = self._last_us
        self._freq_x10 = 0
        self._pin = Pin(pin_no, Pin.IN, Pin.PULL_UP)
        self._pin.irq(self._on_edge, Pin.IRQ_FALLING)

    def _on_edge(self, _pin):
        now = time.ticks_us()
        if time.ticks_diff(now, self._last_us) < self._min_period_us:
            return  # glitch
        self._last_us = now
        self.total += 1

    def _snapshot(self):
        while True:
            total, last = self.total, self._last_us
            if total == self.total:
                return total, last

    def sample(self):
        """Returns (frequency in 0.1 Hz, cumulative pulse count)."""
        total, last = self._snapshot()
        periods = total - self._prev_total
        if periods > 0:
            span = time.ticks_diff(last, self._prev_last_us)
            if span <= self._timeout_us:
                self._freq_x10 = frequency_x10(periods, span) or 0
            # else: first pulses after standing still; the gap isn't a real
            # period, so wait for the next window to measure.
            self._prev_total, self._prev_last_us = total, last
        elif time.ticks_diff(time.ticks_us(), last) > self._timeout_us:
            self._freq_x10 = 0
        return self._freq_x10, total


class Lamps:
    """Debounced digital lamp inputs → protocol flag bits."""

    def __init__(self, pins_by_name, flag_by_name, active_low, debounce_samples):
        self._inputs = []
        for name, pin_no in pins_by_name.items():
            pin = Pin(pin_no, Pin.IN, Pin.PULL_UP if active_low else Pin.PULL_DOWN)
            self._inputs.append((pin, flag_by_name[name], LampFilter(debounce_samples)))
        self._active_low = active_low

    def flags(self):
        bits = 0
        for pin, flag, filt in self._inputs:
            raw = pin.value() == (0 if self._active_low else 1)
            if filt.update(raw):
                bits |= flag
        return bits


class AnalogMv:
    """Averaged, factory-calibrated ADC reading in millivolts."""

    def __init__(self, pin_no, samples, scale=1.0):
        self._adc = ADC(Pin(pin_no), atten=ADC.ATTN_11DB)
        self._samples = samples
        self._scale = scale

    def read_mv(self):
        acc = 0
        for _ in range(self._samples):
            acc += self._adc.read_uv()
        return int(acc / self._samples / 1000 * self._scale)
