import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct WeatherDetailGrid {
  @Prop humidity: string = '';
  @Prop aqi: string = '';
  @Prop wind: string = '';
  @Prop feelsLike: string = '';
  @Prop pressure: string = '';
  @Prop visibilityInfo: string = '';
  @Prop uvIndex: string = '';

  build() {
    Grid() {
      GridItem() {
        this.DetailItem('湿度', this.humidity, DesignSystem.Icons.RAIN, '露点 18°')
      }
      GridItem() {
        this.DetailItem('空气质量', this.aqi, DesignSystem.Icons.CLOUD, '空气清新')
      }
      GridItem() {
        this.DetailItem('风速', this.wind, DesignSystem.Icons.CLOUD, '微风拂面')
      }
      GridItem() {
        this.DetailItem('体感温度', this.feelsLike, DesignSystem.Icons.SUN, '与实际温度相近')
      }
      GridItem() {
        this.DetailItem('气压', this.pressure, DesignSystem.Icons.CLOUD, '呈上升趋势')
      }
      GridItem() {
        this.DetailItem('能见度', this.visibilityInfo, DesignSystem.Icons.SUN, '视野清晰')
      }
      GridItem() {
        this.DetailItem('紫外线', this.uvIndex, DesignSystem.Icons.SUN, '无需特别防护')
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(12) // 减小间距，更紧凑
    .columnsGap(12)
    .width('100%')
    // 不需要定死高度，让 GridItem 自己撑开
  }

  @Builder
  private DetailItem(title: string, value: string, icon: string, desc: string = ''): void {
    Column() {
      // 1. 标题栏 (Icon + Title)
      Row() {
        Path()
          .commands(icon)
          .fill(DesignSystem.Colors.WHITE_50) // 图标颜色淡一点
          .width(16)
          .height(16)
        Text(title)
          .fontSize(13) // 标题字号小一点，精致
          .fontWeight(DesignSystem.FontWeight.MEDIUM)
          .fontColor(DesignSystem.Colors.WHITE_50)
          .margin({ left: 6 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 2. 核心数值 (大字)
      Column() {
        if (value.includes('hPa')) {
          // 特殊处理单位
          Text() {
            Span(value.replace('hPa', ''))
              .fontSize(28)
              .fontWeight(DesignSystem.FontWeight.REGULAR)
              .fontColor(DesignSystem.Colors.WHITE)
            Span(' hPa')
              .fontSize(16)
              .fontColor(DesignSystem.Colors.WHITE_50)
          }
        } else {
          Text(value)
            .fontSize(28)
            .fontWeight(DesignSystem.FontWeight.REGULAR)
            .fontColor(DesignSystem.Colors.WHITE)
        }
      }
      .margin({ top: 12 }) // 数值与标题拉开距离
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Blank()

      // 3. 底部描述 (小字)
      Text(desc)
        .fontSize(12)
        .fontColor(DesignSystem.Colors.WHITE_70)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(14) // 内部 Padding
    .backgroundColor(DesignSystem.Colors.GLASS_BG) // 使用新的极透背景
    .borderRadius(20) // 大圆角
    .backdropBlur(80) // 极高模糊
    .border({ width: 0.5, color: DesignSystem.Colors.GLASS_BORDER }) // 极细边框
    .shadow({
      radius: 20, // 柔和阴影
      color: 'rgba(0, 0, 0, 0.1)',
      offsetY: 4,
      offsetX: 0
    })
    .width('100%')
    .height(120) // 方形卡片
  }
}
