import AppKit
import SwiftUI

enum Pose { case walkIn, giveWater, happy, sad, eyeBreak, walkOut }
enum Bubble { case greeting, question, happy, sad, eyeAsk, eyeLater, eyeStep, eyeDone }

/// One randomly picked set of lines per visit, so the reminder doesn't get stale.
struct Lines {
    let greeting: String
    let title: String
    let subtitle: String

    static let all: [Lines] = [
        Lines(greeting: "Knock knock! Guess who?", title: "Water break, superstar!", subtitle: "You're basically a houseplant. Time to water yourself."),
        Lines(greeting: "Surprise! It's me again!", title: "Sip sip hooray?", subtitle: "One glass of water, coming right up. You've got this."),
        Lines(greeting: "Pssst… hydration squad here!", title: "Your cup misses you", subtitle: "Go give it some love, then come back and tell me."),
        Lines(greeting: "Ta-daaa! Right on time!", title: "Glass of water o'clock", subtitle: "Future you says thank you in advance."),
        Lines(greeting: "Hellooo, hydration hero!", title: "Quick, before I dramatically sigh", subtitle: "Grab a glass of water. It only takes a minute."),
    ]
}

/// How a reminder ended.
enum Outcome { case done, later, dismissed }

/// Owns the transparent window the character lives in and runs the
/// walk in -> ask -> react -> walk out sequence.
@MainActor
final class OverlayController: ObservableObject {
    @Published var pose: Pose = .walkIn
    @Published var poseStart = Date()
    @Published var bubble: Bubble?
    @Published var lines = Lines.all[0]
    @Published var eyeFrame = 0            // index into Sprites.eye (0-7 strain sheet, 8 laptop, 9 stretch)
    @Published var eyeStep = EyeSegment.all[0]
    @Published var eyeProgress = 0.0       // 0...1 through the break
    @Published var eyeIndex = 0            // which of the 12 pop-ups we're on (drives the progress bar)
    @Published var segProgress = 0.0       // 0...1 through the current segment (drives the breathing orb)
    @Published var eyeAsk = EyeAsk.all[0]

    private(set) var isShowing = false
    private var panel: NSPanel?
    private var choice: CheckedContinuation<Bool, Never>?
    private var dismissed = false
    private let escapeKey = EscapeHotKey()

    private let size = CGSize(width: 320, height: 440)
    private let walkDuration: TimeInterval = 3.5

    /// Water reminder. `.done` = "I'll drink", `.later` = "Maybe later".
    func runWater() async -> Outcome {
        guard let session = await begin() else { return .later }
        if dismissed { return abort(session) }

        setPose(.giveWater)
        await pause(0.8)
        bubble = .greeting
        await pause(2.2)
        if dismissed { return abort(session) }
        bubble = .question
        let drank = await withCheckedContinuation { choice = $0 }
        if dismissed { return abort(session) }

        setPose(drank ? .happy : .sad)
        bubble = drank ? .happy : .sad
        await pause(2.8)
        if dismissed { return abort(session) }

        await finish(session)
        return dismissed ? .dismissed : (drank ? .done : .later)
    }

    /// Eye-strain break: asks first, then a timed routine (see EyeSegment.all) of `duration` real seconds.
    /// `.done` = break taken, `.later` = "Not yet".
    func runEyeBreak(duration: Int) async -> Outcome {
        guard let session = await begin() else { return .later }
        if dismissed { return abort(session) }
        eyeIndex = 0
        eyeAsk = EyeAsk.all.randomElement() ?? EyeAsk.all[0]
        eyeFrame = 8
        eyeProgress = 0
        setPose(.eyeBreak)
        bubble = .eyeAsk
        let accepted = await withCheckedContinuation { choice = $0 }
        if dismissed { return abort(session) }
        guard accepted else {
            setPose(.sad)
            bubble = .eyeLater
            await pause(2.8)
            if dismissed { return abort(session) }
            await finish(session)
            return dismissed ? .dismissed : .later
        }

        let scale = Double(duration) / EyeSegment.totalSeconds
        let total = Double(duration)
        setPose(.eyeBreak)
        apply(0)

        // Real clock, no skipping: she only leaves once the full minute has passed (or Esc is pressed).
        let start = Date()
        while !dismissed {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= total { break }
            eyeProgress = elapsed / total

            var t = 0.0
            for (i, seg) in EyeSegment.all.enumerated() {
                let len = seg.seconds * scale
                if elapsed < t + len {
                    segProgress = (elapsed - t) / len
                    apply(i, at: (elapsed - t) / scale)
                    break
                }
                t += len
            }
            await pause(0.1)
        }
        if dismissed { return abort(session) }
        eyeProgress = 1
        await finish(session)
        return dismissed ? .dismissed : .done
    }

    /// Esc: the character vanishes right away, wherever she is in the routine.
    func dismiss() {
        guard isShowing, !dismissed else { return }
        dismissed = true
        choice?.resume(returning: false)
        choice = nil
        bubble = nil
        if let panel {
            // Replaces any walk animation in flight and hides the window.
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0
                panel.animator().setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: panel.frame.origin.y))
            })
            panel.orderOut(nil)
        }
        escapeKey.unregister()
    }

    private func abort(_ s: Session) -> Outcome {
        s.panel.orderOut(nil)
        panel = nil
        bubble = nil
        escapeKey.unregister()
        isShowing = false
        return .dismissed
    }

    private func apply(_ index: Int, at t: Double = 0) {
        let seg = EyeSegment.all[index]
        if eyeIndex != index { eyeIndex = index; eyeStep = seg }
        let frame = seg.frames[Int(t / seg.frameSeconds) % seg.frames.count]
        if eyeFrame != frame { eyeFrame = frame }
        let bubble: Bubble = seg.isFinale ? .eyeDone : .eyeStep
        if self.bubble != bubble { self.bubble = bubble }
    }

    private struct Session { let panel: NSPanel; let y: CGFloat; let offscreenX: CGFloat }

    /// Opens the window and walks the character in. Nil if one is already showing.
    private func begin() async -> Session? {
        guard !isShowing, let screen = NSScreen.main else { return nil }
        isShowing = true
        dismissed = false
        escapeKey.register { [weak self] in self?.dismiss() }
        bubble = nil
        lines = Lines.all.randomElement() ?? Lines.all[0]
        setPose(.walkIn)

        let visible = screen.visibleFrame
        let y = visible.minY + 4
        let restX = visible.maxX - size.width
        let offscreenX = screen.frame.maxX
        let panel = makePanel(at: NSPoint(x: offscreenX, y: y))
        self.panel = panel
        panel.orderFrontRegardless()
        await slide(panel, toX: restX, y: y)
        return Session(panel: panel, y: y, offscreenX: offscreenX)
    }

    private func finish(_ s: Session) async {
        bubble = nil
        setPose(.walkOut)
        await slide(s.panel, toX: s.offscreenX, y: s.y)
        s.panel.orderOut(nil)
        panel = nil
        escapeKey.unregister()
        isShowing = false
    }

    private func setPose(_ p: Pose) {
        pose = p
        poseStart = Date()
    }

    func choose(drank: Bool) {
        choice?.resume(returning: drank)
        choice = nil
    }

    private func makePanel(at origin: NSPoint) -> NSPanel {
        let p = NSPanel(contentRect: NSRect(origin: origin, size: size),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .floating
        p.hidesOnDeactivate = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let host = NSHostingView(rootView: OverlayView(controller: self))
        host.sizingOptions = []   // content must never resize/move the window
        p.contentView = host
        p.setContentSize(size)
        p.setFrameOrigin(origin)
        return p
    }

    private func slide(_ panel: NSPanel, toX x: CGFloat, y: CGFloat) async {
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = walkDuration
                ctx.timingFunction = CAMediaTimingFunction(name: .linear)
                panel.animator().setFrame(NSRect(origin: NSPoint(x: x, y: y), size: size), display: true)
            }, completionHandler: { done.resume() })
        }
    }

    private func pause(_ seconds: TimeInterval) async {
        var left = seconds
        while left > 0 && !dismissed {   // short steps so Esc takes effect immediately
            try? await Task.sleep(nanoseconds: 100_000_000)
            left -= 0.1
        }
    }
}

/// One moment of the 1-minute eye break. Segment lengths add up to 60 s.
struct EyeSegment {
    let title: String
    let subtitle: String
    let seconds: Double
    let frames: [Int]          // indices into Sprites.eye
    let frameSeconds: Double   // how long each frame is shown
    var orb: Orb? = nil
    var isFinale = false

    enum Orb { case inhale, exhale }

    static let totalSeconds = all.reduce(0) { $0 + $1.seconds }

    static let all: [EyeSegment] = [
        EyeSegment(title: "Screens off, eyes up!", subtitle: "You've worked so hard today. This minute is all yours.", seconds: 5, frames: [8], frameSeconds: 5),
        EyeSegment(title: "Glasses off!", subtitle: "Those eyes have earned a proper rest.", seconds: 5, frames: [0, 1, 2, 3], frameSeconds: 1.25),
        EyeSegment(title: "Breathe in…", subtitle: "Nice and slow. Follow the bubble.", seconds: 5, frames: [3], frameSeconds: 5, orb: .inhale),
        EyeSegment(title: "…and breathe out", subtitle: "Let it all go, even that tab you're stressing about.", seconds: 5, frames: [3], frameSeconds: 5, orb: .exhale),
        EyeSegment(title: "Stretch it out!", subtitle: "Arms up high. Reach for the ceiling!", seconds: 5, frames: [9], frameSeconds: 5),
        EyeSegment(title: "Look over there!", subtitle: "Follow my eyes. Ooh, what's that?", seconds: 5, frames: [4], frameSeconds: 5),
        EyeSegment(title: "Now the other way!", subtitle: "Slow eye rolls. Nobody's watching. (I am.)", seconds: 5, frames: [5], frameSeconds: 5),
        EyeSegment(title: "Breathe in again…", subtitle: "Shoulders down. Jaw unclenched. Yes, that one.", seconds: 5, frames: [3], frameSeconds: 5, orb: .inhale),
        EyeSegment(title: "…and all the way out", subtitle: "Aaaand relax. You're doing amazing.", seconds: 5, frames: [3], frameSeconds: 5, orb: .exhale),
        EyeSegment(title: "Big yawn time!", subtitle: "Stretch those arms and yawn like nobody's watching.", seconds: 5, frames: [9], frameSeconds: 5),
        EyeSegment(title: "Look far, far away", subtitle: "Pick something across the room and stare like you mean it.", seconds: 5, frames: [3, 4], frameSeconds: 2.5),
        EyeSegment(title: "Fresh eyes, who dis?", subtitle: "Glasses back on. You deserved that. Go be brilliant!", seconds: 5, frames: [6, 7], frameSeconds: 2.5, isFinale: true),
    ]
}

/// The opening "you deserve a break" pitch; one is picked at random per visit.
struct EyeAsk {
    let title: String
    let subtitle: String

    static let all: [EyeAsk] = [
        EyeAsk(title: "You've worked so hard!", subtitle: "Seriously, you deserve a break. One minute, eyes off the screen?"),
        EyeAsk(title: "Look at you, being productive!", subtitle: "Your eyes are begging for a breather. Give them 60 seconds?"),
        EyeAsk(title: "Okay hotshot, pause!", subtitle: "The screen will survive without you for a minute. Promise."),
    ]
}
