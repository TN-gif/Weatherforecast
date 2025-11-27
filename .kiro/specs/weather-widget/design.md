# Design Document: Weather Widget

## Overview

天气桌面卡片功能为用户提供在主屏幕上快速查看天气信息的能力。该功能基于HarmonyOS的FormExtensionAbility实现，支持2×2和4×4两种尺寸，采用与主应用一致的简约大气设计风格。

核心技术挑战：
1. **跨进程数据共享**：Widget运行在独立的FormAbility进程，需要通过Preferences实现与主应用的数据共享
2. **实时数据同步**：应用切后台时需要立即更新卡片显示最新天气数据
3. **卡片ID管理**：需要追踪所有活跃卡片实例以便批量更新

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Weather Widget System                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │ WeatherWidget2x2 │ ◄────── │ EntryFormAbility │          │
│  │ WeatherWidget4x4 │         │  (Widget Process) │          │
│  │    (UI Layer)    │         └────────┬─────────┘          │
│  └──────────────────┘                  │                     │
│                                        │ Read                │
│                                        ▼                     │
│                          ┌─────────────────────┐             │
│                          │ WidgetDataStorage   │             │
│                          │   (Preferences)     │             │
│                          └─────────┬───────────┘             │
│                                    ▲                         │
│                                    │ Write                   │
│                                    │                         │
│  ┌──────────────────┐    ┌────────┴─────────┐               │
│  │ WeatherHomePage  │───►│  EntryAbility    │               │
│  │ (Weather Data)   │    │ (Main Process)   │               │
│  └──────────────────┘    └──────────────────┘               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **保存数据流**：WeatherHomePage → WidgetDataStorage.saveForWidget() → Preferences
2. **更新卡片流**：EntryAbility.onBackground() → updateAllWidgets() → formProvider.updateForm()
3. **卡片读取流**：EntryFormAbility.onAddForm/onUpdateForm() → WidgetDataStorage.loadForWidget() → FormBindingData

## Components and Interfaces

### 1. WidgetDataStorage (数据存储服务)

负责卡片数据的持久化存储和跨进程共享。

```typescript
// entry/src/main/ets/data/storage/WidgetDataStorage.ets

interface WidgetWeatherData {
  cityName: string;
  temperature: number;
  temperatureUnit: string;
  condition: string;
  iconCode: string;
  themeKey: string;
  humidity: number;
  windSpeed: number;
  updateTime: string;
  timestamp: number;
  hourlyForecast: WidgetHourlyItem[];
}

interface WidgetHourlyItem {
  time: string;
  temperature: number;
  iconCode: string;
}

class WidgetDataStorage {
  // 保存天气数据到Preferences（供卡片读取）
  static async saveForWidget(data: WidgetWeatherData): Promise<void>;
  
  // 从Preferences加载天气数据
  static async loadForWidget(): Promise<WidgetWeatherData | null>;
  
  // 保存卡片ID列表
  static async saveFormIds(formIds: string[]): Promise<void>;
  
  // 加载卡片ID列表
  static async loadFormIds(): Promise<string[]>;
  
  // 添加单个卡片ID
  static async addFormId(formId: string): Promise<void>;
  
  // 移除单个卡片ID
  static async removeFormId(formId: string): Promise<void>;
}
```

### 2. EntryFormAbility (卡片能力)

管理卡片生命周期和数据更新。

```typescript
// entry/src/main/ets/entryformability/EntryFormAbility.ets

class EntryFormAbility extends FormExtensionAbility {
  // 卡片添加时调用
  onAddForm(want: Want): FormBindingData;
  
  // 卡片更新时调用（定时刷新）
  onUpdateForm(formId: string): void;
  
  // 卡片移除时调用
  onRemoveForm(formId: string): void;
  
  // 卡片事件处理（如刷新按钮点击）
  onFormEvent(formId: string, message: string): void;
  
  // 构建卡片绑定数据
  private buildFormData(data: WidgetWeatherData | null, dimension: string): FormBindingData;
}
```

### 3. WeatherWidget2x2 (2×2卡片UI)

紧凑型卡片，显示核心天气信息。

```typescript
// entry/src/main/ets/widget/pages/WeatherWidget2x2.ets

@Entry
@Component
struct WeatherWidget2x2 {
  @LocalStorageProp('cityName') cityName: string;
  @LocalStorageProp('temperature') temperature: string;
  @LocalStorageProp('condition') condition: string;
  @LocalStorageProp('iconCode') iconCode: string;
  @LocalStorageProp('themeKey') themeKey: string;
  @LocalStorageProp('updateTime') updateTime: string;
  @LocalStorageProp('isStale') isStale: boolean;
  
  build(): void;
  private getGradientColors(themeKey: string): [ResourceColor, number][];
  private getWeatherIcon(iconCode: string): Resource;
}
```

### 4. WeatherWidget4x4 (4×4卡片UI)

扩展型卡片，显示详细天气信息和小时预报。

```typescript
// entry/src/main/ets/widget/pages/WeatherWidget4x4.ets

@Entry
@Component
struct WeatherWidget4x4 {
  @LocalStorageProp('cityName') cityName: string;
  @LocalStorageProp('temperature') temperature: string;
  @LocalStorageProp('condition') condition: string;
  @LocalStorageProp('iconCode') iconCode: string;
  @LocalStorageProp('themeKey') themeKey: string;
  @LocalStorageProp('humidity') humidity: string;
  @LocalStorageProp('windSpeed') windSpeed: string;
  @LocalStorageProp('updateTime') updateTime: string;
  @LocalStorageProp('isStale') isStale: boolean;
  @LocalStorageProp('hourly0Time') hourly0Time: string;
  @LocalStorageProp('hourly0Temp') hourly0Temp: string;
  @LocalStorageProp('hourly0Icon') hourly0Icon: string;
  // ... hourly1, hourly2
  
  build(): void;
  private getGradientColors(themeKey: string): [ResourceColor, number][];
  private getWeatherIcon(iconCode: string): Resource;
}
```

### 5. WidgetHelper (工具类)

提供卡片相关的工具函数。

```typescript
// entry/src/main/ets/common/utils/WidgetHelper.ets

class WidgetHelper {
  // 根据天气主题获取渐变色
  static getGradientByTheme(themeKey: string): [ResourceColor, number][];
  
  // 根据图标代码获取图标资源
  static getIconResource(iconCode: string): Resource;
  
  // 格式化更新时间
  static formatUpdateTime(timestamp: number): string;
  
  // 检查数据是否过期（超过30分钟）
  static isDataStale(timestamp: number): boolean;
  
  // 从WeatherSnapshot转换为WidgetWeatherData
  static convertToWidgetData(snapshot: WeatherSnapshot, cityName: string): WidgetWeatherData;
}
```

## Data Models

### WidgetWeatherData

卡片显示所需的天气数据结构。

```typescript
interface WidgetWeatherData {
  cityName: string;           // 城市名称
  temperature: number;        // 当前温度（摄氏度）
  temperatureUnit: string;    // 温度单位 "°C"
  condition: string;          // 天气状况描述
  iconCode: string;           // 天气图标代码
  themeKey: string;           // 主题键（sunny/rainy/snow等）
  humidity: number;           // 湿度百分比
  windSpeed: number;          // 风速 km/h
  updateTime: string;         // 格式化的更新时间
  timestamp: number;          // 更新时间戳（毫秒）
  hourlyForecast: WidgetHourlyItem[];  // 小时预报（最多3项）
}

interface WidgetHourlyItem {
  time: string;               // 时间 "14:00"
  temperature: number;        // 温度
  iconCode: string;           // 图标代码
}
```

### FormDataContent

传递给卡片的绑定数据结构。

```typescript
interface FormData2x2 {
  cityName: string;
  temperature: string;        // "24°"
  condition: string;
  iconCode: string;
  themeKey: string;
  updateTime: string;
  isStale: boolean;
}

interface FormData4x4 extends FormData2x2 {
  humidity: string;           // "65%"
  windSpeed: string;          // "12 km/h"
  hourly0Time: string;
  hourly0Temp: string;
  hourly0Icon: string;
  hourly1Time: string;
  hourly1Temp: string;
  hourly1Icon: string;
  hourly2Time: string;
  hourly2Temp: string;
  hourly2Icon: string;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Widget data completeness

*For any* valid WeatherSnapshot and city name, converting to WidgetWeatherData SHALL produce an object containing all required fields (cityName, temperature, condition, iconCode, themeKey, updateTime, timestamp) with non-null values.

**Validates: Requirements 1.1, 1.2, 1.3, 1.5**

### Property 2: Icon mapping consistency

*For any* weather icon code, the getIconResource function SHALL return a valid Resource object, falling back to a default sun icon for unknown codes.

**Validates: Requirements 1.4, 8.3**

### Property 3: Theme gradient mapping

*For any* weather theme key (sunny, rainy, snow, sunny_night, rainy_night, snow_night), the getGradientByTheme function SHALL return a valid gradient color array with at least 2 color stops.

**Validates: Requirements 5.2**

### Property 4: Data staleness detection

*For any* timestamp, the isDataStale function SHALL return true if and only if the timestamp is more than 30 minutes (1800000 milliseconds) older than the current time.

**Validates: Requirements 3.4**

### Property 5: Dual storage persistence

*For any* WidgetWeatherData object, calling saveForWidget SHALL result in the data being retrievable via loadForWidget with equivalent field values.

**Validates: Requirements 6.1, 6.4**

### Property 6: Form ID management - add

*For any* form ID string, calling addFormId SHALL result in that ID being present in the list returned by loadFormIds.

**Validates: Requirements 7.1**

### Property 7: Form ID management - remove

*For any* form ID string that exists in storage, calling removeFormId SHALL result in that ID being absent from the list returned by loadFormIds.

**Validates: Requirements 7.2**

### Property 8: Data parsing robustness

*For any* valid JSON string representing WidgetWeatherData, parsing SHALL produce an equivalent object. For any invalid or malformed JSON, parsing SHALL return null without throwing an exception.

**Validates: Requirements 6.3**

### Property 9: Widget dimension data structure

*For any* widget dimension ("2*2" or "4*4"), the buildFormData function SHALL return a FormBindingData object containing all fields required for that dimension.

**Validates: Requirements 2.1, 2.2**

## Error Handling

### Storage Errors

- **Preferences unavailable**: Return default placeholder data with `isStale: true`
- **JSON parse error**: Log error and return null, triggering fallback UI
- **Form ID storage error**: Log error but continue operation

### Data Validation Errors

- **Missing required fields**: Use default values (temperature: "--", condition: "加载中")
- **Invalid timestamp**: Treat as stale data
- **Unknown icon code**: Use default sun icon

### Form Update Errors

- **Invalid form ID**: Skip update for that form, continue with others
- **Update timeout**: Log warning, data will refresh on next scheduled update

## Testing Strategy

### Unit Testing

使用HarmonyOS的@ohos/hypium测试框架进行单元测试。

测试范围：
1. WidgetHelper工具函数的正确性
2. WidgetDataStorage的读写操作
3. 数据转换函数的边界情况

### Property-Based Testing

使用fast-check库进行属性测试，验证核心属性在各种输入下的正确性。

配置要求：
- 每个属性测试运行最少100次迭代
- 使用智能生成器约束输入空间

测试标注格式：
```typescript
// **Feature: weather-widget, Property 1: Widget data completeness**
```

### Integration Testing

1. 验证主应用保存数据后卡片能正确读取
2. 验证卡片添加/移除时ID管理的正确性
3. 验证定时刷新机制的触发

### Manual Testing Scenarios

1. 添加2×2卡片，验证显示内容
2. 添加4×4卡片，验证扩展信息
3. 应用切后台，验证卡片数据更新
4. 杀掉应用后，验证卡片仍显示数据
5. 点击卡片，验证应用启动
