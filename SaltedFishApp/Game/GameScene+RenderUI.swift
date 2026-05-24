import SpriteKit
import UIKit

// MARK: - Fish, HUD, Overlays Rendering
extension GameScene {

    // MARK: - Fish Drawing
    func drawFish(ctx: CGContext) {
        let screenX = fishX - cameraXOffset
        let screenY = fishY

        // Idle bob
        var visualY = screenY
        if gameStateVal == .playing {
            visualY += sin(gameTime * 3) * 3
        }

        ctx.saveGState()
        ctx.translateBy(x: screenX, y: visualY)
        ctx.rotate(by: fishRotation)
        ctx.scaleBy(x: fishSquishX, y: fishSquishY)

        let fw = GameConfig.fishWidth
        let fh = GameConfig.fishHeight

        // Body glow
        ctx.setShadow(offset: .zero, blur: 12, color: GameConfig.neonGreen.withAlphaComponent(0.5).cgColor)

        // Level-based color
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let bodyColor = level > 1 ? lvConfig.color : GameConfig.neonGreen

        // Body (ellipse)
        ctx.setFillColor(bodyColor.cgColor)
        ctx.fillEllipse(in: CGRect(x: -fw / 2, y: -fh / 2, width: fw, height: fh))

        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Tail
        ctx.setFillColor(bodyColor.withAlphaComponent(0.8).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: -fw / 2, y: 0))
        ctx.addLine(to: CGPoint(x: -fw / 2 - 12, y: -8))
        ctx.addLine(to: CGPoint(x: -fw / 2 - 12, y: 8))
        ctx.closePath()
        ctx.fillPath()

        // Eye
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: fw / 4 - 4, y: -fh / 4 - 3, width: 8, height: 6))
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: fw / 4 - 1, y: -fh / 4 - 1, width: 3, height: 3))

        // Fin
        ctx.setFillColor(bodyColor.withAlphaComponent(0.6).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: 0, y: fh / 2))
        ctx.addLine(to: CGPoint(x: -8, y: fh / 2 + 8))
        ctx.addLine(to: CGPoint(x: 8, y: fh / 2 + 8))
        ctx.closePath()
        ctx.fillPath()

        // Level decorations
        if level >= 2 {
            // Whiskers
            ctx.setStrokeColor(bodyColor.cgColor)
            ctx.setLineWidth(1)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: fw / 2, y: -2))
            ctx.addLine(to: CGPoint(x: fw / 2 + 10, y: -6))
            ctx.move(to: CGPoint(x: fw / 2, y: 2))
            ctx.addLine(to: CGPoint(x: fw / 2 + 10, y: 6))
            ctx.strokePath()
        }

        if level >= 4 {
            // Halo
            ctx.setStrokeColor(UIColor(hex: "#ffcc00").withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(1.5)
            ctx.strokeEllipse(in: CGRect(x: -fw / 2 - 5, y: -fh / 2 - 8, width: fw + 10, height: 6))
        }

        if level >= 6 {
            // Dragon horns
            ctx.setFillColor(UIColor(hex: "#ff0066").cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: fw / 4 - 5, y: -fh / 2))
            ctx.addLine(to: CGPoint(x: fw / 4 - 3, y: -fh / 2 - 10))
            ctx.addLine(to: CGPoint(x: fw / 4 + 1, y: -fh / 2))
            ctx.closePath()
            ctx.move(to: CGPoint(x: fw / 4 + 5, y: -fh / 2))
            ctx.addLine(to: CGPoint(x: fw / 4 + 7, y: -fh / 2 - 10))
            ctx.addLine(to: CGPoint(x: fw / 4 + 11, y: -fh / 2))
            ctx.closePath()
            ctx.fillPath()
        }

        ctx.restoreGState()
    }

    // MARK: - Charge Indicator
    func drawChargeIndicator(ctx: CGContext) {
        guard gameStateVal == .charging else { return }
        let screenX = fishX - cameraXOffset
        let screenY = fishY

        let chargeRatio = chargePower / GameConfig.maxPower
        let radius: CGFloat = 25 + chargeRatio * 10

        // Arc ring
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = startAngle + chargeRatio * 2 * .pi

        // Color gradient from green to red
        let r = chargeRatio
        let g = 1.0 - chargeRatio
        let arcColor = UIColor(red: r, green: g, blue: 0, alpha: 0.7)

        ctx.setStrokeColor(arcColor.cgColor)
        ctx.setLineWidth(3)
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: screenX, y: screenY),
                   radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        ctx.strokePath()

        // Power text
        let pct = Int(chargeRatio * 100)
        let font = UIFont(name: "Courier New", size: 10) ?? UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: arcColor
        ]
        let text = "\(pct)%"
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: screenX - textSize.width / 2,
                                            y: screenY - radius - 16), withAttributes: attrs)
    }

    // MARK: - Trajectory Preview
    func drawTrajectoryPreview(ctx: CGContext) {
        guard gameStateVal == .charging && chargePower > 1 else { return }
        let screenX = fishX - cameraXOffset
        let screenY = fishY

        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let bonusMult = 1.0 + lvConfig.jumpBonus
        let power = chargePower * bonusMult

        let vx = cos(chargeAngle) * power
        let vy = sin(chargeAngle) * power

        let steps = 30
        for i in 0..<steps {
            let t = CGFloat(i) * 0.5
            let px = screenX + vx * t
            let py = screenY + vy * t + 0.5 * GameConfig.gravity * t * t

            let alpha = CGFloat(1.0 - Double(i) / Double(steps))
            let dotSize = 2 + alpha * 2

            // Flowing effect
            let flowOffset = sin(gameTime * 3 + Double(i) * 0.3)
            let finalAlpha = alpha * CGFloat(0.3 + flowOffset * 0.15)

            ctx.setFillColor(GameConfig.neonGreen.withAlphaComponent(finalAlpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: px - dotSize / 2, y: py - dotSize / 2,
                                       width: dotSize, height: dotSize))
        }
    }

    // MARK: - Cancel Zone
    func drawCancelZone(ctx: CGContext) {
        guard gameStateVal == .charging else { return }
        let zoneY = size.height * (1 - GameConfig.cancelZoneRatio)
        let isInZone = pointerY > zoneY

        ctx.setFillColor(UIColor.red.withAlphaComponent(isInZone ? 0.15 : 0.05).cgColor)
        ctx.fill(CGRect(x: 0, y: zoneY, width: size.width, height: size.height - zoneY))

        let font = UIFont(name: "Courier New", size: 11) ?? UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.red.withAlphaComponent(isInZone ? 0.6 : 0.3)
        ]
        let text = "↓ 拖到这里取消跳跃 ↓"
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: (size.width - textSize.width) / 2,
                                            y: zoneY + 8), withAttributes: attrs)
    }

    // MARK: - Fish Quip
    func drawFishQuipVisual(ctx: CGContext) {
        guard !fishQuip.isEmpty else { return }
        let screenX = fishX - cameraXOffset
        let screenY = fishY - 30

        let font = UIFont(name: "Courier New", size: 10) ?? UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let textSize = (fishQuip as NSString).size(withAttributes: attrs)
        let padding: CGFloat = 6

        // Bubble background
        let bubbleRect = CGRect(x: screenX - textSize.width / 2 - padding,
                                y: screenY - textSize.height / 2 - padding,
                                width: textSize.width + padding * 2,
                                height: textSize.height + padding * 2)
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
        let path = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 6)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(GameConfig.neonGreen.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(0.5)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        (fishQuip as NSString).draw(at: CGPoint(x: screenX - textSize.width / 2,
                                                 y: screenY - textSize.height / 2), withAttributes: attrs)
    }

    // MARK: - Particles & Ripples
    func drawParticlesAndRipples(ctx: CGContext) {
        // Ripples
        for ripple in ripples {
            let screenX = ripple.x - cameraXOffset
            ctx.setStrokeColor(GameConfig.neonGreen.withAlphaComponent(ripple.alpha * 0.5).cgColor)
            ctx.setLineWidth(1.5)
            ctx.strokeEllipse(in: CGRect(x: screenX - ripple.r, y: ripple.y - ripple.r * 0.3,
                                         width: ripple.r * 2, height: ripple.r * 0.6))
        }

        // Particles
        for particle in particles {
            let screenX = particle.x - cameraXOffset
            ctx.setFillColor(particle.color.withAlphaComponent(particle.life).cgColor)
            ctx.fillEllipse(in: CGRect(x: screenX - particle.size / 2,
                                       y: particle.y - particle.size / 2,
                                       width: particle.size, height: particle.size))
        }
    }

    // MARK: - Score Popups
    func drawScorePopupsVisual(ctx: CGContext) {
        for popup in scorePopups {
            let alpha = min(1.0, popup.life * 2)
            let font = UIFont(name: "Courier New", size: popup.fontSize) ?? UIFont.monospacedSystemFont(ofSize: popup.fontSize, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: popup.color.withAlphaComponent(alpha),
                .strokeColor: UIColor.black,
                .strokeWidth: -2.5
            ]
            let textSize = (popup.text as NSString).size(withAttributes: attrs)
            (popup.text as NSString).draw(at: CGPoint(x: popup.x - textSize.width / 2,
                                                       y: popup.y), withAttributes: attrs)
        }
    }

    // MARK: - Dragon Gate
    func drawDragonGateVisual(ctx: CGContext) {
        guard let gate = dragonGate else { return }
        let screenX = gate.x - cameraXOffset
        guard screenX > -100 && screenX < size.width + 100 else { return }

        ctx.saveGState()
        ctx.setAlpha(gate.alpha)

        let gateColor = UIColor(hex: "#ffcc00")

        // Pillars
        ctx.setFillColor(gateColor.cgColor)
        ctx.fill(CGRect(x: screenX - gate.w / 2 - 5, y: gate.y - gate.h / 2, width: 10, height: gate.h))
        ctx.fill(CGRect(x: screenX + gate.w / 2 - 5, y: gate.y - gate.h / 2, width: 10, height: gate.h))

        // Cross beam
        ctx.fill(CGRect(x: screenX - gate.w / 2 - 5, y: gate.y - gate.h / 2 - 8,
                         width: gate.w + 10, height: 8))

        // Label
        let font = UIFont(name: "Courier New", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: gateColor
        ]
        let text = "龙门"
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: screenX - textSize.width / 2,
                                             y: gate.y - gate.h / 2 - 24), withAttributes: attrs)

        // Passed glow
        if gate.passed {
            ctx.setShadow(offset: .zero, blur: 30, color: gateColor.withAlphaComponent(0.3).cgColor)
        }

        ctx.restoreGState()
    }

    // MARK: - HUD
    func drawHUD(ctx: CGContext) {
        let safeTop: CGFloat = 50  // Safe area for notch

        // Score
        let scoreFont = UIFont(name: "Courier New", size: 28) ?? UIFont.monospacedSystemFont(ofSize: 28, weight: .bold)
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: GameConfig.neonGreen,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        ctx.setShadow(offset: .zero, blur: 10, color: GameConfig.neonGreen.withAlphaComponent(0.5).cgColor)
        ("\(score)" as NSString).draw(at: CGPoint(x: 16, y: safeTop), withAttributes: scoreAttrs)
        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Level
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let lvFont = UIFont(name: "Courier New", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let lvAttrs: [NSAttributedString.Key: Any] = [
            .font: lvFont,
            .foregroundColor: lvConfig.color
        ]
        (lvConfig.desc as NSString).draw(at: CGPoint(x: 16, y: safeTop + 34), withAttributes: lvAttrs)

        // Combo
        if combo > 1 {
            let comboFont = UIFont(name: "Courier New", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
            let comboAttrs: [NSAttributedString.Key: Any] = [
                .font: comboFont,
                .foregroundColor: GameConfig.goldColor
            ]
            ("COMBO x\(combo)" as NSString).draw(at: CGPoint(x: 16, y: safeTop + 50), withAttributes: comboAttrs)
        }

        // HUD buttons (calculator & mute) - draw outlines
        let hudBtnSize: CGFloat = min(size.width * 0.12, 42)

        // Calculator button
        drawHUDButton(ctx: ctx, x: size.width - hudBtnSize - 16, y: safeTop,
                      w: hudBtnSize, h: hudBtnSize, text: "🧮", color: GameConfig.neonGreen)

        // Mute button
        let muteText = GamePersistence.shared.isMuted ? "🔇" : "🔊"
        let muteColor = GamePersistence.shared.isMuted ? GameConfig.errorRed : GameConfig.neonGreen
        drawHUDButton(ctx: ctx, x: size.width - hudBtnSize * 2 - 24, y: safeTop,
                      w: hudBtnSize, h: hudBtnSize, text: muteText, color: muteColor)
    }

    private func drawHUDButton(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                                text: String, color: UIColor) {
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: 8)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(color.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        let font = UIFont.systemFont(ofSize: 18)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: x + (w - textSize.width) / 2,
                                             y: y + (h - textSize.height) / 2), withAttributes: attrs)
    }

    // MARK: - Start Screen
    func drawStartScreen(ctx: CGContext) {
        // Title
        let titleFont = UIFont(name: "Courier New", size: 36) ?? UIFont.monospacedSystemFont(ofSize: 36, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: GameConfig.neonGreen
        ]
        ctx.setShadow(offset: .zero, blur: 20, color: GameConfig.neonGreen.withAlphaComponent(0.6).cgColor)
        let title = "鱼来运转"
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        (title as NSString).draw(at: CGPoint(x: (size.width - titleSize.width) / 2,
                                              y: size.height * 0.3), withAttributes: titleAttrs)
        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Subtitle
        let subFont = UIFont(name: "Courier New", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: subFont,
            .foregroundColor: GameConfig.neonGreen.withAlphaComponent(0.6)
        ]
        let sub = "FISH FORTUNE"
        let subSize = (sub as NSString).size(withAttributes: subAttrs)
        (sub as NSString).draw(at: CGPoint(x: (size.width - subSize.width) / 2,
                                            y: size.height * 0.3 + 44), withAttributes: subAttrs)

        // Stats
        let statsFont = UIFont(name: "Courier New", size: 11) ?? UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let statsAttrs: [NSAttributedString.Key: Any] = [
            .font: statsFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        let stats = "历史最高: \(GamePersistence.shared.highScore) 分 | 连续签到: \(GamePersistence.shared.streak) 天"
        let statsSize = (stats as NSString).size(withAttributes: statsAttrs)
        (stats as NSString).draw(at: CGPoint(x: (size.width - statsSize.width) / 2,
                                              y: size.height * 0.45), withAttributes: statsAttrs)

        // Tagline
        let tagAttrs: [NSAttributedString.Key: Any] = [
            .font: statsFont,
            .foregroundColor: GameConfig.goldColor.withAlphaComponent(0.6)
        ]
        let tag = "时来运转，一跃成龙"
        let tagSize = (tag as NSString).size(withAttributes: tagAttrs)
        (tag as NSString).draw(at: CGPoint(x: (size.width - tagSize.width) / 2,
                                            y: size.height * 0.5), withAttributes: tagAttrs)

        // Buttons
        let btnW = min(size.width * 0.42, 160)
        let btnH: CGFloat = 44
        let gap: CGFloat = 16
        let startX = (size.width - (btnW * 2 + gap)) / 2
        let startY = size.height * 0.65

        drawButton(ctx: ctx, x: startX, y: startY, w: btnW, h: btnH,
                   text: "开始摸鱼", color: GameConfig.neonGreen)
        drawButton(ctx: ctx, x: startX + btnW + gap, y: startY, w: btnW, h: btnH,
                   text: "排行", color: GameConfig.goldColor)

        // Animated fish icon
        let fishIconY = size.height * 0.18 + sin(gameTime * 2) * 5
        drawMiniFish(ctx: ctx, x: size.width / 2, y: fishIconY, scale: 2.0)
    }

    private func drawMiniFish(ctx: CGContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.scaleBy(x: scale, y: scale)
        ctx.setShadow(offset: .zero, blur: 15, color: GameConfig.neonGreen.withAlphaComponent(0.6).cgColor)
        ctx.setFillColor(GameConfig.neonGreen.cgColor)
        ctx.fillEllipse(in: CGRect(x: -20, y: -14, width: 40, height: 28))
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        // Tail
        ctx.beginPath()
        ctx.move(to: CGPoint(x: -20, y: 0))
        ctx.addLine(to: CGPoint(x: -32, y: -8))
        ctx.addLine(to: CGPoint(x: -32, y: 8))
        ctx.closePath()
        ctx.fillPath()
        // Eye
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: 6, y: -7, width: 8, height: 6))
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: 9, y: -5, width: 3, height: 3))
        ctx.restoreGState()
    }

    // MARK: - Game Over Screen
    func drawGameOverScreen(ctx: CGContext) {
        // Dark overlay
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.92).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let centerX = size.width / 2

        // Death quote
        let quoteFont = UIFont(name: "Courier New", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: GameConfig.errorRed
        ]
        let quoteSize = (currentDeathQuote as NSString).size(withAttributes: quoteAttrs)
        (currentDeathQuote as NSString).draw(at: CGPoint(x: centerX - quoteSize.width / 2,
                                                          y: size.height * 0.2), withAttributes: quoteAttrs)

        // Score
        let scoreFont = UIFont(name: "Courier New", size: 42) ?? UIFont.monospacedSystemFont(ofSize: 42, weight: .bold)
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: GameConfig.neonGreen
        ]
        ctx.setShadow(offset: .zero, blur: 15, color: GameConfig.neonGreen.withAlphaComponent(0.5).cgColor)
        let scoreText = "\(score)"
        let scoreSize = (scoreText as NSString).size(withAttributes: scoreAttrs)
        (scoreText as NSString).draw(at: CGPoint(x: centerX - scoreSize.width / 2,
                                                  y: size.height * 0.3), withAttributes: scoreAttrs)
        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Level desc
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let lvFont = UIFont(name: "Courier New", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let lvAttrs: [NSAttributedString.Key: Any] = [.font: lvFont, .foregroundColor: lvConfig.color]
        let lvSize = (lvConfig.desc as NSString).size(withAttributes: lvAttrs)
        (lvConfig.desc as NSString).draw(at: CGPoint(x: centerX - lvSize.width / 2,
                                                      y: size.height * 0.38), withAttributes: lvAttrs)

        // High score
        let hiFont = UIFont(name: "Courier New", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let hiAttrs: [NSAttributedString.Key: Any] = [
            .font: hiFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        let hiText = "历史最高: \(GamePersistence.shared.highScore) 分"
        let hiSize = (hiText as NSString).size(withAttributes: hiAttrs)
        (hiText as NSString).draw(at: CGPoint(x: centerX - hiSize.width / 2,
                                               y: size.height * 0.42), withAttributes: hiAttrs)

        // Buttons
        let btnW = min(size.width * 0.42, 150)
        let btnH: CGFloat = 38
        let gapX: CGFloat = 14
        let gapY: CGFloat = 12
        let startX = (size.width - (btnW * 2 + gapX)) / 2
        let startY = size.height * 0.62

        drawButton(ctx: ctx, x: startX, y: startY, w: btnW, h: btnH,
                   text: "再翻一次", color: GameConfig.neonGreen)
        drawButton(ctx: ctx, x: startX + btnW + gapX, y: startY, w: btnW, h: btnH,
                   text: "提交成绩", color: GameConfig.goldColor)
        drawButton(ctx: ctx, x: startX, y: startY + btnH + gapY, w: btnW, h: btnH,
                   text: "查看排行", color: UIColor(hex: "#aa66ff"))
        drawButton(ctx: ctx, x: startX + btnW + gapX, y: startY + btnH + gapY, w: btnW, h: btnH,
                   text: "炫耀一下", color: UIColor(hex: "#00aaff"))
    }

    // MARK: - Leaderboard
    func drawLeaderboardScreen(ctx: CGContext) {
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.95).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let titleFont = UIFont(name: "Courier New", size: 18) ?? UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: GameConfig.goldColor
        ]
        let title = "🏆 排行榜"
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        (title as NSString).draw(at: CGPoint(x: (size.width - titleSize.width) / 2,
                                              y: 60), withAttributes: titleAttrs)

        // Close button
        drawButton(ctx: ctx, x: size.width - 52, y: 16, w: 36, h: 36,
                   text: "✕", color: GameConfig.goldColor)

        // Placeholder
        let placeholderFont = UIFont(name: "Courier New", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let phAttrs: [NSAttributedString.Key: Any] = [
            .font: placeholderFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ]
        let ph = "排行榜功能开发中..."
        let phSize = (ph as NSString).size(withAttributes: phAttrs)
        (ph as NSString).draw(at: CGPoint(x: (size.width - phSize.width) / 2,
                                           y: size.height * 0.45), withAttributes: phAttrs)
    }

    // MARK: - Button Helper
    func drawButton(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                    text: String, color: UIColor) {
        let rect = CGRect(x: x, y: y, width: w, height: h)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1.5)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        ctx.setFillColor(color.withAlphaComponent(0.05).cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        let font = UIFont(name: "Courier New", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: x + (w - textSize.width) / 2,
                                             y: y + (h - textSize.height) / 2), withAttributes: attrs)
    }
}
