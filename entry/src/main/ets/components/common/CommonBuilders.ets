// ============================================================================
// 通用 UI 构建器集合
// ============================================================================

import { DesignSystem } from '../../common/theme/DesignSystem';
import vibrator from '@ohos.vibrator';

/**
 * 通用 UI 构建器模块
 * 
 * 本模块提供跨组件复用的 @Builder 函数，用于构建常见的 UI 模式。
 * 这些构建器遵循 DRY（Don't Repeat Yourself）原则，消除代码重复，
 * 提升代码可维护性和一致性。
 * 
 * 包含的构建器：
 * - IconButton: 圆形图标按钮，带触觉反馈
 * - SectionTitle: 章节标题，支持主标题和副标题
 * - DetailItem: 详情网格项，用于展示天气指标
 * 
 * 使用示例：
 * ```typescript
 * import { IconButton, SectionTitle, DetailItem } from '../../components/common/CommonBuilders';
 * 
 * // 在组件的 build() 方法中使用
 * IconButton($r('app.media.refresh'), () => {
 *   console.log('刷新按钮被点击');
 * });
 * ```
 * 
 * @module CommonBuilders
 */

/**
 * 圆形图标按钮构建器
 * 
 * 创建一个带有图标的圆形按钮，支持触觉反馈（震动）。
 * 按钮背景透明，图标为白色，带有阴影效果。
 * 
 * 视觉特点：
 * - 圆形触摸区域（44x44 dp）
 * - 图标尺寸：24x24 dp
 * - 白色图标，带阴影
 * - 点击时触发 50ms 震动反馈
 * 
 * 使用场景：
 * - 页面头部的功能按钮（刷新、设置、返回等）
 * - 浮动操作按钮
 * - 工具栏按钮
 * 
 * @param iconRes - 图标资源（如 $r('app.media.refresh')）
 * @param action - 点击事件回调函数
 * 
 * @example
 * ```typescript
 * IconButton($r('app.media.refresh'), () => {
 *   this.refreshData();
 * });
 * ```
 */
@Builder
export function IconButton(iconRes: Resource, action: () => void): void {
  Button() {
    Image(iconRes)
      .width(24)
      .height(24)
      .fillColor(DesignSystem.Colors.WHITE)
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
  }
  .width(44)
  .height(44)
  .backgroundColor(Color.Transparent)
  .type(ButtonType.Circle)
  .onClick(() => {
    try {
      // 触觉反馈：50ms 震动
      vibrator.startVibration({ type: 'time', duration: 50 }, { id: 0, usage: 'touch' });
    } catch (e) {
      // 忽略震动不支持的情况
    }
    action();
  })
}

/**
 * 章节标题构建器
 * 
 * 创建一个章节标题，支持主标题和可选的副标题。
 * 主标题使用较大字号和半粗体，副标题使用较小字号和细体。
 * 
 * 视觉特点：
 * - 主标题：18sp，半粗体，主要文本颜色
 * - 副标题：12sp，细体，次要文本颜色
 * - 左对齐，带有上下间距
 * - 支持日间/夜间主题切换
 * 
 * 使用场景：
 * - 页面内容区域的章节分隔
 * - 卡片组的标题
 * - 列表分组标题
 * 
 * @param title - 主标题文本
 * @param subtitle - 副标题文本（可选，默认为空字符串）
 * @param isNightMode - 是否为夜间模式（可选，默认为 true）
 * 
 * @example
 * ```typescript
 * // 只有主标题
 * SectionTitle('今日天气', '', this.isNightMode);
 * 
 * // 带副标题
 * SectionTitle('今日天气', '实时更新', this.isNightMode);
 * ```
 */
@Builder
export function SectionTitle(title: string, subtitle: string = '', isNightMode: boolean = true): void {
  Column() {
    Text(title)
      .fontSize(18)
      .fontWeight(DesignSystem.FONT_WEIGHT_SEMIBOLD)
      .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
      .fontColor(isNightMode ? DesignSystem.COLOR_TEXT_PRIMARY : DesignSystem.COLOR_TEXT_PRIMARY_DAY)
      .margin({ bottom: subtitle ? 4 : 0 })
    
    if (subtitle) {
      Text(subtitle)
        .fontSize(12)
        .fontWeight(DesignSystem.FONT_WEIGHT_LIGHT)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(isNightMode ? DesignSystem.COLOR_TEXT_SECONDARY : DesignSystem.COLOR_TEXT_SECONDARY_DAY)
    }
  }
  .alignItems(HorizontalAlign.Start)
  .width('100%')
  .margin({ top: DesignSystem.SPACING_L, bottom: DesignSystem.SPACING_S, left: 4 })
}

/**
 * 天气详情网格项构建器
 * 
 * 创建一个天气详情卡片，用于展示单个天气指标（如湿度、风速等）。
 * 采用玻璃拟态设计风格，支持日间/夜间主题切换。
 * 
 * 卡片结构：
 * - 顶部：图标 + 标题
 * - 中部：数值（大字号）
 * - 底部：描述文本
 * 
 * 视觉特点：
 * - 玻璃拟态背景（半透明 + 模糊）
 * - 渐变边框
 * - 柔和阴影
 * - 支持大尺寸卡片（占据两列宽度）
 * 
 * 使用场景：
 * - 天气详情网格
 * - 指标展示卡片
 * - 数据可视化面板
 * 
 * @param title - 详情项标题（如"湿度"、"紫外线指数"）
 * @param value - 详情项数值（如"65%"、"3"）
 * @param icon - 详情项图标资源
 * @param desc - 详情项描述文本（如"露点 18°"）
 * @param isLarge - 是否为大尺寸卡片（大卡片占据两列宽度，默认为 false）
 * @param isNightMode - 是否为夜间模式（影响颜色主题，默认为 true）
 * 
 * @example
 * ```typescript
 * // 标准尺寸卡片
 * DetailItem('湿度', '65%', $r('app.media.drop'), '露点 18°', false, this.isNightMode);
 * 
 * // 大尺寸卡片
 * DetailItem('紫外线指数', '3 中等', $r('app.media.sun'), '无需特别防护', true, this.isNightMode);
 * ```
 */
@Builder
export function DetailItem(
  title: string,
  value: string,
  icon: Resource,
  desc: string,
  isLarge: boolean = false,
  isNightMode: boolean = true
): void {
  Column({ space: isLarge ? DesignSystem.SPACING_S : DesignSystem.SPACING_XS }) {
    // 标题行：图标 + 标题文本
    Row({ space: isLarge ? 8 : 6 }) {
      Image(icon)
        .width(isLarge ? 20 : 16)
        .height(isLarge ? 20 : 16)
        .fillColor(getTextColor('secondary', isNightMode))

      Text(title)
        .fontSize(isLarge ? 14 : 13)
        .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(getTextColor('secondary', isNightMode))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')

    // 数值文本（移除 hPa 单位以保持简洁）
    Text(value.replace('hPa', ''))
      .fontSize(isLarge ? 38 : 28)
      .fontWeight(DesignSystem.FONT_WEIGHT_MEDIUM)
      .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
      .fontColor(getTextColor('primary', isNightMode))
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Clip })

    Blank()

    // 描述文本
    Text(desc)
      .fontSize(isLarge ? 13 : 12)
      .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
      .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
      .fontColor(getTextColor('secondary', isNightMode))
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
  .alignItems(HorizontalAlign.Start)
  .justifyContent(FlexAlign.SpaceBetween)
  .padding(DesignSystem.SPACING_M)
  .backgroundColor(isNightMode ? DesignSystem.COLOR_GLASS_BG : DesignSystem.COLOR_GLASS_BG_DAY)
  .linearGradient(DesignSystem.GRADIENT_CARD_INTERNAL)
  .backdropBlur(DesignSystem.BLUR_RADIUS)
  .borderRadius(DesignSystem.CORNER_RADIUS_M)
  .border({ width: 1, color: isNightMode ? DesignSystem.COLOR_GLASS_BORDER : DesignSystem.COLOR_GLASS_BORDER_DAY })
  .shadow(DesignSystem.SHADOW_SOFT)
  .width('100%')
  .height(isLarge ? 130 : 116)
}

// ============================================================================
// 辅助函数
// ============================================================================

/**
 * 根据文本层级和主题模式获取对应的文本颜色
 * 
 * 文本层级说明：
 * - primary: 主要文本，用于标题和重要信息
 * - secondary: 次要文本，用于辅助信息
 * - tertiary: 三级文本，用于不太重要的信息
 * 
 * @param level - 文本层级（'primary' | 'secondary' | 'tertiary'）
 * @param isNightMode - 是否为夜间模式
 * @returns 对应的颜色值
 */
function getTextColor(level: string, isNightMode: boolean): string {
  if (isNightMode) {
    if (level === 'primary') return DesignSystem.COLOR_TEXT_PRIMARY;
    if (level === 'secondary') return DesignSystem.COLOR_TEXT_SECONDARY;
    return DesignSystem.COLOR_TEXT_TERTIARY;
  } else {
    if (level === 'primary') return DesignSystem.COLOR_TEXT_PRIMARY_DAY;
    if (level === 'secondary') return DesignSystem.COLOR_TEXT_SECONDARY_DAY;
    return DesignSystem.COLOR_TEXT_TERTIARY_DAY;
  }
}
