# 时区集成方案

## 当前问题

### 1. 硬编码的时区
**位置：** `QWeatherService.ets` 的 `mapToSnapshot()` 方法

```typescript
const snapshot: WeatherSnapshot = {
  cityId: cityId,
  lastUpdatedIso: new Date().toISOString(),
  timezoneOffsetMinutes: 480,  // ← 硬编码为 UTC+8（北京时间）
  // ...
};
```

**影响：**
- 所有城市都使用北京时间判断白天/夜间
- 国外城市（如洛杉矶、雅典）的背景视频切换不正确
- 例如：洛杉矶（UTC-8）在北京时间18:00时，当地时间是02:00（凌晨），应该显示夜间视频

### 2. 已完成的修复
✅ `isNightTime()` 方法已修改为使用城市当地时间
✅ 创建了 `TimeZoneService` 框架
✅ 添加了 `getCityLocalHours()` 方法计算城市当地时间

### 3. 待完成的工作
❌ 集成实际的时区API
❌ 在获取天气数据时同时获取时区信息
❌ 将时区信息存储到 `City` 和 `WeatherSnapshot` 中

---

## 时区API选项

### 选项1：TimeZoneDB API（推荐）
**优点：**
- 免费版每月100万次请求
- 简单易用，只需经纬度
- 返回时区名称和偏移量
- 支持历史和未来时间的时区查询

**API示例：**
```
GET https://api.timezonedb.com/v2.1/get-time-zone
  ?key=YOUR_API_KEY
  &format=json
  &by=position
  &lat=39.9042
  &lng=116.4074
```

**响应示例：**
```json
{
  "status": "OK",
  "message": "",
  "countryCode": "CN",
  "countryName": "China",
  "zoneName": "Asia/Shanghai",
  "abbreviation": "CST",
  "gmtOffset": 28800,  // 秒数，28800秒 = 8小时 = UTC+8
  "dst": "0",
  "timestamp": 1732636800
}
```

**注册地址：** https://timezonedb.com/register

---

### 选项2：Google Time Zone API
**优点：**
- 准确度高，考虑夏令时
- Google官方支持

**缺点：**
- 需要Google Cloud账号
- 免费额度较少

**API示例：**
```
GET https://maps.googleapis.com/maps/api/timezone/json
  ?location=39.9042,116.4074
  &timestamp=1331161200
  &key=YOUR_API_KEY
```

**响应示例：**
```json
{
  "dstOffset": 0,
  "rawOffset": 28800,  // 秒数
  "status": "OK",
  "timeZoneId": "Asia/Shanghai",
  "timeZoneName": "China Standard Time"
}
```

---

### 选项3：和风天气API（如果支持）
**优点：**
- 已经在使用，无需额外API
- 一次请求获取天气+时区

**需要确认：**
- 和风天气API是否返回时区信息？
- 如果支持，在哪个接口返回？

---

### 选项4：根据经度估算（临时方案）
**优点：**
- 无需API，完全离线
- 已在 `TimeZoneService` 中实现

**缺点：**
- 不准确，不考虑特殊时区和夏令时
- 例如：中国横跨5个时区，但统一使用UTC+8

**实现：**
```typescript
private estimateTimezoneByLongitude(longitude: number): number {
  // 地球每15度经度对应1小时时差
  const hours = Math.round(longitude / 15);
  return hours * 60;  // 转换为分钟
}
```

---

## 推荐方案

### 方案A：TimeZoneDB API（最推荐）
1. 注册 TimeZoneDB 账号，获取 API Key
2. 在 `WeatherApiConstants` 中添加配置
3. 在 `QWeatherService.fetchWeather()` 中调用 `TimeZoneService`
4. 将时区信息存储到 `WeatherSnapshot`

### 方案B：和风天气API + TimeZoneDB 备用
1. 先检查和风天气API是否返回时区
2. 如果不返回，使用 TimeZoneDB API
3. 缓存时区信息，避免重复请求

### 方案C：经度估算（临时方案）
1. 使用 `estimateTimezoneByLongitude()` 方法
2. 适用于快速测试，不推荐生产环境

---

## 实现步骤

### 步骤1：选择API并获取密钥
- [ ] 注册 TimeZoneDB 账号
- [ ] 获取 API Key
- [ ] 或者：确认和风天气API是否支持时区

### 步骤2：配置API密钥
在 `WeatherApiConstants.ets` 中添加：
```typescript
export class WeatherApiConstants {
  static readonly TIMEZONE_API_KEY: string = 'YOUR_TIMEZONEDB_API_KEY';
  // ...
}
```

### 步骤3：修改 QWeatherService
```typescript
import { TimeZoneService } from './TimeZoneService';

export class QWeatherService {
  private readonly timeZoneService: TimeZoneService = TimeZoneService.getInstance();
  
  async fetchWeather(cityId: string, coordinates: Coordinates): Promise<WeatherSnapshot> {
    // 获取时区信息
    const timezoneOffset = await this.timeZoneService.getTimezoneOffset(coordinates);
    
    // 在 mapToSnapshot 中使用实际时区
    const snapshot: WeatherSnapshot = {
      cityId: cityId,
      lastUpdatedIso: new Date().toISOString(),
      timezoneOffsetMinutes: timezoneOffset,  // ← 使用实际时区
      // ...
    };
  }
}
```

### 步骤4：更新 City 的时区信息
在 `CityRepository` 中，添加城市时也获取时区：
```typescript
async addCity(city: City): Promise<void> {
  // 如果城市没有时区信息，获取时区
  if (city.timeZoneOffsetMinutes === 0) {
    const timezoneOffset = await this.timeZoneService.getTimezoneOffset(city.coordinates);
    // 创建新的 City 对象，包含时区信息
    const updatedCity = new City(
      city.id,
      city.name,
      city.country,
      city.coordinates,
      city.source,
      city.videoTheme,
      timezoneOffset  // ← 更新时区
    );
    // 保存到数据库
  }
}
```

### 步骤5：测试验证
测试不同时区的城市：
- 北京（UTC+8）：18:00应显示夜间视频
- 洛杉矶（UTC-8）：当地18:00应显示夜间视频
- 雅典（UTC+2）：当地18:00应显示夜间视频

---

## 测试用例

### 测试1：北京（UTC+8）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：北京
时区偏移：+480分钟
城市当地时间：20:00
预期结果：夜间视频（20:00 >= 18:00）
```

### 测试2：洛杉矶（UTC-8）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：洛杉矶
时区偏移：-480分钟
城市当地时间：04:00（前一天）
预期结果：夜间视频（04:00 <= 06:00）
```

### 测试3：伦敦（UTC+0）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：伦敦
时区偏移：0分钟
城市当地时间：12:00
预期结果：白天视频（07:00 <= 12:00 <= 17:59）
```

### 测试4：悉尼（UTC+11）
```
设备时间：2025-11-26 20:00 (UTC+8)
城市：悉尼
时区偏移：+660分钟
城市当地时间：23:00
预期结果：夜间视频（23:00 >= 18:00）
```

---

## 性能优化

### 1. 缓存时区信息
- 时区信息很少变化，可以缓存到本地数据库
- 只在首次添加城市时获取时区
- 定期更新（例如每月一次）

### 2. 批量获取
- 如果添加多个城市，批量获取时区信息
- 减少API请求次数

### 3. 降级策略
- 如果时区API失败，使用经度估算
- 如果估算也失败，使用UTC+8作为默认值

---

## 下一步行动

请提供以下信息：

1. **你推荐使用哪个时区API？**
   - TimeZoneDB
   - Google Time Zone API
   - 和风天气API（如果支持）
   - 其他API

2. **如果使用 TimeZoneDB：**
   - 请提供 API Key
   - 或者我可以在代码中留一个配置项，你自己填写

3. **如果使用和风天气API：**
   - 请确认和风天气API是否返回时区信息
   - 如果返回，在哪个字段？

4. **临时方案：**
   - 是否先使用经度估算方案进行测试？
   - 等API配置好后再切换到实际API

---

## 代码已准备就绪

✅ `TimeZoneService.ets` - 时区服务框架已创建
✅ `isNightTime(cityState)` - 已修改为使用城市当地时间
✅ `getCityLocalHours(timezoneOffsetMinutes)` - 时间计算方法已实现

只需要：
1. 提供API信息
2. 修改 `QWeatherService` 集成时区服务
3. 测试验证

请告诉我你的选择，我会立即完成集成！
