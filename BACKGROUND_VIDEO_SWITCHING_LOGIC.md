# 背景视频切换逻辑详解

## 概述

背景视频的切换基于两个核心因素：
1. **天气条件**（晴天、雨天、雪天等）
2. **时间段**（白天 vs 夜间）

---

## 完整切换流程

### 第一步：天气数据获取与映射

#### 1.1 和风天气API返回天气文本
例如：`"晴"`, `"多云"`, `"小雨"`, `"大雪"`, `"雷阵雨"` 等

#### 1.2 天气文本映射到 themeKey
**位置：** `QWeatherService.ets` 的 `mapWeatherText()` 方法

```typescript
private mapWeatherText(text: string): WeatherCondition {
  // 1. 晴天
  if (text.includes('晴')) {
    return { 
      description: text, 
      iconCode: 'sunny', 
      themeKey: 'sunny',  // ← 关键：映射到 sunny
      emotion: '阳光明媚，适合出行' 
    };
  }
  
  // 2. 多云/阴天 → 也映射到 sunny
  if (text.includes('云') || text.includes('阴')) {
    return { 
      description: text, 
      iconCode: 'cloudy', 
      themeKey: 'sunny',  // ← 注意：多云也用 sunny 主题
      emotion: '多云天气，记得补水' 
    };
  }
  
  // 3. 雨天
  if (text.includes('雨')) {
    return { 
      description: text, 
      iconCode: 'rainy', 
      themeKey: 'rainy',  // ← 映射到 rainy
      emotion: '雨天路滑，注意安全' 
    };
  }
  
  // 4. 雪天
  if (text.includes('雪')) {
    return { 
      description: text, 
      iconCode: 'snow', 
      themeKey: 'snow',  // ← 映射到 snow
      emotion: '雪天注意保暖' 
    };
  }
  
  // 5. 雷雨 → 映射到 rainy
  if (text.includes('雷')) {
    return { 
      description: text, 
      iconCode: 'storm', 
      themeKey: 'rainy',  // ← 雷雨也用 rainy 主题
      emotion: '雷雨天气，减少外出' 
    };
  }
  
  // 6. 默认 → sunny
  return { 
    description: text, 
    iconCode: 'sunny', 
    themeKey: 'sunny',  // ← 默认使用 sunny
    emotion: '天气不错' 
  };
}
```

**映射规则总结：**
| 天气文本 | themeKey | 说明 |
|---------|----------|------|
| 包含"晴" | `sunny` | 晴天 |
| 包含"云"或"阴" | `sunny` | 多云/阴天也用晴天主题 |
| 包含"雨" | `rainy` | 雨天 |
| 包含"雪" | `snow` | 雪天 |
| 包含"雷" | `rainy` | 雷雨用雨天主题 |
| 其他 | `sunny` | 默认晴天 |

---

### 第二步：判断白天/夜间

#### 2.1 时间判定逻辑
**位置：** `WeatherHomePage.ets` 的 `isNightTime()` 方法

```typescript
private isNightTime(): boolean {
  const now = new Date();
  const hours = now.getHours();
  return hours >= 18 || hours <= 6;
}
```

**判定规则：**
- **夜间：** 18:00 - 次日 06:00（包含18点和6点）
- **白天：** 07:00 - 17:59

**时间轴示意：**
```
00:00 ─────── 06:00 ─────── 18:00 ─────── 23:59
  夜间          白天          夜间
```

---

### 第三步：组合天气+时间生成最终主题

#### 3.1 主题组合逻辑
**位置：** `ThemeConstants.ets` 的 `getThemeWithTimeAware()` 方法

```typescript
static getThemeWithTimeAware(weatherKey: string, isNight: boolean = false): VideoThemeAsset {
  let targetKey = weatherKey;
  
  // 如果是夜间且不是专门的夜间主题，尝试找夜间版本
  if (isNight && !weatherKey.includes('night')) {
    const nightKey = `${weatherKey}_night`;
    const nightTheme = ThemeConstants.THEMES.find(theme => theme.themeKey === nightKey);
    if (nightTheme) {
      targetKey = nightKey;  // 使用夜间版本
    } else {
      // 如果没有对应的夜间版本，使用sunny_night作为默认夜间主题
      targetKey = 'sunny_night';
    }
  }
  
  return ThemeConstants.getTheme(targetKey);
}
```

**组合规则：**
| 天气 themeKey | 白天 (07:00-17:59) | 夜间 (18:00-06:00) |
|--------------|-------------------|-------------------|
| `sunny` | `sunny` | `sunny_night` |
| `rainy` | `rainy` | `rainy_night` |
| `snow` | `snow` | `snow_night` |

---

### 第四步：主题资源定义

#### 4.1 可用主题列表
**位置：** `ThemeConstants.ets` 的 `THEMES` 数组

```typescript
static readonly THEMES: VideoThemeAsset[] = [
  // 白天主题
  {
    themeKey: 'sunny',
    videoResource: 'rawfile/weather/sunny_day.mp4',
    animatedImageResource: 'rawfile/weather/sunny.webp',
    gradientColors: ['#87CEEB', '#4A90E2'],
    accentColor: 'rgba(255, 223, 0, 0.4)',
    mode: BackgroundMode.VIDEO,
    lottieResource: 'rawfile/lottie/sun.json',
    isNightMode: false
  },
  {
    themeKey: 'rainy',
    videoResource: 'rawfile/weather/rainy_day.mp4',
    animatedImageResource: 'rawfile/weather/rainy.webp',
    gradientColors: ['#4A5A6A', '#2C3E50'],
    accentColor: 'rgba(173, 216, 230, 0.4)',
    mode: BackgroundMode.VIDEO,
    lottieResource: 'rawfile/lottie/rain.json',
    isNightMode: false
  },
  {
    themeKey: 'snow',
    videoResource: 'rawfile/weather/snow_day.mp4',
    animatedImageResource: 'rawfile/weather/snow.webp',
    gradientColors: ['#E6F3FF', '#B3D9FF'],
    accentColor: 'rgba(255, 255, 255, 0.5)',
    mode: BackgroundMode.VIDEO,
    lottieResource: 'rawfile/lottie/snow.json',
    isNightMode: false
  },
  
  // 夜间主题
  {
    themeKey: 'sunny_night',
    videoResource: 'rawfile/weather/sunny_night.mp4',
    animatedImageResource: 'rawfile/weather/sunny.webp',
    gradientColors: ['#2C3E50', '#3498DB'],
    accentColor: 'rgba(255, 223, 0, 0.3)',
    mode: BackgroundMode.VIDEO,
    lottieResource: 'rawfile/lottie/moon.json',
    isNightMode: true
  },
  {
    themeKey: 'rainy_night',
    videoResource: 'rawfile/weather/rainy_night.mp4',
    animatedImageResource: 'rawfile/weather/rainy.webp',
    gradientColors: ['#2C3E50', '#34495E'],
    accentColor: 'rgba(173, 216, 230, 0.3)',
    mode: BackgroundMode.VIDEO,
    lottieResource: 'rawfile/lottie/rain.json',
    isNightMode: true
  },
  {
    themeKey: 'snow_night',
    videoResource: 'rawfile/weather/snow_night.mp4',
    animatedImageResource: 'rawfile/weather/snow.webp',
    gradientColors: ['#2C3E50', '#5D6D7E'],
    accentColor: 'rgba(255, 255, 255, 0.4)',
    mode: BackgroundMode.VIDEO,
    lottieResource: 'rawfile/lottie/snow.json',
    isNightMode: true
  }
];
```

**主题资源总结：**
| 主题 Key | 视频文件 | 使用场景 |
|---------|---------|---------|
| `sunny` | `sunny_day.mp4` | 白天晴天/多云/阴天 |
| `rainy` | `rainy_day.mp4` | 白天雨天/雷雨 |
| `snow` | `snow_day.mp4` | 白天雪天 |
| `sunny_night` | `sunny_night.mp4` | 夜间晴天/多云/阴天 |
| `rainy_night` | `rainy_night.mp4` | 夜间雨天/雷雨 |
| `snow_night` | `snow_night.mp4` | 夜间雪天 |

---

### 第五步：背景视频组件监听主题变化

#### 5.1 AtmosphereBackground 组件
**位置：** `AtmosphereBackground.ets`

```typescript
@Component
export struct AtmosphereBackground {
  @StorageProp('themeKey') themeKey: string = 'sunny_day';
  
  build() {
    Video({ src: this.getVideoSource() })
      .autoPlay(true)
      .loop(true)
      .muted(true)
      .objectFit(ImageFit.Cover)
      .width('100%')
      .height('100%')
  }
  
  private getVideoSource(): string {
    const theme = ThemeConstants.getTheme(this.themeKey);
    return theme.videoResource || 'rawfile/weather/sunny_day.mp4';
  }
}
```

**关键点：**
- 使用 `@StorageProp('themeKey')` 监听 AppStorage 中的主题变化
- 当 `themeKey` 变化时，自动重新渲染，加载新的视频资源

---

## 完整示例场景

### 场景1：白天晴天
```
1. 和风天气返回：text = "晴"
2. mapWeatherText() → themeKey = "sunny"
3. isNightTime() → false (假设当前时间 14:00)
4. getThemeWithTimeAware("sunny", false) → "sunny"
5. 背景视频：sunny_day.mp4
```

### 场景2：夜间晴天
```
1. 和风天气返回：text = "晴"
2. mapWeatherText() → themeKey = "sunny"
3. isNightTime() → true (假设当前时间 20:00)
4. getThemeWithTimeAware("sunny", true) → "sunny_night"
5. 背景视频：sunny_night.mp4
```

### 场景3：白天小雨
```
1. 和风天气返回：text = "小雨"
2. mapWeatherText() → themeKey = "rainy"
3. isNightTime() → false (假设当前时间 10:00)
4. getThemeWithTimeAware("rainy", false) → "rainy"
5. 背景视频：rainy_day.mp4
```

### 场景4：夜间雷阵雨
```
1. 和风天气返回：text = "雷阵雨"
2. mapWeatherText() → themeKey = "rainy" (雷雨映射到rainy)
3. isNightTime() → true (假设当前时间 22:00)
4. getThemeWithTimeAware("rainy", true) → "rainy_night"
5. 背景视频：rainy_night.mp4
```

### 场景5：白天多云
```
1. 和风天气返回：text = "多云"
2. mapWeatherText() → themeKey = "sunny" (多云映射到sunny)
3. isNightTime() → false (假设当前时间 15:00)
4. getThemeWithTimeAware("sunny", false) → "sunny"
5. 背景视频：sunny_day.mp4
```

### 场景6：夜间大雪
```
1. 和风天气返回：text = "大雪"
2. mapWeatherText() → themeKey = "snow"
3. isNightTime() → true (假设当前时间 19:00)
4. getThemeWithTimeAware("snow", true) → "snow_night"
5. 背景视频：snow_night.mp4
```

---

## 触发时机

背景视频会在以下情况下切换：

### 1. 应用启动
```typescript
// WeatherHomePage.ets - aboutToAppear()
await this.refresh(false);  // 加载天气数据
this.updateThemeWithStates(validStates, this.activeIndex);  // 更新主题
```

### 2. 下拉刷新
```typescript
// WeatherHomePage.ets - refresh()
const states = await this.controller.loadAll(force);
this.cityStates = validStates;
this.dataVersion++;
this.updateThemeWithStates(validStates, this.activeIndex);  // 更新主题
```

### 3. 切换城市
```typescript
// WeatherHomePage.ets - Swiper.onChange()
.onChange((index: number) => {
  this.activeIndex = index;
  this.updateThemeWithStates(this.cityStates, index);  // 更新主题
})
```

### 4. 添加新城市后
```typescript
// WeatherHomePage.ets - refreshAndJumpToCity()
await this.refresh(true);
this.updateThemeWithStates(this.cityStates, targetIndex);  // 更新主题
```

### 5. 后台自动刷新（每5分钟）
```typescript
// BackgroundRefreshService.ets
this.backgroundRefreshService.setController(this.controller, (states) => {
  this.cityStates = states;
  this.dataVersion++;
  this.updateThemeWithStates(states, this.activeIndex);  // 更新主题
});
```

---

## 关键代码路径

### 主题更新核心方法
```typescript
// WeatherHomePage.ets
private updateThemeWithStates(states: CityWeatherState[], index: number): void {
  const isNight = this.isNightTime();  // 判断白天/夜间
  
  if (states.length === 0 || index < 0 || index >= states.length) {
    // 无数据，使用默认主题
    const defaultTheme = ThemeConstants.getThemeWithTimeAware('sunny', isNight).themeKey;
    AppStorage.setOrCreate('themeKey', defaultTheme);
    return;
  }
  
  const state = states[index];
  if (!state || !state.snapshot) {
    // 城市无天气数据，使用默认主题
    const defaultTheme = ThemeConstants.getThemeWithTimeAware('sunny', isNight).themeKey;
    AppStorage.setOrCreate('themeKey', defaultTheme);
    return;
  }
  
  // 获取天气条件的 themeKey
  const condition = state.snapshot.current.condition;
  console.info(`[WeatherHomePage] 🌤️ 当前城市: ${state.city.name}, 天气条件themeKey: ${condition.themeKey}`);
  
  // 组合天气+时间，生成最终主题
  const newThemeKey = ThemeConstants.getThemeWithTimeAware(condition.themeKey, isNight).themeKey;
  console.info(`[WeatherHomePage] 🎨 最终主题: ${newThemeKey}`);
  
  // 更新到 AppStorage，触发背景视频切换
  AppStorage.setOrCreate('themeKey', newThemeKey);
}
```

---

## 数据流图

```
和风天气API
    ↓
天气文本 (e.g., "晴", "小雨", "大雪")
    ↓
mapWeatherText()
    ↓
themeKey (e.g., "sunny", "rainy", "snow")
    ↓
isNightTime() → 判断白天/夜间
    ↓
getThemeWithTimeAware(themeKey, isNight)
    ↓
最终主题 (e.g., "sunny_night", "rainy_day")
    ↓
AppStorage.setOrCreate('themeKey', ...)
    ↓
@StorageProp('themeKey') 监听变化
    ↓
AtmosphereBackground 重新渲染
    ↓
加载对应的视频文件 (e.g., sunny_night.mp4)
```

---

## 注意事项

### 1. 多云/阴天使用晴天主题
- **原因：** 没有专门的多云视频资源
- **映射：** `"多云"` → `themeKey: "sunny"` → 白天用 `sunny_day.mp4`，夜间用 `sunny_night.mp4`

### 2. 雷雨使用雨天主题
- **原因：** 没有专门的雷雨视频资源
- **映射：** `"雷阵雨"` → `themeKey: "rainy"` → 白天用 `rainy_day.mp4`，夜间用 `rainy_night.mp4`

### 3. 夜间时间判定
- **夜间：** 18:00 - 06:00（包含边界）
- **白天：** 07:00 - 17:59
- **注意：** 使用设备本地时间，不考虑城市时区

### 4. 默认主题
- 当无法获取天气数据时，使用 `sunny` 作为默认天气
- 夜间默认使用 `sunny_night`

### 5. 视频资源路径
- 所有视频文件位于：`entry/src/main/resources/rawfile/weather/`
- 命名规范：`{weather}_{time}.mp4`
  - 例如：`sunny_day.mp4`, `rainy_night.mp4`

---

## 扩展建议

### 如果要添加新的天气类型（如雾霾、沙尘暴）

#### 步骤1：添加视频资源
```
entry/src/main/resources/rawfile/weather/
  ├── haze_day.mp4
  └── haze_night.mp4
```

#### 步骤2：在 ThemeConstants 中添加主题定义
```typescript
{
  themeKey: 'haze',
  videoResource: 'rawfile/weather/haze_day.mp4',
  // ...
  isNightMode: false
},
{
  themeKey: 'haze_night',
  videoResource: 'rawfile/weather/haze_night.mp4',
  // ...
  isNightMode: true
}
```

#### 步骤3：在 QWeatherService 中添加映射规则
```typescript
private mapWeatherText(text: string): WeatherCondition {
  // ... 现有规则 ...
  
  if (text.includes('霾') || text.includes('雾')) {
    return { 
      description: text, 
      iconCode: 'haze', 
      themeKey: 'haze',  // ← 新增
      emotion: '雾霾天气，减少外出' 
    };
  }
  
  // ... 其他规则 ...
}
```

### 如果要调整白天/夜间时间段

修改 `isNightTime()` 方法：
```typescript
private isNightTime(): boolean {
  const now = new Date();
  const hours = now.getHours();
  // 例如：改为 19:00 - 07:00 为夜间
  return hours >= 19 || hours <= 7;
}
```

---

## 总结

背景视频切换的核心逻辑：
1. **天气文本** → **themeKey** (sunny/rainy/snow)
2. **当前时间** → **白天/夜间** (07:00-17:59 / 18:00-06:00)
3. **组合** → **最终主题** (sunny_day / sunny_night / rainy_day / rainy_night / snow_day / snow_night)
4. **AppStorage** → **触发背景视频切换**

整个流程是自动的，每次天气数据更新或切换城市时都会重新计算并更新背景视频。
