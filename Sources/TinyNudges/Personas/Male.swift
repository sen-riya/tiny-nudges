import Foundation

extension Persona {
    /// The male character: black hoodie, khaki cargo trousers, brown boots. Sprites live in Resources/male/.
    /// Eye frames: 0 full body, 1-7 head-and-shoulders (glasses off, thinking, looking, glasses on), 8 lying with the laptop (his staple pose), 9 yawn.
    static let male = Persona(
        id: "male",
        name: "Male",
        palette: Palette(ink: (0.13, 0.12, 0.14), cream: (0.98, 0.96, 0.92), aqua: (0.62, 0.80, 0.93),
                         blush: (0.94, 0.82, 0.62), gold: (1.0, 0.84, 0.40), apricot: (0.98, 0.86, 0.70)),
        sprites: SpriteCounts(walkIn: 5, walkOut: 5, give: 3, happy: 1, sad: 1, eye: 8, relax: 2,
                              askFrame: 8, stretchFrame: 9, idle: 1),
        script: Script(
            waterYes: "Yes, bhai!", waterNo: "Later, bro",
            waterHappy: Message(title: "Dammmmnn, bhai!", subtitle: "Proud of you. See you in an hour."),
            waterSad: Message(title: "Ah!", subtitle: "Cool, cool. I'll be back in 15 minutes. Same glass."),
            eyeYes: "Lessgo!", eyeNo: "Not now",
            eyeLater: Message(title: "Ah!", subtitle: "Cool, cool. Your eyes and I will be back in 10 minutes."),
            waterLines: [
                Lines(greeting: "Oi, sunn!", title: "Drink some water", subtitle: "Your brain is running on fumes, bhai. One glass, quick."),
                Lines(greeting: "Heyyo, sunn! Yes, you.", title: "Time for some water", subtitle: "Go fill that glass. I'll wait right here."),
                Lines(greeting: "Oi, sunn bhai!", title: "Water break, right now", subtitle: "One glass, then back to the grind."),
                Lines(greeting: "Oi, sunn! Ek minute.", title: "Drink some water", subtitle: "Your glass is getting lonely, bhai."),
                Lines(greeting: "Oi, sunn!", title: "Don't make me ask twice", subtitle: "Grab a glass of water. Takes one minute."),
            ],
            eyeAsks: [
                EyeAsk(title: "Dammmmnn bhai, you've been working this long?", subtitle: "Lessgo, get a break. One minute, eyes off the screen."),
                EyeAsk(title: "Heyyo, bhai!", subtitle: "Your eyes are begging for a break. Just 60 seconds, bhai."),
                EyeAsk(title: "The screen can wait, bhai", subtitle: "Lessgo, one minute. Nothing on it is on fire."),
            ],
            eyeSegments: [
                EyeSegment(title: "Screens off, eyes up!", subtitle: "Lessgo, bhai. This minute is all yours.", seconds: 5, frames: [8], frameSeconds: 5),
                EyeSegment(title: "Glasses off!", subtitle: "Ohh Bhai, that feels good. Let those eyes breathe.", seconds: 5, frames: [0, 1, 2, 3], frameSeconds: 1.25),
                EyeSegment(title: "Breathe in…", subtitle: "Slow and easy. Follow the bubble.", seconds: 5, frames: [1], frameSeconds: 5, orb: .inhale),
                EyeSegment(title: "…and breathe out", subtitle: "Let it go, bhai. Yes, even that bug.", seconds: 5, frames: [1], frameSeconds: 5, orb: .exhale),
                EyeSegment(title: "Stretch it out!", subtitle: "Yehoo! Arms up high. Reach for the sky!", seconds: 5, frames: [9], frameSeconds: 5),
                EyeSegment(title: "Look over there!", subtitle: "Follow my eyes. Hmm, what's that?", seconds: 5, frames: [4], frameSeconds: 5),
                EyeSegment(title: "Now the other way!", subtitle: "Slow eye rolls. Nobody's watching. (I am.)", seconds: 5, frames: [5], frameSeconds: 5),
                EyeSegment(title: "Breathe in again…", subtitle: "Shoulders down. Jaw unclenched. Yeah, that one.", seconds: 5, frames: [1], frameSeconds: 5, orb: .inhale),
                EyeSegment(title: "…and all the way out", subtitle: "And relax. You're doing great, bhai.", seconds: 5, frames: [1], frameSeconds: 5, orb: .exhale),
                EyeSegment(title: "Big yawn time!", subtitle: "Stretch those arms and yawn like nobody's watching.", seconds: 5, frames: [9], frameSeconds: 5),
                EyeSegment(title: "Look far, far away", subtitle: "Woah Crazyyy, you can see the whole room. Pick a spot and focus.", seconds: 5, frames: [3, 4], frameSeconds: 2.5),
                EyeSegment(title: "Fresh eyes, who dis?", subtitle: "Glasses back on. Dammmmnn, you look brand new. Go crush it!", seconds: 5, frames: [6, 7], frameSeconds: 2.5, isFinale: true),
            ],
            bye: Message(title: "Crazy, bhai!", subtitle: "Will see you soon.")
        )
    )
}
