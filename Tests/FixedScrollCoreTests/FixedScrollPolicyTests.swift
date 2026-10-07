import FixedScrollPlatform
import XCTest

@testable import FixedScrollCore

final class FixedScrollPolicyTests: XCTestCase {
  func testUpKeysScrollUp() {
    for keyCode in [FixedScrollPolicy.f1KeyCode, FixedScrollPolicy.f14KeyCode] {
      XCTAssertEqual(decision(keyCode: keyCode), .scroll(.up))
    }
  }

  func testDownKeysScrollDown() {
    for keyCode in [FixedScrollPolicy.f3KeyCode, FixedScrollPolicy.f13KeyCode] {
      XCTAssertEqual(decision(keyCode: keyCode), .scroll(.down))
    }
  }

  func testKeyUpIsSuppressedWithoutScrolling() {
    XCTAssertEqual(
      decision(keyCode: FixedScrollPolicy.f1KeyCode, isKeyDown: false),
      .suppress
    )
  }

  func testAutoRepeatContinuesScrollingInTheMappedDirection() {
    let expectedDirections: [(UInt16, ScrollDirection)] = [
      (FixedScrollPolicy.f1KeyCode, .up),
      (FixedScrollPolicy.f3KeyCode, .down),
      (FixedScrollPolicy.f13KeyCode, .down),
      (FixedScrollPolicy.f14KeyCode, .up),
    ]

    for (keyCode, direction) in expectedDirections {
      XCTAssertEqual(
        decision(keyCode: keyCode, isRepeat: true),
        .scroll(direction)
      )
    }
  }

  func testModifiedHandledKeyPassesThrough() {
    XCTAssertEqual(
      decision(keyCode: FixedScrollPolicy.f1KeyCode, hasStandardModifiers: true),
      .passThrough
    )
  }

  func testUnrelatedKeyPassesThrough() {
    XCTAssertEqual(decision(keyCode: 120), .passThrough)
  }

  func testKnownRemoteAndVirtualClientsAreDetected() {
    let bundleIdentifiers = [
      "com.apple.ScreenSharing",
      "com.carriez.RustDesk",
      "com.philandro.anydesk",
      "com.citrix.receiver.icaviewer.mac",
      "com.microsoft.rdc.macos",
      "com.microsoft.rdc.macos.beta",
      "com.parallels.desktop.console",
      "com.teamviewer.TeamViewer",
      "com.utmapp.UTM",
      "com.vmware.fusion",
      "org.virtualbox.app.VirtualBox",
    ]

    for bundleIdentifier in bundleIdentifiers {
      XCTAssertTrue(
        RemoteClientPolicy.isRemoteOrVirtual(bundleIdentifier),
        "Expected remote/virtual match for \(bundleIdentifier)"
      )
    }
  }

  func testNormalAppIsNotTreatedAsRemote() {
    XCTAssertFalse(RemoteClientPolicy.isRemoteOrVirtual("com.apple.Safari"))
    XCTAssertFalse(RemoteClientPolicy.isRemoteOrVirtual(nil))
  }

  func testHandledKeysPassThroughInRemoteClient() {
    for keyCode in [
      FixedScrollPolicy.f1KeyCode,
      FixedScrollPolicy.f3KeyCode,
      FixedScrollPolicy.f13KeyCode,
      FixedScrollPolicy.f14KeyCode,
    ] {
      XCTAssertEqual(
        decision(
          keyCode: keyCode,
          frontmostBundleIdentifier: "com.parallels.desktop.console"
        ),
        .passThrough
      )
    }
  }

  func testAutoRepeatPassesThroughInRemoteClient() {
    XCTAssertEqual(
      decision(
        keyCode: FixedScrollPolicy.f14KeyCode,
        isRepeat: true,
        frontmostBundleIdentifier: "com.parallels.desktop.console"
      ),
      .passThrough
    )
  }

  func testModifiedAutoRepeatPassesThrough() {
    XCTAssertEqual(
      decision(
        keyCode: FixedScrollPolicy.f13KeyCode,
        isRepeat: true,
        hasStandardModifiers: true
      ),
      .passThrough
    )
  }

  func testSupportedAndInvalidDistances() {
    XCTAssertEqual(ScrollDistance.normalized(280), 280)
    XCTAssertEqual(ScrollDistance.normalized(420), 420)
    XCTAssertEqual(ScrollDistance.normalized(560), 560)
    XCTAssertEqual(ScrollDistance.normalized(0), ScrollDistance.defaultValue)
    XCTAssertEqual(ScrollDistance.normalized(999), ScrollDistance.defaultValue)
  }

  func testScrollEventUsesExactPositivePixelDeltaForUp() throws {
    let event = try XCTUnwrap(
      ScrollEventFactory.makeEvent(direction: .up, distance: 420)
    )

    XCTAssertEqual(event.type, .scrollWheel)
    XCTAssertEqual(
      event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
      420
    )
    XCTAssertEqual(
      event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2),
      0
    )
  }

  func testScrollEventUsesExactNegativePixelDeltaForDown() throws {
    let event = try XCTUnwrap(
      ScrollEventFactory.makeEvent(direction: .down, distance: 420)
    )

    XCTAssertEqual(event.type, .scrollWheel)
    XCTAssertEqual(
      event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
      -420
    )
  }

  private func decision(
    keyCode: UInt16,
    isKeyDown: Bool = true,
    isRepeat: Bool = false,
    hasStandardModifiers: Bool = false,
    frontmostBundleIdentifier: String? = "com.apple.Safari"
  ) -> KeyDecision {
    FixedScrollPolicy.decision(
      for: KeyInput(
        keyCode: keyCode,
        isKeyDown: isKeyDown,
        isRepeat: isRepeat,
        hasStandardModifiers: hasStandardModifiers
      ),
      frontmostBundleIdentifier: frontmostBundleIdentifier
    )
  }
}
