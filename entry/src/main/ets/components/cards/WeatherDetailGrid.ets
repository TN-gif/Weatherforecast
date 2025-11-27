import { DesignSystem } from '../../common/theme/DesignSystem';

/**
 * 天气详情网格组件
 * 
 * 以网格布局展示天气的各项详细指标，包括湿度、空气质量、风速、体感温度、
 * 气压、能见度、紫外线指数、日出日落时间等。采用玻璃拟态设计风格，
 * 支持日间/夜间主题自动切换。
 * 
 * 使用场景：
 * - 天气主页的详情区域
 * - 展示完整的天气指标信息
 * 
 * 布局特点：
 * - 2列网格布局
 * - 紫外线指数卡片占据2列宽度（大卡片）
 * - 其他指标卡片各占1列（标准卡片）
 */
@Component
export struct WeatherDetailGrid {
  /** 湿度百分比（如 "65%"） */
  @Prop humidity: string = '';
  
  /** 空气质量指数（如 "优 35"） */
  @Prop aqi: string = '';
  
  /** 风速信息（如 "东北风 2级"） */
  @Prop wind: string = '';
  
  /** 体感温度（如 "22°"） */
  @Prop feelsLike: string = '';
  
  /** 气压值（如 "1013 hPa"） */
  @Prop pressure: string = '';
  
  /** 能见度信息（如 "10 km"） */
  @Prop visibilityInfo: string = '';
  
  /** 紫外线指数（如 "3 中等"） */
  @Prop uvIndex: string = '';
  
  /** 日出时间（如 "06:30"） */
  @Prop sunrise: string = '';
  
  /** 日落时间（如 "18:45"） */
  @Prop sunset: string = '';
  
  /** 是否为夜间模式（从全局存储中获取） */
  @StorageProp('isNightMode') isNightMode: boolean = true;

  build() {
    Grid() {
      GridItem() {
        this.renderDetailItem('紫外线指数', this.uvIndex, DesignSystem.ICON_SUN, '无需特别防护', true)
      }
      .columnStart(0)
      .columnEnd(1)

      GridItem() {
        this.renderDetailItem('湿度', this.humidity, DesignSystem.ICON_DROP, '露点 18°', false)
      }

      GridItem() {
        this.renderDetailItem('空气质量', this.aqi, DesignSystem.ICON_CLOUDY, '空气清新', false)
      }

      GridItem() {
        this.renderDetailItem('风速', this.wind, DesignSystem.ICON_WIND, '微风拂面', false)
      }

      GridItem() {
        this.renderDetailItem('体感温度', this.feelsLike, DesignSystem.ICON_SUN, '与实际温度相近', false)
      }

      GridItem() {
        this.renderDetailItem('气压', this.pressure, DesignSystem.ICON_CLOUDY, '呈上升趋势', false)
      }

      GridItem() {
        this.renderDetailItem('能见度', this.visibilityInfo, DesignSystem.ICON_SUN, '视野清晰', false)
      }
      
      GridItem() {
        this.renderDetailItem('日出', this.sunrise, DesignSystem.ICON_SUN, '日出时间', false)
      }
      
      GridItem() {
        this.renderDetailItem('日落', this.sunset, DesignSystem.ICON_MOON, '日落时间', false)
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(DesignSystem.SPACING_M)
    .columnsGap(DesignSystem.SPACING_M)
    .width('100%')
  }

  /**
   * 渲染天气详情网格项
   * 
   * @param title - 详情项标题（如"湿度"、"紫外线指数"）
   * @param value - 详情项数值（如"65%"、"3"）
   * @param icon - 详情项图标资源
   * @param desc - 详情项描述文本（如"露点 18°"）
   * @param isLarge - 是否为大尺寸卡片（大卡片占据两列宽度）
   */
  @Builder
  private renderDetailItem(title: string, value: string, icon: Resource, desc: string, isLarge: boolean): void {
    Column({ space: isLarge ? DesignSystem.SPACING_S : DesignSystem.SPACING_XS }) {
      // 标题行：图标 + 标题文本
      Row({ space: isLarge ? 8 : 6 }) {
        Image(icon)
          .width(isLarge ? 20 : 16)
          .height(isLarge ? 20 : 16)
          .fillColor(this.getTextColor('secondary'))

        Text(title)
          .fontSize(isLarge ? 14 : 13)
          .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(this.getTextColor('secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      // 数值文本（移除 hPa 单位以保持简洁）
      Text(value.replace('hPa', ''))
        .fontSize(isLarge ? 38 : 28)
        .fontWeight(DesignSystem.FONT_WEIGHT_MEDIUM)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor('primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Clip })

      Blank()

      // 描述文本
      Text(desc)
        .fontSize(isLarge ? 13 : 12)
        .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor('secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(DesignSystem.SPACING_M)
    .backgroundColor(this.isNightMode ? DesignSystem.COLOR_GLASS_BG : DesignSystem.COLOR_GLASS_BG_DAY)
    .linearGradient(DesignSystem.GRADIENT_CARD_INTERNAL)
    .backdropBlur(DesignSystem.BLUR_RADIUS)
    .borderRadius(DesignSystem.CORNER_RADIUS_M)
    .border({ width: 1, color: this.isNightMode ? DesignSystem.COLOR_GLASS_BORDER : DesignSystem.COLOR_GLASS_BORDER_DAY })
    .shadow(DesignSystem.SHADOW_SOFT)
    .width('100%')
    .height(isLarge ? 130 : 116)
  }

  /**
   * 根据文本层级和主题模式获取对应的文本颜色
   * 
   * @param level - 文本层级（'primary': 主要文本, 'secondary': 次要文本, 'tertiary': 三级文本）
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
}
