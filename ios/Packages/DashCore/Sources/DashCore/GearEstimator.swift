import Foundation

/// The TNT135 only has a neutral switch, so the gear is inferred from the
/// ratio of engine rpm to road speed. See docs/decisions/0003-gear-inference.md.
public struct GearEstimator: Sendable {
    public enum Gear: Equatable, Sendable {
        case neutral
        case gear(Int)
    }

    /// Max distance between measured and learned ratio, in log space (~8 %).
    public var tolerance = 0.08
    /// Below this the ratio is dominated by noise and clutch slip.
    public var minimumSpeedKmh = 5.0
    public var minimumRpm = 1_500.0
    /// Consecutive matching frames required before the displayed gear changes (3 × 50 ms).
    public var framesToSwitch = 3

    private var candidate: Gear?
    private var candidateFrames = 0
    public private(set) var current: Gear?

    public init() {}

    /// Returns the gear to display, or nil when unknown (clutch in, coasting, uncalibrated).
    @discardableResult
    public mutating func update(rpm: Double, speedKmh: Double, neutral: Bool, ratios: [Double]) -> Gear? {
        let measured = neutral ? .neutral : Self.match(rpm: rpm, speedKmh: speedKmh, ratios: ratios,
                                                         tolerance: tolerance, minimumSpeedKmh: minimumSpeedKmh,
                                                         minimumRpm: minimumRpm)
        if measured == current {
            candidate = nil
            candidateFrames = 0
        } else if measured == candidate {
            candidateFrames += 1
        } else {
            candidate = measured
            candidateFrames = 1
        }
        // Neutral comes from a real switch — show it immediately.
        if candidateFrames >= framesToSwitch || measured == .neutral {
            current = measured
            candidate = nil
            candidateFrames = 0
        }
        return current
    }

    static func match(rpm: Double, speedKmh: Double, ratios: [Double], tolerance: Double,
                      minimumSpeedKmh: Double, minimumRpm: Double) -> Gear? {
        guard speedKmh >= minimumSpeedKmh, rpm >= minimumRpm, !ratios.isEmpty else { return nil }
        let measured = log(rpm / speedKmh)
        let best = ratios.enumerated()
            .filter { $0.element > 0 }
            .min { abs(log($0.element) - measured) < abs(log($1.element) - measured) }
        guard let best, abs(log(best.element) - measured) <= tolerance else { return nil }
        return .gear(best.offset + 1)
    }
}
