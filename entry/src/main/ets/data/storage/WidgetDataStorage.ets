import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';

/**
 * Widget 天气数据接口，用于跨进程共享
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
 * 小时预报项，用于 Widget 显示
 */
export interface WidgetHourlyItem {
  time: string;
  temperature: number;
  iconCode: string;
}

/**
 * Widget 数据存储常量
 */
const WIDGET_PREF_NAME: string = 'aurora_weather_widget';
const WIDGET_DATA_KEY: string = 'widget_weather_data';
const FORM_IDS_KEY: string = 'widget_form_ids';

/**
 * WidgetDataStorage - 天气 Widget 数据存储类
 *
 * 本类提供天气数据的持久化存储功能。
 * 注意：主应用和卡片进程使用独立的 Preferences 存储
 * - 主应用保存天气数据到 Preferences
 * - 卡片进程从 Preferences 读取天气数据
 * - form IDs 由卡片进程管理（主应用无法访问）
 *
 * Requirements: 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3
 */
export class WidgetDataStorage {
  private static prefs: preferences.Preferences | null = null;

  /**
   * 使用应用上下文初始化 Preferences
   */
  private static async ensurePreferences(context: common.Context): Promise<preferences.Preferences> {
    // 每次都重新获取 Preferences，确保数据最新
    console.info('[WidgetDataStorage] ⚙️ Initializing widget preferences...');
    const prefs = await preferences.getPreferences(context, WIDGET_PREF_NAME);
    console.info('[WidgetDataStorage] ✅ Widget preferences initialized');
    return prefs;
  }


  /**
   * 保存天气数据到 Preferences 供 Widget 访问
   * 同时将数据持久化到 AppStorage 和 Preferences
   * 
   * @param context 用于访问 Preferences 的应用上下文
   * @param data 要保存的天气数据
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
   * 从 Preferences 加载天气数据
   * 如果数据不存在或解析失败则返回 null
   * 
   * @param context 用于访问 Preferences 的应用上下文
   * @returns 天气数据，如果不可用则返回 null
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
   * 解析 JSON 字符串为 WidgetWeatherData 并进行验证
   * 对于无效或格式错误的 JSON 返回 null，不抛出异常
   * 
   * @param jsonData 要解析的 JSON 字符串
   * @returns 解析后的数据，如果无效则返回 null
   * Requirements: 6.3
   */
  static parseWeatherData(jsonData: string): WidgetWeatherData | null {
    try {
      if (!jsonData || jsonData.trim().length === 0) {
        console.warn('[WidgetDataStorage] ⚠️ Empty JSON data');
        return null;
      }
      
      // 解析 JSON 并直接转换为 WidgetWeatherData
      // ArkTS 将在运行时验证结构
      const parsed: WidgetWeatherData = JSON.parse(jsonData) as WidgetWeatherData;
      
      // 调试：记录解析后的数据
      console.info(`[WidgetDataStorage] 📊 Parsed data - city: ${parsed.cityName}, temp: ${parsed.temperature}, humidity: ${parsed.humidity}, windSpeed: ${parsed.windSpeed}`);
      console.info(`[WidgetDataStorage] 📊 Hourly forecast count: ${parsed.hourlyForecast?.length ?? 0}`);
      
      // 验证必需字段是否存在
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
      
      // 确保 hourlyForecast 是数组
      if (!parsed.hourlyForecast) {
        console.info('[WidgetDataStorage] ⚠️ No hourly forecast, initializing empty array');
        parsed.hourlyForecast = [];
      }
      
      // 确保 humidity 和 windSpeed 有默认值（如果未定义）
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
   * 保存表单 ID 列表到 Preferences
   * 
   * @param context 应用上下文
   * @param formIds 要保存的表单 ID 数组
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
   * 从 Preferences 加载表单 ID 列表
   * 
   * @param context 应用上下文
   * @returns 表单 ID 数组，如果不存在则返回空数组
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
   * 添加单个表单 ID 到存储
   * 防止重复 ID
   * 
   * @param context 应用上下文
   * @param formId 要添加的表单 ID
   * Requirements: 7.1
   */
  static async addFormId(context: common.Context, formId: string): Promise<void> {
    try {
      console.info(`[WidgetDataStorage] ➕ Adding form ID: ${formId}`);
      const formIds = await WidgetDataStorage.loadFormIds(context);
      
      // 防止重复
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
   * 从存储中移除单个表单 ID
   * 
   * @param context 应用上下文
   * @param formId 要移除的表单 ID
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
   * 清除所有 Widget 数据（用于测试/重置）
   * 
   * @param context 应用上下文
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
   * 检查存储中是否存在天气数据
   * 
   * @param context 应用上下文
   * @returns 如果数据存在则返回 true
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
