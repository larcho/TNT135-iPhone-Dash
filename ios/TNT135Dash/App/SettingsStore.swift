import DashCore
import Foundation

/// Calibration + odometer persisted as JSON in UserDefaults.
struct SettingsStore {
    private let defaults: UserDefaults
    private let calibrationKey = "calibration.v1"
    private let odometerKey = "odometer.v1"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func loadCalibration() -> Calibration { load(calibrationKey) ?? .uncalibrated }
    func save(calibration: Calibration) { save(calibration, key: calibrationKey) }

    func loadOdometer() -> Odometer { load(odometerKey) ?? Odometer() }
    func save(odometer: Odometer) { save(odometer, key: odometerKey) }

    private func load<T: Decodable>(_ key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
}
