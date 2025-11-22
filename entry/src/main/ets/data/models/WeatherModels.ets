export enum CitySource {
  AUTO = 0,
  MANUAL = 1,
  MOCK = 2
}

export enum LocationErrorCode {
  PERMISSION_DENIED = 201,
  LOCATION_SWITCH_OFF = 301,
  LOCATION_TIMEOUT = 800,
  CONTEXT_UNAVAILABLE = 900,
  NETWORK_ERROR = 1001,
  UNKNOWN_ERROR = 9999
}

export class LocationError extends Error {
  readonly code: LocationErrorCode;
  
  constructor(code: LocationErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = 'LocationError';
  }
}

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export class City {
  readonly id: string;
  readonly name: string;
  readonly country: string;
  readonly coordinates: Coordinates;
  readonly source: CitySource;
  readonly videoTheme: string;
  readonly timeZoneOffsetMinutes: number;

  constructor(id: string, name: string, country: string, coordinates: Coordinates, source: CitySource, videoTheme: string, timeZoneOffsetMinutes: number) {
    this.id = id;
    this.name = name;
    this.country = country;
    this.coordinates = coordinates;
    this.source = source;
    this.videoTheme = videoTheme;
    this.timeZoneOffsetMinutes = timeZoneOffsetMinutes;
  }
}

export interface WeatherCondition {
  description: string;
  iconCode: string;
  themeKey: string;
  emotion: string;
}

export interface CurrentWeather {
  temperatureC: number;
  feelsLikeC: number;
  humidity: number;
  windSpeedKph: number;
  windDirection: string;
  pressureHpa: number;
  visibilityKm: number;
  uvIndex: number;
  aqi: number;
  sunrise: string;
  sunset: string;
  condition: WeatherCondition;
}

export interface HourlyForecast {
  time: string;
  temperatureC: number;
  precipitationProbability: number;
  iconCode: string;
  description: string;
}

export interface DailyForecast {
  date: string;
  minTempC: number;
  maxTempC: number;
  iconCode: string;
  description: string;
  precipitationProbability: number;
}

export interface AdviceItem {
  id: string;
  icon: string;
  tone: string;
  content: string;
}

export interface WeatherSnapshot {
  cityId: string;
  lastUpdatedIso: string;
  timezoneOffsetMinutes: number;
  current: CurrentWeather;
  hourly: HourlyForecast[];
  daily: DailyForecast[];
  advice: AdviceItem[];
  dataSource: string;
}

export interface WeatherApiConfig {
  readonly baseUrl: string;
  readonly apiKey: string;
  readonly hourlyCount: number;
  readonly dailyCount: number;
}

export interface TrendPoint {
  readonly label: string;
  readonly temperature: number;
  readonly precipitationProbability: number;
}

export enum RefreshState {
  IDLE = 0,
  REFRESHING = 1,
  ERROR = 2
}
