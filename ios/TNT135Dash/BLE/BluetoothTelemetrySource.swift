import CoreBluetooth
import DashCore
import Foundation

/// CoreBluetooth central for the ESP32 bridge. GATT layout: protocol/README.md.
///
/// Reconnection strategy: after the first connection the peripheral identifier
/// is remembered, and a pending `connect` is kept open forever. iOS completes it
/// as soon as the bridge powers up with the ignition — even in the background.
final class BluetoothTelemetrySource: NSObject, TelemetrySource {
    static let serviceUUID = CBUUID(string: "5A463AEF-3E50-422C-BB65-71823EAA941A")
    static let telemetryUUID = CBUUID(string: "E2362505-5861-44DD-A02D-186F6B8750F3")
    static let deviceInfoUUID = CBUUID(string: "8B66B202-1392-4644-9FB1-650EDD5C4F19")
    private static let restoreIdentifier = "tnt135.central"
    private static let knownPeripheralKey = "ble.knownPeripheral"

    let isSimulated = false

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var continuation: AsyncStream<TelemetryEvent>.Continuation?

    func events() -> AsyncStream<TelemetryEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
            self.central = CBCentralManager(
                delegate: self, queue: .main,
                options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreIdentifier])
        }
    }

    private func emit(_ event: TelemetryEvent) { continuation?.yield(event) }

    private func connectToBridge() {
        guard let central, central.state == .poweredOn else { return }
        if let id = UserDefaults.standard.string(forKey: Self.knownPeripheralKey).flatMap(UUID.init),
           let known = central.retrievePeripherals(withIdentifiers: [id]).first {
            connect(known)
        } else {
            emit(.status(.scanning))
            central.scanForPeripherals(withServices: [Self.serviceUUID])
        }
    }

    private func connect(_ target: CBPeripheral) {
        peripheral = target
        target.delegate = self
        emit(.status(.connecting))
        central?.connect(target)
    }
}

// Delegate callbacks arrive on the main queue (see `queue: .main`), so the
// conformances are MainActor-isolated (SE-0470).
extension BluetoothTelemetrySource: @MainActor CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: connectToBridge()
        case .unauthorized: emit(.status(.bluetoothUnavailable("Bluetooth permission denied")))
        case .poweredOff: emit(.status(.bluetoothUnavailable("Bluetooth is off")))
        default: emit(.status(.bluetoothUnavailable("Bluetooth unavailable")))
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        if let restored = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first {
            peripheral = restored
            restored.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        central.stopScan()
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: Self.knownPeripheralKey)
        connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        emit(.status(.connected))
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        emit(.status(.connecting))
        central.connect(peripheral)  // pending forever until the bridge is back
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        central.connect(peripheral)
    }
}

extension BluetoothTelemetrySource: @MainActor CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else { return }
        peripheral.discoverCharacteristics([Self.telemetryUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let telemetry = service.characteristics?.first(where: { $0.uuid == Self.telemetryUUID }) else {
            return
        }
        peripheral.setNotifyValue(true, for: telemetry)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard let data = characteristic.value else { return }
        switch Result(catching: { () throws(TelemetryFrame.DecodeError) in try TelemetryFrame(decoding: data) }) {
        case .success(let frame): emit(.frame(frame))
        case .failure(.unsupportedVersion(let version)): emit(.status(.firmwareMismatch(version)))
        case .failure(.tooShort): break  // drop; the sequence gap is counted downstream
        }
    }
}
