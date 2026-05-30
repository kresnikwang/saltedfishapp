import SpriteKit
import UIKit

// MARK: - Custom Rendering
extension GameScene {

    // Called by renderFrame() in Update.swift — ctx is already created there
    func drawGame(ctx: CGContext) {
        // Apply screen shake
        var shakeX: CGFloat = 0
        var shakeY: CGFloat = 0
        if screenShakeX != 0 || screenShakeY != 0 {
            shakeX = screenShakeX + CGFloat.random(in: -0.5...0.5) * abs(screenShakeX) * 0.3
            shakeY = screenShakeY + CGFloat.random(in: -0.5...0.5) * abs(screenShakeY) * 0.3
        }
        ctx.translateBy(x: shakeX, y: shakeY)

        switch gameStateVal {
        case .start:
            drawBackground(ctx: ctx)
            drawBubbles(ctx: ctx)
            drawStartScreen(ctx: ctx)
        case .playing, .charging, .jumping:
            drawBackground(ctx: ctx)
            drawGrid(ctx: ctx)
            drawWaterSurface(ctx: ctx)
            drawBubbles(ctx: ctx)
            drawDanmaku(ctx: ctx)
            drawPlatforms(ctx: ctx)
            drawObstacles(ctx: ctx)
            drawDragonGateVisual(ctx: ctx)
            drawFish(ctx: ctx)
            drawChargeIndicator(ctx: ctx)
            drawTrajectoryPreview(ctx: ctx)
            drawParticlesAndRipples(ctx: ctx)
            drawScorePopupsVisual(ctx: ctx)
            drawHUD(ctx: ctx)
            drawCancelZone(ctx: ctx)
            drawFishQuipVisual(ctx: ctx)
        case .gameover:
            drawBackground(ctx: ctx)
            drawGrid(ctx: ctx)
            drawPlatforms(ctx: ctx)
            drawFish(ctx: ctx)
            drawParticlesAndRipples(ctx: ctx)
            drawGameOverScreen(ctx: ctx)
        case .leaderboard:
            drawBackground(ctx: ctx)
            drawLeaderboardScreen(ctx: ctx)
        }
    }

    // MARK: - Background (cached gradient)
    func drawBackground(ctx: CGContext) {
        // Use flat fill instead of gradient for perf — visually nearly identical at 1x scale
        ctx.setFillColor(GameConfig.bgDark.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        // Subtle bottom tint (one rect, zero gradient overhead)
        ctx.setFillColor(UIColor(red: 0, green: 0.08, blue: 0.04, alpha: 0.6).cgColor)
        ctx.fill(CGRect(x: 0, y: size.height * 0.5, width: size.width, height: size.height * 0.5))
    }

    // MARK: - Grid (coarser for perf — 60px instead of 40px = ~40% fewer lines)
    func drawGrid(ctx: CGContext) {
        ctx.setStrokeColor(UIColor(white: 1, alpha: 0.025).cgColor)
        ctx.setLineWidth(0.5)
        let gridSize: CGFloat = 60
        let offsetX = cameraXOffset.truncatingRemainder(dividingBy: gridSize)

        ctx.beginPath()
        for x in stride(from: -offsetX, to: size.width + gridSize, by: gridSize) {
            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: size.height))
        }
        // Only horizontal lines every 2nd row to halve draw calls
        for y in stride(from: CGFloat(0), to: size.height, by: gridSize) {
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.strokePath()
    }

    // MARK: - Water Surface (larger step = fewer path segments)
    func drawWaterSurface(ctx: CGContext) {
        let waterY = size.height * 0.92
        ctx.setStrokeColor(UIColor(red: 0, green: 1, blue: 0.53, alpha: 0.12).cgColor)
        ctx.setLineWidth(1.5)

        ctx.beginPath()
        // Step 6px instead of 2px — still smooth, ~3x fewer path points
        var first = true
        for x in stride(from: CGFloat(0), to: size.width, by: 6) {
            let wave = sin(Double(x) * 0.02 + gameTime * 2) * 4
            let y = waterY + CGFloat(wave)
            if first { ctx.move(to: CGPoint(x: x, y: y)); first = false }
            else { ctx.addLine(to: CGPoint(x: x, y: y)) }
        }
        ctx.strokePath()

        ctx.setFillColor(UIColor(red: 0, green: 0.2, blue: 0.1, alpha: 0.08).cgColor)
        ctx.fill(CGRect(x: 0, y: waterY, width: size.width, height: size.height - waterY))
    }

    // MARK: - Bubbles
    func drawBubbles(ctx: CGContext) {
        ctx.setFillColor(UIColor(red: 0, green: 1, blue: 0.53, alpha: 0.07).cgColor)
        for bubble in bubbles {
            let screenX = bubble.x - cameraXOffset
            guard screenX > -20 && screenX < size.width + 20 else { continue }
            ctx.fillEllipse(in: CGRect(x: screenX - bubble.r, y: bubble.y - bubble.r,
                                       width: bubble.r * 2, height: bubble.r * 2))
        }
    }

    // MARK: - Danmaku
    func drawDanmaku(ctx: CGContext) {
        let font = UIFont(name: "Courier New", size: 14) ?? UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        for dm in activeDanmaku {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(white: 1, alpha: 0.45),
                .strokeColor: UIColor.black.withAlphaComponent(0.45),
                .strokeWidth: -2.5
            ]
            (dm.text as NSString).draw(at: CGPoint(x: dm.x, y: dm.y), withAttributes: attrs)
        }
    }

    // MARK: - Platforms
    func drawPlatforms(ctx: CGContext) {
        // Pre-resolve font once outside loop
        let labelFont = UIFont(name: "Courier New", size: 10) ?? UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)

        for p in platforms {
            var platY = p.y
            if p.type == .client {
                platY = p.y + sin(gameTime * 2 + Double(p.bobOffset)) * 20
            }

            let screenX = p.x - cameraXOffset
            guard screenX > -p.w && screenX < size.width + p.w else { continue }

            // Vanish alpha
            var vanishAlpha: CGFloat = 1
            if p.type == .vanish && p.vanishTimer > 0 {
                let elapsed = gameTime - p.vanishTimer
                if elapsed > 1.0 { continue }
                vanishAlpha = CGFloat(max(0, 1 - elapsed))
            }

            let color = p.type.color
            let platRect = CGRect(x: screenX - p.w / 2, y: platY - p.h / 2,
                                  width: p.w, height: p.h)

            ctx.saveGState()
            ctx.setAlpha(vanishAlpha)

            // Platform fill (no expensive shadow — replaced by inner border for perf)
            ctx.setFillColor(color.cgColor)
            let path = UIBezierPath(roundedRect: platRect, cornerRadius: 3)
            ctx.addPath(path.cgPath)
            ctx.fillPath()

            // Thin border instead of glow/shadow (much cheaper)
            ctx.setStrokeColor(color.withAlphaComponent(0.6).cgColor)
            ctx.setLineWidth(1.0)
            ctx.addPath(path.cgPath)
            ctx.strokePath()

            // Perfect zone indicator (center highlight, non-boss only)
            if p.type != .boss {
                let perfectW = p.w * GameConfig.perfectLandingZone * 2
                let perfectRect = CGRect(x: screenX - perfectW / 2, y: platY - p.h / 2,
                                        width: perfectW, height: p.h)
                ctx.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
                let perfectPath = UIBezierPath(roundedRect: perfectRect, cornerRadius: 2)
                ctx.addPath(perfectPath.cgPath)
                ctx.fillPath()
            }

            // Platform label
            if p.w > 30 {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: labelFont,
                    .foregroundColor: UIColor.white,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -2.5
                ]
                let label = NSAttributedString(string: p.type.label, attributes: attrs)
                let labelSize = label.size()
                label.draw(at: CGPoint(x: screenX - labelSize.width / 2, y: platY - labelSize.height / 2))
            }

            ctx.restoreGState()
        }
    }

    // MARK: - Seaweed (reduced segments: 12 vs 20)
    private func drawSeaweed(ctx: CGContext, x: CGFloat, y: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: "#00aa44").cgColor)
        ctx.setLineWidth(3)
        ctx.beginPath()
        for i in 0..<12 {
            let t = CGFloat(i) / 12.0
            let px = x + sin(t * 4 + CGFloat(gameTime) * 3) * 6
            let py = y + t * 40
            if i == 0 { ctx.move(to: CGPoint(x: px, y: py)) }
            else { ctx.addLine(to: CGPoint(x: px, y: py)) }
        }
        ctx.strokePath()
    }

    private func drawCrab(ctx: CGContext, x: CGFloat, y: CGFloat) {
        ctx.setFillColor(UIColor(hex: "#ff4444").cgColor)
        ctx.fillEllipse(in: CGRect(x: x - 10, y: y - 6, width: 20, height: 12))
        let clawAngle = sin(gameTime * 5) * 0.3
        ctx.setStrokeColor(UIColor(hex: "#ff4444").cgColor)
        ctx.setLineWidth(2)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x - 10, y: y))
        ctx.addLine(to: CGPoint(x: x - 16, y: y - 8 + CGFloat(clawAngle) * 10))
        ctx.move(to: CGPoint(x: x + 10, y: y))
        ctx.addLine(to: CGPoint(x: x + 16, y: y - 8 - CGFloat(clawAngle) * 10))
        ctx.strokePath()
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: x - 5, y: y - 8, width: 4, height: 4))
        ctx.fillEllipse(in: CGRect(x: x + 1, y: y - 8, width: 4, height: 4))
    }

    private func drawDoc(ctx: CGContext, x: CGFloat, y: CGFloat) {
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        ctx.fill(CGRect(x: x - 8, y: y - 12, width: 16, height: 24))
        ctx.setStrokeColor(UIColor.gray.cgColor)
        ctx.setLineWidth(0.5)
        ctx.beginPath()
        for i in 0..<3 {
            let ly = y - 6 + CGFloat(i) * 6
            ctx.move(to: CGPoint(x: x - 5, y: ly))
            ctx.addLine(to: CGPoint(x: x + 5, y: ly))
        }
        ctx.strokePath()
        let font = UIFont(name: "Courier New", size: 7) ?? UIFont.monospacedSystemFont(ofSize: 7, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.red]
        NSAttributedString(string: "PRD", attributes: attrs).draw(at: CGPoint(x: x - 7, y: y - 11))
    }

    // MARK: - Obstacles
    func drawObstacles(ctx: CGContext) {
        for obs in obstacles {
            guard obs.y > -9000 else { continue }

            var ox = obs.x
            if obs.type == .doc {
                ox = obs.startX + sin(gameTime * 1.5 + Double(obs.bobOffset)) * 30
            }
            let screenX = ox - cameraXOffset
            guard screenX > -30 && screenX < size.width + 30 else { continue }

            let bobY = obs.y + sin(gameTime * 3.0 + Double(obs.bobOffset)) * 6.0

            switch obs.type {
            case .seaweed:
                drawSeaweed(ctx: ctx, x: screenX, y: bobY)
            case .crab:
                drawCrab(ctx: ctx, x: screenX, y: bobY)
            case .doc:
                drawDoc(ctx: ctx, x: screenX, y: bobY)
            case .boss:
                drawBossMonitor(ctx: ctx, x: screenX, y: bobY, obs: obs)
            }
        }
    }

    private func drawBossMonitor(ctx: CGContext, x: CGFloat, y: CGFloat, obs: ObstacleData) {
        // Monitor body
        ctx.setFillColor(UIColor(hex: "#333333").cgColor)
        ctx.fill(CGRect(x: x - 14, y: y - 12, width: 28, height: 20))
        ctx.setStrokeColor(UIColor(hex: "#ff0055").cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(CGRect(x: x - 14, y: y - 12, width: 28, height: 20))

        // Eye
        let eyeOffset = sin(gameTime * 1.5 + Double(obs.bobOffset)) * 5.0
        ctx.setFillColor(UIColor(hex: "#ff0055").cgColor)
        ctx.fillEllipse(in: CGRect(x: x + eyeOffset - 3, y: y - 5, width: 6, height: 6))

        // Scan beam — simplified: just draw a semi-transparent triangle, no gradient (gradient is expensive)
        let scanX = x + sin(gameTime * 1.5 + Double(obs.bobOffset)) * 30.0
        ctx.setFillColor(UIColor(hex: "#ff0055").withAlphaComponent(0.18).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: y + 8))
        ctx.addLine(to: CGPoint(x: scanX - 14, y: size.height))
        ctx.addLine(to: CGPoint(x: scanX + 14, y: size.height))
        ctx.closePath()
        ctx.fillPath()
    }
}
