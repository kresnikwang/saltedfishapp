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
            if gx > size.width - 52 && gy < safeTopInset + 36 {
                registerButtonFeedback(x: gx, y: gy)
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
    private func registerButtonFeedback(x: CGFloat, y: CGFloat) {
        buttonFeedbackX = x
        buttonFeedbackY = y
        buttonFeedbackLife = 1.0
        AudioManager.shared.playSound(.tap)
        AudioManager.shared.vibrate(.light)
    }
    
    private func handleStartTouch(x: CGFloat, y: CGFloat) {
        let btnW: CGFloat = min(size.width * 0.42, 160)
        let btnH: CGFloat = 44
        let gap: CGFloat = 16
        let startX = (size.width - (btnW * 2 + gap)) / 2
        let startY = min(size.height - safeBottomInset - btnH - 28, size.height * 0.65)

        // Start button
        if x >= startX && x <= startX + btnW && y >= startY && y <= startY + btnH {
            registerButtonFeedback(x: x, y: y)
            startGame()
            return
        }
        // Rank button
        if x >= startX + btnW + gap && x <= startX + btnW * 2 + gap && y >= startY && y <= startY + btnH {
            registerButtonFeedback(x: x, y: y)
            showLeaderboard()
            return
        }
        // Mute button
        let muteSz: CGFloat = min(size.width * 0.1, 38)
        if x >= size.width - muteSz - 14 && y >= safeTopInset - 12 && y <= safeTopInset + muteSz + 4 {
            registerButtonFeedback(x: x, y: y)
            AudioManager.shared.toggleMute()
            return
        }
    }

    private func handlePlayingTouch(x: CGFloat, y: CGFloat) {
        let hudBtnSize: CGFloat = min(size.width * 0.12, 42)
        let safeTop = safeTopInset

        // Calculator button (top right)
        if x >= size.width - hudBtnSize - 16 && x <= size.width - 16 &&
           y >= safeTop && y <= safeTop + hudBtnSize {
            registerButtonFeedback(x: x, y: y)
            gameManager?.showCalculator = true
            return
        }

        // Mute button (next to calculator)
        if x >= size.width - hudBtnSize * 2 - 24 && x <= size.width - hudBtnSize - 24 &&
           y >= safeTop && y <= safeTop + hudBtnSize {
            registerButtonFeedback(x: x, y: y)
            AudioManager.shared.toggleMute()
            return
        }

        // Start charging
        isCharging = true
        chargePower = 0
        chargeProgress = 0
        chargeStartX = x
        chargeStartY = y
        chargeAngle = -.pi / 4
        chargeReadyFeedbackPlayed = false
        gameStateVal = .charging
        advanceTutorial(to: 1)
        AudioManager.shared.startChargeSound()
    }

    private func handleGameOverTouch(x: CGFloat, y: CGFloat) {
        let btnW = min(size.width * 0.42, 150)
        let btnH: CGFloat = 38
        let gapX: CGFloat = 14
        let gapY: CGFloat = 12
        let startX = (size.width - (btnW * 2 + gapX)) / 2
        let startY = min(size.height - safeBottomInset - btnH * 2 - gapY - 24, size.height * 0.62)

        // Retry
        if x >= startX && x <= startX + btnW &&
           y >= startY && y <= startY + btnH {
            registerButtonFeedback(x: x, y: y)
            startGame()
            return
        }
        // Submit
        if x >= startX + btnW + gapX && x <= startX + btnW * 2 + gapX &&
           y >= startY && y <= startY + btnH {
            registerButtonFeedback(x: x, y: y)
            GameCenterManager.shared.submitScore(score)
            return
        }
        // Leaderboard
        if x >= startX && x <= startX + btnW &&
           y >= startY + btnH + gapY && y <= startY + btnH * 2 + gapY {
            registerButtonFeedback(x: x, y: y)
            showLeaderboard()
            return
        }
        // Share
        if x >= startX + btnW + gapX && x <= startX + btnW * 2 + gapX &&
           y >= startY + btnH + gapY && y <= startY + btnH * 2 + gapY {
            registerButtonFeedback(x: x, y: y)
            shareScore()
            return
        }
    }

    func shareScore() {
        let text = Localized.string(
            zh: "我在 Tiny Buff 中获得了 \(score) 分！\(gameLevels[min(level-1, gameLevels.count-1)].desc)",
            en: "Tiny Buff: \(score) pts · \(gameLevels[min(level-1, gameLevels.count-1)].name)"
        )
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
 
    func showLeaderboard() {
        GameCenterManager.shared.showLeaderboard(fallback: {
            self.gameStateVal = .leaderboard
        })
    }
}
