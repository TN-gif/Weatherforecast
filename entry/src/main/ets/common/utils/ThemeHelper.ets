import { ThemeConstants, VideoThemeAsset } from '../constants/ThemeConstants';
import { WeatherCondition } from '../../data/models/WeatherModels';

export class ThemeHelper {
  static resolveTheme(condition: WeatherCondition): VideoThemeAsset {
    return ThemeConstants.getTheme(condition.themeKey);
  }

  static resolveThemeByKey(themeKey: string): VideoThemeAsset {
    return ThemeConstants.getTheme(themeKey);
  }
}
