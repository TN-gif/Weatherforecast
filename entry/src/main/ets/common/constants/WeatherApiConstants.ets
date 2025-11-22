import { WeatherApiConfig } from '../../data/models/WeatherModels';

export class WeatherApiConstants {
  static readonly OPEN_METEO_CONFIG: WeatherApiConfig = {
    baseUrl: 'https://api.open-meteo.com/v1/forecast',
    apiKey: '',
    hourlyCount: 12,
    dailyCount: 5
  };
}
