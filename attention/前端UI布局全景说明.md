# 天气应用前端 UI 布局全景说明

> 面向小白的端到端讲解，覆盖页面结构、组件布局、主题/背景策略、调试界面和资源位置信息。文中路径均为项目内相对路径，直接在 IDE 中可定位。

---

## 1. 前端技术栈与入口
- **框架**：HarmonyOS ArkTS 声明式 UI。
- **应用入口**：`entry/src/main/ets/pages/Index.ets` 里用 `Stack` 填充全屏，仅渲染 `WeatherHomePage`。
- **页面路由**：路由表在 `entry/src/main/resources/base/profile/main_pages.json`（首页与城市管理页）。
- **全局状态**：`AppStorage` 持久化主题键、背景模式、性能标记等，常见键值：`themeKey`、`backgroundMode`、`currentTheme`、`isDarkMode`。

---

## 2. 设计系统与主题
- **设计令牌**：`entry/src/main/ets/common/theme/DesignSystem.ets`
  - 字体粗细：`THIN/LIGHT/REGULAR/MEDIUM/BOLD/HEAVY`。
  - 8px 间距栅格：`Spacing.XS/S/M/L/XL/XXL/XXXL`。
  - 玻璃质感色：`GLASS_BG`（10% 白透明）、`GLASS_BORDER`（20% 白透明）。
  - 图标为 SVG Path 字符串（菜单、返回、加号、太阳、云、雨等）。
- **主题管理**：`entry/src/main/ets/common/theme/ThemeManager.ets`
  - 模式：自动/浅色/深色 (`ThemeMode.AUTO/LIGHT/DARK`)，自动按时间 06:00-18:00 切换。
  - 配置字段：主色/背景/卡片色/文本主次/分割线/阴影/图表色/语义色等（详见 `ThemeConfig`）。
  - 通过 `AppPreferences` 读写用户选择；`AppStorage` 挂载 `currentTheme`、`isDarkMode` 供组件 `@StorageLink` 取色。
- **视频背景主题表**：`entry/src/main/ets/common/constants/ThemeConstants.ets`
  - 模式枚举：`BackgroundMode.VIDEO | ANIMATED_IMAGE | GRADIENT`，实际在首页强制使用视频。
  - 主题键 → 资源：`sunny/rainy/snow/night` 及其夜间版，包含 mp4、webp、渐变色、Lottie 占位路径。
- **资源清单**：`entry/src/main/resources/base/profile/weather_resources.json`
  - 列出每个 mp4/webp/lottie 的路径、分辨率、时长、大小等，用于核对素材。

---

## 3. 首页 WeatherHomePage 布局（`entry/src/main/ets/pages/home/WeatherHomePage.ets`）
### 3.1 顶层容器
- `Stack` 全屏：顺序为 **视频背景 → 半透明黑幕 → 主内容/骨架/错误 → Toast**。
- 背景组件：`AtmosphereBackground()`（详见下节）。
- 覆盖层：全屏 `Rect` 填充黑色 `opacity(0.35)` 提高对比度，`hitTestBehavior` 设为 `None` 保持透传。

### 3.2 数据与状态
- 核心控制器：`WeatherController` 负责城市列表与天气快照加载。
- 页面状态：`cityStates`(城市数据)、`isLoading`、`currentError`、`activeIndex`（Swiper 当前页）、`isRefreshing`、`backgroundMode`、`themeKey` 等。
- 刷新状态：`isRefreshing/refreshState` 控制下拉刷新；`Refresh` 的顶部提示条由 `refreshBuilder` 定义，60 高、居中 24px 圆形进度 + “刷新中...” 文案（14px，70% 白）。
- 刷新机制：`Refresh` 组件包裹 `Column`，下拉或手动刷新会调用 `handleRefresh()` → `refresh(true)`。
- 摇一摇：`ShakeDetector` 监听，触发 `handleShakeRefresh()`（带振动反馈）。

### 3.3 Header
```ts
Row()
  .padding({ left: 24, right: 24, top: 32 })
  // 左右各一个圆形透明按钮，图标路径来自 DesignSystem.Icons
```
- 左按钮：菜单图标 → `navigateToCityManagement()`。
- 右按钮：加号图标 → 同样跳转城市管理。
- `IconButton` 组件封装：44x44 圆形触控区域，`ButtonType.Circle`，点击尝试短振动。

### 3.4 主体区域
- `Column` 承载 `renderSwiper()`，`layoutWeight(1)` 占满剩余空间。
- 空数据态：居中展示城市名（或“北京市”兜底）+“添加城市”按钮。

### 3.5 城市滑动视图（Swiper）
- `Swiper` 横向、不循环、隐藏默认指示器，`index` 绑定 `activeIndex`。
- 每个城市 `SwiperItem` 内部是 `Scroll` + `Column`，`Scroll` 关闭滚动条、启用弹簧边缘。
- **上半区**：`CityWeatherCard`（城市名、天气描述、巨型温度、当日高低温）。
- **下半区**（`Column`，间距 20，左右 16 padding，底部 100 间隔避免遮挡指示点）：
  - `HourlyTrendChart`：横向 `List`，显示时间/图标占位/温度，背景玻璃风 24 圆角、15% 白透明、模糊 80、阴影 30。
  - `WeatherDetailGrid`：2 列网格 7 项（湿度/空气质量/风速/体感/气压/能见度/紫外线），每项 110 高度，15% 白透明玻璃卡片，模糊 80、无边框、柔和阴影。
  - `AdviceList`：若有生活建议，逐条行卡片（15% 白透明、模糊 80、0.5 边框、20 圆角、阴影 30）。
- **自定义指示器**：底部 95% 位置的 `Row`，当前页 8x8 白点，其他 6x6 半透明白点，通过 `position({x:'50%',y:'95%'}) + translate(-50%)` 精确居中。

### 3.6 加载与错误态
- `WeatherSkeleton`：骨架屏，含标题/温度/小时块/日预报占位 + 50% 宽度的高光线性渐变左右往返动画。
- 错误态：居中文本 + “重试”按钮调用 `refresh(true)`。
- `ErrorToast`：顶部 90% 宽悬浮条（左右各 5% 外边距，距顶 10），4s 自动消失，插入/删除均带 300ms 透明+上移动画，类型对应底色（红/橙/蓝），附关闭按钮。

### 3.7 背景模式切换按钮（隐藏在代码中，可按需打开）
- `renderBackgroundModeSwitch()`：左上（x=16,y=100，zIndex=1000）放置三枚按钮（视频/动画/渐变），点击更新 `AppStorage('backgroundMode')`。

### 3.8 主题选择逻辑
- `resolveThemeKey()`：依据当前快照的 `condition.themeKey` 与时间（18:00-06:00 为夜间）决定 `sunny/rainy/snow/night` 具体键，夜间自动加 `_night`。
- `AtmosphereBackground` 与城市卡文案颜色均使用 `DesignSystem.Colors.WHITE` 系列，确保在深色视频上清晰。

---

## 4. 背景/氛围层（`entry/src/main/ets/components/background/AtmosphereBackground.ets`）
- 通过 `@StorageProp('themeKey')` 监听主题变化，`onThemeChange` 重置准备状态并更新资源。
- **资源路径规则**：`videoSource = weather/${themeKey}.mp4`，实际引用 `rawfile/weather/*.mp4`。
- 仅渲染视频：`Video` 全屏 `objectFit(Cover)`、自动播放、循环、静音、无控件；错误/准备/开始均记录日志。
- 背景模式在 `aboutToAppear` 被强制设为 `VIDEO`，保证体验一致。
- 透明度叠加由首页的黑幕 `Rect.opacity(0.25)` 控制，如需更亮可降低透明度。

---

## 5. 核心卡片与功能组件
### 5.1 城市天气卡（`components/cards/CityWeatherCard.ets`）
- 布局：纵向 `Column`，上下内边距 48/24，左右 16。
- 城市名 34px（`MEDIUM`）+ 描述 20px，白色，附 4px 阴影增强可读性。
- 温度 110px 特大号，超细 100 权重，向上轻移 `margin top -10`，当日高低温 18px；温度区块 `alignItems(HorizontalAlign.Center)` 居中。
- 更新标签当前隐藏（`opacity(0)` 保留位）。

### 5.2 详情网格（`components/cards/WeatherDetailGrid.ets`）
- `Grid` 两列，行/列间距 `Spacing.M`(16)。
- 每项卡片：16 padding，24 圆角，15% 白透明背景，模糊 80，无边框，柔和阴影 30（偏下 10px）。
- 行 1：Path 图标强制白色 70% 透明、18px，标题 14px（60% 白，左侧 6px 间距）。
- 行 2：32px 数值白色；若值包含 `hPa`，以富文本分离数字(32px)与单位(18px 70% 白)。
- 输入字段：湿度/空气质量/风速/体感/气压/能见度/紫外线，调用方已格式化文案。

### 5.3 小时趋势（`components/charts/HourlyTrendChart.ets`）
- 组件整体玻璃风背景（同上），padding 12/16，圆角 24，高度 100。
- 横向 `List`，间距 12，关闭滚动条/开启弹簧；每个 60 宽的 `Column`：时间（14px 80% 白）、天气 Path 图标（默认太阳，24px 白色），温度 16px 白。
- 背景：15% 白透明、模糊 80、无边框、24 圆角、阴影 30。
- 时间格式：当前小时显示“现在”，否则“HH时”。

### 5.4 生活建议列表（`components/cards/AdviceList.ets`）
- 逐条 `Row`：左侧 emoji 图标，右侧 `Column` 含语气 12px（60% 白）、正文 16px（纯白，最多 2 行）。
- 卡片背景 15% 白透明，模糊 80，圆角 20，内边距 12/16，0.5 边框（20% 白），阴影 30。

### 5.5 骨架屏（`components/common/WeatherSkeleton.ets`）
- 预定义 margin 常量减少运行时创建。
- 使用多个矩形块模拟标题/温度/小时/日报列表，颜色 10% 白透明。
- 高光层为 50% 宽 `Row` 做 90° 线性渐变，`animateTo` 无限循环平移；整体 `Stack` 100% 宽高覆盖。

### 5.6 错误吐司（`components/common/ErrorToast.ets`）
- `@Link errorMessage` 共享数据；出现时 `isVisible=true`，4s 后自动淡出并清空。
- 布局：左右图标与关闭按钮，中间文本 `flexGrow` 占满。
- 过渡：插入/删除均带透明度与向上位移动画 300ms。

### 5.7 主题化基础卡片（`components/common/ThemedCard.ets`）
- 常用于设置页：`@StorageLink('currentTheme')` 取主题色，默认圆角 16、模糊 10、可按压缩放。
- 同文件还包含 `ThemedText/ThemedButton/ThemedDivider`，用于快速应用主题配色、按压动画、禁用态透明度等。

---

## 6. 城市管理页（`entry/src/main/ets/pages/management/CityManagementPage.ets`）
### 6.1 页面框架
- 背景：`Column` 全屏浅灰 `#F5F5F7`。
- Header：56 高 `Row`，左右各 40x40 透明按钮，中间标题。
  - 左按钮：返回 `router.back()`。
  - 右按钮：加号/关闭（通过旋转 45° 模拟 X，300ms 动画），切换搜索模式。
  - 背景 90% 白 + 20 模糊，突出浮层感。

### 6.2 搜索区（条件渲染：`isSearchMode`）
- 使用 `CitySearchBar` 组件 + 热门城市九宫格。
- 容器：白底、左右上下 16 padding，插入/删除动画向上位移 20px。
- 热门城市：`Grid` 3 列，8px 间距，浅灰块点击即添加城市。

### 6.3 城市列表
- `List` 间距 `Spacing.S`，上下左右留白 16。
- `ListItem` 支持右滑删除（`swipeAction` -> 红底删除按钮 80x100，圆角 16）。
- 城市卡：高度 100，24 圆角，左右 padding 24，阴影 8。
  - 渐变背景：第一个城市蓝色渐变，其他深灰渐变。
  - 左侧城市名 20px + 来源/国家标签（自动定位时显示定位图标+“Current Location”）。
  - 右侧天气图标占位（太阳 Path）。
- 空、加载态：加载显示 `LoadingProgress` 32px。
- 删除约束：索引 0 的默认城市禁止删除，提示 Toast。

### 6.4 搜索条组件（`components/search/CitySearchBar.ets`）
- 容器：白底，圆角 12，16 padding，阴影 8。
- 输入行：圆角 24 灰色背景，16 高度 padding；左侧放大镜占位图标，右侧清除按钮/加载转圈。
- 交互：
  - 输入 ≥2 字符触发 300ms 防抖搜索（`CitySearchService.searchCities`）。
  - 失焦后延迟 200ms 关闭结果层，防止点击穿透。
  - `callbacks` 将搜索/选择/清空事件回传父组件。
- 结果层（白底、边框、300 高度上限）：
  - 无输入时展示“搜索建议”列表。
  - 有结果时 `List` 展示城市名 + 州/国家，右侧蓝色箭头占位。
  - 无结果（输入≥2，非搜索中）显示提示插画占位。
- 列表样式：`List` 使用分隔线（`strokeWidth:1`、浅灰），列表项 44-60 高度，左右 16 内边距，文案颜色 #333/#666；热门城市宫格背景 #F0F0F5、8px 圆角。

---

## 7. 主题设置页（`entry/src/main/ets/pages/settings/ThemeSettingsPage.ets`）
- 背景色绑定 `currentTheme.backgroundColor`，页面切换带 300ms 缓动动画。
- Header：左侧返回图标，中间标题（`ThemedText`），右侧空列保持居中。
- “主题预览”卡：`ThemedCard` 内部简单城市温度预览，右上角用 emoji 显示当前昼夜。
- “主题模式”卡：三行选项（自动/浅色/深色），左 emoji + 文本 + `Radio(group:'themeGroup')` 单选，整行可点击；选项间用 `ThemedDivider`。
- “主题建议”卡：展示 `ThemeManager.getThemeSuggestion()` 返回的文案；若为自动模式，附带切换时间表。
- 选择逻辑：点击调用 `selectThemeMode` → `ThemeManager.setThemeMode(mode)` → 持久化并触发动画。

---

## 8. 小组件（卡片）布局（`entry/src/main/ets/widget/pages/WeatherCard.ets`）
- `Stack` 全屏：底层线性渐变背景（135° 蓝系），上层 `Column` 显示城市/时间 + 温度/图标/天气。
- 字体：城市 14px 粗体；更新时间 10px 半透明白；温度 36px 粗体；右侧太阳圆形占位 + 12px 描述。
- 点击动作：`postCardAction` 跳转 `EntryAbility`。
- 数据源：`@LocalStorageProp` 读取卡片存储的温度/城市/天气/更新时间。

---

## 9. 调试与诊断界面（仅开发模式显示）
- **性能悬浮层** `components/debug/PerformanceOverlay.ets`：左上角（x=20,y=80）显示性能等级/FPS/内存/摇一摇状态，黑底圆角；`FPSCounter` 每 16ms 采样。
- **资源状态悬浮层** `components/debug/ResourceStatusOverlay.ets`：右上角 300 宽黑底卡（top≈100，right=16），概览资源健康度、主题状态（缺失资源数）、建议列表，可刷新/关闭。
- **数据库检查器** `components/debug/DatabaseInspector.ets`：左上 350x500 黑底卡（top=50,left=16），Tab 切换“城市数据/功能测试”，列表展示城市信息或测试套件进度。
- **图表性能监控** `components/debug/ChartPerformanceMonitor.ets`：右侧 280 宽黑底卡（top≈200,right=16），渲染耗时/FPS/内存/数据点/缓存命中率，含“清理缓存/自动优化”按钮。
- **主题调试面板** `components/debug/ThemeDebugPanel.ets`：右下 320 宽黑底卡（bottom≈50,right=16），可一键切换主题模式，展示当前配色值。
- **资源验证器** `components/debug/ResourceValidator.ets`：右下 350 宽黑底卡（bottom≈120,right=16），列出各主题资源验证结果（模拟大小/状态），提供“开始验证/清除结果”。
- **日志查看器** `components/debug/LogViewer.ets`：右上 400x500 黑底卡（top=50,right=16），默认 1s 自动刷新最近 50 条日志，按级别着色；带“刷新/停止自动/清空”按钮。
- **网络诊断对话框** `components/diagnosis/NetworkDiagnosisDialog.ets`：居中弹窗，评分+详细项+问题建议，关闭按钮；由首页网络诊断逻辑触发。
- 开关逻辑：上述浮层组件均通过 `AppStorage.get<boolean>('isDevelopment')` 控制，发布版默认不显示。

---

## 10. 数据格式与展示映射
- 数据模型：`entry/src/main/ets/data/models/WeatherModels.ets`
  - `WeatherSnapshot` 内含 `current/hourly/daily/advice`，首页 UI 直接用 `snapshot.current` 等字段。
  - `CityWeatherState`（在 `viewmodel/WeatherController.ets`）是 UI 消费的结构，包含城市元数据 + 天气快照/错误状态。
- 文案格式化：`common/utils/FormatHelper.ets`
  - 温度 `Math.round(value) + '°'`；湿度 `xx%`；AQI 分级文案；风速 `km/h + 风向`；更新时间 `HH:mm`。
- 主题映射：`ThemeConstants.getThemeWithTimeAware(weatherKey, isNight)` 供背景选择；`WeatherHomePage.resolveThemeKey` 先根据天气 key，再根据时间选夜间版。
- 刷新枚举：`RefreshState`（IDLE/REFRESHING/ERROR）驱动 `Refresh` UI 和骨架/错误显示。

---

## 11. 资源位置总览
- 背景视频/WebP：`entry/src/main/resources/rawfile/weather/`（含 `README.md` 规格说明）。
- Lottie：`entry/src/main/resources/rawfile/lottie/`（含使用示例）。
- 颜色/字符串：`entry/src/main/resources/base/element/`（仅启动背景色、权限说明等）。
- 主题/页面清单：`entry/src/main/resources/base/profile/`。

---

## 12. 开发/扩展指引（给小白的操作步骤）
1. **新增天气子卡片**：在 `components/cards/` 新建组件，遵循 `DesignSystem.Spacing` 与玻璃风格背景（10% 黑透明 + 24 圆角 + 0.5 边框 + 40 模糊），在 `WeatherHomePage.renderSwiper()` 的 `Column` 中按需插入。
2. **接入数据字段**：在新卡 `@Prop` 接收 `CityWeatherState.snapshot` 里对应字段，必要时在 `FormatHelper` 添加格式化函数，保持展示一致。
3. **保证主题适配**：文字颜色优先用 `DesignSystem.Colors.WHITE_*` 或 `currentTheme` 系列；背景保持半透明/模糊，避免与视频冲突。
4. **交互反馈**：按钮可参考 `IconButton` 与 `ThemedButton` 的按压缩放/阴影；重要操作（刷新/删除）可调用 `ErrorToast.createInfoMessage` 等提供即时提示。
5. **调试资源问题**：在开发模式下打开 `ResourceValidator`/`ResourceStatusOverlay` 检查缺失的 mp4/webp/lottie；更新 `ThemeConstants.THEMES` 或 `weather_resources.json` 后保持路径一致。
6. **布局适配**：主要使用百分比/权重(`layoutWeight`)与 `Swiper+Scroll`，在新布局中避免写死高度，除非像 `WeatherDetailGrid` 这种需要等高网格（110 高）。
7. **导航**：新页面需在 `resources/base/profile/main_pages.json` 注册，并通过 `router.push({ url: 'pages/yourPage' })` 跳转。
8. **调试开关**：所有黑底调试浮层均读取 `AppStorage('isDevelopment')`，若新增调试组件，沿用该开关并放置在屏幕边缘避免遮挡主交互。

---

## 13. 一眼看懂的页面组成速查表
- 首页：背景视频 + 黑色蒙版 → 刷新容器 → Header(菜单/加号) + Swiper(城市卡 + 小时趋势 + 详情网格 + 建议) + 底部指示点 + Toast/骨架/错误。
- 城市管理：浅灰背景 → Header(返回/搜索开关) → 搜索区(搜索条+热门城市) → 城市列表(渐变卡、右滑删除) → Toast。
- 主题设置：主题背景 → Header → 预览卡 → 模式列表（单选）→ 建议卡。
- Widget：渐变背景 → 城市/时间 → 温度+图标+描述。
- 调试：若开启开发模式，屏幕边缘出现多个黑底浮层用于性能、资源、数据库、主题、图表监控与验证。

以上即当前前端 UI 布局与设计细节的完整视图，可直接按路径跳转查看源码并依据指引调整或扩展。若需进一步拆解某个组件的交互或动画，可在对应 `.ets` 文件中搜索 `@Builder` 段落，逐行对照本文说明。
