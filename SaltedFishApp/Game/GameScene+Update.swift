import SpriteKit

// MARK: - Game Update Loop
extension GameScene {

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let rawDt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let dt = min(rawDt, 1.0 / 30.0)

        // Time scale for slow-motion
        let effectiveDt = dt * Double(timeScale)
        gameTime += effectiveDt

        switch gameStateVal {
        case .start:
            updateBubbles(dt: dt)
        case .playing, .charging:
            updateCharging(dt: dt) // Pass raw dt to maintain 1.2s charge speed!
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
        renderFrame()
    }

    private func renderFrame() {
        guard let sprite = renderSprite else { return }
        // Use scale 1.0 for perf — looks crisp enough on simulator/device at 1x
        // Change to 2.0 for Retina quality at moderate cost, or UIScreen.main.scale for max
        let renderScale: CGFloat = 1.0
        let renderSize = size

        UIGraphicsBeginImageContextWithOptions(renderSize, true, renderScale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }

        drawGame(ctx: ctx)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let image = image, let cgImage = image.cgImage {
            // SKTexture(cgImage:) reuses existing GPU memory allocation when size matches
            sprite.texture = SKTexture(cgImage: cgImage)
            sprite.size = renderSize
        }
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
            isCharging = false
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
        isCharging = false
        timeScale = 1.0

        gameStateVal = .jumping
        AudioManager.shared.playSound(.jump)
        AudioManager.shared.vibrate(.light)

        // Directional kickback screen shake (Task 5)
        let kickbackScale: CGFloat = min(power * 0.4, 10.0)
        screenShakeX = -cos(chargeAngle) * kickbackScale
        screenShakeY = -sin(chargeAngle) * kickbackScale

        // Set launch stretch wobble
        fishWobbleAmp = (power / (GameConfig.maxPower * bonusMult)) * 0.45
        fishWobbleTime = CGFloat.pi / 2
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
        let endIdx = min(platforms.count, currentPlatformIdx + 40)

        for i in startIdx..<endIdx {
            let p = platforms[i]

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

                if p.type == .spring {
                    handleSpringLanding(index: i, platTop: platTop)
                    return
                }

                // Landed!
                let preImpactVy = fishVY
                fishY = platTop - GameConfig.fishHeight / 2
                fishVY = 0
                fishVX = 0
                fishRotation = 0
                lastOnPlatformTime = gameTime

                let landColor = p.type.color
                let isPerfect = p.type != .boss && abs(fishX - p.x) < p.w * GameConfig.perfectLandingZone
                
                let landingShake = min(max(isPerfect ? 8.0 : 5.0, preImpactVy * 0.6), 15.0)
                screenShakeY = landingShake
                screenShakeX = CGFloat.random(in: -0.5...0.5) * (landingShake * 0.3)
                
                spawnLandingParticles(x: fishX, y: platTop, color: isPerfect ? GameConfig.perfectGold : landColor, count: isPerfect ? 24 : 12)
                spawnRipple(x: fishX, y: platTop)
                AudioManager.shared.vibrate(isPerfect ? .success : .medium)

                // Wobble animation
                fishWobbleAmp = 0.25
                fishWobbleTime = CGFloat.pi / 2

                // Score calculation
                if i > furthestPlatformIdx {
                    let skipped = i - furthestPlatformIdx
                    if isPerfect {
                        combo += skipped + 1
                    } else {
                        combo += skipped
                    }

                    if p.type == .boss {
                        // Boss platform: ONLY deduct, matching WeChat behaviour
                        score = max(0, score - 200)
                        AudioManager.shared.playSound(.hit)
                        AudioManager.shared.vibrate(.heavy)
                        showScorePopup(x: fishX - cameraXOffset, y: platTop - 15, text: "-200", color: GameConfig.errorRed)
                    } else {
                        let comboMult = 1.0 + CGFloat(combo) * GameConfig.comboMultiplierStep
                        var basePoints = CGFloat(GameConfig.baseScore * skipped)

                        // Perfect landing
                        if isPerfect {
                            basePoints *= GameConfig.perfectMultiplier
                            showScorePopup(x: fishX - cameraXOffset, y: platTop - 38, text: "PERFECT!", color: GameConfig.perfectGold)
                        }

                        // Platform type bonus
                        var platMult: CGFloat = 1.0
                        if p.type == .tea { platMult = 1.5 }

                        // Streak bonus
                        let streakMult = 1.0 + GamePersistence.shared.streakBonus

                        let totalScore = Int(basePoints * comboMult * platMult * streakMult)
                        score += totalScore

                        if combo > 1 {
                            AudioManager.shared.playSound(isPerfect ? .perfect : .combo)
                            showScorePopup(x: fishX - cameraXOffset, y: platTop - 55, text: "COMBO x\(combo)", color: GameConfig.goldColor)
                        } else if isPerfect {
                            AudioManager.shared.playSound(.perfect)
                        } else {
                            AudioManager.shared.playSound(.land)
                        }

                        showScorePopup(x: fishX - cameraXOffset, y: platTop - 15, text: "+\(totalScore)", color: landColor)
                    }

                    furthestPlatformIdx = i
                    updateLevel()
                } else {
                    // Backward / same platform: just land sound, reset combo
                    AudioManager.shared.playSound(p.type == .boss ? .hit : .land)
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

    func handleSpringLanding(index: Int, platTop: CGFloat) {
        let p = platforms[index]
        platforms[index].launchTimer = gameTime
        
        let isForward = index > furthestPlatformIdx
        let isPerfect = abs(fishX - p.x) < p.w * GameConfig.perfectLandingZone
        
        // Combo update
        let skipped = index - furthestPlatformIdx
        if isForward {
            if isPerfect {
                combo += skipped + 1
            } else {
                combo += skipped
            }
            
            // Score calculation
            let comboMult = 1.0 + CGFloat(combo) * GameConfig.comboMultiplierStep
            let streakMult = 1.0 + GamePersistence.shared.streakBonus
            var basePoints = CGFloat(GameConfig.baseScore * skipped)
            if isPerfect {
                basePoints *= GameConfig.perfectMultiplier
            }
            let totalScore = Int(basePoints * comboMult * streakMult)
            score += totalScore
            
            furthestPlatformIdx = index
            updateLevel()
            
            // Popups
            if isPerfect {
                showScorePopup(x: fishX - cameraXOffset, y: platTop - 15, text: "+\(totalScore)", color: GameConfig.perfectGold)
                showScorePopup(x: fishX - cameraXOffset, y: platTop - 30, text: "PERFECT!", color: GameConfig.perfectGold)
                AudioManager.shared.playSound(.perfect)
                AudioManager.shared.vibrate(.success)
            } else {
                showScorePopup(x: fishX - cameraXOffset, y: platTop - 15, text: "+\(totalScore)", color: p.type.color)
                if combo > 1 {
                    showScorePopup(x: fishX - cameraXOffset, y: platTop - 35, text: "COMBO x\(combo)", color: GameConfig.goldColor)
                }
                AudioManager.shared.playSound(.land)
                AudioManager.shared.vibrate(.medium)
            }
        } else {
            combo = 0
            AudioManager.shared.playSound(.land)
        }
        
        currentPlatformIdx = index
        
        // Auto-launch velocity calculation
        let launchAngle: CGFloat = -CGFloat.pi / 3.2
        let tanA = tan(launchAngle)
        
        if index + 1 < platforms.count {
            let nextP = platforms[index + 1]
            var nextPlatY = nextP.y
            if nextP.type == .client {
                nextPlatY = nextP.y + sin(gameTime * 2.0 + Double(nextP.bobOffset)) * 20.0
            }
            let targetX = nextP.x
            let targetY = nextPlatY - GameConfig.platformHeight / 2 - GameConfig.fishHeight / 2
            
            let dx = targetX - fishX
            let dy = targetY - fishY
            
            if dx > 10 {
                let denom = dy - dx * tanA
                if denom > 0 {
                    var vx = dx * sqrt((0.5 * GameConfig.gravity) / denom)
                    var vy = vx * tanA
                    
                    let speed = sqrt(vx * vx + vy * vy)
                    if speed > 25 {
                        let scale = 25 / speed
                        vx *= scale
                        vy *= scale
                    }
                    fishVX = vx
                    fishVY = vy
                } else {
                    let power: CGFloat = 13.5
                    fishVX = cos(launchAngle) * power
                    fishVY = sin(launchAngle) * power
                }
            } else {
                let power: CGFloat = 13.5
                fishVX = cos(launchAngle) * power
                fishVY = sin(launchAngle) * power
            }
        } else {
            let power: CGFloat = 13.5
            fishVX = cos(launchAngle) * power
            fishVY = sin(launchAngle) * power
        }
        
        gameStateVal = .jumping
        
        // Play jump sound
        AudioManager.shared.playSound(.jump)
        
        // Wobble & Screen Shake
        fishWobbleAmp = 0.4
        fishWobbleTime = CGFloat.pi / 2
        
        let shakeY = isPerfect ? CGFloat(9) : CGFloat(6)
        screenShakeY = shakeY
        screenShakeX = CGFloat.random(in: -0.5...0.5) * shakeY * 0.3
        
        // Particles and Ripple
        let landColor = isPerfect ? GameConfig.perfectGold : p.type.color
        spawnLandingParticles(x: fishX, y: platTop, color: landColor, count: isPerfect ? 24 : 12)
        spawnRipple(x: fishX, y: platTop)
    }

    func handlePlatformEffect(index: Int, platY: CGFloat) {
        let p = platforms[index]

        switch p.type {
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
        let fw = GameConfig.fishWidth
        
        for index in 0..<obstacles.count {
            let obs = obstacles[index]
            // Skip hit/destroyed obstacles
            guard obs.y > -9000 else { continue }
            
            let bobY = sin(gameTime * 3.0 + Double(obs.bobOffset)) * 6.0
            var ox = obs.x
            if obs.type == .doc {
                ox = obs.startX + sin(gameTime * 1.5 + Double(obs.bobOffset)) * 30.0
            }
            let oy = obs.y + bobY
            
            var hit = false
            if obs.type == .boss {
                // Boss scan beam moving horizontally (gameTime * 1.5 matches gameTime * 0.0015 in WeChat)
                let scanX = ox + sin(gameTime * 1.5 + Double(obs.bobOffset)) * 30.0
                let scannerWidth: CGFloat = 20.0
                if abs(fishX - scanX) < (scannerWidth / 2.0 + fw / 2.0) && fishY > oy {
                    hit = true
                }
            } else {
                // Circle-based collision (radius 22)
                let dx = fishX - ox
                let dy = fishY - oy
                let dist = sqrt(dx * dx + dy * dy)
                if dist < 22.0 {
                    hit = true
                }
            }
            
            if hit {
                // Rebound physics matching WeChat
                fishVY += 3.0
                fishVX *= 0.5
                if obs.type == .boss {
                    fishVX = -1.0
                    fishVY += 2.0
                }
                
                AudioManager.shared.playSound(.hit)
                AudioManager.shared.vibrate(.heavy)
                
                screenShakeX = CGFloat.random(in: -7.5...7.5)
                screenShakeY = CGFloat.random(in: -7.5...7.5)
                
                spawnLandingParticles(x: fishX, y: fishY, color: GameConfig.errorRed, count: 8)
                
                // Mark obstacle as hit/destroyed
                obstacles[index].y = -9999.0
                break
            }
        }
    }

    func checkDragonGateCollision() {
        guard let gate = dragonGate, !gate.passed else { return }
        if fishX > gate.x - gate.w / 2 && fishX < gate.x + gate.w / 2 {
            dragonGate?.passed = true
            spawnLandingParticles(x: gate.x, y: gate.y, color: GameConfig.perfectGold, count: 30)
            screenShakeX = CGFloat.random(in: -6...6)
            screenShakeY = -8
            AudioManager.shared.playSound(.perfect)
            AudioManager.shared.vibrate(.success)
            showLevelUpPopup(text: Localized.string(zh: "鱼跃龙门！", en: "Leaped the Dragon Gate!"), color: GameConfig.perfectGold)
        }
    }

    // MARK: - Fish Idle & Platform Sync
    func updateFishIdle(dt: Double) {
        guard gameStateVal == .playing || gameStateVal == .charging else { return }
        let dtFactor = CGFloat(dt) * 60.0

        // Wobble decay (frame-rate independent)
        if fishWobbleAmp > 0.001 {
            fishWobbleTime += dtFactor * 0.5
            fishWobbleAmp *= pow(0.88, dtFactor)
            let wobbleVal = sin(fishWobbleTime) * fishWobbleAmp
            fishSquishX = 1.0 + wobbleVal
            fishSquishY = 1.0 - wobbleVal * 0.8
        } else {
            fishSquishX = 1; fishSquishY = 1
            fishWobbleAmp = 0
        }

        // Sync fish position to platform (with slide, vanish, coyote time, and bobbing support)
        if currentPlatformIdx < platforms.count {
            let cp = platforms[currentPlatformIdx]

            // Check vanishing platform timer
            if cp.type == .vanish && cp.vanishTimer > 0 {
                let elapsed = gameTime - cp.vanishTimer
                if elapsed > 1.0 {
                    // Vanished!
                    gameStateVal = .jumping
                    fishVY = 1.0 // start falling
                    fishVX = 0
                    if isCharging {
                        isCharging = false
                        AudioManager.shared.stopChargeSound()
                        chargePower = 0
                    }
                    return
                }
            }

            // Slide platform push
            if cp.type == .slide {
                fishX -= 0.8 * dtFactor
            }

            let platLeft = cp.x - cp.w / 2
            let platRight = cp.x + cp.w / 2

            // Check if slipped off the platform
            if fishX < platLeft || fishX > platRight {
                let coyoteTime: TimeInterval = 0.150 // 150ms
                if gameTime - lastOnPlatformTime > coyoteTime {
                    gameStateVal = .jumping
                    fishVY = 1.0 // start falling
                    fishVX = cp.type == .slide ? -0.8 : 0
                    if isCharging {
                        isCharging = false
                        AudioManager.shared.stopChargeSound()
                        chargePower = 0
                    }
                } else {
                    // Within coyote time: visual fall
                    let coyoteElapsed = gameTime - lastOnPlatformTime
                    let fallDist = CGFloat(coyoteElapsed / coyoteTime) * 15.0
                    var bobY: CGFloat = 0
                    if cp.type == .client {
                        bobY = sin(gameTime * 2.0 + Double(cp.bobOffset)) * 20.0
                    }
                    let platTop = cp.y + bobY - GameConfig.platformHeight / 2
                    fishY = platTop - GameConfig.fishHeight / 2 + fallDist
                }
            } else {
                lastOnPlatformTime = gameTime
                // Snap Y position, adjusting for client bob
                var bobY: CGFloat = 0
                if cp.type == .client {
                    bobY = sin(gameTime * 2.0 + Double(cp.bobOffset)) * 20.0
                }
                let platTop = cp.y + bobY - GameConfig.platformHeight / 2
                fishY = platTop - GameConfig.fishHeight / 2
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
        cameraXOffset += (targetCameraX - cameraXOffset) * GameConfig.cameraLerpFactor * timeScale
    }

    // MARK: - Screen Shake
    func updateScreenShake(dt: Double) {
        let dtFactor = CGFloat(dt) * 60.0
        if abs(screenShakeX) > 0.1 {
            screenShakeX *= pow(0.88, dtFactor)
        } else {
            screenShakeX = 0
        }
        if abs(screenShakeY) > 0.1 {
            screenShakeY *= pow(0.88, dtFactor)
        } else {
            screenShakeY = 0
        }
    }

    // MARK: - Effects Updates
    func updateParticles(dt: Double) {
        let dtFactor = CGFloat(dt) * 60.0
        for i in (0..<particles.count).reversed() {
            particles[i].x += particles[i].vx * dtFactor
            particles[i].y += particles[i].vy * dtFactor
            particles[i].vy += 0.1 * dtFactor // gravity
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
                // Keep bubbles visible relative to camera (world X follows camera)
                bubbles[i].x = cameraXOffset + CGFloat.random(in: 0...size.width)
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
        guard let gate = dragonGate else { return }
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
