# Requirements Document

## Introduction

本文档定义了天气应用桌面卡片（Service Widget）功能的需求规范。桌面卡片将为用户提供快速查看天气信息的能力，无需打开应用即可获取当前城市的天气状况、温度、天气描述等关键信息。卡片支持2×2和4×4两种尺寸，采用与主应用一致的简约大气设计风格，并支持实时数据同步和定时刷新。

## Glossary

- **Weather_Widget**: 天气应用的桌面服务卡片组件，运行在独立的FormExtensionAbility进程中
- **FormExtensionAbility**: HarmonyOS服务卡片的扩展能力，负责卡片生命周期管理和数据更新
- **AppStorage**: 应用内存存储，用于进程内快速数据共享
- **Preferences**: 持久化存储，用于跨进程数据共享和应用重启后数据恢复
- **WeatherSnapshot**: 天气数据快照，包含当前天气、小时预报、每日预报等完整天气信息
- **FormBindingData**: 卡片绑定数据对象，用于向卡片传递显示数据
- **ThemeKey**: 天气主题标识符，如sunny、rainy、snow等，用于确定卡片背景样式

## Requirements

### Requirement 1: 卡片数据显示

**User Story:** As a user, I want to view current weather information on my home screen widget, so that I can quickly check the weather without opening the app.

#### Acceptance Criteria

1. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL show the current city name in a clearly visible font
2. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL show the current temperature in Celsius with a prominent font size
3. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL show the weather condition description (e.g., "晴", "多云", "雨")
4. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL show an appropriate weather icon matching the current condition
5. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL show the last update time in a secondary text style

### Requirement 2: 卡片尺寸支持

**User Story:** As a user, I want to choose between different widget sizes, so that I can customize my home screen layout according to my preferences.

#### Acceptance Criteria

1. WHEN a user adds a 2×2 Weather_Widget THEN the Weather_Widget SHALL display compact weather information including city, temperature, and condition icon
2. WHEN a user adds a 4×4 Weather_Widget THEN the Weather_Widget SHALL display extended weather information including city, temperature, condition, humidity, wind speed, and a 3-hour forecast preview
3. WHEN the Weather_Widget is resized THEN the Weather_Widget SHALL adapt its layout to fit the new dimensions while maintaining readability

### Requirement 3: 数据同步与更新

**User Story:** As a user, I want my widget to show up-to-date weather information, so that I can rely on accurate data for my daily planning.

#### Acceptance Criteria

1. WHEN the main application updates weather data THEN the Weather_Widget SHALL receive the updated data within 5 seconds of the application entering background
2. WHEN the system triggers a scheduled update THEN the Weather_Widget SHALL fetch the latest cached weather data from Preferences storage
3. WHEN no cached data is available THEN the Weather_Widget SHALL display a default placeholder state with "点击刷新" prompt
4. WHEN the Weather_Widget data is older than 30 minutes THEN the Weather_Widget SHALL display a visual indicator showing the data may be stale

### Requirement 4: 卡片交互

**User Story:** As a user, I want to interact with the widget to access more detailed weather information, so that I can quickly navigate to the full app when needed.

#### Acceptance Criteria

1. WHEN a user taps on the Weather_Widget THEN the Weather_Widget SHALL launch the main application and navigate to the weather home page
2. WHEN a user taps on the refresh area of the 4×4 Weather_Widget THEN the Weather_Widget SHALL trigger a data refresh request to the main application

### Requirement 5: 视觉设计一致性

**User Story:** As a user, I want the widget to match the app's visual design, so that I have a consistent and aesthetically pleasing experience.

#### Acceptance Criteria

1. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL use the same color palette defined in DesignSystem (glass background, white text hierarchy)
2. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL apply a gradient background based on the current weather theme (sunny, rainy, snow)
3. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL use rounded corners consistent with DesignSystem.CORNER_RADIUS_M (16dp)
4. WHEN the Weather_Widget is displayed THEN the Weather_Widget SHALL apply a subtle blur effect for the glass-morphism style

### Requirement 6: 数据持久化与跨进程共享

**User Story:** As a developer, I want reliable data sharing between the main app and widget, so that the widget always displays accurate information.

#### Acceptance Criteria

1. WHEN the main application saves weather data THEN the Weather_Widget data storage SHALL persist the data to both AppStorage and Preferences simultaneously
2. WHEN the FormExtensionAbility reads weather data THEN the FormExtensionAbility SHALL first attempt to read from Preferences (cross-process accessible)
3. WHEN reading weather data from Preferences THEN the FormExtensionAbility SHALL parse the JSON payload and validate the data structure before display
4. WHEN the application is destroyed THEN the Weather_Widget SHALL continue to display the last known weather data from Preferences

### Requirement 7: 卡片ID管理

**User Story:** As a developer, I want to track all active widget instances, so that I can update all widgets when weather data changes.

#### Acceptance Criteria

1. WHEN a new Weather_Widget is added to the home screen THEN the FormExtensionAbility SHALL save the widget form ID to a persistent storage
2. WHEN a Weather_Widget is removed from the home screen THEN the FormExtensionAbility SHALL remove the corresponding form ID from storage
3. WHEN the main application needs to update widgets THEN the main application SHALL retrieve all stored form IDs and update each widget individually

### Requirement 8: 错误处理与降级

**User Story:** As a user, I want the widget to handle errors gracefully, so that I always see meaningful information even when data is unavailable.

#### Acceptance Criteria

1. IF weather data parsing fails THEN the Weather_Widget SHALL display a fallback UI with "数据加载中" message
2. IF the Preferences storage is inaccessible THEN the Weather_Widget SHALL display default placeholder values
3. IF the weather icon resource is not found THEN the Weather_Widget SHALL display a generic weather icon as fallback
