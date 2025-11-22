export class AppConstants {
  static readonly APP_NAME: string = 'Aurora Weather';
  static readonly DEFAULT_CITY_ID: string = 'city_shanghai';
  static readonly DEFAULT_COUNTRY: string = 'China';
  static readonly LOCATION_PERMISSION: string = 'ohos.permission.LOCATION';
  static readonly APPROX_LOCATION_PERMISSION: string = 'ohos.permission.APPROXIMATELY_LOCATION';
  static readonly GET_NETWORK_INFO_PERMISSION: string = 'ohos.permission.GET_NETWORK_INFO';
  static readonly PREFERENCES_FILE: string = 'aurora_weather_pref';
  static readonly APP_SETTINGS_PREF: string = 'aurora_weather_settings';
  static readonly RDB_NAME: string = 'aurora_weather.db';
  static readonly SCHEMA_VERSION: number = 2;
  static readonly CITY_TABLE: string = 'cities';
  static readonly WEATHER_TABLE: string = 'weather_snapshot';
  static readonly METADATA_TABLE: string = 'metadata';
  static readonly MOCK_PAYLOAD_FILE: string = 'weather_mock_payload.json';
  static readonly MIN_REFRESH_INTERVAL_MINUTES: number = 15;
  static readonly MAX_CITIES: number = 6;
  static readonly BACKGROUND_MODE_KEY: string = 'background_mode';
  static readonly AUTO_LOCATION_KEY: string = 'auto_location';
  static readonly DEFAULT_BACKGROUND_MODE: string = 'gradient';
}
