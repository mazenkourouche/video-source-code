import Foundation
@main struct EngineChecks {
    static func main() {
        func near(_ a:Double,_ b:Double) { precondition(abs(a-b)<1e-7,"Numerical mismatch: \(a) vs \(b)") }
        let cfg = PhysicsConfig(); var a = BirdSimulation(); let start = a.y
        a.flap(); for _ in 0..<24 { a.step(collisions:false) }; near(a.y,start-cfg.flap*0.2+0.5*cfg.gravity*0.04)
        a.velocity = 120; a.flap(); near(a.velocity,-cfg.flap)
        a.velocity = cfg.terminal; a.step(collisions:false); near(a.velocity,cfg.terminal)
        var b = BirdSimulation(); b.flap(); var c = b
        for i in 0..<1000 { if i%45 == 0 { b.flap(); c.flap() }; b.step(collisions:false); c.step(collisions:false) }
        near(b.y,c.y); precondition(b.pipes.map(\.centre)==c.pipes.map(\.centre))
        precondition(b.pipes.allSatisfy { cfg.centreMin <= $0.centre && $0.centre <= cfg.centreMax })
        a = BirdSimulation(); a.phase = .playing; a.pipes = [Pipe(x:cfg.birdX,centre:220)]; a.y = 220; a.step(); precondition(a.phase == .playing)
        a.y = 100; a.step(); precondition(a.phase == .dead)
        a = BirdSimulation(); a.phase = .playing; a.y = cfg.ground-5; a.step(); precondition(a.phase == .dead)
        a = BirdSimulation(); a.phase = .playing; a.pipes = [Pipe(x:cfg.birdX-cfg.pipeWidth-1,centre:220)]; a.y = 220; a.step(); precondition(a.score == 1); a.step(); precondition(a.score == 1)
        a = BirdSimulation(); a.flap(); near(a.rotationDegrees,-20); for _ in 0..<72 { a.step(collisions:false) }; near(a.rotationDegrees,4.75); a.flap(); near(a.rotationDegrees,-20)
        print("Passed: analytic jump, reset tap, terminal cap, deterministic generation, gap survival, pipe/ground collision and single scoring.")
    }
}
