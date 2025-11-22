# 沉浸式天气预报 APP 实验方案（精简可落地版）

## 一、实验背景与目标
- **课程任务**：HarmonyOS + ArkTS 天气预报 APP，需实现多城市天气展示、网络数据获取、数据持久化、界面友好等评分点。
- **定位**：以“视觉冲击 + 简洁交互”为核心卖点，用最小可行逻辑实现最大程度的“抓眼球”效果。
- **目标**：
    1. 完成题目硬性功能（网络、城市管理、数据库、刷新）；
    2. 打磨一套沉浸式界面，保证打开即被吸引；
    3. 控制实现难度，确保 4 周内可交付、高质量演示。

## 二、专家建议采纳与策略调整
| 建议 | 采纳情况 | 调整说明 |
| --- | --- | --- |
| Canvas 粒子/自绘动效过重 | ✅ 采纳 | 改用 `VideoComponent/AnimatedImage` 播放循环天气视频或高帧 WebP，实现 90% 视觉效果，避免性能/开发黑洞。 |
| 功能点过多，难以在 4 周完成 | ✅ 采纳 | 将需求拆为“必做/加强/彩蛋”三级，优先保障视觉核心与硬性功能，延后高复杂度项。 |
| 多主题、情景提醒、复杂动效优先级低 | ✅ 部分采纳 | 默认只做一套高质主题 + 自动夜景，情景提醒改为“智能建议”文字展示；多感官刷新、主题切换列为可选扩展。 |
| 摇一摇刷新应后置 | ✅ 采纳 | 作为彩蛋置于第 4 周，若时间不足可降级为“展示型原型”或直接砍掉。 |
| 趋势图勿再自行绘制 Path | ✅ 采纳 | 采用“Chart 组件 → `List` 条形 → `Stack` 圆点”三级兜底策略，彻底规避自绘坐标带来的时间黑洞。 |
| 第一周塞满硬功能导致视觉被挤压 | ✅ 采纳 | 调整为“Mock 数据 + 视觉先行”与“功能落地”两条平行工作流，确保核心视觉从第 1 天开始制作，功能开发不再卡住整体节奏。 |
| Mock 数据与真实 API 结构不一致易引发“集成地狱” | ✅ 采纳 | Track F 第一步即抓取真实 API 响应并生成 Mock 文件，后续 UI 全程以该结构驱动，确保切换数据源时零重构。 |
| VideoComponent + 毛玻璃 + Swiper 可能造成性能瓶颈 | ✅ 采纳 | 为视觉核心建立“Video → AnimatedImage → 静态渐变+Lottie”三级兜底，并在 Day 1 完成压力测试，随时可降级保障流畅度。 |

> 通过上述取舍，方案从“CEO 级大而全”调整为“学生可控、侧重视觉”的版本。

### 2.1 当前进度快照
- ✅ 基础工程结构与路由：`AppScope`、`entry` 已就绪，可直接接入新页面。
- ✅ 核心数据模型：`WeatherModels.ets` 定义了城市、天气快照等实体。
- ✅ 网络层：`WeatherService` 已对接 OpenMeteo API，可在此基础上补齐容错。
- ✅ UI 雏形：`WeatherHomePage`、`AtmosphereBackground` 已能展示静态梯度背景。
- ✅ 仓库架构：Repository + Mock 数据链路已经搭建，方便随时切换到真实接口。
- ⚠️ 待完成：城市/天气 RDB 存储、缓存策略、定位服务尚未落地，错误处理与网络检测仍需加强。
- 📐 结构评价：整体遵循 MVVM + Repository，接口清晰，适合直接延展专家提出的强化项。

### 2.2 优先执行路线（Phase 1 周内必做）
**Track F（功能）**
1. Weather API 集成：验证当前 `WeatherService`，补充重试、非阻塞网络检测、`try-catch` 错误抛出链路。
2. 数据库存储：完成 `CityStorage.ets`、`WeatherCacheStorage.ets`，使用 RDB + Preferences 管理城市、缓存与设置。
3. 定位与权限：接入 `@ohos.geoLocationManager`，写好权限弹窗 + `usedScene` 描述，首启自动添加当前城市。
4. 缓存兜底：Repository 层实现“缓存 → API → Mock”的三段策略，保证离线也能展示。

**Track V（视觉）**
1. 背景系统升级：在现有渐变基础上加上 Video/AnimatedImage 两级资源，形成 3 层 fallback，首周完成压测。
2. 毛玻璃卡片：全局采用 `.backgroundBlur()` + 半透明色块，配合玻璃态描边与阴影。
3. Blur Card 动效：实现 `backdropBlur`、`shadow`、`border` 边界效果，形成统一设计语言。
4. 备用资源：为视频/动图准备静态渐变 + Lottie 兜底，防止模拟器或低配设备播放失败。

### 2.3 官方风控要点（需立即补强）
- **性能分层**：AtmosphereBackground 在渲染前调用 `deviceInfo/display` 识别 RAM、GPU、分辨率，自动决定视频/动图/渐变，并监听视频预加载失败直接降级。
- **毛玻璃上限**：统一卡片模糊半径，使用 `CompositingStrategy.RenderTarget/OFFSCREEN` 和 `renderGroup(true)` 降低 GPU 压力，禁止多层嵌套模糊。
- **RDB 迁移**：CityStorage/WeatherCacheStorage 引入 `version + onUpgrade` 与 `schema_metadata` 表，支持增量 `ALTER TABLE` 行为并具备损坏恢复逻辑。
- **缓存弹性**：根据天气类型动态调整有效期（雷暴 10min、雨雪 20min、晴天 45min），极端天气触发更快刷新。
- **权限合规**：`module.json5` 补齐 API 版本与定位/网络权限，所有权限写明 `reason + usedScene`，同时准备对应 `string` 资源。
- **防御式定位**：LocationService 需提供“权限引导 → 定位开关提示 → IP 定位 → 默认城市”多级回退路径。
- **网络鲁棒性**：WeatherService 引入 `AbortController`、超时定时器、指数退避重试与可重试错误识别。
- **性能量化**：建立 FPS/内存/冷启动等量化阈值，纳入测试与答辩材料。

## 三、体验愿景与设计原则
1. **沉浸先行**：首屏即呈现动态天气背景 + 毛玻璃信息层，配情绪化文案，带来“天气故事”感。
2. **轻逻辑闭环**：打开即显示当前位置天气，上下刷新、左右切换城市，流程简单可讲。
3. **可解释的“聪明”**：利用规则引擎输出生活建议，既显得有温度又易于实现维护。
4. **渐进增强**：先确保功能、视觉 MVP；再逐步叠加交互彩蛋，保证即使砍掉拓展也能按时交付。

## 四、核心创新与实现路径

### 4.1 视觉呈现（必做）
| 要素 | 实现方式 | 说明 |
| --- | --- | --- |
| 动态天气背景 | 根据天气条件切换本地循环视频 / 高帧 WebP（晴、雨、雪、雾霾、夜晚），通过 `VideoComponent` 背景播放，设置 `muted` 和 `loop`。 | 无需自绘动画即可获得强烈沉浸感；素材可提前准备。 |
| 毛玻璃卡片 | 使用 `backgroundBlur` + 半透明渐变 + 轻投影展示温度、体感、湿度等关键指标。 | 视觉层次清晰，符合 ArkUI 声明式写法。 |
| 微动画点缀 | 选用少量 Lottie/GIF（如太阳旋转、风车摆动）放置在卡片角落。 | 只保留 1-2 个动画，降低性能压力。 |
| 情绪化文案 | 按天气/温度生成一句“今日情绪”描述，如“雨夜最适合慢咖啡”。 | 与背景联动，增强记忆点。 |

#### 视觉核心安全策略
1. **Plan A（首选）**：`VideoComponent` + 毛玻璃；Day 1 即在 Swiper 场景下做滑动/刷新压力测试（含低端设备或模拟器），若出现掉帧/黑屏立即记录瓶颈数据。
2. **Plan B（降级）**：`AnimatedImage`（高帧 WebP/GIF）+ 毛玻璃；同样测试多城市滑动与刷新并确认帧率，满足视觉动感同时减轻 GPU 占用。
3. **Plan C（兜底）**：静态渐变背景 + 少量 Lottie/位移动效（太阳、雨滴），保证 100% 流畅且仍优于传统静态界面。Plan C 资源提前准备，可一键切换。
> 三套方案共享同一背景组件接口，切换仅需调整资源配置，确保演示前可根据设备性能快速选择最稳方案。

#### 背景系统 3 层实现草案
- 借助枚举 + 资源清单维护 Video（Plan A）、AnimatedImage（Plan B）、Gradient（Plan C）三种模式，任意天气主题都具备完整的降级链路。
- `AtmosphereBackground` 组件内统一根据 `mode` 渲染视频/动图/渐变，并叠加半透明遮罩，避免 UI 闪烁。

```ts
// ThemeConstants.ets
export enum BackgroundMode {
  VIDEO = 'video',
  ANIMATED_IMAGE = 'webp',
  GRADIENT = 'gradient'
}

export interface VideoThemeAsset {
  themeKey: string;
  videoResource?: string;
  animatedImageResource?: string;
  gradientColors: string[];
  accentColor?: string;
  mode: BackgroundMode;
}

export class ThemeConstants {
  static readonly THEMES: VideoThemeAsset[] = [
    {
      themeKey: 'sunny',
      videoResource: 'rawfile/weather/sunny.mp4',
      animatedImageResource: 'rawfile/weather/sunny.webp',
      gradientColors: ['#87CEEB', '#4A90E2'],
      accentColor: 'rgba(255, 223, 0, 0.4)',
      mode: BackgroundMode.VIDEO
    },
    {
      themeKey: 'rainy',
      videoResource: 'rawfile/weather/rainy.mp4',
      animatedImageResource: 'rawfile/weather/rainy.webp',
      gradientColors: ['#4A5A6A', '#2C3E50'],
      accentColor: 'rgba(173, 216, 230, 0.4)',
      mode: BackgroundMode.VIDEO
    }
  ];
}
```

```ts
// AtmosphereBackground.ets
@Component
export struct AtmosphereBackground {
  @Prop themeKey: string = 'sunny';
  @StorageLink('backgroundMode') mode: BackgroundMode = BackgroundMode.GRADIENT;

  build() {
    Stack() {
      if (this.mode === BackgroundMode.VIDEO) {
        this.renderVideo();
      } else if (this.mode === BackgroundMode.ANIMATED_IMAGE) {
        this.renderAnimatedImage();
      } else {
        this.renderGradient();
      }

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.18)');
    };
  }

  @Builder
  private renderVideo(): void {
    // Video 方案：自动播放 + 静音 + 循环，素材由 ThemeConstants 提供
  }

  @Builder
  private renderGradient(): void {
    // 渐变兜底方案：沿用当前实现，保证任意设备可用
  }
}
```

#### 性能自适应与在线视频兜底
- 通过 `DevicePerformanceDetector`（封装 `@ohos.deviceInfo`、`@ohos.display`、`@ohos.systemCapabilityManager`）在 `aboutToAppear` 阶段收集 RAM、GPU、分辨率，得出 `PerformanceLevel`，再写入 `AppStorage` 供全局组件共享。
- 根据性能等级选择 `BackgroundMode`：高配 → 视频（含本地/在线视频，支持 `.onError` 降级），中配 → AnimatedImage，低配/模拟器 → 渐变。
- Video 渲染需：
    - 依据分辨率动态选择 `hd/fullhd/4k` 资源；
    - 开启 `.compositingStrategy(CompositingStrategy.OFFSCREEN)`；
    - 在 `.onError` 中切换至 AnimatedImage，AnimatedImage 再失败则切至渐变；
    - 支持 `renderOnlineVideo(url)` 以便后续引入云端素材，并在出错时回退。
- AnimatedImage/渐变保持统一遮罩，避免 UI 闪断。
```ts
class DevicePerformanceDetector {
  async detect(): Promise<DeviceCapability> {
    const deviceInfo = await deviceInfo.getDeviceInformation();
    const displayInfo = display.getDefaultDisplaySync();
    const ramGB = deviceInfo.totalMem / (1024 * 1024 * 1024);
    const level = ramGB >= 8 && displayInfo.refreshRate >= 120
      ? PerformanceLevel.HIGH
      : ramGB >= 4
        ? PerformanceLevel.MEDIUM
        : PerformanceLevel.LOW;
    return {
      performanceLevel: level,
      screenWidth: displayInfo.width,
      screenHeight: displayInfo.height
    };
  }
}
```

#### 毛玻璃卡片代码示例
```ts
@Component
struct WeatherInfoCard {
  build() {
    Column() {
      Text('23°C')
        .fontSize(48)
        .fontColor(Color.White);
      // 其余内容同 WeatherHomePage 现有布局
    }
    .padding(20)
    .backgroundColor('rgba(255, 255, 255, 0.15)')
    .backdropBlur(20)
    .borderRadius(20)
    .border({
      width: 1,
      color: 'rgba(255, 255, 255, 0.25)'
    })
    .shadow({
      radius: 15,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    });
  }
}
```
- 卡片使用 `compositingStrategy(CompositingStrategy.RenderTarget)` 或 `OFFSCREEN` 缓存绘制结果，根据高亮状态动态下调 `backdropBlur`（10~15），并通过 `.renderGroup(true)` 减少 GPU 重算。

### 4.2 交互体验（必做 + 增强）
| 层级 | 功能 | 说明 |
| --- | --- | --- |
| 必做 | Swiper 城市卡片 | 采用 `Swiper` 展示多城市，全屏卡片 + 缩略指示；尾卡为“＋”入口添加城市。 |
| 必做 | 自动定位首屏 | 调用 `@ohos.geoLocationManager` 获取当前位置，配合权限弹窗与 `usedScene` 描述，生成首张卡片减少手动输入。 |
| 增强 | 下拉刷新动画 | 使用内置刷新组件 + 简洁进度动画，配合时间戳提示“上次更新”。 |
| 彩蛋（可砍） | 摇一摇刷新 | 监听加速度传感器，达到阈值后触发同一刷新逻辑；若第 4 周时间不足可降级为仅在 Demo 中演示。 |

### 4.3 数据表达与智能提示
- **24 小时趋势 mini 图**：解析小时级数据，优先选用轻量 Chart 组件；若集成受阻，则降级为横向 `List` + 栏高/圆点位置模拟条形或折线效果，坚决避免自绘 `Path` 造成的坐标与性能负担。
- **三日“故事线”**：将未来 3~5 日天气以“卡片时间轴”呈现，配简短提示语，避免复杂动画。
- **智能生活建议**：基于天气代码、温度区间、AQI 构建规则表，输出 1~2 条文字建议，直接显示在毛玻璃卡片下方。
- **本地缓存与离线提醒**：使用 Preferences/RDB 保存城市列表 + 最近一次天气数据，网络异常时展示缓存并提示“当前显示离线数据，更新时间 XX:XX”。

#### 趋势图安全落地策略
1. **Plan A（首选）**：引入 ArkUI 兼容的轻量 Chart 组件（折线/条形），仅做必要样式调整，快速达成可视化。
2. **Plan B（降级）**：使用 `List` + `Column`/`Text` 组合，24 个小时平铺，借助 `height` 或渐变条模拟温度差异。
3. **Plan C（视觉增强版）**：在 Plan B 基础上，通过在 `Stack` 中放置可调 `Circle` 或小图标，以 `marginTop` 控制“折线”位置，保持实现简单且无需手写路径。
> 以上策略确保趋势展示不会再次跌入“自定义绘制陷阱”，即使 Plan A 失败，也能在 Plan B/C 保持视觉一致性。

### 4.4 拓展亮点（仅在时间允许时投入）
1. 自动夜景切换（根据时间改用夜间视频与深色卡片）。
2. 主题皮肤/用户自定义背景。
3. 情绪化天气地图、语音播报等创意展示。

## 五、功能范围与优先级
| 等级 | 功能 | 说明 |
| --- | --- | --- |
| **Must Have** | 网络天气获取、城市增删、RDB/Preferences 存储、Swiper 展示、多日/小时数据、下拉刷新、离线提示 | 满足实验评分硬指标。 |
| **Should Have** | 动态视频背景、毛玻璃卡片、智能生活建议、自动定位、趋势图 mini 版 | 保障“抓眼球 + 有温度”。 |
| **Nice to Have** | 摇一摇刷新、夜间自动切换、主题拓展、语音播报等 | 按时间投入，优先展示价值最高者。 |

### 题目要求对照
| 题目要求 | 对应实现 | 优先级 |
| --- | --- | --- |
| 网络获取天气信息 | `WeatherService` 请求第三方 API（实时 + 小时 + 多日），含错误兜底 | Must |
| 多城市展示 | `Swiper` 卡片 + 缩略指示，首页即可左右滑看多城 | Must |
| 更新天气信息 | 下拉刷新（主）+ 手动按钮；摇一摇刷新列为彩蛋 | Must / Nice |
| 动态添加城市 | 尾卡“＋”入口 -> 搜索/选择 -> 写入数据库 | Must |
| 同屏总览多个城市 | Swiper + 城市缩略导航条 + “回到当前位置”按钮 | Must |
| 使用数据库 | RDB 存城市列表与天气缓存，Preferences 存主题、定位开关 | Must |

## 六、技术架构与组件策略
1. **表现层（ArkUI）**
    - `Swiper` + `PageStack` 组织多城市与详情。
    - `VideoComponent`/`AnimatedImage` 作为背景容器；`Column/Row` + `backgroundBlur` 构造毛玻璃卡片。
    - `PullToRefresh`、`Dialog` 用于刷新与添加城市流程。
2. **逻辑层（ArkTS）**
    - `WeatherService`: 统一请求、错误处理、缓存写入。
    - `CityManager`: 管理城市增删排序、默认城市。
    - `AdviceEngine`: 根据规则表生成情绪文案与建议。
3. **数据层**
    - `RDB`：`cities` 表（id、name、lat、lon、order）、`weather_snapshot` 表（cityId、payload、updateTime）。
    - `Preferences`: 保存主题模式、自动定位开关、摇一摇开关等轻量配置。
4. **系统服务**
    - `@ohos.location` 获取经纬度；
    - `@ohos.sensor`（仅当实现摇一摇）监听加速度；
    - `@ohos.hapticPlayer`（可选）在刷新成功时进行轻震反馈。

### 6.1 ArkTS 编码硬性规范
1. **类型安全**：禁止 `any/unknown`，所有对象需有明确接口。
   ```ts
   import resourceManager from '@ohos.resourceManager';

   interface WeatherData {
     temperature: number;
     humidity: number;
   }

   private currentData: resourceManager.RawFileDescriptor | null = null;
   const result: WeatherData = getData();
   ```
2. **对象字面量必备类型**：先声明接口再定义常量，常量类不可用 `Record<string, T>`，需写具体键值映射。
3. **静态方法禁用 `this`**：统一使用类名访问静态字段，规避 `arkts-no-standalone-this`。
4. **Promise 错误处理**：一律使用 `async/await + try-catch`，禁止 `.catch(err => …)`。
5. **catch 变量不带类型**：进入 `catch` 后使用 `as BusinessError` 等断言。
6. **属性命名规避冲突**：避免使用 `scale`、`width` 这类与 ArkUI 属性重名的 `@State` 字段，统一加语义前缀。
7. **网络图片必须转换 PixelMap**：先用 `@ohos.net.http` 拉取数组缓冲，再调用 `@ohos.multimedia.image` 转为 `PixelMap`，再交给 `Image` 组件。
   ```ts
   import http from '@ohos.net.http';
   import image from '@ohos.multimedia.image';

   async function loadNetworkImage(url: string): Promise<image.PixelMap> {
     const httpRequest = http.createHttp();
     try {
       const response = await httpRequest.request(url, {
         method: http.RequestMethod.GET,
         expectDataType: http.HttpDataType.ARRAY_BUFFER,
         connectTimeout: 15000,
         readTimeout: 30000
       });
       if (response.responseCode === 200) {
         const arrayBuffer = response.result as ArrayBuffer;
         const imageSource = image.createImageSource(arrayBuffer);
         return await imageSource.createPixelMap();
       }
       throw new Error(`HTTP ${response.responseCode}`);
     } finally {
       httpRequest.destroy();
     }
   }
   ```
8. **非阻塞网络检测**：`getNetworkInfo()` 失败时仅记录 warning，真实 HTTP 请求才判定网络是否可用，避免模拟器误判。
   ```ts
   try {
     const networkInfo = await networkHelper.getNetworkInfo();
     console.info('Network type:', networkInfo.type);
   } catch (error) {
     console.warn('Network check failed (simulator), continue request');
   }
   ```
9. **模块配置一致性**：`module.json5` 需声明 `deviceTypes`、`apiVersion.compatible/target`，并在 `requestPermissions` 中写明 `reason + usedScene`，资源文件同步提供多语言描述，防止审核驳回。
   ```json5
   "deviceTypes": ["phone", "tablet"],
   "apiVersion": { "compatible": 6, "target": 9, "releaseType": "Release" },
   "requestPermissions": [
     {
       "name": "ohos.permission.LOCATION",
       "reason": "$string:permission_location_reason",
       "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
     }
   ]
   ```

### 6.2 常见踩坑速查表
| 踩坑 | 解决策略 | 优先级 |
| --- | --- | --- |
| 滥用 any/unknown | 定义接口 + 类型断言 | 🔴 CRITICAL |
| 无类型对象字面量 | 先声明接口再赋值 | 🔴 CRITICAL |
| 静态方法引用 this | 使用类名访问静态成员 | 🔴 CRITICAL |
| `.catch(err)` 写法 | 改为 `async/await` + `try-catch` | 🔴 CRITICAL |
| `catch (err: Error)` | 去掉类型，在内部断言 | 🔴 CRITICAL |
| 网络图片直连 URL | 转为 PixelMap 再展示 | 🟡 HIGH |
| 阻塞式网络检测 | 捕获异常但不中断流程 | 🟡 HIGH |
| 组件属性名称冲突 | 添加语义化前缀 | 🟡 HIGH |
| 权限描述缺失 | 在 `module.json5` 中补充 `reason` 与 `usedScene` | 🟢 MEDIUM |

### 6.3 数据存储骨架（RDB + Preferences）
- 城市信息使用 RDB 保证排序与去重，写入统一通过 `ValuesBucket`，禁止“临时对象”写法。
- 天气缓存/设置项走 Preferences，用异步 `put/get` + `flush()`，读取时记得做类型断言。

```ts
// data/storage/CityStorage.ets
import relationalStore from '@ohos.data.relationalStore';
import type common from '@ohos.app.ability.common';
import { City } from '../models/WeatherModels';

export class CityStorage {
  private rdbStore: relationalStore.RdbStore | null = null;
  private static readonly DB_NAME = 'weather.db';
  private static readonly TABLE_CITIES = 'cities';
  private static readonly CURRENT_VERSION = 2;

  async init(context: common.UIAbilityContext): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: CityStorage.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
      version: CityStorage.CURRENT_VERSION
    };
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.migrate();
      await this.createTables();
    } catch (error) {
      console.error('[CityStorage] init failed, try recovery');
      await relationalStore.deleteRdbStore(context, CityStorage.DB_NAME);
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      await this.updateSchemaVersion(CityStorage.CURRENT_VERSION);
    }
  }

  private async migrate(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    const version = await this.getCurrentSchemaVersion();
    if (version < 2) {
      await this.rdbStore.executeSql(
        `ALTER TABLE ${CityStorage.TABLE_CITIES} ADD COLUMN timeZoneOffsetMinutes INTEGER DEFAULT 0`
      );
    }
    await this.updateSchemaVersion(CityStorage.CURRENT_VERSION);
  }

  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    const createTableSql = `
      CREATE TABLE IF NOT EXISTS ${CityStorage.TABLE_CITIES} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        source INTEGER NOT NULL,
        videoTheme TEXT NOT NULL,
        timeZoneOffsetMinutes INTEGER NOT NULL DEFAULT 0,
        displayOrder INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    `;
    await this.rdbStore.executeSql(createTableSql);
    await this.rdbStore.executeSql(`
      CREATE INDEX IF NOT EXISTS idx_display_order
      ON ${CityStorage.TABLE_CITIES} (displayOrder)
    `);
  }

  private async getCurrentSchemaVersion(): Promise<number> {
    if (!this.rdbStore) {
      return 1;
    }
    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS schema_metadata (
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      )
    `);
    const predicates = new relationalStore.RdbPredicates('schema_metadata');
    predicates.equalTo('key', 'version');
    const resultSet = await this.rdbStore.query(predicates);
    try {
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('value'));
      }
      return 1;
    } finally {
      resultSet.close();
    }
  }

  private async updateSchemaVersion(version: number): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      'key': 'version',
      'value': version
    };
    await this.rdbStore.insert('schema_metadata', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async addCity(city: City): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized');
    }
    const valueBucket: relationalStore.ValuesBucket = {
      'id': city.id,
      'name': city.name,
      'country': city.country,
      'latitude': city.coordinates.latitude,
      'longitude': city.coordinates.longitude,
      'source': city.source,
      'videoTheme': city.videoTheme,
      'timeZoneOffsetMinutes': city.timeZoneOffsetMinutes,
      'displayOrder': 0,
      'createdAt': Date.now(),
      'updatedAt': Date.now()
    };
    await this.rdbStore.insert(CityStorage.TABLE_CITIES, valueBucket);
  }

  async getAllCities(): Promise<City[]> {
    if (!this.rdbStore) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates(CityStorage.TABLE_CITIES);
    predicates.orderByAsc('displayOrder');
    const resultSet = await this.rdbStore.query(predicates);
    const cities: City[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const city = new City(
          resultSet.getString(resultSet.getColumnIndex('id')),
          resultSet.getString(resultSet.getColumnIndex('name')),
          resultSet.getString(resultSet.getColumnIndex('country')),
          {
            latitude: resultSet.getDouble(resultSet.getColumnIndex('latitude')),
            longitude: resultSet.getDouble(resultSet.getColumnIndex('longitude'))
          },
          resultSet.getLong(resultSet.getColumnIndex('source')),
          resultSet.getString(resultSet.getColumnIndex('videoTheme')),
          resultSet.getLong(resultSet.getColumnIndex('timeZoneOffsetMinutes'))
        );
        cities.push(city);
      }
    } finally {
      resultSet.close();
    }
    return cities;
  }
}
```

```ts
// data/storage/AppPreferences.ets
import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';

export class AppPreferences {
  private prefs: preferences.Preferences | null = null;

  async init(context: common.UIAbilityContext): Promise<void> {
    this.prefs = await preferences.getPreferences(context, 'app_settings');
  }

  async setBackgroundMode(mode: string): Promise<void> {
    if (!this.prefs) {
      return;
    }
    await this.prefs.put('background_mode', mode);
    await this.prefs.flush();
  }

  async getBackgroundMode(): Promise<string> {
    if (!this.prefs) {
      return 'gradient';
    }
    const value = await this.prefs.get('background_mode', 'gradient');
    return value as string;
  }

  async isAutoLocationEnabled(): Promise<boolean> {
    if (!this.prefs) {
      return true;
    }
    const value = await this.prefs.get('auto_location', true);
    return value as boolean;
  }
}
```
- `WeatherCacheStorage`：使用 `cityId` 作为主键，序列化 `WeatherSnapshot` JSON + 更新时间；提供 `get/save/clearExpired` 方法，为仓库层提供读写接口。

### 6.4 仓库层缓存策略
- `WeatherRepository` 负责统一调度真实服务、缓存与 Mock，确保“缓存优先 → 网络刷新 → Mock 兜底”的链路顺滑。
- 缓存校验逻辑建议 30 分钟失效，失败时记录日志并自动回退到本地数据。

```ts
export class WeatherRepository {
  private service: WeatherService;
  private mockRepo: MockWeatherRepository;
  private cacheStorage: WeatherCacheStorage;

  constructor(
    service: WeatherService,
    mockRepo: MockWeatherRepository,
    cacheStorage: WeatherCacheStorage
  ) {
    this.service = service;
    this.mockRepo = mockRepo;
    this.cacheStorage = cacheStorage;
  }

  async fetchWeather(
    city: City,
    forceRefresh: boolean
  ): Promise<WeatherSnapshot> {
    if (!forceRefresh) {
      const cached = await this.cacheStorage.get(city.id);
      if (cached && this.isCacheValid(cached)) {
        console.info('[WeatherRepository] Using cached data');
        return cached;
      }
    }

    try {
      const snapshot = await this.service.fetchWeather(city.id, city.coordinates);
      await this.cacheStorage.save(snapshot);
      return snapshot;
    } catch (error) {
      let err = error as Error;
      console.error('[WeatherRepository] API failed:', err.message);
      const cached = await this.cacheStorage.get(city.id);
      if (cached) {
        console.warn('[WeatherRepository] Using stale cache due to API failure');
        return cached;
      }
      console.warn('[WeatherRepository] Using mock data');
      return this.mockRepo.getMockWeather(city.id);
    }
  }

  private isCacheValid(snapshot: WeatherSnapshot): boolean {
    const lastUpdate = new Date(snapshot.lastUpdatedIso);
    const now = new Date();
    const diffMinutes = (now.getTime() - lastUpdate.getTime()) / (1000 * 60);
    const cacheMinutes = this.getCacheDuration(snapshot);
    return diffMinutes < cacheMinutes;
  }

  private getCacheDuration(snapshot: WeatherSnapshot): number {
    const weatherCode = snapshot.current.condition.iconCode.toLowerCase();
    if (weatherCode.includes('thunder') || weatherCode.includes('storm')) {
      return 10;
    }
    if (weatherCode.includes('rain') || weatherCode.includes('snow') || weatherCode.includes('fog')) {
      return 20;
    }
    if (snapshot.daily.length > 0) {
      const today = snapshot.daily[0];
      if (today.maxTempC - today.minTempC > 15) {
        return 25;
      }
    }
    if (weatherCode.includes('sunny') || weatherCode.includes('clear')) {
      return 45;
    }
    return 30;
  }
}
```

### 6.5 网络韧性与异步策略
1. **运行时数据校验**：引入 `zod` 或轻量自研校验器，防止后端字段异常导致崩溃。
   ```ts
   import { z } from 'zod';

   const WeatherDataSchema = z.object({
     temperature: z.number().min(-50).max(60),
     humidity: z.number().min(0).max(100)
   });

   const parseWeatherData = (data: unknown): WeatherData => {
     return WeatherDataSchema.parse(data);
   };
   ```
2. **请求取消 + 超时 + 重试**：WeatherService 统一使用 `AbortController`、自定义超时、指数退避与抖动策略，可重试的错误限定在网络、5xx、超时场景。
   ```ts
   class WeatherService {
     private abortController: AbortController | null = null;
     private requestTimeoutHandle: number | null = null;

     async fetchWeather(cityId: string, coordinates: Coordinates): Promise<WeatherSnapshot> {
       this.abortController?.abort();
       this.abortController = new AbortController();

       for (let attempt = 1; attempt <= this.retryConfig.maxRetries; attempt++) {
         try {
           const requestPromise = httpRequest.request(this.buildQuery(coordinates), {
             signal: this.abortController.signal,
             // ...
           });
           const timeoutPromise = new Promise<never>((_, reject) => {
             this.requestTimeoutHandle = setTimeout(() => reject(new Error('timeout')), this.retryConfig.timeout);
           });
           const response = await Promise.race([requestPromise, timeoutPromise]);
           // 解析 + 校验
           return this.mapToSnapshot(cityId, parseWeatherData(response));
         } catch (error) {
           if (!this.isRetryableError(error as Error) || attempt === this.retryConfig.maxRetries) {
             throw error;
           }
           await this.sleep(this.calculateRetryDelay(attempt));
         } finally {
           if (this.requestTimeoutHandle !== null) {
             clearTimeout(this.requestTimeoutHandle);
             this.requestTimeoutHandle = null;
           }
         }
       }
       throw new Error('Unreachable');
     }
   }
   ```

### 6.6 定位服务多级回退
- **权限 → 开关 → 精确定位**：首次调用前通过 `abilityAccessCtrl` 检查 `LOCATION`、`APPROXIMATELY_LOCATION`，若拒绝则弹出引导弹窗。
- **超时/失败回退**：`geoLocationManager.getCurrentLocation` 超时 15s，失败码 201/301 分别引导权限或打开定位，否则尝试 IP 定位，再不行使用默认城市（如北京）。
- **API 封装**：
  ```ts
  try {
    return await geoLocationManager.getCurrentLocation(options);
  } catch (error) {
    if ((error as BusinessError).code === LocationErrorCode.TIMEOUT) {
      return await this.fallbackToIPLocation();
    }
    return this.getDefaultLocation();
  }
  ```
- **权限声明**：`module.json5` 中一次性增补 `INTERNET/GET_NETWORK_INFO/LOCATION/APPROXIMATELY_LOCATION/LOCATION_IN_BACKGROUND`，并在字符串资源中写明 `reason`。

## 七、数据流与接口策略
1. **启动**：读取 `cities` 列表 → 若为空则尝试定位添加当前城市 → 并行加载缓存与网络数据 → 刷新 UI 与时间戳。
2. **刷新**：触发下拉/按钮/摇一摇 → 调用 WeatherService → 成功写入缓存 → 失败则提示并保留旧数据。
3. **城市增删**：添加时校验重复 → 写入 RDB → 触发一次即时拉取；删除时移除对应缓存。
4. **趋势图数据处理**：从 API 小时数组提取温度/降雨概率，转换为 `ChartPoint` 或 `ListItem` 数据源，驱动 Chart 组件；若走 Plan B/C，则直接提供 `time + value + height` 三元组即可。
5. **智能建议**：根据当前城市天气结构调用规则表，返回 `AdviceItem[]`，与 UI 绑定。

## 八、Mock 数据与并行双轨策略
- **目标**：防止瀑布式节奏导致视觉被功能卡住，保证“最抓眼球”的部分从第 1 天就进入打磨，并彻底杜绝集成阶段的结构错配。
- **Mock 数据**：
    1. Track F 在 Day 1 的首要任务是用 Postman/cURL/ArkTS 请求真实天气 API，获取完整 JSON；
    2. 将该原始响应原封不动保存为 `mock_data.ts`（或 `MockWeatherRepo`），仅额外加类型标注/导出语句；
    3. Track V 全程引用此 Mock，不允许手写字段或擅自修改结构；若 API 字段调整，Track F 负责同步更新 Mock，使两条工作流始终对齐。
- **双轨协作**：
  | 工作流 | 覆盖范围 | 每日协同要点 |
  | --- | --- | --- |
  | **Track V（Visual）** | 视频背景、毛玻璃卡片、Swiper 布局、过场动画、情绪文案 | 以 Mock 数据驱动 UI，Day 1 完成 Video/AnimatedImage/静态渐变三套资源与压力测试，随时可切换；提交可视化 Demo，制定视觉规范。 |
  | **Track F（Function）** | WeatherService、CityManager、RDB/Preferences、定位、刷新逻辑 | 专注 API 联调、持久化、错误处理；每天同步字段变化，确保最终可与 Track V 无缝对接。 |
- **字段契约检查**：每次 API 结构或类型发生变化时，由 Track F 更新 mock 文件并提供 Type 定义/简单校验脚本（`MockTypeCheck`），Track V 在合并前执行校验，确保“集成关”仅是数据源切换而非 UI 重构。
- **切换机制**：当 Track F 某个接口完成后，仅需在 `Repository` 层替换数据源即可完成串联，视觉层无需大改。

## 九、实施计划（4 周双轨推进）
| 周次 | Track V（视觉体验） | Track F（功能落地） | 阶段产出 |
| --- | --- | --- | --- |
| 第 1 周：起势 | 使用真实 API 生成的 Mock 数据完成 Video→AnimatedImage→渐变三套背景、毛玻璃卡片与 Swiper 结构；记录每套方案在滑动/刷新场景下的 FPS、内存与耗电数据，输出视觉样稿与样式表 | 修复 `module.json5` 尾逗号等基础配置，验证 WeatherService；完成 `CityStorage`、`WeatherCacheStorage`、`AppPreferences` 初始化，接好 RDB/Preferences，打通 CRUD 并写首个自动定位流程 | 可播放的沉浸式 UI Demo + 白盒数据链路 |
| 第 2 周：融合 | 打磨玻璃态卡片、背景遮罩、刷新动效，完善“上次更新”时间戳展示；完成夜景/日景样式切换与 AnimatedImage 兜底效果 | 切换至真实天气数据，完成下拉刷新、缓存写入与手动/自动刷新；实现城市增删排序、`Swiper` 联动与“缓存 → API → Mock”回退链路 | 真实数据驱动的核心界面 |
| 第 3 周：数据与智能 | 基于真实数据完成 24h 趋势 mini 图（Chart→List→Stack 三级兜底）、3~5 日故事线视觉、情绪化文案 + 智能建议模块 | 完成趋势数据解析、智能建议规则引擎、离线模式提示；首启自动定位与权限文案打磨；补齐网络错误提醒与日志埋点 | 功能与视觉双线闭环 |
| 第 4 周：彩蛋与打磨 | 统一动效节奏、细化字体/配色、补充 Demo 所需素材；若时间允许，完善摇一摇刷新动画与夜间动态主题 | （可选）实现摇一摇刷新、夜间自动切换、Shake to Refresh 传感器调优；完成性能/兼容/离线测试，整理演示脚本与实验报告 | 最终演示包、测试记录、彩蛋功能（若完成） |

## 十、测试与验收
- **功能**：网络异常回退、城市 CRUD、缓存一致性、定位授权流程。
- **性能**：视频背景播放帧率、Swiper 滑动流畅度、刷新响应时间。
- **体验**：视觉元素在不同屏幕上的适配（字体、模糊度）、夜间场景可读性。
- **可选功能验证**：摇一摇阈值、防误触逻辑（若实现）、主题切换正确性（若实现）。
- **验收材料**：实验报告、关键界面截图、数据库表结构示意、测试用例、演示视频/现场 Demo。

### 10.1 性能量化指标
| 场景 | 合格阈值 | 测试方法 |
| --- | --- | --- |
| Swiper 快速滑动 10 页 | 平均帧率 ≥ 50 FPS | 开启性能面板（开发模式）记录 |
| 视频背景循环播放 | 内存增量 ≤ 50 MB，CPU 占用 ≤ 45% | `hd/fullhd/4k` 各跑 5 min |
| 冷启动 | ≤ 1.5 s | 从点击图标到首屏渲染完成 |
| 下拉刷新 | 数据返回 ≤ 800 ms (缓存命中) / ≤ 2.5 s (真实网络) | 分别在 Wi-Fi、4G 下测试 |
| 定位耗时 | 首次定位 ≤ 5 s，失败回退提示 ≤ 1 s | 开关定位/断网场景 |

### 10.2 异常流测试
- **网络极端情况**：利用 `networkHelper.mockLatency(3000)`、`mockPacketLoss(0.3)` 模拟高延迟、丢包，验证超时重试与 Mock 回退。
- **数据库损坏恢复**：手动 `relationalStore.deleteRdbStore` 后重新启动，确保自动建表成功。
- **定位权限拒绝**：拒绝精确定位 → 观察弹窗提示 → 允许后自动重试。
- **视频资源缺失**：删掉某个视频文件，确认 `AtmosphereBackground` 自动切换 AnimatedImage/渐变。
- **API 不可用**：断网或返回 5xx，验证仓库层打印 `Using stale cache` 并展示缓存时间戳。

## 十一、展示与答辩要点
1. **Demo 顺序**：自动定位 → 沉浸背景 + 情绪文案 → 左右滑切多城 → 下拉刷新并显示时间戳 → 展示趋势图与智能建议 →（若有）摇一摇刷新彩蛋。
2. **讲述主线**：强调“用视频背景替代复杂 Canvas”实现低成本视觉冲击；说明 Must/Should/Nice 分层以确保按时交付。
3. **答辩准备**：准备规则表、数据表结构图、视频素材来源说明；若彩蛋未实现，可展示原型或可行性说明，展示理性取舍。
4. **故障预案**：提前写好“视频失败→切 Plan C、API 失败→切 Mock、定位异常→手动输入”应急脚本，并在开发模式开启性能叠层，实时展示 FPS/内存数据。

> 调整后的方案在保证“第一眼惊艳”的同时，严格控制开发复杂度。通过“必做 + 增强 + 彩蛋”的分层策略，即便只完成前两层，也能交付一个视觉亮眼、逻辑简洁且满足课程评分标准的作品。

## 十二、立即行动项
1. **修复配置**：清理 `module.json5` 语法（含第 47 行尾逗号），补充 `deviceTypes`、`apiVersion` 与全量权限条目，并同步字符串资源。
2. **数据库迁移**：为 `CityStorage`/`WeatherCacheStorage` 添加版本号、`schema_metadata`、`onUpgrade` 与损坏恢复逻辑，跑通 v1→v2 升级。
3. **网络服务加固**：在 `WeatherService` 加上 `AbortController`、超时定时器、指数退避重试及 `zod` 数据校验，确保 5xx 自动重试。
4. **定位多级回退**：实现 `LocationService` 权限检测、定位开关提示、IP 回退与默认城市兜底，联调权限引导弹窗。
5. **性能自适应**：完成 `DevicePerformanceDetector` + 背景模式自动切换，记录视频/动图/渐变三档 FPS、内存数据，形成 Week 1 压测报告。
