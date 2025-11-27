import { HourlyForecast } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

/**
 * 小时趋势图表组件
 * 
 * 显示未来24小时的天气趋势，包括温度、天气图标和降水概率。
 * 使用横向滚动列表展示每小时的天气数据。
 * 
 * @component
 */
@Component
export struct HourlyTrendChart {
  /** 小时预报数据数组 */
  @Prop hourlyData: HourlyForecast[] = [];
  /** 
   * 夜间模式标志，影响颜色主题
   * 性能优化: 使用 @StorageProp 而非 @State，因为该值由全局状态管理，避免不必要的组件内部状态
   * 默认值设为 false，由 WeatherHomePage.bootstrap() 根据系统时间设置正确值
   */
  @StorageProp('isNightMode') isNightMode: boolean = false;

  build() {
    Column() {
      // 性能优化: 使用横向滚动列表，只渲染可见区域的项，避免一次性渲染所有24小时数据
      List({ space: DesignSystem.SPACING_M }) {
        ForEach(this.hourlyData, (item: HourlyForecast, index: number) => {
          ListItem() {
            this.renderHourlyItem(item, index === 0)
          }
        }, (item: HourlyForecast) => item.time)
      }
      .listDirection(Axis.Horizontal)
      .height(140)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
    }
    .width('100%')
    .padding(DesignSystem.SPACING_M)
    .backgroundColor(this.isNightMode ? DesignSystem.COLOR_GLASS_BG : DesignSystem.COLOR_GLASS_BG_DAY)
    .linearGradient(DesignSystem.GRADIENT_CARD_INTERNAL)
    .backdropBlur(DesignSystem.BLUR_RADIUS)
    .borderRadius(DesignSystem.CORNER_RADIUS_L)
    .border({ width: 1, color: this.isNightMode ? DesignSystem.COLOR_GLASS_BORDER : DesignSystem.COLOR_GLASS_BORDER_DAY })
    .shadow(DesignSystem.SHADOW_SOFT)
  }

  /**
   * 渲染单个小时项
   * 
   * 性能优化: 使用 @Builder 函数而非独立组件，减少组件创建开销
   * 
   * @param item - 小时预报数据
   * @param isNow - 是否为当前时间
   */
  @Builder
  private renderHourlyItem(item: HourlyForecast, isNow: boolean): void {
    Column({ space: DesignSystem.SPACING_S }) {
      // 时间
      Text(this.getDisplayTime(item.time, isNow))
        .fontSize(12)
        .fontWeight(isNow ? DesignSystem.FONT_WEIGHT_MEDIUM : DesignSystem.FONT_WEIGHT_REGULAR)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor(isNow ? 'primary' : 'secondary'))

      // 天气图标
      Image(this.getWeatherIcon(item.iconCode))
        .width(DesignSystem.ICON_SIZE_M)
        .height(DesignSystem.ICON_SIZE_M)
        .fillColor(this.getTextColor('primary'))

      // 温度
      Text(this.formatTemperature(item.temperatureC))
        .fontSize(17)
        .fontWeight(DesignSystem.FONT_WEIGHT_MEDIUM)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor('primary'))

      // 降水概率柱状图
      if (item.precipitationProbability > 0) {
        Column() {
          Rect()
            .width(6)
            .height(this.calculatePrecipitationBarHeight(item.precipitationProbability))
            .fill('#64B5F6')
            .borderRadius(3)

          Text(`${item.precipitationProbability}%`)
            .fontSize(10)
            .fontColor('#64B5F6')
            .margin({ top: 2 })
        }
        .height(40)
        .justifyContent(FlexAlign.End)
      } else {
        Column().height(40)
      }
    }
    .width(70)
    .padding(DesignSystem.SPACING_S)
    .backgroundColor(isNow ? 'rgba(255, 255, 255, 0.20)' : Color.Transparent)
    .borderRadius(DesignSystem.CORNER_RADIUS_S)
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 私有方法 ====================

  /**
   * 获取显示时间文本
   * 
   * @param timeStr - ISO 时间字符串
   * @param isNow - 是否为当前时间
   * @returns 格式化的时间文本（"现在" 或 "X时"）
   */
  private getDisplayTime(timeStr: string, isNow: boolean): string {
    if (isNow) {
      return '现在';
    }
    return this.formatTime(timeStr);
  }

  /**
   * 格式化时间字符串为小时显示
   * 
   * @param timeStr - ISO 时间字符串
   * @returns 格式化的小时文本（例如："14时"）
   */
  private formatTime(timeStr: string): string {
    const date: Date = new Date(timeStr);
    return `${date.getHours()}时`;
  }

  /**
   * 格式化温度显示
   * 
   * @param temperatureC - 摄氏温度值
   * @returns 格式化的温度文本（例如："25°"）
   */
  private formatTemperature(temperatureC: number): string {
    return `${Math.round(temperatureC)}°`;
  }

  /**
   * 计算降水概率柱状图高度
   * 
   * 将降水概率（0-100%）映射到柱状图高度（0-30px）
   * 
   * @param probability - 降水概率（0-100）
   * @returns 柱状图高度（像素）
   */
  private calculatePrecipitationBarHeight(probability: number): number {
    // 性能优化: 使用简单的线性映射，避免复杂计算
    return Math.min(probability / 2, 30);
  }

  /**
   * 根据文本级别和主题模式获取文本颜色
   * 
   * @param level - 文本级别（'primary', 'secondary', 'tertiary'）
   * @returns 对应的颜色值
   */
  private getTextColor(level: string): string {
    if (this.isNightMode) {
      if (level === 'primary') return DesignSystem.COLOR_TEXT_PRIMARY;
      if (level === 'secondary') return DesignSystem.COLOR_TEXT_SECONDARY;
      return DesignSystem.COLOR_TEXT_TERTIARY;
    } else {
      if (level === 'primary') return DesignSystem.COLOR_TEXT_PRIMARY_DAY;
      if (level === 'secondary') return DesignSystem.COLOR_TEXT_SECONDARY_DAY;
      return DesignSystem.COLOR_TEXT_TERTIARY_DAY;
    }
  }

  /**
   * 根据天气代码获取对应的图标资源
   * 
   * @param code - 天气代码字符串
   * @returns 天气图标资源
   */
  private getWeatherIcon(code: string): Resource {
    if (code.includes('rain') || code.includes('Rain')) {
      return DesignSystem.ICON_RAIN;
    } else if (code.includes('cloud') || code.includes('Cloud')) {
      return DesignSystem.ICON_CLOUDY;
    } else {
      return DesignSystem.ICON_SUN;
    }
  }
}
