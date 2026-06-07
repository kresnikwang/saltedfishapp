import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameManager = GameManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // SpriteKit Game View
            SpriteView(scene: gameManager.gameScene, transition: nil,
                       isPaused: gameManager.isScenePaused, preferredFramesPerSecond: 60)
                .ignoresSafeArea()

            // Calculator overlay
            if gameManager.showCalculator {
                CalculatorView(isPresented: $gameManager.showCalculator)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: gameManager.showCalculator)
        .onChange(of: scenePhase) { phase in
            gameManager.setScenePaused(phase != .active)
        }
    }
}

class GameManager: ObservableObject {
    static let shared = GameManager()

    @Published var showCalculator = false
    @Published var isScenePaused = false

    lazy var gameScene: GameScene = {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.gameManager = self
        return scene
    }()

    private init() {}

    func setScenePaused(_ paused: Bool) {
        guard isScenePaused != paused else { return }
        isScenePaused = paused
        gameScene.isPaused = paused

        if paused {
            gameScene.prepareForAppPause()
            AudioManager.shared.suspend()
        } else {
            gameScene.resumeAfterAppPause()
            AudioManager.shared.resume()
        }
    }
}
