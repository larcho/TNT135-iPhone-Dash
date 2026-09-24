import Foundation
import Testing
@testable import DashCore

/// Loads protocol/test-vectors.json — the same file the firmware tests use.
private struct Vectors: Decodable {
    struct Case: Decodable {
        struct Fields: Decodable {
            let version: UInt8, seq: UInt8, tach_hz_x10: UInt16, speed_hz_x10: UInt16
            let fuel_mv: UInt16, vbat_mv: UInt16, flags: UInt8, speed_pulses: UInt32
        }
        let name: String, fields: Fields, hex: String
    }
    let protocol_version: UInt8
    let cases: [Case]

    static func load() throws -> Vectors {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent().appending(path: "../../../../../protocol/test-vectors.json")
            .standardized
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }
}

private func data(hex: String) -> Data {
    Data(stride(from: 0, to: hex.count, by: 2).map { i in
        let start = hex.index(hex.startIndex, offsetBy: i)
        return UInt8(hex[start..<hex.index(start, offsetBy: 2)], radix: 16)!
    })
}

@Test func vectorsMatchSupportedVersion() throws {
    #expect(try Vectors.load().protocol_version == TelemetryFrame.supportedVersion)
}

@Test(arguments: try Vectors.load().cases.map(\.name))
func decodesSharedVector(name: String) throws {
    let c = try #require(try Vectors.load().cases.first { $0.name == name })
    let frame = try TelemetryFrame(decoding: data(hex: c.hex))
    #expect(frame == TelemetryFrame(
        sequence: c.fields.seq, tachHzX10: c.fields.tach_hz_x10, speedHzX10: c.fields.speed_hz_x10,
        fuelMillivolts: c.fields.fuel_mv, batteryMillivolts: c.fields.vbat_mv,
        flags: .init(rawValue: c.fields.flags), speedPulses: c.fields.speed_pulses))
}

@Test func rejectsShortPacket() {
    #expect(throws: TelemetryFrame.DecodeError.tooShort(3)) {
        try TelemetryFrame(decoding: Data([1, 0, 0]))
    }
}

@Test func rejectsUnknownVersion() {
    var bytes = [UInt8](repeating: 0, count: 16)
    bytes[0] = 2
    #expect(throws: TelemetryFrame.DecodeError.unsupportedVersion(2)) {
        try TelemetryFrame(decoding: Data(bytes))
    }
}

@Test func acceptsLongerPacketsFromNewerFirmware() throws {
    var bytes = [UInt8](repeating: 0, count: 20)
    bytes[0] = 1
    bytes[1] = 9
    #expect(try TelemetryFrame(decoding: Data(bytes)).sequence == 9)
}
