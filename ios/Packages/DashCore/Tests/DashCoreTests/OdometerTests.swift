import Testing
@testable import DashCore

@Test func firstFrameIsBaselineThenAccumulates() {
    var odo = Odometer()
    odo.ingest(pulses: 5_000, metresPerPulse: 0.1)
    #expect(odo.totalMetres == 0)
    odo.ingest(pulses: 5_010, metresPerPulse: 0.1)
    #expect(abs(odo.totalMetres - 1.0) < 1e-9)
}

@Test func bridgeRebootCountsFromZero() {
    var odo = Odometer()
    odo.ingest(pulses: 5_000, metresPerPulse: 1)
    odo.ingest(pulses: 3, metresPerPulse: 1)
    #expect(odo.totalMetres == 3)
}

@Test func implausibleJumpIsDropped() {
    var odo = Odometer()
    odo.ingest(pulses: 0, metresPerPulse: 1)
    odo.ingest(pulses: 50_000, metresPerPulse: 1)
    #expect(odo.totalMetres == 0)
}

@Test func reconnectStartsNewBaseline() {
    var odo = Odometer()
    odo.ingest(pulses: 0, metresPerPulse: 1)
    odo.resetBaseline()
    odo.ingest(pulses: 900, metresPerPulse: 1)
    #expect(odo.totalMetres == 0)
}
