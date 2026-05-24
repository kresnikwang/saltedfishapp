# 鱼来运转 (SaltedFish App) - iOS Native

原生 iOS 版本的「鱼来运转」休闲跳跃游戏，基于原版 Web/微信小游戏完整复刻。

## 功能特性

### 核心玩法
- 按住屏幕蓄力，拖动调整方向，松手跳跃
- 8种平台类型（普通/会议/客户/喝茶/弹射/消失/滑行/老板）
- 4种障碍物（海草/螃蟹/PRD文档/老板监控）
- 连击系统 & 完美着陆加分
- 7级进化体系（咸鱼形态 → 离职神龙）
- 龙门彩蛋（满级触发）

### 特色功能
- 计算器伪装模式（按🧮隐藏游戏）
- 弹幕系统（职场梗滚动文字）
- 咸鱼吐槽气泡
- 输入缓冲（空中预按下一跳）
- 连续签到奖励
- 触觉反馈

### 视觉效果
- 霓虹绿色系赛博朋克风格
- 粒子爆发 & 水波纹
- 屏幕震动
- 鱼身变形动画（蓄力挤压/着陆弹跳）
- 动态背景网格 & 水面

### 音效系统
- 实时合成音效（AVAudioEngine）
- 跳跃/着陆/连击/受击/完美着陆/游戏结束
- 蓄力持续音效
- 静音开关

## 技术栈

- **语言**: Swift 5
- **框架**: SpriteKit + SwiftUI
- **渲染**: Core Graphics (CGContext) 自定义绘制
- **音频**: AVAudioEngine 实时合成
- **触觉**: UIImpactFeedbackGenerator
- **最低支持**: iOS 16.0

## 项目结构

```
SaltedFishApp/
├── SaltedFishAppApp.swift       # App 入口
├── ContentView.swift            # 主 SwiftUI 视图
├── Info.plist                   # 应用配置
├── Assets.xcassets/             # 资源目录
└── Game/
    ├── GameConfig.swift         # 常量、数据模型、配置
    ├── GameScene.swift          # 主游戏场景
    ├── GameScene+Update.swift   # 游戏循环更新逻辑
    ├── GameScene+Touch.swift    # 触摸输入处理
    ├── GameScene+Render.swift   # 背景、平台、障碍物渲染
    ├── GameScene+RenderUI.swift # 鱼、HUD、UI界面渲染
    ├── AudioManager.swift       # 音效合成管理
    └── CalculatorView.swift     # 计算器伪装模式
```

## 使用方法

1. 用 Xcode 15+ 打开 `SaltedFishApp.xcodeproj`
2. 选择目标设备（iPhone 模拟器或真机）
3. 点击 Run (⌘R) 即可运行

## 致谢

基于 [saltedfish](https://github.com/kresnikwang/saltedfish) Web 版本移植。
