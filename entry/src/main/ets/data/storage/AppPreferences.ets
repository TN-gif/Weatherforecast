import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';
import { AppConstants } from '../../common/constants/AppConstants';
import { BackgroundMode } from '../../common/constants/ThemeConstants';
import { ThemeMode } from '../../common/theme/ThemeManager';

export class AppPreferences {
  private prefs: preferences.Preferences | null = null;

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.prefs) {
      console.debug('[AppPreferences] ⚠️ 偏好设置已初始化，跳过');
      return;
    }
    console.info('[AppPreferences] ⚙️ 初始化偏好设置...');
    this.prefs = await preferences.getPreferences(context, AppConstants.APP_SETTINGS_PREF);
    console.info('[AppPreferences] ✅ 偏好设置初始化成功');
  }

  async setBackgroundMode(mode: BackgroundMode): Promise<void> {
    if (!this.prefs) return;
    console.info(`[AppPreferences] 💾 保存背景模式: ${mode}`);
    await this.prefs.put(AppConstants.BACKGROUND_MODE_KEY, mode);
    await this.prefs.flush();
  }

  async getBackgroundMode(): Promise<BackgroundMode> {
    if (!this.prefs) return BackgroundMode.GRADIENT;
    const value: preferences.ValueType = await this.prefs.get(
      AppConstants.BACKGROUND_MODE_KEY,
      AppConstants.DEFAULT_BACKGROUND_MODE
    );
    console.debug(`[AppPreferences] 📖 读取背景模式: ${value}`);
    return (value as string) as BackgroundMode;
  }

  async setAutoLocationEnabled(enabled: boolean): Promise<void> {
    if (!this.prefs) return;
    console.info(`[AppPreferences] 💾 保存自动定位设置: ${enabled}`);
    await this.prefs.put(AppConstants.AUTO_LOCATION_KEY, enabled);
    await this.prefs.flush();
  }

  async isAutoLocationEnabled(): Promise<boolean> {
    if (!this.prefs) return true;
    const value: preferences.ValueType = await this.prefs.get(AppConstants.AUTO_LOCATION_KEY, true);
    console.debug(`[AppPreferences] 📖 读取自动定位设置: ${value}`);
    return value as boolean;
  }

  async setThemeMode(mode: ThemeMode): Promise<void> {
    if (!this.prefs) return;
    console.info(`[AppPreferences] 💾 保存主题模式: ${mode}`);
    await this.prefs.put('theme_mode', mode);
    await this.prefs.flush();
  }

  async getThemeMode(): Promise<ThemeMode> {
    if (!this.prefs) return ThemeMode.AUTO;
    const value: preferences.ValueType = await this.prefs.get('theme_mode', ThemeMode.AUTO);
    console.debug(`[AppPreferences] 📖 读取主题模式: ${value}`);
    return value as ThemeMode;
  }

  async setShakeRefreshEnabled(enabled: boolean): Promise<void> {
    if (!this.prefs) return;
    console.info(`[AppPreferences] 💾 保存摇一摇设置: ${enabled}`);
    await this.prefs.put('shake_refresh_enabled', enabled);
    await this.prefs.flush();
  }

  async isShakeRefreshEnabled(): Promise<boolean> {
    if (!this.prefs) return true;
    const value: preferences.ValueType = await this.prefs.get('shake_refresh_enabled', true);
    console.debug(`[AppPreferences] 📖 读取摇一摇设置: ${value}`);
    return value as boolean;
  }

  async setNotificationEnabled(enabled: boolean): Promise<void> {
    if (!this.prefs) return;
    console.info(`[AppPreferences] 💾 保存通知设置: ${enabled}`);
    await this.prefs.put('notification_enabled', enabled);
    await this.prefs.flush();
  }

  async isNotificationEnabled(): Promise<boolean> {
    if (!this.prefs) return false;
    const value: preferences.ValueType = await this.prefs.get('notification_enabled', false);
    console.debug(`[AppPreferences] 📖 读取通知设置: ${value}`);
    return value as boolean;
  }
}
