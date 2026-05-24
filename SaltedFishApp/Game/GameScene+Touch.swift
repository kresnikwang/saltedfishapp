import SpriteKit

// MARK: - Touch Handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let pos = touch.location(in: self)
        // Convert SpriteKit coords (origin bottom-left) to game coords (origin top-left)
        let gx = pos.x
        let gy = size.height - pos.y
        pointerX = gx
        pointerY = gy
        isTouching = true

        switch gameStateVal {
        case .start:
            handleStartTouch(x: gx, y: gy)
        case .playing:
            handlePlayingTouch(x: gx, y: gy)
        case .jumping:
            inputBufferTime = gameTime
            bufferedPointerX = gx
            bufferedPointerY = gy
        case .gameover:
            handleGameOverTouch(x: gx, y: gy)
        case .leaderboard:
            // Close button
            if gx > size.width - 52 && gy < 52 {
                gameStateVal = .gameover
            }
        default:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let pos = touch.location(in: self)
        pointerX = pos.x
        pointerY = size.height - pos.y
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let pos = touch.location(in: self)
        pointerX = pos.x
        pointerY = size.height - pos.y
        isTouching = false

        if gameStateVal == .charging {
            releaseCharge()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        if gameStateVal == .charging {
            releaseCharge()
        }
    }

    // MARK: - Touch Handlers
    private func handleStartTouch(x: CGFloat, y: CGFloat) {
        let btnW: CGFloat = min(size.width * 0.42, 160)
        let btnH: CGFloat = 44
        let gap: CGFloat = 16
        let startX = (size.width - (btnW * 2 + gap)) / 2
        let startY = size.height * 0.65

        // Start button
        if x >= startX && x <= startX + btnW && y >= startY && y <= startY + btnH {
            startGame()
            return
        }
        // Rank button
        if x >= startX + btnW + gap && x <= startX + btnW * 2 + gap && y >= startY && y <= startY + btnH {
            // Show leaderboard placeholder
            return
        }
        // Mute button
        let muteSz: CGFloat = min(size.width * 0.1, 38)
        if x >= size.width - muteSz - 14 && y <= muteSz + 16 {
            AudioManager.shared.toggleMute()
            return
        }
    }

    private func handlePlayingTouch(x: CGFloat, y: CGFloat) {
        let hudBtnSize: CGFloat = min(size.width * 0.12, 42)

        // Calculator button (top right)
        if x >= size.width - hudBtnSize - 16 && x <= size.width - 16 &&
           y >= 0 && y <= hudBtnSize {
            gameManager?.showCalculator = true
            return
        }

        // Mute button (next to calculator)
        if x >= size.width - hudBtnSize * 2 - 24 && x <= size.width - hudBtnSize - 24 &&
           y >= 0 && y <= hudBtnSize {
            AudioManager.shared.toggleMute()
            return
        }

        // Start charging
        isCharging = true
        chargePower = 0
        chargeStartX = x
        chargeStartY = y
        chargeAngle = -.pi / 4
        gameStateVal = .charging
        AudioManager.shared.startChargeSound()
    }

    private func handleGameOverTouch(x: CGFloat, y: CGFloat) {
        let btnW = min(size.width * 0.42, 150)
        let btnH: CGFloat = 38
        let gapX: CGFloat = 14
        let gapY: CGFloat = 12
        let startX = (size.width - (btnW * 2 + gapX)) / 2
        let startY = size.height * 0.62

        // Retry
        if x >= startX && x <= startX + btnW &&
           y >= startY && y <= startY + btnH {
            startGame()
            return
        }
        // Submit (placeholder)
        if x >= startX + btnW + gapX && x <= startX + btnW * 2 + gapX &&
           y >= startY && y <= startY + btnH {
            // Submit score - placeholder
            return
        }
        // Leaderboard
        if x >= startX && x <= startX + btnW &&
           y >= startY + btnH + gapY && y <= startY + btnH * 2 + gapY {
            gameStateVal = .leaderboard
            return
        }
        // Share
        if x >= startX + btnW + gapX && x <= startX + btnW * 2 + gapX &&
           y >= startY + btnH + gapY && y <= startY + btnH * 2 + gapY {
            shareScore()
            return
        }
    }

    func shareScore() {
        let text = "我在「鱼来运转」中获得了 \(score) 分！\(gameLevels[min(level-1, gameLevels.count-1)].desc)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
