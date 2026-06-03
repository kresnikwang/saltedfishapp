import SpriteKit
import UIKit

// MARK: - Game State
enum GameState {
    case start, playing, charging, jumping, gameover, leaderboard
}

class GameScene: SKScene {

    // MARK: - Properties
    weak var gameManager: GameManager?

    var gameStateVal: GameState = .start
    var score: Int = 0
    var combo: Int = 0
    var level: Int = 1
    var cameraXOffset: CGFloat = 0
    var targetCameraX: CGFloat = 0
    var screenShakeIntensity: CGFloat = 0
    var screenShakeX: CGFloat = 0
    var screenShakeY: CGFloat = 0
    var gameTime: TimeInterval = 0
    var timeScale: CGFloat = 1.0
    var lastOnPlatformTime: TimeInterval = 0
    var inputBufferTime: TimeInterval = 0
    var bufferedPointerX: CGFloat = -999
    var bufferedPointerY: CGFloat = -999
    var safeTopInset: CGFloat = 50
    var safeBottomInset: CGFloat = 20

    // Fish state
    var fishX: CGFloat = 0
    var fishY: CGFloat = 0
    var fishVX: CGFloat = 0
    var fishVY: CGFloat = 0
    var fishRotation: CGFloat = 0
    var fishSquishX: CGFloat = 1
    var fishSquishY: CGFloat = 1
    var fishWobbleAmp: CGFloat = 0
    var fishWobbleTime: CGFloat = 0

    // Charge state
    var chargePower: CGFloat = 0
    var chargeProgress: CGFloat = 0
    var chargeAngle: CGFloat = -.pi / 4
    var chargeStartX: CGFloat = 0
    var chargeStartY: CGFloat = 0
    var isCharging = false
    var chargeReadyFeedbackPlayed = false

    // Fish quip
    var fishQuip = ""
    var fishQuipTimer: TimeInterval = 0

    // Platforms
    var platforms: [PlatformData] = []
    var currentPlatformIdx = 0
    var furthestPlatformIdx = 0
    var lastPlatformX: CGFloat = 0
    var lastPlatformY: CGFloat = 0
    var generatedPlatformCount = 0

    // Effects
    var particles: [Particle] = []
    var ripples: [Ripple] = []
    var obstacles: [ObstacleData] = []
    var bubbles: [Bubble] = []
    var activeDanmaku: [DanmakuItem] = []
    var danmakuSpawnTimer: TimeInterval = 0
    var scorePopups: [ScorePopup] = []

    // Dragon gate
    var dragonGate: DragonGate? = nil

    // Death
    var currentDeathQuote = ""

    // Pointer tracking
    var pointerX: CGFloat = -999
    var pointerY: CGFloat = -999
    var isTouching = false
    var tutorialStep: Int = -1
    var tutorialTimer: TimeInterval = 0
    var buttonFeedbackX: CGFloat = -999
    var buttonFeedbackY: CGFloat = -999
    var buttonFeedbackLife: CGFloat = 0

    // Last update time
    var lastUpdateTime: TimeInterval = 0

    // MARK: - Persistent Render Sprite (reused every frame to avoid GPU texture churn)
    var renderSprite: SKSpriteNode?
    var lastRenderedSize: CGSize = .zero
    
    // Fonts reused during custom drawing to reduce per-frame allocations.
    let mono7 = UIFont.monospacedSystemFont(ofSize: 7, weight: .bold)
    let mono10 = UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)
    let mono12 = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
    let mono13 = UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
    let mono14 = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
    let mono15 = UIFont.monospacedSystemFont(ofSize: 15, weight: .bold)
    let mono16 = UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
    let mono18 = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
    let mono22 = UIFont.monospacedSystemFont(ofSize: 22, weight: .heavy)
    let mono32 = UIFont.monospacedSystemFont(ofSize: 32, weight: .heavy)
    let mono44 = UIFont.monospacedSystemFont(ofSize: 44, weight: .heavy)
    let mono48 = UIFont.monospacedSystemFont(ofSize: 48, weight: .heavy)
    let mono56 = UIFont.monospacedSystemFont(ofSize: 56, weight: .heavy)
    let iconFont = UIFont.systemFont(ofSize: 18, weight: .semibold)

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = GameConfig.bgDark
        safeTopInset = max(44, view.safeAreaInsets.top + 16)
        safeBottomInset = max(20, view.safeAreaInsets.bottom + 12)
        view.ignoresSiblingOrder = true
        view.allowsTransparency = false
        GamePersistence.shared.checkDaily()
        initBubbles()
        gameTime = 0
        lastOnPlatformTime = 0

        // Authenticate Game Center player silently on startup
        GameCenterManager.shared.authenticateLocalPlayer()

        // Pre-create the render sprite so it lives for the lifetime of the scene
        let sprite = SKSpriteNode()
        sprite.name = "renderSprite"
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sprite.zPosition = 0
        addChild(sprite)
        renderSprite = sprite

        // Hint SpriteKit to run at 60fps cap (30fps on simulator is enough but let's keep it smooth)
        view.preferredFramesPerSecond = 60
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        if let view = view {
            safeTopInset = max(44, view.safeAreaInsets.top + 16)
            safeBottomInset = max(20, view.safeAreaInsets.bottom + 12)
        }
        renderSprite?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        initBubbles()
    }

    // MARK: - Platform Generation
    func generateMorePlatforms(count: Int) {
        for _ in 0..<count {
            let index = generatedPlatformCount
            let diff = min(1.0, CGFloat(index) / 100.0)
            let earlyEase = min(1.0, CGFloat(max(index - 3, 0)) / 14.0)
            let earlyWidthBonus = max(0, 10 - CGFloat(index)) * 2.0
            var w = (50 - diff * 20) + CGFloat.random(in: 0...(40 - diff * 10)) + earlyWidthBonus
            var type: PlatformType = .normal

            let meetingProb = (0.10 + diff * 0.18) * earlyEase
            let clientProb = (0.06 + diff * 0.12) * earlyEase
            if index > 3 && CGFloat.random(in: 0...1) < meetingProb { type = .meeting }
            if index > 5 && CGFloat.random(in: 0...1) < clientProb { type = .client }
            if index > 4 && CGFloat.random(in: 0...1) < 0.06 * earlyEase { type = .tea }
            if index > 10 && CGFloat.random(in: 0...1) < 0.08 { type = .spring }
            if index > 14 && CGFloat.random(in: 0...1) < 0.07 { type = .vanish }
            if index > 16 && CGFloat.random(in: 0...1) < 0.06 { type = .slide }
            if index > 20 && CGFloat.random(in: 0...1) < 0.05 { type = .boss }
            if index == 0 { type = .normal }
            if type == .meeting { w = (40 - diff * 15) + CGFloat.random(in: 0...20) }
            if index < 12, let previousType = platforms.last?.type, previousType != .normal, type != .normal {
                type = .normal
            }

            platforms.append(PlatformData(
                x: lastPlatformX, y: lastPlatformY,
                w: w, type: type,
                bobOffset: CGFloat.random(in: 0...(CGFloat.pi * 2))
            ))

            // Add obstacles
            let obstacleChance = (0.18 + diff * 0.45) * max(0.35, earlyEase)
            if index > 8 && CGFloat.random(in: 0...1) < obstacleChance {
                let ox = lastPlatformX - 20 + CGFloat.random(in: 0...40)
                var oy = lastPlatformY - 40 - CGFloat.random(in: 0...60)
                let r = CGFloat.random(in: 0...1)
                var otype: ObstacleType = .seaweed
                if r > 0.4 { otype = .crab }
                if r > 0.7 && index > 20 { otype = .doc }
                if r > 0.85 && index > 40 { otype = .boss; oy -= 60 }
                obstacles.append(ObstacleData(x: ox, y: oy, type: otype, bobOffset: CGFloat.random(in: 0...(CGFloat.pi * 2)), startX: ox))
            }

            let trainingGaps: [CGFloat] = [82, 96, 112, 128, 104, 142]
            let gapAdd = diff * 80
            if index < trainingGaps.count {
                lastPlatformX += trainingGaps[index]
            } else {
                lastPlatformX += GameConfig.platformMinGap + gapAdd + CGFloat.random(in: 0...(GameConfig.platformMaxGap - GameConfig.platformMinGap + gapAdd))
            }
            let heightVar: CGFloat = index < 8 ? 48 : 80 + diff * 60
            lastPlatformY += (CGFloat.random(in: 0...1) - (index < 8 ? 0.50 : 0.55)) * heightVar
            lastPlatformY = max(size.height * 0.25, min(size.height * 0.85, lastPlatformY))

            generatedPlatformCount += 1
        }
    }

    // MARK: - Bubbles
    func initBubbles() {
        bubbles = []
        for _ in 0..<GameConfig.maxBubbles {
            bubbles.append(Bubble(
                x: cameraXOffset + CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                r: 2 + CGFloat.random(in: 0...4),
                speed: 0.3 + CGFloat.random(in: 0...0.5),
                offset: CGFloat.random(in: 0...(CGFloat.pi * 2))
            ))
        }
    }

    // MARK: - Game Start
    func startGame() {
        score = 0; combo = 0; level = 1
        currentPlatformIdx = 0; furthestPlatformIdx = 0
        particles = []; ripples = []; obstacles = []
        chargePower = 0; chargeProgress = 0; isCharging = false
        chargeReadyFeedbackPlayed = false
        scorePopups = []
        dragonGate = nil
        currentDeathQuote = ""
        tutorialStep = GamePersistence.shared.hasSeenTutorial ? -1 : 0
        tutorialTimer = 0
        buttonFeedbackLife = 0

        platforms = []
        lastPlatformX = size.width * 0.3
        lastPlatformY = size.height * 0.65
        generatedPlatformCount = 0
        generateMorePlatforms(count: 25)

        let p0 = platforms[0]
        fishX = p0.x; fishY = p0.y - GameConfig.platformHeight / 2 - GameConfig.fishHeight / 2
        fishVX = 0; fishVY = 0; fishRotation = 0
        fishSquishX = 1; fishSquishY = 1
        fishWobbleAmp = 0; fishWobbleTime = 0
        cameraXOffset = fishX - size.width * GameConfig.cameraBaseOffset
        targetCameraX = cameraXOffset

        gameStateVal = .playing
        gameTime = 0
        lastUpdateTime = 0  // Reset so first frame dt is clean
        lastOnPlatformTime = 0
        inputBufferTime = 0
        timeScale = 1.0

        activeDanmaku = []
        danmakuSpawnTimer = 0

        showLevelUpPopup(text: Localized.string(zh: "按住屏幕蓄力 · 拖动瞄准 · 松手跳跃", en: "Hold · Aim · Release", ja: "画面長押しでチャージ ・ ドラッグで照準 ・ 指を離してジャンプ"), color: GameConfig.neonGreen)
    }
    
    func advanceTutorial(to step: Int) {
        guard tutorialStep >= 0, step > tutorialStep else { return }
        tutorialStep = step
        tutorialTimer = 0
    }
    
    func finishTutorial() {
        guard tutorialStep >= 0 else { return }
        tutorialStep = -1
        GamePersistence.shared.hasSeenTutorial = true
    }

    func triggerGameOver() {
        gameStateVal = .gameover
        AudioManager.shared.stopChargeSound()
        AudioManager.shared.playSound(.gameover)
        AudioManager.shared.vibrate(.error)
        currentDeathQuote = GameTexts.deathQuotes.randomElement() ?? ""

        // Submit local score
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        GamePersistence.shared.submitLocalScore(score, playerTitle: lvConfig.desc)
        
        // Submit Game Center score
        GameCenterManager.shared.submitScore(score)

        if score > GamePersistence.shared.highScore {
            GamePersistence.shared.highScore = score
            GamePersistence.shared.checkDaily()
        }
    }

    // MARK: - Level Management
    func updateLevel() {
        var newLevel = 1
        for (i, lv) in gameLevels.enumerated() {
            if score >= lv.threshold { newLevel = i + 1 }
        }
        if newLevel > level {
            level = newLevel
            let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
            showLevelUpPopup(text: Localized.string(zh: "进化！\(lvConfig.desc)", en: "Level Up! \(lvConfig.name)", ja: "進化！\(lvConfig.desc)"), color: lvConfig.color)
            AudioManager.shared.playSound(.perfect)
            AudioManager.shared.vibrate(.success)

            // Dragon gate at max level
            if level == gameLevels.count && dragonGate == nil {
                spawnDragonGate()
            }
        }
    }

    func spawnDragonGate() {
        let gateX = fishX + size.width * 1.5
        let gateY = size.height * 0.5
        dragonGate = DragonGate(
            x: gateX, y: gateY,
            w: 60, h: 120,
            alpha: 0, spawnTime: gameTime,
            passed: false, particles: []
        )
    }

    // MARK: - Score Popup
    func showLevelUpPopup(text: String, color: UIColor) {
        scorePopups.append(ScorePopup(
            x: size.width / 2, y: size.height * 0.35,
            text: text, color: color, life: 1.0, fontSize: 18
        ))
    }

    func showScorePopup(x: CGFloat, y: CGFloat, text: String, color: UIColor) {
        scorePopups.append(ScorePopup(
            x: x, y: y,
            text: text, color: color, life: 1.0, fontSize: 16
        ))
    }

    // MARK: - Particle Effects
    func spawnLandingParticles(x: CGFloat, y: CGFloat, color: UIColor, count: Int = 12) {
        let maxParticles = 50
        // Trim oldest particles if near cap
        if particles.count + count > maxParticles {
            let excess = (particles.count + count) - maxParticles
            if excess < particles.count {
                particles.removeFirst(excess)
            } else {
                particles.removeAll()
            }
        }
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let speed = CGFloat.random(in: 1...4)
            particles.append(Particle(
                x: x, y: y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - 2,
                color: color, life: 1.0,
                size: CGFloat.random(in: 2...5)
            ))
        }
    }

    func spawnRipple(x: CGFloat, y: CGFloat) {
        ripples.append(Ripple(x: x, y: y, r: 0, maxR: 40, alpha: 0.6))
    }

    // MARK: - Screen Shake
    func applyScreenShake(intensity: CGFloat) {
        screenShakeIntensity = intensity
    }
}
