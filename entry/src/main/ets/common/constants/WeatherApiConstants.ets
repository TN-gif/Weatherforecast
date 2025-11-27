

import { WeatherApiConfig } from '../../data/models/WeatherModels';

export class WeatherApiConstants {
  // Open-Meteo配置 (无需API Key)
  static readonly OPEN_METEO_CONFIG: WeatherApiConfig = {
    baseUrl: 'https://api.open-meteo.com/v1',
    apiKey: '', // Open-Meteo is free for non-commercial use
    hourlyCount: 24,
    dailyCount: 7
  };

  static readonly OPEN_METEO_GEO_CONFIG: WeatherApiConfig = {
    baseUrl: 'https://geocoding-api.open-meteo.com/v1',
    apiKey: '',
    hourlyCount: 0, // Not applicable for geo API
    dailyCount: 0  // Not applicable for geo API
  };

  // 和风天气配置（中国区域）
  static readonly QWEATHER_CONFIG: WeatherApiConfig = {
    baseUrl: 'https://mk4d93cexw.re.qweatherapi.com', // 用户自定义域名
    apiKey: '23d5896540cf4048a5c7242694cf9886',
    hourlyCount: 24,
    dailyCount: 7
  };
}
