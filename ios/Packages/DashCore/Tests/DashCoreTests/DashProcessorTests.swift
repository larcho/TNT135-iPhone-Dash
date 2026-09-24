import Testing
@testable import DashCore

private func frame(seq: UInt8, tach: UInt16 = 0, speed: UInt16 = 0, flags: TelemetryFrame.Flags = [],
                   pulses: UInt32 = 0) -> TelemetryFrame {
    TelemetryFrame(sequence: seq, tachHzX10: tach, speedHzX10: speed, fuelMillivolts: 1_550,
                   batteryMillivolts: 13_800, flags: flags, speedPulses: pulses)
}

@Test func countsDroppedFramesAcrossWrap() {
    var p = DashProcessor(calibration: .uncalibrated)
    p.ingest(frame(seq: 254))
    p.ingest(frame(seq: 1))  // 255 and 0 missing
    #expect(p.state.droppedFrames == 2)
}

@Test func derivesRiderValues() {
    var p = DashProcessor(calibration: .uncalibrated)
    p.ingest(frame(seq: 0, tach: 1_000, speed: 600, flags: [.neutral, .highBeam]))
    #expect(p.state.rpm == 6_000)
    #expect(p.state.speedKmh == 30)
    #expect(p.state.batteryVolts == 13.8)
    #expect(p.state.gear == .neutral)
    #expect(p.state.indicators.contains(.highBeam))
    #expect(p.state.fuelPercent == 50)
}

@Test func fuelFaultHidesFuelLevel() {
    var p = DashProcessor(calibration: .uncalibrated)
    p.ingest(frame(seq: 0, flags: [.fuelSensorFault]))
    #expect(p.state.fuelPercent == nil)
}

@Test func odometerIncludesOriginalDashOffset() {
    var cal = Calibration.uncalibrated
    cal.odometerOffsetKm = 1_102
    var p = DashProcessor(calibration: cal)
    p.ingest(frame(seq: 0, pulses: 0))
    p.ingest(frame(seq: 1, pulses: 720))  // 720 pulses * (0.5/3.6) m = 100 m
    #expect(abs(p.state.odometerKm - 1_102.1) < 1e-9)
}
