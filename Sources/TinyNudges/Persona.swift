import SwiftUI

/// Everything that makes one character *that* character: its sprites (Resources/<id>/),
/// bubble colours, and every word it says. To add a character, drop in a sprite folder,
/// write a `Persona` like `Persona.female`, and list it in `Persona.all`.
struct Persona: Identifiable {
    let id: String
    let name: String
    let palette: Palette
    let sprites: SpriteCounts
    let script: Script
    /// Wording for the menu and Settings screens. Optional: a new character gets the neutral defaults.
    var ui = UIText()
    /// Sprite file (without .png) used as the menu avatar; nil = the standing pose, else the happy one.
    var avatarSprite: String? = nil

    static let all: [Persona] = [.female, .male]
    /// The single-character setting from before each reminder had its own; still read as a fallback.
    static let storageKey = "persona"

    enum Reminder: String {
        case water, eye
        var storageKey: String { "persona.\(rawValue)" }
    }

    /// The character the user picked for a reminder (falls back to the older shared pick, then the first character).
    static func selected(for reminder: Reminder) -> Persona {
        let d = UserDefaults.standard
        let id = d.string(forKey: reminder.storageKey) ?? d.string(forKey: storageKey)
        return all.first { $0.id == id } ?? all[0]
    }

    /// Resolves a stored id (empty = not chosen yet) for a reminder.
    static func resolve(_ id: String, for reminder: Reminder) -> Persona {
        all.first { $0.id == id } ?? selected(for: reminder)
    }

    /// Bubble colours, as RGB triples so personas can be declared without SwiftUI.
    struct Palette {
        typealias RGB = (Double, Double, Double)
        let ink, cream, aqua, blush, gold, apricot: RGB
    }

    /// How many frames each sprite sequence has: Resources/<id>/<name>_<n>.png.
    /// The eye-break frames are `eye_0…` followed by `relax_0…`, numbered as one list (`EyeSegment.frames`).
    /// `askFrame` is the pose held while asking (and in the first step); `stretchFrame` is the one that bounces.
    struct SpriteCounts {
        let walkIn, walkOut, give, happy, sad, eye, relax: Int
        let askFrame, stretchFrame: Int
        /// Frames of an optional standing pose held while talking after walking in (0 = none: the glass is held out instead).
        var idle = 0
    }

    /// The character's voice in the menu-bar popover and Settings. Every field has a neutral default,
    /// so a new persona only overrides what it wants to say differently.
    struct UIText {
        var menuTagline = "Looking after you"
        var settingsSubtitle = "Press Save to apply changes"
        var save = "Save"
        var saved = "Saved"
        /// Shown under the water card; `%d` is today's glass count.
        var glassesOne = "1 glass today"
        var glassesMany = "%d glasses today"
    }

    /// All the words, per reminder.
    struct Script {
        let waterYes, waterNo: String
        let waterHappy, waterSad: Message
        let eyeYes, eyeNo: String
        let eyeLater: Message
        let waterLines: [Lines]
        let eyeAsks: [EyeAsk]
        let eyeSegments: [EyeSegment]
        /// Said while walking back out (nil = leaves silently).
        var bye: Message? = nil

        /// Length of the timed routine; the finale is shown afterwards and isn't counted.
        var eyeRoutineSeconds: Double { eyeSegments.filter { !$0.isFinale }.reduce(0) { $0 + $1.seconds } }
    }
}

extension Color {
    init(_ rgb: Persona.Palette.RGB) { self.init(red: rgb.0, green: rgb.1, blue: rgb.2) }
}

struct Message { let title: String; let subtitle: String }

/// One randomly picked set of lines per water visit, so the reminder doesn't get stale.
struct Lines {
    let greeting: String
    let title: String
    let subtitle: String
}

/// The opening "you deserve a break" pitch; one is picked at random per visit.
struct EyeAsk {
    let title: String
    let subtitle: String
}

/// One moment of the eye break. Segment lengths (excluding the finale) add up to the routine length.
struct EyeSegment {
    let title: String
    let subtitle: String
    let seconds: Double
    let frames: [Int]          // indices into the persona's eye frames
    let frameSeconds: Double   // how long each frame is shown
    var orb: Orb? = nil
    var isFinale = false

    enum Orb { case inhale, exhale }
}
