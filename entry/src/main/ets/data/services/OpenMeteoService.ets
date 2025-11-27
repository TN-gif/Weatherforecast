import http from '@ohos.net.http';
import { WeatherSnapshot, CurrentWeather, DailyForecast, HourlyForecast, Coordinates } from '../models/WeatherModels';
import { WeatherApiConstants } from '../../common/constants/WeatherApiConstants';

// Open-Meteo API Response Interfaces
interface OpenMeteoCurrent {
  time: string;
  interval: number;
  temperature_2m: number;
  relative_humidity_2m: number;
  apparent_temperature: number;
  is_day: number;
  precipitation: number;
  rain: number;
  showers: number;
  snowfall: number;
  weather_code: number;
  cloud_cover: number;
  pressure_msl: number;
  surface_pressure: number;
  wind_speed_10m: number;
  wind_direction_10m: number;
  wind_gusts_10m: number;
}

interface OpenMeteoHourly {
  time: string[];
  temperature_2m: number[];
  relative_humidity_2m: number[];
  dew_point_2m: number[];
  apparent_temperature: number[];
  precipitation_probability: number[];
  precipitation: number[];
  weather_code: number[];
  pressure_msl: number[];
  surface_pressure: number[];
  cloud_cover: number[];
  visibility: number[];
  wind_speed_10m: number[];
  wind_direction_10m: number[];
  uv_index: number[];
}

interface OpenMeteoDaily {
  time: string[];
  weather_code: number[];
  temperature_2m_max: number[];
  temperature_2m_min: number[];
  apparent_temperature_max: number[];
  apparent_temperature_min: number[];
  sunrise: string[];
  sunset: string[];
  uv_index_max: number[];
  precipitation_sum: number[];
  rain_sum: number[];
  showers_sum: number[];
  snowfall_sum: number[];
  precipitation_hours: number[];
  precipitation_probability_max: number[];
  wind_speed_10m_max: number[];
  wind_gusts_10m_max: number[];
  wind_direction_10m_dominant: number[];
}

interface OpenMeteoResponse {
  latitude: number;
  longitude: number;
  generationtime_ms: number;
  utc_offset_seconds: number;
  timezone: string;
  timezone_abbreviation: string;
  elevation: number;
  current_units: Record<string, string>;
  current: OpenMeteoCurrent;
  hourly_units: Record<string, string>;
  hourly: OpenMeteoHourly;
  daily_units: Record<string, string>;
  daily: OpenMeteoDaily;
}

interface WmoWeatherCondition {
  text: string;
  icon: string;
  themeKey: string;
  description: string;
}

// Open-Meteo Air Quality API 响应接口
interface OpenMeteoAirQualityCurrent {
  time: string;
  us_aqi: number;  // 美国AQI标准
  pm2_5?: number;
  pm10?: number;
}

interface OpenMeteoAirQualityResponse {
  latitude: number;
  longitude: number;
  current: OpenMeteoAirQualityCurrent;
}

export class OpenMeteoService {
  private readonly baseUrl: string = WeatherApiConstants.OPEN_METEO_CONFIG.baseUrl;
  private readonly timeoutMs: number = 15000;

  async fetchWeather(cityId: string, coordinates: Coordinates, timezoneOffsetMinutes?: number): Promise<WeatherSnapshot> {
    const httpRequest = http.createHttp();
    
    // 构建请求URL
    // 需要的参数:
    // current: temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m
    // hourly: temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,precipitation_probability,precipitation,weather_code,pressure_msl,surface_pressure,cloud_cover,visibility,wind_speed_10m,wind_direction_10m,uv_index
    // daily: weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,uv_index_max,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant
    // timezone: auto
    
    const params = [
      `latitude=${coordinates.latitude}`,
      `longitude=${coordinates.longitude}`,
      'current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m',
      'hourly=temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,precipitation_probability,precipitation,weather_code,pressure_msl,surface_pressure,cloud_cover,visibility,wind_speed_10m,wind_direction_10m,uv_index',
      'daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,uv_index_max,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant',
      'timezone=auto'
    ].join('&');

    const url = `${this.baseUrl}/forecast?${params}`;
    console.info(`[OpenMeteoService] 📡 发起天气请求: ${url}`);

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });

      if (response.responseCode !== 200) {
        throw new Error(`Open-Meteo API Error: ${response.responseCode}`);
      }

      const data = JSON.parse(response.result as string) as OpenMeteoResponse;
      
      // ✅ 调用空气质量API
      console.info(`[OpenMeteoService] 🌬️ 获取空气质量数据...`);
      const aqi = await this.fetchAirQuality(coordinates.latitude, coordinates.longitude);
      
      return this.mapToSnapshot(cityId, data, aqi, timezoneOffsetMinutes);
    } catch (error) {
      console.error(`[OpenMeteoService] ❌ 请求失败:`, error);
      throw error instanceof Error ? error : new Error(String(error));
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 获取空气质量数据（单独的API）
   */
  private async fetchAirQuality(lat: number, lon: number): Promise<number> {
    const airQualityUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
    const params = [
      `latitude=${lat}`,
      `longitude=${lon}`,
      'current=us_aqi'
    ].join('&');
    
    const url = `${airQualityUrl}?${params}`;
    const httpRequest = http.createHttp();
    
    try {
      console.debug(`[OpenMeteoService] 📤 请求空气质量: ${url}`);
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });
      
      if (response.responseCode !== 200) {
        console.warn(`[OpenMeteoService] ⚠️ 空气质量API返回错误: ${response.responseCode}`);
        return 0;
      }
      
      const data = JSON.parse(response.result as string) as OpenMeteoAirQualityResponse;
      const aqiValue = Math.round(data.current.us_aqi || 0);
      console.info(`[OpenMeteoService] ✅ 空气质量获取成功: AQI=${aqiValue}`);
      return aqiValue;
    } catch (error) {
      console.error(`[OpenMeteoService] ❌ 空气质量API调用失败:`, error);
      return 0;  // 失败时返回0
    } finally {
      httpRequest.destroy();
    }
  }

  private mapToSnapshot(cityId: string, data: OpenMeteoResponse, aqi: number, timezoneOffsetMinutes?: number): WeatherSnapshot {
    const current = this.mapCurrentWeather(data.current, data.daily, data.hourly, aqi);
    const hourly = this.mapHourlyForecast(data.hourly);
    const daily = this.mapDailyForecast(data.daily);

    // 🔧 修复：优先使用传入的时区，否则使用API返回的时区
    const actualTimezoneOffset = timezoneOffsetMinutes !== undefined 
      ? timezoneOffsetMinutes 
      : Math.round(data.utc_offset_seconds / 60);
    
    console.info(`[OpenMeteoService] 🕒 使用时区偏移: ${actualTimezoneOffset}分钟`);

    return {
      cityId: cityId,
      lastUpdatedIso: new Date().toISOString(),
      timezoneOffsetMinutes: actualTimezoneOffset,
      current: current,
      hourly: hourly,
      daily: daily,
      advice: [], // Open-Meteo 免费版不直接提供生活建议
      alerts: [], // 免费版无预警
      rainForecast: [], // 免费版无分钟级降雨
      dataSource: 'open-meteo'
    };
  }

  private mapCurrentWeather(current: OpenMeteoCurrent, daily: OpenMeteoDaily, hourly: OpenMeteoHourly, aqi: number): CurrentWeather {
    const condition = this.mapWmoCode(current.weather_code, current.is_day === 1);
    
    // 获取当天的最高/最低温
    const maxTemp = daily.temperature_2m_max.length > 0 ? daily.temperature_2m_max[0] : current.temperature_2m;
    const minTemp = daily.temperature_2m_min.length > 0 ? daily.temperature_2m_min[0] : current.temperature_2m;
    const uvIndex = daily.uv_index_max.length > 0 ? daily.uv_index_max[0] : 0;
    
    // ✅ 从 hourly 数据中获取当前能见度（第一个小时的数据）
    let visibilityKm = 10; // 默认值
    if (hourly.visibility && hourly.visibility.length > 0) {
      visibilityKm = Math.round(hourly.visibility[0] / 1000);  // 转换为 km
      console.info(`[OpenMeteoService] ✅ 能见度获取成功: ${visibilityKm}km (原始值: ${hourly.visibility[0]}m)`);
    } else {
      console.warn(`[OpenMeteoService] ⚠️ 能见度数据不可用，使用默认值10km`);
    }
    
    // ✅ 从daily数据中提取日出日落时间，并格式化为 HH:mm
    let sunrise = '06:00';
    let sunset = '18:00';
    if (daily.sunrise && daily.sunrise.length > 0) {
      sunrise = this.extractTimeFromIso(daily.sunrise[0]);
      console.info(`[OpenMeteoService] ✅ 日出时间: ${sunrise} (原始: ${daily.sunrise[0]})`);
    }
    if (daily.sunset && daily.sunset.length > 0) {
      sunset = this.extractTimeFromIso(daily.sunset[0]);
      console.info(`[OpenMeteoService] ✅ 日落时间: ${sunset} (原始: ${daily.sunset[0]})`);
    }

    const weather: CurrentWeather = {
      temperatureC: current.temperature_2m,
      feelsLikeC: current.apparent_temperature,
      condition: {
        description: condition.description,
        iconCode: condition.icon,
        themeKey: condition.themeKey,
        emotion: 'neutral' // Default emotion
      },
      humidity: current.relative_humidity_2m,
      windSpeedKph: current.wind_speed_10m,
      windDirection: String(current.wind_direction_10m),
      pressureHpa: current.pressure_msl,
      uvIndex: uvIndex,
      visibilityKm: visibilityKm,  // ✅ 使用真实能见度数据
      aqi: aqi,  // ✅ 使用真实AQI数据
      sunrise: sunrise,  // ✅ 格式化后的日出时间 HH:mm
      sunset: sunset     // ✅ 格式化后的日落时间 HH:mm
    };
    return weather;
  }

  /**
   * 从ISO格式时间字符串中提取 HH:mm 部分
   * @param isoString ISO格式时间，如 "2025-11-27T07:18:00"
   * @returns HH:mm 格式，如 "07:18"
   */
  private extractTimeFromIso(isoString: string): string {
    try {
      console.debug(`[OpenMeteoService] 🔍 提取时间 - 输入: "${isoString}", 类型: ${typeof isoString}`);
      
      // 检查输入是否为字符串
      if (typeof isoString !== 'string') {
        console.error(`[OpenMeteoService] ❌ 输入不是字符串: ${isoString}`);
        return '--:--';
      }
      
      // 检查是否包含 'T'
      if (!isoString.includes('T')) {
        console.error(`[OpenMeteoService] ❌ 输入不包含'T': ${isoString}`);
        return '--:--';
      }
      
      // ISO格式: 2025-11-27T07:18:00 或 2025-11-27T07:18:00+00:00
      const parts = isoString.split('T');
      console.debug(`[OpenMeteoService] 🔍 分割结果: parts.length=${parts.length}, parts[0]="${parts[0]}", parts[1]="${parts[1]}"`);
      
      const timePart = parts[1];  // "07:18:00" 或 "07:18:00+00:00"
      if (timePart && timePart.length >= 5) {
        const hhmm = timePart.substring(0, 5);  // "07:18"
        console.debug(`[OpenMeteoService] ✅ 提取成功: "${hhmm}"`);
        return hhmm;
      }
      
      console.error(`[OpenMeteoService] ❌ timePart无效: "${timePart}"`);
      return '--:--';
    } catch (error) {
      console.error(`[OpenMeteoService] ❌ 时间格式化失败: ${isoString}`, error);
      return '--:--';
    }
  }

  private mapHourlyForecast(hourly: OpenMeteoHourly): HourlyForecast[] {
    const forecasts: HourlyForecast[] = [];
    // 只取未来24小时
    const limit = Math.min(hourly.time.length, 24);

    for (let i = 0; i < limit; i++) {
      const isDay = this.isDaytime(hourly.time[i]);
      const condition = this.mapWmoCode(hourly.weather_code[i], isDay);
      const forecast: HourlyForecast = {
        time: hourly.time[i],
        temperatureC: hourly.temperature_2m[i],
        precipitationProbability: hourly.precipitation_probability[i],
        iconCode: condition.icon,
        description: condition.description
      };
      forecasts.push(forecast);
    }
    return forecasts;
  }

  private mapDailyForecast(daily: OpenMeteoDaily): DailyForecast[] {
    const forecasts: DailyForecast[] = [];
    // 取7天
    const limit = Math.min(daily.time.length, 7);

    for (let i = 0; i < limit; i++) {
      const condition = this.mapWmoCode(daily.weather_code[i], true);
      const forecast: DailyForecast = {
        date: daily.time[i],
        maxTempC: daily.temperature_2m_max[i],
        minTempC: daily.temperature_2m_min[i],
        iconCode: condition.icon,
        description: condition.description,
        precipitationProbability: daily.precipitation_probability_max[i]
      };
      forecasts.push(forecast);
    }
    return forecasts;
  }

  // 辅助方法：判断是否为白天 (简单根据时间判断，6-18点为白天)
  // 更精确的方法是使用 daily.sunrise 和 daily.sunset，但 hourly 数据中没有直接对应
  private isDaytime(timeStr: string): boolean {
    const hour = new Date(timeStr).getHours();
    return hour >= 6 && hour < 18;
  }

  /**
   * WMO Weather interpretation codes (WW)
   * Code	Description
   * 0	Clear sky
   * 1, 2, 3	Mainly clear, partly cloudy, and overcast
   * 45, 48	Fog and depositing rime fog
   * 51, 53, 55	Drizzle: Light, moderate, and dense intensity
   * 56, 57	Freezing Drizzle: Light and dense intensity
   * 61, 63, 65	Rain: Slight, moderate and heavy intensity
   * 66, 67	Freezing Rain: Light and heavy intensity
   * 71, 73, 75	Snow fall: Slight, moderate, and heavy intensity
   * 77	Snow grains
   * 80, 81, 82	Rain showers: Slight, moderate, and violent
   * 85, 86	Snow showers slight and heavy
   * 95 *	Thunderstorm: Slight or moderate
   * 96, 99 *	Thunderstorm with slight and heavy hail
   */
  private mapWmoCode(code: number, isDay: boolean): WmoWeatherCondition {
    const suffix = isDay ? 'd' : 'n';
    
    switch (code) {
      case 0:
        return { text: '晴', icon: '100', themeKey: 'sunny', description: '晴朗无云' };
      case 1:
      case 2:
        return { text: '多云', icon: '101', themeKey: 'sunny', description: '多云' };
      case 3:
        return { text: '阴', icon: '104', themeKey: 'sunny', description: '阴天' };  // 🔧 修复：改为sunny
      case 45:
      case 48:
        return { text: '雾', icon: '501', themeKey: 'sunny', description: '有雾' };  // 🔧 修复：改为sunny
      case 51:
      case 53:
      case 55:
        return { text: '毛毛雨', icon: '300', themeKey: 'rainy', description: '毛毛雨' };
      case 56:
      case 57:
        return { text: '冻雨', icon: '304', themeKey: 'rainy', description: '冻雨' };
      case 61:
        return { text: '小雨', icon: '305', themeKey: 'rainy', description: '小雨' };
      case 63:
        return { text: '中雨', icon: '306', themeKey: 'rainy', description: '中雨' };
      case 65:
        return { text: '大雨', icon: '307', themeKey: 'rainy', description: '大雨' };
      case 66:
      case 67:
        return { text: '冻雨', icon: '304', themeKey: 'rainy', description: '冻雨' };
      case 71:
        return { text: '小雪', icon: '400', themeKey: 'snow', description: '小雪' };
      case 73:
        return { text: '中雪', icon: '401', themeKey: 'snow', description: '中雪' };
      case 75:
        return { text: '大雪', icon: '402', themeKey: 'snow', description: '大雪' };
      case 77:
        return { text: '雪粒', icon: '403', themeKey: 'snow', description: '雪粒' };
      case 80:
      case 81:
      case 82:
        return { text: '阵雨', icon: '300', themeKey: 'rainy', description: '阵雨' };
      case 85:
      case 86:
        return { text: '阵雪', icon: '400', themeKey: 'snow', description: '阵雪' };
      case 95:
        return { text: '雷阵雨', icon: '302', themeKey: 'rainy', description: '雷阵雨' };
      case 96:
      case 99:
        return { text: '雷阵雨伴有冰雹', icon: '304', themeKey: 'rainy', description: '雷雨冰雹' };
      default:
        return { text: '未知', icon: '999', themeKey: 'sunny', description: '未知天气' };
    }
  }
}
