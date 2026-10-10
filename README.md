<p align="center"><img src="logo.png" alt="Tiny Nudges logo" width="160"></p>

# Tiny Nudges

A tiny macOS menu-bar app that nags you, cheerfully, to look after yourself. A little animated character walks onto your screen, chats to you in a speech bubble, and reminds you to:

- **Drink water**: every hour.
- **Take an eye break**: every 3 hours, a one-minute guided routine (glasses off, breathe in and out, stretch, look away).

You choose who nags you from a list of characters, and you can pick a different one for water and for eye breaks. Each character has their own name, sprites, colours and messages. The app lives only in the menu bar (no Dock icon), and the two reminders never show back-to-back (at least a 10-minute gap).

## Contents

- [How it works](#how-it-works)
- [The menu-bar popover](#the-menu-bar-popover)
- [Settings](#settings)
- [Characters](#characters)
- [Install](#install)
- [Customising](#customising)
- [Testing with short timings](#testing-with-short-timings)
- [Project layout](#project-layout)
- [License](#license)

## How it works

### Water reminder

1. The character **walks in** from the right edge of the screen.
2. They greet you in a speech bubble, then ask you to drink some water with two buttons (yes / later). The greeting is picked at random from a handful, so it doesn't get stale.
3. They **react** to your answer:
   - **Yes**: a happy, cheering reaction, then they walk out.
   - **Later**: a disappointed reaction (for example a side-eye, depending on the character), then they walk out. They come back after the snooze delay.
4. If the character has a goodbye line, it rides along with them as they **walk back out**.

### Eye break

1. The character walks in and **asks** if you want a break (one of a few pitches, picked at random), with a yes button and a not-now button.
2. **Not now** and they leave, then come back after the snooze delay.
3. **Yes** starts a guided routine. A step bubble pops up for each moment, and a segmented bar fills as you go:

   | Steps | What happens |
   |-------|--------------|
   | 1 | Screens off, eyes up |
   | 2 | Glasses off |
   | 3 | Breathe in, breathe out (a circle swells and shrinks with the breath) |
   | 4 | Stretch |
   | 5 | Look over there, then the other way |
   | 6 | Breathe in again, breathe out |
   | 7 | Big yawn |
   | 8 | Look far away |

   These 8 steps share the **break length** (60 seconds by default) equally, on a real clock, so the routine always lasts as long as you set. Only after the whole routine is done does the **finale** bubble ("fresh eyes") appear for a few seconds, and then the character walks out.

### Esc

Press **Esc** at any time while the character is on screen and they vanish immediately. The reminder comes back after the Esc delay. Esc is registered as a system hot key, so no Accessibility permission is needed.

### Defaults

| Reminder | Default interval | "Later" / "Not now" | Esc |
|----------|------------------|---------------------|-----|
| Water | 60 min | back in 15 min | back in 15 min |
| Eye break | 3 h | back in 10 min | back in 15 min |

The eye break lasts 60 seconds by default, and there is at least a 10-minute gap between any two reminders. Every one of these can be changed in [Settings](#settings).

## The menu-bar popover

Click the water-drop icon in the menu bar. The popover is deliberately simple:

- **The logo and name.**
- **A Water line and an Eye break line.** Each shows when the reminder is next due (for example "7:23 PM · in 3 h", counting down by itself) and a **Now** button to run it immediately. The popover closes when you press it, so the character isn't hidden behind it.
- **Open app** (⌘,) and **Quit**.

Only one copy of the app runs at a time: a second copy quits straight away, so you never get two menu-bar icons.

## The app window

**Open app** shows the full window, with two tabs:

- **Reminders**: a Water card and an Eye break card, each with the next due time, a **Now** button and a **"Nagged by"** picker. Tap the picker to open a list of every character (picture and name). Water and eye breaks can use different characters, and a change shows up the next time that reminder appears.
- **Stats**: tap a card's name to open its stats: the total number of glasses (or eye breaks) taken with Tiny Nudges, today's count, how many times you answered yes, maybe later and Esc, the yes percentage, and a 7-day daily tracker. The eye break page also shows the total time spent resting your eyes. Every answer is saved on your Mac (up to the last 5,000), so the stats carry over between launches.
- **Settings**: see below.

## Settings

Open the **Settings** tab in the app window. Each setting is shown as a title, a short description and its current value with a stepper.

- **Nothing changes until you press Save.** Edits stay in a draft; **Save** writes and applies them, and changing an interval restarts that countdown.
- The button reads **Save** while there are unsaved changes and **Saved** once everything is applied.
- Closing the window without saving discards your edits.
- **Reset to defaults** fills in the defaults, but they too only take effect once you press Save.

| Group | Setting | What it does | Default |
|-------|---------|--------------|---------|
| Water | Reminder interval | How often a water reminder appears | 60 min |
| Water | Snooze delay | Wait before asking again when you say later | 15 min |
| Eye break | Reminder interval | How often an eye break is suggested | 180 min |
| Eye break | Snooze delay | Wait before asking again when you say not now | 10 min |
| Eye break | Break length | How long the guided routine runs | 60 sec |
| Both | Esc delay | Wait before coming back after you press Esc | 15 min |
| Both | Minimum gap | Least time between a water reminder and an eye break | 10 min |

## Characters

Every character has the same set of animations: walking in and out, offering the water, a happy reaction, a sad or side-eye reaction, and the eye-break poses. What differs is the name, the artwork, the colours and every word they say. The table compares the two characters that ship with the app, as an example of how far characters can differ.

| | `female` | `male` |
|---|--------|------|
| Look | Long dark hair, cream suit, gold earrings, glasses | Black hoodie, khaki cargo trousers, brown boots, glasses |
| Water | Holds the glass out while she talks | Strikes a standing, hands-in-pockets pose while he talks |
| Said no | A sad, then eyes-closed reaction | A swaying side-eye |
| Eye break | Lies down with a laptop, then glasses and stretches | Lies down with a laptop, then glasses, stretches and a yawn |
| Voice | Warm and playful | Casual, with "Oi, sunn!" and "Lessgo!" |

### How a character is built

Each character is a `Persona` (`Sources/TinyNudges/Persona.swift`). It bundles:

- the character's **id** (used for the sprite folder and saved choices) and display **name**,
- a **colour palette** for the speech bubbles and the popover,
- **sprite counts**: how many frames each animation has, which frame is held while asking, which one bounces when stretching, and an optional standing pose,
- a **script**: the button labels, the water greetings and replies, the eye-break pitches, the eye-break routine (eleven timed steps plus a finale) and an optional goodbye,
- an optional **menu avatar** (a sprite file shown in the character list).

`Personas/Female.swift` and `Personas/Male.swift` are the two included examples. The character chosen for each reminder is stored in your preferences and picked up fresh each time that reminder appears.

### Adding another character

1. Make a folder `Sources/TinyNudges/Resources/<id>/` with PNG frames named `<animation>_<number>.png`: `walkin`, `walkout`, `give`, `happy`, `sad` and `eye` (plus `relax` for the laptop and stretch poses, and `idle` if the character should stand while talking). Frames in one animation should share the same canvas size so the character doesn't jump.
2. Copy `Personas/Male.swift`, rename it, give it a name, and fill in the palette, sprite counts, messages and (optionally) a menu avatar.
3. Add it to `Persona.all` in `Persona.swift`.
4. Run `./package.sh`. The "Nagged by" lists show every character in `Persona.all`.

Walk frames must face the way the character moves: **left** when walking in (they enter from the right edge) and **right** when walking out.

### Making sprites from sheets

The source artwork lives in `Frames/` as sprite sheets. The male sheets are sliced into frames by a script:

```sh
python3 Scripts/slice_male_frames.py
```

It needs Python 3 with `Pillow`, `numpy` and `scipy` (`pip3 install pillow numpy scipy`). The script:

- splits each sheet into its poses,
- removes backgrounds, including faint halos and stray specks,
- scales every frame in an animation onto one shared canvas,
- mirrors the walk frames so they face the right way,
- writes the results to `Sources/TinyNudges/Resources/male/`.

It reads `Male Walk In/Out`, `Male Give Water`, `Male Happy`, `male side eye`, `Male Cool pose` and `Specific` (the eye-break poses) from `Frames/`. The female frames were already sliced and live in `Resources/female/`.

## Install

Tiny Nudges is built from source; there is no pre-built download. You need a Mac running macOS 13 or later.

1. Install the Swift toolchain if you don't have it: `xcode-select --install` (or install Xcode).
2. Download the code:
   ```sh
   git clone https://github.com/sen-riya/tiny-nudges.git
   cd tiny-nudges
   ```
   Or use **Code > Download ZIP** on GitHub, unzip it, and open a Terminal in that folder.
3. Install and start it:
   ```sh
   ./package.sh
   ```
4. Look for the water-drop icon in the menu bar. Press **Now** on a card to see the character straight away.

It then starts automatically every time you log in. To just try it without installing, run `swift run TinyNudges` instead of step 3.

### Requirements

- macOS 13 or later
- Swift 5.9+ toolchain (Xcode or Command Line Tools)

### What the installer does

`./package.sh` builds a release binary, creates `~/Applications/Tiny Nudges.app` (with the app icon), ad-hoc signs it, and registers a LaunchAgent so it starts at login. Run it again any time to reinstall after you change the code. Edit `LABEL` at the top of `package.sh` to use your own bundle identifier.

To uninstall:

```sh
launchctl bootout "gui/$(id -u)/com.tinynudges.app"
rm -rf "$HOME/Applications/Tiny Nudges.app" "$HOME/Library/LaunchAgents/com.tinynudges.app.plist"
```

## Customising

- **Change what a character says:** edit `Personas/Female.swift` or `Personas/Male.swift`, then run `./package.sh`. The speech bubbles fit their text: they are as narrow as short text allows and grow (up to about 290 pt wide) to wrap long text. The two buttons sit side by side when their labels are short and stack when a label is long.
- **Change colours:** edit the `palette` of the character.
- **Change timings:** use Settings, or the [environment variables](#testing-with-short-timings) while testing.

## Testing with short timings

Environment variables override the saved Settings values. Set any interval (in seconds) like this:

```sh
TINY_NUDGES_INTERVAL_SECONDS=20 TINY_NUDGES_EYE_INTERVAL_SECONDS=45 swift run TinyNudges
```

| Variable | Meaning |
|----------|---------|
| `TINY_NUDGES_INTERVAL_SECONDS` | water interval |
| `TINY_NUDGES_SNOOZE_SECONDS` | water "later" delay |
| `TINY_NUDGES_EYE_INTERVAL_SECONDS` | eye-break interval |
| `TINY_NUDGES_EYE_SNOOZE_SECONDS` | eye-break "not now" delay |
| `TINY_NUDGES_EYE_DURATION_SECONDS` | eye-break length |
| `TINY_NUDGES_DISMISS_SECONDS` | delay after pressing Esc |
| `TINY_NUDGES_GAP_SECONDS` | minimum gap between the two reminders |

To start with a particular character, pass it as a launch argument per reminder: `swift run TinyNudges -persona.water male -persona.eye female`.

## Project layout

- `Sources/TinyNudges/`: app code (SwiftUI + AppKit)
  - `TinyNudgesApp.swift`: app entry point (menu-bar popover and app window)
  - `MenuBarView.swift`: the simple menu-bar popover
  - `ReminderDetailView.swift` / `NudgeLog.swift`: the per-reminder stats page and the saved history of answers
  - `AppView.swift` / `Components.swift`: the app window (Reminders and Settings tabs) and its shared cards and buttons
  - `SettingsView.swift` / `TimingSetting.swift`: the Settings tab and the adjustable timings
  - `NudgeScheduler.swift`: decides when each reminder shows
  - `OverlayController.swift` / `OverlayView.swift` / `CharacterView.swift`: the on-screen character, the speech bubbles and the sprite animations
  - `EscapeHotKey.swift`: the global Esc shortcut
  - `Persona.swift`: what a character is (palette, sprites, messages)
  - `Personas/Female.swift`, `Personas/Male.swift`: each character's content
  - `Resources/female/`, `Resources/male/`: each character's sprite frames; `Resources/logo.png`: the logo shown in the popover header
- `Frames/`: source sprite sheets
- `Scripts/slice_male_frames.py`: slices the male sheets into frames
- `logo.png` / `Icon/AppIcon.icns`: the logo and the app icon made from it
- `package.sh`: build, install and enable start-at-login

## License

[MIT](LICENSE). The character artwork is AI-generated and free to reuse.
