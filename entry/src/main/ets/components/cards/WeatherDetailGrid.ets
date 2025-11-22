import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct WeatherDetailGrid {
  @Prop humidity: string = '';
  @Prop aqi: string = '';
  @Prop wind: string = '';
  @Prop feelsLike: string = '';
  @Prop pressure: string = '';
  @Prop visibilityInfo: string = '';  // Renamed to avoid conflict
  @Prop uvIndex: string = '';

  build() {
    Grid() {
      GridItem() {
        this.DetailItem('湿度', this.humidity, DesignSystem.Icons.RAIN)
      }
      GridItem() {
        this.DetailItem('空气质量', this.aqi, DesignSystem.Icons.CLOUD)
      }
      GridItem() {
        this.DetailItem('风速', this.wind, DesignSystem.Icons.CLOUD)
      }
      GridItem() {
        this.DetailItem('体感', this.feelsLike, DesignSystem.Icons.SUN)
      }
      GridItem() {
        this.DetailItem('气压', this.pressure, DesignSystem.Icons.CLOUD)
      }
      GridItem() {
        this.DetailItem('能见度', this.visibilityInfo, DesignSystem.Icons.SUN)
      }
      GridItem() {
        this.DetailItem('紫外线', this.uvIndex, DesignSystem.Icons.SUN)
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(DesignSystem.Spacing.M)
    .columnsGap(DesignSystem.Spacing.M)
    .width('100%')
    .height('100%')
  }

  @Builder
  private DetailItem(title: string, value: string, icon: string): void {
    Column() {
      // Row 1: Icon + Title (Left aligned)
      Row() {
        Path()
          .commands(icon)
          .fill(Color.White) // Fix 1: Force White
          .opacity(0.9) // Increased opacity
          .width(18)
          .height(18)
        Text(title)
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.7)')
          .margin({ left: 6 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Blank()

      // Row 2: Big Value
      // Fix 4: Formatting (Check if value contains units to separate)
      if (value.includes('hPa')) {
        Text() {
          Span(value.replace('hPa', ''))
            .fontSize(28) // Reduced from 32 to 28
            .fontWeight(DesignSystem.FontWeight.MEDIUM)
            .fontColor(DesignSystem.Colors.WHITE)
          Span(' hPa')
            .fontSize(16)
            .fontColor('rgba(255,255,255,0.7)')
        }
        .width('100%')
        .textAlign(TextAlign.Start)
      } else {
        Text(value)
          .fontSize(28) // Reduced from 32 to 28
          .fontWeight(DesignSystem.FontWeight.MEDIUM)
          .fontColor(DesignSystem.Colors.WHITE)
          .width('100%')
          .textAlign(TextAlign.Start)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor('rgba(255, 255, 255, 0.12)') // Unified: 12% White
    .borderRadius(20)
    .backdropBlur(50) // Unified: Blur 50
    .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.3)' }) // Unified: Border 0.5
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetY: 0,
      offsetX: 0
    })
    .width('100%')
    .height(110) // Fixed height for square-ish look
  }
}
