import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';

/**
 * Widget weather data interface for cross-process sharing
 */
export interface WidgetWeatherData {
  cityName: string;
  temperature: number;
  temperatureUnit: string;
  condition: string;
  iconCode: string;
  themeKey: string;
  humidity: number;
  windSpeed: number;
  updateTime: string;
  timestamp: number;
  hourlyForecast: WidgetHourlyItem[];
}

/**
 * Hourly forecast item for widget display
 */
export interface WidgetHourlyItem {
  time: string;
  temperature: number;
  iconCode: string;
}

/**
 * Constants for widget data storage
 */
const WIDGET_PREF_NAME: string = 'aurora_weather_widget';
const WIDGET_DATA_KEY: string = 'widget_weather_data';
const FORM_IDS_KEY: string = 'widget_form_ids';

/**
 * WidgetDataStorage - Data storage for weather widget
 *
 * This class provides persistent storage for weather data.
 * Note: 主应用和卡片进程使用独立的 Preferences 存储
 * - 主应用保存天气数据到 Preferences
 * - 卡片进程从 Preferences 读取天气数据
 * - form IDs 由卡片进程管理（主应用无法访问）
 *
 * Requirements: 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3
 */
export class WidgetDataStorage {
  private static prefs: preferences.Preferences | null = null;

  /**
   * Initialize preferences with application context
   */
  private static async ensurePreferences(context: common.Context): Promise<preferences.Preferences> {
    // 每次都重新获取 Preferences，确保数据最新
    console.info('[WidgetDataStorage] ⚙️ Initializing widget preferences...');
    const prefs = await preferences.getPreferences(context, WIDGET_PREF_NAME);
    console.info('[WidgetDataStorage] ✅ Widget preferences initialized');
    return prefs;
  }


  /**
   * Save weather data to Preferences for widget access
   * Persists data to both AppStorage and Preferences simultaneously
   * 
   * @param context Application context for Preferences access
   * @param data Weather data to save
   * Requirements: 6.1, 6.2
   */
  static async saveForWidget(context: common.Context, data: WidgetWeatherData): Promise<void> {
    try {
      console.info('[WidgetDataStorage] 💾 Saving weather data for widget...');
      const prefs = await WidgetDataStorage.ensurePreferences(context);
      
      const jsonData = JSON.stringify(data);
      await prefs.put(WIDGET_DATA_KEY, jsonData);
      await prefs.flush();
      
      console.info(`[WidgetDataStorage] ✅ Weather data saved successfully for city: ${data.cityName}`);
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to save weather data:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * Load weather data from Preferences
   * Returns null if no data exists or parsing fails
   * 
   * @param context Application context for Preferences access
   * @returns Weather data or null if unavailable
   * Requirements: 6.2, 6.3, 6.4
   */
  static async loadForWidget(context: common.Context): Promise<WidgetWeatherData | null> {
    try {
      console.info('[WidgetDataStorage] 📖 Loading weather data for widget...');
      const prefs = await WidgetDataStorage.ensurePreferences(context);
      
      const jsonData = await prefs.get(WIDGET_DATA_KEY, '') as string;
      
      if (!jsonData || jsonData.length === 0) {
        console.info('[WidgetDataStorage] ⚠️ No weather data found in storage');
        return null;
      }
      
      const data = WidgetDataStorage.parseWeatherData(jsonData);
      if (data) {
        console.info(`[WidgetDataStorage] ✅ Weather data loaded for city: ${data.cityName}`);
      }
      return data;
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to load weather data:', error);
      return null;
    }
  }

  /**
   * Parse JSON string to WidgetWeatherData with validation
   * Returns null for invalid or malformed JSON without throwing
   * 
   * @param jsonData JSON string to parse
   * @returns Parsed data or null if invalid
   * Requirements: 6.3
   */
  static parseWeatherData(jsonData: string): WidgetWeatherData | null {
    try {
      if (!jsonData || jsonData.trim().length === 0) {
        console.warn('[WidgetDataStorage] ⚠️ Empty JSON data');
        return null;
      }
      
      // Parse JSON and directly cast to WidgetWeatherData
      // ArkTS will validate the structure at runtime
      const parsed: WidgetWeatherData = JSON.parse(jsonData) as WidgetWeatherData;
      
      // Debug: Log parsed data
      console.info(`[WidgetDataStorage] 📊 Parsed data - city: ${parsed.cityName}, temp: ${parsed.temperature}, humidity: ${parsed.humidity}, windSpeed: ${parsed.windSpeed}`);
      console.info(`[WidgetDataStorage] 📊 Hourly forecast count: ${parsed.hourlyForecast?.length ?? 0}`);
      
      // Validate required fields exist
      if (!parsed.cityName || !parsed.condition || !parsed.iconCode || !parsed.themeKey) {
        console.warn('[WidgetDataStorage] ⚠️ Weather data validation failed - missing required fields');
        console.warn(`[WidgetDataStorage] cityName: ${parsed.cityName}, condition: ${parsed.condition}, iconCode: ${parsed.iconCode}, themeKey: ${parsed.themeKey}`);
        return null;
      }
      
      if (typeof parsed.temperature !== 'number' || typeof parsed.timestamp !== 'number') {
        console.warn('[WidgetDataStorage] ⚠️ Weather data validation failed - invalid number fields');
        console.warn(`[WidgetDataStorage] temperature type: ${typeof parsed.temperature}, timestamp type: ${typeof parsed.timestamp}`);
        return null;
      }
      
      // Ensure hourlyForecast is an array
      if (!parsed.hourlyForecast) {
        console.info('[WidgetDataStorage] ⚠️ No hourly forecast, initializing empty array');
        parsed.hourlyForecast = [];
      }
      
      // Ensure humidity and windSpeed have default values if undefined
      if (parsed.humidity === undefined || parsed.humidity === null) {
        console.info('[WidgetDataStorage] ⚠️ Humidity undefined, setting to 0');
        parsed.humidity = 0;
      }
      if (parsed.windSpeed === undefined || parsed.windSpeed === null) {
        console.info('[WidgetDataStorage] ⚠️ WindSpeed undefined, setting to 0');
        parsed.windSpeed = 0;
      }
      
      console.info(`[WidgetDataStorage] ✅ Data validation passed - humidity: ${parsed.humidity}%, windSpeed: ${parsed.windSpeed} km/h`);
      return parsed;
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ JSON parse error:', error);
      return null;
    }
  }

  /**
   * Save form ID list to Preferences
   * 
   * @param context Application context
   * @param formIds Array of form IDs to save
   * Requirements: 7.3
   */
  static async saveFormIds(context: common.Context, formIds: string[]): Promise<void> {
    try {
      console.info(`[WidgetDataStorage] 💾 Saving ${formIds.length} form IDs...`);
      const prefs = await WidgetDataStorage.ensurePreferences(context);
      
      const jsonData = JSON.stringify(formIds);
      await prefs.put(FORM_IDS_KEY, jsonData);
      await prefs.flush();
      
      console.info('[WidgetDataStorage] ✅ Form IDs saved successfully');
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to save form IDs:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * Load form ID list from Preferences
   * 
   * @param context Application context
   * @returns Array of form IDs or empty array if none exist
   * Requirements: 7.3
   */
  static async loadFormIds(context: common.Context): Promise<string[]> {
    try {
      console.info('[WidgetDataStorage] 📖 Loading form IDs...');
      const prefs = await WidgetDataStorage.ensurePreferences(context);
      
      const jsonData = await prefs.get(FORM_IDS_KEY, '[]') as string;
      
      const formIds = JSON.parse(jsonData) as string[];
      console.info(`[WidgetDataStorage] ✅ Loaded ${formIds.length} form IDs`);
      return formIds;
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to load form IDs:', error);
      return [];
    }
  }


  /**
   * Add a single form ID to storage
   * Prevents duplicate IDs
   * 
   * @param context Application context
   * @param formId Form ID to add
   * Requirements: 7.1
   */
  static async addFormId(context: common.Context, formId: string): Promise<void> {
    try {
      console.info(`[WidgetDataStorage] ➕ Adding form ID: ${formId}`);
      const formIds = await WidgetDataStorage.loadFormIds(context);
      
      // Prevent duplicates
      if (!formIds.includes(formId)) {
        formIds.push(formId);
        await WidgetDataStorage.saveFormIds(context, formIds);
        console.info(`[WidgetDataStorage] ✅ Form ID added, total: ${formIds.length}`);
      } else {
        console.info('[WidgetDataStorage] ⚠️ Form ID already exists, skipping');
      }
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to add form ID:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * Remove a single form ID from storage
   * 
   * @param context Application context
   * @param formId Form ID to remove
   * Requirements: 7.2
   */
  static async removeFormId(context: common.Context, formId: string): Promise<void> {
    try {
      console.info(`[WidgetDataStorage] ➖ Removing form ID: ${formId}`);
      const formIds = await WidgetDataStorage.loadFormIds(context);
      
      const index = formIds.indexOf(formId);
      if (index !== -1) {
        formIds.splice(index, 1);
        await WidgetDataStorage.saveFormIds(context, formIds);
        console.info(`[WidgetDataStorage] ✅ Form ID removed, remaining: ${formIds.length}`);
      } else {
        console.info('[WidgetDataStorage] ⚠️ Form ID not found, nothing to remove');
      }
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to remove form ID:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * Clear all widget data (for testing/reset purposes)
   * 
   * @param context Application context
   */
  static async clearAll(context: common.Context): Promise<void> {
    try {
      console.info('[WidgetDataStorage] 🧹 Clearing all widget data...');
      const prefs = await WidgetDataStorage.ensurePreferences(context);
      
      await prefs.delete(WIDGET_DATA_KEY);
      await prefs.delete(FORM_IDS_KEY);
      await prefs.flush();
      
      console.info('[WidgetDataStorage] ✅ All widget data cleared');
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to clear widget data:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * Check if weather data exists in storage
   * 
   * @param context Application context
   * @returns true if data exists
   */
  static async hasWeatherData(context: common.Context): Promise<boolean> {
    try {
      const prefs = await WidgetDataStorage.ensurePreferences(context);
      const jsonData = await prefs.get(WIDGET_DATA_KEY, '') as string;
      return jsonData.length > 0;
    } catch (error) {
      console.error('[WidgetDataStorage] ❌ Failed to check weather data:', error);
      return false;
    }
  }
}
