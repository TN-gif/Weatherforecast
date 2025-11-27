import { DailyForecast } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

/**
 * 每日天气预报卡片组件
 *
 * 展示未来一周的天气预报，包括日期、天气图标、温度范围和可视化温度条。
 * 使用玻璃拟态设计风格，支持日间/夜间主题切换。
 *
 * @component
 * @example
 * DailyForecastCard({ dailyData: forecastList })
 */
@Component
export struct DailyForecastCard {
  /**
   * 每日天气预报数据数组
   * 包含日期、温度、天气图标等信息
   */
  @Prop dailyData: DailyForecast[] = [];

  /**
   * 夜间模式标识
   * 从全局存储中同步，用于切换主题颜色
   * 默认值设为 false，由 WeatherHomePage.bootstrap() 根据系统时间设置正确值
   */
  @StorageProp('isNightMode') isNightMode: boolean = false;

  // 一周内的最低温度（用于温度条计算）
  private weekMinTemp: number = 0;
  // 一周内的最高温度（用于温度条计算）
  private weekMaxTemp: number = 0;
  // 一周内的温度范围（用于温度条比例计算）
  private weekTempRange: number = 1;

  /**
   * 组件即将出现时的生命周期回调
   * 计算一周内的温度范围，用于温度条的比例显示
   */
  aboutToAppear(): void {
    this.calculateWeekTempRange();
  }

  /**
   * 计算一周内的温度范围
   *
   * 遍历所有每日预报数据，找出最低温和最高温，
   * 用于后续温度条的比例计算和可视化展示。
   *
   * @private
   */
  private calculateWeekTempRange(): void {
    if (this.dailyData.length === 0) {
      return;
    }
    const minTemps: number[] = this.dailyData.map((d: DailyForecast) => d.minTempC);
    const maxTemps: number[] = this.dailyData.map((d: DailyForecast) => d.maxTempC);
    this.weekMinTemp = Math.min(...minTemps);
    this.weekMaxTemp = Math.max(...maxTemps);
    this.weekTempRange = this.weekMaxTemp - this.weekMinTemp || 1;
  }

  build() {
    Column() {
      List({ space: DesignSystem.SPACING_S }) {
        // 性能优化: 使用稳定的 key 生成器提升列表渲染性能
        // date 字段作为唯一标识符，避免不必要的列表项重建
        ForEach(this.dailyData, (item: DailyForecast, index: number) => {
          ListItem() {
            this.renderDailyItem(item, index === 0)
          }
          .reuseId(item.date) // 性能优化: 启用列表项复用，减少创建销毁开销
        }, (item: DailyForecast) => item.date)
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .cachedCount(2) // 性能优化: 缓存屏幕外的 2 个列表项，提升滚动流畅度
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
   * 渲染单个每日预报列表项
   *
   * 展示日期/周几、天气图标、温度条和温度数值。
   * 今天的项目会有特殊的背景高亮显示。
   *
   * @param item - 每日天气预报数据
   * @param isToday - 是否为今天的预报
   * @private
   */
  @Builder
  private renderDailyItem(item: DailyForecast, isToday: boolean): void {
    Row() {
      // 左：日期/周几
      Text(isToday ? '今天' : this.formatDate(item.date))
        .fontSize(16)
        .fontWeight(isToday ? DesignSystem.FONT_WEIGHT_MEDIUM : DesignSystem.FONT_WEIGHT_REGULAR)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor('primary'))
        .width('18%')

      // 图标
      Image(this.getWeatherIcon(item.iconCode))
        .width(DesignSystem.ICON_SIZE_M)
        .height(DesignSystem.ICON_SIZE_M)
        .fillColor(this.getTextColor('primary'))
        .width('12%')
        .objectFit(ImageFit.Contain)

      // 温度条
      Stack() {
        // 背景槽 - 统一使用白色半透明
        Rect()
          .width('100%')
          .height(5)
          .fill('rgba(255, 255, 255, 0.20)')
          .borderRadius(2.5)

        // 进度条
        Row()
          .height(5)
          .borderRadius(2.5)
          .linearGradient({
            angle: 90,
            colors: [
              ['#64B5F6', 0.0],
              ['#FFB74D', 1.0]
            ]
          })
          .width(`${this.getTempBarWidth(item)}%`)
          .margin({ left: `${this.getTempBarStart(item)}%` })
      }
      .layoutWeight(1)
      .margin({ left: DesignSystem.SPACING_M, right: DesignSystem.SPACING_M })
      .height(20)
      .alignContent(Alignment.Center)

      // 右：低温/高温
      Row({ space: DesignSystem.SPACING_XS }) {
        Text(`${Math.round(item.minTempC)}°`)
          .fontSize(15)
          .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(this.getTextColor('secondary'))
          .textAlign(TextAlign.End)
          .width(32)

        Text(`${Math.round(item.maxTempC)}°`)
          .fontSize(15)
          .fontWeight(DesignSystem.FONT_WEIGHT_MEDIUM)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(this.getTextColor('primary'))
          .textAlign(TextAlign.End)
          .width(32)
      }
      .width('22%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height(48)
    .padding({ left: DesignSystem.SPACING_S, right: DesignSystem.SPACING_S })
    .backgroundColor(isToday ? 'rgba(255, 255, 255, 0.15)' : Color.Transparent)
    .borderRadius(DesignSystem.SPACING_S)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 获取文本颜色
   *
   * 根据当前主题模式（日间/夜间）和文本层级返回对应的颜色值。
   *
   * @param level - 文本层级：'primary'（主要）、'secondary'（次要）、'tertiary'（第三级）
   * @returns 对应的颜色字符串
   * @private
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
   * 格式化日期为周几
   *
   * 将日期字符串转换为中文的星期表示（如"周一"、"周二"）。
   *
   * @param dateStr - ISO 格式的日期字符串
   * @returns 中文星期表示
   * @private
   */
  private formatDate(dateStr: string): string {
    const date: Date = new Date(dateStr);
    const days: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return days[date.getDay()];
  }

  /**
   * 计算温度条的起始位置
   *
   * 根据当日最低温度在一周温度范围中的位置，
   * 计算温度条在可视区域中的起始百分比。
   *
   * @param item - 每日天气预报数据
   * @returns 起始位置百分比（0-100）
   * @private
   */
  private getTempBarStart(item: DailyForecast): number {
    return ((item.minTempC - this.weekMinTemp) / this.weekTempRange) * 100;
  }

  /**
   * 计算温度条的宽度
   *
   * 根据当日温度范围（最高温-最低温）在一周温度范围中的占比，
   * 计算温度条的宽度百分比。
   *
   * @param item - 每日天气预报数据
   * @returns 宽度百分比（0-100）
   * @private
   */
  private getTempBarWidth(item: DailyForecast): number {
    return ((item.maxTempC - item.minTempC) / this.weekTempRange) * 100;
  }

  /**
   * 根据天气代码获取对应的图标资源
   *
   * 通过匹配天气代码中的关键词，返回相应的天气图标。
   * 支持雨、雪、雷暴、多云、雾霾、晴天等常见天气类型。
   *
   * @param code - 天气代码字符串
   * @returns 天气图标资源
   * @private
   */
  private getWeatherIcon(code: string): Resource {
    if (code.includes('rain') || code.includes('Rain')) {
      return DesignSystem.IconResources.RAIN;
    }
    if (code.includes('storm') || code.includes('Storm')) {
      return DesignSystem.IconResources.STORM;
    }
    if (code.includes('snow') || code.includes('Snow')) {
      return DesignSystem.IconResources.SNOW;
    }
    if (code.includes('cloud') || code.includes('Cloud')) {
      return DesignSystem.IconResources.CLOUDY;
    }
    if (code.includes('fog') || code.includes('Fog') || code.includes('haze') || code.includes('Haze')) {
      return DesignSystem.IconResources.FOG;
    }
    return DesignSystem.IconResources.SUN;
  }
}
