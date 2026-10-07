# Fixed Scroll

Fixed Scroll is a small native macOS menu bar utility. One unmodified F1 press
posts a fixed upward pixel scroll; F3 posts the same distance downward. The
default distance is 420 px, with 280 px and 560 px options in the menu. Holding
either key continues scrolling at the macOS keyboard repeat cadence until the
key is released.

Virtual-machine and remote-desktop clients are excluded. When one of the
supported clients is frontmost, function keys pass through unchanged.

## Build

```sh
./scripts/build_app.sh
open dist/FixedScroll.app
```

Before first launch, either keep the app at `dist/FixedScroll.app` or move it to
the stable location where you intend to use it. Then open it and grant Fixed
Scroll access in System Settings > Privacy & Security > Accessibility. The menu
status changes to `Status: Active` when the event tap is ready.

To keep it available after reboot, add that stable app path in System Settings
> General > Login Items.

## Karabiner Bridge

Direct F1/F3 handling works when macOS treats the top row as standard function
keys. For consistent behavior when the top row is configured as media keys:

1. In Karabiner-Elements, disable the old rule that maps F1/F3 to
   `mouse_key.vertical_wheel`.
2. Enable `F1/F3 bridge for Fixed Scroll` from Complex Modifications.
3. Keep Fixed Scroll running. The bridge sends F14 for F1 and F13 for F3, and
   preserves original F1/F3 inside supported virtual-machine and remote-desktop
   clients.

If LinearMouse is running, enable its `Bypass events from other applications`
setting so it does not reverse Fixed Scroll's generated wheel events.

The source rule is `karabiner/f1_f3_fixed_scroll_bridge.json`; the installed
copy is under Karabiner's `assets/complex_modifications` directory.

## Alt+Tab Shortcut

Copy `karabiner/alt_tab_to_control_down.json` to
`~/.config/karabiner/assets/complex_modifications/`, then enable
`Alt+Tab to Control+Down` in Karabiner-Elements > Complex Modifications.
Option+Tab sends Control+Down Arrow, except in supported remote-desktop clients
such as Windows App, where it passes through. The rule applies to either Option
key and leaves shortcuts with additional modifiers unchanged.

## Option+Grave Shortcut

Copy `karabiner/option_grave_to_control_down.json` to
`~/.config/karabiner/assets/complex_modifications/`, then enable
`Option+Grave to Control+Down` in Karabiner-Elements > Complex Modifications.
Hold either Option key and press the backtick key (`` ` ``) to send
Control+Down Arrow once per press. The backtick key is usually below Escape
and to the left of 1. Shortcuts with additional Command, Control, or Shift
modifiers keep their usual behavior.

## Behavior Notes

- The event is sent to the scrollable UI under the mouse pointer.
- Holding F1 or F3 scrolls repeatedly after the macOS key-repeat delay. Every
  repeated step uses the selected fixed distance without added acceleration.
- Command/Control/Option/Shift modified function keys pass through.
- The emitted pixel delta is fixed. Apps with custom pagination or scroll
  engines may still reinterpret the event.
- Web-based remote desktops running inside a general browser cannot be detected
  from the browser bundle identifier. Add a Karabiner application condition or
  temporarily disable the bridge for that case.

## Verify

```sh
swift test --scratch-path .build
jq empty karabiner/f1_f3_fixed_scroll_bridge.json
jq empty karabiner/alt_tab_to_control_down.json
jq empty karabiner/option_grave_to_control_down.json
./scripts/build_app.sh
```
