import Foundation

extension Persona {
    /// The original character: chocolate hair, cream suit, gold earrings. Sprites live in Resources/female/.
    static let female = Persona(
        id: "female",
        name: "Female",
        palette: Palette(ink: (0.25, 0.15, 0.12), cream: (1.0, 0.965, 0.92), aqua: (0.60, 0.86, 0.84),
                         blush: (1.0, 0.78, 0.78), gold: (1.0, 0.84, 0.45), apricot: (1.0, 0.84, 0.68)),
        sprites: SpriteCounts(walkIn: 4, walkOut: 4, give: 3, happy: 1, sad: 2, eye: 8, relax: 2, askFrame: 8, stretchFrame: 9),
        script: Script(
            waterYes: "I'll drink", waterNo: "Maybe later",
            waterHappy: Message(title: "Sip sip hooray!", subtitle: "Gold star for you. See you in an hour."),
            waterSad: Message(title: "Boo… fine.", subtitle: "I'll go sulk for 15 minutes, then I'm back."),
            eyeYes: "Break time!", eyeNo: "Not yet",
            eyeLater: Message(title: "Hmph. Fine.", subtitle: "I'll nag you again in 10 minutes. With love."),
            waterLines: [
                Lines(greeting: "Knock knock! Guess who?", title: "Water break, superstar!", subtitle: "You're basically a houseplant. Time to water yourself."),
                Lines(greeting: "Surprise! It's me again!", title: "Sip sip hooray?", subtitle: "One glass of water, coming right up. You've got this."),
                Lines(greeting: "Pssst… hydration squad here!", title: "Your cup misses you", subtitle: "Go give it some love, then come back and tell me."),
                Lines(greeting: "Ta-daaa! Right on time!", title: "Glass of water o'clock", subtitle: "Future you says thank you in advance."),
                Lines(greeting: "Hellooo, hydration hero!", title: "Quick, before I dramatically sigh", subtitle: "Grab a glass of water. It only takes a minute."),
            ],
            eyeAsks: [
                EyeAsk(title: "You've worked so hard!", subtitle: "Seriously, you deserve a break. One minute, eyes off the screen?"),
                EyeAsk(title: "Look at you, being productive!", subtitle: "Your eyes are begging for a breather. Give them 60 seconds?"),
                EyeAsk(title: "Okay hotshot, pause!", subtitle: "The screen will survive without you for a minute. Promise."),
            ],
            eyeSegments: [
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
        ),
        avatarSprite: "eye_0"
    )
}
