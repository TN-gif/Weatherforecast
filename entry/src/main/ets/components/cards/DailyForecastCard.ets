import { DailyForecast } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct DailyForecastCard {
  @Prop dailyData: DailyForecast[] = [];
  @StorageProp('isNightMode') isNightMode: boolean = true;

  private weekMinTemp: number = 0;
  private weekMaxTemp: number = 0;
  private weekTempRange: number = 1;

  aboutToAppear(): void {
    this.calculateWeekTempRange();
  }

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
        ForEach(this.dailyData, (item: DailyForecast, index: number) => {
          ListItem() {
            this.renderDailyItem(item, index === 0)
          }
        }, (item: DailyForecast) => item.date)
      }
      .width('100%')
      .scrollBar(BarState.Off)
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

  private formatDate(dateStr: string): string {
    const date: Date = new Date(dateStr);
    const days: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return days[date.getDay()];
  }

  private getTempBarStart(item: DailyForecast): number {
    return ((item.minTempC - this.weekMinTemp) / this.weekTempRange) * 100;
  }

  private getTempBarWidth(item: DailyForecast): number {
    return ((item.maxTempC - item.minTempC) / this.weekTempRange) * 100;
  }

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
