# Pamodoro · macOS 菜单栏计时器

> 一个原生 macOS 菜单栏计时器：菜单栏常驻 **8-bit 像素图标 + 倒计时**，点开是贴合 macOS 设计语言的浮层面板。
> 纯 Swift（AppKit + SwiftUI），零第三方依赖，**不需要 Xcode 本体**，命令行 `swiftc` 直接编译出一个通用二进制 `.app`。

![菜单栏三态](Preview/menubar.png)

---

## 下载安装（只想用的话）

1. 打开 [Releases · latest](https://github.com/ne0-svg/pamodoro-menubar/releases/latest)
2. 在页面底部的 **Assets** 里点下载：
   - **`Pamodoro-v1.3.4-universal.dmg`**（推荐）：双击打开后，把 `Pamodoro.app` 拖进旁边的 `Applications` 文件夹
   - 或 `Pamodoro-v1.3.4-universal.zip`：解压后把 `Pamodoro.app` 拖进「应用程序」
3. 首次打开会被 Gatekeeper 拦下，提示「无法打开」或「已损坏，应移到废纸篓」——
   **这只是因为没有 Apple 开发者签名，文件是完整的，不是病毒**。放行方式：
   - **macOS 15 及以上**（右键「打开」这个旧办法已被苹果移除，只能走系统设置）：
     先在「访达 → 应用程序」里**双击** App 让它被拦一次 →
     打开 系统设置 → 隐私与安全性 → 滚到底部，点「**仍要打开**」→ 输密码
   - **macOS 14 及更早**：右键点 App → **打开** → 再点「打开」
   - 或者终端一行搞定：`xattr -dr com.apple.quarantine /Applications/Pamodoro.app`
4. 打开后不会出现在 Dock，只在屏幕右上角菜单栏（计时器图标 + 倒计时）

> 想开机自启：系统设置 → 通用 → 登录项 → 「登录时打开」选择 Pamodoro.app。

校验下载文件（可选）：

```bash
shasum -a 256 Pamodoro-v1.3.4-universal.dmg
# a34470ff8fa8768b0d28acebf14b5dd78801c9e96aa98f7fc79bb4dd743d3861

shasum -a 256 Pamodoro-v1.3.4-universal.zip
# d144ddff7ac345e9d317023d8588e156182ecc2482926fd74b07f09705613636
```

## 从源码构建

环境要求：macOS 13+、Xcode Command Line Tools（提供 `swiftc`）。

```bash
git clone https://github.com/ne0-svg/pamodoro-menubar.git
cd pamodoro-menubar
./run.sh            # 编译 + 启动，看屏幕右上角菜单栏
```

`build.sh` 会分别编译 arm64 与 x86_64 再 `lipo` 合成通用二进制；本机构建出来的
App 没有 quarantine 标记，双击不会被 Gatekeeper 拦。

只编译不启动：

```bash
./build.sh                  # 产物：Build/Pamodoro.app
open Build/Pamodoro.app
```

装进「应用程序」：

```bash
cp -R Build/Pamodoro.app /Applications/
open /Applications/Pamodoro.app
# 系统设置 → 通用 → 登录项 → 「登录时打开」选择 Pamodoro.app
```

## 界面

| 待机 | 计时中 |
| :---: | :---: |
| <img src="Preview/popover-light.png" width="260" /> | <img src="Preview/popover-running.png" width="260" /> |

| 暂停 | 休息中 |
| :---: | :---: |
| <img src="Preview/popover-paused.png" width="260" /> | <img src="Preview/popover-rest.png" width="260" /> |

深色模式会自动适配：

<img src="Preview/popover-dark.png" width="300" />

## 功能

- **菜单栏常驻倒计时**：计时状态是秒表图标 + `24:59`，休息状态换成冒热气的像素咖啡杯 + `4:10`
- **毫秒显示**：面板里秒后面跟两位毫秒（`29:13.99`，50fps 刷新）；状态栏仍只显示到秒
- **点击开面板**：环形进度、大号等宽时间、胶囊按钮；右键图标可直接退出
- **点击表盘**：直接点圆形表盘即可开始 / 暂停 / 继续（悬停时光标变手型、状态文字提示当前动作）
- **任意时长**：计时 / 休息都是 1–180 分钟，可直接键入任意数字；
  计时步进器每次 ±5 分钟，休息步进器每次 ±1 分钟
- **自动循环 + 循环次数**：一轮 = 一次计时 + 一次休息。开启自动循环后，休息结束自动进入下一轮，
  跑满「循环次数」（1–99，默认 4 轮）就自动停下，电脑开着也不会一直响；
  关闭自动循环则休息结束即停
- **结束提示音**：播放内置的 `Resources/pomo-chime.mp3`（约 6 秒），响度跟随系统输出音量；
  若音频缺失会自动退回合成的电子表蜂鸣（4000 Hz「滴滴。。」）
- **提示音不计时**：提示音期间计时暂停、下一阶段不启动，响完才开始（时长按音频实际长度自动适配）
- **点击音效**：所有按钮共用同一段 0.11 秒的短音（`Resources/click.wav`），音量固定为提醒音量的 30%
- **今日计数**：以北京时间 00:00 为一天的分界，跨天自动归零，无需重启
- **设置持久化**：写入 `UserDefaults`，重启后保留

## 使用说明

| 操作 | 说明 |
| --- | --- |
| 左键点图标 | 打开 / 收起面板 |
| 右键点图标 | 菜单：退出 |
| 面板主按钮 / 点表盘 | 开始计时 / 暂停 / 继续（每次点击都有短音反馈） |
| 重置 / 跳过 | 重置回待机；跳过当前阶段 |
| 自动循环 | 关掉后，一整轮（计时 + 休息）跑完自动停 |
| 循环次数 | 自动循环最多跑几轮（1–99），行内显示「已完成/上限」 |
| 重置计数 | 面板左下角，清零循环轮数与今日完成数，按钮会短暂显示「已重置」 |
| 提醒中 | 提示音期间计时暂停；点表盘 / 主按钮可跳过提醒立即开始 |
| 今日 N 个 | 每个完成的计时阶段 +1，北京时间零点清零 |
| 退出 | 面板右下角的胶囊按钮，点击响一声后退出 |

菜单栏图标位置：按住 `Cmd` 拖动即可排序或移除。

卸载：

```bash
pkill -x Pamodoro
defaults delete local.maxwell.pomodoro
rm -rf /Applications/Pamodoro.app
```

## 实现要点

- **状态栏**：`NSStatusItem` + 固定宽度（按两种像素图标里更宽的一档算），倒计时位数在
  `5:00` / `25:00` / `180:00` 之间变化都不会让 item 伸缩——否则锚定其上的面板会跟着左右跳。
- **状态栏图标**：计时态是 `StatusIcon` 用 `NSBezierPath` 画的秒表（表壳 + 表冠 + 指针，18pt），
  休息态是 8-bit 像素咖啡杯；两者都是模板图，浅色菜单栏黑、深色菜单栏白，点击高亮自动反相。
- **面板**：`NSPopover` + SwiftUI。`NSPopover` 自带的菜单栏定位会把面板顶出屏幕上沿
  （顶部被裁），因此另做了屏幕几何校正，把面板夹在图标正下方与可见区域内。
- **统一配色**：表盘与主按钮在任何状态都是「浅色底 + 强调色文字 + 细描边」，
  状态差异交给左上角运行灯（绿 = 计时中，红 = 暂停 / 待机）和进度环；深色模式换成深色底。
- **标题**：左上角 `Pamodoro` 做了刻字质感——深色字面 + 下缘高光 + 上缘暗影。
- **表盘液体**：`DialLiquid` 用 `TimelineView(.animation)` + `Canvas` 画一团**不规则的流动水银**——
  多边形路径按 2/3/5 阶正弦叠加做形变（±12%），整体缓慢漂移，旁边还有一颗绕行的卫星液滴；
  径向渐变 + 3pt 模糊让边缘柔化，高光跟随移动，深色模式自动降亮度。
- **计时状态机**：单一 `Timer`（20ms 间隔）驱动 `remaining`，毫秒由剩余时间直接算出；
  阶段切换集中在 `finishPhase()`，跨天归零用「下一个北京时间零点」的一次性 Timer 驱动。
- **提示音**：优先用 `AVAudioPlayer` 播放 bundle 里的 `pomo-chime.mp3`，取它的 `duration`
  来决定「响完再开始」的延时；没有音频文件时退回合成 WAV（老式电子表「滴滴。。」）。
- **点击音效**：从提示音里截出 0.11 秒的极短尾音（`Resources/click.wav`），
  所有按钮共用，音量 30%；素材缺失时退回合成的 90ms「啪嗒」。
- **初始化**：先读出全部 `UserDefaults` 再统一赋值，并用 `isLoading` 标记挡掉初始化期间的
  `didSet` 回写，防止启动时把用户设置覆盖成默认值。
- **分发**：`build.sh` 分别编译 `arm64` 与 `x86_64`，用 `lipo` 合成通用二进制，
  再 ad-hoc 签名打包（zip / dmg）发 Release（因此未公证，首次打开需要手动放行）。

## 目录结构

```
.
├── Sources/
│   ├── main.swift            # AppDelegate：状态栏 item、popover、调试钩子
│   ├── PamodoroEngine.swift  # 计时状态机 + 持久化 + 每日归零
│   ├── PopoverView.swift     # SwiftUI 面板
│   ├── DialLiquid.swift      # 表盘里的水银液体
│   ├── PixelIcon.swift       # 8-bit 像素图标（咖啡杯）
│   ├── StatusIcon.swift      # 菜单栏图标（秒表 / 咖啡杯）
│   ├── SoundFX.swift         # 按钮点击音
│   └── WatchBeep.swift       # 结束提示音（含合成兜底）
├── Resources/
│   ├── AppIcon.icns          # App 图标
│   ├── AppIcon-1024.png      # 图标预览
│   ├── pomo-chime.mp3        # 结束提示音（缺失时退回合成蜂鸣）
│   └── click.wav             # 0.11s 短音，所有按钮点击共用
├── Preview/                  # README 用的界面截图
├── Scripts/make-icon.swift   # 图标绘制脚本
├── Info.plist                # LSUIElement=true（只驻留菜单栏）
├── build.sh                  # 编译 arm64 + x86_64 → lipo → 签名
├── run.sh                    # build + open
└── LICENSE                   # MIT
```

## 调试

```bash
# 状态栏 item 是否挂载、标题是否在走
POMODORO_DEBUG=1 POMODORO_DEBUG_START=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro

# 离屏渲染面板与状态栏截图（不需要屏幕录制权限）
POMODORO_SNAPSHOT=/tmp/snap ./Build/Pamodoro.app/Contents/MacOS/Pamodoro
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_RUNNING=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_PAUSED=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_REST=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_APPEARANCE=dark ./Build/Pamodoro.app/Contents/MacOS/Pamodoro

# 连拍两帧，用于验证液体动效确实在跑
POMODORO_SNAPSHOT=/tmp/snap POMODORO_SNAPSHOT_TWICE=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro

# 面板窗口 / 屏幕几何
POMODORO_DEBUG_POPOVER=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro

# 验证蜂鸣节奏；导出合成音频
POMODORO_DEBUG=1 POMODORO_DEBUG_CHIME=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro
POMODORO_DUMP_BEEP=/tmp/watchbeep.wav ./Build/Pamodoro.app/Contents/MacOS/Pamodoro

# 验证自动循环（开 / 关）
POMODORO_DEBUG=1 POMODORO_DEBUG_LOOP=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro

# 验证跨天归零
POMODORO_DEBUG=1 POMODORO_DEBUG_ROLLOVER=1 ./Build/Pamodoro.app/Contents/MacOS/Pamodoro
```

## 其他实现方案

不想维护一个 App 的话，也可以用宿主程序的插件机制：

| 方案 | 形态 | 语言 | 适合 |
| --- | --- | --- | --- |
| 本项目（原生 App） | 独立菜单栏 App | Swift | 想长期用、要通知 / 声音 / 设置 |
| SwiftBar / xbar | 菜单栏脚本插件 | Shell / Python / JS | 十几行脚本快速出效果 |
| Übersicht | 桌面小组件 | JSX | 挂在桌面而不是菜单栏 |
| Hammerspoon | 菜单栏 + 全局快捷键 | Lua | 想和窗口管理联动 |
| Raycast 扩展 | 独立窗口 | TS / React | 想要搜索式交互 |

## 已知限制

- 用 ad-hoc 签名（`codesign --sign -`），未公证，仅本机使用；分发需开发者证书。
- 计时进度不跨进程保存：重启 App 回到待机状态，今日计数保留。
- 面板用 SwiftUI，最低 macOS 13。

## 许可证

[MIT](LICENSE) © 2026 ne0-svg
