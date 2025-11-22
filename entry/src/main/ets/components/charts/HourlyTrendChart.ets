import { HourlyForecast } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct HourlyTrendChart {
  @Prop hourlyData: HourlyForecast[] = [];

  build() {
    Column() {
      // Title (Optional, maybe remove to be cleaner? Keeping it for now but smaller)
      // Text('24小时预报')
      //   .fontSize(14)
      //   .fontColor(DesignSystem.Colors.WHITE_70)
      //   .margin({ bottom: 12, left: 4 });

      List({ space: 12 }) {
        ForEach(this.hourlyData, (item: HourlyForecast, index: number) => {
          ListItem() {
            this.renderHourlyItem(item, index);
          }
        }, (item: HourlyForecast) => item.time)
      }
      .listDirection(Axis.Horizontal)
      .height(100) // Reduced height
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
    }
    .width('100%')
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
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
  }

  @Builder
  private renderHourlyItem(item: HourlyForecast, index: number): void {
    Column() {
      Text(this.formatTime(item.time))
        .fontSize(14)
        .fontWeight(DesignSystem.FontWeight.REGULAR)
        .fontColor(DesignSystem.Colors.WHITE)
        .opacity(0.8);

      // Fix 3: Add Weather Icon
      Path()
        .commands(DesignSystem.Icons.SUN) // Default to Sun for visual structure
        .fill(Color.White)
        .width(24)
        .height(24)
        .margin({ top: 8, bottom: 8 });

      Text(`${Math.round(item.temperatureC)}°`)
        .fontSize(16)
        .fontWeight(DesignSystem.FontWeight.MEDIUM)
        .fontColor(DesignSystem.Colors.WHITE);
    }
    .width(60)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private formatTime(timeStr: string): string {
    const date = new Date(timeStr);
    const now = new Date();
    if (date.getHours() === now.getHours() && date.getDate() === now.getDate()) {
      return '现在';
    }
    return `${date.getHours()}时`;
  }

  private getWeatherIcon(code: string): string {
    // Simple mapping or return default
    // This should ideally map to DesignSystem.Icons
    return '/resources/base/media/weather_icon.svg'; // Placeholder or use DesignSystem paths if they were SVGs strings
    // Since DesignSystem.Icons are path strings, we can use Path component.
    // But inside List, using Path might be heavy? No, it's fine.
    // Let's change renderHourlyItem to use Path if we want to use DesignSystem.Icons
  }
}
