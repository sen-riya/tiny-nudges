import SwiftUI

struct OverlayView: View {
    @ObservedObject var controller: OverlayController

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer(minLength: 0)
            if let bubble = controller.bubble {
                SpeechBubble(kind: bubble, controller: controller)
                    .id(controller.eyeIndex)   // each break step pops in as a fresh bubble
                    .transition(.scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity))
            }
            CharacterView(persona: controller.persona, pose: controller.pose, start: controller.poseStart, eyeFrame: controller.eyeFrame)
                .padding(.trailing, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: controller.bubble)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: controller.eyeIndex)
    }
}

struct SpeechBubble: View {
    let kind: Bubble
    let controller: OverlayController

    private var palette: Persona.Palette { controller.persona.palette }
    private var script: Persona.Script { controller.persona.script }
    private var ink: Color { Color(palette.ink) }
    private var cream: Color { Color(palette.cream) }
    private var aqua: Color { Color(palette.aqua) }
    private var blush: Color { Color(palette.blush) }
    private var gold: Color { Color(palette.gold) }
    private var apricot: Color { Color(palette.apricot) }

    var body: some View {
        VStack(alignment: .trailing, spacing: -2) {
            card.zIndex(1)
            Tail()
                .fill(cream)
                .overlay(Tail().fill(accent.opacity(0.45)))
                .overlay(Tail().stroke(ink, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)))
                .frame(width: 24, height: 13)
                .padding(.trailing, 48)
        }
        .padding(.trailing, 10)
        .padding(.bottom, 2)
    }

    private var card: some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minWidth: 210, maxWidth: 290)   // hugs short text, grows (and wraps) for long text
            .fixedSize(horizontal: false, vertical: true)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(ink).offset(x: 4, y: 5)
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(cream)
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(accent.opacity(0.45))
                    RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(ink, lineWidth: 2.5)
                }
            )
    }

    private var accent: Color {
        switch kind {
        case .eyeAsk: return apricot
        case .eyeLater: return aqua
        case .eyeStep: return aqua
        case .eyeDone: return gold
        case .bye: return apricot
        case .greeting: return blush
        case .question: return apricot
        case .happy: return gold
        case .sad: return aqua
        }
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .greeting:
            Text(controller.lines.greeting)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(ink)
        case .question:
            VStack(spacing: 14) {
                BubbleText(palette: palette, title: controller.lines.title, subtitle: controller.lines.subtitle)
                ButtonRow(palette: palette, yes: script.waterYes, no: script.waterNo) { controller.choose(drank: $0) }
            }
        case .eyeAsk:
            VStack(spacing: 14) {
                BubbleText(palette: palette, title: controller.eyeAsk.title, subtitle: controller.eyeAsk.subtitle)
                ButtonRow(palette: palette, yes: script.eyeYes, no: script.eyeNo) { controller.choose(drank: $0) }
            }
        case .eyeLater:
            message(title: script.eyeLater.title, subtitle: script.eyeLater.subtitle)
        case .eyeStep:
            VStack(spacing: 12) {
                BubbleText(palette: palette, title: controller.eyeStep.title, subtitle: controller.eyeStep.subtitle)
                if let orb = controller.eyeStep.orb {
                    BreathOrb(palette: palette, inhale: orb == .inhale, progress: controller.segProgress)
                }
                StepBar(palette: palette, done: controller.eyeIndex + 1, of: script.eyeSegments.count)
            }
        case .eyeDone:
            VStack(spacing: 12) {
                message(title: controller.eyeStep.title, subtitle: controller.eyeStep.subtitle)
                StepBar(palette: palette, done: script.eyeSegments.count, of: script.eyeSegments.count)
            }
        case .bye:
            if let bye = script.bye { message(title: bye.title, subtitle: bye.subtitle) }
        case .happy:
            message(title: script.waterHappy.title, subtitle: script.waterHappy.subtitle)
        case .sad:
            message(title: script.waterSad.title, subtitle: script.waterSad.subtitle)
        }
    }

    private func message(title: String, subtitle: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.system(size: 20, weight: .heavy, design: .rounded))
            Text(subtitle).font(.system(size: 13, weight: .medium, design: .rounded)).opacity(0.75)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(ink)
    }
}

/// Title plus smaller subtitle, centred; wraps to as many lines as the text needs.
struct BubbleText: View {
    let palette: Persona.Palette
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .opacity(0.75)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(Color(palette.ink))
    }
}

/// The yes / no buttons: side by side when the labels are short, stacked when they're long.
struct ButtonRow: View {
    let palette: Persona.Palette
    let yes: String
    let no: String
    let choose: (Bool) -> Void

    private var stacked: Bool { max(yes.count, no.count) > 13 }

    var body: some View {
        let layout = stacked ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            BubbleButton(palette: palette, title: yes, fill: Color(palette.aqua)) { choose(true) }
            BubbleButton(palette: palette, title: no, fill: Color(palette.blush)) { choose(false) }
        }
    }
}

/// A circle to breathe along with: it swells while you breathe in and shrinks as you breathe out.
struct BreathOrb: View {
    let palette: Persona.Palette
    let inhale: Bool
    let progress: Double

    var body: some View {
        let grow = inhale ? progress : 1 - progress
        ZStack {
            Circle().fill(Color(palette.aqua)).overlay(Circle().strokeBorder(Color(palette.ink), lineWidth: 2.5))
                .frame(width: 24 + 36 * grow, height: 24 + 36 * grow)
            Text(inhale ? "in" : "out")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Color(palette.ink))
        }
        .frame(height: 60)
        .animation(.linear(duration: 0.1), value: progress)
    }
}

/// Segmented progress bar: one more segment fills with every pop-up.
struct StepBar: View {
    let palette: Persona.Palette
    let done: Int
    let of: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<of, id: \.self) { i in
                Capsule()
                    .fill(Color(i < done ? palette.blush : palette.cream))
                    .overlay(Capsule().strokeBorder(Color(palette.ink), lineWidth: 2))
                    .frame(height: 12)
                    .scaleEffect(i == done - 1 ? 1.12 : 1)
            }
        }
        .frame(maxWidth: 214)   // don't let the bar stretch the bubble
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: done)
    }
}

struct Tail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

struct BubbleButton: View {
    let palette: Persona.Palette
    let title: String
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(Color(palette.ink))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)   // long labels wrap instead of clipping
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .padding(.horizontal, 10)
                .background(
                    Capsule().fill(fill)
                        .overlay(Capsule().strokeBorder(Color(palette.ink), lineWidth: 2.5))
                )
        }
        .buttonStyle(PressStyle())
    }
}

private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
