import { Coordinates, WeatherSnapshot } from '../models/WeatherModels';
import { OpenMeteoService } from './OpenMeteoService';
import { QWeatherService } from './QWeatherService';

// 地理边界接口
interface GeoBounds {
  latMin: number;
  latMax: number;
  lonMin: number;
  lonMax: number;
}

/**
 * 天气数据路由器
 * 根据地理位置智能选择最佳数据源
 */
export class WeatherDataRouter {
  private openMeteoService: OpenMeteoService;
  private qweatherService: QWeatherService;

  constructor(openMeteoService: OpenMeteoService, qweatherService: QWeatherService) {
    this.openMeteoService = openMeteoService;
    this.qweatherService = qweatherService;
  }

  /**
   * 获取天气数据（自动路由）
   * @param cityId 城市ID
   * @param coordinates 城市坐标
   * @param timezoneOffsetMinutes 城市时区偏移量（分钟），可选
   */
  async fetchWeather(cityId: string, coordinates: Coordinates, timezoneOffsetMinutes?: number): Promise<WeatherSnapshot> {
    console.info(`[WeatherDataRouter] ========== 开始天气数据路由 ==========`);
    console.info(`[WeatherDataRouter] 📍 目标坐标: ${coordinates.latitude.toFixed(4)}, ${coordinates.longitude.toFixed(4)}`);
    if (timezoneOffsetMinutes !== undefined) {
      console.info(`[WeatherDataRouter] 🕒 时区偏移: ${timezoneOffsetMinutes}分钟`);
    }
    const startTime = Date.now();

    let snapshot: WeatherSnapshot;
    if (this.isInChina(coordinates)) {
      console.info(`[WeatherDataRouter] 🇨🇳 判定为中国区域，路由至和风天气服务`);
      try {
        snapshot = await this.qweatherService.fetchWeather(cityId, coordinates, timezoneOffsetMinutes);
        console.info(`[WeatherDataRouter] ✅ 和风天气数据获取成功`);
      } catch (error) {
        console.error(`[WeatherDataRouter] ❌ 和风天气服务异常:`, error);
        throw error instanceof Error ? error : new Error(String(error));
      }
    } else {
      console.info(`[WeatherDataRouter] 🌍 判定为国际区域，路由至Open-Meteo服务`);
      try {
        snapshot = await this.openMeteoService.fetchWeather(cityId, coordinates, timezoneOffsetMinutes);
        console.info(`[WeatherDataRouter] ✅ Open-Meteo数据获取成功`);
      } catch (error) {
        console.error(`[WeatherDataRouter] ❌ Open-Meteo服务异常:`, error);
        throw error instanceof Error ? error : new Error(String(error));
      }
    }
    
    console.info(`[WeatherDataRouter] ⏱️ 数据路由完成，总耗时: ${Date.now() - startTime}ms`);
    return snapshot;
  }

  /**
   * 判断坐标是否在中国境内
   * 包含中国大陆、香港、澳门、台湾
   */
  private isInChina(coordinates: Coordinates): boolean {
    const lat = coordinates.latitude;
    const lon = coordinates.longitude;

    // 中国大陆边界（包含南海诸岛）
    const mainlandBounds: GeoBounds = {
      latMin: 3.86,
      latMax: 53.56,
      lonMin: 73.50,
      lonMax: 135.09
    };

    // 香港边界
    const hongKongBounds: GeoBounds = {
      latMin: 22.15,
      latMax: 22.56,
      lonMin: 113.83,
      lonMax: 114.41
    };

    // 澳门边界
    const macauBounds: GeoBounds = {
      latMin: 22.11,
      latMax: 22.22,
      lonMin: 113.52,
      lonMax: 113.60
    };

    // 台湾边界
    const taiwanBounds: GeoBounds = {
      latMin: 21.90,
      latMax: 25.30,
      lonMin: 119.50,
      lonMax: 122.00
    };

    // 检查是否在任一区域内
    const inMainland = this.isInBounds(lat, lon, mainlandBounds);
    const inHongKong = this.isInBounds(lat, lon, hongKongBounds);
    const inMacau = this.isInBounds(lat, lon, macauBounds);
    const inTaiwan = this.isInBounds(lat, lon, taiwanBounds);

    const result = inMainland || inHongKong || inMacau || inTaiwan;
    
    if (result) {
      const region = inHongKong ? '香港' : inMacau ? '澳门' : inTaiwan ? '台湾' : '中国大陆';
      console.info(`[WeatherDataRouter] 位置判定: ${region}`);
    }

    return result;
  }

  /**
   * 检查坐标是否在指定边界内
   */
  private isInBounds(lat: number, lon: number, bounds: GeoBounds): boolean {
    return lat >= bounds.latMin
      && lat <= bounds.latMax
      && lon >= bounds.lonMin
      && lon <= bounds.lonMax;
  }

  /**
   * 获取当前使用的数据源名称（用于调试）
   */
  getDataSourceName(coordinates: Coordinates): string {
    return this.isInChina(coordinates) ? 'QWeather (和风天气)' : 'Open-Meteo';
  }
}
