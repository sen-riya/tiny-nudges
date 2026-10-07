import AppKit
import SwiftUI

enum Pose { case walkIn, giveWater, idle, happy, sad, eyeBreak, walkOut }
enum Bubble { case greeting, question, happy, sad, eyeAsk, eyeLater, eyeStep, eyeDone }

/// How a reminder ended.
enum Outcome { case done, later, dismissed }

/// Owns the transparent window the character lives in and runs the
/// walk in -> ask -> react -> walk out sequence.
@MainActor
final class OverlayController: ObservableObject {
    @Published var pose: Pose = .walkIn
    @Published var poseStart = Date()
    @Published var bubble: Bubble?
    @Published var persona = Persona.selected
    @Published var lines = Persona.selected.script.waterLines[0]
    @Published var eyeFrame = 0            // index into Sprites.eye (strain frames, then laptop, then stretch)
    @Published var eyeStep = Persona.selected.script.eyeSegments[0]
    @Published var eyeProgress = 0.0       // 0...1 through the break
    @Published var eyeIndex = 0            // which of the 12 pop-ups we're on (drives the progress bar)
    @Published var segProgress = 0.0       // 0...1 through the current segment (drives the breathing orb)
    @Published var eyeAsk = Persona.selected.script.eyeAsks[0]

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

        setPose(persona.sprites.idle > 0 ? .idle : .giveWater)   // some characters strike a pose instead of offering the glass
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

    /// Eye-strain break: asks first, then a timed routine (see the persona's eyeSegments) of `duration` real seconds.
    /// `.done` = break taken, `.later` = "Not yet".
    func runEyeBreak(duration: Int) async -> Outcome {
        guard let session = await begin() else { return .later }
        if dismissed { return abort(session) }
        eyeIndex = 0
        eyeStep = persona.script.eyeSegments[0]   // otherwise the previous run's finale lingers in the first bubble
        eyeAsk = persona.script.eyeAsks.randomElement() ?? persona.script.eyeAsks[0]
        eyeFrame = persona.sprites.askFrame
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

        let scale = Double(duration) / persona.script.eyeRoutineSeconds
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
            for (i, seg) in persona.script.eyeSegments.enumerated() where !seg.isFinale {
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

        await playFinale()
        if dismissed { return abort(session) }
        await finish(session)
        return dismissed ? .dismissed : .done
    }

    /// The "Fresh eyes" message: shown only once the whole timed routine is done.
    private func playFinale() async {
        guard let index = persona.script.eyeSegments.firstIndex(where: \.isFinale) else { return }
        let seg = persona.script.eyeSegments[index]
        let start = Date()
        while !dismissed {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= seg.seconds { break }
            apply(index, at: elapsed)
            await pause(0.1)
        }
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
        let seg = persona.script.eyeSegments[index]
        if eyeIndex != index { eyeIndex = index }
        if eyeStep.title != seg.title { eyeStep = seg }   // not tied to eyeIndex: a new run restarts at index 0
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
        persona = Persona.selected   // picked up fresh each visit, so a change applies next time
        escapeKey.register { [weak self] in self?.dismiss() }
        bubble = nil
        lines = persona.script.waterLines.randomElement() ?? persona.script.waterLines[0]
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
