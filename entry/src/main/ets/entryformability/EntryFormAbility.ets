/**
 * EntryFormAbility - Weather Widget Form Extension Ability
 * 
 * Manages the lifecycle of weather widgets including:
 * - Widget creation and data initialization
 * - Scheduled and manual data updates
 * - Widget removal and cleanup
 * - Form event handling (refresh button)
 * 
 * Requirements: 3.2, 3.3, 7.1, 7.2, 8.1, 8.2
 */
import formInfo from '@ohos.app.form.formInfo';
import formBindingData from '@ohos.app.form.formBindingData';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formProvider from '@ohos.app.form.formProvider';
import Want from '@ohos.app.ability.Want';
import { WidgetDataStorage, WidgetWeatherData } from '../data/storage/WidgetDataStorage';
import preferences from '@ohos.data.preferences';

/**
 * Form data interface for 2x2 widget
 * 数据格式：普通字符串和布尔值（参考拼图游戏成功实现）
 */
interface FormData2x2 {
  cityName: string;
  temperature: string;
  condition: string;
  iconCode: string;
  themeKey: string;
  updateTime: string;
  isStale: boolean;
}

/**
 * Staleness threshold in milliseconds (30 minutes)
 */
const STALENESS_THRESHOLD_MS: number = 30 * 60 * 1000;

export default class EntryFormAbility extends FormExtensionAbility {
  /**
   * Called when a new widget is added to the home screen
   * Loads weather data from storage and saves the form ID
   * 
   * 🔧 关键修复：使用同步方式读取 Preferences 数据
   * ArkTS 卡片的 @LocalStorageProp 只在 onAddForm 返回时绑定数据
   * 后续的 formProvider.updateForm() 无法更新已渲染的卡片UI
   * 
   * @param want Contains form information including formId and dimension
   * @returns FormBindingData with weather data for the widget
   * Requirements: 3.2, 3.3, 7.1
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info('[EntryFormAbility] 📱 onAddForm called');

    // Extract form information from want
    const formIdRaw = want.parameters?.['ohos.extra.param.key.form_identity'];
    const formId: string = formIdRaw !== undefined ? String(formIdRaw) : '';
    const dimensionRaw = want.parameters?.['ohos.extra.param.key.form_dimension'];
    const dimension: string = dimensionRaw !== undefined ? String(dimensionRaw) : '';
    const formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;

    console.info(`[EntryFormAbility] Form ID: ${formId} (raw type: ${typeof formIdRaw}), Dimension: ${dimension} (raw: ${dimensionRaw}), Name: ${formName}`);
    
    // Save form ID asynchronously (don't block widget creation)
    if (formId) {
      this.saveFormIdAsync(formId);
    }
    
    // 🔧 关键修复：同步读取 Preferences 数据
    // 使用 getPreferencesSync 同步获取数据，确保 onAddForm 返回时就包含真实数据
    let weatherData: WidgetWeatherData | null = null;
    try {
      const prefs = preferences.getPreferencesSync(this.context, { name: 'aurora_weather_widget' });
      const jsonData = prefs.getSync('widget_weather_data', '') as string;
      console.info(`[EntryFormAbility] 📖 Sync loaded JSON data length: ${jsonData.length}`);
      
      if (jsonData && jsonData.length > 0) {
        weatherData = this.parseWeatherDataSync(jsonData);
        if (weatherData) {
          console.info(`[EntryFormAbility] ✅ Sync loaded weather data for city: ${weatherData.cityName}`);
          console.info(`[EntryFormAbility] 📊 Data: temp=${weatherData.temperature}, humidity=${weatherData.humidity}, windSpeed=${weatherData.windSpeed}`);
        }
      } else {
        console.info('[EntryFormAbility] ⚠️ No weather data in Preferences');
      }
    } catch (error) {
      console.error('[EntryFormAbility] ❌ Failed to sync load weather data:', error);
    }
    
    // Build form data with real data (or defaults if no data available)
    const formData = this.buildFormData(weatherData, dimension);
    
    if (weatherData) {
      console.info(`[EntryFormAbility] 📤 Returning form data with real weather: ${weatherData.cityName}, ${weatherData.temperature}°`);
    } else {
      console.info(`[EntryFormAbility] 📤 Returning default form data (no cached data)`);
    }
    
    return formData;
  }
  
  /**
   * 同步解析天气数据 JSON
   */
  private parseWeatherDataSync(jsonData: string): WidgetWeatherData | null {
    try {
      if (!jsonData || jsonData.trim().length === 0) {
        return null;
      }
      
      const parsed: WidgetWeatherData = JSON.parse(jsonData) as WidgetWeatherData;
      
      // Validate required fields
      if (!parsed.cityName || !parsed.condition || !parsed.iconCode || !parsed.themeKey) {
        console.warn('[EntryFormAbility] ⚠️ Weather data validation failed - missing required fields');
        return null;
      }
      
      if (typeof parsed.temperature !== 'number' || typeof parsed.timestamp !== 'number') {
        console.warn('[EntryFormAbility] ⚠️ Weather data validation failed - invalid number fields');
        return null;
      }
      
      // Ensure defaults
      if (!parsed.hourlyForecast) {
        parsed.hourlyForecast = [];
      }
      if (parsed.humidity === undefined || parsed.humidity === null) {
        parsed.humidity = 0;
      }
      if (parsed.windSpeed === undefined || parsed.windSpeed === null) {
        parsed.windSpeed = 0;
      }
      
      return parsed;
    } catch (error) {
      console.error('[EntryFormAbility] ❌ JSON parse error:', error);
      return null;
    }
  }

  /**
   * Called when the system triggers a scheduled update
   * Refreshes the widget with the latest cached weather data
   * 
   * @param formId The ID of the form to update
   * Requirements: 3.2
   */
  onUpdateForm(formId: string): void {
    console.info(`[EntryFormAbility] 🔄 onUpdateForm called for formId: ${formId}`);
    
    // 🔧 使用同步方式读取数据并更新
    this.updateFormSync(formId);
  }
  
  /**
   * 同步更新卡片数据
   */
  private updateFormSync(formId: string): void {
    try {
      console.info(`[EntryFormAbility] 📖 Sync loading weather data for form: ${formId}`);
      
      const prefs = preferences.getPreferencesSync(this.context, { name: 'aurora_weather_widget' });
      const jsonData = prefs.getSync('widget_weather_data', '') as string;
      
      let weatherData: WidgetWeatherData | null = null;
      if (jsonData && jsonData.length > 0) {
        weatherData = this.parseWeatherDataSync(jsonData);
      }
      
      if (weatherData) {
        console.info(`[EntryFormAbility] ✅ Loaded data for city: ${weatherData.cityName}, temp: ${weatherData.temperature}`);
      } else {
        console.info('[EntryFormAbility] ⚠️ No weather data available');
      }
      
      // Build form data (2x2 only)
      const formData = this.buildFormData(weatherData, '2*2');
      
      // Update form asynchronously
      formProvider.updateForm(formId, formData).then(() => {
        console.info(`[EntryFormAbility] ✅ Form ${formId} updated successfully`);
      }).catch((error: Error) => {
        console.error(`[EntryFormAbility] ❌ Failed to update form ${formId}:`, error);
      });
    } catch (error) {
      console.error('[EntryFormAbility] ❌ Failed to sync update form:', error);
    }
  }

  /**
   * Called when a widget is removed from the home screen
   * Cleans up the form ID from storage
   * 
   * @param formId The ID of the removed form
   * Requirements: 7.2
   */
  onRemoveForm(formId: string): void {
    console.info(`[EntryFormAbility] 🗑️ onRemoveForm called for formId: ${formId}`);
    
    // Remove form ID from storage asynchronously
    this.removeFormIdAsync(formId);
  }

  /**
   * Called when a form event is received (e.g., refresh button click)
   * Handles the refresh action by reloading weather data
   * 
   * @param formId The ID of the form that triggered the event
   * @param message The event message
   * Requirements: 4.2
   */
  onFormEvent(formId: string, message: string): void {
    console.info(`[EntryFormAbility] 📨 onFormEvent: formId=${formId}, message=${message}`);
    
    // Handle refresh button click
    if (message === 'refresh' || message.includes('refresh')) {
      console.info('[EntryFormAbility] 🔄 Refresh requested, reloading data...');
      this.updateFormSync(formId);
    }
  }

  /**
   * Called when the form provider is notified that a temporary form
   * is successfully converted to a normal form
   * 
   * @param formId The ID of the converted form
   */
  onCastToNormalForm(formId: string): void {
    console.info(`[EntryFormAbility] onCastToNormalForm: ${formId}`);
  }

  /**
   * Called when form visibility changes
   * 
   * @param newStatus Map of form IDs to visibility status
   */
  onChangeFormVisibility(newStatus: Record<string, number>): void {
    console.info('[EntryFormAbility] onChangeFormVisibility');
  }

  /**
   * Called to return the form state
   * 
   * @param want Contains form information
   * @returns FormState indicating the form is ready
   */
  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  /**
   * Build FormBindingData for widget
   * Constructs the data structure for 2×2 widget dimension
   * 
   * @param data Weather data or null for default values
   * @param dimension Widget dimension (currently only "2*2" is supported)
   * @returns FormBindingData ready for widget display
   * Requirements: 2.1, 8.1, 8.2
   */
  private buildFormData(data: WidgetWeatherData | null, dimension: string): formBindingData.FormBindingData {
    console.info(`[EntryFormAbility] 🏗️ Building form data for dimension: ${dimension}`);
    
    // Debug: Log received data
    if (data) {
      console.info(`[EntryFormAbility] 📊 Data received - city: ${data.cityName}, temp: ${data.temperature}, humidity: ${data.humidity}, windSpeed: ${data.windSpeed}`);
      console.info(`[EntryFormAbility] 📊 Hourly forecast count: ${data.hourlyForecast?.length ?? 0}`);
    } else {
      console.info('[EntryFormAbility] ⚠️ No data received, using defaults');
    }
    
    // Check if data is stale (older than 30 minutes)
    const isStale = data ? this.isDataStale(data.timestamp) : true;
    
    // Build form data (2x2 only) - 使用普通字符串格式（参考拼图游戏成功实现）
    const formData2x2: FormData2x2 = {
      cityName: data?.cityName ?? '点击刷新',
      temperature: data !== null && data.temperature !== undefined ? `${data.temperature}°` : '--°',
      condition: data?.condition ?? '数据加载中',
      iconCode: data?.iconCode ?? 'sun',
      themeKey: data?.themeKey ?? 'sunny',
      updateTime: data?.updateTime ?? '--:-- 更新',
      isStale: isStale
    };
    
    // Return 2x2 data
    console.info(`[EntryFormAbility] ✅ Built 2x2 form data for city: ${formData2x2.cityName}`);
    console.info(`[EntryFormAbility] 📋 Full 2x2 form data: temperature=${formData2x2.temperature}, condition=${formData2x2.condition}`);
    
    const bindingData = formBindingData.createFormBindingData(formData2x2);
    console.info(`[EntryFormAbility] 📦 FormBindingData created for 2x2`);
    return bindingData;
  }

  /**
   * Check if weather data is stale (older than 30 minutes)
   * 
   * @param timestamp Data timestamp in milliseconds
   * @returns true if data is stale
   * Requirements: 3.4
   */
  private isDataStale(timestamp: number): boolean {
    if (!timestamp || timestamp <= 0) {
      return true;
    }
    
    const now = Date.now();
    const age = now - timestamp;
    
    return age > STALENESS_THRESHOLD_MS;
  }

  /**
   * Save form ID to storage asynchronously
   * 
   * @param formId Form ID to save
   * Requirements: 7.1
   */
  private async saveFormIdAsync(formId: string): Promise<void> {
    try {
      console.info(`[EntryFormAbility] 💾 Saving form ID: ${formId}`);
      await WidgetDataStorage.addFormId(this.context, formId);
      console.info('[EntryFormAbility] ✅ Form ID saved successfully');
    } catch (error) {
      console.error('[EntryFormAbility] ❌ Failed to save form ID:', error);
    }
  }

  /**
   * Remove form ID from storage asynchronously
   * 
   * @param formId Form ID to remove
   * Requirements: 7.2
   */
  private async removeFormIdAsync(formId: string): Promise<void> {
    try {
      console.info(`[EntryFormAbility] 🗑️ Removing form ID: ${formId}`);
      await WidgetDataStorage.removeFormId(this.context, formId);
      console.info('[EntryFormAbility] ✅ Form ID removed successfully');
    } catch (error) {
      console.error('[EntryFormAbility] ❌ Failed to remove form ID:', error);
    }
  }

  /**
   * Load weather data and update form asynchronously
   * Called during onAddForm to update widget after initial display
   * 
   * @param formId Form ID to update
   * @param dimension Widget dimension (can be string or number)
   */
  private async loadAndUpdateFormAsync(formId: string | undefined, dimension: string): Promise<void> {
    if (!formId) {
      console.warn('[EntryFormAbility] ⚠️ No form ID provided, skipping update');
      return;
    }
    
    try {
      console.info(`[EntryFormAbility] 📖 Loading weather data for form: ${formId}`);
      
      // Load weather data from storage
      const weatherData = await WidgetDataStorage.loadForWidget(this.context);
      
      if (weatherData) {
        console.info(`[EntryFormAbility] ✅ Weather data loaded for city: ${weatherData.cityName}`);
        console.info(`[EntryFormAbility] 📊 Data details - temp: ${weatherData.temperature}, humidity: ${weatherData.humidity}, windSpeed: ${weatherData.windSpeed}`);
        console.info(`[EntryFormAbility] 📊 Hourly count: ${weatherData.hourlyForecast?.length ?? 0}`);
        
        // Build and update form with real data
        const formData = this.buildFormData(weatherData, dimension);
        
        // 🔧 添加重试机制，确保更新成功
        let retryCount = 0;
        const maxRetries = 3;
        let updateSuccess = false;
        
        while (retryCount < maxRetries && !updateSuccess) {
          try {
            await formProvider.updateForm(formId, formData);
            updateSuccess = true;
            console.info(`[EntryFormAbility] ✅ Form ${formId} updated with weather data (attempt ${retryCount + 1})`);
          } catch (updateError) {
            retryCount++;
            console.warn(`[EntryFormAbility] ⚠️ Update attempt ${retryCount} failed:`, updateError);
            if (retryCount < maxRetries) {
              // 等待 200ms 后重试
              await new Promise<void>((resolve) => setTimeout(resolve, 200));
            }
          }
        }
        
        if (!updateSuccess) {
          console.error(`[EntryFormAbility] ❌ Failed to update form after ${maxRetries} attempts`);
        }
      } else {
        console.info('[EntryFormAbility] ⚠️ No weather data available, keeping default display');
      }
    } catch (error) {
      console.error('[EntryFormAbility] ❌ Failed to load and update form:', error);
      // Keep default display on error - Requirements: 8.1, 8.2
    }
  }

  /**
   * Load weather data and update form by ID asynchronously
   * Used for scheduled updates and refresh events
   * 
   * @param formId Form ID to update
   */
  private async loadAndUpdateFormByIdAsync(formId: string): Promise<void> {
    try {
      console.info(`[EntryFormAbility] 📖 Loading weather data for scheduled update: ${formId}`);
      
      // Load weather data from storage
      const weatherData = await WidgetDataStorage.loadForWidget(this.context);
      
      if (weatherData) {
        console.info(`[EntryFormAbility] 📊 Loaded data - city: ${weatherData.cityName}, temp: ${weatherData.temperature}`);
        console.info(`[EntryFormAbility] 📊 Extended - humidity: ${weatherData.humidity}%, windSpeed: ${weatherData.windSpeed} km/h`);
        console.info(`[EntryFormAbility] 📊 Hourly forecast count: ${weatherData.hourlyForecast?.length ?? 0}`);
      } else {
        console.warn('[EntryFormAbility] ⚠️ No weather data in storage');
      }
      
      // Build 2x2 form data
      const formData = this.buildFormData(weatherData, '2*2');
      
      await formProvider.updateForm(formId, formData);
      console.info('[EntryFormAbility] ✅ Form updated successfully');
    } catch (error) {
      console.error('[EntryFormAbility] ❌ Failed to update form:', error);
      
      // On error, try to update with fallback data
      // Requirements: 8.1, 8.2
      try {
        const fallbackData = this.buildFormData(null, '2*2');
        await formProvider.updateForm(formId, fallbackData);
        console.info('[EntryFormAbility] ⚠️ Form updated with fallback data');
      } catch (fallbackError) {
        console.error('[EntryFormAbility] ❌ Failed to update form with fallback:', fallbackError);
      }
    }
  }
}
