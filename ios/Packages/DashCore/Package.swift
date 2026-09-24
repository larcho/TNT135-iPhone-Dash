// swift-tools-version: 6.2
import PackageDescription

// Pure, platform-independent dash logic: protocol decoding, calibration,
// gear inference, odometer. No CoreBluetooth / UIKit so `swift test` runs on macOS.
let package = Package(
    name: "DashCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "DashCore", targets: ["DashCore"])],
    targets: [
        .target(name: "DashCore"),
        .testTarget(name: "DashCoreTests", dependencies: ["DashCore"]),
    ]
)
