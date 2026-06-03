# 🐟 Tiny Buff - iOS Native

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat-square)](https://developer.apple.com/swift/)
[![SpriteKit](https://img.shields.io/badge/SpriteKit-iOS_16.0+-blue.svg?style=flat-square)](https://developer.apple.com/documentation/spritekit)
[![UIKit](https://img.shields.io/badge/UIKit-Native-green.svg?style=flat-square)](https://developer.apple.com/documentation/uikit)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat-square)](LICENSE)

> **带薪摸鱼，锦鲤翻身！** 
> 原生 iOS 版本的「Tiny Buff」休闲弹射跳跃游戏，基于微信小程序原版游戏逻辑及物理手感进行高精度原生复刻与手感优化。

---

## 🎯 游戏核心手感与物理对标优化

> [!IMPORTANT]
> 本版本经历了深度细节调校，将原生 iOS 的 **SpriteKit** 物理循环与原版微信小程序（Canvas Isomorphic Engine）的逐帧经典手感进行了 1:1 的完美对齐，解决了原移植版“蓄力粘滞”、“判定严格”、“空飘感强”等体验痛点。

### ⚡ 蓄力与轨迹体验 (Controls & Aiming)
* **蓄力速率对齐**：修复了原 App 错误地将时间缩放（Slow-Motion）乘入蓄力速率的 Bug，将原本拖沓的 **3.4秒** 蓄力时间校准回与微信版一致的 **1.2秒**，操作干净利落。
* **5倍精准抛物线**：辅助预测线从极短的 14 帧距离提升至 **80 帧（5倍以上延伸）**，并完美同步 **HSL 动态颜色过渡**（绿色 → 黄色 → 红色）和粒子渐细、流水线滑动动效，彻底消除盲跳感。
* **土狼容错时间 (Coyote Time)**：咸鱼滑出台阶边缘或滑行跳台坠落时，拥有 **150ms 缓冲保护期**。在缓冲期内仍可进行蓄力与弹跳，同时提供下沉视觉反馈，给予极限操作下的完美操作感。

### 💥 撞击与震屏特效 (Recoil & Impact)
* **弹射后坐力震屏**：松手发射的一瞬间，镜头将反向产生一个与弹射力（Power）成正比的**单向后坐力推力**，并在之后的数帧中以 `0.88` 的阻尼指数高速微震衰减，充满弹射力量感。
* **着陆撞击力学**：落地震动直接取决于着陆前的瞬时速度 `preImpactVy`（Perfect 时震屏更强），配合水波纹扩散和粒子喷射，给予绝佳的重力打击感。
* **连击堆叠规则**：完美对齐微信小程序的 Combo 连击加法。当一次飞跃跨越多个跳台时，连击数直接累加跨越数（Perfect 连击 `+skipped + 1`），让得分 progression 完全符合原版的精细设计。

### 👾 动态障碍与警戒射线 (Obstacles & Sweep Beam)
* **圆形半径判定**：摒弃了硬直的 AABB 轴向碰撞矩形，使用更为宽容和真实的 **圆形距离碰撞（Radius = 22px）**。
* **物理下坠反馈**：受击后不再无理地向上反弹和疯狂扣分（移除了扣除 50 分的挫败体验），而是完全对齐原版的**向下坠落、速度减半**（VX 砍半，VY 增加），把危险转嫁到“落水危机”的玩法节奏上。
* **移动扫射红外线**：全面重构 Boss 监视器的攻击判定。Boss 眼睛动态偏转，其红外扫射光束以正弦弧度**在屏幕底部大范围左右扫掠**，一旦咸鱼在光束的垂直范围内暴露，即刻被老板逮捕下坠。

---

## 🎨 视觉与外观重绘 (Aesthetics & Fins)

> [!TIP]
> 针对 iOS 早期版本“鱼鳍位置突兀、极易误认为鱼身反转”的视觉瑕疵，对咸鱼进行了重构绘制，呈现出更加丰满的 upright 鱼类形态：

```
                    .-----.
                   /       \____  __ <---- Horns (Lv6+)
                  /  O   __     \/  \
     Dorsal Fin --> /_  (..)  __  |  \
                 /   \       /  \ \   \ <---- Whiskers (Lv2+)
                |     '-----'    \ \__/
                 \              / \__/ <---- Tail Wave Anim
      Pelvic Fin --> \_  ______/
                       \____/
```

1. **正立双鳍布局**：
   * **主背鳍 (Dorsal Fin)**：在鱼背上方 (y 坐标上方) 绘制了高亮半透背鳍，高耸指向斜后方。
   * **小腹鳍 (Pelvic Fin)**：在鱼腹下方绘制了小巧的斜向后腹鳍，彻底确立了“背上腹下”的 upright 正立空间感。
2. **三维玻璃体高光**：在咸鱼脊部上方引入了 `0.15` 透明度的白色渐变曲面高光，营造 2D 赛博霓虹风格的半透亮玻璃质感。
3. **动态摆动鱼尾**：鱼尾不再是死板的三角形，而是基于 `sin(time)` 正弦公式以不同相位和阻尼动态摇摆（待机、蓄力、飞越时均呈现不同的游泳身姿）。
4. **等级视觉 Progression**：
   * **LV.2**：长出动态偏折的胡须。
   * **LV.4**：生成围绕全身的霓虹发光环。
   * **LV.5**：添加双层防护轨道圈以及 6 个随时间公转的轨道亮斑粒子。
   * **LV.6**：鱼头上长出亮粉色的龙角。
   * **LV.7 (MAX)**：尾部会拖出 5 圈随游动波动渐隐的环状气泡粒子轨道，并触发龙门关卡。

---

## 🛠️ 技术栈

* **开发语言**：Swift 5.10
* **核心框架**：SpriteKit (2D 物理与时间驱动)
* **界面框架**：SwiftUI (UI 组件、高阶视图状态同步)
* **画布绘制**：Core Graphics (CGContext 二维矢量实时硬件加速渲染)
* **声效合成**：AVAudioEngine (利用三角波、低频振荡器实时算力合成音效，完全不依赖外置 wav 静态文件)
* **触觉马达**：UIImpactFeedbackGenerator (Taptic Engine 级微秒段震动反馈)
* **系统要求**：iOS 16.0+

---

## 📂 核心代码架构

```
SaltedFishApp/
├── SaltedFishAppApp.swift       # SwiftUI App 引导入口
├── ContentView.swift            # 游戏视图容器与 SwiftUI 数据流绑定
├── Info.plist                   # iOS 权限及基础打包配置
├── Assets.xcassets/             # 图标及静态 UI 贴图资源
└── Game/
    ├── GameConfig.swift         # 物理常数、色彩代号、等级定义与数据模型
    ├── GameScene.swift          # SpriteKit Scene 生命周期及关卡重置管理
    ├── GameScene+Update.swift   # 核心物理帧更新循环（蓄力、土狼时间、弹簧落点、碰撞检测）
    ├── GameScene+Touch.swift    # 用户多指滑动与蓄力拖拽输入解包
    ├── GameScene+Render.swift   # 水面、网格、背景与静态/动态障碍物的高性能矢量绘制
    ├── GameScene+RenderUI.swift # 咸鱼主体、3D 高光、发光轨道、粒子尾迹、HUD 及蓄力轨迹线绘制
    ├── AudioManager.swift       # 基于原生音频总线的频率滑移（Ramp）实时合成器
    └── CalculatorView.swift     # 极度逼真的计算器伪装界面（防老板突击检查模式）
```

---

## 🚀 编译与调试

1. 确保您的 Mac 已经安装 **Xcode 15.0** 或以上版本。
2. 打开终端，克隆或进入项目工作目录：
   ```bash
   cd "/Users/kresnikwang/Work/skand games/saltedfishapp"
   ```
3. 使用 Xcode 打开项目：
   ```bash
   open SaltedFishApp.xcodeproj
   ```
4. 连接您的 iPhone 真机或选择模拟器设备（例如 `iPhone 15 Pro`）。
5. 按下 **Cmd + R** (⌘R) 即可编译运行并开始摸鱼。

---

## 📄 开源许可

本项目基于 MIT 协议开源，项目代码基于 Web 开源项目 [saltedfish](https://github.com/kresnikwang/saltedfish) 深度移植和优化。
