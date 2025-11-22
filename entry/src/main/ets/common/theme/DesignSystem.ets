// 字体权重类型定义
interface FontWeightDef {
  THIN: number;
  LIGHT: number;
  REGULAR: number;
  MEDIUM: number;
  BOLD: number;
  HEAVY: number;
}

// 间距系统类型定义
interface SpacingDef {
  XS: number;
  S: number;
  M: number;
  L: number;
  XL: number;
  XXL: number;
  XXXL: number;
}

// 颜色系统类型定义
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
  ERROR: string;
  SUCCESS: string;
  WARNING: string;
}

// 图标系统类型定义
interface IconsDef {
  LOCATION: string;
  MENU: string;
  REFRESH: string;
  PLUS: string;
  BACK: string;
  SUN: string;
  CLOUD: string;
  RAIN: string;
}

export class DesignSystem {
  // 字体权重
  static readonly FontWeight: FontWeightDef = {
    THIN: 100,
    LIGHT: 300,
    REGULAR: 400,
    MEDIUM: 500,
    BOLD: 700,
    HEAVY: 900
  };

  // 间距系统 (8px grid)
  static readonly Spacing: SpacingDef = {
    XS: 4,
    S: 8,
    M: 16,
    L: 24,
    XL: 32,
    XXL: 48,
    XXXL: 64
  };

  // 颜色系统
  static readonly Colors: ColorsDef = {
    WHITE: '#FFFFFF',
    WHITE_90: 'rgba(255, 255, 255, 0.9)',
    WHITE_70: 'rgba(255, 255, 255, 0.7)',
    WHITE_50: 'rgba(255, 255, 255, 0.5)',
    WHITE_30: 'rgba(255, 255, 255, 0.3)',
    WHITE_10: 'rgba(255, 255, 255, 0.1)',
    
    BLACK: '#000000',
    BLACK_90: 'rgba(0, 0, 0, 0.9)',
    BLACK_50: 'rgba(0, 0, 0, 0.5)',
    
    GLASS_BG: 'rgba(255, 255, 255, 0.1)',
    GLASS_BORDER: 'rgba(255, 255, 255, 0.2)',
    
    // 语义色
    ERROR: '#FF453A',
    SUCCESS: '#32D74B',
    WARNING: '#FFD60A'
  };

  // 图标路径 (SVG Path Data)
  static readonly Icons: IconsDef = {
    LOCATION: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
    MENU: 'M3 18h18v-2H3v2zm0-5h18v-2H3v2zm0-7v2h18V6H3z',
    REFRESH: 'M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z',
    PLUS: 'M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z',
    BACK: 'M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z',
    
    // 天气图标 (简化的SVG路径)
    SUN: 'M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zm0 9c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-10.96c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06zM7.05 18.36c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06z',
    CLOUD: 'M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM19 18H6c-2.21 0-4-1.79-4-4 0-2.05 1.53-3.76 3.56-3.97l1.07-.11.5-.95C8.08 7.14 9.94 6 12 6c2.62 0 4.88 1.86 5.39 4.43l.3 1.5 1.53.11c1.56.1 2.78 1.41 2.78 2.96 0 1.65-1.35 3-3 3z',
    RAIN: 'M19 10c0-3.87-3.13-7-7-7S5 6.13 5 10c0 2.12.93 4.03 2.4 5.32.32.27.37.75.1 1.07-.26.32-.74.37-1.06.1C4.69 14.96 3.5 12.62 3.5 10c0-4.69 3.81-8.5 8.5-8.5s8.5 3.81 8.5 8.5c0 2.62-1.19 4.96-3.04 6.49-.32.27-.8.22-1.06-.1-.27-.32-.22-.8.1-1.07C18.07 14.03 19 12.12 19 10zM8 14v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1zm4 0v-2c0-.55-.45-1-1-1s-1 .45-1 1v2c0 .55.45 1 1 1s1-.45 1-1zm4 0v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1zm-8 4v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1zm4 0v-2c0-.55-.45-1-1-1s-1 .45-1 1v2c0 .55.45 1 1 1s1-.45 1-1zm4 0v-1c0-.55-.45-1-1-1s-1 .45-1 1v1c0 .55.45 1 1 1s1-.45 1-1z'
  };
}
