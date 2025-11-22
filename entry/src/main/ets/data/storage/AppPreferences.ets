import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';
import { AppConstants } from '../../common/constants/AppConstants';
import { BackgroundMode } from '../../common/constants/ThemeConstants';
import { ThemeMode } from '../../common/theme/ThemeManager';

export class AppPreferences {
  private prefs: preferences.Preferences | null = null;

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.prefs) {
      return;
    }
    this.prefs = await preferences.getPreferences(context, AppConstants.APP_SETTINGS_PREF);
  }

  async setBackgroundMode(mode: BackgroundMode): Promise<void> {
    if (!this.prefs) {
      return;
    }
    await this.prefs.put(AppConstants.BACKGROUND_MODE_KEY, mode);
    await this.prefs.flush();
  }

  async getBackgroundMode(): Promise<BackgroundMode> {
    if (!this.prefs) {
      return BackgroundMode.GRADIENT;
    }
    const value: preferences.ValueType = await this.prefs.get(
      AppConstants.BACKGROUND_MODE_KEY,
      AppConstants.DEFAULT_BACKGROUND_MODE
    );
    return (value as string) as BackgroundMode;
  }

  async setAutoLocationEnabled(enabled: boolean): Promise<void> {
    if (!this.prefs) {
      return;
    }
    await this.prefs.put(AppConstants.AUTO_LOCATION_KEY, enabled);
    await this.prefs.flush();
  }

  async isAutoLocationEnabled(): Promise<boolean> {
    if (!this.prefs) {
      return true;
    }
    const value: preferences.ValueType = await this.prefs.get(AppConstants.AUTO_LOCATION_KEY, true);
    return value as boolean;
  }

  async setThemeMode(mode: ThemeMode): Promise<void> {
    if (!this.prefs) {
      return;
    }
    await this.prefs.put('theme_mode', mode);
    await this.prefs.flush();
  }

  async getThemeMode(): Promise<ThemeMode> {
    if (!this.prefs) {
      return ThemeMode.AUTO;
    }
    const value: preferences.ValueType = await this.prefs.get('theme_mode', ThemeMode.AUTO);
    return value as ThemeMode;
  }

  async setShakeRefreshEnabled(enabled: boolean): Promise<void> {
    if (!this.prefs) {
      return;
    }
    await this.prefs.put('shake_refresh_enabled', enabled);
    await this.prefs.flush();
  }

  async isShakeRefreshEnabled(): Promise<boolean> {
    if (!this.prefs) {
      return true;
    }
    const value: preferences.ValueType = await this.prefs.get('shake_refresh_enabled', true);
    return value as boolean;
  }

  async setNotificationEnabled(enabled: boolean): Promise<void> {
    if (!this.prefs) {
      return;
    }
    await this.prefs.put('notification_enabled', enabled);
    await this.prefs.flush();
  }

  async isNotificationEnabled(): Promise<boolean> {
    if (!this.prefs) {
      return false;
    }
    const value: preferences.ValueType = await this.prefs.get('notification_enabled', false);
    return value as boolean;
  }
}
