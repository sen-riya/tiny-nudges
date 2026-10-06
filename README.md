# Tiny Nudges

A tiny macOS menu-bar app that nags you, cheerfully, to look after yourself. A little animated character walks onto your screen to remind you to:

- **Drink water**: every hour.
- **Take an eye break**: every 3 hours, a one-minute guided break (glasses off, breathe in/out, stretch, look away).

The two reminders never show back-to-back (at least a 10-minute gap), and the app lives only in the menu bar (no Dock icon). The menu shows when the next reminders are due and lets you trigger either one immediately.

## Behaviour

| Reminder | Default interval | "Maybe later" / "Not yet" | Esc (dismiss) |
|----------|------------------|---------------------------|---------------|
| Water | 60 min | back in 15 min | back in 15 min |
| Eye break | 3 h | back in 10 min | back in 15 min |

Pressing **Esc** while the character is on screen dismisses it. It's registered as a system hot key, so no Accessibility permission is needed.

## Requirements

- macOS 13 or later
- Swift 5.9+ toolchain (Xcode or Command Line Tools)

## Build and run

```sh
swift build -c release
swift run TinyNudges
```

## Install (start at login)

```sh
./package.sh
```

This builds a release binary, creates `~/Applications/Tiny Nudges.app`, ad-hoc signs it, and registers a LaunchAgent so it starts at login. Edit `LABEL` at the top of `package.sh` to use your own bundle identifier.

To uninstall:

```sh
launchctl bootout "gui/$(id -u)/com.tinynudges.app"
rm -rf "$HOME/Applications/Tiny Nudges.app" "$HOME/Library/LaunchAgents/com.tinynudges.app.plist"
```

## Testing with short timings

Override any interval (in seconds) with environment variables:

```sh
TINY_NUDGES_INTERVAL_SECONDS=20 TINY_NUDGES_EYE_INTERVAL_SECONDS=45 swift run TinyNudges
```

| Variable | Meaning |
|----------|---------|
| `TINY_NUDGES_INTERVAL_SECONDS` | water interval |
| `TINY_NUDGES_SNOOZE_SECONDS` | water "Maybe later" delay |
| `TINY_NUDGES_EYE_INTERVAL_SECONDS` | eye-break interval |
| `TINY_NUDGES_EYE_SNOOZE_SECONDS` | eye-break "Not yet" delay |
| `TINY_NUDGES_EYE_DURATION_SECONDS` | eye-break length |
| `TINY_NUDGES_DISMISS_SECONDS` | delay after pressing Esc |
| `TINY_NUDGES_GAP_SECONDS` | minimum gap between the two reminders |

## Project layout

- `Sources/TinyNudges/`: app code (SwiftUI + AppKit)
  - `NudgeScheduler.swift`: decides when each reminder shows
  - `OverlayController.swift` / `OverlayView.swift` / `CharacterView.swift`: the on-screen character and its animations
  - `EscapeHotKey.swift`: global Esc shortcut
  - `Resources/`: sprite frames
- `Frames/`: source sprite sheets
- `package.sh`: build, install and enable start-at-login

## License

[MIT](LICENSE). The character artwork is AI-generated and free to reuse.
