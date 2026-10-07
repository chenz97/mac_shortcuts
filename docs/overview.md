# Fixed Scroll Overview

Fixed Scroll solves one narrow macOS input problem: Karabiner-Elements can map
a key to a mouse wheel speed, but that path is accelerated and affected by
system mouse settings. Fixed Scroll instead injects a pixel-unit Core Graphics
scroll event with a constant delta for each accepted key-down. Quick presses
produce one step; held keys follow the user's macOS key-repeat timing and emit
the same fixed step continuously until release.

The product is a lightweight menu bar utility with no network dependency. It
supports direct standard function keys and an optional Karabiner bridge for
media-key top rows. Its guarantee applies to the emitted input delta; an
application with a custom scroll engine may still reinterpret that event.

The first release intentionally omits per-app rules, animation, and automatic
login-item registration. Its priority is a small auditable implementation,
predictable behavior, and a clear permission state.
