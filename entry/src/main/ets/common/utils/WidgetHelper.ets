import { DesignSystem } from '../theme/DesignSystem';
import { ThemeConstants } from '../constants/ThemeConstants';
import type { WeatherSnapshot } from '../../data/models/WeatherModels';
import type { WidgetWeatherData, WidgetHourlyItem } from '../../data/storage/WidgetDataStorage';

/**
 * 渐变色色标类型，用于 Widget 背景
 */
type GradientColorStop = [ResourceColor, number];

/**
 * 导出 GradientColorStop 类型供 Widget 组件使用
 */
export type { GradientColorStop };

/**
 * WidgetHelper - 天气 Widget 工具类
 * 
 * 提供以下辅助功能：
 * - 主题到渐变色的映射
 * - 图标代码到资源的映射
 * - 时间格式化
 * - 数据过期检测
 * - WeatherSnapshot 到 WidgetWeatherData 的转换
 * 
 * Requirements: 1.4, 3.4, 5.2, 8.3
 */
export class WidgetHelper {
  /**
   * 数据过期阈值（30 分钟，单位：毫秒）
   */
  private static readonly STALENESS_THRESHOLD_MS: number = 30 * 60 * 1000;

  /**
   * 根据天气主题获取 Widget 背景渐变色
   * 返回至少包含 2 个色标的有效渐变色数组
   * 
   * @param themeKey 天气主题键（sunny, rainy, snow, sunny_night, rainy_night, snow_night）
   * @returns 渐变色色标数组 [颜色, 位置]
   * Requirements: 5.2
   */
  static getGradientByTheme(themeKey: string): GradientColorStop[] {
    const theme = ThemeConstants.getTheme(themeKey);
    const gradientColors = theme.gradientColors;
    
    // 确保至少有 2 个颜色以形成有效渐变
    if (gradientColors.length >= 2) {
      return [
        [gradientColors[0], 0.0],
        [gradientColors[1], 1.0]
      ];
    }
    
    // 如果主题颜色不足，回退到默认晴天渐变色
    return [
      ['#87CEEB', 0.0],
      ['#4A90E2', 1.0]
    ];
  }

  /**
   * 获取基于天气主题的渐变色（Widget 专用版本）
   * 提供完整的主题到渐变色映射，包括日夜变体
   * 
   * @param themeKey 天气主题键（如 sunny, sunny_day, sunny_night, rainy, snow 等）
   * @returns 渐变色数组，至少包含 2 个色标
   * Requirements: 1.1, 1.3, 1.5
   */
  static getGradientColors(themeKey: string): GradientColorStop[] {
    // 主题到渐变色的完整映射表
    const gradientMap: Record<string, GradientColorStop[]> = {
      'sunny': [['#4A90E2', 0.0], ['#87CEEB', 1.0]],
      'sunny_day': [['#4A90E2', 0.0], ['#87CEEB', 1.0]],
      'sunny_night': [['#1a1a2e', 0.0], ['#16213e', 1.0]],
      'cloudy': [['#546E7A', 0.0], ['#78909C', 1.0]],
      'cloudy_day': [['#546E7A', 0.0], ['#78909C', 1.0]],
      'cloudy_night': [['#2C3E50', 0.0], ['#34495E', 1.0]],
      'rainy': [['#3D5A80', 0.0], ['#5C7A99', 1.0]],
      'rainy_day': [['#3D5A80', 0.0], ['#5C7A99', 1.0]],
      'rainy_night': [['#1B2838', 0.0], ['#2C3E50', 1.0]],
      'snow': [['#E8EEF2', 0.0], ['#B0BEC5', 1.0]],
      'snow_day': [['#E8EEF2', 0.0], ['#B0BEC5', 1.0]],
      'snow_night': [['#37474F', 0.0], ['#455A64', 1.0]],
      'fog': [['#90A4AE', 0.0], ['#B0BEC5', 1.0]],
      'haze': [['#8D6E63', 0.0], ['#A1887F', 1.0]],
      'storm': [['#263238', 0.0], ['#37474F', 1.0]]
    };

    const normalizedKey = themeKey.toLowerCase().trim();
    
    if (gradientMap[normalizedKey]) {
      return gradientMap[normalizedKey];
    }
    
    // 回退到晴天渐变色
    return [['#4A90E2', 0.0], ['#87CEEB', 1.0]];
  }

  /**
   * 获取天气图标资源（Widget 专用版本）
   * 与 getIconResource 功能相同，提供别名以保持向后兼容
   * 
   * @param iconCode 天气图标代码
   * @returns 天气图标资源
   * Requirements: 1.1, 1.3, 1.5
   */
  static getWeatherIcon(iconCode: string): Resource {
    return WidgetHelper.getIconResource(iconCode);
  }

  /**
   * 根据天气图标代码获取图标资源
   * 未知代码时回退到太阳图标
   * 
   * @param iconCode 天气图标代码字符串
   * @returns 天气图标的 Resource 对象
   * Requirements: 1.4, 8.3
   */
  static getIconResource(iconCode: string): Resource {
    // 图标代码到 DesignSystem 图标资源的映射
    // 图标代码通常遵循以下模式：sun, cloudy, rain, snow 等
    const iconMap: Record<string, Resource> = {
      'sun': DesignSystem.ICON_SUN,
      'sunny': DesignSystem.ICON_SUN,
      'clear': DesignSystem.ICON_SUN,
      'clear-day': DesignSystem.ICON_SUN,
      'clear-night': DesignSystem.ICON_MOON,
      'moon': DesignSystem.ICON_MOON,
      'cloudy': DesignSystem.ICON_CLOUDY,
      'cloud': DesignSystem.ICON_CLOUDY,
      'partly-cloudy': DesignSystem.ICON_CLOUDY,
      'partly-cloudy-day': DesignSystem.ICON_CLOUDY,
      'partly-cloudy-night': DesignSystem.ICON_CLOUD_MOON,
      'cloud-moon': DesignSystem.ICON_CLOUD_MOON,
      'overcast': DesignSystem.ICON_OVERCAST,
      'rain': DesignSystem.ICON_RAIN,
      'rainy': DesignSystem.ICON_RAIN,
      'drizzle': DesignSystem.ICON_DRIZZLE,
      'light-rain': DesignSystem.ICON_DRIZZLE,
      'heavy-rain': DesignSystem.ICON_RAIN,
      'storm': DesignSystem.ICON_STORM,
      'thunderstorm': DesignSystem.ICON_STORM,
      'snow': DesignSystem.ICON_SNOW,
      'snowy': DesignSystem.ICON_SNOW,
      'light-snow': DesignSystem.ICON_SNOW,
      'heavy-snow': DesignSystem.ICON_SNOW,
      'fog': DesignSystem.ICON_FOG,
      'foggy': DesignSystem.ICON_FOG,
      'mist': DesignSystem.ICON_FOG,
      'haze': DesignSystem.ICON_HAZE,
      'hazy': DesignSystem.ICON_HAZE,
      'wind': DesignSystem.ICON_WIND,
      'windy': DesignSystem.ICON_WIND
    };

    // 将图标代码转换为小写以进行匹配
    const normalizedCode = iconCode.toLowerCase().trim();
    
    // 首先尝试精确匹配
    if (iconMap[normalizedCode]) {
      return iconMap[normalizedCode];
    }
    
    // 尝试部分匹配（用于复合代码）
    for (const key of Object.keys(iconMap)) {
      if (normalizedCode.includes(key)) {
        return iconMap[key];
      }
    }
    
    // 未知代码时回退到太阳图标
    console.warn(`[WidgetHelper] 未知图标代码: ${iconCode}，使用默认太阳图标`);
    return DesignSystem.ICON_SUN;
  }


  /**
   * 将时间戳格式化为可读的更新时间字符串
   * 
   * @param timestamp Unix 时间戳（毫秒）
   * @returns 格式化的时间字符串，如 "14:30 更新"
   * Requirements: 1.5
   */
  static formatUpdateTime(timestamp: number): string {
    if (!timestamp || timestamp <= 0) {
      return '--:-- 更新';
    }
    
    const date = new Date(timestamp);
    const hours = date.getHours();
    const minutes = date.getMinutes();
    
    const hoursStr = hours < 10 ? `0${hours}` : `${hours}`;
    const minutesStr = minutes < 10 ? `0${minutes}` : `${minutes}`;
    
    return `${hoursStr}:${minutesStr} 更新`;
  }

  /**
   * 检查天气数据是否过期（超过 30 分钟）
   * 当且仅当时间戳比当前时间早 30 分钟以上时返回 true
   * 
   * @param timestamp Unix 时间戳（毫秒）
   * @returns 数据过期返回 true，否则返回 false
   * Requirements: 3.4
   */
  static isDataStale(timestamp: number): boolean {
    if (!timestamp || timestamp <= 0) {
      return true;
    }
    
    const now = Date.now();
    const age = now - timestamp;
    
    return age > WidgetHelper.STALENESS_THRESHOLD_MS;
  }

  /**
   * 将 WeatherSnapshot 转换为 WidgetWeatherData
   * 生成包含所有必需字段且值非空的对象
   * 
   * @param snapshot 主应用的天气快照
   * @param cityName 要显示的城市名称
   * @returns 可用于 Widget 显示的 WidgetWeatherData 对象
   * Requirements: 1.1, 1.2, 1.3, 1.5
   */
  static convertToWidgetData(snapshot: WeatherSnapshot, cityName: string): WidgetWeatherData {
    const now = Date.now();
    
    console.info(`[WidgetHelper] 🔄 Converting snapshot to widget data for city: ${cityName}`);
    console.info(`[WidgetHelper] 📊 Snapshot current - temp: ${snapshot.current.temperatureC}, humidity: ${snapshot.current.humidity}, windSpeed: ${snapshot.current.windSpeedKph}`);
    console.info(`[WidgetHelper] 📊 Snapshot hourly count: ${snapshot.hourly?.length ?? 0}`);
    
    // 提取小时预报（最多 3 项）
    const hourlyForecast: WidgetHourlyItem[] = [];
    const hourlyArray = snapshot.hourly ?? [];
    const hourlyCount = Math.min(hourlyArray.length, 3);
    
    for (let i = 0; i < hourlyCount; i++) {
      const hourly = hourlyArray[i];
      const item: WidgetHourlyItem = {
        time: WidgetHelper.extractTimeFromIso(hourly.time),
        temperature: Math.round(hourly.temperatureC),
        iconCode: hourly.iconCode || 'sun'
      };
      hourlyForecast.push(item);
      console.info(`[WidgetHelper] 📊 小时预报[${i}]: ${item.time}, ${item.temperature}°, ${item.iconCode}`);
    }
    
    // 构建包含所有必需字段的 Widget 数据
    const humidity = snapshot.current.humidity !== undefined && snapshot.current.humidity !== null 
      ? snapshot.current.humidity 
      : 0;
    const windSpeed = snapshot.current.windSpeedKph !== undefined && snapshot.current.windSpeedKph !== null 
      ? Math.round(snapshot.current.windSpeedKph) 
      : 0;
    
    const widgetData: WidgetWeatherData = {
      cityName: cityName || '未知城市',
      temperature: Math.round(snapshot.current.temperatureC),
      temperatureUnit: '°C',
      condition: snapshot.current.condition.description || '未知',
      iconCode: snapshot.current.condition.iconCode || 'sun',
      themeKey: snapshot.current.condition.themeKey || 'sunny',
      humidity: humidity,
      windSpeed: windSpeed,
      updateTime: WidgetHelper.formatUpdateTime(now),
      timestamp: now,
      hourlyForecast: hourlyForecast
    };
    
    console.info(`[WidgetHelper] ✅ Widget data created - humidity: ${widgetData.humidity}%, windSpeed: ${widgetData.windSpeed} km/h, hourly: ${widgetData.hourlyForecast.length}`);
    
    return widgetData;
  }

  /**
   * 从 ISO 日期字符串中提取时间字符串（HH:mm）
   * 
   * @param isoString ISO 格式的日期字符串
   * @returns 时间字符串，如 "14:00"
   */
  private static extractTimeFromIso(isoString: string): string {
    if (!isoString) {
      return '--:--';
    }
    
    try {
      const date = new Date(isoString);
      const hours = date.getHours();
      const minutes = date.getMinutes();
      
      const hoursStr = hours < 10 ? `0${hours}` : `${hours}`;
      const minutesStr = minutes < 10 ? `0${minutes}` : `${minutes}`;
      
      return `${hoursStr}:${minutesStr}`;
    } catch (error) {
      console.error('[WidgetHelper] Failed to parse ISO time:', error);
      return '--:--';
    }
  }

  /**
   * 获取默认的 Widget 数据（用于回退场景）
   * 当没有缓存数据可用时使用
   * 
   * @returns 包含占位符值的默认 WidgetWeatherData
   * Requirements: 8.1, 8.2
   */
  static getDefaultWidgetData(): WidgetWeatherData {
    return {
      cityName: '点击刷新',
      temperature: 0,
      temperatureUnit: '°C',
      condition: '数据加载中',
      iconCode: 'sun',
      themeKey: 'sunny',
      humidity: 0,
      windSpeed: 0,
      updateTime: '--:-- 更新',
      timestamp: 0,
      hourlyForecast: []
    };
  }
}
