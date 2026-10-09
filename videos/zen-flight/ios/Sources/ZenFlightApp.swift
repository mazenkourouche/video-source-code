import SwiftUI
import SpriteKit

@main struct ZenFlightApp: App { var body: some Scene { WindowGroup { ContentView() } } }
struct ContentView: View {
    @StateObject private var game = GameScene()
    @Environment(\.scenePhase) private var phase
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene:game,options:[.allowsTransparency])
                .frame(width:geometry.size.width,height:geometry.size.height)
                .accessibilityLabel("Zen Flight. " + game.status)
                .accessibilityIdentifier("paper-flight")
                .onAppear {
                    game.configureViewport(geometry.size)
                    if ProcessInfo.processInfo.arguments.contains("--show-colliders") { game.showColliders = true }
                }
                .onChange(of:geometry.size) { _, size in game.configureViewport(size) }
        }.ignoresSafeArea().background(Color(red:0.953,green:0.918,blue:0.843))
            .onChange(of:phase) { _, value in game.setActive(value == .active) }
            .alert("Best flight",isPresented:$game.showScores) { Button("Done",role:.cancel) {} } message: { Text("\(game.bestScore) bamboo openings passed") }
            .statusBarHidden()
    }
}
