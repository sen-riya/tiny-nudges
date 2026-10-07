import SwiftUI

/// Everything that makes one character *that* character: her sprites (Resources/<id>/),
/// bubble colours, and every word she says. To add a character, drop in a sprite folder,
/// write a `Persona` like `Persona.female`, and list it in `Persona.all`.
struct Persona: Identifiable {
    let id: String
    let name: String
    let palette: Palette
    let sprites: SpriteCounts
    let script: Script

    static let all: [Persona] = [.female, .male]
    static let storageKey = "persona"

    /// The character the user picked (falls back to the first one).
    static var selected: Persona {
        let id = UserDefaults.standard.string(forKey: storageKey)
        return all.first { $0.id == id } ?? all[0]
    }

    /// Bubble colours, as RGB triples so personas can be declared without SwiftUI.
    struct Palette {
        typealias RGB = (Double, Double, Double)
        let ink, cream, aqua, blush, gold, apricot: RGB
    }

    /// How many frames each sprite sequence has: Resources/<id>/<name>_<n>.png.
    /// The eye-break frames are `eye_0…` followed by `relax_0…`, numbered as one list (`EyeSegment.frames`).
    /// `askFrame` is the pose she holds while asking (and in the first step); `stretchFrame` is the one that bounces.
    struct SpriteCounts {
        let walkIn, walkOut, give, happy, sad, eye, relax: Int
        let askFrame, stretchFrame: Int
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
