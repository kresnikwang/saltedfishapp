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

        // Level-based color
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let bodyColor = level > 1 ? lvConfig.color : GameConfig.neonGreen

        // Cheap fake glow: draw larger semi-transparent ellipse under body
        // (replaces costly setShadow/blur — visually very similar at 1x render scale)
        let glowAlpha: CGFloat = level >= 4 ? 0.22 : 0.14
        let glowPad: CGFloat = level >= 6 ? 14 : level >= 4 ? 10 : 6
        ctx.setFillColor(bodyColor.withAlphaComponent(glowAlpha).cgColor)
        ctx.fillEllipse(in: CGRect(x: -fw / 2 - glowPad, y: -fh / 2 - glowPad,
                                   width: fw + glowPad * 2, height: fh + glowPad * 2))
        ctx.setFillColor(bodyColor.withAlphaComponent(glowAlpha * 0.5).cgColor)
        ctx.fillEllipse(in: CGRect(x: -fw / 2 - glowPad * 2, y: -fh / 2 - glowPad * 2,
                                   width: fw + glowPad * 4, height: fh + glowPad * 4))

        // 1. Dorsal Fin (on the back/top, points UPWARDS)
        ctx.setFillColor(bodyColor.withAlphaComponent(0.7).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: -fw / 6, y: -fh / 2))
        ctx.addLine(to: CGPoint(x: -fw / 3, y: -fh / 2 - 7))
        ctx.addLine(to: CGPoint(x: fw / 6, y: -fh / 2))
        ctx.closePath()
        ctx.fillPath()

        // 2. Pelvic Fin (on the belly/bottom, smaller, points DOWNWARDS)
        ctx.setFillColor(bodyColor.withAlphaComponent(0.5).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: -fw / 8, y: fh / 2))
        ctx.addLine(to: CGPoint(x: -fw / 4, y: fh / 2 + 5))
        ctx.addLine(to: CGPoint(x: fw / 8, y: fh / 2))
        ctx.closePath()
        ctx.fillPath()

        // 3. Body (ellipse)
        ctx.setFillColor(bodyColor.cgColor)
        ctx.fillEllipse(in: CGRect(x: -fw / 2, y: -fh / 2, width: fw, height: fh))

        // 4. Highlight (3D glossy effect, upper half)
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        ctx.fillEllipse(in: CGRect(x: -fw / 2.5, y: -fh / 3 - 3, width: fw * 0.8, height: fh * 2.0 / 3.0))

        // 5. Tail (dynamic swimming animation)
        let t = CGFloat(gameTime)
        ctx.setFillColor(bodyColor.cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: -fw / 2, y: 0))
        ctx.addLine(to: CGPoint(x: -fw / 2 - 12, y: -10 + sin(t * 3) * 3))
        ctx.addLine(to: CGPoint(x: -fw / 2 - 12, y: 10 + sin(t * 3 + 1) * 3))
        ctx.closePath()
        ctx.fillPath()

        // 6. Eye (always on the top-right facing forward)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: fw / 4 - 4, y: -fh / 4 - 3, width: 8, height: 6))
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fillEllipse(in: CGRect(x: fw / 4 - 1, y: -fh / 4 - 1, width: 3, height: 3))

        // 7. Progression Visuals (matching WeChat level milestones)
        if level >= 2 {
            // Whiskers
            ctx.setStrokeColor(bodyColor.cgColor)
            ctx.setLineWidth(level >= 3 ? 1.5 : 1)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: fw / 3, y: 2))
            ctx.addLine(to: CGPoint(x: fw / 2 + 6, y: 6))
            ctx.move(to: CGPoint(x: fw / 3, y: -2))
            ctx.addLine(to: CGPoint(x: fw / 2 + 6, y: -8))
            ctx.strokePath()
        }

        if level >= 4 {
            // Halo Ring
            ctx.setStrokeColor(bodyColor.withAlphaComponent(0.25).cgColor)
            ctx.setLineWidth(level >= 5 ? 4 : 2.5)
            ctx.strokeEllipse(in: CGRect(x: -fw / 2 - 6, y: -fh / 2 - 6, width: fw + 12, height: fh + 12))
        }

        if level >= 5 {
            // Second Outer Ring
            ctx.setStrokeColor(bodyColor.withAlphaComponent(0.13).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: -fw / 2 - 13, y: -fh / 2 - 13, width: fw + 26, height: fh + 26))
            
            // Orbital particles rotating
            ctx.setFillColor(bodyColor.withAlphaComponent(0.4).cgColor)
            for s in 0..<6 {
                let sa = t * 5.0 + CGFloat(s) * CGFloat.pi / 3.0
                let px = cos(sa) * (fw / 2 + 10)
                let py = sin(sa) * (fh / 2 + 10)
                ctx.fillEllipse(in: CGRect(x: px - 1.5, y: py - 1.5, width: 3, height: 3))
            }
        }

        if level >= 6 {
            // Dragon Horns
            ctx.setFillColor(UIColor(hex: "#ff0066").cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: fw / 4 - 4, y: -fh / 2))
            ctx.addLine(to: CGPoint(x: fw / 4 - 8, y: -fh / 2 - 14))
            ctx.addLine(to: CGPoint(x: fw / 4, y: -fh / 2))
            ctx.closePath()
            ctx.move(to: CGPoint(x: fw / 4 + 6, y: -fh / 2))
            ctx.addLine(to: CGPoint(x: fw / 4 + 2, y: -fh / 2 - 12))
            ctx.addLine(to: CGPoint(x: fw / 4 + 10, y: -fh / 2))
            ctx.closePath()
            ctx.fillPath()
        }

        if level >= 7 {
            // Tail trail rings
            ctx.setStrokeColor(UIColor(hex: "#ff0066").withAlphaComponent(0.25).cgColor)
            ctx.setLineWidth(2)
            for i in 1...5 {
                let waveY = sin(t * 4.0 + CGFloat(i)) * 5.0
                ctx.strokeEllipse(in: CGRect(x: -fw / 2 - CGFloat(i) * 8 - 4, y: waveY - 4, width: 8, height: 8))
            }
        }

        ctx.restoreGState()
    }

    // MARK: - Charge Indicator
    func drawChargeIndicator(ctx: CGContext) {
        guard gameStateVal == .charging else { return }
        let screenX = fishX - cameraXOffset
        let screenY = fishY

        let chargeRatio = chargePower / GameConfig.maxPower
        let radius = GameConfig.fishWidth / 2 + 12

        // Background ring (subtle, semi-transparent)
        ctx.setStrokeColor(UIColor(red: 0, green: 1, blue: 136.0/255, alpha: 0.15).cgColor)
        ctx.setLineWidth(4)
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: screenX, y: screenY),
                   radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        ctx.strokePath()

        // Active ring segment (from green to yellow to red via HSL)
        let hueDegrees = 130 - chargeRatio * 130
        let arcColor = UIColor(hue: hueDegrees / 360.0, saturation: 1.0, brightness: 1.0, alpha: 0.7)

        ctx.setStrokeColor(arcColor.cgColor)
        ctx.setLineWidth(4)
        ctx.setLineCap(.round)
        ctx.beginPath()
        ctx.addArc(center: CGPoint(x: screenX, y: screenY),
                   radius: radius, startAngle: -.pi / 2, endAngle: -.pi / 2 + chargeRatio * 2 * .pi, clockwise: false)
        ctx.strokePath()
        ctx.setLineCap(.butt) // reset
        
        if chargeRatio >= GameConfig.chargeReadyThreshold {
            let pulse = CGFloat(0.5 + sin(gameTime * 10) * 0.5)
            ctx.setStrokeColor(GameConfig.goldColor.withAlphaComponent(0.35 + 0.25 * pulse).cgColor)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: CGRect(x: screenX - radius - 6, y: screenY - radius - 6,
                                          width: (radius + 6) * 2, height: (radius + 6) * 2))
        }

        // Power text
        let pct = Int(chargeRatio * 100)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono12,
            .foregroundColor: arcColor,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.5
        ]
        let text = "\(pct)%"
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: screenX - textSize.width / 2,
                                            y: screenY - radius - 16), withAttributes: attrs)
        
        if chargeRatio >= GameConfig.chargeReadyThreshold {
            let readyText = Localized.string(zh: "高能", en: "READY", ja: "準備OK")
            let readySize = (readyText as NSString).size(withAttributes: attrs)
            (readyText as NSString).draw(at: CGPoint(x: screenX - readySize.width / 2,
                                                     y: screenY + radius + 4), withAttributes: attrs)
        }
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

        let chargeRatio = chargePower / GameConfig.maxPower
        let maxDots = min(GameConfig.maxTrajectoryDots, 10 + Int(chargeRatio * 18))
        let flowOffset = (gameTime * 0.05).truncatingRemainder(dividingBy: 1.0)
        
        let hueDegrees = 130 - chargeRatio * 130

        for i in 0..<maxDots {
            let t = (CGFloat(i) + CGFloat(flowOffset)) * 2.8
            let px = screenX + vx * t
            let py = screenY + vy * t + 0.5 * GameConfig.gravity * t * t

            let ratio = CGFloat(i) / CGFloat(maxDots)
            let dotSize = max(1.0, 3.2 * (1.0 - ratio)) * 2.0 // size matches WeChat's taper
            let opacity = 0.85 * (1.0 - ratio)

            let dotColor = UIColor(hue: hueDegrees / 360.0, saturation: 1.0, brightness: 1.0, alpha: opacity)
            ctx.setFillColor(dotColor.cgColor)
            ctx.fillEllipse(in: CGRect(x: px - dotSize / 2, y: py - dotSize / 2,
                                       width: dotSize, height: dotSize))
        }
    }

    // MARK: - Cancel Zone
    func drawCancelZone(ctx: CGContext) {
        guard gameStateVal == .charging else { return }
        let zoneY = size.height * (1 - GameConfig.cancelZoneRatio)
        let isInZone = pointerY > zoneY

        ctx.setFillColor(UIColor.red.withAlphaComponent(isInZone ? 0.22 : 0.05).cgColor)
        ctx.fill(CGRect(x: 0, y: zoneY, width: size.width, height: size.height - zoneY))

        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono14,
            .foregroundColor: UIColor.red.withAlphaComponent(isInZone ? 0.95 : 0.65),
            .strokeColor: UIColor.black,
            .strokeWidth: -2.5
        ]
        let text = isInZone
            ? Localized.string(zh: "松手取消跳跃", en: "Release to cancel", ja: "離してキャンセル")
            : Localized.string(zh: "↓ 拖到这里取消跳跃 ↓", en: "↓ Drag here to cancel jump ↓", ja: "↓ ここにドラッグしてキャンセル ↓")
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: (size.width - textSize.width) / 2,
                                             y: zoneY + 8), withAttributes: attrs)
    }

    // MARK: - Fish Quip
    func drawFishQuipVisual(ctx: CGContext) {
        guard !fishQuip.isEmpty else { return }
        let screenX = fishX - cameraXOffset
        let screenY = fishY - 30
        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono13,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.5
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
            let font = popup.fontSize >= 18 ? mono18 : mono16
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: popup.color.withAlphaComponent(alpha),
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0
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
        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono15,
            .foregroundColor: gateColor,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.5
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
        let safeTop = safeTopInset

        // Score
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: mono32,
            .foregroundColor: GameConfig.neonGreen,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        ("\(score)" as NSString).draw(at: CGPoint(x: 16, y: safeTop), withAttributes: scoreAttrs)

        // Level
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let lvAttrs: [NSAttributedString.Key: Any] = [
            .font: mono15,
            .foregroundColor: lvConfig.color,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.5
        ]
        (lvConfig.desc as NSString).draw(at: CGPoint(x: 16, y: safeTop + 38), withAttributes: lvAttrs)

        // Combo
        if combo > 1 {
            let comboAttrs: [NSAttributedString.Key: Any] = [
                .font: mono18,
                .foregroundColor: GameConfig.goldColor,
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0
            ]
            ("COMBO x\(combo)" as NSString).draw(at: CGPoint(x: 16, y: safeTop + 58), withAttributes: comboAttrs)
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
        ctx.setFillColor(GameConfig.panelFill.withAlphaComponent(0.72).cgColor)
        let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: 8)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        ctx.setFillColor(color.withAlphaComponent(0.10).cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        ctx.setStrokeColor(color.withAlphaComponent(0.75).cgColor)
        ctx.setLineWidth(1.5)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        if text == "🧮" {
            drawCalculatorIcon(ctx: ctx, rect: CGRect(x: x, y: y, width: w, height: h), color: color)
        } else if text == "🔇" || text == "🔊" {
            drawSpeakerIcon(ctx: ctx, rect: CGRect(x: x, y: y, width: w, height: h),
                            color: color, muted: text == "🔇")
        } else {
            let attrs: [NSAttributedString.Key: Any] = [.font: iconFont]
            let textSize = (text as NSString).size(withAttributes: attrs)
            (text as NSString).draw(at: CGPoint(x: x + (w - textSize.width) / 2,
                                                 y: y + (h - textSize.height) / 2), withAttributes: attrs)
        }
    }

    private func drawCalculatorIcon(ctx: CGContext, rect: CGRect, color: UIColor) {
        let iconRect = rect.insetBy(dx: rect.width * 0.27, dy: rect.height * 0.19)
        let bodyPath = UIBezierPath(roundedRect: iconRect, cornerRadius: 3)

        ctx.setFillColor(color.withAlphaComponent(0.18).cgColor)
        ctx.addPath(bodyPath.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1.8)
        ctx.addPath(bodyPath.cgPath)
        ctx.strokePath()

        let displayRect = CGRect(x: iconRect.minX + 4, y: iconRect.minY + 4,
                                 width: iconRect.width - 8, height: iconRect.height * 0.24)
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.55).cgColor)
        ctx.fill(displayRect)
        ctx.setStrokeColor(color.withAlphaComponent(0.65).cgColor)
        ctx.setLineWidth(0.8)
        ctx.stroke(displayRect)

        let keySize = max(2.8, iconRect.width * 0.16)
        let gap = (iconRect.width - keySize * 3) / 4
        let startY = displayRect.maxY + 5
        ctx.setFillColor(color.withAlphaComponent(0.95).cgColor)
        for row in 0..<2 {
            for col in 0..<3 {
                let keyX = iconRect.minX + gap + CGFloat(col) * (keySize + gap)
                let keyY = startY + CGFloat(row) * (keySize + 4)
                ctx.fill(CGRect(x: keyX, y: keyY, width: keySize, height: keySize))
            }
        }
    }

    private func drawSpeakerIcon(ctx: CGContext, rect: CGRect, color: UIColor, muted: Bool) {
        let centerY = rect.midY
        let left = rect.minX + rect.width * 0.26
        let speakerW = rect.width * 0.32
        let speakerH = rect.height * 0.34

        ctx.setFillColor(color.withAlphaComponent(0.95).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: left, y: centerY - speakerH * 0.28))
        ctx.addLine(to: CGPoint(x: left + speakerW * 0.32, y: centerY - speakerH * 0.28))
        ctx.addLine(to: CGPoint(x: left + speakerW, y: centerY - speakerH * 0.58))
        ctx.addLine(to: CGPoint(x: left + speakerW, y: centerY + speakerH * 0.58))
        ctx.addLine(to: CGPoint(x: left + speakerW * 0.32, y: centerY + speakerH * 0.28))
        ctx.addLine(to: CGPoint(x: left, y: centerY + speakerH * 0.28))
        ctx.closePath()
        ctx.fillPath()

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(2)
        ctx.setLineCap(.round)

        if muted {
            let slashStart = CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY + rect.height * 0.32)
            let slashEnd = CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.68)
            ctx.move(to: slashStart)
            ctx.addLine(to: slashEnd)
            ctx.move(to: CGPoint(x: slashEnd.x, y: slashStart.y))
            ctx.addLine(to: CGPoint(x: slashStart.x, y: slashEnd.y))
            ctx.strokePath()
        } else {
            let waveCenter = CGPoint(x: left + speakerW * 0.92, y: centerY)
            ctx.addArc(center: waveCenter, radius: rect.width * 0.17,
                       startAngle: -0.72, endAngle: 0.72, clockwise: false)
            ctx.addArc(center: waveCenter, radius: rect.width * 0.27,
                       startAngle: -0.62, endAngle: 0.62, clockwise: false)
            ctx.strokePath()
        }

        ctx.setLineCap(.butt)
    }

    // MARK: - Start Screen
    func drawStartScreen(ctx: CGContext) {
        let compact = size.height < 700
        let english = Localized.isEnglish
        let titleY = max(safeTopInset + 36, size.height * (compact ? 0.20 : english ? 0.27 : 0.3))
        
        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: compact ? mono32 : mono44,
            .foregroundColor: GameConfig.neonGreen,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.5
        ]
        let title = "Tiny Buff"
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        (title as NSString).draw(at: CGPoint(x: (size.width - titleSize.width) / 2,
                                              y: titleY), withAttributes: titleAttrs)

        // Subtitle
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: mono16,
            .foregroundColor: GameConfig.neonGreen.withAlphaComponent(0.95),
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        let sub = Localized.string(zh: "FISH FORTUNE", en: "JUMP. LAND. REPEAT.", ja: "出世ジャンプ")
        let subSize = (sub as NSString).size(withAttributes: subAttrs)
        (sub as NSString).draw(at: CGPoint(x: (size.width - subSize.width) / 2,
                                            y: titleY + (compact ? 40 : 52)), withAttributes: subAttrs)

        // Stats
        let statsAttrs: [NSAttributedString.Key: Any] = [
            .font: mono13,
            .foregroundColor: GameConfig.textSecondary,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        let stats = Localized.string(
            zh: "历史最高: \(GamePersistence.shared.highScore) 分 | 连续签到: \(GamePersistence.shared.streak) 天",
            en: "Best \(GamePersistence.shared.highScore)",
            ja: "ハイスコア: \(GamePersistence.shared.highScore) | ログイン継続: \(GamePersistence.shared.streak)日"
        )
        let statsSize = (stats as NSString).size(withAttributes: statsAttrs)
        (stats as NSString).draw(at: CGPoint(x: (size.width - statsSize.width) / 2,
                                              y: titleY + (compact ? 78 : 112)), withAttributes: statsAttrs)

        // Tagline
        if english {
            drawEnglishStartHint(ctx: ctx, y: titleY + (compact ? 106 : 146))
        } else {
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: mono15,
                .foregroundColor: GameConfig.goldColor.withAlphaComponent(0.95),
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0
            ]
            let tag = Localized.string(zh: "时来运转，一跃成龙", en: "Slack off to rise, leap to the top", ja: "サボって登りつめ、龍となれ")
            let tagSize = (tag as NSString).size(withAttributes: tagAttrs)
            (tag as NSString).draw(at: CGPoint(x: (size.width - tagSize.width) / 2,
                                                y: titleY + (compact ? 104 : 146)), withAttributes: tagAttrs)
            drawStartInstructions(ctx: ctx, y: titleY + (compact ? 136 : 184))
        }

        // Buttons
        let btnW = min(size.width * 0.42, 160)
        let btnH: CGFloat = 44
        let gap: CGFloat = 16
        let startX = (size.width - (btnW * 2 + gap)) / 2
        let startY = min(size.height - safeBottomInset - btnH - 28, size.height * 0.65)

        drawButton(ctx: ctx, x: startX, y: startY, w: btnW, h: btnH,
                   text: Localized.string(zh: "开始摸鱼", en: "Start Slacking", ja: "サボり開始"), color: GameConfig.neonGreen)
        drawButton(ctx: ctx, x: startX + btnW + gap, y: startY, w: btnW, h: btnH,
                   text: Localized.string(zh: "排行", en: "Ranks", ja: "ランキング"), color: GameConfig.goldColor)
        
        let muteSz: CGFloat = min(size.width * 0.1, 38)
        let muteText = GamePersistence.shared.isMuted ? "🔇" : "🔊"
        let muteColor = GamePersistence.shared.isMuted ? GameConfig.errorRed : GameConfig.neonGreen
        drawHUDButton(ctx: ctx, x: size.width - muteSz - 14, y: safeTopInset - 12,
                      w: muteSz, h: muteSz, text: muteText, color: muteColor)

        // Animated fish icon
        let fishIconY = max(safeTopInset + 10, titleY - (compact ? 42 : 72)) + sin(gameTime * 2) * 5
        drawMiniFish(ctx: ctx, x: size.width / 2, y: fishIconY, scale: 2.0)
    }

    private func drawEnglishStartHint(ctx: CGContext, y: CGFloat) {
        let text = "Hold to charge  •  drag to aim"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono14,
            .foregroundColor: GameConfig.goldColor,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: y), withAttributes: attrs)
    }
    
    private func drawStartInstructions(ctx: CGContext, y: CGFloat) {
        guard y < size.height - safeBottomInset - 120 else { return }
        let lines = [
            Localized.string(zh: "1. 按住任意空白处蓄力", en: "1. Hold anywhere to charge", ja: "1. 長押しでチャージ"),
            Localized.string(zh: "2. 拖动改变轨迹，松手跳跃", en: "2. Drag to aim, release to jump", ja: "2. ドラッグで照準、離してジャンプ"),
            Localized.string(zh: "3. 落在发光中心可获得 PERFECT", en: "3. Land on the bright center for PERFECT", ja: "3. 中央に着地で PERFECT")
        ]
        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono13,
            .foregroundColor: UIColor.white.withAlphaComponent(0.88),
            .strokeColor: UIColor.black,
            .strokeWidth: -2.5
        ]
        let cardW = min(size.width - 48, 330)
        let cardH: CGFloat = 82
        let cardRect = CGRect(x: (size.width - cardW) / 2, y: y, width: cardW, height: cardH)
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.34).cgColor)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 10)
        ctx.addPath(cardPath.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(GameConfig.neonGreen.withAlphaComponent(0.22).cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(cardPath.cgPath)
        ctx.strokePath()
        
        for (idx, line) in lines.enumerated() {
            (line as NSString).draw(at: CGPoint(x: cardRect.minX + 14, y: cardRect.minY + 12 + CGFloat(idx) * 21), withAttributes: attrs)
        }
    }

    private func drawMiniFish(ctx: CGContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.scaleBy(x: scale, y: scale)
        ctx.setFillColor(GameConfig.neonGreen.withAlphaComponent(0.16).cgColor)
        ctx.fillEllipse(in: CGRect(x: -30, y: -22, width: 60, height: 44))
        ctx.setFillColor(GameConfig.neonGreen.cgColor)
        ctx.fillEllipse(in: CGRect(x: -20, y: -14, width: 40, height: 28))
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
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.78).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let centerX = size.width / 2
        let compact = size.height < 700
        let topY = max(safeTopInset + 24, size.height * (compact ? 0.13 : 0.2))
        let contentBottomY = topY + (compact ? 174 : 236)
        let panelW = min(size.width - 36, 360)
        let panelRect = CGRect(x: centerX - panelW / 2,
                               y: topY - 22,
                               width: panelW,
                               height: contentBottomY - topY + 44)
        drawPanel(ctx: ctx, rect: panelRect, borderColor: GameConfig.neonGreen.withAlphaComponent(0.26))

        // Death quote
        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: compact ? mono16 : mono18,
            .foregroundColor: GameConfig.errorRed,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.5
        ]
        let quoteSize = (currentDeathQuote as NSString).size(withAttributes: quoteAttrs)
        (currentDeathQuote as NSString).draw(at: CGPoint(x: centerX - quoteSize.width / 2,
                                                          y: topY), withAttributes: quoteAttrs)

        // Score
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: compact ? mono48 : mono56,
            .foregroundColor: GameConfig.neonGreen,
            .strokeColor: UIColor.black,
            .strokeWidth: -4.0
        ]
        let scoreText = "\(score)"
        let scoreSize = (scoreText as NSString).size(withAttributes: scoreAttrs)
        (scoreText as NSString).draw(at: CGPoint(x: centerX - scoreSize.width / 2,
                                                  y: topY + (compact ? 42 : 64)), withAttributes: scoreAttrs)

        // Level desc
        let lvConfig = gameLevels[min(level - 1, gameLevels.count - 1)]
        let lvAttrs: [NSAttributedString.Key: Any] = [
            .font: compact ? mono16 : mono18,
            .foregroundColor: lvConfig.color,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.5
        ]
        let lvSize = (lvConfig.desc as NSString).size(withAttributes: lvAttrs)
        (lvConfig.desc as NSString).draw(at: CGPoint(x: centerX - lvSize.width / 2,
                                                      y: topY + (compact ? 98 : 138)), withAttributes: lvAttrs)

        // High score
        let hiAttrs: [NSAttributedString.Key: Any] = [
            .font: mono15,
            .foregroundColor: GameConfig.textPrimary,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        let hiText = Localized.string(zh: "历史最高: \(GamePersistence.shared.highScore) 分", en: "Best \(GamePersistence.shared.highScore)", ja: "ハイスコア: \(GamePersistence.shared.highScore)")
        let hiSize = (hiText as NSString).size(withAttributes: hiAttrs)
        (hiText as NSString).draw(at: CGPoint(x: centerX - hiSize.width / 2,
                                               y: topY + (compact ? 126 : 174)), withAttributes: hiAttrs)

        // Buttons
        let btnW = min(size.width * 0.42, 150)
        let btnH: CGFloat = 38
        let gapX: CGFloat = 14
        let gapY: CGFloat = 12
        let startX = (size.width - (btnW * 2 + gapX)) / 2
        let startY = min(size.height - safeBottomInset - btnH * 2 - gapY - 24, size.height * 0.62)

        drawButton(ctx: ctx, x: startX, y: startY, w: btnW, h: btnH,
                   text: Localized.string(zh: "再翻一次", en: "Retry", ja: "もう一度サボる"), color: GameConfig.neonGreen)
        drawButton(ctx: ctx, x: startX + btnW + gapX, y: startY, w: btnW, h: btnH,
                   text: Localized.string(zh: "提交成绩", en: "Submit", ja: "スコア送信"), color: GameConfig.goldColor)
        drawButton(ctx: ctx, x: startX, y: startY + btnH + gapY, w: btnW, h: btnH,
                   text: Localized.string(zh: "查看排行", en: "Ranks", ja: "順位表"), color: UIColor(hex: "#aa66ff"))
        drawButton(ctx: ctx, x: startX + btnW + gapX, y: startY + btnH + gapY, w: btnW, h: btnH,
                   text: Localized.string(zh: "炫耀一下", en: "Share", ja: "自慢する"), color: UIColor(hex: "#00aaff"))
    }

    // MARK: - Leaderboard
    func drawLeaderboardScreen(ctx: CGContext) {
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.95).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: mono22,
            .foregroundColor: GameConfig.goldColor,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        let title = Localized.string(zh: "🏆 办公室摸鱼榜", en: "🏆 Ranks", ja: "🏆 社内サボり順位")
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        (title as NSString).draw(at: CGPoint(x: (size.width - titleSize.width) / 2,
                                              y: safeTopInset + 12), withAttributes: titleAttrs)

        // Close button
        drawButton(ctx: ctx, x: size.width - 52, y: safeTopInset - 12, w: 36, h: 36,
                   text: "✕", color: GameConfig.goldColor)

        // Render local leaderboard entries
        let entries = GamePersistence.shared.getLocalLeaderboard()
        let startY = max(safeTopInset + 70, size.height * 0.22)
        let rowH: CGFloat = 38
        
        for (i, entry) in entries.enumerated() {
            let rowY = startY + CGFloat(i) * (rowH + 10)
            
            // Draw a subtle background bar for each row
            let rowRect = CGRect(x: 24, y: rowY, width: size.width - 48, height: rowH)
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.04).cgColor)
            let path = UIBezierPath(roundedRect: rowRect, cornerRadius: 6)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            
            // Highlight the user row
            let isUser = entry.name.contains("你") || entry.name.contains("You") || entry.name.contains("あなた")
            if isUser {
                ctx.setStrokeColor(GameConfig.neonGreen.withAlphaComponent(0.3).cgColor)
                ctx.setLineWidth(1.0)
                ctx.addPath(path.cgPath)
                ctx.strokePath()
            }
            
            // Draw rank number
            let rankText = "#\(i + 1)"
            let rankColor = i == 0 ? GameConfig.goldColor : i == 1 ? UIColor.lightGray : i == 2 ? UIColor(hex: "#cd7f32") : UIColor.white.withAlphaComponent(0.6)
            
            let rankAttrs: [NSAttributedString.Key: Any] = [
                .font: mono15,
                .foregroundColor: rankColor,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.5
            ]
            (rankText as NSString).draw(at: CGPoint(x: 36, y: rowY + (rowH - 18) / 2), withAttributes: rankAttrs)
            
            // Draw name
            let nameColor = isUser ? GameConfig.neonGreen : UIColor.white
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: mono15,
                .foregroundColor: nameColor,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.5
            ]
            (entry.name as NSString).draw(at: CGPoint(x: 76, y: rowY + (rowH - 18) / 2), withAttributes: nameAttrs)
            
            // Draw score
            let scoreText = "\(entry.score)"
            let scoreAttrs: [NSAttributedString.Key: Any] = [
                .font: mono15,
                .foregroundColor: GameConfig.neonGreen,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.5
            ]
            let scoreSize = (scoreText as NSString).size(withAttributes: scoreAttrs)
            (scoreText as NSString).draw(at: CGPoint(x: size.width - 36 - scoreSize.width, y: rowY + (rowH - 18) / 2), withAttributes: scoreAttrs)
        }
    }

    // MARK: - Button Helper
    func drawButton(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                    text: String, color: UIColor) {
        let rect = CGRect(x: x, y: y, width: w, height: h)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 7)

        ctx.setFillColor(GameConfig.panelFill.withAlphaComponent(0.72).cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        ctx.setFillColor(color.withAlphaComponent(0.22).cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(2)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: mono16,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.5
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: x + (w - textSize.width) / 2,
                                             y: y + (h - textSize.height) / 2), withAttributes: attrs)
    }

    private func drawPanel(ctx: CGContext, rect: CGRect, borderColor: UIColor) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        ctx.setFillColor(GameConfig.panelFill.withAlphaComponent(0.78).cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(borderColor.cgColor)
        ctx.setLineWidth(1.5)
        ctx.addPath(path.cgPath)
        ctx.strokePath()
    }
    
    // MARK: - Tutorial & Button Feedback
    func drawTutorialOverlay(ctx: CGContext) {
        guard tutorialStep >= 0 else { return }
        
        let pulse = CGFloat(0.5 + sin(tutorialTimer * 4.0) * 0.5)
        let title: String
        let body: String
        switch tutorialStep {
        case 0:
            title = Localized.string(zh: "第一步：按住蓄力", en: "Hold", ja: "ステップ1：長押し")
            body = Localized.string(zh: "按住任意空白处，能量环会开始增长。", en: "Press anywhere to charge.", ja: "空いている場所を長押しすると、パワーが溜まります。")
        case 1:
            title = Localized.string(zh: "第二步：拖动瞄准", en: "Aim", ja: "ステップ2：ドラッグ")
            body = Localized.string(zh: "手指移动会改变虚线轨迹，拖到底部红区可取消。", en: "Drag to steer. Red zone cancels.", ja: "指を動かすと軌道が変わります。赤いエリアでキャンセル。")
        default:
            title = Localized.string(zh: "第三步：松手跳跃", en: "Release", ja: "ステップ3：離す")
            body = Localized.string(zh: "落在平台发光中心可获得 PERFECT 和更高连击。", en: "Hit the center for PERFECT.", ja: "中央に着地すると PERFECT とコンボが伸びます。")
        }
        
        let cardW = min(size.width - 36, 360)
        let cardH: CGFloat = Localized.isEnglish ? 74 : 88
        let cardY = min(size.height - safeBottomInset - cardH - 22, max(safeTopInset + 92, size.height * 0.68))
        let rect = CGRect(x: (size.width - cardW) / 2, y: cardY, width: cardW, height: cardH)
        
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.72).cgColor)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(GameConfig.neonGreen.withAlphaComponent(0.45 + pulse * 0.2).cgColor)
        ctx.setLineWidth(1.5)
        ctx.addPath(path.cgPath)
        ctx.strokePath()
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: mono16,
            .foregroundColor: GameConfig.neonGreen,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.5
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: mono13,
            .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            .strokeColor: UIColor.black,
            .strokeWidth: -2.0
        ]
        (title as NSString).draw(at: CGPoint(x: rect.minX + 14, y: rect.minY + 12), withAttributes: titleAttrs)
        (body as NSString).draw(in: CGRect(x: rect.minX + 14, y: rect.minY + 40, width: rect.width - 28, height: 38), withAttributes: bodyAttrs)
    }
    
    func drawButtonFeedback(ctx: CGContext) {
        guard buttonFeedbackLife > 0, buttonFeedbackX > -900 else { return }
        let progress = 1.0 - buttonFeedbackLife
        let radius = 8 + progress * 34
        ctx.setStrokeColor(GameConfig.neonGreen.withAlphaComponent(buttonFeedbackLife * 0.45).cgColor)
        ctx.setLineWidth(2)
        ctx.strokeEllipse(in: CGRect(x: buttonFeedbackX - radius, y: buttonFeedbackY - radius,
                                     width: radius * 2, height: radius * 2))
    }
}
