import SwiftUI

/// Plays the persona's sprite frames from Resources/<id>/ (sliced from the Frames/ sheets).
struct CharacterView: View {
    let persona: Persona
    let pose: Pose
    let start: Date
    var eyeFrame = 0

    /// ~4 cm on screen (doubled from the original ~2 cm).
    private static let height: CGFloat = 114

    var body: some View {
        TimelineView(.animation) { timeline in
            let dt = timeline.date.timeIntervalSince(start)
            let sprites = Sprites.set(for: persona)
            Image(nsImage: pose == .eyeBreak ? sprites.eye[eyeFrame] : sprites.image(for: pose, at: dt))
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: pose == .happy ? Self.height * 1.2 : pose == .eyeBreak ? Self.height * (eyeFrame == persona.sprites.askFrame ? 0.95 : 1.25) : Self.height)
                .rotationEffect(.degrees(pose == .sad && sprites.sad.count == 1 ? sin(dt * 3) * 2.5 : 0), anchor: .bottom)   // a single sad frame sways instead of staying frozen
                .scaleEffect(pose == .eyeBreak ? 1 + 0.035 * sin(dt * 2 * .pi / 5) : 1, anchor: .bottom)   // slow breathing
                .offset(y: pose == .happy ? -abs(sin(dt * 7)) * 14 : (pose == .eyeBreak && eyeFrame == persona.sprites.stretchFrame ? -abs(sin(dt * 2)) * 4 : 0))
        }
    }
}

/// One persona's loaded frames, cached after the first use.
private struct Sprites {
    let walkIn, walkOut, give, happy, sad, idle: [NSImage]
    let eye: [NSImage]   // strain frames, then laptop, then stretch

    private static var cache: [String: Sprites] = [:]

    static func set(for persona: Persona) -> Sprites {
        if let cached = cache[persona.id] { return cached }
        let n = persona.sprites
        let set = Sprites(
            walkIn: load("walkin", n.walkIn, persona.id), walkOut: load("walkout", n.walkOut, persona.id),
            give: load("give", n.give, persona.id), happy: load("happy", n.happy, persona.id),
            sad: load("sad", n.sad, persona.id), idle: load("idle", n.idle, persona.id),
            eye: load("eye", n.eye, persona.id) + load("relax", n.relax, persona.id))
        cache[persona.id] = set
        return set
    }

    func image(for pose: Pose, at t: TimeInterval) -> NSImage {
        switch pose {
        case .walkIn: return walkIn[Int(t * 8) % walkIn.count]
        case .walkOut: return walkOut[Int(t * 8) % walkOut.count]
        case .giveWater: return give[min(give.count - 1, Int(t * 4))]   // plays once, holds the glass out
        case .idle: return idle[0]
        case .happy: return happy[0]
        case .eyeBreak: return eye[0]
        case .sad: return sad[min(sad.count - 1, Int(t / 0.8))]          // looks down, then closes eyes
        }
    }

    /// Frames that exist on disk; a count larger than the files provided is tolerated (extra frames are skipped).
    private static func load(_ name: String, _ count: Int, _ folder: String) -> [NSImage] {
        (0..<count).compactMap { i in
            Bundle.module.url(forResource: "\(name)_\(i)", withExtension: "png", subdirectory: "Resources/\(folder)")
                .flatMap(NSImage.init(contentsOf:))
        }
    }
}
