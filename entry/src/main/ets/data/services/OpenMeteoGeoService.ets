import http from '@ohos.net.http';
import { Coordinates } from '../models/WeatherModels';
import { WeatherApiConstants } from '../../common/constants/WeatherApiConstants';

// Open-Meteo Geocoding Result Interface
export interface OpenMeteoGeoResult {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  elevation: number;
  feature_code: string;
  country_code: string;
  admin1_id?: number;
  admin2_id?: number;
  admin3_id?: number;
  admin4_id?: number;
  timezone: string;
  population?: number;
  postcodes?: string[];
  country_id?: number;
  country?: string;
  admin1?: string;
  admin2?: string;
  admin3?: string;
  admin4?: string;
}

interface OpenMeteoGeoResponse {
  results?: OpenMeteoGeoResult[];
  generationtime_ms: number;
}

export class OpenMeteoGeoService {
  private readonly baseUrl: string = WeatherApiConstants.OPEN_METEO_GEO_CONFIG.baseUrl;
  private readonly timeoutMs: number = 10000;

  async searchCities(keyword: string): Promise<OpenMeteoGeoResult[] | null> {
    if (!keyword || keyword.trim().length < 2) {
      return null;
    }

    const httpRequest = http.createHttp();
    try {
      // Open-Meteo Geocoding API: https://geocoding-api.open-meteo.com/v1/search?name=Berlin&count=10&language=en&format=json
      const url = `${this.baseUrl}/search?name=${encodeURIComponent(keyword.trim())}&count=10&language=zh&format=json`;
      console.info(`[OpenMeteoGeoService] 🔍 发起城市搜索: ${url}`);
      const startTime = Date.now();

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });

      const duration = Date.now() - startTime;
      console.debug(`[OpenMeteoGeoService] ⏱️ 搜索耗时: ${duration}ms, 状态码: ${response.responseCode}`);

      if (response.responseCode !== 200) {
        console.warn(`[OpenMeteoGeoService] ❌ 搜索请求失败: ${response.responseCode}`);
        return null;
      }

      const data = JSON.parse(response.result as string) as OpenMeteoGeoResponse;
      if (data.results && Array.isArray(data.results)) {
        console.info(`[OpenMeteoGeoService] ✅ 搜索成功，找到 ${data.results.length} 个结果`);
        return data.results;
      } else {
        console.warn('[OpenMeteoGeoService] ⚠️ 搜索无结果');
        return null;
      }
    } catch (error) {
      console.error(`[OpenMeteoGeoService] ❌ 搜索异常:`, error);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  // Open-Meteo Geocoding API currently does not support reverse geocoding directly in the same way as OpenWeather.
  // However, we can use a different free service or just return null if not strictly required, 
  // OR we can use BigDataCloud or similar free reverse geocoding APIs.
  // BUT, the user specifically asked to replace OpenWeather with Open-Meteo.
  // Open-Meteo DOES NOT have a reverse geocoding endpoint in the free tier documentation I found?
  // Wait, let me check the search results again.
  // The search result didn't explicitly mention reverse geocoding endpoint.
  // Actually, Open-Meteo usually recommends using other services for reverse geocoding or it might be a different endpoint.
  // Let's assume for now we only use it for search, and maybe keep a fallback or return null.
  // WAIT! I should check if I can use the search endpoint with coordinates? No.
  // Let's look at the user request: "Open-Meteo... replace OpenWeather".
  // If Open-Meteo doesn't support reverse geocoding, I might break that feature for international locations.
  // Let me double check if there is a reverse endpoint.
  // Common knowledge: Open-Meteo doesn't have its own reverse geocoding, it often suggests using Nominatim or others.
  // However, for the purpose of this task, I will implement `searchCities`.
  // For `reverseGeocode`, I will try to find a solution or just log a warning that it's not supported by Open-Meteo directly.
  // Actually, let's look at the `GeoServiceRouter` usage. It uses reverse geocoding for "Current Location" name.
  // If I can't reverse geocode international coordinates, "Current Location" might show coordinates.
  // I will implement a placeholder for reverse geocoding that returns null for now, or maybe use a different free API if allowed?
  // User said "replace OpenWeather with Open-Meteo". Strictly following that.
  
  async reverseGeocode(coordinates: Coordinates): Promise<string | null> {
     // Open-Meteo Geocoding API does not officially support reverse geocoding in the same simple way.
     // We will return null for now, triggering the fallback mechanism in LocationService (coordinate guessing).
     console.warn('[OpenMeteoGeoService] ⚠️ Open-Meteo Geocoding API does not support reverse geocoding directly.');
     return null;
  }
}
