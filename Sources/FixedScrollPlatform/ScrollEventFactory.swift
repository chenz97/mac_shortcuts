import CoreGraphics
import FixedScrollCore

public enum ScrollEventFactory {
  public static func makeEvent(
    direction: ScrollDirection,
    distance: Int32
  ) -> CGEvent? {
    let signedDistance = direction == .up ? distance : -distance
    let source = CGEventSource(stateID: .hidSystemState)
    return CGEvent(
      scrollWheelEvent2Source: source,
      units: .pixel,
      wheelCount: 1,
      wheel1: signedDistance,
      wheel2: 0,
      wheel3: 0
    )
  }
}
