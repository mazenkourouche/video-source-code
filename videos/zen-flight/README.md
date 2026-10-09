# Zen Flight

A one-tap paper-plane game with bamboo obstacles and hand-drawn Japanese-garden artwork. Built with SwiftUI and SpriteKit for iOS 17 or later.

## Run it

1. Open `ios/ZenFlight.xcodeproj` in Xcode.
2. Choose the **ZenFlight** scheme and an iPhone Simulator.
3. Run. Tap to fly; avoid the bamboo and ground.

For a physical iPhone, select your own signing team in **Signing & Capabilities** and use a unique bundle identifier. The public project contains no saved development team or provisioning profile. No API keys, accounts or external services are needed.

## Project map

- `ios/Sources/ZenFlightApp.swift`: SwiftUI entry point and full-screen scene.
- `ios/Sources/GameScene.swift`: sprites, layout, input, score and game screens.
- `ios/Sources/Physics.swift`: fixed-step simulation, tap impulse, gravity, obstacle generation and collision checks.
- `ios/Resources/`: the game's generated artwork, including the plane, bamboo, background and buttons.
- `ios/Tests/EngineChecks.swift`: checks for the simulation.
- `ios/project.yml`: optional XcodeGen project definition. The checked-in Xcode project opens directly without XcodeGen.

## Check the simulation

From this folder, run:

```sh
swiftc ios/Sources/Physics.swift ios/Tests/EngineChecks.swift -o /tmp/zen-flight-engine-checks
/tmp/zen-flight-engine-checks
```

Movement parameters were estimated from recorded reference gameplay. The model approximates the feel; it does not claim to recover the original game's source code, exact collision shapes or obstacle generator. The plane and garden artwork are custom generated assets; original game sprites and reference recordings are not included.

The high score is saved locally using UserDefaults. Review flags `--show-colliders`, `--review-flight` and `--review-results` are optional visual inspection aids.
