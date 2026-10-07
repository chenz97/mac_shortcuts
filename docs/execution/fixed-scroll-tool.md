# Fixed Scroll Tool Execution

Status: completed historical baseline; long-press behavior is tracked in
`continuous-scroll.md`. Direction statements below describe that historical
build and are superseded by `scroll-direction-correction.md`; the manual
permission-dependent acceptance check remains recorded.

## Scope and Decisions

- Implement a dependency-free native macOS menu bar application.
- Originally emitted a single fixed pixel scroll event per physical press.
  This behavior was superseded by the long-press continuous-scroll enhancement.
- Default to 420 px with 280 px and 560 px alternatives.
- Handle direct F1/F3 and bridge F13/F14 keys.
- Pass all handled keys through unchanged while a known virtual-machine or
  remote-desktop client is frontmost, in both the app and Karabiner bridge.
- Do not attempt raw IOHID device seizure; the optional Karabiner bridge covers
  top rows configured as media keys.
- Do not alter the user's active Karabiner profile automatically.

## Historical Verification Contract (Superseded for Long Press)

### End-to-End Completion Criteria

- A release command produces a launchable, ad-hoc signed
  `dist/FixedScroll.app` with the expected identifier and accessory policy.
- With Accessibility permission granted, the status menu reports active;
  unmodified F3/F13 scrolls up while F1/F14 scrolls down.
- Each physical press emits exactly one scroll command with the selected fixed
  delta, and key-up does not emit another scroll.
- The chosen distance persists after app relaunch.
- The Karabiner bridge imports as valid JSON and maps only F1 to F14 and F3 to
  F13.

### Functional Correctness

- Unit tests cover all four recognized keys, both directions, key-up
  suppression, auto-repeat suppression, standard modifier pass-through, and
  invalid stored-distance fallback.
- Unit tests cover exact and prefix-based remote-client bundle matching and
  prove that recognized keys pass through in those clients.
- Runtime inspection confirms that the app installs an active event tap when
  trusted and remains responsive after a tap-disabled callback.
- Menu test actions use the same scroll-posting function as keyboard input.

### Performance Metrics

- Release build succeeds without third-party dependency resolution.
- Decision logic is synchronous and constant-time.
- User-visible scroll posting occurs in the event-tap callback without disk or
  network I/O; observed input-to-scroll latency should be below 50 ms.
- Idle CPU should remain negligible; permission polling stops once the event
  tap is active.

### UI/UX and Interaction Flow

- The app has a single recognizable menu bar icon and no Dock icon.
- The menu always exposes current status and selected distance.
- Missing permission is understandable from the menu, with a direct link to
  the correct System Settings pane.
- Distance items behave as a mutually exclusive selection.
- Test and Quit commands are discoverable and do not require keyboard input.

### Edge Cases and Failure Handling

- Modified function keys pass through and are not scrolled or suppressed.
- Virtual-machine and remote-desktop sessions receive the original function
  keys rather than scroll actions or F13/F14 bridge events.
- At the time of this baseline, holding a recognized key could not generate
  repeated scroll actions. See `continuous-scroll.md` for the newer contract.
- Missing permission does not crash or create a busy retry loop.
- Event-tap timeout/user-disable callbacks re-enable the tap.
- A malformed persisted distance falls back to 420 px.
- Apps that quantize pixel scrolling are documented as a platform boundary.

### Regression and Side Effects

- F2 and all function keys other than F1/F3/F13/F14 remain untouched.
- Modified shortcuts remain available to other applications.
- Virtual-machine and remote-desktop function-key behavior remains unchanged.
- Generated scroll events are not intercepted recursively.
- The build does not modify `/Applications`, login items, the active Karabiner
  profile, or privacy settings.
- Quitting removes the event tap through process termination and restores
  normal function-key behavior.

### Planned Steps

1. Create the Swift package, pure decision module, and unit tests.
2. Implement the menu app, permission lifecycle, event tap, and scroll posting.
3. Add the app-bundle resource, build script, bridge rule, and user guide.
4. Run tests, build/sign validation, static configuration checks, and launch UI
   inspection.
5. Record real verification results and remaining manual permission-dependent
   checks in this document.

## Progress

- Requirements, consistency boundary, architecture, and verification contract
  recorded.
- Core policy, remote-client exclusions, menu application, permission lifecycle,
  event tap, fixed pixel-event factory, tests, packaging, and Karabiner bridge
  implemented.
- Karabiner bridge installed into the assets directory without enabling or
  changing the active profile.
- Physical-key directions updated to F1 down and F3 up; the app policy,
  Karabiner bridge, tests, and user documentation were updated together.

## Verification Results

### Automated Checks

- `swift test` completed successfully after directing SwiftPM's module cache to
  the project and running outside the host sandbox required by SwiftPM:

  ```text
  Executed 12 tests, with 0 failures (0 unexpected) in 0.027 seconds
  ```

- The Core Graphics tests read the generated event fields and confirmed an
  exact `+420` pixel Axis1 delta for up and `-420` for down.
- `xcrun swift-format lint --recursive Package.swift Sources Tests` exited 0
  with no output after mechanical formatting.
- `./scripts/build_app.sh` completed a release build, ad-hoc signature,
  `plutil` validation, and strict `codesign` verification:

  ```text
  Build complete! (0.65s)
  dist/FixedScroll.app/Contents/Info.plist: OK
  Built dist/FixedScroll.app
  ```

- `jq empty karabiner/f1_f3_fixed_scroll_bridge.json` passed. The installed
  assets copy was byte-compared with the project source and matched.
- Bundle inspection confirmed identifier `local.fixedscroll.app`,
  `LSUIElement = true`, macOS 13 minimum, an arm64 Mach-O executable for the
  current machine, and only Apple system frameworks/libraries.
- A launch smoke test confirmed a resident `FixedScroll` process, creation of
  the status-item scene, and a macOS TCC Accessibility request. No crash or app
  error was logged. The test process was then stopped before the final build.

### Manual Acceptance Check

macOS Accessibility permission is intentionally user-controlled and was not
changed during verification. After granting it to the final bundle, manually
confirm:

1. The menu reports `Status: Active` and 420 px is selected.
2. F1 moves a normal scroll view down and F3 moves it up by equal fixed
   increments.
3. After enabling the bridge and disabling the old `vertical_wheel` rule,
   F1/F3 still reach one available virtual-machine or remote-desktop session as
   original function keys.
4. Changing the menu distance changes the next movement and persists across a
   relaunch.

Computer Use could not inspect the third-party menu extra because macOS does
not expose this `LSUIElement` status item through its app enumeration; the
status scene and permission flow were instead confirmed from the process and
system log.

## Documentation Review

- `overview.md`, `requirements.md`, and `architecture.md` reflect the completed
  behavior and remote-session exclusions.
- A project `planning.md` is not needed for this single completed utility.
- A separate `design.md` is not needed because the small stable event flow and
  module boundaries are fully captured in `architecture.md`.
