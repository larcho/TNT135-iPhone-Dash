import Testing
@testable import DashCore

private let ratios = [220.0, 140.0, 105.0, 85.0]  // made-up rpm per km/h for 4 gears

@Test func matchesNearestGearWithinTolerance() {
    #expect(GearEstimator.match(rpm: 6_600, speedKmh: 30, ratios: ratios, tolerance: 0.08,
                                minimumSpeedKmh: 5, minimumRpm: 1_500) == .gear(1))
    #expect(GearEstimator.match(rpm: 5_100, speedKmh: 60, ratios: ratios, tolerance: 0.08,
                                minimumSpeedKmh: 5, minimumRpm: 1_500) == .gear(4))
}

@Test func unknownWhenBetweenGearsOrStopped() {
    // 175 rpm/kmh sits between 1st and 2nd -> clutch slipping / mid-shift
    #expect(GearEstimator.match(rpm: 5_250, speedKmh: 30, ratios: ratios, tolerance: 0.08,
                                minimumSpeedKmh: 5, minimumRpm: 1_500) == nil)
    #expect(GearEstimator.match(rpm: 1_400, speedKmh: 0, ratios: ratios, tolerance: 0.08,
                                minimumSpeedKmh: 5, minimumRpm: 1_500) == nil)
    #expect(GearEstimator.match(rpm: 6_600, speedKmh: 30, ratios: [], tolerance: 0.08,
                                minimumSpeedKmh: 5, minimumRpm: 1_500) == nil)
}

@Test func requiresStableFramesBeforeSwitching() {
    var g = GearEstimator()
    #expect(g.update(rpm: 6_600, speedKmh: 30, neutral: false, ratios: ratios) == nil)
    #expect(g.update(rpm: 6_600, speedKmh: 30, neutral: false, ratios: ratios) == nil)
    #expect(g.update(rpm: 6_600, speedKmh: 30, neutral: false, ratios: ratios) == .gear(1))
    // single noisy frame does not flip the display
    #expect(g.update(rpm: 4_200, speedKmh: 30, neutral: false, ratios: ratios) == .gear(1))
    #expect(g.update(rpm: 6_600, speedKmh: 30, neutral: false, ratios: ratios) == .gear(1))
}

@Test func neutralSwitchWinsImmediately() {
    var g = GearEstimator()
    #expect(g.update(rpm: 1_400, speedKmh: 0, neutral: true, ratios: ratios) == .neutral)
}
