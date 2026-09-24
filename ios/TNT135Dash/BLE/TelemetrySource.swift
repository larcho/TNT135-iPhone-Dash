import DashCore

enum ConnectionStatus: Equatable, Sendable {
    case idle
    case bluetoothUnavailable(String)
    case scanning
    case connecting
    case connected
    /// Bridge speaks a protocol version this app doesn't know.
    case firmwareMismatch(UInt8)
}

enum TelemetryEvent: Sendable {
    case status(ConnectionStatus)
    case frame(TelemetryFrame)
}

protocol TelemetrySource: AnyObject {
    var isSimulated: Bool { get }
    /// Single consumer. Starts the source on first iteration.
    func events() -> AsyncStream<TelemetryEvent>
}
