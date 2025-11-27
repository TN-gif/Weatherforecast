# 主题键（themeKey）逻辑说明

## 核心原则

**主题键分为两个层次：**
1. **基础主题键**（天气类型）：`sunny` / `rainy` / `snow`
2. **最终主题键**（天气+时间）：`sunny_day` / `sunny_night` / `rainy_day` / `rainy_night` / `snow_day` / `snow_night`

---

## 数据流详解

### 第1步：天气服务返回基础主题键

**位置：** `QWeatherService.ets` 和 `OpenMeteoService.ets`

**规则：** 只返回天气类型，**不包含时间信息**

```typescript
// QWeatherService.mapWeatherText()
if (text.includes('晴')) {
  return { themeKey: 'sunny' };  // ✅ 只有天气类型
}
if (text.includes('雨')) {
  return { themeKey: 'rainy' };  // ✅ 只有天气类型
}
if (text.includes('雪')) {
  return { themeKey: 'snow' };   // ✅ 只有天气类型
}
```

**为什么不包含时间？**
- 天气服务不知道用户设备的当前时间
- 天气服务不知道城市的时区
- 时间判断应该在客户端进行

---

### 第2步：判断城市当地时间

**位置：** `WeatherHomePage.ets` 的 `isNightTime()` 方法

**规则：** 基于**城市当地时间**判断白天/夜间

```typescript
private isNightTime(cityState?: CityWeatherState | null): boolean {
  // 获取城市时区偏移量
  let timezoneOffsetMinutes = 0;
  if (cityState?.snapshot?.timezoneOffsetMinutes !== undefined) {
    timezoneOffsetMinutes = cityState.snapshot.timezoneOffsetMinutes;
  }
  
  // 计算城市当地时间
  const localHours = this.getCityLocalHours(timezoneOffsetMinutes);
  
  // 夜间判定：18:00 - 06:00
  return localHours >= 18 || localHours <= 6;
}
```

**示例：**
- 北京时间 20:00，北京当地 20:00 → 夜间 ✓
- 北京时间 20:00，洛杉矶当地 04:00 → 夜间 ✓
- 北京时间 20:00，伦敦当地 12:00 → 白天 ✓

---

### 第3步：组合生成最终主题键

**位置：** `WeatherHomePage.ets` 的 `updateThemeWithStates()` 方法

**规则：** 基础主题键 + 时间判断 = 最终主题键

```typescript
// 1. 获取基础主题键（只有天气类型）
const condition = state.snapshot.current.condition;
const weatherKey = condition.themeKey;  // 'sunny' / 'rainy' / 'snow'

// 2. 判断当地时间
const isNight = this.isNightTime(currentCityState);  // true / false

// 3. 组合生成最终主题键
const finalThemeKey = ThemeConstants.getThemeWithTimeAware(weatherKey, isNight).themeKey;
```

---

### 第4步：ThemeConstants 添加时间后缀

**位置：** `ThemeConstants.ets` 的 `getThemeWithTimeAware()` 方法

**规则：** 如果是夜间，添加 `_night` 后缀

```typescript
static getThemeWithTimeAware(weatherKey: string, isNight: boolean = false): VideoThemeAsset {
  let targetKey = weatherKey;
  
  // 如果是夜间且不是专门的夜间主题，尝试找夜间版本
  if (isNight && !weatherKey.includes('night')) {
    const nightKey = `${weatherKey}_night`;  // sunny → sunny_night
    const nightTheme = ThemeConstants.THEMES.find(theme => theme.themeKey === nightKey);
    if (nightTheme) {
      targetKey = nightKey;
    } else {
      // 如果没有对应的夜间版本，使用sunny_night作为默认夜间主题
      targetKey = 'sunny_night';
    }
  }
  
  return ThemeConstants.getTheme(targetKey);
}
```

**转换规则：**
| 基础主题键 | 白天 (isNight=false) | 夜间 (isNight=true) |
|-----------|---------------------|-------------------|
| `sunny` | `sunny` | `sunny_night` |
| `rainy` | `rainy` | `rainy_night` |
| `snow` | `snow` | `snow_night` |

---

## 完整示例

### 示例1：北京晴天，白天
```
1. 和风天气返回：text = "晴"
2. QWeatherService.mapWeatherText() → themeKey = "sunny"
3. 北京当地时间：14:00
4. isNightTime() → false (14:00 在 07:00-17:59 之间)
5. getThemeWithTimeAware("sunny", false) → "sunny"
6. 视频文件：weather/sunny_day.mp4 ✓
```

### 示例2：北京晴天，夜间
```
1. 和风天气返回：text = "晴"
2. QWeatherService.mapWeatherText() → themeKey = "sunny"
3. 北京当地时间：20:00
4. isNightTime() → true (20:00 >= 18:00)
5. getThemeWithTimeAware("sunny", true) → "sunny_night"
6. 视频文件：weather/sunny_night.mp4 ✓
```

### 示例3：洛杉矶晴天，当地白天（北京时间夜间）
```
1. 和风天气返回：text = "晴"
2. QWeatherService.mapWeatherText() → themeKey = "sunny"
3. 北京时间：20:00，洛杉矶当地时间：04:00
4. isNightTime(洛杉矶) → true (04:00 <= 06:00)
5. getThemeWithTimeAware("sunny", true) → "sunny_night"
6. 视频文件：weather/sunny_night.mp4 ✓
```

### 示例4：伦敦雨天，当地白天（北京时间夜间）
```
1. 和风天气返回：text = "小雨"
2. QWeatherService.mapWeatherText() → themeKey = "rainy"
3. 北京时间：20:00，伦敦当地时间：12:00
4. isNightTime(伦敦) → false (12:00 在 07:00-17:59 之间)
5. getThemeWithTimeAware("rainy", false) → "rainy"
6. 视频文件：weather/rainy_day.mp4 ✓
```

---

## 为什么这样设计？

### 优点1：关注点分离
- **天气服务**：只负责识别天气类型
- **客户端**：负责判断时间和组合主题

### 优点2：支持多时区
- 每个城市使用自己的当地时间
- 不受设备时区影响

### 优点3：易于扩展
- 添加新天气类型：只需在天气服务中添加映射
- 添加新时间段：只需修改 `getThemeWithTimeAware()`

### 优点4：代码清晰
- 基础主题键简单明了（`sunny`/`rainy`/`snow`）
- 时间逻辑集中在一个地方

---

## 常见误解

### ❌ 误解1：天气服务应该返回 `sunny_day` 或 `sunny_night`
**错误原因：** 天气服务不知道当前时间和时区

**正确做法：** 天气服务只返回 `sunny`，客户端根据时间添加后缀

### ❌ 误解2：多云/阴天应该有独立的主题
**错误原因：** 没有 `cloudy` 主题的视频资源

**正确做法：** 多云/阴天映射到 `sunny`，使用晴天视频

### ❌ 误解3：应该使用设备本地时间判断白天/夜间
**错误原因：** 不同城市有不同时区

**正确做法：** 使用城市当地时间判断

---

## ThemeConstants 中的主题配置

### 基础主题（白天）
```typescript
{
  themeKey: 'sunny',
  videoResource: 'rawfile/weather/sunny_day.mp4',
  isNightMode: false
},
{
  themeKey: 'rainy',
  videoResource: 'rawfile/weather/rainy_day.mp4',
  isNightMode: false
},
{
  themeKey: 'snow',
  videoResource: 'rawfile/weather/snow_day.mp4',
  isNightMode: false
}
```

### 夜间主题
```typescript
{
  themeKey: 'sunny_night',
  videoResource: 'rawfile/weather/sunny_night.mp4',
  isNightMode: true
},
{
  themeKey: 'rainy_night',
  videoResource: 'rawfile/weather/rainy_night.mp4',
  isNightMode: true
},
{
  themeKey: 'snow_night',
  videoResource: 'rawfile/weather/snow_night.mp4',
  isNightMode: true
}
```

**注意：** 
- 基础主题的 `themeKey` 不包含 `_day` 后缀
- 这是为了简化映射逻辑
- `getThemeWithTimeAware()` 会自动添加 `_night` 后缀

---

## 总结

### 核心逻辑
```
天气类型 (sunny/rainy/snow) + 时间判断 (day/night) = 最终主题 (sunny_night/rainy_day等)
```

### 数据流
```
天气API → 基础主题键 → 时间判断 → 最终主题键 → 视频文件
```

### 关键方法
1. `QWeatherService.mapWeatherText()` - 返回基础主题键
2. `WeatherHomePage.isNightTime()` - 判断城市当地时间
3. `ThemeConstants.getThemeWithTimeAware()` - 组合生成最终主题键
4. `AtmosphereBackground.updateVideoSource()` - 加载对应视频

🎯 **这样设计确保了每个城市都能根据自己的当地时间显示正确的白天/夜间背景视频！**
