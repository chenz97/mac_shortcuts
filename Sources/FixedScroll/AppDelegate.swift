import AppKit
import FixedScrollCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let eventTapController = EventTapController()
  private var statusItem: NSStatusItem!
  private var statusMenuItem: NSMenuItem!
  private var openSettingsMenuItem: NSMenuItem!
  private var testUpMenuItem: NSMenuItem!
  private var testDownMenuItem: NSMenuItem!
  private var permissionTimer: Timer?
  private var distanceMenuItems: [Int32: NSMenuItem] = [:]

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    configureStatusMenu()

    _ = eventTapController.isAccessibilityTrusted(prompt: true)
    refreshPermissionState()

    if !eventTapController.isActive {
      permissionTimer = Timer.scheduledTimer(
        timeInterval: 2,
        target: self,
        selector: #selector(refreshPermissionState),
        userInfo: nil,
        repeats: true
      )
    }
  }

  private func configureStatusMenu() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = statusItem.button {
      button.image = NSImage(
        systemSymbolName: "arrow.up.and.down",
        accessibilityDescription: "Fixed Scroll"
      )
      button.toolTip = "Fixed Scroll"
    }

    let menu = NSMenu()

    statusMenuItem = NSMenuItem(title: "Status: Starting", action: nil, keyEquivalent: "")
    statusMenuItem.isEnabled = false
    menu.addItem(statusMenuItem)

    openSettingsMenuItem = NSMenuItem(
      title: "Open Accessibility Settings...",
      action: #selector(openAccessibilitySettings),
      keyEquivalent: ""
    )
    openSettingsMenuItem.target = self
    menu.addItem(openSettingsMenuItem)
    menu.addItem(.separator())

    let distanceTitle = NSMenuItem(title: "Scroll Distance", action: nil, keyEquivalent: "")
    distanceTitle.isEnabled = false
    menu.addItem(distanceTitle)

    for distance in ScrollDistance.supportedValues {
      let item = NSMenuItem(
        title: "\(distance) px",
        action: #selector(selectDistance(_:)),
        keyEquivalent: ""
      )
      item.target = self
      item.representedObject = Int(distance)
      distanceMenuItems[distance] = item
      menu.addItem(item)
    }

    menu.addItem(.separator())
    testUpMenuItem = NSMenuItem(
      title: "Test Scroll Up",
      action: #selector(testScrollUp),
      keyEquivalent: ""
    )
    testUpMenuItem.target = self
    menu.addItem(testUpMenuItem)

    testDownMenuItem = NSMenuItem(
      title: "Test Scroll Down",
      action: #selector(testScrollDown),
      keyEquivalent: ""
    )
    testDownMenuItem.target = self
    menu.addItem(testDownMenuItem)

    menu.addItem(.separator())
    let quitItem = NSMenuItem(
      title: "Quit Fixed Scroll",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    menu.addItem(quitItem)

    statusItem.menu = menu
    updateDistanceChecks()
  }

  @objc private func refreshPermissionState() {
    let trusted = eventTapController.isAccessibilityTrusted(prompt: false)
    let active = trusted && eventTapController.installIfPossible()

    statusMenuItem.title =
      active
      ? "Status: Active"
      : "Status: Accessibility Permission Required"
    openSettingsMenuItem.isHidden = active
    testUpMenuItem.isEnabled = active
    testDownMenuItem.isEnabled = active

    if active {
      permissionTimer?.invalidate()
      permissionTimer = nil
    }
  }

  @objc private func selectDistance(_ sender: NSMenuItem) {
    guard let rawValue = sender.representedObject as? Int else { return }
    AppPreferences.scrollDistance = Int32(clamping: rawValue)
    updateDistanceChecks()
  }

  private func updateDistanceChecks() {
    let selectedDistance = AppPreferences.scrollDistance
    for (distance, item) in distanceMenuItems {
      item.state = distance == selectedDistance ? .on : .off
    }
  }

  @objc private func testScrollUp() {
    eventTapController.postScroll(.up, distance: AppPreferences.scrollDistance)
  }

  @objc private func testScrollDown() {
    eventTapController.postScroll(.down, distance: AppPreferences.scrollDistance)
  }

  @objc private func openAccessibilitySettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    else { return }
    NSWorkspace.shared.open(url)
  }
}
