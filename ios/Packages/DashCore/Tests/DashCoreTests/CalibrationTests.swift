import Testing
@testable import DashCore

@Test func rpmFromTachFrequency() {
    var cal = Calibration.uncalibrated
    cal.tachPulsesPerRevolution = 1
    #expect(cal.rpm(fromTachHz: 23.3) == 1_398)
    cal.tachPulsesPerRevolution = 2
    #expect(cal.rpm(fromTachHz: 200) == 6_000)
}

@Test func fuelCurveInterpolatesAndClamps() {
    var cal = Calibration.uncalibrated
    cal.fuelCurve = [.init(millivolts: 2800, percent: 0), .init(millivolts: 300, percent: 100),
                     .init(millivolts: 1300, percent: 50)]
    #expect(cal.fuelPercent(fromMillivolts: 100) == 100)
    #expect(cal.fuelPercent(fromMillivolts: 800) == 75)
    #expect(cal.fuelPercent(fromMillivolts: 2050) == 25)
    #expect(cal.fuelPercent(fromMillivolts: 3200) == 0)
}

@Test func emptyFuelCurveIsUnknown() {
    var cal = Calibration.uncalibrated
    cal.fuelCurve = []
    #expect(cal.fuelPercent(fromMillivolts: 1000) == nil)
}
