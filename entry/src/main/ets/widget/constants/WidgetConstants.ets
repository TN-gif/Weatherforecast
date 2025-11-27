/**
 * WidgetConstants - Shared constants for weather widgets
 * 
 * Centralized design system constants for widget components
 * to avoid duplicate definitions and naming conflicts.
 * 
 * These constants are specifically for widget context where
 * importing from DesignSystem may cause issues.
 */

/**
 * Gradient color stop type for widget backgrounds
 */
export type GradientColorStop = [ResourceColor, number];

// Layout & Spacing
export const CORNER_RADIUS_M: number = 16;
export const CORNER_RADIUS_S: number = 12;
export const SPACING_XS: number = 4;
export const SPACING_S: number = 8;
export const SPACING_M: number = 12;
export const SPACING_L: number = 16;

// Typography
export const FONT_SIZE_DESC: number = 10;
export const FONT_SIZE_BODY: number = 12;
export const FONT_SIZE_SUBTITLE: number = 14;
export const FONT_SIZE_TITLE: number = 16;
export const FONT_SIZE_TEMP_WIDGET: number = 40;
export const FONT_SIZE_TEMP_WIDGET_LARGE: number = 48;

// Icon Sizes
export const ICON_SIZE_WIDGET: number = 36;
export const ICON_SIZE_WIDGET_LARGE: number = 40;
export const ICON_SIZE_SMALL: number = 20;
export const ICON_SIZE_HOURLY: number = 18;

// Colors - 改进可见性，增加对比度
export const COLOR_TEXT_PRIMARY: string = '#FFFFFF';
export const COLOR_TEXT_SECONDARY: string = 'rgba(255, 255, 255, 0.92)';  // 从0.85提升到0.92
export const COLOR_TEXT_TERTIARY: string = 'rgba(255, 255, 255, 0.75)';   // 从0.6提升到0.75
export const COLOR_GLASS_OVERLAY: string = 'rgba(0, 0, 0, 0.15)';         // 改为深色遮罩增加对比度
export const COLOR_GLASS_CARD: string = 'rgba(0, 0, 0, 0.12)';
export const COLOR_STALENESS_INDICATOR: string = '#FFD60A';

// Effects
export const BLUR_RADIUS_WIDGET: number = 20;
export const STALENESS_DOT_SIZE: number = 6;
export const REFRESH_BUTTON_SIZE: number = 28;
