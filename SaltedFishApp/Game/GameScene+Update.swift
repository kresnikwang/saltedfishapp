import SpriteKit

// MARK: - Game Update Loop
extension GameScene {

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let rawDt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let dt = min(rawDt, 1.0 / 30.0)
        gameTime = currentTime

        // Time scale for slow-motion
        let effectiveDt = dt * Double(timeScale)

        switch gameStateVal {
        case .start:
            updateBubbles(dt: dt)
        case .playing, .charging:
            updateCharging(dt: effectiveDt)
            updateFishIdle(dt: effectiveDt)
            updateDanmaku(dt: dt)
            updateBubbles(dt: dt)
            updateParticles(dt: dt)
            updateRipples(dt: dt)
            updateScorePopups(dt: dt)
            updateCamera(dt: dt)
            updateScreenShake(dt: dt)
            updateDragonGate(dt: dt)
            checkPlatformGeneration()
            updateFishQuip(dt: dt)
        case .jumping:
            updateJumping(dt: effectiveDt)
            updateDanmaku(dt: dt)
            updateBubbles(dt: dt)
            updateParticles(dt: dt)
            updateRipples(dt: dt)
            updateScorePopups(dt: dt)
            updateCamera(dt: dt)
            updateScreenShake(dt: dt)
            updateDragonGate(dt: dt)
            checkPlatformGeneration()
        case .gameover:
            updateBubbles(dt: dt)
            updateParticles(dt: dt)
            updateRipples(dt: dt)
            updateScorePopups(dt: dt)
        case .leaderboard:
            break
        }

        // Render via custom draw
        setNeedsDisplay()
    }

    private func setNeedsDisplay() {
        // Remove old render node and re-draw
        childNode(withName: "renderNode")?.removeFromParent()
        let renderNode = SKNode()
        renderNode.name = "renderNode"
        addChild(renderNode)
        drawGame(in: renderNode)
    }

    // MARK: - Charging Update
    func updateCharging(dt: Double) {
        guard gameStateVal == .charging else { return }
        timeScale = GameConfig.slowMotionScale

        chargePower = min(chargePower + GameConfig.chargeRate * CGFloat(dt) * 60, GameConfig.maxPower)

        // Squish effect
        let chargeRatio = chargePower / GameConfig.maxPower
        fishSquishX = 1.0 - chargeRatio * 0.3
        fishSquishY = 1.0 + chargeRatio * 0.2

        // Angle from drag
        if pointerX > -900 {
            let dx = pointerX - chargeStartX
            let dy = pointerY - chargeStartY
            if abs(dx) > 5 || abs(dy) > 5 {
                chargeAngle = atan2(dy, dx)
                // Clamp to upward angles
                if chargeAngle > 0 { chargeAngle = min(chargeAngle, CGFloat.pi * 0.1) }
                chargeAngle = max(chargeAngle, -CGFloat.pi * 0.85)
            }
        }
    }

    func releaseCharge() {
        guard gameStateVal == .charging else { return }
        AudioManager.shared.stopChargeSound()

        // Cancel zone check (bottom 15%)
        if pointerY > size.height * (1 - GameConfig.cancelZoneRatio) {
            gameStateVal = .playing
            chargePower = 0
            fishSquishX = 1; fishSquishY = 1
            timeScale = 1.0
            return
        }

        // Apply jump bonus from level
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let bonusMult = 1.0 + lvConfig.jumpBonus
        let power = chargePower * bonusMult

        fishVX = cos(chargeAngle) * power
        fishVY = sin(chargeAngle) * power
        fishSquishX = 1; fishSquishY = 1
        chargePower = 0
        timeScale = 1.0

        gameStateVal = .jumping
        AudioManager.shared.playSound(.jump)
        AudioManager.shared.vibrate(.light)
    }

    // MARK: - Jumping Update
    func updateJumping(dt: Double) {
        let dtFactor = CGFloat(dt) * 60.0

        fishVY += GameConfig.gravity * dtFactor
        fishX += fishVX * dtFactor
        fishY += fishVY * dtFactor

        // Rotation based on velocity
        fishRotation = atan2(fishVY, fishVX)

        // Check collision with platforms
        checkPlatformCollision()

        // Check collision with obstacles
        checkObstacleCollision()

        // Check dragon gate
        checkDragonGateCollision()

        // Fall off screen
        if fishY > size.height + 100 {
            triggerGameOver()
        }
    }

    func checkPlatformCollision() {
        let startIdx = max(0, currentPlatformIdx - 5)
        let endIdx = min(platforms.count, currentPlatformIdx + 15)

        for i in startIdx..<endIdx {
            var p = platforms[i]

            // Client platform bobbing
            var platY = p.y
            if p.type == .client {
                platY = p.y + sin(gameTime * 2 + Double(p.bobOffset)) * 20
            }

            // Vanish check
            if p.type == .vanish && p.vanishTimer > 0 && gameTime - p.vanishTimer > 1.0 {
                continue
            }

            // Collision box
            let fishBottom = fishY + GameConfig.fishHeight / 2
            let fishLeft = fishX - GameConfig.fishWidth / 2
            let fishRight = fishX + GameConfig.fishWidth / 2
            let platTop = platY - p.h / 2
            let platLeft = p.x - p.w / 2
            let platRight = p.x + p.w / 2

            if fishVY > 0 &&
               fishBottom >= platTop && fishBottom <= platTop + fishVY + 10 &&
               fishRight > platLeft && fishLeft < platRight {

                // Landed!
                fishY = platTop - GameConfig.fishHeight / 2
                fishVY = 0
                fishVX = 0
                fishRotation = 0
                lastOnPlatformTime = gameTime

                // Landing effects
                let landColor = p.type.color
                spawnLandingParticles(x: fishX, y: platTop, color: landColor)
                spawnRipple(x: fishX, y: platTop)
                applyScreenShake(intensity: 3)
                AudioManager.shared.playSound(.land)
                AudioManager.shared.vibrate(.medium)

                // Wobble animation
                fishWobbleAmp = 0.15
                fishWobbleTime = 0

                // Score calculation
                if i > furthestPlatformIdx {
                    let skipped = i - furthestPlatformIdx
                    combo += 1
                    let comboMult = 1.0 + CGFloat(combo) * GameConfig.comboMultiplierStep
                    var basePoints = CGFloat(GameConfig.baseScore * skipped)

                    // Perfect landing
                    let centerDist = abs(fishX - p.x) / (p.w / 2)
                    var isPerfect = centerDist < GameConfig.perfectLandingZone
                    if isPerfect {
                        basePoints *= GameConfig.perfectMultiplier
                        AudioManager.shared.playSound(.perfect)
                        AudioManager.shared.vibrate(.success)
                        spawnLandingParticles(x: fishX, y: platTop, color: GameConfig.perfectGold, count: 20)
                        showScorePopup(x: fishX - cameraXOffset, y: platTop - 30, text: "PERFECT!", color: GameConfig.perfectGold)
                    }

                    // Platform type bonus
                    var platMult: CGFloat = 1.0
                    if p.type == .tea { platMult = 1.5 }

                    // Streak bonus
                    let streakMult = 1.0 + GamePersistence.shared.streakBonus

                    let totalScore = Int(basePoints * comboMult * platMult * streakMult)
                    score += totalScore

                    if combo > 1 {
                        AudioManager.shared.playSound(.combo)
                        showScorePopup(x: fishX - cameraXOffset, y: platTop - 50, text: "COMBO x\(combo)", color: GameConfig.goldColor)
                    }

                    showScorePopup(x: fishX - cameraXOffset, y: platTop - 15, text: "+\(totalScore)", color: landColor)

                    // Boss penalty
                    if p.type == .boss {
                        score = max(0, score - 200)
                        AudioManager.shared.playSound(.hit)
                        AudioManager.shared.vibrate(.heavy)
                        showScorePopup(x: fishX - cameraXOffset, y: platTop - 15, text: "-200", color: GameConfig.errorRed)
                    }

                    furthestPlatformIdx = i
                    updateLevel()
                } else {
                    combo = 0
                }

                currentPlatformIdx = i

                // Special platform effects
                handlePlatformEffect(index: i, platY: platY)

                gameStateVal = .playing

                // Input buffer
                if inputBufferTime > 0 && gameTime - inputBufferTime < GameConfig.inputBufferWindow {
                    isCharging = true
                    chargePower = 0
                    chargeStartX = bufferedPointerX
                    chargeStartY = bufferedPointerY
                    gameStateVal = .charging
                    AudioManager.shared.startChargeSound()
                    inputBufferTime = 0
                }

                return
            }
        }
    }

    func handlePlatformEffect(index: Int, platY: CGFloat) {
        let p = platforms[index]

        switch p.type {
        case .spring:
            // Auto-launch to next platform
            if index + 1 < platforms.count {
                let next = platforms[index + 1]
                let dx = next.x - fishX
                let dy = next.y - fishY
                let angle: CGFloat = -CGFloat.pi * 0.3125  // -56.25 degrees
                let t = dx / (cos(angle) * GameConfig.maxPower * 0.8)
                fishVX = dx / max(t, 1)
                fishVY = (dy - 0.5 * GameConfig.gravity * t * t) / max(t, 1)
                gameStateVal = .jumping
                AudioManager.shared.playSound(.jump)
                AudioManager.shared.vibrate(.heavy)
                platforms[index].launchTimer = gameTime
            }
        case .vanish:
            platforms[index].vanishTimer = gameTime
        case .slide:
            // Handled in idle update
            break
        default:
            break
        }
    }

    func checkObstacleCollision() {
        let fishLeft = fishX - GameConfig.fishWidth / 2
        let fishRight = fishX + GameConfig.fishWidth / 2
        let fishTop = fishY - GameConfig.fishHeight / 2
        let fishBottom = fishY + GameConfig.fishHeight / 2

        for obs in obstacles {
            let obsBounds: CGRect
            switch obs.type {
            case .seaweed:
                obsBounds = CGRect(x: obs.x - 8, y: obs.y - 20, width: 16, height: 40)
            case .crab:
                obsBounds = CGRect(x: obs.x - 12, y: obs.y - 8, width: 24, height: 16)
            case .doc:
                let docX = obs.startX + sin(gameTime * 1.5 + Double(obs.bobOffset)) * 30
                obsBounds = CGRect(x: docX - 10, y: obs.y - 14, width: 20, height: 28)
            case .boss:
                obsBounds = CGRect(x: obs.x - 15, y: obs.y - 15, width: 30, height: 30)
            }

            if fishRight > obsBounds.minX && fishLeft < obsBounds.maxX &&
               fishBottom > obsBounds.minY && fishTop < obsBounds.maxY {
                // Hit obstacle
                AudioManager.shared.playSound(.hit)
                AudioManager.shared.vibrate(.heavy)
                applyScreenShake(intensity: 8)
                spawnLandingParticles(x: fishX, y: fishY, color: .red, count: 8)

                score = max(0, score - 50)
                showScorePopup(x: fishX - cameraXOffset, y: fishY - 20, text: "-50", color: GameConfig.errorRed)

                // Deflect fish slightly
                fishVY = min(fishVY, -2)
                break
            }
        }
    }

    func checkDragonGateCollision() {
        guard var gate = dragonGate, !gate.passed else { return }
        if fishX > gate.x - gate.w / 2 && fishX < gate.x + gate.w / 2 {
            dragonGate?.passed = true
            spawnLandingParticles(x: gate.x, y: gate.y, color: GameConfig.perfectGold, count: 30)
            applyScreenShake(intensity: 10)
            AudioManager.shared.playSound(.perfect)
            AudioManager.shared.vibrate(.success)
            showLevelUpPopup(text: "鱼跃龙门！", color: GameConfig.perfectGold)
        }
    }

    // MARK: - Fish Idle
    func updateFishIdle(dt: Double) {
        guard gameStateVal == .playing else { return }
        let dtFactor = CGFloat(dt) * 60.0

        // Idle bob
        let bob = sin(gameTime * 3) * 3
        // Apply only visual offset, not to fishY directly

        // Wobble decay
        if fishWobbleAmp > 0.001 {
            fishWobbleTime += CGFloat(dt) * 10
            fishWobbleAmp *= 0.92
            fishSquishX = 1.0 + sin(fishWobbleTime) * fishWobbleAmp
            fishSquishY = 1.0 - sin(fishWobbleTime) * fishWobbleAmp * 0.8
        } else {
            fishSquishX = 1; fishSquishY = 1
        }

        // Slide platform push
        if currentPlatformIdx < platforms.count {
            let p = platforms[currentPlatformIdx]
            if p.type == .slide {
                fishX -= 0.5 * dtFactor
                // Check if pushed off
                let platLeft = p.x - p.w / 2
                if fishX < platLeft - GameConfig.fishWidth / 2 {
                    fishVY = 1
                    gameStateVal = .jumping
                }
            }
        }
    }

    // MARK: - Camera
    func updateCamera(dt: Double) {
        let baseOffset = size.width * GameConfig.cameraBaseOffset
        var lookAhead: CGFloat = 0
        if gameStateVal == .charging {
            lookAhead = cos(chargeAngle) * size.width * 0.25
        }
        targetCameraX = fishX - baseOffset + lookAhead
        cameraXOffset += (targetCameraX - cameraXOffset) * GameConfig.cameraLerpFactor
    }

    // MARK: - Screen Shake
    func updateScreenShake(dt: Double) {
        if screenShakeIntensity > 0.1 {
            screenShakeX = CGFloat.random(in: -screenShakeIntensity...screenShakeIntensity)
            screenShakeY = CGFloat.random(in: -screenShakeIntensity...screenShakeIntensity)
            screenShakeIntensity *= 0.85
        } else {
            screenShakeX = 0; screenShakeY = 0; screenShakeIntensity = 0
        }
    }

    // MARK: - Effects Updates
    func updateParticles(dt: Double) {
        for i in (0..<particles.count).reversed() {
            particles[i].x += particles[i].vx
            particles[i].y += particles[i].vy
            particles[i].vy += 0.1 // gravity
            particles[i].life -= CGFloat(dt) * 2
            if particles[i].life <= 0 { particles.remove(at: i) }
        }
    }

    func updateRipples(dt: Double) {
        for i in (0..<ripples.count).reversed() {
            ripples[i].r += CGFloat(dt) * 60
            ripples[i].alpha -= CGFloat(dt) * 1.5
            if ripples[i].alpha <= 0 { ripples.remove(at: i) }
        }
    }

    func updateBubbles(dt: Double) {
        for i in 0..<bubbles.count {
            bubbles[i].y -= bubbles[i].speed * CGFloat(dt) * 60
            bubbles[i].x += sin(gameTime * 2 + Double(bubbles[i].offset)) * 0.3
            if bubbles[i].y < -10 {
                bubbles[i].y = size.height + 10
                bubbles[i].x = CGFloat.random(in: 0...2000)
            }
        }
    }

    func updateDanmaku(dt: Double) {
        danmakuSpawnTimer += dt
        if danmakuSpawnTimer > 3.0 {
            danmakuSpawnTimer = 0
            let text = GameTexts.danmakuTexts.randomElement() ?? ""
            let lane = Int.random(in: 0..<5)
            let y = 60 + CGFloat(lane) * 28
            activeDanmaku.append(DanmakuItem(
                x: size.width + 10, y: y,
                text: text, speed: 1.0 + CGFloat.random(in: 0...0.5),
                lane: lane
            ))
        }

        for i in (0..<activeDanmaku.count).reversed() {
            activeDanmaku[i].x -= activeDanmaku[i].speed * CGFloat(dt) * 60
            if activeDanmaku[i].x < -200 { activeDanmaku.remove(at: i) }
        }
    }

    func updateScorePopups(dt: Double) {
        for i in (0..<scorePopups.count).reversed() {
            scorePopups[i].y -= CGFloat(dt) * 30
            scorePopups[i].life -= CGFloat(dt)
            if scorePopups[i].life <= 0 { scorePopups.remove(at: i) }
        }
    }

    func updateDragonGate(dt: Double) {
        guard var gate = dragonGate else { return }
        if gate.alpha < 1 {
            dragonGate?.alpha = min(1, gate.alpha + CGFloat(dt))
        }
    }

    func updateFishQuip(dt: Double) {
        if fishQuipTimer > 0 {
            fishQuipTimer -= dt
            if fishQuipTimer <= 0 { fishQuip = "" }
        } else if CGFloat.random(in: 0...1) < 0.002 {
            fishQuip = GameTexts.fishQuips.randomElement() ?? ""
            fishQuipTimer = 2.5
        }
    }

    func checkPlatformGeneration() {
        if currentPlatformIdx > platforms.count - 20 {
            generateMorePlatforms(count: 20)
        }
    }
}
