/**
 * WeatherWidget2x2 - 2×2 紧凑型天气卡片
 * 
 * 以紧凑格式显示核心天气信息：
 * - 城市名称
 * - 当前温度
 * - 天气状况描述
 * - 天气图标
 * - 最后更新时间
 * - 数据过期指示器
 * 
 * 设计遵循 DesignSystem 规范：
 * - 玻璃拟态效果，圆角半径 16dp (CORNER_RADIUS_M)
 * - 白色文本层级，确保可读性
 * - 基于天气主题的渐变背景
 * 
 * 性能优化：
 * - 使用 @Builder 函数减少嵌套层级
 * - 提取工具方法到 WidgetHelper 实现复用
 * - LocalStorage 绑定实现跨进程数据通信
 * 
 * Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 4.1, 5.1, 5.2, 5.3, 5.4
 */

import {
  CORNER_RADIUS_M,
  SPACING_S,
  SPACING_M,
  FONT_SIZE_DESC,
  FONT_SIZE_BODY,
  FONT_SIZE_SUBTITLE,
  FONT_SIZE_TEMP_WIDGET,
  ICON_SIZE_WIDGET,
  COLOR_TEXT_PRIMARY,
  COLOR_TEXT_SECONDARY,
  COLOR_TEXT_TERTIARY,
  COLOR_GLASS_OVERLAY,
  COLOR_STALENESS_INDICATOR,
  BLUR_RADIUS_WIDGET,
  STALENESS_DOT_SIZE
} from '../constants/WidgetConstants';
import { WidgetHelper } from '../../common/utils/WidgetHelper';
import type { GradientColorStop } from '../../common/utils/WidgetHelper';

/**
 * 性能优化：使用 LocalStorage 实现跨进程数据通信
 * 
 * Widget 运行在独立的进程中，通过 LocalStorage.getShared() 获取框架共享的存储实例。
 * EntryFormAbility 通过 formBindingData 更新数据，Widget 通过 @LocalStorageProp 自动响应更新。
 * 
 * 优势：
 * 1. 避免频繁的跨进程通信开销
 * 2. 数据变化时自动触发 UI 更新，无需手动刷新
 * 3. 支持多个 Widget 实例共享同一数据源
 */
let widgetStorage = LocalStorage.getShared();

@Entry(widgetStorage)
@Component
struct WeatherWidget2x2 {
  /**
   * Widget 数据属性，通过 LocalStorage 从 FormBindingData 绑定
   * 这些属性会在 EntryFormAbility 更新数据时自动触发 UI 重渲染
   */
  
  /** 城市名称 */
  @LocalStorageProp('cityName') cityName: string = '点击刷新';
  
  /** 当前温度（带单位，如 "25°"） */
  @LocalStorageProp('temperature') temperature: string = '--°';
  
  /** 天气状况描述（如 "晴朗"、"多云"） */
  @LocalStorageProp('condition') condition: string = '数据加载中';
  
  /** 天气图标代码（如 "sun"、"rain"） */
  @LocalStorageProp('iconCode') iconCode: string = 'sun';
  
  /** 天气主题键，用于确定背景渐变色（如 "sunny"、"rainy_night"） */
  @LocalStorageProp('themeKey') themeKey: string = 'sunny';
  
  /** 最后更新时间（格式：HH:mm 更新） */
  @LocalStorageProp('updateTime') updateTime: string = '--:-- 更新';
  
  /** 数据是否过期（超过 30 分钟） */
  @LocalStorageProp('isStale') isStale: boolean = false;

  /**
   * 渲染城市名称和数据过期指示器
   * 显示城市名称，如果数据超过 30 分钟则显示红色圆点
   */
  @Builder
  private renderCityHeader() {
    Row() {
      Text(this.cityName)
        .fontSize(FONT_SIZE_SUBTITLE)
        .fontColor(COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textShadow({ radius: 2, color: 'rgba(0, 0, 0, 0.3)', offsetX: 0, offsetY: 1 })

      // 数据过期指示器（数据超过 30 分钟时显示）
      if (this.isStale) {
        Circle({ width: STALENESS_DOT_SIZE, height: STALENESS_DOT_SIZE })
          .fill(COLOR_STALENESS_INDICATOR)
          .margin({ left: SPACING_S / 2 })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 渲染温度和天气图标
   * 显示当前温度和对应的天气图标
   */
  @Builder
  private renderTemperatureSection() {
    Row() {
      Text(this.temperature)
        .fontSize(FONT_SIZE_TEMP_WIDGET)
        .fontColor(COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textShadow({ radius: 3, color: 'rgba(0, 0, 0, 0.35)', offsetX: 0, offsetY: 2 })

      Image(WidgetHelper.getWeatherIcon(this.iconCode))
        .width(ICON_SIZE_WIDGET)
        .height(ICON_SIZE_WIDGET)
        .fillColor(COLOR_TEXT_PRIMARY)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 渲染天气状况描述
   * 显示天气状况的文字描述（如"晴朗"、"多云"等）
   */
  @Builder
  private renderConditionText() {
    Text(this.condition)
      .fontSize(FONT_SIZE_BODY)
      .fontColor(COLOR_TEXT_SECONDARY)
      .fontWeight(FontWeight.Medium)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .margin({ top: SPACING_S / 2 })
      .textShadow({ radius: 2, color: 'rgba(0, 0, 0, 0.25)', offsetX: 0, offsetY: 1 })
  }

  /**
   * 渲染更新时间
   * 显示数据最后更新的时间
   */
  @Builder
  private renderUpdateTime() {
    Text(this.updateTime)
      .fontSize(FONT_SIZE_DESC)
      .fontColor(COLOR_TEXT_TERTIARY)
      .fontWeight(FontWeight.Medium)
      .textShadow({ radius: 1, color: 'rgba(0, 0, 0, 0.2)', offsetX: 0, offsetY: 1 })
  }

  /**
   * 渲染背景层
   * 包括渐变背景和玻璃拟态效果
   * 
   * 性能优化：
   * - 使用 WidgetHelper.getGradientColors() 避免重复的映射逻辑
   * - 渐变色在主题变化时才重新计算，减少不必要的计算开销
   */
  @Builder
  private renderBackground() {
    // 渐变背景层
    Column()
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 135,
        colors: WidgetHelper.getGradientColors(this.themeKey)
      })

    // 玻璃拟态叠加层
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(COLOR_GLASS_OVERLAY)
      .backdropBlur(BLUR_RADIUS_WIDGET)
  }

  /**
   * 渲染内容层
   * 包括所有天气信息的布局
   * 
   * 性能优化：
   * - 使用 @Builder 函数拆分 UI 结构，减少 build() 方法的嵌套层级
   * - 每个 @Builder 函数职责单一，便于 ArkUI 框架进行局部更新优化
   * - 使用 Blank().layoutWeight(1) 实现弹性布局，避免复杂的计算
   */
  @Builder
  private renderContent() {
    Column() {
      // 顶部：城市名称和过期指示器
      this.renderCityHeader()

      Blank()
        .layoutWeight(1)

      // 中部：温度和图标
      this.renderTemperatureSection()

      // 天气状况描述
      this.renderConditionText()

      Blank()
        .layoutWeight(1)

      // 底部：更新时间
      this.renderUpdateTime()
    }
    .width('100%')
    .height('100%')
    .padding(SPACING_M)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  build() {
    Stack() {
      // 背景层：渐变色和玻璃拟态效果
      this.renderBackground()

      // 内容层：天气信息
      this.renderContent()
    }
    .width('100%')
    .height('100%')
    .borderRadius(CORNER_RADIUS_M)
    .clip(true)
    .onClick(() => {
      // 点击卡片时启动主应用
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          message: 'OpenFromWidget',
          forceGpsCity: 'true'
        }
      });
    })
  }
}
