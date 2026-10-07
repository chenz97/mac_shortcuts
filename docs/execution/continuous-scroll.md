# Long-Press Continuous Scroll Execution

Status: completed historical record. Direction statements below are superseded
by `scroll-direction-correction.md`; the physical-key acceptance check remains.

## Goal and Decisions

- A short F1/F3 press still emits exactly one fixed-distance scroll step.
- Holding F1/F3 emits an initial step immediately, then one identical step for
  every macOS key auto-repeat event until key-up.
- Direct F1/F3 and Karabiner-bridged F14/F13 follow the same behavior.
- Repeat timing uses the user's macOS keyboard delay and repeat-rate settings;
  the app does not add a second timer or an independent acceleration curve.
- Every repeated step uses the currently selected distance. Modifier and
  remote/virtual-client pass-through behavior remains unchanged.

## Verification Contract

### End-to-End Completion Criteria

- A short unmodified F1/F14 press scrolls down once and F3/F13 scrolls up once.
- Holding any supported key scrolls once immediately and continues in the same
  direction after the system key-repeat delay; releasing it stops further
  scrolling without adding a key-up scroll.
- The optional Karabiner bridge permits repeated F14/F13 output so media-key
  top rows behave like direct standard function keys.
- A release build produces a valid, signed `dist/FixedScroll.app` containing
  the new behavior.

### Functional Correctness

- Core tests prove both initial and auto-repeat key-down events produce the
  correct direction for all four supported key codes.
- Core tests prove key-up is suppressed without scrolling.
- JSON inspection proves both bridge mappings enable repeated output and keep
  their original directions and remote-client exclusions.
- Scroll event tests continue to prove each step uses the exact selected signed
  pixel delta.

### Performance Metrics

- Event handling stays synchronous and constant-time, with no allocation-heavy
  scheduler or I/O added to the event-tap callback.
- Each accepted repeat is posted immediately; the app adds no intentional
  latency beyond the user's system keyboard repeat settings.
- Idle behavior is unchanged because no app-owned repeating timer is added.

### UI/UX and Interaction Flow

- A quick tap keeps the existing one-step interaction.
- Long-press timing feels consistent with other held keys on the user's Mac.
- There is no hidden acceleration: each repeat has the selected fixed distance.
- No new menu setting is necessary because delay and cadence are controlled by
  the existing macOS keyboard preferences.

### Edge Cases and Failure Handling

- Key-up never posts an extra step and naturally terminates system repeat.
- Command, Control, Option, or Shift modified supported keys still pass through.
- Supported keys still pass through in known remote/virtual clients, including
  all repeat events delivered while those apps are frontmost.
- Changing the frontmost app or modifier state is evaluated per event rather
  than captured when the physical key was first pressed.
- Unrelated keys and generated scroll-wheel events remain untouched.

### Regression and Side Effects

- Short presses, distance persistence, permission handling, status menu test
  actions, tap re-enabling, and exact pixel deltas retain existing behavior.
- F2 and other unrelated function keys remain available to macOS and apps.
- The Karabiner bridge continues to preserve original keys in excluded remote
  and virtual clients.
- No app-owned timer can continue scrolling after key-up, quit, permission loss,
  or an event-tap disable.

### Planned Steps

1. Change the core policy to accept supported auto-repeat key-down events.
2. Enable repeat output for both Karabiner bridge mappings.
3. Update policy tests and user-facing/stable documentation.
4. Run the full Swift tests, formatter lint, JSON/schema assertions, release
   build, bundle validation, and code-signature verification.
5. Record actual results and any manual permission-dependent acceptance check.

## Progress

- Requirements and implementation approach recorded.
- Core policy now maps supported auto-repeat key-down events to the same scroll
  direction as the initial key-down.
- Both Karabiner bridge outputs now explicitly enable repeat.
- Core tests cover all four repeat mappings plus modifier and remote-client
  repeat pass-through.
- Stable requirements, overview, architecture, and user documentation now
  describe continuous scrolling and system-owned repeat timing.

## Verification Results

### Automated Checks

- The full test command completed successfully after running outside the host
  sandbox required by SwiftPM and directing module caches into the project:

  ```sh
  env CLANG_MODULE_CACHE_PATH=/Users/zeno/projects/mac_shortcuts/.build/module-cache \
    SWIFTPM_MODULECACHE_OVERRIDE=/Users/zeno/projects/mac_shortcuts/.build/module-cache \
    swift test --scratch-path /Users/zeno/projects/mac_shortcuts/.build
  ```

  ```text
  Executed 14 tests, with 0 failures (0 unexpected) in 0.020 seconds
  ```

- `xcrun swift-format lint --recursive Package.swift Sources Tests` exited 0
  with no output.
- `jq empty karabiner/f1_f3_fixed_scroll_bridge.json` exited 0. A structural
  assertion verified exactly F1 to F14 and F3 to F13, with `repeat: true` on
  both outputs and the remote-client condition retained:

  ```text
  f1  f14  true
  f3  f13  true
  ```

- `./scripts/build_app.sh` produced the release bundle and passed its plist and
  signature checks:

  ```text
  Build complete! (0.79s)
  /Users/zeno/projects/mac_shortcuts/dist/FixedScroll.app/Contents/Info.plist: OK
  Built /Users/zeno/projects/mac_shortcuts/dist/FixedScroll.app
  ```

- `codesign --verify --deep --strict --verbose=2 dist/FixedScroll.app` reported
  `valid on disk` and `satisfies its Designated Requirement`. Bundle inspection
  confirmed identifier `local.fixedscroll.app`, `LSUIElement = true`, an ad-hoc
  signature, and an arm64 executable linked only to Apple system libraries.
- The updated bridge source was copied to the user's Karabiner assets directory
  and byte-compared successfully. The active Karabiner profile was inspected
  afterward and deliberately left unchanged; it still contains the older F1/F3
  `mouse_key.vertical_wheel` mappings.
- The previous `/Applications/FixedScroll.app` was stopped and moved to
  `/private/tmp/FixedScroll-before-continuous-scroll.app`. The verified release
  bundle was copied into `/Applications`, passed strict signature verification,
  and relaunched as PID 97407. The installed and `dist/` executables had the
  same SHA-256 digest:

  ```text
  4eb799c3a46771d224ca7fc8bb3a68f9981c5be36b68a15a4e4575e02a6c7d04
  ```

### Manual Acceptance Check

Accessibility permission, a physical key hold, and the current foreground
scroll target are user-controlled. The installed app has been replaced and
relaunched. After switching Karabiner from the old wheel rule to the Fixed
Scroll bridge when needed, manually confirm:

1. A quick F1/F3 press still moves exactly one selected-distance step.
2. Holding F1 scrolls down and holding F3 scrolls up after the system repeat
   delay; releasing either key stops without an extra step.
3. The behavior works through F14/F13 when the bridge is enabled.
4. Modified keys and one available remote/virtual client still receive their
   original keys without local scrolling.

## Documentation Review

- `requirements.md`, `overview.md`, `architecture.md`, README, and the original
  execution record were reviewed and updated after implementation.
- `planning.md` and `design.md` remain unnecessary unless the implementation
  grows beyond the current event-policy change.
