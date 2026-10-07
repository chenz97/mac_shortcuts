# Fixed Scroll Architecture

## Modules

- `Sources/FixedScrollCore`: pure key-decision and distance-selection logic.
  This module has no AppKit dependency and is covered by unit tests.
- `Sources/FixedScrollPlatform`: Core Graphics pixel scroll-event construction,
  separated so the exact signed event delta can be tested without permission.
- `Sources/FixedScroll`: AppKit lifecycle, status-menu construction,
  Accessibility permission checks, Core Graphics event-tap management, and
  scroll-event posting.
- `Tests/FixedScrollCoreTests`: mapping, modifier, repeat, and configuration
  tests.
- `Resources/Info.plist`: application bundle metadata for a menu bar accessory.
- `scripts/build_app.sh`: release build, bundle assembly, and ad-hoc signing.
- `complex_modifications/f1_f3_fixed_scroll_bridge.json`: optional F1 to F14
  and F3 to F13 bridge for Karabiner-Elements.

## Event Flow

1. A session-level active `CGEventTap` receives key-down and key-up events.
2. The frontmost bundle identifier is classified as local or remote/virtual,
   then `FixedScrollCore` classifies the key and returns pass-through,
   suppress, or scroll-up/scroll-down.
   F1/F14 map to up, while F3/F13 map to down.
3. The app suppresses recognized function-key events and posts a new
   pixel-unit scroll-wheel event for every key-down, including macOS
   auto-repeat events generated while a supported key remains held.
4. macOS routes that scroll event to the scrollable UI under the pointer.

Repeat cadence comes from the system keyboard settings. The app deliberately
does not maintain held-key state or its own repeating timer, so key-up, process
termination, and event-tap interruption cannot leave an internal scroll loop
running. The Karabiner bridge explicitly enables repeat on its F14/F13 output
to preserve this behavior when the top row is configured as media keys.

The event tap is never subscribed to scroll-wheel events, so the app cannot
recursively consume the events it creates.

Third-party scroll transformers can still intercept the generated event after
Fixed Scroll posts it. They must be configured to bypass events from other
applications; otherwise a direction-reversal feature can invert Fixed Scroll's
already semantic up/down output.

Remote/virtual application matching is maintained as explicit exact bundle IDs
and vendor prefixes in the core module. The Karabiner bridge mirrors that list
as a `frontmost_application_unless` regular expression, ensuring the original
F1/F3 event survives before it reaches the remote client.

## Permission Model

Global keyboard event taps require Accessibility trust. The app requests it,
keeps an inactive status while trust is missing, and periodically retries tap
installation after the user grants permission. No administrator or Input
Monitoring privilege is required by design.
