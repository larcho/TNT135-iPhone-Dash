import DashCore
import Foundation

/// Fake ride for the simulator and UI design: accelerates through the gears,
/// cruises, brakes to a stop in neutral, and blinks an indicator. Frames are
/// raw, exactly as the bridge would send them, so the full DashCore pipeline runs.
final class SimulatedTelemetrySource: TelemetrySource {
    /// rpm per km/h for each gear — plausible, not measured.
    static let gearRatios = [230.0, 150.0, 112.0, 90.0]

    let isSimulated = true

    func events() -> AsyncStream<TelemetryEvent> {
        AsyncStream { continuation in
            let task = Task {
                continuation.yield(.status(.connected))
                var seq: UInt8 = 0
                var pulses: Double = 0
                let start = ContinuousClock.now
                while !Task.isCancelled {
                    let t = (ContinuousClock.now - start) / .seconds(1)
                    let frame = Self.frame(at: t.truncatingRemainder(dividingBy: 40), seq: seq, pulses: &pulses)
                    continuation.yield(.frame(frame))
                    seq &+= 1
                    try? await Task.sleep(for: .milliseconds(50))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func frame(at t: Double, seq: UInt8, pulses: inout Double) -> TelemetryFrame {
        let (speed, gear): (Double, Int?) = switch t {
        case ..<3: (0, nil)
        case ..<7: ((t - 3) * 6, 1)
        case ..<11: (24 + (t - 7) * 5, 2)
        case ..<16: (44 + (t - 11) * 4, 3)
        case ..<26: (64 + (t - 16) * 1.5, 4)
        case ..<34: (max(0, 79 - (t - 26) * 10), 4)
        default: (0, nil)
        }
        let idle = 1_400 + 60 * sin(t * 3)
        let rpm = gear.flatMap { speed >= 5 ? speed * gearRatios[$0 - 1] : nil } ?? idle
        let kmhPerHz = Calibration.uncalibrated.kmhPerSpeedHz
        pulses += speed / kmhPerHz * 0.05

        var flags: TelemetryFrame.Flags = []
        if gear == nil || speed < 5 { flags.insert(.neutral) }
        if (20..<26).contains(t), Int(t * 3) % 2 == 0 { flags.insert(.turnLeft) }
        if t > 12 { flags.insert(.highBeam) }

        return TelemetryFrame(
            sequence: seq,
            tachHzX10: UInt16(min(rpm, 12_000) / 60 * 10),
            speedHzX10: UInt16(speed / kmhPerHz * 10),
            fuelMillivolts: 1_300,
            batteryMillivolts: gear == nil ? 12_700 : 14_100,
            flags: flags,
            speedPulses: UInt32(pulses))
    }
}
