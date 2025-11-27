import http from '@ohos.net.http';
import { Coordinates } from '../models/WeatherModels';

/**
 * 时区服务
 * 用于根据城市经纬度获取时区偏移量
 */
export class TimeZoneService {
  private static instance: TimeZoneService;
  private readonly timeoutMs: number = 10000;

  private constructor() {}

  static getInstance(): TimeZoneService {
    if (!TimeZoneService.instance) {
      TimeZoneService.instance = new TimeZoneService();
    }
    return TimeZoneService.instance;
  }

  /**
   * 根据经纬度获取时区偏移量（分钟）
   * @param coords 经纬度坐标
   * @returns 时区偏移量（分钟），相对于UTC。例如：UTC+8 = 480, UTC-5 = -300
   */
  async getTimezoneOffset(coords: Coordinates): Promise<number> {
    try {
      console.info(`[TimeZoneService] 🌍 获取时区: lat=${coords.latitude}, lon=${coords.longitude}`);
      
      // TODO: 集成实际的时区API
      // 选项1: TimeZoneDB API
      // 选项2: Google Time Zone API
      // 选项3: 和风天气API（如果支持）
      
      // 临时方案：根据经度粗略估算时区
      const estimatedOffset = this.estimateTimezoneByLongitude(coords.longitude);
      console.info(`[TimeZoneService] ⏰ 估算时区偏移: ${estimatedOffset}分钟 (UTC${estimatedOffset >= 0 ? '+' : ''}${estimatedOffset / 60})`);
      
      return estimatedOffset;
    } catch (error) {
      console.error(`[TimeZoneService] ❌ 获取时区失败: ${error}`);
      // 失败时返回UTC+8（中国标准时间）作为默认值
      return 480;
    }
  }

  /**
   * 临时方案：根据经度粗略估算时区
   * 注意：这只是粗略估算，不考虑夏令时和特殊时区
   * @param longitude 经度
   * @returns 时区偏移量（分钟）
   */
  private estimateTimezoneByLongitude(longitude: number): number {
    // 地球每15度经度对应1小时时差
    // 经度0度为UTC+0（格林威治）
    const hours = Math.round(longitude / 15);
    return hours * 60;
  }

  /**
   * 使用 TimeZoneDB API 获取时区（需要API Key）
   * API文档: https://timezonedb.com/api
   */
  private async fetchFromTimeZoneDB(coords: Coordinates, apiKey: string): Promise<number> {
    const url = `https://api.timezonedb.com/v2.1/get-time-zone?key=${apiKey}&format=json&by=position&lat=${coords.latitude}&lng=${coords.longitude}`;
    
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`);
      }

      const data = JSON.parse(response.result as string);
      
      if (data.status === 'OK') {
        // gmtOffset 是秒数，需要转换为分钟
        const offsetMinutes = Math.round(data.gmtOffset / 60);
        console.info(`[TimeZoneService] ✅ TimeZoneDB返回时区: ${data.zoneName}, 偏移: ${offsetMinutes}分钟`);
        return offsetMinutes;
      } else {
        throw new Error(`TimeZoneDB API error: ${data.message}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 使用 Google Time Zone API 获取时区（需要API Key）
   * API文档: https://developers.google.com/maps/documentation/timezone/overview
   */
  private async fetchFromGoogleTimeZone(coords: Coordinates, apiKey: string): Promise<number> {
    const timestamp = Math.floor(Date.now() / 1000);
    const url = `https://maps.googleapis.com/maps/api/timezone/json?location=${coords.latitude},${coords.longitude}&timestamp=${timestamp}&key=${apiKey}`;
    
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`);
      }

      const data = JSON.parse(response.result as string);
      
      if (data.status === 'OK') {
        // rawOffset + dstOffset = 总偏移量（秒）
        const totalOffsetSeconds = data.rawOffset + data.dstOffset;
        const offsetMinutes = Math.round(totalOffsetSeconds / 60);
        console.info(`[TimeZoneService] ✅ Google返回时区: ${data.timeZoneId}, 偏移: ${offsetMinutes}分钟`);
        return offsetMinutes;
      } else {
        throw new Error(`Google Time Zone API error: ${data.status}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 格式化时区偏移量为可读字符串
   * @param offsetMinutes 时区偏移量（分钟）
   * @returns 格式化字符串，例如 "UTC+8:00", "UTC-5:30"
   */
  static formatTimezoneOffset(offsetMinutes: number): string {
    const sign = offsetMinutes >= 0 ? '+' : '-';
    const absMinutes = Math.abs(offsetMinutes);
    const hours = Math.floor(absMinutes / 60);
    const minutes = absMinutes % 60;
    return `UTC${sign}${hours}:${minutes.toString().padStart(2, '0')}`;
  }
}
