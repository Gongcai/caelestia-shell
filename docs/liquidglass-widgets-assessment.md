# Liquid Glass 桌面小组件移植评估

评估日期：2026-09-14。上游版本固定为
[`ff196b4`](https://github.com/jaxparrow07/liquidglass-kde-widgets/tree/ff196b4a688eccc7c8c858b3d53a76d8e7055719)。

结论：可以移植为 Caelestia 的原生桌面小组件。双方使用 Qt Quick / Qt 6；上游的玻璃材质由 QML 和 Qt 着色器实现，核心渲染可以脱离 Plasma 运行。应保留其材质、布局和动画，接入本项目的宿主、配置与数据服务。

按本次需求，日历只保留日期网格、月份切换和今天标记等现有 dashboard 日历能力，重点还原视觉效果。Akonadi、账号同步、日程列表、提醒和日历插件设置均不在范围内。

## 第一批接入

第一批实现包含数字玻璃时钟、指针玻璃时钟、基础玻璃日历，以及共用的玻璃材质。入口为 Nexus 的“壁纸与样式 → 桌面小组件”。

- 时钟样式可选择“经典”“玻璃数字时钟”“玻璃指针时钟”。已有配置继续默认使用经典样式。
- 日历独立启用；左右箭头翻月，点击月份标题回到今天。日期格式随界面语言变化。
- 各屏幕可分别设置位置、缩放与玻璃材质，也可恢复全局设置。玻璃不透明度为 0–100%，折射强度为 0–200%，磨砂可独立关闭。
- 长按卡片空白区域移动；日历按钮保留普通点击。组件改变大小时会将位置约束到屏幕内。
- 每块屏幕共用一次壁纸采样。图片加载和过渡、视频壁纸、背景频谱均可使采样更新；静态状态下采样和局部模糊链停止刷新。游戏模式或关闭透明效果时使用纯色回退。

对应配置示例：

```json
{
  "background": {
    "desktopClock": { "enabled": true, "style": "digital", "showSeconds": false },
    "desktopCalendar": { "enabled": true, "position": "top-right", "scale": 1.0 },
    "desktopGlass": { "opacity": 0.3, "blur": true, "refraction": 1.0 }
  }
}
```

玻璃材质遵循现有 `appearance.transparency.enabled` 开关。`desktopClock.style` 的有效值为 `classic`、`digital`、`analog`。

新增入口和公共组件位于 `modules/background/widgets/`；材质封装位于 `components/effects/DesktopGlass.qml` 和 `KawaseBlur.qml`。字体、图标和数据源使用本项目已有资源；上游来源记录随 `assets/third-party/liquidglass-kde-widgets.txt` 一起安装。

已完成配置模块与着色器编译、修改文件的 qmllint / 格式 / QML 约定检查，并在真实 Quickshell 的隔离窗口中验证了 1.0 和 1.6 倍缩放、日历按钮、跨年和闰年日期、拖动坐标与缩放、配置继承与重置、两种时钟切换、图片壁纸切换、视频实时采样以及游戏模式回退。后文保留初始评估过程和后续组件的适配建议。

本机插件已安装并在实际双屏桌面加载。首次接入时还复现并修复了一个异步初始化问题：`MonthGrid` 的日期 delegate 可能在其尺寸分配之后创建，宽度保持为 0，导致只有月份和星期行可见。日期格子现在显式绑定可用区域的七列六行尺寸；延迟创建、重新启用、0.5–2 倍组件大小与 1.0／1.6 倍屏幕缩放均已验证，实际桌面截图确认日期正常显示。

## 第二批接入

新增天气、音乐、世界时钟和倒计时四类小组件，继续使用相同的玻璃材质、壁纸采样与长按拖动宿主。入口仍为“壁纸与样式 → 桌面小组件”，可分别选择屏幕、启用、调整大小和位置，以及恢复全局设置。新增组件默认关闭。

| 组件 | 布局与功能 | 数据来源 |
| --- | --- | --- |
| 天气 | 紧凑、横版、完整预报；实时天气、6 小时／5 日预报、温度范围与刷新 | 现有 `Weather` 服务；沿用天气位置及摄氏／华氏设置 |
| 音乐 | 横版、紧凑横条、竖版；封面、播放／暂停、切歌、进度、歌词翻转、多播放器切换 | 现有 `Players` / MPRIS 与 `Lyrics` 服务；不支持的控制自动禁用 |
| 世界时钟 | 1–4 座城市；数字刻度、简洁、四分刻度及数字显示；昼夜表盘、时差和跨日提示 | `Time` 与新增 Qt `QTimeZone` 适配，支持夏令时及非整点时区 |
| 倒计时 | 分／秒滚轮、开始、暂停、继续、取消、完成提示；横版提供 1／5／10／15／25 分钟预设 | 每屏独立的 `DesktopTimers` 与现有 `Toaster` |

世界时钟设置提供 32 个常用城市，也可在 `timeZones` 中填写系统支持的 IANA 时区 ID；空列表显示本地时间，无效时区显示未知状态。倒计时最长为 99 分 59 秒：隐藏组件或 QML 热重载后仍保留运行／暂停状态，到时提示一次；退出或重启 shell 后清空。倒计时不涉及日历日程，基础日历的范围保持不变。

配置示例：

```json
{
  "background": {
    "desktopWeather": { "enabled": true, "layout": "forecast" },
    "desktopMusic": { "enabled": true, "layout": "wide" },
    "desktopWorldClock": {
      "enabled": true,
      "style": "numbered",
      "timeZones": ["Asia/Shanghai", "Europe/London", "America/New_York", "Asia/Tokyo"]
    },
    "desktopTimer": { "enabled": true, "wide": true, "duration": 300 }
  }
}
```

`desktopWeather.layout` 为 `compact`、`wide`、`forecast`；`desktopMusic.layout` 为 `compact`、`wide`、`tall`；`desktopWorldClock.style` 为 `numbered`、`minimal`、`quarters`、`digital`。四类组件均支持 `position`、`scale`、`offsetX`、`offsetY`，并共用 `desktopGlass`。

已完成 Config／Services 插件编译、Qt 6 qmllint、格式与 QML 约定检查，以及真实 Quickshell 中的隔离集成验证：覆盖 1.0／1.6 倍屏幕缩放、布局切换、天气单位与空状态、播放和切歌、进度控制、歌词实际显示、时区夏令时切换、滚轮鼠标／键盘操作、长按移动、按屏配置与重置、隐藏倒计时到时提醒，以及运行／暂停／完成状态的热重载恢复。测试数据使用本地天气、播放器和歌词样本；外部天气请求和媒体应用的支持情况沿用已有服务。

验证时修正了 `Lyrics.hasLyrics` 的变更通知，使歌词加载与清空后画面及时更新；倒计时持久属性使用 JSON 字符串在热重载的 QML 引擎之间传递，避免 JavaScript 对象失效。

第二批已安装到本机并成功重载，保留原有屏幕配置。运行中的 shell 已加载更新后的 Config／Services 插件，安装后的 QML 检查通过，启动日志中没有新增组件错误。

## 已验证的渲染路径

上游核心文件：

- [`LiquidGlass.qml`](https://github.com/jaxparrow07/liquidglass-kde-widgets/blob/ff196b4a688eccc7c8c858b3d53a76d8e7055719/1-common/components/LiquidGlass.qml)：壁纸采样、局部裁切、Dual Kawase 模糊、鼠标高光及静态缓存。
- [`liquidglass.frag`](https://github.com/jaxparrow07/liquidglass-kde-widgets/blob/ff196b4a688eccc7c8c858b3d53a76d8e7055719/1-common/components/shaders/liquidglass.frag)：超椭圆圆角、边缘折射、色散和高光。

独立实验只做两项宿主适配：移除 `org.kde.plasma.plasmoid` 导入，将从 `Plasmoid.containment.wallpaperGraphicsObject` 查找壁纸改为由调用方传入 `wallpaperItem`。玻璃着色器保持上游源码。

在本机 Qt 6.11.2、Xvfb、OpenGL 软件渲染环境下，重新编译 `crop`、`kawase_down`、`kawase_up`、`liquidglass` 四个着色器并运行成功：

- 清晰折射与磨砂折射均实际出图；关闭折射后图像存在可测的像素差异。
- 卡片移动后，壁纸采样坐标随之更新。
- 开启实时采样后，背景颜色变化能传递到磨砂卡片。
- 使用 Qt `MonthGrid` 的日期网格正常显示；最终测试没有 QML 或着色器警告。

临时实验文件及截图位于 `/tmp/liquidglass-kde-review.5GnvNl/probe/`。这是接入前的独立实验记录；第一批接入后的验证结果见上文。

## 组件与现有能力的对应

| 组件 | 可保留的视觉部分 | 本项目接入点 | 主要适配 |
| --- | --- | --- | --- |
| 数字／模拟时钟 | 表盘、刻度、数字布局、玻璃背景 | [Time.qml](../services/Time.qml) | 用统一时间服务替代各组件自己的轮询 |
| 日历 | 月份标题、星期行、日期网格、今天标记 | [dashboard 日历](../modules/dashboard/dash/Calendar.qml) 的 `MonthGrid` / `DayOfWeekRow` | 提取日期状态与展示；去掉上游日程后端 |
| 天气 | 温度、天气图标、小时与多日预报布局 | [Weather.qml](../services/Weather.qml) | 映射现有天气数据；共用位置与温度单位配置 |
| 音乐 | 封面、翻转动画、播放控制、不同宽高布局 | [Players.qml](../services/Players.qml)、现有歌词服务 | 替换 KDE 私有 MPRIS 模型；桌面频谱沿用原有独立组件 |
| 世界时钟 | 多城市表盘和布局 | `Time` 与 [timezones.cpp](../plugin/src/Caelestia/Services/timezones.cpp) | 用 Qt 时区转换替代 `org.kde.plasma.clock` |
| 倒计时 | 滚轮、倒计时、按钮与预设布局 | [DesktopTimers.qml](../services/DesktopTimers.qml) 与现有提示机制 | 替换 KDE 通知和面板宿主 |

上游的设置页依赖 Kirigami 和 Plasma 配置，适合在 Nexus 内按现有设置控件重新接入。字体与颜色使用本项目的 `Tokens`、`Colours` 和现有图标资源。

## 在项目中的落点

1. 新增桌面组件共用的玻璃背景组件，接入上游核心着色器。保留现有 [BackdropGlass.qml](../components/effects/BackdropGlass.qml) 的锁屏用途，避免改变已验证的锁屏材质。
2. 从 [Background.qml](../modules/background/Background.qml) 传入 `behindClock`。它已经包含图片／视频壁纸，且不包含桌面组件本身，适合在同一个 Qt 场景里作为玻璃采样源。
3. 在 [DesktopWidgets.qml](../modules/background/widgets/DesktopWidgets.qml) 增加组件 Loader，并扩展背景窗口的输入区域。
4. 在 [backgroundconfig.hpp](../plugin/src/Caelestia/Config/backgroundconfig.hpp) 与 [DesktopWidgetsPage.qml](../modules/nexus/pages/wallandstyle/DesktopWidgetsPage.qml) 接入启用、位置、大小、玻璃样式及各屏幕配置。
5. 着色器通过现有 [Caelestia.Blobs 构建](../plugin/src/Caelestia/Blobs/CMakeLists.txt) 编译为 `.qsb`，使用项目资源路径加载。

桌面组件与壁纸目前处于同一个窗口，直接采样壁纸符合其结构。现有 Hyprglass 面板效果处理合成器窗口背景，不能直接替代同一窗口内部的壁纸采样。

## 接入时需要处理的细节

- **点击与拖动：** [WidgetLoader.qml](../modules/background/widgets/WidgetLoader.qml) 的最上层 `MouseArea` 覆盖整个组件并接收左键。需要调整手势处理，兼容组件移动、日历翻页和音乐控制。
- **采样坐标：** 上游通过定时器检测位置；本项目可直接利用 Loader 的位置和拖动偏移。还需纳入拖动时的 `1.03` 缩放，确保玻璃采样与卡片几何一致。
- **刷新策略：** 静态壁纸按需刷新，壁纸切换应使缓存失效；视频壁纸才连续采样，并接入 `GameMode`。避免每张卡片独立维持全屏纹理和持续工作的模糊链。
- **缺失背景：** 关闭本项目壁纸或背景尚未加载时，使用可读的底色回退。
- **内容清晰度：** 模糊与折射只作用于背景；文字、刻度和按钮作为前景绘制。
- **资源来源：** 双方仓库的根 LICENSE 均为 GPL-3.0，复用代码保留来源与相关声明。上游 README 对所带 Apple 字体和图标另有限制，移植时使用本项目已有资源。

两批接入已覆盖时钟、基础日历、天气、音乐、世界时钟和倒计时。上游的测试组件及 KDE 面板宿主不纳入当前移植。
