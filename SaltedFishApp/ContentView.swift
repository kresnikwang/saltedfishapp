import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameManager = GameManager.shared

    var body: some View {
        ZStack {
            // SpriteKit Game View
            SpriteView(scene: gameManager.gameScene, transition: nil,
                       isPaused: false, preferredFramesPerSecond: 60)
                .ignoresSafeArea()

            // Calculator overlay
            if gameManager.showCalculator {
                CalculatorView(isPresented: $gameManager.showCalculator)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: gameManager.showCalculator)
    }
}

class GameManager: ObservableObject {
    static let shared = GameManager()

    @Published var showCalculator = false

    lazy var gameScene: GameScene = {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.gameManager = self
        return scene
    }()

    private init() {}
}
