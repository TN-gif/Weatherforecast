# 时区集成完成报告

## 概述

已成功集成和风天气API的时区数据，实现基于城市当地时间的白天/夜间判定，确保背景视频根据城市当地时间正确切换。

---

## 修改的文件

### 1. `CitySearchService.ets`
**修改内容：**
- ✅ 更新 `CitySearchResult` 接口，添加 `timezone` 和 `utcOffset` 字段
- ✅ 修改 `mapQWeatherToSearchResult()` 方法，保存和风API返回的时区信息
- ✅ 修改 `convertToCity()` 方法，优先使用API返回的时区数据
- ✅ 新增 `parseUtcOffset()` 方法，解析UTC偏移量字符串（如 "+08:00"）

**关键代码：**
```typescript
export interface CitySearchResult {
  id: string;
  name: string;
  country: string;
  state?: string;
  coordinates: Coordinates;
  timezone?: string;  // 新增：时区名称，如 "Asia/Shanghai"
  utcOffset?: string;  // 新增：UTC偏移，如 "+08:00"
}

private parseUtcOffset(utcOffset: string): number {
  const offset = utcOffset.replace('UTC', '').trim();
  const sign = offset.startsWith('-') ? -1 : 1;
  const parts = offset.replace(/[+-]/, '').split(':');
  const hours = parseInt(parts[0]) || 0;
  const minutes = parseInt(parts[1]) || 0;
  return sign * (hours * 60 + minutes);
}
```

---

### 2. `QWeatherService.ets`
**修改内容：**
- ✅ 修改 `fetchWeather()` 方法签名，添加可选的 `timezoneOffsetMinutes` 参数
- ✅ 修改 `mapToSnapshot()` 方法，使用传入的时区偏移量
- ✅ 添加详细的时区日志输出

**关键代码：**
```typescript
async fetchWeather(
  cityId: string, 
  coordinates: Coordinates, 
  timezoneOffsetMinutes?: number  // 新增参数
): Promise<WeatherSnapshot> {
  // ...
}

private mapToSnapshot(
  cityId: string,
  nowData: QWeatherNow,
  hourlyData: QWeatherHourly,
  dailyData: QWeatherDaily,
  warningData: QWeatherWarning,
  minutelyData: QWeatherMinutely,
  airData: QWeatherAir,
  timezoneOffsetMinutes?: number  // 新增参数
): WeatherSnapshot {
  // 使用传入的实际时区偏移量，如果未提供则使用UTC+8作为默认值
  const actualTimezoneOffset = timezoneOffsetMinutes !== undefined ? timezoneOffsetMinutes : 480;
  
  const snapshot: WeatherSnapshot = {
    cityId: cityId,
    lastUpdatedIso: new Date().toISOString(),
    timezoneOffsetMinutes: actualTimezoneOffset,  // 使用实际时区
    // ...
  };
  return snapshot;
}
```

---

### 3. `OpenMeteoService.ets`
**修改内容：**
- ✅ 修改 `fetchWeather()` 方法签名，添加可选的 `timezoneOffsetMinutes` 参数
- ✅ 修改 `mapToSnapshot()` 方法，优先使用传入的时区，否则使用API返回的时区

**关键代码：**
```typescript
async fetchWeather(
  cityId: string, 
  coordinates: Coordinates, 
  timezoneOffsetMinutes?: number  // 新增参数
): Promise<WeatherSnapshot> {
  // ...
}

private mapToSnapshot(
  cityId: string, 
  data: OpenMeteoResponse, 
  timezoneOffsetMinutes?: number  // 新增参数
): WeatherSnapshot {
  // 优先使用传入的时区，否则使用API返回的时区
  const actualTimezoneOffset = timezoneOffsetMinutes !== undefined 
    ? timezoneOffsetMinutes 
    : Math.round(data.utc_offset_seconds / 60);
  
  return {
    cityId: cityId,
    lastUpdatedIso: new Date().toISOString(),
    timezoneOffsetMinutes: actualTimezoneOffset,  // 使用实际时区
    // ...
  };
}
```

---

### 4. `WeatherDataRouter.ets`
**修改内容：**
- ✅ 修改 `fetchWeather()` 方法签名，添加可选的 `timezoneOffsetMinutes` 参数
- ✅ 将时区参数传递给 `QWeatherService` 和 `OpenMeteoService`

**关键代码：**
```typescript
async fetchWeather(
  cityId: string, 
  coordinates: Coordinates, 
  timezoneOffsetMinutes?: number  // 新增参数
): Promise<WeatherSnapshot> {
  if (this.isInChina(coordinates)) {
    snapshot = await this.qweatherService.fetchWeather(cityId, coordinates, timezoneOffsetMinutes);
  } else {
    snapshot = await this.openMeteoService.fetchWeather(cityId, coordinates, timezoneOffsetMinutes);
  }
  return snapshot;
}
```

---

### 5. `WeatherRepository.ets`
**修改内容：**
- ✅ 修改 `loadWeather()` 方法，调用 `router.fetchWeather()` 时传入城市的时区信息

**关键代码：**
```typescript
async loadWeather(city: City, forceRefresh: boolean): Promise<WeatherSnapshot> {
  // ...
  // 传入城市的时区信息
  const snapshot: WeatherSnapshot = await this.router.fetchWeather(
    city.id, 
    city.coordinates, 
    city.timeZoneOffsetMinutes  // 传入时区
  );
  // ...
}
```

---

### 6. `WeatherHomePage.ets`
**修改内容：**
- ✅ 修改 `isNightTime()` 方法，接受 `CityWeatherState` 参数，使用城市当地时间判断
- ✅ 新增 `getCityLocalHours()` 方法，计算城市当地时间的小时数
- ✅ 更新所有调用 `isNightTime()` 的地方，传入城市状态

**关键代码：**
```typescript
/**
 * 判断指定城市是否为夜间
 * @param cityState 城市天气状态，包含时区信息
 * @returns true=夜间(18:00-06:00), false=白天(07:00-17:59)
 */
private isNightTime(cityState?: CityWeatherState): boolean {
  // 获取时区偏移量（分钟）
  let timezoneOffsetMinutes = 0;
  
  if (cityState) {
    // 优先使用 snapshot 中的时区（更准确）
    if (cityState.snapshot && cityState.snapshot.timezoneOffsetMinutes !== undefined) {
      timezoneOffsetMinutes = cityState.snapshot.timezoneOffsetMinutes;
    } 
    // 其次使用 city 中的时区
    else if (cityState.city && cityState.city.timeZoneOffsetMinutes !== undefined) {
      timezoneOffsetMinutes = cityState.city.timeZoneOffsetMinutes;
    }
  }
  
  // 获取城市当地时间
  const localHours = this.getCityLocalHours(timezoneOffsetMinutes);
  
  // 夜间判定：18:00 - 06:00
  return localHours >= 18 || localHours <= 6;
}

/**
 * 获取城市当地时间的小时数
 * @param timezoneOffsetMinutes 城市时区偏移量（分钟），相对于UTC
 * @returns 城市当地时间的小时数 (0-23)
 */
private getCityLocalHours(timezoneOffsetMinutes: number): number {
  const now = new Date();
  
  // 获取UTC时间戳
  const utcTime = now.getTime() + (now.getTimezoneOffset() * 60000);
  
  // 加上城市时区偏移，得到城市当地时间
  const cityLocalTime = new Date(utcTime + (timezoneOffsetMinutes * 60000));
  
  return cityLocalTime.getHours();
}
```

---

### 7. `TimeZoneService.ets`（新增）
**说明：**
- 创建了时区服务框架，包含 TimeZoneDB 和 Google Time Zone API 的集成方法
- 目前未使用，因为和风天气API已经提供了时区信息
- 保留作为备用方案

---

## 数据流

### 添加城市时的时区获取流程

```
用户搜索城市
    ↓
CitySearchService.searchCities()
    ↓
GeoServiceRouter → QWeatherGeoService
    ↓
和风天气城市搜索API返回：
{
  "name": "北京",
  "tz": "Asia/Shanghai",
  "utcOffset": "+08:00",
  ...
}
    ↓
mapQWeatherToSearchResult() 保存时区信息
    ↓
CitySearchResult {
  timezone: "Asia/Shanghai",
  utcOffset: "+08:00"
}
    ↓
convertToCity() 解析 utcOffset
    ↓
City {
  timeZoneOffsetMinutes: 480  // +08:00 = 480分钟
}
    ↓
保存到数据库
```

### 获取天气数据时的时区传递流程

```
WeatherController.loadWeather(city)
    ↓
WeatherRepository.loadWeather(city)
    ↓
WeatherDataRouter.fetchWeather(city.id, city.coordinates, city.timeZoneOffsetMinutes)
    ↓
QWeatherService.fetchWeather(cityId, coordinates, timezoneOffsetMinutes)
    ↓
mapToSnapshot(..., timezoneOffsetMinutes)
    ↓
WeatherSnapshot {
  timezoneOffsetMinutes: 480  // 使用传入的时区
}
    ↓
返回给UI层
```

### 判断白天/夜间的流程

```
WeatherHomePage.updateThemeWithStates(states, index)
    ↓
获取当前城市状态: states[index]
    ↓
isNightTime(cityState)
    ↓
从 cityState.snapshot.timezoneOffsetMinutes 获取时区
    ↓
getCityLocalHours(timezoneOffsetMinutes)
    ↓
计算城市当地时间：
  UTC时间 + 时区偏移 = 城市当地时间
    ↓
判断当地时间是否在 18:00-06:00
    ↓
返回 true（夜间）或 false（白天）
    ↓
ThemeConstants.getThemeWithTimeAware(weatherKey, isNight)
    ↓
返回最终主题：sunny_night / rainy_day 等
    ↓
AppStorage.setOrCreate('themeKey', ...)
    ↓
AtmosphereBackground 监听变化，切换背景视频
```

---

## 测试场景

### 场景1：北京（UTC+8）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：北京
时区偏移：+480分钟
城市当地时间：20:00
判定结果：夜间（20:00 >= 18:00）
背景视频：根据天气条件 + _night 后缀
```

### 场景2：洛杉矶（UTC-8）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：洛杉矶
时区偏移：-480分钟
城市当地时间：04:00（前一天）
判定结果：夜间（04:00 <= 06:00）
背景视频：根据天气条件 + _night 后缀
```

### 场景3：伦敦（UTC+0）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：伦敦
时区偏移：0分钟
城市当地时间：12:00
判定结果：白天（07:00 <= 12:00 <= 17:59）
背景视频：根据天气条件，白天版本
```

### 场景4：悉尼（UTC+11）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：悉尼
时区偏移：+660分钟
城市当地时间：23:00
判定结果：夜间（23:00 >= 18:00）
背景视频：根据天气条件 + _night 后缀
```

---

## 和风天气API时区字段说明

### 城市搜索API返回的时区字段

```json
{
  "name": "北京",
  "id": "101010100",
  "lat": "39.90499",
  "lon": "116.40529",
  "tz": "Asia/Shanghai",        // 时区名称（IANA时区数据库）
  "utcOffset": "+08:00",         // UTC偏移量（小时:分钟）
  "isDst": "0"                   // 是否夏令时（0=否，1=是）
}
```

### 字段解释

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `tz` | string | IANA时区名称 | "Asia/Shanghai", "America/Los_Angeles" |
| `utcOffset` | string | UTC偏移量 | "+08:00", "-05:00", "+05:30" |
| `isDst` | string | 是否夏令时 | "0"（否）, "1"（是）|

### UTC偏移量格式

- **格式：** `[+/-]HH:MM`
- **正数：** 东时区，如 `+08:00`（UTC+8，北京时间）
- **负数：** 西时区，如 `-05:00`（UTC-5，美国东部时间）
- **半小时时区：** 如 `+05:30`（印度标准时间）

---

## 关键改进

### 1. 使用实际时区数据
- ❌ 旧方案：硬编码 `timezoneOffsetMinutes: 480`（所有城市都用UTC+8）
- ✅ 新方案：使用和风天气API返回的实际时区数据

### 2. 基于城市当地时间判断
- ❌ 旧方案：使用设备本地时间判断白天/夜间
- ✅ 新方案：计算城市当地时间，基于当地时间判断

### 3. 降级策略
- 如果和风API未返回时区 → 使用经度估算
- 如果经度估算失败 → 使用UTC+8作为默认值

---

## 日志示例

### 添加城市时的日志
```
[CitySearchService] 🏗️ 将搜索结果转换为城市对象: 洛杉矶
[CitySearchService] ✅ 使用API返回的时区: America/Los_Angeles (-08:00) = -480分钟
[CitySearchService] 🎨 自动匹配主题: sunny
[CitySearchService] ✅ 城市对象创建成功: ID=qw_5368361, 时区偏移=-480分钟
```

### 获取天气数据时的日志
```
[QWeatherService] ========== 开始获取和风天气数据 ==========
[QWeatherService] 🏙️ 城市ID: qw_5368361
[QWeatherService] 📍 坐标: 34.0522,-118.2437
[QWeatherService] 🕒 时区偏移: -480分钟 (UTC-8)
[QWeatherService] 🕒 使用时区偏移: -480分钟 (UTC-8)
```

### 判断白天/夜间时的日志
```
[WeatherHomePage] 🎨 updateThemeWithStates: states.length=8, index=3
[WeatherHomePage] 🌙 城市当地是否夜间: true
[WeatherHomePage] 🕐 时区偏移: -480分钟, 当地时间: 4:00
[WeatherHomePage] 📊 当前城市状态: 洛杉矶, 加利福尼亚（加州）, hasSnapshot=true
[WeatherHomePage] 🌤️ 当前城市: 洛杉矶, 加利福尼亚（加州）, 天气条件themeKey: sunny
[WeatherHomePage] 🎨 最终主题: sunny_night
```

---

## 注意事项

### 1. 夏令时处理
- 和风天气API返回的 `utcOffset` 已经考虑了夏令时
- `isDst` 字段指示当前是否处于夏令时
- 我们直接使用 `utcOffset`，无需额外处理夏令时

### 2. 特殊时区
- 半小时时区（如印度 UTC+5:30）：`parseUtcOffset()` 方法已支持
- 45分钟时区（如尼泊尔 UTC+5:45）：`parseUtcOffset()` 方法已支持

### 3. 时区更新
- 城市的时区信息在添加时获取并保存
- 如果时区发生变化（如夏令时切换），需要重新获取天气数据
- 建议定期更新城市信息（如每月一次）

### 4. 降级策略
- 和风API未返回时区 → 经度估算
- 经度估算：`offsetHours = Math.round(longitude / 15)`
- 最终降级：UTC+8（中国标准时间）

---

## 总结

✅ **已完成：**
1. 集成和风天气API的时区数据
2. 修改所有相关服务，支持时区参数传递
3. 实现基于城市当地时间的白天/夜间判断
4. 添加详细的日志输出，便于调试
5. 实现降级策略，确保系统稳定性

✅ **效果：**
- 背景视频现在根据城市当地时间正确切换
- 北京18:00显示夜间视频，洛杉矶18:00也显示夜间视频（各自的当地时间）
- 支持全球任意时区的城市

✅ **性能：**
- 无额外API请求（时区信息来自城市搜索API）
- 时区计算非常快速（简单的数学运算）
- 时区信息缓存在城市对象中，无需重复获取

🎉 **时区集成完成！背景视频现在能够根据城市当地时间正确切换！**
