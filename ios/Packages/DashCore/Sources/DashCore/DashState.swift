import Foundation

/// Rider-facing state derived from raw frames + calibration. Drives the UI.
public struct DashState: Equatable, Sendable {
    public var rpm: Double = 0
    public var speedKmh: Double = 0
    public var fuelPercent: Double?
    public var batteryVolts: Double = 0
    public var gear: GearEstimator.Gear?
    public var indicators: TelemetryFrame.Flags = []
    public var odometerKm: Double = 0
    public var droppedFrames = 0

    public init() {}
}

/// Stateful pipeline: feed frames in, read `state` out.
public struct DashProcessor: Sendable {
    public var calibration: Calibration
    public private(set) var state = DashState()
    public private(set) var odometer: Odometer

    private var gearEstimator = GearEstimator()
    private var lastSequence: UInt8?
    /// Fuel sloshes; smooth over ~10 s at 20 Hz.
    private let fuelSmoothing = 0.005

    public init(calibration: Calibration, odometer: Odometer = Odometer()) {
        self.calibration = calibration
        self.odometer = odometer
    }

    public mutating func ingest(_ frame: TelemetryFrame) {
        if let last = lastSequence {
            let gap = Int(frame.sequence &- last) - 1
            if gap > 0 { state.droppedFrames += gap }
        }
        lastSequence = frame.sequence

        state.rpm = calibration.rpm(fromTachHz: frame.tachHz)
        state.speedKmh = calibration.speedKmh(fromSpeedHz: frame.speedHz)
        state.batteryVolts = Double(frame.batteryMillivolts) / 1000
        state.indicators = frame.flags

        if frame.flags.contains(.fuelSensorFault) {
            state.fuelPercent = nil
        } else if let raw = calibration.fuelPercent(fromMillivolts: Double(frame.fuelMillivolts)) {
            state.fuelPercent = state.fuelPercent.map { $0 + (raw - $0) * fuelSmoothing } ?? raw
        }

        state.gear = gearEstimator.update(
            rpm: state.rpm, speedKmh: state.speedKmh,
            neutral: frame.flags.contains(.neutral), ratios: calibration.gearRatios)

        odometer.ingest(pulses: frame.speedPulses, metresPerPulse: calibration.metresPerSpeedPulse)
        state.odometerKm = calibration.odometerOffsetKm + odometer.totalMetres / 1000
    }

    public mutating func connectionLost() {
        lastSequence = nil
        odometer.resetBaseline()
    }
}
