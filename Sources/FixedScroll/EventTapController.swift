import AppKit
import ApplicationServices
import CoreGraphics
import FixedScrollCore
import FixedScrollPlatform

final class EventTapController {
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?

  var isActive: Bool {
    guard let eventTap else { return false }
    return CGEvent.tapIsEnabled(tap: eventTap)
  }

  func isAccessibilityTrusted(prompt: Bool) -> Bool {
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
  }

  @discardableResult
  func installIfPossible() -> Bool {
    if isActive {
      return true
    }

    guard isAccessibilityTrusted(prompt: false) else {
      return false
    }

    removeTap()

    let eventMask =
      CGEventMask(1) << CGEventType.keyDown.rawValue
      | CGEventMask(1) << CGEventType.keyUp.rawValue

    let callback: CGEventTapCallBack = { _, eventType, event, userInfo in
      guard let userInfo else {
        return Unmanaged.passUnretained(event)
      }

      let controller = Unmanaged<EventTapController>
        .fromOpaque(userInfo)
        .takeUnretainedValue()
      return controller.handle(eventType: eventType, event: event)
    }

    guard
      let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: Unmanaged.passUnretained(self).toOpaque()
      )
    else {
      NSLog("FixedScroll: failed to create keyboard event tap")
      return false
    }

    guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
      CFMachPortInvalidate(tap)
      NSLog("FixedScroll: failed to create event-tap run-loop source")
      return false
    }

    eventTap = tap
    runLoopSource = source
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    return isActive
  }

  func postScroll(_ direction: ScrollDirection, distance: Int32) {
    let event = ScrollEventFactory.makeEvent(
      direction: direction,
      distance: distance
    )
    event?.post(tap: .cghidEventTap)
  }

  private func handle(
    eventType: CGEventType,
    event: CGEvent
  ) -> Unmanaged<CGEvent>? {
    if eventType == .tapDisabledByTimeout || eventType == .tapDisabledByUserInput {
      if let eventTap {
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }

    guard eventType == .keyDown || eventType == .keyUp else {
      return Unmanaged.passUnretained(event)
    }

    let blockedModifiers: CGEventFlags = [
      .maskCommand,
      .maskControl,
      .maskAlternate,
      .maskShift,
    ]
    let input = KeyInput(
      keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
      isKeyDown: eventType == .keyDown,
      isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
      hasStandardModifiers: !event.flags.intersection(blockedModifiers).isEmpty
    )
    let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

    switch FixedScrollPolicy.decision(
      for: input,
      frontmostBundleIdentifier: bundleIdentifier
    ) {
    case .passThrough:
      return Unmanaged.passUnretained(event)
    case .suppress:
      return nil
    case .scroll(let direction):
      postScroll(direction, distance: AppPreferences.scrollDistance)
      return nil
    }
  }

  private func removeTap() {
    if let runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }
    if let eventTap {
      CFMachPortInvalidate(eventTap)
    }
    runLoopSource = nil
    eventTap = nil
  }

  deinit {
    removeTap()
  }
}
