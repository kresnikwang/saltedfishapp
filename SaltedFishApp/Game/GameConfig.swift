import Foundation
import UIKit
import GameKit

// MARK: - Localization Helper
struct Localized {
    enum Language {
        case zh, en, ja
    }

    static var currentLanguage: Language {
        if #available(iOS 16.0, *) {
            guard let lang = Locale.current.language.languageCode?.identifier else { return .zh }
            let lower = lang.lowercased()
            if lower.hasPrefix("en") { return .en }
            if lower.hasPrefix("ja") { return .ja }
            return .zh
        } else {
            guard let lang = Locale.current.languageCode else { return .zh }
            let lower = lang.lowercased()
            if lower.hasPrefix("en") { return .en }
            if lower.hasPrefix("ja") { return .ja }
            return .zh
        }
    }

    static var isEnglish: Bool {
        return currentLanguage == .en
    }

    static func string(zh: String, en: String, ja: String? = nil) -> String {
        switch currentLanguage {
        case .en: return en
        case .ja: return ja ?? en
        case .zh: return zh
        }
    }
}

// MARK: - Physics Constants
struct GameConfig {
    static let gravity: CGFloat = 0.35
    static let maxPower: CGFloat = 18.0
    static let chargeRate: CGFloat = 0.25
    static let chargeFullDuration: CGFloat = 1.25
    static let chargeCurveExponent: CGFloat = 0.82
    static let minLaunchPower: CGFloat = 4.2
    static let chargeReadyThreshold: CGFloat = 0.88
    static let aimSmoothingFactor: CGFloat = 0.30
    static let minLaunchAngle: CGFloat = -CGFloat.pi * 0.82
    static let maxLaunchAngle: CGFloat = -CGFloat.pi * 0.08
    static let platformMinGap: CGFloat = 60.0
    static let platformMaxGap: CGFloat = 160.0
    static let fishWidth: CGFloat = 40.0
    static let fishHeight: CGFloat = 28.0
    static let platformHeight: CGFloat = 14.0
    static let slowMotionScale: CGFloat = 0.35
    static let cancelZoneRatio: CGFloat = 0.15
    static let maxBubbles: Int = 12
    static let maxDanmakuItems: Int = 4
    static let maxTrajectoryDots: Int = 22
    static let perfectLandingZone: CGFloat = 0.15
    static let perfectMultiplier: CGFloat = 1.8
    static let baseScore: Int = 100
    static let comboMultiplierStep: CGFloat = 0.1
    static let inputBufferWindow: TimeInterval = 0.3
    static let cameraLerpFactor: CGFloat = 0.12
    static let cameraBaseOffset: CGFloat = 0.3  // fraction of screen width
    static let cameraChargeLookAhead: CGFloat = 0.34
    static let cameraJumpLookAhead: CGFloat = 0.16
    static let landingForgiveness: CGFloat = 7.0
    static let landingVerticalForgiveness: CGFloat = 14.0
    static let obstacleCollisionRadius: CGFloat = 20.0

    // Colors
    static let neonGreen = UIColor(red: 0, green: 1, blue: 136.0/255, alpha: 1)
    static let bgDark = UIColor(red: 10.0/255, green: 10.0/255, blue: 10.0/255, alpha: 1)
    static let bgDarkGreen = UIColor(red: 13.0/255, green: 26.0/255, blue: 13.0/255, alpha: 1)
    static let goldColor = UIColor(red: 1, green: 170.0/255, blue: 0, alpha: 1)
    static let perfectGold = UIColor(red: 1, green: 238.0/255, blue: 0, alpha: 1)
    static let errorRed = UIColor(red: 1, green: 68.0/255, blue: 102.0/255, alpha: 1)
}

// MARK: - Platform Types
enum PlatformType: String, CaseIterable {
    case normal, meeting, client, tea, spring, vanish, slide, boss

    var color: UIColor {
        switch self {
        case .normal:  return UIColor(hex: "#00ff88")
        case .meeting: return UIColor(hex: "#ff4444")
        case .client:  return UIColor(hex: "#ff8800")
        case .tea:     return UIColor(hex: "#44ddaa")
        case .spring:  return UIColor(hex: "#00bbff")
        case .vanish:  return UIColor(hex: "#cc55ff")
        case .slide:   return UIColor(hex: "#ffbb00")
        case .boss:    return UIColor(hex: "#ff0055")
        }
    }

    var label: String {
        switch self {
        case .normal:  return Localized.string(zh: "摸鱼", en: "Slack", ja: "サボり")
        case .meeting: return Localized.string(zh: "会议", en: "Meeting", ja: "会議")
        case .client:  return Localized.string(zh: "见客", en: "Client", ja: "来客")
        case .tea:     return Localized.string(zh: "喝茶", en: "Coffee", ja: "お茶")
        case .spring:  return Localized.string(zh: "弹射", en: "Bounce", ja: "ジャンプ")
        case .vanish:  return Localized.string(zh: "消失", en: "Vanish", ja: "消滅")
        case .slide:   return Localized.string(zh: "滑行", en: "Coast", ja: "滑走")
        case .boss:    return Localized.string(zh: "老板", en: "Boss", ja: "上司")
        }
    }
}

// MARK: - Obstacle Types
enum ObstacleType: String {
    case seaweed, crab, doc, boss
}

// MARK: - Level Config
struct LevelConfig {
    let nameZh: String
    let nameEn: String
    let nameJa: String
    let threshold: Int
    let color: UIColor
    let jumpBonus: CGFloat
    let descZh: String
    let descEn: String
    let descJa: String

    var name: String {
        switch Localized.currentLanguage {
        case .en: return nameEn
        case .ja: return nameJa
        case .zh: return nameZh
        }
    }

    var desc: String {
        switch Localized.currentLanguage {
        case .en: return descEn
        case .ja: return descJa
        case .zh: return descZh
        }
    }
}

let gameLevels: [LevelConfig] = [
    LevelConfig(nameZh: "咸鱼形态", nameEn: "Unmotivated Intern", nameJa: "サボり初心者", threshold: 0, color: UIColor(hex: "#888888"), jumpBonus: 0, descZh: "LV.01 咸鱼形态", descEn: "LV.01 Unmotivated Intern", descJa: "LV.01 サボり初心者"),
    LevelConfig(nameZh: "摸鱼学徒", nameEn: "Quiet Quitter", nameJa: "サボり魔", threshold: 1000, color: UIColor(hex: "#aa7700"), jumpBonus: 0.06, descZh: "LV.02 摸鱼学徒", descEn: "LV.02 Quiet Quitter", descJa: "LV.02 サボり魔"),
    LevelConfig(nameZh: "锦鲤本鲤", nameEn: "Coffee Badger", nameJa: "定時退社プロ", threshold: 2500, color: UIColor(hex: "#ffaa00"), jumpBonus: 0.13, descZh: "LV.03 锦鲤本鲤", descEn: "LV.03 Coffee Badger", descJa: "LV.03 定時退社プロ"),
    LevelConfig(nameZh: "职场海王", nameEn: "Corporate Survivor", nameJa: "窓際族", threshold: 5000, color: UIColor(hex: "#dd5500"), jumpBonus: 0.21, descZh: "LV.04 职场海王", descEn: "LV.04 Corporate Survivor", descJa: "LV.04 窓際族"),
    LevelConfig(nameZh: "老油条", nameEn: "Overemployed Guru", nameJa: "ステルス社員", threshold: 10000, color: UIColor(hex: "#ff6600"), jumpBonus: 0.30, descZh: "LV.05 老油条", descEn: "LV.05 Overemployed Guru", descJa: "LV.05 ステルス社員"),
    LevelConfig(nameZh: "隐形高手", nameEn: "Meeting Dodger", nameJa: "妖精さん", threshold: 20000, color: UIColor(hex: "#cc3366"), jumpBonus: 0.40, descZh: "LV.06 隐形高手", descEn: "LV.06 Meeting Dodger", descJa: "LV.06 妖精さん"),
    LevelConfig(nameZh: "离职神龙", nameEn: "Resigned Legend", nameJa: "脱出成功龍", threshold: 35000, color: UIColor(hex: "#ff0066"), jumpBonus: 0.52, descZh: "MAX 离职神龙", descEn: "MAX Resigned Legend", descJa: "MAX 脱出成功龍"),
]

// MARK: - Game Texts
struct GameTexts {
    static var fishQuips: [String] {
        switch Localized.currentLanguage {
        case .en:
            return [
                "Meeting in 5 mins...", "I'll do it tomorrow.", "Just looking busy...",
                "Quiet quitting today.", "Slack is open, I'm active.", "Is it 5 PM yet?",
                "Oh no, Boss is typing...", "Did payday hit yet?", "Pretending to care."
            ]
        case .ja:
            return [
                "終わったらサボろう...", "帰りたい...", "忙しいフリ中...",
                "定時退社こそ正義", "上司がこっち見てる", "給料日まだ？",
                "サボる5分、幸せ2時間", "お腹空いたな", "有給とりたい"
            ]
        case .zh:
            return [
                "玩完这把就去开会了", "好想下班...", "假装很忙.jpg",
                "今天也是摸鱼的一天", "摸鱼5分钟，快乐2小时", "又在划水了",
                "老板别过来！", "发工资了吗？", "佛系打工中..."
            ]
        }
    }

    static var danmakuTexts: [String] {
        switch Localized.currentLanguage {
        case .en:
            return [
                "Paid to poop", "This meeting could have been an email", "Let's circle back",
                "Let's touch base", "I don't have the bandwidth", "As per my last email...",
                "Happy Friday!", "Is it the weekend yet?", "Another useless sync",
                "Mouse jiggler is on", "Quiet quitting is a lifestyle", "Overemployed & proud",
                "HR is watching", "Synergy! Innovation! Disruption!", "Let's take this offline"
            ]
        case .ja:
            return [
                "働いたら負け", "この会議、メールで良くない？", "持ち帰って検討します",
                "プレミアムフライデー？", "有給休暇消化中", "定時ダッシュ！",
                "業務時間外です", "稟議書どこいった？", "ハンコ押してください",
                "お疲れ様でした", "進捗どうですか？", "シュシュッと退社"
            ]
        case .zh:
            return [
                "摸鱼使我快乐", "老板又开会了...", "今天的KPI完成了吗？",
                "带薪拉屎中", "这个需求做不了", "明天再说吧", "工资到账了吗",
                "加班是不可能加班的", "又到了摸鱼时间", "甲方改了第18版",
                "今天周五吗？", "摸鱼才是真生产力", "996是福报？", "00后整顿职场",
                "请假被拒了", "下班倒计时", "开始摆烂", "佛系打工",
                "月薪三千操碎了心", "外包比我还卷"
            ]
        }
    }

    static var deathQuotes: [String] {
        switch Localized.currentLanguage {
        case .en:
            return [
                "Back to editing slides...",
                "Boss: 'Can you hop on a quick Zoom?'",
                "PIP (Performance Improvement Plan) incoming...",
                "Slacking failed, back to the grind.",
                "Client: 'We need to pivot.'",
                "Out of office. Forever.",
                "Layoffs are coming...",
                "My mouse jiggler unplugged.",
                "Promoted to customer."
            ]
        case .ja:
            return [
                "サボりがバレた、始末書だ...",
                "社長：ちょっと会議室に来て",
                "ブラック企業から逃げられなかった",
                "ボーナスカット...",
                "お祈りメールが届きました",
                "残業確定...",
                "社畜に戻ります..."
            ]
        case .zh:
            return [
                "算了，我还是回去改PPT吧",
                "老板：你刚才在干嘛？",
                "这个月绩效没了...",
                "摸鱼失败，回去搬砖",
                "甲方：我觉得不行",
                "「咸鱼翻身」？翻了个面继续烤",
                "社畜的命运不可违抗",
                "系统检测到你在摸鱼，已扣工资",
                "离职？你舍得这份工资吗？",
                "梦想很丰满，现实很骨感"
            ]
        }
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Data Models
struct PlatformData {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    let h: CGFloat = GameConfig.platformHeight
    var type: PlatformType
    var bobOffset: CGFloat
    var vanishTimer: TimeInterval = 0
    var launchTimer: TimeInterval = 0
}

struct ObstacleData {
    var x: CGFloat
    var y: CGFloat
    var type: ObstacleType
    var bobOffset: CGFloat
    var startX: CGFloat
}

struct Particle {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var color: UIColor
    var life: CGFloat  // 0..1
    var size: CGFloat
}

struct Ripple {
    var x: CGFloat
    var y: CGFloat
    var r: CGFloat
    var maxR: CGFloat
    var alpha: CGFloat
}

struct Bubble {
    var x: CGFloat
    var y: CGFloat
    var r: CGFloat
    var speed: CGFloat
    var offset: CGFloat
}

struct DanmakuItem {
    var x: CGFloat
    var y: CGFloat
    var text: String
    var speed: CGFloat
    var lane: Int
}

struct ScorePopup {
    var x: CGFloat
    var y: CGFloat
    var text: String
    var color: UIColor
    var life: CGFloat
    var fontSize: CGFloat
}

struct DragonGate {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
    var alpha: CGFloat
    var spawnTime: TimeInterval
    var passed: Bool
    var particles: [Particle]
}

// MARK: - Persistence
struct LeaderboardEntry: Codable {
    let name: String
    let score: Int
    let date: String
}

class GamePersistence {
    static let shared = GamePersistence()

    private let highScoreKey = "sf_high_score"
    private let streakKey = "sf_streak"
    private let lastDateKey = "sf_last_date"
    private let mutedKey = "sf_muted"
    private let leaderboardKey = "sf_local_leaderboard"
    private let tutorialSeenKey = "sf_tutorial_seen"

    func getLocalLeaderboard() -> [LeaderboardEntry] {
        if let data = UserDefaults.standard.data(forKey: leaderboardKey),
           let list = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            return list
        }
        let defaultList = [
            LeaderboardEntry(name: Localized.string(zh: "摸鱼王老板", en: "CEO Boss", ja: "サボり社長"), score: 8000, date: ""),
            LeaderboardEntry(name: Localized.string(zh: "主管阿强", en: "Manager Qiang", ja: "マネージャー強"), score: 5000, date: ""),
            LeaderboardEntry(name: Localized.string(zh: "程序员阿飞", en: "Dev Fei", ja: "エンジニア飛"), score: 3200, date: ""),
            LeaderboardEntry(name: Localized.string(zh: "设计小美", en: "Designer Mei", ja: "デザイナー美"), score: 1800, date: ""),
            LeaderboardEntry(name: Localized.string(zh: "实习生小明", en: "Intern Ming", ja: "インターン明"), score: 600, date: "")
        ]
        saveLocalLeaderboard(defaultList)
        return defaultList
    }

    func saveLocalLeaderboard(_ list: [LeaderboardEntry]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: leaderboardKey)
        }
    }

    func submitLocalScore(_ newScore: Int, playerTitle: String) {
        var list = getLocalLeaderboard()
        let playerName = Localized.string(zh: "你 (\(playerTitle))", en: "You (\(playerTitle))", ja: "あなた (\(playerTitle))")
        
        list = list.filter { !$0.name.contains("你") && !$0.name.contains("You") && !$0.name.contains("あなた") }
        
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let newEntry = LeaderboardEntry(name: playerName, score: newScore, date: today)
        list.append(newEntry)
        
        list.sort { $0.score > $1.score }
        if list.count > 6 {
            list = Array(list.prefix(6))
        }
        saveLocalLeaderboard(list)
    }

    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: highScoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: highScoreKey) }
    }

    var streak: Int {
        get { max(1, UserDefaults.standard.integer(forKey: streakKey)) }
        set { UserDefaults.standard.set(newValue, forKey: streakKey) }
    }

    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: mutedKey) }
        set { UserDefaults.standard.set(newValue, forKey: mutedKey) }
    }
    
    var hasSeenTutorial: Bool {
        get { UserDefaults.standard.bool(forKey: tutorialSeenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tutorialSeenKey) }
    }

    var streakBonus: CGFloat {
        return min(0.5, CGFloat(streak - 1) * 0.05)
    }

    func checkDaily() {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        let lastDate = UserDefaults.standard.string(forKey: lastDateKey)

        if lastDate != today {
            if let last = lastDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                if let lastD = formatter.date(from: last),
                   let todayD = formatter.date(from: today) {
                    let diff = Calendar.current.dateComponents([.day], from: lastD, to: todayD).day ?? 0
                    if diff == 1 {
                        streak += 1
                    } else {
                        streak = 1
                    }
                }
            }
            UserDefaults.standard.set(today, forKey: lastDateKey)
        }
    }
}

// MARK: - Game Center Manager
class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()
    
    // Default leaderboard ID configured in App Store Connect
    private let leaderboardID = "sf_leaderboard_global"
    
    var isEnabled = false
    
    func authenticateLocalPlayer(presentingVC: UIViewController? = nil) {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { vc, error in
            if let targetVC = vc {
                let topVC = presentingVC ?? self.getRootViewController()
                topVC?.present(targetVC, animated: true)
            } else if localPlayer.isAuthenticated {
                self.isEnabled = true
                print("Game Center: Authenticated - \(localPlayer.displayName)")
            } else {
                self.isEnabled = false
                print("Game Center: Disabled - \(error?.localizedDescription ?? "No error")")
            }
        }
    }
    
    func submitScore(_ score: Int) {
        guard isEnabled && GKLocalPlayer.local.isAuthenticated else { return }
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Game Center: Failed to submit score: \(error.localizedDescription)")
            } else {
                print("Game Center: Score \(score) submitted successfully")
            }
        }
    }
    
    func showLeaderboard(presentingVC: UIViewController? = nil) {
        guard isEnabled && GKLocalPlayer.local.isAuthenticated else { return }
        
        let topVC = presentingVC ?? getRootViewController()
        guard let vc = topVC else { return }
        
        let gcVC = GKGameCenterViewController(state: .leaderboards)
        gcVC.gameCenterDelegate = self
        gcVC.leaderboardIdentifier = leaderboardID
        vc.present(gcVC, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    private func getRootViewController() -> UIViewController? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first?.rootViewController
        }
        return nil
    }
}
