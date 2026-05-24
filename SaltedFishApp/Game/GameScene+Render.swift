import SpriteKit
import UIKit

// MARK: - Custom Rendering
extension GameScene {

    func drawGame(in parentNode: SKNode) {
        // We'll use a single SKShapeNode-based drawing approach
        // or a bitmap rendering approach via SKSpriteNode with CGContext

        let renderSize = size
        UIGraphicsBeginImageContextWithOptions(renderSize, true, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }

        // Flip coordinate system (CGContext is bottom-left, we want top-left)
        ctx.translateBy(x: 0, y: renderSize.height)
        ctx.scaleBy(x: 1, y: -1)

        // Apply screen shake
        ctx.translateBy(x: screenShakeX, y: screenShakeY)

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

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let cgImage = image?.cgImage {
            let texture = SKTexture(cgImage: cgImage)
            let sprite = SKSpriteNode(texture: texture, size: renderSize)
            sprite.position = CGPoint(x: renderSize.width / 2, y: renderSize.height / 2)
            sprite.zPosition = 0
            parentNode.addChild(sprite)
        }
    }

    // MARK: - Background
    func drawBackground(ctx: CGContext) {
        let w = size.width
        let h = size.height
        let colors = [GameConfig.bgDark.cgColor, GameConfig.bgDarkGreen.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray,
                                  locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: h),
                               options: [])
    }

    // MARK: - Grid
    func drawGrid(ctx: CGContext) {
        ctx.setStrokeColor(UIColor(white: 1, alpha: 0.03).cgColor)
        ctx.setLineWidth(0.5)
        let gridSize: CGFloat = 40
        let offsetX = cameraXOffset.truncatingRemainder(dividingBy: gridSize)

        for x in stride(from: -offsetX, to: size.width + gridSize, by: gridSize) {
            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: size.height))
        }
        for y in stride(from: CGFloat(0), to: size.height, by: gridSize) {
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.strokePath()
    }

    // MARK: - Water Surface
    func drawWaterSurface(ctx: CGContext) {
        let waterY = size.height * 0.92
        ctx.setStrokeColor(UIColor(red: 0, green: 1, blue: 0.53, alpha: 0.15).cgColor)
        ctx.setLineWidth(1.5)

        ctx.beginPath()
        for x in stride(from: CGFloat(0), to: size.width, by: 2) {
            let wave = sin(Double(x) * 0.02 + gameTime * 2) * 4
            let y = waterY + CGFloat(wave)
            if x == 0 { ctx.move(to: CGPoint(x: x, y: y)) }
            else { ctx.addLine(to: CGPoint(x: x, y: y)) }
        }
        ctx.strokePath()

        // Water fill
        ctx.setFillColor(UIColor(red: 0, green: 0.2, blue: 0.1, alpha: 0.1).cgColor)
        ctx.fill(CGRect(x: 0, y: waterY, width: size.width, height: size.height - waterY))
    }

    // MARK: - Bubbles
    func drawBubbles(ctx: CGContext) {
        for bubble in bubbles {
            let screenX = bubble.x - cameraXOffset
            guard screenX > -20 && screenX < size.width + 20 else { continue }
            ctx.setFillColor(UIColor(red: 0, green: 1, blue: 0.53, alpha: 0.08).cgColor)
            ctx.fillEllipse(in: CGRect(x: screenX - bubble.r, y: bubble.y - bubble.r,
                                       width: bubble.r * 2, height: bubble.r * 2))
        }
    }

    // MARK: - Danmaku
    func drawDanmaku(ctx: CGContext) {
        let font = UIFont(name: "Courier New", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        for dm in activeDanmaku {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(white: 1, alpha: 0.25),
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]
            let str = NSAttributedString(string: dm.text, attributes: attrs)
            str.draw(at: CGPoint(x: dm.x, y: dm.y))
        }
    }

    // MARK: - Platforms
    func drawPlatforms(ctx: CGContext) {
        for (i, p) in platforms.enumerated() {
            var platY = p.y
            if p.type == .client {
                platY = p.y + sin(gameTime * 2 + Double(p.bobOffset)) * 20
            }

            let screenX = p.x - cameraXOffset
            guard screenX > -p.w && screenX < size.width + p.w else { continue }

            // Vanish check
            if p.type == .vanish && p.vanishTimer > 0 {
                let elapsed = gameTime - p.vanishTimer
                if elapsed > 1.0 { continue }
                ctx.setAlpha(CGFloat(max(0, 1 - elapsed)))
            }

            let color = p.type.color
            let platRect = CGRect(x: screenX - p.w / 2, y: platY - p.h / 2,
                                  width: p.w, height: p.h)

            // Platform glow
            ctx.setShadow(offset: .zero, blur: 8, color: color.withAlphaComponent(0.4).cgColor)
            ctx.setFillColor(color.cgColor)

            let path = UIBezierPath(roundedRect: platRect, cornerRadius: 3)
            ctx.addPath(path.cgPath)
            ctx.fillPath()

            ctx.setShadow(offset: .zero, blur: 0, color: nil)

            // Platform label
            if p.w > 30 {
                let labelFont = UIFont(name: "Courier New", size: 8) ?? UIFont.monospacedSystemFont(ofSize: 8, weight: .bold)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: labelFont,
                    .foregroundColor: UIColor.black.withAlphaComponent(0.6)
                ]
                let label = NSAttributedString(string: p.type.label, attributes: attrs)
                let labelSize = label.size()
                label.draw(at: CGPoint(x: screenX - labelSize.width / 2, y: platY - labelSize.height / 2))
            }

            ctx.setAlpha(1)
        }
    }

    // MARK: - Obstacles
    func drawObstacles(ctx: CGContext) {
        for obs in obstacles {
            var ox = obs.x
            if obs.type == .doc {
                ox = obs.startX + sin(gameTime * 1.5 + Double(obs.bobOffset)) * 30
            }
            let screenX = ox - cameraXOffset
            guard screenX > -30 && screenX < size.width + 30 else { continue }

            let bobY = obs.y + sin(gameTime * 2 + Double(obs.bobOffset)) * 5

            switch obs.type {
            case .seaweed:
                drawSeaweed(ctx: ctx, x: screenX, y: bobY)
            case .crab:
                drawCrab(ctx: ctx, x: screenX, y: bobY)
            case .doc:
                drawDoc(ctx: ctx, x: screenX, y: bobY)
            case .boss:
                drawBossMonitor(ctx: ctx, x: screenX, y: bobY)
            }
        }
    }

    private func drawSeaweed(ctx: CGContext, x: CGFloat, y: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: "#00aa44").cgColor)
        ctx.setLineWidth(3)
        ctx.beginPath()
        for i in 0..<20 {
            let t = CGFloat(i) / 20.0
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
        // Claws
        let clawAngle = sin(gameTime * 5) * 0.3
        ctx.setStrokeColor(UIColor(hex: "#ff4444").cgColor)
        ctx.setLineWidth(2)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x - 10, y: y))
        ctx.addLine(to: CGPoint(x: x - 16, y: y - 8 + CGFloat(clawAngle) * 10))
        ctx.move(to: CGPoint(x: x + 10, y: y))
        ctx.addLine(to: CGPoint(x: x + 16, y: y - 8 - CGFloat(clawAngle) * 10))
        ctx.strokePath()
        // Eyes
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: x - 5, y: y - 8, width: 4, height: 4))
        ctx.fillEllipse(in: CGRect(x: x + 1, y: y - 8, width: 4, height: 4))
    }

    private func drawDoc(ctx: CGContext, x: CGFloat, y: CGFloat) {
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        ctx.fill(CGRect(x: x - 8, y: y - 12, width: 16, height: 24))
        // Lines on doc
        ctx.setStrokeColor(UIColor.gray.cgColor)
        ctx.setLineWidth(0.5)
        for i in 0..<3 {
            let ly = y - 6 + CGFloat(i) * 6
            ctx.move(to: CGPoint(x: x - 5, y: ly))
            ctx.addLine(to: CGPoint(x: x + 5, y: ly))
        }
        ctx.strokePath()
        // PRD label
        let font = UIFont(name: "Courier New", size: 6) ?? UIFont.monospacedSystemFont(ofSize: 6, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.red]
        NSAttributedString(string: "PRD", attributes: attrs).draw(at: CGPoint(x: x - 7, y: y - 11))
    }

    private func drawBossMonitor(ctx: CGContext, x: CGFloat, y: CGFloat) {
        // Monitor
        ctx.setFillColor(UIColor(hex: "#333333").cgColor)
        ctx.fill(CGRect(x: x - 14, y: y - 12, width: 28, height: 20))
        ctx.setStrokeColor(UIColor(hex: "#ff0055").cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(CGRect(x: x - 14, y: y - 12, width: 28, height: 20))
        // Eye
        ctx.setFillColor(UIColor(hex: "#ff0055").cgColor)
        let eyeX = x + sin(gameTime * 3) * 5
        ctx.fillEllipse(in: CGRect(x: eyeX - 3, y: y - 5, width: 6, height: 6))
        // Scan beam
        let beamAlpha = (sin(gameTime * 4) + 1) / 4
        ctx.setFillColor(UIColor(hex: "#ff0055").withAlphaComponent(CGFloat(beamAlpha)).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: y + 8))
        ctx.addLine(to: CGPoint(x: x - 20, y: y + 60))
        ctx.addLine(to: CGPoint(x: x + 20, y: y + 60))
        ctx.closePath()
        ctx.fillPath()
    }
}
