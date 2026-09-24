import Foundation

/// Integrates the bridge's cumulative speed-pulse counter into distance.
/// Only counts while the phone is connected — see docs/decisions/0001.
public struct Odometer: Codable, Equatable, Sendable {
    public private(set) var totalMetres: Double = 0
    private var lastPulses: UInt32?

    /// A single 50 ms frame can't legitimately contain more pulses than this;
    /// anything larger is treated as a glitch and dropped.
    public static let maxPulsesPerFrame: UInt32 = 1_000

    public init(totalMetres: Double = 0) { self.totalMetres = totalMetres }

    // Only the distance is persisted; the baseline must be re-taken after relaunch.
    private enum CodingKeys: String, CodingKey { case totalMetres }

    public mutating func ingest(pulses: UInt32, metresPerPulse: Double) {
        defer { lastPulses = pulses }
        guard let last = lastPulses else { return }
        // Counter went backwards: the ESP32 rebooted and started again from 0.
        let delta = pulses >= last ? pulses - last : pulses
        guard delta <= Self.maxPulsesPerFrame else { return }
        totalMetres += Double(delta) * metresPerPulse
    }

    /// Call on BLE disconnect so the first frame after reconnecting is a baseline.
    public mutating func resetBaseline() { lastPulses = nil }
}
