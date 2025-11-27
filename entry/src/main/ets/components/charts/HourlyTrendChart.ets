import { HourlyForecast } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct HourlyTrendChart {
  @Prop hourlyData: HourlyForecast[] = [];
  @StorageProp('isNightMode') isNightMode: boolean = true;

  build() {
    Column() {
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

  @Builder
  private renderHourlyItem(item: HourlyForecast, isNow: boolean): void {
    Column({ space: DesignSystem.SPACING_S }) {
      // 时间
      Text(isNow ? '现在' : this.formatTime(item.time))
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
      Text(`${Math.round(item.temperatureC)}°`)
        .fontSize(17)
        .fontWeight(DesignSystem.FONT_WEIGHT_MEDIUM)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor('primary'))

      // 降水概率柱状图
      if (item.precipitationProbability > 0) {
        Column() {
          Rect()
            .width(6)
            .height(Math.min(item.precipitationProbability / 2, 30))
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

  private formatTime(timeStr: string): string {
    const date: Date = new Date(timeStr);
    return `${date.getHours()}时`;
  }

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
