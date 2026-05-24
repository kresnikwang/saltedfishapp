import Foundation
import UIKit

// MARK: - Physics Constants
struct GameConfig {
    static let gravity: CGFloat = 0.35
    static let maxPower: CGFloat = 18.0
    static let chargeRate: CGFloat = 0.25
    static let platformMinGap: CGFloat = 60.0
    static let platformMaxGap: CGFloat = 160.0
    static let fishWidth: CGFloat = 40.0
    static let fishHeight: CGFloat = 28.0
    static let platformHeight: CGFloat = 14.0
    static let slowMotionScale: CGFloat = 0.35
    static let cancelZoneRatio: CGFloat = 0.15
    static let perfectLandingZone: CGFloat = 0.15
    static let perfectMultiplier: CGFloat = 1.8
    static let baseScore: Int = 100
    static let comboMultiplierStep: CGFloat = 0.1
    static let inputBufferWindow: TimeInterval = 0.3
    static let cameraLerpFactor: CGFloat = 0.12
    static let cameraBaseOffset: CGFloat = 0.3  // fraction of screen width

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
        case .normal:  return "摸鱼"
        case .meeting: return "会议"
        case .client:  return "见客"
        case .tea:     return "喝茶"
        case .spring:  return "弹射"
        case .vanish:  return "消失"
        case .slide:   return "滑行"
        case .boss:    return "老板"
        }
    }
}

// MARK: - Obstacle Types
enum ObstacleType: String {
    case seaweed, crab, doc, boss
}

// MARK: - Level Config
struct LevelConfig {
    let name: String
    let threshold: Int
    let color: UIColor
    let jumpBonus: CGFloat
    let desc: String
}

let gameLevels: [LevelConfig] = [
    LevelConfig(name: "咸鱼形态", threshold: 0, color: UIColor(hex: "#888888"), jumpBonus: 0, desc: "LV.01 咸鱼形态"),
    LevelConfig(name: "摸鱼学徒", threshold: 1000, color: UIColor(hex: "#aa7700"), jumpBonus: 0.06, desc: "LV.02 摸鱼学徒"),
    LevelConfig(name: "锦鲤本鲤", threshold: 2500, color: UIColor(hex: "#ffaa00"), jumpBonus: 0.13, desc: "LV.03 锦鲤本鲤"),
    LevelConfig(name: "职场海王", threshold: 5000, color: UIColor(hex: "#dd5500"), jumpBonus: 0.21, desc: "LV.04 职场海王"),
    LevelConfig(name: "老油条", threshold: 10000, color: UIColor(hex: "#ff6600"), jumpBonus: 0.30, desc: "LV.05 老油条"),
    LevelConfig(name: "隐形高手", threshold: 20000, color: UIColor(hex: "#cc3366"), jumpBonus: 0.40, desc: "LV.06 隐形高手"),
    LevelConfig(name: "离职神龙", threshold: 35000, color: UIColor(hex: "#ff0066"), jumpBonus: 0.52, desc: "MAX 离职神龙"),
]

// MARK: - Game Texts
struct GameTexts {
    static let fishQuips = [
        "玩完这把就去开会了", "好想下班...", "假装很忙.jpg",
        "今天也是摸鱼的一天", "摸鱼5分钟，快乐2小时", "又在划水了",
        "老板别过来！", "发工资了吗？", "佛系打工中..."
    ]

    static let danmakuTexts = [
        "摸鱼使我快乐", "老板又开会了...", "今天的KPI完成了吗？",
        "带薪拉屎中", "这个需求做不了", "明天再说吧", "工资到账了吗",
        "加班是不可能加班的", "又到了摸鱼时间", "甲方改了第18版",
        "今天周五吗？", "摸鱼才是真生产力", "996是福报？", "00后整顿职场",
        "请假被拒了", "下班倒计时", "开始摆烂", "佛系打工",
        "月薪三千操碎了心", "外包比我还卷"
    ]

    static let deathQuotes = [
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
class GamePersistence {
    static let shared = GamePersistence()

    private let highScoreKey = "sf_high_score"
    private let streakKey = "sf_streak"
    private let lastDateKey = "sf_last_date"
    private let mutedKey = "sf_muted"

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
