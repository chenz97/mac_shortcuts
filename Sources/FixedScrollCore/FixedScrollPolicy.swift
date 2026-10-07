import Foundation

public enum ScrollDirection: Equatable, Sendable {
  case up
  case down
}

public enum KeyDecision: Equatable, Sendable {
  case passThrough
  case suppress
  case scroll(ScrollDirection)
}

public struct KeyInput: Equatable, Sendable {
  public let keyCode: UInt16
  public let isKeyDown: Bool
  public let isRepeat: Bool
  public let hasStandardModifiers: Bool

  public init(
    keyCode: UInt16,
    isKeyDown: Bool,
    isRepeat: Bool = false,
    hasStandardModifiers: Bool = false
  ) {
    self.keyCode = keyCode
    self.isKeyDown = isKeyDown
    self.isRepeat = isRepeat
    self.hasStandardModifiers = hasStandardModifiers
  }
}

public enum FixedScrollPolicy {
  public static let f1KeyCode: UInt16 = 122
  public static let f3KeyCode: UInt16 = 99
  public static let f13KeyCode: UInt16 = 105
  public static let f14KeyCode: UInt16 = 107

  public static func decision(
    for input: KeyInput,
    frontmostBundleIdentifier: String?
  ) -> KeyDecision {
    if RemoteClientPolicy.isRemoteOrVirtual(frontmostBundleIdentifier) {
      return .passThrough
    }

    guard let direction = direction(for: input.keyCode) else {
      return .passThrough
    }

    if input.hasStandardModifiers {
      return .passThrough
    }

    guard input.isKeyDown else {
      return .suppress
    }

    return .scroll(direction)
  }

  private static func direction(for keyCode: UInt16) -> ScrollDirection? {
    switch keyCode {
    case f1KeyCode, f14KeyCode:
      return .up
    case f3KeyCode, f13KeyCode:
      return .down
    default:
      return nil
    }
  }
}

public enum ScrollDistance {
  public static let defaultValue: Int32 = 420
  public static let supportedValues: [Int32] = [280, 420, 560]

  public static func normalized(_ value: Int) -> Int32 {
    let candidate = Int32(clamping: value)
    return supportedValues.contains(candidate) ? candidate : defaultValue
  }
}

public enum RemoteClientPolicy {
  private static let exactBundleIdentifiers: Set<String> = [
    "com.apple.ScreenSharing",
    "com.carriez.RustDesk",
    "com.philandro.anydesk",
  ]

  private static let bundleIdentifierPrefixes = [
    "com.citrix.",
    "com.microsoft.rdc.macos",
    "com.parallels.",
    "com.teamviewer.",
    "com.utmapp.",
    "com.vmware.",
    "org.virtualbox.app.",
  ]

  public static func isRemoteOrVirtual(_ bundleIdentifier: String?) -> Bool {
    guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
      return false
    }

    if exactBundleIdentifiers.contains(bundleIdentifier) {
      return true
    }

    return bundleIdentifierPrefixes.contains {
      bundleIdentifier.hasPrefix($0)
    }
  }
}
