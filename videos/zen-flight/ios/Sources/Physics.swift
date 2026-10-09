import Foundation

enum GamePhase: String { case ready, playing, dead }
struct PhysicsConfig: Codable, Equatable {
    // Convert locally measured capture values into the 288×512 simulation canvas.
    var gravity = 2110.0 * 512 / 1006, flap = 625.0 * 512 / 1006
    var terminal = 960.0 * 512 / 1006, speed = 235.302 * 288 / 565
    var gap = 188.5 * 512 / 1006, spacing = 308.5 * 288 / 565, pipeWidth = 102.0 * 288 / 565
    var radius = 10.0, birdX = 176.0 * 288 / 565, ground = 788.0 * 512 / 1006
    var centreMin = 259.5 * 512 / 1006, centreMax = 609.5 * 512 / 1006, maxStep = 324.0 * 512 / 1006
    var hz = 120.0, seed: UInt32 = 13013
}
struct Pipe { var x: Double; var centre: Double; var scored = false }
struct BirdSimulation {
    var config: PhysicsConfig
    var tick = 0, score = 0, lastFlapTick = 0
    var y = 509.0 * 512 / 1006, velocity = 0.0, nextX = 456.0
    var phase = GamePhase.ready
    var rng: UInt32
    var pipes: [Pipe] = []
    private var previousCentre: Double?
    init(config: PhysicsConfig = PhysicsConfig()) { self.config = config; rng = config.seed }
    var rotationDegrees: Double { phase == .ready ? 0 : min(90, -20 + 330 * max(0, Double(tick-lastFlapTick)/config.hz - 0.525)) }
    mutating func random() -> Double { rng = 1664525 &* rng &+ 1013904223; return Double(rng) / 4294967296.0 }
    mutating func flap() { guard phase != .dead else { return }; phase = .playing; velocity = -config.flap; lastFlapTick = tick }
    mutating func step(collisions: Bool = true) {
        guard phase == .playing else { return }; let c = config, dt = 1 / c.hz
        let accelerating = max(0, min(dt, (c.terminal - velocity) / c.gravity))
        y += velocity * accelerating + 0.5 * c.gravity * accelerating * accelerating + c.terminal * (dt - accelerating)
        velocity = min(c.terminal, velocity + c.gravity * dt); tick += 1
        while nextX < 358 {
            let lo = max(c.centreMin, (previousCentre ?? c.centreMin) - c.maxStep)
            let hi = min(c.centreMax, (previousCentre ?? c.centreMax) + c.maxStep)
            let centre = lo + random() * (hi - lo); previousCentre = centre
            pipes.append(Pipe(x: nextX, centre: centre)); nextX += c.spacing
        }
        nextX -= c.speed * dt
        for i in pipes.indices {
            pipes[i].x -= c.speed * dt
            if !pipes[i].scored && pipes[i].x + c.pipeWidth < c.birdX { pipes[i].scored = true; score += 1 }
            let nearestX = max(pipes[i].x, min(c.birdX, pipes[i].x + c.pipeWidth))
            for (top, bottom) in [(0.0, pipes[i].centre - c.gap / 2), (pipes[i].centre + c.gap / 2, c.ground)] {
                let nearestY = max(top, min(y, bottom))
                if collisions && pow(c.birdX - nearestX, 2) + pow(y - nearestY, 2) <= pow(c.radius, 2) { phase = .dead }
            }
        }
        pipes.removeAll { $0.x + c.pipeWidth <= 0 }
        if collisions && (y - c.radius <= 0 || y + c.radius >= c.ground) { phase = .dead }
    }
}
