// DesignSystem.ets - Weather App 设计系统"宪法"
// 所有颜色、间距、字体必须引用这里，严禁写死数字

// 类型定义
type ResourceColor = string;
interface SpacingDef {
  XS: number;
  S: number;
  M: number;
  L: number;
  XL: number;
  XXL: number;
  XXXL: number;
}

interface ColorsDef {
  WHITE: string;
  WHITE_90: string;
  WHITE_70: string;
  WHITE_50: string;
  WHITE_30: string;
  WHITE_10: string;
  BLACK: string;
  BLACK_90: string;
  BLACK_50: string;
  GLASS_BG: string;
  GLASS_BORDER: string;
  TEXT_PRIMARY: string;
  TEXT_SECONDARY: string;
  TEXT_TERTIARY: string;
  CARD_OVERLAY: string;
  ERROR: string;
  SUCCESS: string;
  WARNING: string;
}

interface FontWeightDef {
  THIN: number;
  LIGHT: number;
  REGULAR: number;
  MEDIUM: number;
  SEMIBOLD: number;
  BOLD: number;
}

interface AnimationPreset {
  duration: number;
  curve: Curve;
}

interface AnimationDef {
  FAST: AnimationPreset;
  MEDIUM: AnimationPreset;
  SLOW: AnimationPreset;
}

interface ShadowDef {
  radius: number;
  color: string;
  offsetY: number;
  offsetX: number;
}

interface GradientDef {
  angle: number;
  colors: [ResourceColor, number][];
}

interface PathIconsDef {
  LOCATION: string;
  MENU: string;
  REFRESH: string;
  PLUS: string;
  BACK: string;
  SUN: string;
  CLOUD: string;
  RAIN: string;
}

interface ResourceIconsDef {
  LOCATION: Resource;
  SUN: Resource;
  CLOUDY: Resource;
  RAIN: Resource;
  WIND: Resource;
  DROP: Resource;
  MENU: Resource;
  ADD: Resource;
  BACK: Resource;
  REFRESH: Resource;
  CLOSE: Resource;
  MORE: Resource;
  CHECK: Resource;
  SEARCH: Resource;
  EDIT: Resource;
  REORDER: Resource;
  LOCATION_PIN: Resource;
  MOON: Resource;
  CLOUD_MOON: Resource;
  STORM: Resource;
  SNOW: Resource;
  FOG: Resource;
  HAZE: Resource;
  DRIZZLE: Resource;
  OVERCAST: Resource;
  AQI: Resource;
  HUMIDITY: Resource;
}

export class DesignSystem {
  // ========== 1. 栅格间距 (Spacing) - 严格遵循 4/8/16/24/32 规律 ==========
  static readonly SPACING_XS = 4;
  static readonly SPACING_S = 8;
  static readonly SPACING_M = 16;  // 核心内边距
  static readonly SPACING_L = 24;  // 模块间距/顶部间距
  static readonly SPACING_XL = 32; // 大标题间距

  static readonly Spacing: SpacingDef = {
    XS: DesignSystem.SPACING_XS,
    S: DesignSystem.SPACING_S,
    M: DesignSystem.SPACING_M,
    L: DesignSystem.SPACING_L,
    XL: DesignSystem.SPACING_XL,
    XXL: 48,
    XXXL: 64
  };

  // ========== 2. 核心颜色 (Colors) ==========
  // ===== 夜间模式颜色（默认） =====
  // 毛玻璃卡片背景：白色 28% 透明度
  static readonly COLOR_GLASS_BG = 'rgba(255, 255, 255, 0.28)';
  // 毛玻璃边框：白色 20% 透明度
  static readonly COLOR_GLASS_BORDER = 'rgba(255, 255, 255, 0.20)';
  // 文本颜色层级（夜间 - 白色系）
  static readonly COLOR_TEXT_PRIMARY = '#FFFFFF';
  static readonly COLOR_TEXT_SECONDARY = 'rgba(255, 255, 255, 0.75)';
  static readonly COLOR_TEXT_TERTIARY = 'rgba(255, 255, 255, 0.55)';
  
  // ===== 白天模式颜色 =====
  // 毛玻璃卡片背景：深色半透明（白天背景亮，用深色卡片衬托白字）
  static readonly COLOR_GLASS_BG_DAY = 'rgba(0, 0, 0, 0.25)';
  // 毛玻璃边框：白色 15% 透明度
  static readonly COLOR_GLASS_BORDER_DAY = 'rgba(255, 255, 255, 0.15)';
  // 文本颜色层级（白天 - 依然使用白色系，简约大气）
  static readonly COLOR_TEXT_PRIMARY_DAY = '#FFFFFF';
  static readonly COLOR_TEXT_SECONDARY_DAY = 'rgba(255, 255, 255, 0.80)';
  static readonly COLOR_TEXT_TERTIARY_DAY = 'rgba(255, 255, 255, 0.60)';
  
  static readonly COLOR_ERROR = '#FF453A';
  static readonly COLOR_SUCCESS = '#32D74B';
  static readonly COLOR_WARNING = '#FFD60A';

  // ========== 3. 遮罩策略 (Overlays) - 解决"看不清字"和"黑条"问题 ==========
  // (1) 全屏柔和遮罩 - 使用平滑多段渐变，彻底消除35%位置的硬边界
  static readonly GRADIENT_OVERLAY_FULL: GradientDef = {
    angle: 180,
    colors: [
      ['rgba(0, 0, 0, 0.40)', 0.0],   // 顶部压暗40%，确保状态栏可读
      ['rgba(0, 0, 0, 0.25)', 0.15],  // 15%位置过渡到25%
      ['rgba(0, 0, 0, 0.12)', 0.35],  // 35%位置过渡到12%（关键：消除硬边界）
      ['rgba(0, 0, 0, 0.05)', 0.55],  // 55%位置过渡到5%
      ['rgba(0, 0, 0, 0.00)', 0.75]   // 75%位置完全透明
    ]
  };
  
  // (2) Header专属局部遮罩 - 仅用于需要额外加深的区域
  static readonly GRADIENT_OVERLAY_HEADER: GradientDef = {
    angle: 180,
    colors: [
      ['rgba(0, 0, 0, 0.15)', 0.0],  // 顶部轻微加深
      ['rgba(0, 0, 0, 0.00)', 1.0]   // 底部透明
    ]
  };
  
  // (3) 卡片内部对比度增强遮罩 - 解决"光线穿透文字"
  static readonly GRADIENT_CARD_INTERNAL: GradientDef = {
    angle: 180,
    colors: [
      ['rgba(255, 255, 255, 0.12)', 0.0],  // 上方微亮，模拟高光
      ['rgba(255, 255, 255, 0.00)', 0.3],  // 中间透明
      ['rgba(0, 0, 0, 0.12)', 1.0]         // 底部微暗，增加稳重感
    ]
  };
  
  // 保留旧的GRADIENT_HEADER供兼容（已废弃，请使用上面的新遮罩）
  static readonly GRADIENT_HEADER: GradientDef = DesignSystem.GRADIENT_OVERLAY_HEADER;
  
  // 卡片局部遮罩：卡片底部的浅黑色，增强对比
  static readonly COLOR_CARD_OVERLAY = 'rgba(0, 0, 0, 0.10)';

  static readonly Colors: ColorsDef = {
    WHITE: '#FFFFFF',
    WHITE_90: 'rgba(255, 255, 255, 0.9)',
    WHITE_70: DesignSystem.COLOR_TEXT_SECONDARY,
    WHITE_50: DesignSystem.COLOR_TEXT_TERTIARY,
    WHITE_30: 'rgba(255, 255, 255, 0.3)',
    WHITE_10: 'rgba(255, 255, 255, 0.1)',
    BLACK: '#000000',
    BLACK_90: 'rgba(0, 0, 0, 0.9)',
    BLACK_50: 'rgba(0, 0, 0, 0.5)',
    GLASS_BG: DesignSystem.COLOR_GLASS_BG,
    GLASS_BORDER: DesignSystem.COLOR_GLASS_BORDER,
    TEXT_PRIMARY: DesignSystem.COLOR_TEXT_PRIMARY,
    TEXT_SECONDARY: DesignSystem.COLOR_TEXT_SECONDARY,
    TEXT_TERTIARY: DesignSystem.COLOR_TEXT_TERTIARY,
    CARD_OVERLAY: DesignSystem.COLOR_CARD_OVERLAY,
    ERROR: DesignSystem.COLOR_ERROR,
    SUCCESS: DesignSystem.COLOR_SUCCESS,
    WARNING: DesignSystem.COLOR_WARNING
  };

  // ========== 4. 模糊与阴影 (Blur & Shadow) ==========
  static readonly BLUR_RADIUS = 45; // 增加模糊度到45，提升毛玻璃效果和可读性
  static readonly CORNER_RADIUS_L = 24; // 卡片大圆角
  static readonly CORNER_RADIUS_M = 16; // 中圆角
  static readonly CORNER_RADIUS_S = 12; // 内部小圆角
  
  // 极轻柔的阴影，只为了让卡片浮起来一点点
  static readonly SHADOW_SOFT: ShadowDef = {
    radius: 16,
    color: 'rgba(0, 0, 0, 0.08)', // 更淡的阴影
    offsetY: 4,
    offsetX: 0
  };
  
  static readonly SHADOW_LIGHT: ShadowDef = {
    radius: 8,
    color: 'rgba(0, 0, 0, 0.05)',
    offsetY: 2,
    offsetX: 0
  };

  // ========== 5. 字体 (Typography) ==========
  static readonly FONT_FAMILY_PRIMARY = 'HarmonyOS Sans';
  static readonly FONT_FAMILY_FALLBACK = 'sans-serif';
  
  // 字体尺寸层级
  static readonly FONT_SIZE_DESC = 12;      // 描述/标签
  static readonly FONT_SIZE_BODY = 14;      // 正文
  static readonly FONT_SIZE_SUBTITLE = 16;  // 副标题/日期
  static readonly FONT_SIZE_TITLE = 20;     // 模块标题
  static readonly FONT_SIZE_CITY = 32;      // 城市名
  static readonly FONT_SIZE_TEMP_L = 96;    // 大温度
  
  // 字重层级
  static readonly FONT_WEIGHT_THIN = 100;      // 超大温度数字
  static readonly FONT_WEIGHT_LIGHT = 300;     // 次要描述
  static readonly FONT_WEIGHT_REGULAR = 400;   // 正文
  static readonly FONT_WEIGHT_MEDIUM = 500;    // 卡片标题、数值
  static readonly FONT_WEIGHT_SEMIBOLD = 600;  // 模块标题
  static readonly FONT_WEIGHT_BOLD = 700;      // 强调信息

  static readonly FontWeight: FontWeightDef = {
    THIN: DesignSystem.FONT_WEIGHT_THIN,
    LIGHT: DesignSystem.FONT_WEIGHT_LIGHT,
    REGULAR: DesignSystem.FONT_WEIGHT_REGULAR,
    MEDIUM: DesignSystem.FONT_WEIGHT_MEDIUM,
    SEMIBOLD: DesignSystem.FONT_WEIGHT_SEMIBOLD,
    BOLD: DesignSystem.FONT_WEIGHT_BOLD
  };

  // ========== 6. 动效 (Animation) ==========
  static readonly ANIMATION_FAST: AnimationPreset = { duration: 200, curve: Curve.EaseOut };
  static readonly ANIMATION_MEDIUM: AnimationPreset = { duration: 300, curve: Curve.EaseInOut };
  static readonly ANIMATION_SLOW: AnimationPreset = { duration: 400, curve: Curve.EaseOut };

  static readonly Animation: AnimationDef = {
    FAST: DesignSystem.ANIMATION_FAST,
    MEDIUM: DesignSystem.ANIMATION_MEDIUM,
    SLOW: DesignSystem.ANIMATION_SLOW
  };

  // ========== 7. 图标路径 (Icons) - SVG线性图标 ==========
  static readonly ICON_SIZE_S = 20;
  static readonly ICON_SIZE_M = 24;
  static readonly ICON_SIZE_L = 28;
  
  // 图标资源路径（使用已放置的SVG）
  static readonly ICON_LOCATION = $r('app.media.location');
  static readonly ICON_SUN = $r('app.media.sun');
  static readonly ICON_CLOUDY = $r('app.media.cloudy');
  static readonly ICON_RAIN = $r('app.media.rain');
  static readonly ICON_WIND = $r('app.media.wind');
  static readonly ICON_DROP = $r('app.media.drop');
  static readonly ICON_MENU = $r('app.media.menu');
  static readonly ICON_ADD = $r('app.media.add');
  static readonly ICON_BACK = $r('app.media.back');
  static readonly ICON_REFRESH = $r('app.media.refresh');
  static readonly ICON_CLOSE = $r('app.media.close');
  static readonly ICON_MORE = $r('app.media.more');
  static readonly ICON_CHECK = $r('app.media.check');
  static readonly ICON_SEARCH = $r('app.media.search');
  static readonly ICON_EDIT = $r('app.media.edit');
  static readonly ICON_REORDER = $r('app.media.reorder');
  static readonly ICON_LOCATION_PIN = $r('app.media.location_pin');
  static readonly ICON_MOON = $r('app.media.moon');
  static readonly ICON_CLOUD_MOON = $r('app.media.cloud_moon');
  static readonly ICON_STORM = $r('app.media.storm');
  static readonly ICON_SNOW = $r('app.media.snow');
  static readonly ICON_FOG = $r('app.media.fog');
  static readonly ICON_HAZE = $r('app.media.haze');
  static readonly ICON_DRIZZLE = $r('app.media.drizzle');
  static readonly ICON_OVERCAST = $r('app.media.overcast');
  static readonly ICON_AQI = $r('app.media.aqi');
  static readonly ICON_HUMIDITY = $r('app.media.humidity');

  // 资源图标集合（Image 使用）
  static readonly IconResources: ResourceIconsDef = {
    LOCATION: DesignSystem.ICON_LOCATION,
    SUN: DesignSystem.ICON_SUN,
    CLOUDY: DesignSystem.ICON_CLOUDY,
    RAIN: DesignSystem.ICON_RAIN,
    WIND: DesignSystem.ICON_WIND,
    DROP: DesignSystem.ICON_DROP,
    MENU: DesignSystem.ICON_MENU,
    ADD: DesignSystem.ICON_ADD,
    BACK: DesignSystem.ICON_BACK,
    REFRESH: DesignSystem.ICON_REFRESH,
    CLOSE: DesignSystem.ICON_CLOSE,
    MORE: DesignSystem.ICON_MORE,
    CHECK: DesignSystem.ICON_CHECK,
    SEARCH: DesignSystem.ICON_SEARCH,
    EDIT: DesignSystem.ICON_EDIT,
    REORDER: DesignSystem.ICON_REORDER,
    LOCATION_PIN: DesignSystem.ICON_LOCATION_PIN,
    MOON: DesignSystem.ICON_MOON,
    CLOUD_MOON: DesignSystem.ICON_CLOUD_MOON,
    STORM: DesignSystem.ICON_STORM,
    SNOW: DesignSystem.ICON_SNOW,
    FOG: DesignSystem.ICON_FOG,
    HAZE: DesignSystem.ICON_HAZE,
    DRIZZLE: DesignSystem.ICON_DRIZZLE,
    OVERCAST: DesignSystem.ICON_OVERCAST,
    AQI: DesignSystem.ICON_AQI,
    HUMIDITY: DesignSystem.ICON_HUMIDITY
  };

  // Path 图标集合（Path 命令使用）
  static readonly Icons: PathIconsDef = {
    LOCATION: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
    MENU: 'M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z',
    REFRESH: 'M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z',
    PLUS: 'M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z',
    BACK: 'M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z',
    SUN: 'M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zm0 9c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-10.96c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06zM7.05 18.36c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06z',
    CLOUD: 'M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM19 18H6c-2.21 0-4-1.79-4-4 0-2.05 1.53-3.76 3.56-3.97l1.07-.11.5-.95C8.08 7.14 9.94 6 12 6c2.62 0 4.88 1.86 5.39 4.43l.3 1.5 1.53.11c1.56.1 2.78 1.41 2.78 2.96 0 1.65-1.35 3-3 3z',
    RAIN: 'M19 10c0-3.87-3.13-7-7-7S5 6.13 5 10c0 2.12.93 4.03 2.4 5.32.32.27.37.75.1 1.07-.26.32-.74.37-1.06.1C4.69 14.96 3.5 12.62 3.5 10c0-4.69 3.81-8.5 8.5-8.5s8.5 3.81 8.5 8.5c0 2.62-1.19 4.96-3.04 6.49-.32.27-.8.22-1.06-.1-.27-.32-.22-.8.1-1.07C18.07 14.03 19 12.12 19 10zM8 14v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1zm4 0v-2c0-.55-.45-1-1-1s-1 .45-1 1v2c0 .55.45 1 1 1s1-.45 1-1zm4 0v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1zm-8 4v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1zm4 0v-2c0-.55-.45-1-1-1s-1 .45-1 1v2c0 .55.45 1 1 1s1-.45 1-1zm4 0v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1z'
  };
}
