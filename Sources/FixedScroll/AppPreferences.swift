import FixedScrollCore
import Foundation

enum AppPreferences {
  private static let scrollDistanceKey = "scrollDistance"

  static var scrollDistance: Int32 {
    get {
      ScrollDistance.normalized(
        UserDefaults.standard.integer(forKey: scrollDistanceKey)
      )
    }
    set {
      let normalized = ScrollDistance.normalized(Int(newValue))
      UserDefaults.standard.set(Int(normalized), forKey: scrollDistanceKey)
    }
  }
}
