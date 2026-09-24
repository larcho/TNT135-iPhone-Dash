import DashCore
import Foundation
import Observation

@Observable
final class DashboardModel {
    private(set) var state = DashState()
    private(set) var connection: ConnectionStatus = .idle

    private let source: any TelemetrySource
    private let store: SettingsStore
    private var processor: DashProcessor
    private var task: Task<Void, Never>?
    private var framesSinceSave = 0

    init(source: any TelemetrySource, store: SettingsStore = SettingsStore()) {
        self.source = source
        self.store = store
        let calibration = source.isSimulated ? .demo : store.loadCalibration()
        processor = DashProcessor(calibration: calibration, odometer: store.loadOdometer())
    }

    func start() {
        guard task == nil else { return }
        task = Task { [source] in
            for await event in source.events() {
                handle(event)
            }
        }
    }

    func persist() {
        guard !source.isSimulated else { return }
        store.save(odometer: processor.odometer)
    }

    private func handle(_ event: TelemetryEvent) {
        switch event {
        case .status(let status):
            connection = status
            if status != .connected { processor.connectionLost() }
        case .frame(let frame):
            processor.ingest(frame)
            state = processor.state
            framesSinceSave += 1
            if framesSinceSave >= 200 {  // ~10 s at 20 Hz
                framesSinceSave = 0
                persist()
            }
        }
    }
}

extension Calibration {
    /// Matches SimulatedTelemetrySource so the simulator shows a working gear indicator.
    static let demo: Calibration = {
        var cal = Calibration.uncalibrated
        cal.gearRatios = SimulatedTelemetrySource.gearRatios
        cal.odometerOffsetKm = 1_102
        return cal
    }()
}
