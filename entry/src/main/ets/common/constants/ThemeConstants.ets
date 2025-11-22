export enum BackgroundMode {
  VIDEO = 'video',
  ANIMATED_IMAGE = 'webp',
  GRADIENT = 'gradient'
}

export interface VideoThemeAsset {
  themeKey: string;
  videoResource?: string;
  animatedImageResource?: string;
  gradientColors: string[];
  accentColor?: string;
  mode: BackgroundMode;
  lottieResource?: string;
  isNightMode?: boolean;
}

export class ThemeConstants {
  static readonly THEMES: VideoThemeAsset[] = [
    {
      themeKey: 'sunny',
      videoResource: 'rawfile/weather/sunny_day.mp4',
      animatedImageResource: 'rawfile/weather/sunny.webp',
      gradientColors: ['#87CEEB', '#4A90E2'],
      accentColor: 'rgba(255, 223, 0, 0.4)',
      mode: BackgroundMode.VIDEO,
      lottieResource: 'rawfile/lottie/sun.json',
      isNightMode: false
    },
    {
      themeKey: 'rainy',
      videoResource: 'rawfile/weather/rainy_day.mp4',
      animatedImageResource: 'rawfile/weather/rainy.webp',
      gradientColors: ['#4A5A6A', '#2C3E50'],
      accentColor: 'rgba(173, 216, 230, 0.4)',
      mode: BackgroundMode.VIDEO,
      lottieResource: 'rawfile/lottie/rain.json',
      isNightMode: false
    },
    {
      themeKey: 'snow',
      videoResource: 'rawfile/weather/snow_day.mp4',
      animatedImageResource: 'rawfile/weather/snow.webp',
      gradientColors: ['#E6F3FF', '#B3D9FF'],
      accentColor: 'rgba(255, 255, 255, 0.5)',
      mode: BackgroundMode.VIDEO,
      lottieResource: 'rawfile/lottie/snow.json',
      isNightMode: false
    },
    {
      themeKey: 'night',
      videoResource: 'rawfile/weather/night.mp4',
      animatedImageResource: 'rawfile/weather/night.webp',
      gradientColors: ['#1A1A2E', '#16213E'],
      accentColor: 'rgba(100, 149, 237, 0.3)',
      mode: BackgroundMode.VIDEO,
      lottieResource: 'rawfile/lottie/moon.json',
      isNightMode: true
    },
    // 夜间版本
    {
      themeKey: 'sunny_night',
      videoResource: 'rawfile/weather/sunny_night.mp4',
      animatedImageResource: 'rawfile/weather/sunny.webp',
      gradientColors: ['#2C3E50', '#3498DB'],
      accentColor: 'rgba(255, 223, 0, 0.3)',
      mode: BackgroundMode.VIDEO,
      lottieResource: 'rawfile/lottie/moon.json',
      isNightMode: true
    },
    {
      themeKey: 'rainy_night',
      videoResource: 'rawfile/weather/rainy_night.mp4',
      animatedImageResource: 'rawfile/weather/rainy.webp',
      gradientColors: ['#2C3E50', '#34495E'],
      accentColor: 'rgba(173, 216, 230, 0.3)',
      mode: BackgroundMode.VIDEO,
      lottieResource: 'rawfile/lottie/rain.json',
      isNightMode: true
    },
    {
      themeKey: 'snow_night',
      videoResource: 'rawfile/weather/snow_night.mp4',
      animatedImageResource: 'rawfile/weather/snow.webp',
      gradientColors: ['#2C3E50', '#5D6D7E'],
      accentColor: 'rgba(255, 255, 255, 0.4)',
      mode: BackgroundMode.VIDEO,
      lottieResource: 'rawfile/lottie/snow.json',
      isNightMode: true
    }
  ];

  static getTheme(key: string): VideoThemeAsset {
    const found: VideoThemeAsset | undefined = ThemeConstants.THEMES.find((item: VideoThemeAsset) => item.themeKey === key);
    if (found !== undefined) {
      return found;
    }
    return ThemeConstants.THEMES[0];
  }

  /**
   * 根据天气条件和时间自动选择主题
   */
  static getThemeWithTimeAware(weatherKey: string, isNight: boolean = false): VideoThemeAsset {
    let targetKey = weatherKey;
    
    // 如果是夜间且不是专门的夜间主题，尝试找夜间版本
    if (isNight && !weatherKey.includes('night')) {
      const nightKey = `${weatherKey}_night`;
      const nightTheme = ThemeConstants.THEMES.find(theme => theme.themeKey === nightKey);
      if (nightTheme) {
        targetKey = nightKey;
      } else {
        // 如果没有对应的夜间版本，使用通用夜间主题
        targetKey = 'night';
      }
    }
    
    return ThemeConstants.getTheme(targetKey);
  }

  /**
   * 获取所有可用的主题键
   */
  static getAllThemeKeys(): string[] {
    return ThemeConstants.THEMES.map(theme => theme.themeKey);
  }

  /**
   * 检查主题是否为夜间模式
   */
  static isNightTheme(themeKey: string): boolean {
    const theme = ThemeConstants.getTheme(themeKey);
    return theme.isNightMode === true;
  }
}
