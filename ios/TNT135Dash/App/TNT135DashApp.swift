import SwiftUI

@main
struct TNT135DashApp: App {
    @State private var model = DashboardModel(source: Self.makeSource())
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DashboardView(model: model)
                .onAppear {
                    model.start()
                    // A dash must never auto-lock while riding.
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { model.persist() }
                }
        }
    }

    /// Simulator (or launch argument `-simulate`) uses fake data so the UI can be
    /// designed and demoed without the bike.
    private static func makeSource() -> any TelemetrySource {
        #if targetEnvironment(simulator)
        return SimulatedTelemetrySource()
        #else
        if ProcessInfo.processInfo.arguments.contains("-simulate") { return SimulatedTelemetrySource() }
        return BluetoothTelemetrySource()
        #endif
    }
}
