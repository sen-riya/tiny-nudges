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
            CharacterView(pose: controller.pose, start: controller.poseStart, eyeFrame: controller.eyeFrame)
                .padding(.trailing, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: controller.bubble)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: controller.eyeIndex)
    }
}

// Warm palette pulled from the character: chocolate hair, cream suit, gold earrings.
private let ink = Color(red: 0.25, green: 0.15, blue: 0.12)
private let cream = Color(red: 1.0, green: 0.965, blue: 0.92)
private let aqua = Color(red: 0.60, green: 0.86, blue: 0.84)
private let blush = Color(red: 1.0, green: 0.78, blue: 0.78)
private let gold = Color(red: 1.0, green: 0.84, blue: 0.45)
private let apricot = Color(red: 1.0, green: 0.84, blue: 0.68)

struct SpeechBubble: View {
    let kind: Bubble
    let controller: OverlayController

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
            .frame(width: 250)
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
                VStack(spacing: 4) {
                    Text(controller.lines.title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(controller.lines.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .opacity(0.75)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(ink)
                HStack(spacing: 10) {
                    BubbleButton(title: "I'll drink", fill: aqua) { controller.choose(drank: true) }
                    BubbleButton(title: "Maybe later", fill: blush) { controller.choose(drank: false) }
                }
            }
        case .eyeAsk:
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(controller.eyeAsk.title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(controller.eyeAsk.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .opacity(0.75)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(ink)
                HStack(spacing: 10) {
                    BubbleButton(title: "Break time!", fill: aqua) { controller.choose(drank: true) }
                    BubbleButton(title: "Not yet", fill: blush) { controller.choose(drank: false) }
                }
            }
        case .eyeLater:
            message(title: "Hmph. Fine.", subtitle: "I'll nag you again in 10 minutes. With love.")
        case .eyeStep:
            VStack(spacing: 12) {
                VStack(spacing: 3) {
                    Text(controller.eyeStep.title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(controller.eyeStep.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .opacity(0.75)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(ink)
                if let orb = controller.eyeStep.orb {
                    BreathOrb(inhale: orb == .inhale, progress: controller.segProgress)
                }
                StepBar(done: controller.eyeIndex + 1, of: EyeSegment.all.count)
            }
        case .eyeDone:
            VStack(spacing: 12) {
                message(title: controller.eyeStep.title, subtitle: controller.eyeStep.subtitle)
                StepBar(done: EyeSegment.all.count, of: EyeSegment.all.count)
            }
        case .happy:
            message(title: "Sip sip hooray!", subtitle: "Gold star for you. See you in an hour.")
        case .sad:
            message(title: "Boo… fine.", subtitle: "I'll go sulk for 15 minutes, then I'm back.")
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

/// A circle to breathe along with: it swells while you breathe in and shrinks as you breathe out.
struct BreathOrb: View {
    let inhale: Bool
    let progress: Double

    var body: some View {
        let grow = inhale ? progress : 1 - progress
        ZStack {
            Circle().fill(aqua).overlay(Circle().strokeBorder(ink, lineWidth: 2.5))
                .frame(width: 24 + 36 * grow, height: 24 + 36 * grow)
            Text(inhale ? "in" : "out")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(ink)
        }
        .frame(height: 60)
        .animation(.linear(duration: 0.1), value: progress)
    }
}

/// Segmented progress bar: one more segment fills with every pop-up.
struct StepBar: View {
    let done: Int
    let of: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<of, id: \.self) { i in
                Capsule()
                    .fill(i < done ? blush : cream)
                    .overlay(Capsule().strokeBorder(ink, lineWidth: 2))
                    .frame(height: 12)
                    .scaleEffect(i == done - 1 ? 1.12 : 1)
            }
        }
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
    let title: String
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(fill)
                        .overlay(Capsule().strokeBorder(ink, lineWidth: 2.5))
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
