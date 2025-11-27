import { DesignSystem } from '../theme/DesignSystem';
import { ThemeConstants } from '../constants/ThemeConstants';
import type { WeatherSnapshot } from '../../data/models/WeatherModels';
import type { WidgetWeatherData, WidgetHourlyItem } from '../../data/storage/WidgetDataStorage';

/**
 * Gradient color stop type for widget backgrounds
 */
type GradientColorStop = [ResourceColor, number];

/**
 * 导出 GradientColorStop 类型供 Widget 组件使用
 */
export type { GradientColorStop };

/**
 * WidgetHelper - Utility class for weather widget operations
 * 
 * Provides helper functions for:
 * - Theme to gradient color mapping
 * - Icon code to Resource mapping
 * - Time formatting
 * - Data staleness detection
 * - WeatherSnapshot to WidgetWeatherData conversion
 * 
 * Requirements: 1.4, 3.4, 5.2, 8.3
 */
export class WidgetHelper {
  /**
   * Staleness threshold in milliseconds (30 minutes)
   */
  private static readonly STALENESS_THRESHOLD_MS: number = 30 * 60 * 1000;

  /**
   * Get gradient colors for widget background based on weather theme
   * Returns a valid gradient color array with at least 2 color stops
   * 
   * @param themeKey Weather theme key (sunny, rainy, snow, sunny_night, rainy_night, snow_night)
   * @returns Array of gradient color stops [color, position]
   * Requirements: 5.2
   */
  static getGradientByTheme(themeKey: string): GradientColorStop[] {
    const theme = ThemeConstants.getTheme(themeKey);
    const gradientColors = theme.gradientColors;
    
    // Ensure we have at least 2 colors for a valid gradient
    if (gradientColors.length >= 2) {
      return [
        [gradientColors[0], 0.0],
        [gradientColors[1], 1.0]
      ];
    }
    
    // Fallback to default sunny gradient if theme has insufficient colors
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
   * Get icon Resource based on weather icon code
   * Falls back to sun icon for unknown codes
   * 
   * @param iconCode Weather icon code string
   * @returns Resource object for the weather icon
   * Requirements: 1.4, 8.3
   */
  static getIconResource(iconCode: string): Resource {
    // Map icon codes to DesignSystem icon resources
    // Icon codes typically follow patterns like: sun, cloudy, rain, snow, etc.
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

    // Normalize icon code to lowercase for matching
    const normalizedCode = iconCode.toLowerCase().trim();
    
    // Try exact match first
    if (iconMap[normalizedCode]) {
      return iconMap[normalizedCode];
    }
    
    // Try partial match for compound codes
    for (const key of Object.keys(iconMap)) {
      if (normalizedCode.includes(key)) {
        return iconMap[key];
      }
    }
    
    // Fallback to sun icon for unknown codes
    console.warn(`[WidgetHelper] Unknown icon code: ${iconCode}, using default sun icon`);
    return DesignSystem.ICON_SUN;
  }


  /**
   * Format timestamp to human-readable update time string
   * 
   * @param timestamp Unix timestamp in milliseconds
   * @returns Formatted time string like "14:30 更新"
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
   * Check if weather data is stale (older than 30 minutes)
   * Returns true if and only if the timestamp is more than 30 minutes older than current time
   * 
   * @param timestamp Unix timestamp in milliseconds
   * @returns true if data is stale, false otherwise
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
   * Convert WeatherSnapshot to WidgetWeatherData
   * Produces an object containing all required fields with non-null values
   * 
   * @param snapshot Weather snapshot from main application
   * @param cityName City name to display
   * @returns WidgetWeatherData object ready for widget display
   * Requirements: 1.1, 1.2, 1.3, 1.5
   */
  static convertToWidgetData(snapshot: WeatherSnapshot, cityName: string): WidgetWeatherData {
    const now = Date.now();
    
    console.info(`[WidgetHelper] 🔄 Converting snapshot to widget data for city: ${cityName}`);
    console.info(`[WidgetHelper] 📊 Snapshot current - temp: ${snapshot.current.temperatureC}, humidity: ${snapshot.current.humidity}, windSpeed: ${snapshot.current.windSpeedKph}`);
    console.info(`[WidgetHelper] 📊 Snapshot hourly count: ${snapshot.hourly?.length ?? 0}`);
    
    // Extract hourly forecast (up to 3 items)
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
      console.info(`[WidgetHelper] 📊 Hourly[${i}]: ${item.time}, ${item.temperature}°, ${item.iconCode}`);
    }
    
    // Build widget data with all required fields
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
   * Extract time string (HH:mm) from ISO date string
   * 
   * @param isoString ISO format date string
   * @returns Time string like "14:00"
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
   * Get default widget data for fallback scenarios
   * Used when no cached data is available
   * 
   * @returns Default WidgetWeatherData with placeholder values
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
