# iOS tasks. The Xcode project is generated from project.yml (XcodeGen).

.PHONY: project open test build-sim

project:
	xcodegen generate

open: project
	open TNT135Dash.xcodeproj

# Fast: pure logic tests on macOS, no simulator needed.
test:
	cd Packages/DashCore && swift test

build-sim: project
	xcodebuild -project TNT135Dash.xcodeproj -scheme TNT135Dash \
		-destination 'generic/platform=iOS Simulator' -quiet build
