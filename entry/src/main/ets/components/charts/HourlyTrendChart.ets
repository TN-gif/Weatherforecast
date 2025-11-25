import { HourlyForecast } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct HourlyTrendChart {
  @Prop hourlyData: HourlyForecast[] = [];

  build() {
    Column() {
      // 顶部说明
      Text('24小时预报')
        .fontSize(13)
        .fontWeight(DesignSystem.FontWeight.MEDIUM)
        .fontColor(DesignSystem.Colors.WHITE_50)
        .margin({ bottom: 12, left: 4 })
        .width('100%')

      List({ space: 20 }) { // 增加列表项之间的间距，让它更舒展
        ForEach(this.hourlyData, (item: HourlyForecast, index: number) => {
          ListItem() {
            this.renderHourlyItem(item, index);
          }
        }, (item: HourlyForecast) => item.time)
      }
      .listDirection(Axis.Horizontal)
      .height(90)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(DesignSystem.Colors.GLASS_BG)
    .borderRadius(20)
    .backdropBlur(80)
    .border({ width: 0.5, color: DesignSystem.Colors.GLASS_BORDER })
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetY: 4
    })
  }

  @Builder
  private renderHourlyItem(item: HourlyForecast, index: number): void {
    Column() {
      // 时间
      Text(index === 0 ? '现在' : this.formatTime(item.time))
        .fontSize(14)
        .fontWeight(DesignSystem.FontWeight.MEDIUM)
        .fontColor(DesignSystem.Colors.WHITE)
        .margin({ bottom: 8 });

      // 图标 (这里强烈建议替换为 Image 资源)
      // 暂时用 Path 模拟填充图标
      Path()
        .commands(DesignSystem.Icons.SUN)
        .fill(DesignSystem.Colors.WHITE) // 纯白填充
        .width(24)
        .height(24)
        .shadow({ radius: 8, color: 'rgba(255,255,255,0.3)', offsetY: 0 }) // 图标发光效果
        .margin({ bottom: 8 });

      // 温度
      Text(`${Math.round(item.temperatureC)}°`)
        .fontSize(18)
        .fontWeight(DesignSystem.FontWeight.MEDIUM)
        .fontColor(DesignSystem.Colors.WHITE);
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .height('100%')
  }

  private formatTime(timeStr: string): string {
    const date = new Date(timeStr);
    return `${date.getHours()}时`;
  }
}
