import Foundation

/// Everything that turns raw bridge measurements into rider-facing numbers.
/// Persisted on the phone; the firmware never needs re-flashing to recalibrate.
public struct Calibration: Codable, Equatable, Sendable {
    /// Tach pulses per crankshaft revolution. Measure against the original dash.
    public var tachPulsesPerRevolution: Double
    /// km/h per 1 Hz of speed-sensor signal. Calibrate against iPhone GPS.
    public var kmhPerSpeedHz: Double
    /// Fuel sender curve: (millivolts at ADC, percent). Any order; interpolated linearly.
    public var fuelCurve: [FuelPoint]
    /// Learned engine-rpm-per-km/h ratio for each gear, index 0 = 1st gear.
    public var gearRatios: [Double]
    /// Kilometres on the original odometer when the new dash took over.
    public var odometerOffsetKm: Double

    public struct FuelPoint: Codable, Equatable, Sendable {
        public var millivolts: Double
        public var percent: Double
        public init(millivolts: Double, percent: Double) {
            self.millivolts = millivolts
            self.percent = percent
        }
    }

    public init(
        tachPulsesPerRevolution: Double, kmhPerSpeedHz: Double, fuelCurve: [FuelPoint],
        gearRatios: [Double], odometerOffsetKm: Double
    ) {
        self.tachPulsesPerRevolution = tachPulsesPerRevolution
        self.kmhPerSpeedHz = kmhPerSpeedHz
        self.fuelCurve = fuelCurve
        self.gearRatios = gearRatios
        self.odometerOffsetKm = odometerOffsetKm
    }

    /// Placeholder values so the UI works before calibration. None of these are
    /// measured on the real bike yet — see docs/hardware/signal-survey.md.
    public static let uncalibrated = Calibration(
        tachPulsesPerRevolution: 1,
        kmhPerSpeedHz: 0.5,
        fuelCurve: [.init(millivolts: 300, percent: 100), .init(millivolts: 2800, percent: 0)],
        gearRatios: [],
        odometerOffsetKm: 0
    )

    public func rpm(fromTachHz hz: Double) -> Double {
        tachPulsesPerRevolution > 0 ? hz * 60 / tachPulsesPerRevolution : 0
    }

    public func speedKmh(fromSpeedHz hz: Double) -> Double { hz * kmhPerSpeedHz }

    /// (km/h per Hz) / 3.6 = (m/s per Hz) = metres per pulse.
    public var metresPerSpeedPulse: Double { kmhPerSpeedHz / 3.6 }

    public func fuelPercent(fromMillivolts mv: Double) -> Double? {
        let points = fuelCurve.sorted { $0.millivolts < $1.millivolts }
        guard let first = points.first, let last = points.last else { return nil }
        if mv <= first.millivolts { return first.percent }
        if mv >= last.millivolts { return last.percent }
        for (a, b) in zip(points, points.dropFirst()) where mv <= b.millivolts {
            let t = (mv - a.millivolts) / (b.millivolts - a.millivolts)
            return a.percent + t * (b.percent - a.percent)
        }
        return last.percent
    }
}
