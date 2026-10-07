import Foundation

extension Persona {
    /// The male character: black hoodie, khaki cargo trousers, brown boots. Sprites live in Resources/male/.
    /// Eye frames: 0 full body, 1-7 head-and-shoulders (glasses off, thinking, looking, glasses on), 8 lying with the laptop (his staple pose), 9 yawn.
    static let male = Persona(
        id: "male",
        name: "Male",
        palette: Palette(ink: (0.13, 0.12, 0.14), cream: (0.98, 0.96, 0.92), aqua: (0.62, 0.80, 0.93),
                         blush: (0.94, 0.82, 0.62), gold: (1.0, 0.84, 0.40), apricot: (0.98, 0.86, 0.70)),
        sprites: SpriteCounts(walkIn: 5, walkOut: 5, give: 3, happy: 1, sad: 2, eye: 8, relax: 2,
                              askFrame: 8, stretchFrame: 9, idle: 1),
        script: Script(
            waterYes: "Yes, bhai!", waterNo: "Later, bro",
            waterHappy: Message(title: "Dammmmnn!", subtitle: "Hydration level: legend. See you in an hour."),
            waterSad: Message(title: "Ohh Bhai…", subtitle: "Really? I'll be back in 15 minutes. Same glass."),
            eyeYes: "Let's do it", eyeNo: "Not now",
            eyeLater: Message(title: "Crazy… fine.", subtitle: "Your eyes and I will be back in 10 minutes."),
            waterLines: [
                Lines(greeting: "Ohh Bhai! Got a minute?", title: "Water o'clock, champ", subtitle: "Your brain runs on this stuff. Let's top it up."),
                Lines(greeting: "Special delivery, bhai!", title: "Dammmmnn, fresh glass!", subtitle: "Drink up and get back to being awesome."),
                Lines(greeting: "Woah Crazyyy, it's me again!", title: "Your glass called", subtitle: "It says it's lonely. Go pay it a visit."),
                Lines(greeting: "Pit stop time!", title: "Refuel, boss", subtitle: "Crazy how long it's been. Even the best engines need water."),
                Lines(greeting: "Ahem. Hydration check!", title: "Quick sip, big win", subtitle: "Takes one minute. Ohh Bhai, I'll wait right here."),
            ],
            eyeAsks: [
                EyeAsk(title: "Dammmmnn, big day!", subtitle: "Your eyes have earned a breather. One minute, screen off?"),
                EyeAsk(title: "Ohh Bhai, look away!", subtitle: "Give your eyes 60 seconds. The code will wait. Promise."),
                EyeAsk(title: "Crazy amount of work!", subtitle: "Nothing on that screen is on fire. Take a minute."),
            ],
            eyeSegments: [
                EyeSegment(title: "Screens off, eyes up!", subtitle: "Dammmmnn, you've been grinding all day. This minute is yours.", seconds: 5, frames: [8], frameSeconds: 5),
                EyeSegment(title: "Glasses off!", subtitle: "Ohh Bhai, let those eyes breathe for a second.", seconds: 5, frames: [0, 1, 2, 3], frameSeconds: 1.25),
                EyeSegment(title: "Breathe in…", subtitle: "Nice and slow. Follow the bubble.", seconds: 5, frames: [1], frameSeconds: 5, orb: .inhale),
                EyeSegment(title: "…and breathe out", subtitle: "Let it go. Yes, even that crazy bug.", seconds: 5, frames: [1], frameSeconds: 5, orb: .exhale),
                EyeSegment(title: "Stretch it out!", subtitle: "Arms up high. Reach for the ceiling!", seconds: 5, frames: [9], frameSeconds: 5),
                EyeSegment(title: "Look over there!", subtitle: "Follow my eyes. Woah Crazyyy, what's that?", seconds: 5, frames: [4], frameSeconds: 5),
                EyeSegment(title: "Now the other way!", subtitle: "Slow eye rolls. Nobody's watching. (I am.)", seconds: 5, frames: [5], frameSeconds: 5),
                EyeSegment(title: "Breathe in again…", subtitle: "Shoulders down. Jaw unclenched. Yeah, that one.", seconds: 5, frames: [1], frameSeconds: 5, orb: .inhale),
                EyeSegment(title: "…and all the way out", subtitle: "And relax. You're doing great.", seconds: 5, frames: [1], frameSeconds: 5, orb: .exhale),
                EyeSegment(title: "Big yawn time!", subtitle: "Stretch those arms and yawn like nobody's watching.", seconds: 5, frames: [9], frameSeconds: 5),
                EyeSegment(title: "Look far, far away", subtitle: "Pick something across the room. Crazy how relaxing that is.", seconds: 5, frames: [3, 4], frameSeconds: 2.5),
                EyeSegment(title: "Fresh eyes, who dis?", subtitle: "Glasses back on. Dammmmnn, you look brand new. Go crush it!", seconds: 5, frames: [6, 7], frameSeconds: 2.5, isFinale: true),
            ]
        )
    )
}
