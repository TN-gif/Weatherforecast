import http from '@ohos.net.http';
import { City, CitySource, Coordinates } from '../models/WeatherModels';
import { GeoServiceRouter, QWeatherLocationItem, OpenMeteoGeoResult } from './GeoServiceRouter';

export interface CitySearchResult {
  id: string;
  name: string;
  country: string;
  state?: string;
  coordinates: Coordinates;
  timezone?: string;  // 时区名称，如 "Asia/Shanghai"
  utcOffset?: string;  // UTC偏移，如 "+08:00"
}

// 定义数据包装接口
interface SearchDataWrapper {
  source: string;
  data: QWeatherCitySearchData | OpenMeteoGeoResult[];
}

interface QWeatherCitySearchData {
  code: string;
  location: QWeatherLocationItem[];
}

export class CitySearchService {
  private static instance: CitySearchService | null = null;
  private readonly geoRouter: GeoServiceRouter = new GeoServiceRouter();
  private existingCityIds: Set<string> = new Set();

  private constructor() {}

  static getInstance(): CitySearchService {
    if (CitySearchService.instance === null) {
      CitySearchService.instance = new CitySearchService();
    }
    return CitySearchService.instance;
  }

  setExistingCities(cityIds: string[]): void {
    this.existingCityIds = new Set(cityIds);
  }

  async searchCities(keyword: string): Promise<CitySearchResult[]> {
    if (!keyword || keyword.trim().length < 2) {
      return [];
    }

    console.info(`[CitySearchService] ========== 开始搜索城市: "${keyword}" ==========`);
    const startTime = Date.now();
    
    try {
      console.info('[CitySearchService] 📡 调用GeoRouter进行搜索...');
      const routerResult = await this.geoRouter.searchCities(keyword);
      
      if (!routerResult) {
        console.warn(`[CitySearchService] ⚠️ 搜索无结果，耗时: ${Date.now() - startTime}ms`);
        return [];
      }

      const source = routerResult.source;
      const data = routerResult.data;
      console.info(`[CitySearchService] ✅ 获取到搜索数据，来源: ${source}`);

      let results: CitySearchResult[] = [];
      
      if (source === 'qweather') {
        // 和风天气数据格式
        console.debug('[CitySearchService] 🔄 解析和风天气数据...');
        const qweatherData = data as QWeatherCitySearchData;
        results = qweatherData.location
          .filter((item: QWeatherLocationItem) => {
            const isValid = this.isValidQWeatherResult(item);
            if (!isValid) console.warn(`[CitySearchService] ⚠️ 忽略无效的和风数据项: ${JSON.stringify(item)}`);
            return isValid;
          })
          .map((item: QWeatherLocationItem) => this.mapQWeatherToSearchResult(item));
      } else {
        // Open-Meteo数据格式
        console.debug('[CitySearchService] 🔄 解析Open-Meteo数据...');
        const openMeteoData = data as OpenMeteoGeoResult[];
        results = openMeteoData
          .filter((item: OpenMeteoGeoResult) => {
             const isValid = this.isValidOpenMeteoResult(item);
             if (!isValid) console.warn(`[CitySearchService] ⚠️ 忽略无效的Open-Meteo数据项: ${JSON.stringify(item)}`);
             return isValid;
          })
          .map((item: OpenMeteoGeoResult) => this.mapOpenMeteoToSearchResult(item));
      }

      // 过滤已存在城市
      const initialCount = results.length;
      results = results.filter((result: CitySearchResult) => {
        const exists = this.existingCityIds.has(result.id);
        if (exists) {
          console.debug(`[CitySearchService] 🚫 过滤已存在城市: ${result.name} (${result.id})`);
        }
        return !exists;
      });

      console.info(`[CitySearchService] ✅ 搜索完成，耗时: ${Date.now() - startTime}ms`);
      console.info(`[CitySearchService] 📊 结果统计: 原始=${initialCount}, 过滤后=${results.length}`);
      
      return results;

    } catch (error) {
      console.error(`[CitySearchService] ❌ 搜索异常，耗时: ${Date.now() - startTime}ms:`, error);
      return [];
    }
  }

  private isValidQWeatherResult(item: QWeatherLocationItem): boolean {
    return item && 
           typeof item.name === 'string' &&
           typeof item.country === 'string' &&
           typeof item.lat === 'string' &&
           typeof item.lon === 'string';
  }

  private isValidOpenMeteoResult(item: OpenMeteoGeoResult): boolean {
    return item && 
           typeof item.name === 'string' && 
           typeof item.country === 'string' &&
           typeof item.latitude === 'number' && 
           typeof item.longitude === 'number';
  }

  private mapQWeatherToSearchResult(item: QWeatherLocationItem): CitySearchResult {
    const coordinates: Coordinates = {
      latitude: parseFloat(item.lat),
      longitude: parseFloat(item.lon)
    };

    const id = `qw_${item.id}`;
    
    // 🔧 改进：构建更精准的城市名称显示
    // 优先级：adm2（市级） > adm1（省级） > country（国家）
    let displayName = item.name;
    
    // 对于中国城市，显示完整的行政区划
    if (item.country === '中国' || item.country === 'China') {
      if (item.adm2 && item.adm2 !== item.name) {
        // 如果有市级信息且与城市名不同，显示"城市名, 市级, 省级"
        // 例如："路南区, 唐山市, 河北省"
        if (item.adm1 && item.adm1 !== item.adm2) {
          displayName = `${item.name}, ${item.adm2}, ${item.adm1}`;
        } else {
          displayName = `${item.name}, ${item.adm2}`;
        }
      } else if (item.adm1 && item.adm1 !== item.name) {
        // 如果只有省级信息，显示"城市名, 省级"
        // 例如："唐山, 河北省"
        displayName = `${item.name}, ${item.adm1}`;
      }
    } else {
      // 对于国际城市，显示"城市名, 国家"
      if (item.adm1 && item.adm1 !== item.name) {
        displayName = `${item.name}, ${item.adm1}, ${item.country}`;
      } else {
        displayName = `${item.name}, ${item.country}`;
      }
    }

    // 🔧 新增：保存时区信息到搜索结果
    const result: CitySearchResult = {
      id: id,
      name: displayName,  // 使用构建好的完整显示名称
      country: item.country,
      state: item.adm1 || undefined,
      coordinates: coordinates,
      timezone: item.tz,  // 时区名称，如 "Asia/Shanghai"
      utcOffset: item.utcOffset  // UTC偏移，如 "+08:00"
    };
    return result;
  }

  private mapOpenMeteoToSearchResult(item: OpenMeteoGeoResult): CitySearchResult {
    const coordinates: Coordinates = {
      latitude: item.latitude,
      longitude: item.longitude
    };

    const id = `om_${item.id}`;
    const country: string = item.country ?? 'Unknown';

    const result: CitySearchResult = {
      id: id,
      name: item.name, // OpenMeteo names are usually English/local, might need better handling if Chinese is preferred
      country: country,
      state: item.admin1 || undefined,
      coordinates: coordinates
    };
    return result;
  }

  convertToCity(searchResult: CitySearchResult): City {
    console.info(`[CitySearchService] 🏗️ 将搜索结果转换为城市对象: ${searchResult.name}`);
    
    // 🔧 改进：直接使用已经构建好的完整显示名称
    const displayName = searchResult.name;

    const theme = this.getThemeForLocation(searchResult.coordinates);
    
    // 🔧 修复：优先使用和风天气API返回的实际时区数据
    let timezoneOffset: number;
    if (searchResult.utcOffset) {
      // 解析 UTC 偏移量，如 "+08:00" → 480分钟
      timezoneOffset = this.parseUtcOffset(searchResult.utcOffset);
      console.info(`[CitySearchService] ✅ 使用API返回的时区: ${searchResult.timezone} (${searchResult.utcOffset}) = ${timezoneOffset}分钟`);
    } else {
      // 降级方案：根据经度估算
      timezoneOffset = this.getTimezoneOffset(searchResult.coordinates);
      console.warn(`[CitySearchService] ⚠️ API未返回时区，使用经度估算: ${timezoneOffset}分钟`);
    }
    
    console.debug(`[CitySearchService] 🎨 自动匹配主题: ${theme}`);

    const city = new City(
      searchResult.id,
      displayName,
      searchResult.country,
      searchResult.coordinates,
      CitySource.MANUAL,
      theme,
      timezoneOffset
    );
    
    console.info(`[CitySearchService] ✅ 城市对象创建成功: ID=${city.id}, 显示名称=${displayName}, 时区偏移=${timezoneOffset}分钟`);
    return city;
  }

  /**
   * 解析 UTC 偏移量字符串为分钟数
   * @param utcOffset UTC偏移量字符串，如 "+08:00", "-05:30"
   * @returns 偏移量（分钟），如 480, -330
   */
  private parseUtcOffset(utcOffset: string): number {
    try {
      // 移除 "UTC" 前缀（如果有）
      const offset = utcOffset.replace('UTC', '').trim();
      
      // 检查格式是否有效
      if (!offset || offset.length < 3) {
        console.warn(`[CitySearchService] ⚠️ 无效的UTC偏移格式: ${utcOffset}，使用默认值0`);
        return 0;
      }
      
      // 解析符号
      const sign = offset.startsWith('-') ? -1 : 1;
      
      // 移除符号，分割小时和分钟
      const parts = offset.replace(/[+-]/, '').split(':');
      const hours = parseInt(parts[0]) || 0;
      const minutes = parseInt(parts[1]) || 0;
      
      // 验证范围（UTC-12 到 UTC+14）
      const totalMinutes = sign * (hours * 60 + minutes);
      if (totalMinutes < -720 || totalMinutes > 840) {
        console.warn(`[CitySearchService] ⚠️ UTC偏移超出有效范围: ${totalMinutes}分钟，使用默认值0`);
        return 0;
      }
      
      return totalMinutes;
    } catch (error) {
      console.error(`[CitySearchService] ❌ 解析UTC偏移失败: ${utcOffset}, 错误: ${error}`);
      return 0;
    }
  }

  private getThemeForLocation(coordinates: Coordinates): string {
    const latitude = Math.abs(coordinates.latitude);
    
    // 🔧 修复：只返回ThemeConstants中存在的主题
    // 可用主题：sunny, rainy, snow（不包含cloudy）
    if (latitude > 60) {
      return 'snow';  // 高纬度地区（极地）
    } else if (latitude > 40) {
      return 'sunny';  // 🔧 修复：改为sunny（原来是cloudy，但没有这个主题）
    } else if (latitude > 23.5) {
      return 'sunny';  // 温带地区
    } else {
      return 'sunny';  // 热带地区
    }
  }

  private getTimezoneOffset(coordinates: Coordinates): number {
    const longitude = coordinates.longitude;
    const offsetHours = Math.round(longitude / 15);
    return offsetHours * 60;
  }

  getSearchSuggestions(): string[] {
    return [
      '北京', '上海', '广州', '深圳', '杭州', '南京', '成都', '武汉',
      'Beijing', 'Shanghai', 'Tokyo', 'Seoul', 'New York', 'London', 
      'Paris', 'Sydney', 'Singapore', 'Bangkok'
    ];
  }

  getPopularCities(): CitySearchResult[] {
    const popularList: CitySearchResult[] = [
      {
        id: 'popular_beijing',
        name: '北京',
        country: 'China',
        coordinates: { latitude: 39.9042, longitude: 116.4074 }
      },
      {
        id: 'popular_shanghai',
        name: '上海',
        country: 'China',
        coordinates: { latitude: 31.2304, longitude: 121.4737 }
      },
      {
        id: 'popular_guangzhou',
        name: '广州',
        country: 'China',
        coordinates: { latitude: 23.1291, longitude: 113.2644 }
      },
      {
        id: 'popular_shenzhen',
        name: '深圳',
        country: 'China',
        coordinates: { latitude: 22.5431, longitude: 114.0579 }
      }
    ];
    return popularList;
  }
}
