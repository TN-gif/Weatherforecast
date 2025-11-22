import http from '@ohos.net.http';
import { City, CitySource, Coordinates } from '../models/WeatherModels';

export interface CitySearchResult {
  id: string;
  name: string;
  country: string;
  state?: string;
  coordinates: Coordinates;
}

interface GeocodingApiResult {
  id?: number;
  name: string;
  country: string;
  admin1?: string;
  latitude: number;
  longitude: number;
}

interface GeocodingApiResponse {
  results?: GeocodingApiResult[];
}

export class CitySearchService {
  private static instance: CitySearchService | null = null;
  private readonly baseUrl: string = 'https://geocoding-api.open-meteo.com/v1/search';
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

    console.info(`[CitySearchService] Searching for cities: "${keyword}"`);
    
    const httpRequest = http.createHttp();
    try {
      const query = `${this.baseUrl}?name=${encodeURIComponent(keyword.trim())}&count=10&language=zh&format=json`;
      console.info(`[CitySearchService] Request URL: ${query}`);

      const response = await httpRequest.request(query, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      if (response.responseCode !== 200) {
        console.error(`[CitySearchService] Search failed: ${response.responseCode}`);
        return [];
      }

      const data = JSON.parse(response.result as string) as GeocodingApiResponse;
      console.info(`[CitySearchService] Found ${data.results?.length || 0} results`);

      if (!data.results || !Array.isArray(data.results)) {
        return [];
      }

      const results: CitySearchResult[] = data.results
        .filter((item: GeocodingApiResult) => this.isValidResult(item))
        .map((item: GeocodingApiResult) => this.mapToSearchResult(item))
        .filter((result: CitySearchResult) => !this.existingCityIds.has(result.id));

      console.info(`[CitySearchService] Filtered to ${results.length} new cities`);
      return results;

    } catch (error) {
      console.error(`[CitySearchService] Search error:`, error);
      return [];
    } finally {
      httpRequest.destroy();
    }
  }

  private isValidResult(item: GeocodingApiResult): boolean {
    return item && 
           typeof item.name === 'string' && 
           typeof item.country === 'string' &&
           typeof item.latitude === 'number' && 
           typeof item.longitude === 'number' &&
           item.latitude >= -90 && item.latitude <= 90 &&
           item.longitude >= -180 && item.longitude <= 180;
  }

  private mapToSearchResult(item: GeocodingApiResult): CitySearchResult {
    const coordinates: Coordinates = {
      latitude: item.latitude,
      longitude: item.longitude
    };

    // 生成唯一ID
    const id = `search_${Math.round(item.latitude * 1000)}_${Math.round(item.longitude * 1000)}`;

    return {
      id: id,
      name: item.name,
      country: item.country,
      state: item.admin1 || undefined,
      coordinates: coordinates
    };
  }

  convertToCity(searchResult: CitySearchResult): City {
    const displayName = searchResult.state 
      ? `${searchResult.name}, ${searchResult.state}`
      : searchResult.name;

    return new City(
      searchResult.id,
      displayName,
      searchResult.country,
      searchResult.coordinates,
      CitySource.MANUAL,
      this.getThemeForLocation(searchResult.coordinates),
      this.getTimezoneOffset(searchResult.coordinates)
    );
  }

  private getThemeForLocation(coordinates: Coordinates): string {
    // 根据纬度选择主题
    const latitude = Math.abs(coordinates.latitude);
    
    if (latitude > 60) {
      return 'snow'; // 极地地区
    } else if (latitude > 40) {
      return 'cloudy'; // 温带地区
    } else if (latitude > 23.5) {
      return 'sunny'; // 亚热带地区
    } else {
      return 'sunny'; // 热带地区
    }
  }

  private getTimezoneOffset(coordinates: Coordinates): number {
    // 简单的时区估算（基于经度）
    // 实际应用中应该使用更精确的时区API
    const longitude = coordinates.longitude;
    const offsetHours = Math.round(longitude / 15);
    return offsetHours * 60; // 转换为分钟
  }

  // 搜索建议（本地化）
  getSearchSuggestions(): string[] {
    return [
      '北京', '上海', '广州', '深圳', '杭州', '南京', '成都', '武汉',
      'Beijing', 'Shanghai', 'Tokyo', 'Seoul', 'New York', 'London', 
      'Paris', 'Sydney', 'Singapore', 'Bangkok'
    ];
  }

  // 热门城市
  getPopularCities(): CitySearchResult[] {
    return [
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
  }
}
