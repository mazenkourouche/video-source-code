import SpriteKit
import Combine
import UIKit

final class GameScene: SKScene, ObservableObject {
    @Published var status = "Tap to fly"
    @Published var showScores = false
    var bestScore: Int { best }
    var simulation = BirdSimulation()
    private let collisionsEnabled = true
    private var lastTime: TimeInterval = 0, accumulator = 0.0, tutorialTime = 0.0
    private var textures: [String: SKTexture] = [:]
    private var best = UserDefaults.standard.integer(forKey: "PaperFlightBest")
    private let viewportCamera = SKCameraNode()
    private var extraSky = 0.0
    private var floorShift = 0.0
    private let numberFont = UIFont(name:"ChalkboardSE-Regular",size:16)?.fontName ?? "MarkerFelt-Thin"
    private var skyTexture: SKTexture?
    private var newBest = false
    var showColliders = false
    private let sx = 565.0 / 288, sy = 1006.0 / 512
    override init() {
        super.init(size: CGSize(width: 565, height: 1006)); scaleMode = .resizeFill
        backgroundColor = UIColor(red:0.953,green:0.918,blue:0.843,alpha:1)
        for name in ["background","bamboo","plane","pebbles","earth","score","text_ready","text_game_over","score_panel","button_play","button_score","new","medals_0","tutorial_hand","tutorial_tap","tutorial_arrow"] {
            let t = SKTexture(imageNamed:name); t.filteringMode = .linear; textures[name] = t
        }
        skyTexture = SKTexture(rect:CGRect(x:0,y:0.9,width:1,height:0.1),in:textures["background"]!)
        if ProcessInfo.processInfo.arguments.contains("--review-flight") { simulation.flap() }
        if ProcessInfo.processInfo.arguments.contains("--review-results") { simulation.phase = .dead; simulation.score = 3; best = 3; newBest = true }
        paint()
    }
    required init?(coder:NSCoder) { fatalError("No storyboard") }
    func configureViewport(_ viewport:CGSize) {
        guard viewport.width > 0, viewport.height > 0 else { return }
        size = viewport
        // Keep the measured world width and uniform sprite scale; reveal scenery vertically.
        let scale = 565 / viewport.width
        viewportCamera.setScale(scale)
        viewportCamera.position = CGPoint(x:282.5,y:503)
        extraSky = max(0,(viewport.height * scale - 1006) / 2)
        // Use some of the extra height for flight space rather than a deep earth band.
        floorShift = min(64,extraSky * 0.55)
        simulation.config.ground = (788 + floorShift) / sy
        paint()
    }
    func reset() { simulation = BirdSimulation(config:simulation.config); newBest = false; lastTime = 0; accumulator = 0; tutorialTime = 0; paint() }
    func setActive(_ active:Bool) { isPaused = !active; lastTime = 0; accumulator = 0 }
    override func touchesBegan(_ touches:Set<UITouch>, with event:UIEvent?) {
        guard let touch = touches.first else { return }
        if simulation.phase == .dead {
            if nodes(at:touch.location(in:self)).contains(where: { $0.name == "play" }) { reset() }
            if nodes(at:touch.location(in:self)).contains(where: { $0.name == "scores" }) { showScores = true }
            return
        }
        simulation.flap(); paint()
    }
    override func update(_ time:TimeInterval) {
        if lastTime == 0 { lastTime = time }
        let dt = min(max(time-lastTime,0),0.1); lastTime = time; tutorialTime += dt; accumulator += dt
        while accumulator >= 1 / simulation.config.hz {
            if ProcessInfo.processInfo.arguments.contains("--review-flight") && simulation.y > 285 && simulation.velocity > 0 { simulation.flap() }
            simulation.step(collisions:collisionsEnabled)
            if !collisionsEnabled { simulation.y = min(max(simulation.y,12),simulation.config.ground-12) }
            accumulator -= 1 / simulation.config.hz
        }
        if !ProcessInfo.processInfo.arguments.contains("--review-results") && simulation.phase == .dead && simulation.score > best { best = simulation.score; newBest = true; UserDefaults.standard.set(best,forKey:"PaperFlightBest") }
        paint()
    }
    @discardableResult private func sprite(_ name:String,_ x:Double,_ y:Double,_ w:Double,_ h:Double,parent:SKNode? = nil,fit:Bool = false) -> SKSpriteNode {
        let n = SKSpriteNode(texture:textures[name]); var width = w, height = h
        if fit, let texture = textures[name] { let native = texture.size(), k = min(w/native.width,h/native.height); width = native.width*k; height = native.height*k }
        n.size = CGSize(width:width,height:height); n.position = CGPoint(x:x+w/2,y:1006-y-h/2); (parent ?? self).addChild(n); return n
    }
    private func label(_ text:String,_ x:Double,_ y:Double,_ font:Double,_ alignment:SKLabelHorizontalAlignmentMode = .center) {
        let l = SKLabelNode(fontNamed:numberFont); l.text = text; l.fontSize = font; l.fontColor = UIColor(red:0.20,green:0.18,blue:0.15,alpha:1); l.horizontalAlignmentMode = alignment; l.verticalAlignmentMode = .center; l.position = CGPoint(x:x,y:1006-y); addChild(l)
    }
    private func outline(_ x:Double,_ y:Double,_ w:Double,_ h:Double) {
        let n = SKShapeNode(rect:CGRect(x:x,y:1006-y-h,width:w,height:h)); n.strokeColor = .systemPink; n.lineWidth = 2; n.fillColor = .clear; addChild(n)
    }
    private func player(_ x:Double,_ y:Double,_ angle:Double) {
        // Uniform fit of the full-resolution master inside the original bird envelope.
        let n = sprite("plane",x-32.8888889*sx/2,y-24*sx/2,32.8888889*sx,24*sx); n.zRotation = -angle * .pi / 180
        if showColliders {
            let c = SKShapeNode(circleOfRadius:simulation.config.radius*sx); c.position = CGPoint(x:x,y:1006-y); c.strokeColor = .systemPink; c.lineWidth = 2; c.fillColor = .clear; addChild(c)
        }
    }
    func paint() {
        removeAllChildren(); let s = simulation, cfg = s.config
        addChild(viewportCamera); camera = viewportCamera
        let groundY = cfg.ground * sy
        sprite("background",0,floorShift,565,1006)
        if extraSky + floorShift > 0 {
            let sky = SKSpriteNode(texture:skyTexture)
            sky.size = CGSize(width:565,height:extraSky+floorShift+2)
            sky.position = CGPoint(x:282.5,y:1006+(extraSky-floorShift)/2-1)
            addChild(sky)
        }
        let crop = SKCropNode(); let mask = SKSpriteNode(color:.white,size:CGSize(width:565,height:groundY+extraSky)); mask.position = CGPoint(x:282.5,y:1006-groundY/2+extraSky/2); crop.maskNode = mask; addChild(crop)
        for p in s.pipes {
            let x = p.x*sx, w = cfg.pipeWidth*sx, upper = (p.centre-cfg.gap/2)*sy, lower = (p.centre+cfg.gap/2)*sy
            let t = textures["bamboo"]!.size(), h = w*t.height/t.width
            let top = sprite("bamboo",x,upper-h,w,h,parent:crop); top.yScale = -1
            sprite("bamboo",x,lower,w,h,parent:crop)
            if showColliders { outline(x,0,w,upper); outline(x,lower,w,groundY-lower) }
        }
        let angle = s.rotationDegrees
        player(cfg.birdX*sx,s.y*sy,angle)
        sprite("earth",0,groundY,565,565)
        let floorCrop = SKCropNode(); let fm = SKSpriteNode(color:.white,size:CGSize(width:565,height:236-floorShift)); fm.position = CGPoint(x:282.5,y:(236-floorShift)/2); floorCrop.maskNode = fm; addChild(floorCrop)
        let peb = textures["pebbles"]!.size(), pebW = 41*peb.width/peb.height
        sprite("pebbles",(565-pebW)/2,groundY-18,pebW,41,parent:floorCrop)
        if s.phase != .dead {
            sprite("score",261,162,47,70); label(String(s.score),284.5,197,43)
        }
        if s.phase == .ready {
            sprite("text_ready",90,286,385,122,fit:true)
            player(283,454-sin(tutorialTime*2 * .pi/1.6)*4,-8)
            sprite("tutorial_arrow",267,506,31,65,fit:true)
            let phase = tutorialTime.truncatingRemainder(dividingBy:1.6), press = max(0,1-abs(phase-0.35)/0.18)
            let hand = sprite("tutorial_hand",267,577,40,48,fit:true); hand.setScale(1-press*0.08)
            for x in [171.0,315.0] { let tap = sprite("tutorial_tap",x,566,80,31,fit:true); tap.alpha = 0.7+press*0.3 }
        }
        if s.phase == .dead {
            sprite("text_game_over",83,255,400,106,fit:true)
            let p = sprite("score_panel",49,379,467,247,fit:true)
            let x = p.position.x-p.size.width/2, y = 1006-p.position.y-p.size.height/2, kx = p.size.width/238, ky = p.size.height/126
            // Centre measured from the circular placeholder in the score-panel master.
            let medalCentreX = 63.3333333, medalCentreY = 75.3333333
            sprite("medals_0",x+(medalCentreX-22)*kx,y+(medalCentreY-22)*ky,44*kx,44*ky,fit:true)
            label(String(s.score),x+210*kx,y+44*ky,16*ky,.right); label(String(best),x+210*kx,y+100*ky,16*ky,.right)
            if newBest { sprite("new",x+130*kx,y+35*ky,32*kx,14*ky,fit:true) }
            sprite("button_play",39,668+floorShift,228,137,fit:true).name = "play"
            sprite("button_score",298,668+floorShift,228,137,fit:true).name = "scores"
        }
        if showColliders { outline(0,groundY,565,1) }
        let next = s.phase == .dead ? "Score \(s.score). Tap play to restart." : s.phase == .ready ? "Tap to fly" : "Score \(s.score)"
        if status != next { status = next }
    }
}
