import http from '@ohos.net.http';
import { Coordinates } from '../models/WeatherModels';
import { WeatherApiConstants } from '../../common/constants/WeatherApiConstants';
import { OpenMeteoGeoService, OpenMeteoGeoResult } from './OpenMeteoGeoService';

// 和风城市搜索位置项 - 导出供CitySearchService使用
export interface QWeatherLocationItem {
  name: string;
  id: string;
  lat: string;
  lon: string;
  adm2: string;
  adm1: string;
  country: string;
  tz: string;
  utcOffset: string;
  isDst: string;
  type: string;
  rank: string;
  fxLink: string;
}

// 和风城市搜索响应
interface QWeatherCitySearchResult {
  code: string;
  location: QWeatherLocationItem[];
}

// 和风逆地理编码位置项
interface QWeatherReverseLocationItem {
  name: string;
  id: string;
  lat: string;
  lon: string;
  adm2: string;
  adm1: string;
  country: string;
}

// 和风逆地理编码响应
interface QWeatherReverseGeoResult {
  code: string;
  location: QWeatherReverseLocationItem[];
}

// Open-Meteo地理编码结果项 - 导出供CitySearchService使用
export { OpenMeteoGeoResult } from './OpenMeteoGeoService';

// 搜索结果包装 - 导出供CitySearchService使用
export interface SearchResultWrapper {
  source: string;
  data: QWeatherCitySearchResult | OpenMeteoGeoResult[];
}

/**
 * 和风天气地理服务 - 城市搜索和逆地理编码
 */
export class QWeatherGeoService {
  private readonly baseUrl: string;
  private readonly apiKey: string;
  private readonly timeoutMs: number = 10000;

  constructor(baseUrl: string, apiKey: string) {
    // 使用配置的baseUrl + /geo/v2路径
    this.baseUrl = `${baseUrl}/geo/v2`;
    this.apiKey = apiKey;
  }

  async searchCities(keyword: string): Promise<QWeatherCitySearchResult | null> {
    if (!keyword || keyword.trim().length < 2) {
      return null;
    }

    const httpRequest = http.createHttp();
    try {
      const url = `${this.baseUrl}/city/lookup?location=${encodeURIComponent(keyword.trim())}&key=${this.apiKey}&lang=zh`;
      console.info(`[QWeatherGeoService] 🔍 发起城市搜索: ${url}`);
      const startTime = Date.now();

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });
      
      const duration = Date.now() - startTime;
      console.debug(`[QWeatherGeoService] ⏱️ 搜索耗时: ${duration}ms, 状态码: ${response.responseCode}`);

      if (response.responseCode !== 200) {
        console.error(`[QWeatherGeoService] ❌ 搜索请求失败: ${response.responseCode}`);
        return null;
      }

      const data = JSON.parse(response.result as string) as QWeatherCitySearchResult;
      
      if (data.code === '200') {
        console.info(`[QWeatherGeoService] ✅ 搜索成功，找到 ${data.location?.length || 0} 个结果`);
        return data;
      } else {
        console.warn(`[QWeatherGeoService] ⚠️ 搜索API返回业务错误码: ${data.code}`);
        return null;
      }
    } catch (error) {
      console.error(`[QWeatherGeoService] ❌ 搜索异常:`, error);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  async reverseGeocode(coordinates: Coordinates): Promise<string | null> {
    const httpRequest = http.createHttp();
    try {
      const location = `${coordinates.longitude},${coordinates.latitude}`;
      const url = `${this.baseUrl}/city/lookup?location=${location}&key=${this.apiKey}&lang=zh`;
      console.info(`[QWeatherGeoService] 🗺️ 发起逆地理编码: ${url}`);
      const startTime = Date.now();

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });

      const duration = Date.now() - startTime;
      console.debug(`[QWeatherGeoService] ⏱️ 逆编码耗时: ${duration}ms, 状态码: ${response.responseCode}`);

      if (response.responseCode !== 200) {
        console.error(`[QWeatherGeoService] ❌ 逆编码请求失败: ${response.responseCode}`);
        return null;
      }

      const data = JSON.parse(response.result as string) as QWeatherReverseGeoResult;
      
      if (data.code === '200' && data.location && data.location.length > 0) {
        const result = data.location[0];
        
        // 🔧 改进：构建更精准的城市名称显示
        let cityName = result.name;
        
        // 对于中国城市，显示完整的行政区划
        if (result.country === '中国' || result.country === 'China') {
          if (result.adm2 && result.adm2 !== result.name) {
            // 如果有市级信息且与城市名不同，显示"城市名, 市级, 省级"
            if (result.adm1 && result.adm1 !== result.adm2) {
              cityName = `${result.name}, ${result.adm2}, ${result.adm1}`;
            } else {
              cityName = `${result.name}, ${result.adm2}`;
            }
          } else if (result.adm1 && result.adm1 !== result.name) {
            // 如果只有省级信息，显示"城市名, 省级"
            cityName = `${result.name}, ${result.adm1}`;
          }
        } else {
          // 对于国际城市，显示"城市名, 国家"
          if (result.adm1 && result.adm1 !== result.name) {
            cityName = `${result.name}, ${result.adm1}, ${result.country}`;
          } else {
            cityName = `${result.name}, ${result.country}`;
          }
        }
        
        console.info(`[QWeatherGeoService] ✅ 逆编码成功: ${cityName}`);
        return cityName;
      } else {
        console.warn(`[QWeatherGeoService] ⚠️ 逆编码API返回业务错误码: ${data.code}`);
        return null;
      }
    } catch (error) {
      console.error(`[QWeatherGeoService] ❌ 逆编码异常:`, error);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }
}



/**
 * 地理服务路由器 - 智能选择和风或OpenWeather
 */
export class GeoServiceRouter {
  private qweatherGeo: QWeatherGeoService;
  private openMeteoGeo: OpenMeteoGeoService;

  constructor() {
    this.qweatherGeo = new QWeatherGeoService(
      WeatherApiConstants.QWEATHER_CONFIG.baseUrl,
      WeatherApiConstants.QWEATHER_CONFIG.apiKey
    );
    this.openMeteoGeo = new OpenMeteoGeoService();
  }

  async searchCities(keyword: string): Promise<SearchResultWrapper | null> {
    console.info(`[GeoServiceRouter] ========== 开始搜索城市: "${keyword}" ==========`);
    const startTime = Date.now();

    // 优先使用和风天气
    try {
      console.info('[GeoServiceRouter] 1️⃣ 尝试使用和风天气搜索...');
      const qweatherResult = await this.qweatherGeo.searchCities(keyword);
      if (qweatherResult && qweatherResult.location && qweatherResult.location.length > 0) {
        console.info(`[GeoServiceRouter] ✅ 和风搜索成功，找到 ${qweatherResult.location.length} 个结果`);
        const wrapper: SearchResultWrapper = { 
          source: 'qweather', 
          data: qweatherResult 
        };
        console.info(`[GeoServiceRouter] ⏱️ 搜索总耗时: ${Date.now() - startTime}ms`);
        return wrapper;
      }
      console.warn('[GeoServiceRouter] ⚠️ 和风搜索无结果，准备降级');
    } catch (error) {
      console.warn(`[GeoServiceRouter] ⚠️ 和风搜索失败，降级到OpenWeather:`, error);
    }

    // 降级到Open-Meteo
    try {
      console.info('[GeoServiceRouter] 2️⃣ 降级尝试使用Open-Meteo搜索...');
      const openMeteoResult = await this.openMeteoGeo.searchCities(keyword);
      if (openMeteoResult && openMeteoResult.length > 0) {
        console.info(`[GeoServiceRouter] ✅ Open-Meteo搜索成功，找到 ${openMeteoResult.length} 个结果`);
        const wrapper: SearchResultWrapper = { 
          source: 'openmeteo', 
          data: openMeteoResult 
        };
        console.info(`[GeoServiceRouter] ⏱️ 搜索总耗时: ${Date.now() - startTime}ms`);
        return wrapper;
      }
      console.warn('[GeoServiceRouter] ⚠️ Open-Meteo搜索无结果');
    } catch (error) {
      console.error(`[GeoServiceRouter] ❌ Open-Meteo搜索失败:`, error);
    }

    console.warn(`[GeoServiceRouter] ❌ 所有数据源搜索均失败，耗时: ${Date.now() - startTime}ms`);
    return null;
  }

  async reverseGeocode(coordinates: Coordinates): Promise<string | null> {
    console.info(`[GeoServiceRouter] ========== 开始逆地理编码 ==========`);
    console.info(`[GeoServiceRouter] 📍 坐标: ${coordinates.latitude}, ${coordinates.longitude}`);
    const startTime = Date.now();

    if (this.isInChina(coordinates)) {
      console.info(`[GeoServiceRouter] 🇨🇳 判定为中国区域，优先使用和风天气`);
      
      // 策略：和风 -> OpenWeather
      const result = await this.qweatherGeo.reverseGeocode(coordinates);
      if (result) {
        console.info(`[GeoServiceRouter] ✅ 和风逆编码成功，耗时: ${Date.now() - startTime}ms`);
        return result;
      }
      
      console.warn(`[GeoServiceRouter] ⚠️ 和风失败，降级到Open-Meteo`);
      const fallbackResult = await this.openMeteoGeo.reverseGeocode(coordinates);
      if (fallbackResult) {
        console.info(`[GeoServiceRouter] ✅ Open-Meteo逆编码成功，耗时: ${Date.now() - startTime}ms`);
        return fallbackResult;
      }
    } else {
      console.info(`[GeoServiceRouter] 🌍 判定为国际区域，优先使用Open-Meteo`);
      
      // 策略：Open-Meteo -> 和风
      // 注意：Open-Meteo目前不直接支持逆地理编码，这里可能会返回null，从而触发LocationService的降级
      const result = await this.openMeteoGeo.reverseGeocode(coordinates);
      if (result) {
        console.info(`[GeoServiceRouter] ✅ Open-Meteo逆编码成功，耗时: ${Date.now() - startTime}ms`);
        return result;
      }
      
      console.warn(`[GeoServiceRouter] ⚠️ Open-Meteo失败(或不支持)，降级到和风`);
      const fallbackResult = await this.qweatherGeo.reverseGeocode(coordinates);
      if (fallbackResult) {
        console.info(`[GeoServiceRouter] ✅ 和风逆编码成功，耗时: ${Date.now() - startTime}ms`);
        return fallbackResult;
      }
    }
    
    console.error(`[GeoServiceRouter] ❌ 所有逆地理编码服务均失败，耗时: ${Date.now() - startTime}ms`);
    return null;
  }

  private isInChina(coordinates: Coordinates): boolean {
    const lat = coordinates.latitude;
    const lon = coordinates.longitude;
    
    return (lat >= 3.86 && lat <= 53.56 && lon >= 73.50 && lon <= 135.09) ||
           (lat >= 22.15 && lat <= 22.56 && lon >= 113.83 && lon <= 114.41) ||
           (lat >= 22.11 && lat <= 22.22 && lon >= 113.52 && lon <= 113.60) ||
           (lat >= 21.90 && lat <= 25.30 && lon >= 119.50 && lon <= 122.00);
  }
}
