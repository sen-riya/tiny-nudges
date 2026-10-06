import SwiftUI

/// Plays the sprite frames from Resources/ (sliced from the Frames/ sheets).
struct CharacterView: View {
    let pose: Pose
    let start: Date
    var eyeFrame = 0

    /// ~4 cm on screen (doubled from the original ~2 cm).
    private static let height: CGFloat = 114

    var body: some View {
        TimelineView(.animation) { timeline in
            let dt = timeline.date.timeIntervalSince(start)
            Image(nsImage: pose == .eyeBreak ? Sprites.eye[eyeFrame] : Sprites.image(for: pose, at: dt))
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: pose == .happy ? Self.height * 1.2 : pose == .eyeBreak ? Self.height * (eyeFrame == 8 ? 0.95 : 1.25) : Self.height)
                .scaleEffect(pose == .eyeBreak ? 1 + 0.035 * sin(dt * 2 * .pi / 5) : 1, anchor: .bottom)   // slow breathing
                .offset(y: pose == .happy ? -abs(sin(dt * 7)) * 14 : (pose == .eyeBreak && eyeFrame == 9 ? -abs(sin(dt * 2)) * 4 : 0))
        }
    }
}

private enum Sprites {
    static let walkIn = load("walkin", 4)
    static let walkOut = load("walkout", 4)
    static let give = load("give", 3)
    static let happy = load("happy", 1)
    static let sad = load("sad", 2)
    static let eye = load("eye", 8) + load("relax", 2)   // 8 = laptop, 9 = stretch

    static func image(for pose: Pose, at t: TimeInterval) -> NSImage {
        switch pose {
        case .walkIn: return walkIn[Int(t * 8) % walkIn.count]
        case .walkOut: return walkOut[Int(t * 8) % walkOut.count]
        case .giveWater: return give[min(give.count - 1, Int(t * 4))]   // plays once, holds the glass out
        case .happy: return happy[0]
        case .eyeBreak: return eye[0]
        case .sad: return sad[min(sad.count - 1, Int(t / 0.8))]          // looks down, then closes eyes
        }
    }

    private static func load(_ name: String, _ count: Int) -> [NSImage] {
        (0..<count).map { i in
            Bundle.module.url(forResource: "\(name)_\(i)", withExtension: "png")
                .flatMap(NSImage.init(contentsOf:)) ?? NSImage()
        }
    }
}
