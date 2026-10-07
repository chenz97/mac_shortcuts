# F1/F3 Scroll Direction Correction

Status: implemented and automatically verified; physical-key acceptance remains
pending because the newly ad-hoc-signed binary requires renewed macOS
Accessibility approval.

## Goal

Make the application's intrinsic and documented behavior match the intended
workflow: F1 scrolls up and F3 scrolls down. The Karabiner bridge must preserve
those physical-key directions through F14 and F13 without relying on a second
scroll-reversal utility to cancel an incorrect mapping.

## Verification Contract

### End-to-End Completion Criteria

- A short unmodified F1 press, or bridged F14 press, produces one upward fixed
  pixel step.
- A short unmodified F3 press, or bridged F13 press, produces one downward fixed
  pixel step.
- Holding a supported key repeats only that key's mapped direction at the macOS
  keyboard repeat cadence until release.
- LinearMouse is documented to bypass events from other applications so it does
  not reverse Fixed Scroll output a second time.

### Functional Correctness

- Policy tests cover all four initial key mappings and all four auto-repeat
  mappings.
- The event factory continues to encode up as a positive Axis1 point delta and
  down as a negative Axis1 point delta.
- The bridge remains F1 to F14 and F3 to F13 with repeat enabled.

### Performance Metrics

- The key callback remains constant-time and adds no I/O, timer, or allocation
  loop to the input path.
- The correction must not add observable latency beyond the existing direct
  event-posting path.

### UI/UX and Interaction Flow

- README and stable requirements state the same physical-key directions as the
  implementation.
- Menu test-up and test-down actions retain their literal directions.
- Users are told how to prevent a running scroll-transform utility from causing
  an apparent intermittent reversal.

### Edge Cases and Failure Handling

- Key-up remains suppressed without posting an additional scroll step.
- Command, Control, Option, or Shift modified supported keys pass through.
- Supported keys pass through unchanged in known remote and virtual clients.
- Unrelated keys and invalid saved distances retain their existing behavior.

### Regression and Side Effects

- Run the complete Swift test suite, formatter lint, JSON validation, bridge
  structure assertion, release build, plist validation, and code-signature
  verification.
- Confirm no old direction claims remain in stable documentation. Historical
  execution records may retain old results only when marked superseded.

## Planned Steps

1. Reverse the core key-to-direction policy and corresponding tests.
2. Update stable documentation and mark historical direction records superseded.
3. Run automated verification and build the release application.
4. Replace and relaunch the installed application, then compare it byte-for-byte
   with the verified release bundle.
5. Record results and remaining physical-key acceptance checks here.

## Progress

- Verification contract recorded.
- Core mapping, tests, stable documentation, and historical annotations updated.
- Release bundle built, verified, installed, and relaunched.

## Verification Results

### Automated Checks

- The complete Swift test suite passed:

  ```text
  Executed 14 tests, with 0 failures (0 unexpected) in 0.018 seconds
  ```

  This includes all initial and repeat direction mappings, exact positive and
  negative Axis1 point deltas, key-up suppression, modifier pass-through,
  remote/virtual-client pass-through, unrelated keys, and distance handling.
- `xcrun swift-format lint --recursive Package.swift Sources Tests` exited 0
  with no output.
- `jq empty karabiner/f1_f3_fixed_scroll_bridge.json` exited 0. A structural
  assertion returned `true` for exactly F1 to F14 and F3 to F13 with repeat
  enabled on both outputs.
- `./scripts/build_app.sh` completed a production build, replaced the ad-hoc
  signature, and validated the bundle plist:

  ```text
  Build complete! (0.70s)
  /Users/zeno/projects/mac_shortcuts/dist/FixedScroll.app/Contents/Info.plist: OK
  Built /Users/zeno/projects/mac_shortcuts/dist/FixedScroll.app
  ```

- Strict signature verification reported `valid on disk` and `satisfies its
  Designated Requirement`. The installed and `dist` executables have the same
  SHA-256 digest:

  ```text
  cb1f9c9e763780efbd8e0c91fa580fef1ec5efbe6bb0077ee1454a27e81c3c6a
  ```

- The previous installed bundle was preserved at
  `/private/tmp/FixedScroll-before-direction-correction.app`. The new installed
  application is resident as `application.local.fixedscroll.app`.

### Manual Acceptance Check

The new ad-hoc signature changed the designated-requirement CDHash, so macOS did
not carry the old Accessibility approval to the replacement binary. After
re-enabling FixedScroll under System Settings > Privacy & Security >
Accessibility, confirm in a normal scroll view:

1. A quick or held F1 scrolls up, and a quick or held F3 scrolls down.
2. LinearMouse's `Bypass events from other applications` setting is enabled and
   the directions remain stable after changing pointing devices or waking the
   Mac.
3. Modified keys and a supported remote/virtual client still receive their
   original function keys.

## Documentation Review

- `requirements.md`, `architecture.md`, README, and both prior execution records
  required direction-related updates.
- `overview.md` does not state a direction and needs no change.
- `planning.md` and `design.md` remain unnecessary for this bounded correction.
