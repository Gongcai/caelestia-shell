# macOS 风格 UI 改造规划

状态：实施中（阶段 0～3 首批完成，正在做场景回归）

当前进度（2026-09-13）：主题基础层和公共控件换肤已完成，Dashboard、QuickPanel、Sidebar、Control Center、Nexus、Session、通知、文件对话框、WindowInfo 和锁屏已完成首批页面层统一。原始 scheme 仍作为输入保留，页面继续通过原有 `m3...` 属性名取色；Material Symbols 仍作为兼容图标层，OSD 继续复用已换肤的公共滑块，媒体可视化和 LoadingIndicator 等动态装饰形状暂时保留。

已验证：当前工作树可在运行中的 Hyprland 0.56.2 会话加载，两个显示器、Dashboard、Launchpad、QuickPanel、Sidebar、Nexus 和锁屏相关页面均可渲染并保留现有页面动画。

## 1. 目标

在不改变 Caelestia Shell 现有布局、功能和交互结构的前提下，将 Material 3 视觉语言替换为现代 macOS 风格。

本次改造的目标是让现有的启动台、控制中心、Dashboard、侧边栏、通知和设置页面看起来像同一套 macOS-like 桌面 UI，而不是引入另一套 Shell。

需要保留：

- 现有模块布局、窗口位置和打开方式；
- 现有业务逻辑、服务、IPC 和配置结构；
- `Anim.qml`、`CAnim`、`AnchorAnim` 以及现有动画触发时机；
- 现有的透明度、壁纸取色、模糊和多屏行为；
- 用户已经配置的尺寸、字体和透明度选项（除非明确迁移）。

## 2. 非目标

本次不实现以下 macOS 功能：

- Dock、顶部菜单栏、全局菜单、Notch、Stage Manager；
- macOS 窗口管理行为或应用生命周期；
- Finder、Spotlight、Control Center 等新功能模块；
- 业务服务重写或后端替换；
- 打包 Apple 专有字体、SF Symbols 或其他未授权资源。

目标是“macOS 设计语言”，不是完整模拟 macOS 桌面。

## 3. 当前代码基线

项目的视觉系统已经有可复用的公共入口：

| 位置 | 当前职责 | 改造策略 |
| --- | --- | --- |
| [`services/Colours.qml`](../services/Colours.qml) | Material 3 颜色角色、透明度和壁纸亮度处理 | 保留现有属性兼容层，替换其实际颜色和表面映射 |
| [`plugin/src/Caelestia/Config/tokens.hpp`](../plugin/src/Caelestia/Config/tokens.hpp) | 圆角、间距、字号、动画时长 | 保留动画 Token，增加或调整 macOS 几何 Token |
| [`plugin/src/Caelestia/Config/appearanceconfig.hpp`](../plugin/src/Caelestia/Config/appearanceconfig.hpp) | 字体族和文字层级 | 移除 Google Sans 的默认依赖，使用 Linux 可分发字体和回退链 |
| [`components/Anim.qml`](../components/Anim.qml) | 标准、强调和 expressive 动画 | 保留 API、时长和曲线，必要时只调整控件内部的视觉反馈 |
| [`components/StateLayer.qml`](../components/StateLayer.qml) | Hover、Pressed、ripple 和点击状态 | 保留信号与交互 API，去掉 Material ripple，改为 macOS 式高亮/按压反馈 |
| [`components/StyledRect.qml`](../components/StyledRect.qml) | 通用矩形表面 | 保留组件，统一表面色、边框和圆角来源 |
| [`components/controls/`](../components/controls) | 按钮、菜单、输入框、开关、滑块等公共控件 | 第一优先级重做，尽量不改变调用方属性 |

项目约有 303 个 QML 文件。颜色、Token、Material 图标和公共组件的引用分布较广，因此不采用大规模改名或逐页面重写。

## 4. 参考项目与使用边界

### 4.1 参考项目

| 项目 | 许可证 | 用途 | 结论 |
| --- | --- | --- | --- |
| [Golden Gate Shell](https://github.com/KGobikrishnan/Goldengate-mac-mod-Theme) | 仓库未声明许可证 | Qt/QML 控制中心、Toggle、滑块、菜单和通知的几何参考 | 只看截图和设计；不直接复制代码、图标或资源 |
| [envShell](https://github.com/E3nviction/envshell) | Apache-2.0 | Hyprland 控制中心、通知、透明面板和状态反馈 | 可在保留版权声明的前提下参考或移植明确授权的代码 |
| [WhiteSur GTK Theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) | MIT | 现代 macOS-like 的表面、圆角、透明度、按钮和控件参数 | 作为几何和颜色基准，不直接把 GTK/CSS 放进 QML |
| [Mojave GTK Theme](https://github.com/vinceliuice/Mojave-gtk-theme) | GPL-3.0 | 紧凑控件、阴影、边框和菜单参数 | 可作为参数参考；复制代码时保留许可证信息 |
| [aura-glass](https://github.com/DevWebeloper/aura-glass) | MIT | 毛玻璃与近实色弹出层的区分、焦点环、hover/pressed 状态 | 作为玻璃材质和状态层规则参考 |
| [NotchNux](https://github.com/Adityasah2004/NotchNux) | MIT | Dashboard 卡片密度、Tab 和指标组件的视觉层级 | 只借鉴卡片组织和密度，不引入 Notch |

### 4.2 复用规则

当前仓库为 GPL-3.0。直接移植外部代码时：

- 只接受许可证明确且与 GPL-3.0 兼容的代码；
- 保留原作者版权、许可证和必要的 NOTICE；
- 外部截图只用于设计评审，不提交到仓库作为运行时资源；
- 不复制 Apple 的 SF Pro、SF Symbols、系统图标或专有素材；
- Golden Gate Shell 没有明确许可证，因此仅作为视觉参考；
- GTK/SCSS/CSS 项目中的规则需要转换成 QML 组件逻辑，不能整段粘贴。

## 5. 目标设计语言

方向定为现代 macOS（Big Sur 之后的半透明桌面风格），不做旧版 Aqua 的拟物化外观。

### 5.1 色彩

先使用现有的 `m3...` 属性名作为兼容层，避免一次性修改近千处调用。后续再逐步迁移到更中性的语义名。

建议的初始角色：

| 角色 | 深色 | 浅色 |
| --- | --- | --- |
| 背景 | `#1C1C1E` | `#F5F5F7` |
| 普通表面 | `#2C2C2E` | `#FFFFFF` |
| 提升表面 | `#3A3A3C` | `#E5E5EA` |
| 主文字 | `#F5F5F7` | `#1D1D1F` |
| 次要文字 | `#98989D` | `#6E6E73` |
| 系统蓝 | `#0A84FF` | `#007AFF` |
| 错误 | `#FF453A` | `#FF3B30` |
| 成功 | `#30D158` | `#34C759` |
| 警告 | `#FF9F0A` | `#FF9500` |

壁纸取色仍然可以影响透明层，但不能破坏文字可读性。建议把颜色分成三类：

1. `surface`：大面积面板，可透明并使用模糊；
2. `elevated`：菜单、弹窗和文字密集卡片，接近实色；
3. `control`：按钮、开关、滑块和选中状态，使用半透明白/黑叠层或系统蓝。

### 5.2 材质、边框和阴影

- 大面板使用低饱和度半透明底色、背景模糊和 1px 低透明度边框；
- 菜单、输入框和确认对话框默认使用更接近实色的表面；
- 使用细内高光和低强度外阴影表现层级，不使用 Material 3 的明显 elevation 体系；
- 不在每个卡片上叠加毛玻璃，避免整个 UI 变成透明噪声；
- 现有 `Elevation.qml` 保留接口，但重新映射为较轻的 macOS 阴影等级。

### 5.3 几何

首轮建议值，最终以实际截图校准：

| 对象 | 圆角 |
| --- | ---: |
| 小按钮、菜单项 | 6～8px |
| 输入框、普通卡片 | 10～14px |
| 大卡片、弹出面板 | 16～20px |
| 控制中心、启动台容器 | 20～24px |
| 滑块、开关、搜索框 | 胶囊形 |

控件应保持较紧凑的高度和内边距。大圆角只用于容器，不把所有文字行都做成药丸。

### 5.4 状态反馈和动画

保留当前动画系统，但改变状态反馈的表现：

- Hover：背景亮度变化约 0.06～0.12；
- Pressed：短暂缩放或更深的覆盖层；
- Focus：细蓝色焦点环或边框，而不是 Material ripple；
- Checked：颜色或滑块位置变化，使用现有动画曲线；
- Popup：继续使用当前的淡入、位移和缩放动画；
- 页面切换：继续使用现有的 `AnchorAnim` 和 `CAnim`。

`StateLayer` 应保留 `pressed`、`containsMouse`、`clicked` 等现有接口，使模块页面不需要改写。

### 5.5 字体和图标

- 默认 UI 字体优先使用 `Inter`，回退到 `Noto Sans` 或系统无衬线字体；
- 等宽字体继续使用现有配置；
- 不把 Apple 字体作为依赖；如果用户本机有合法安装的 SF Pro，可以通过配置选择，但不能作为默认安装要求；
- 第一阶段可以暂时保留 Material Symbols，先完成表面和控件换肤；
- 第二阶段将高频图标迁移到许可证清楚的 Lucide、Phosphor 或自有 SVG，并保留 `MaterialIcon` 的调用兼容层；
- 迁移优先级为设置、网络、音频、电源、播放控制和导航图标，装饰性图标最后处理。

## 6. 实施阶段

### 阶段 0：建立视觉基线

工作项：

- 记录当前浅色/深色、透明/不透明和有壁纸/无壁纸的截图；
- 按模块建立检查清单：启动台、控制中心、Dashboard、QuickPanel、Sidebar、Nexus、通知、锁屏、OSD、文件对话框；
- 记录当前公共控件的属性和调用方，避免换肤时破坏 QML API；
- 选定一套默认 macOS-like 深浅色方案。

产出：视觉基线截图、控件清单和颜色角色映射表。

预计：0.5～1 天。

### 阶段 1：主题基础层

主要文件：

- `services/Colours.qml`
- `assets/schemes/`
- `plugin/src/Caelestia/Config/tokens.hpp`
- `plugin/src/Caelestia/Config/appearanceconfig.hpp`
- `components/effects/Elevation.qml`

工作项：

- 在 `Colours.qml` 中保留原始 scheme，并通过 macOS-like 语义视图提供深浅色表面和控件角色；动态 scheme 仍可提供强调色；
- 统一 surface、elevated、separator、scrim 和 accent 的实际映射；
- 增加面板圆角、控件圆角、边框透明度和阴影等级 Token；
- 调整默认字体回退链；
- 确认透明度和壁纸亮度算法在两种背景下都可读。

首批已完成：`Colours.qml`、`tokens.hpp`、`appearanceconfig.hpp`、`Elevation.qml`。动画 duration 和 easing token 保持不变。

预计：2～3 天。

### 阶段 2：公共控件换肤

按以下顺序改造：

1. `StateLayer.qml`、`ButtonBase.qml`、`IconButton.qml`、`IconTextButton.qml`、`TextButton.qml`；
2. `Menu.qml`、`MenuItem.qml`、`StyledTextField.qml`、`TextFieldBase.qml`；
3. `StyledSwitch.qml`、`StyledSlider.qml`、`FilledSlider.qml`、`StyledProgressBar.qml`；
4. `StyledScrollBar.qml`、`StyledRadioButton.qml`、`StyledSpinBox.qml`；
5. `Elevation.qml` 以及公共弹出层的背景和边框。

约束：

- 尽量保持现有属性名、信号和枚举；
- 保留控件的动画时长和触发顺序；
- 不让调用方继续决定 Material-specific 的默认颜色；
- 每完成一组控件就用 Dashboard、QuickPanel 和 Nexus 进行回归。

已完成：`StateLayer.qml`、`ButtonBase.qml`、`IconButton.qml`、`IconTextButton.qml`、`TextButton.qml`、`Menu.qml`、`StyledTextField.qml`、`StyledSwitch.qml`、`StyledSlider.qml`、`FilledSlider.qml`、`StyledProgressBar.qml`、`StyledScrollBar.qml`、`StyledRadioButton.qml` 和 `StyledSpinBox.qml`。Material ripple 已替换为 hover/pressed 覆盖层和轻微按压反馈，保留 `press()`、`pressed`、`containsMouse`、`clicked` 等调用契约；开关和滑块继续保留位置、尺寸及数值变化动画。

预计：4～7 天。当前阶段已完成，剩余工作是跨场景回归和少量页面特例。

### 阶段 3：现有页面表面统一

优先处理可见度最高、且已经接近 macOS 布局的模块：

- `modules/launchpad/`：搜索框、应用项、背景遮罩和选中状态；
- `modules/quickpanel/`：切换按钮、媒体区域、剪贴板列表和弹出面板；
- `modules/dashboard/`：卡片、Tab、媒体控制、天气和性能图表；
- `modules/sidebar/`：通知卡片、操作按钮和列表层级；
- `modules/nexus/`：导航栏、设置行、选择器、滑块和弹窗；
- `modules/session/`、`modules/lock/`、`modules/osd/`：高对比度表面和状态反馈；
- `components/filedialog/`、`modules/windowinfo/`：文件项、菜单和窗口信息卡片。

页面层只处理以下问题：

- 直接写死的 Material 颜色；
- 直接设置的 MaterialShape 或不合适的异形装饰；
- 与公共控件不一致的圆角、边框和表面层级；
- 因新字体或控件高度造成的溢出和布局偏移。

现有媒体可视化和 `M3Shapes` 装饰形状先保留，除非它们与目标风格发生明显冲突。

当前已完成：

- Dashboard Tab 分隔线和媒体区域的层级颜色；
- QuickPanel 高亮、Sidebar 面板边框和 Control Center 的系统蓝选中态；
- Nexus 搜索框、导航选中态、选择列表和弹出行的语义颜色；
- Session 的键盘焦点态、通知的严重级别颜色与操作按钮、文件对话框的选中态；
- WindowInfo 的工作区选择、元信息分隔线和次要信息颜色。

仍待处理：OSD 的独立场景截图回归，以及媒体可视化、LoadingIndicator 等需要保留动效的 Material Shapes。锁屏、通知、Session、文件对话框和 WindowInfo 已完成首批页面层收口。

预计：4～7 天。

### 阶段 4：图标与细节收尾

- 建立 Material 图标名到新图标名的映射表；
- 先替换高频系统图标，再替换模块专属图标；
- 统一图标尺寸、线宽、填充状态和垂直对齐；
- 检查浅色模式下的图标对比度；
- 删除不再使用的 Material-specific 视觉代码，但保留必要的兼容 API。

预计：2～4 天。

### 阶段 5：验证与清理

- 在浅色、深色、透明、无透明和高亮/低亮壁纸下回归；
- 验证单屏、多屏、不同 DPI 和字体缩放；
- 验证启动台、控制中心、通知、侧边栏和设置页的打开/关闭动画；
- 检查滑块、开关、输入框、菜单的键盘和鼠标交互；
- 运行 `git diff --check`、QML lint 和项目现有构建流程；
- 更新截图或补充用户配置迁移说明。

预计：2～3 天。当前已完成构建、diff 检查、深色透明模式实机回归，以及浅色/无透明度和高 DPI 场景的截图检查。

## 7. 建议的提交拆分

每个提交只处理一个视觉边界，便于回退和逐步评审：

1. `theme: add macos palette and surface tokens`
2. `components: restyle common controls`
3. `modules: unify macos panel surfaces`
4. `components: replace material state feedback`
5. `theme: migrate high-frequency icons`
6. `docs: describe macos ui theme`

第一阶段不应同时修改业务逻辑、服务接口或模块布局。

## 8. 风险与处理方式

| 风险 | 处理方式 |
| --- | --- |
| 只换颜色后仍然有明显 Material 味道 | 优先重做 `StateLayer`、按钮、菜单、开关和滑块，而不是继续调色 |
| 毛玻璃导致文字在壁纸上不可读 | 菜单、输入框和确认框使用 elevated 近实色表面 |
| 修改 Token 影响用户现有配置 | 保留现有键名，新增默认值和兼容映射，避免删除配置字段 |
| Google Sans 和 Material Symbols 暴露原设计语言 | 字体先换成 Inter/Noto Sans；图标迁移放在公共控件稳定之后 |
| M3Shapes 装饰与 macOS 风格冲突 | 仅保留媒体可视化等装饰场景，不在基础控件中继续扩散 |
| 外部项目代码或资源许可证不清楚 | 只复制许可证明确且兼容的部分；无许可证项目只参考效果 |
| 透明度、阴影和模糊带来性能回退 | 保留现有开关，分别测试玻璃面板数量和动画期间 GPU 占用 |

## 9. 验收标准

改造完成后应满足：

- 启动台、控制中心、Dashboard 等现有布局和交互不变；
- 现有动画名称、时长、曲线和页面切换行为没有无关变化；
- 公共按钮、菜单、输入框、开关、滑块和通知使用统一的 macOS-like 状态反馈；
- 大面板有适度玻璃感，但文字密集弹出层仍然清晰；
- 深浅色模式、透明度设置和壁纸取色均可用；
- 默认 UI 不再依赖 Material 3 的 ripple、tonal button、surface container 层级和异形基础控件；
- 没有引入未经授权的 Apple 字体、图标或资源；
- 构建、QML lint 和现有模块功能回归通过。

## 10. 工程量判断

按当前范围，不改布局、不增加 macOS 特色 Shell 功能：

- 视觉验证版：1～2 天；
- 公共控件和主要页面完成：1～2 周；
- 图标迁移、深浅色打磨和完整回归：额外 3～7 天；
- 总体预计：2～3 周，取决于图标迁移深度和截图回归数量。

推荐先完成阶段 0～2。完成后即可看到真实的 macOS-like 方向，并能在不触碰业务模块的情况下判断是否需要扩大页面层改造。
