/**
 * 格式化工具类
 * 
 * 提供天气数据的格式化方法，包括温度、风速、空气质量、湿度等。
 * 所有方法都会处理 undefined/null/NaN 值，返回安全的默认值。
 */
export class FormatHelper {
  /**
   * 格式化温度值
   * 
   * @param value 温度值（摄氏度）
   * @returns 格式化后的温度字符串，如 "25°"
   */
  static formatTemperature(value: number): string {
    // 处理 undefined、null 或 NaN 的情况
    if (value === undefined || value === null || isNaN(value)) {
      return '--°';
    }
    return `${Math.round(value)}°`;
  }

  /**
   * 格式化风速和风向
   * 
   * @param speedKph 风速（公里/小时）
   * @param direction 风向
   * @returns 格式化后的风速字符串，如 "15 km/h 东北"
   */
  static formatWind(speedKph: number, direction: string): string {
    // 处理 undefined、null 或 NaN 的情况
    const speed = (speedKph === undefined || speedKph === null || isNaN(speedKph)) ? 0 : speedKph;
    const dir = direction || '--';
    return `${speed.toFixed(0)} km/h ${dir}`;
  }

  /**
   * 格式化空气质量指数
   * 
   * @param aqi 空气质量指数
   * @returns 格式化后的 AQI 字符串，如 "优 (35)"
   */
  static formatAqi(aqi: number): string {
    // 处理 undefined、null 或 NaN 的情况
    if (aqi === undefined || aqi === null || isNaN(aqi)) {
      return '-- (--)';
    }
    if (aqi <= 50) {
      return `优 (${aqi})`;
    }
    if (aqi <= 100) {
      return `良 (${aqi})`;
    }
    if (aqi <= 150) {
      return `轻度 (${aqi})`;
    }
    return `较差 (${aqi})`;
  }

  /**
   * 格式化湿度值
   * 
   * @param value 湿度百分比
   * @returns 格式化后的湿度字符串，如 "65%"
   */
  static formatHumidity(value: number): string {
    // 处理 undefined、null 或 NaN 的情况
    if (value === undefined || value === null || isNaN(value)) {
      return '--%';
    }
    return `${value.toFixed(0)}%`;
  }

  /**
   * 格式化更新时间
   * 
   * @param isoString ISO 格式的时间字符串
   * @returns 格式化后的时间字符串，如 "14:30"
   */
  static formatUpdatedTime(isoString: string): string {
    // 处理空字符串或无效值
    if (!isoString) {
      return '--:--';
    }
    try {
      const date: Date = new Date(isoString);
      // 检查日期是否有效
      if (isNaN(date.getTime())) {
        return '--:--';
      }
      const hours: string = date.getHours().toString().padStart(2, '0');
      const minutes: string = date.getMinutes().toString().padStart(2, '0');
      return `${hours}:${minutes}`;
    } catch (error) {
      return '--:--';
    }
  }

  /**
   * 格式化气压值
   * 
   * @param value 气压值（hPa）
   * @returns 格式化后的气压字符串，如 "1013 hPa"
   */
  static formatPressure(value: number): string {
    if (value === undefined || value === null || isNaN(value)) {
      return '-- hPa';
    }
    return `${Math.round(value)} hPa`;
  }

  /**
   * 格式化能见度
   * 
   * @param value 能见度（公里）
   * @returns 格式化后的能见度字符串，如 "10 km"
   */
  static formatVisibility(value: number): string {
    if (value === undefined || value === null || isNaN(value)) {
      return '-- km';
    }
    return `${value.toFixed(1)} km`;
  }

  /**
   * 格式化紫外线指数
   * 
   * @param value 紫外线指数
   * @returns 格式化后的紫外线指数字符串，如 "3 中等"
   */
  static formatUvIndex(value: number): string {
    if (value === undefined || value === null || isNaN(value)) {
      return '--';
    }
    const level = value <= 2 ? '低' : value <= 5 ? '中等' : value <= 7 ? '高' : '极高';
    return `${Math.round(value)} ${level}`;
  }
}
