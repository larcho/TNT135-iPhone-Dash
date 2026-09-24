import DashCore
import SwiftUI

/// PLACEHOLDER layout so the data pipeline can be tested end to end.
/// The real design comes from Figma — see docs/design/figma-brief.md.
struct DashboardView: View {
    let model: DashboardModel

    private var state: DashState { model.state }

    var body: some View {
        HStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                IndicatorRow(flags: state.indicators)
                Text(state.rpm, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: 40, weight: .semibold, design: .rounded).monospacedDigit())
                Text("RPM").font(.caption).foregroundStyle(.secondary)
                ProgressView(value: min(state.rpm, 12_000), total: 12_000)
                    .tint(state.rpm > 10_000 ? .red : .orange)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                Text(state.speedKmh, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: 140, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
                Text("km/h").font(.title3).foregroundStyle(.secondary)
            }

            VStack(alignment: .trailing, spacing: 12) {
                Text(gearLabel)
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(state.gear == .neutral ? .green : .primary)
                Label(fuelLabel, systemImage: "fuelpump.fill")
                Text(String(format: "%.1f V", state.batteryVolts)).foregroundStyle(.secondary)
                Text(String(format: "%.0f km", state.odometerKm)).foregroundStyle(.secondary)
                ConnectionBadge(status: model.connection)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
    }

    private var gearLabel: String {
        switch state.gear {
        case .neutral: "N"
        case .gear(let n): "\(n)"
        case nil: "–"
        }
    }

    private var fuelLabel: String {
        state.fuelPercent.map { String(format: "%.0f %%", $0) } ?? "--"
    }
}

private struct IndicatorRow: View {
    let flags: TelemetryFrame.Flags

    var body: some View {
        HStack(spacing: 16) {
            lamp("arrowtriangle.left.fill", on: flags.contains(.turnLeft), color: .green)
            lamp("headlight.high.beam.fill", on: flags.contains(.highBeam), color: .blue)
            lamp("engine.combustion.fill", on: flags.contains(.malfunction), color: .orange)
            lamp("arrowtriangle.right.fill", on: flags.contains(.turnRight), color: .green)
        }
        .font(.title)
    }

    private func lamp(_ symbol: String, on: Bool, color: Color) -> some View {
        Image(systemName: symbol).foregroundStyle(on ? color : Color.white.opacity(0.15))
    }
}

private struct ConnectionBadge: View {
    let status: ConnectionStatus

    var body: some View {
        switch status {
        case .connected: EmptyView()
        case .idle, .scanning: Label("Searching for bike…", systemImage: "antenna.radiowaves.left.and.right")
        case .connecting: Label("Reconnecting…", systemImage: "antenna.radiowaves.left.and.right")
        case .bluetoothUnavailable(let reason): Label(reason, systemImage: "exclamationmark.triangle")
        case .firmwareMismatch(let v): Label("Bridge protocol v\(v) — update app", systemImage: "exclamationmark.triangle")
        }
    }
}

#Preview(traits: .landscapeLeft) {
    DashboardView(model: DashboardModel(source: SimulatedTelemetrySource()))
}
