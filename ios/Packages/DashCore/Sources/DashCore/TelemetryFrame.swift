import Foundation

/// One raw telemetry packet from the ESP32 bridge. Layout: `protocol/README.md`.
public struct TelemetryFrame: Equatable, Sendable {
    public static let supportedVersion: UInt8 = 1
    public static let minimumSize = 16

    public struct Flags: OptionSet, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }

        public static let neutral = Flags(rawValue: 1 << 0)
        public static let turnLeft = Flags(rawValue: 1 << 1)
        public static let turnRight = Flags(rawValue: 1 << 2)
        public static let highBeam = Flags(rawValue: 1 << 3)
        public static let malfunction = Flags(rawValue: 1 << 4)
        public static let fuelSensorFault = Flags(rawValue: 1 << 5)
    }

    public enum DecodeError: Error, Equatable {
        case tooShort(Int)
        case unsupportedVersion(UInt8)
    }

    public var sequence: UInt8
    public var tachHzX10: UInt16
    public var speedHzX10: UInt16
    public var fuelMillivolts: UInt16
    public var batteryMillivolts: UInt16
    public var flags: Flags
    public var speedPulses: UInt32

    public init(
        sequence: UInt8, tachHzX10: UInt16, speedHzX10: UInt16, fuelMillivolts: UInt16,
        batteryMillivolts: UInt16, flags: Flags, speedPulses: UInt32
    ) {
        self.sequence = sequence
        self.tachHzX10 = tachHzX10
        self.speedHzX10 = speedHzX10
        self.fuelMillivolts = fuelMillivolts
        self.batteryMillivolts = batteryMillivolts
        self.flags = flags
        self.speedPulses = speedPulses
    }

    /// Longer packets are accepted: newer firmware may append fields (protocol rule 1).
    public init(decoding data: Data) throws(DecodeError) {
        guard data.count >= Self.minimumSize else { throw .tooShort(data.count) }
        let bytes = [UInt8](data)
        guard bytes[0] == Self.supportedVersion else { throw .unsupportedVersion(bytes[0]) }

        func u16(_ at: Int) -> UInt16 { UInt16(bytes[at]) | UInt16(bytes[at + 1]) << 8 }
        func u32(_ at: Int) -> UInt32 { UInt32(u16(at)) | UInt32(u16(at + 2)) << 16 }

        self.init(
            sequence: bytes[1],
            tachHzX10: u16(2),
            speedHzX10: u16(4),
            fuelMillivolts: u16(6),
            batteryMillivolts: u16(8),
            flags: Flags(rawValue: bytes[10]),
            speedPulses: u32(12)
        )
    }

    public var tachHz: Double { Double(tachHzX10) / 10 }
    public var speedHz: Double { Double(speedHzX10) / 10 }
}
