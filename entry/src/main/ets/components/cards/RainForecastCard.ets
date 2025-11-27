import { RainForecast } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct RainForecastCard {
  @Prop rainData: RainForecast[];
  /** 夜间模式标志，默认 false，由 WeatherHomePage.bootstrap() 设置 */
  @StorageProp('isNightMode') isNightMode: boolean = false;

  build() {
    Column({ space: DesignSystem.Spacing.S }) {
      // 标题和核心信息
      Row() {
        Image($r('app.media.rain'))
          .width(24)
          .height(24)
          .fillColor(this.getTextColor('primary'))
          .margin({ right: DesignSystem.Spacing.S });
        
        Column() {
          Text(this.getMainMessage())
            .fontSize(16)
            .fontWeight(DesignSystem.FontWeight.SEMIBOLD)
            .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
            .fontColor(this.getTextColor('primary'));
          
          Text(this.getSubMessage())
            .fontSize(12)
            .fontWeight(DesignSystem.FontWeight.REGULAR)
            .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
            .fontColor(this.getTextColor('secondary'))
            .margin({ top: DesignSystem.Spacing.XS });
        }
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%');

      // 降雨强度图表
      Row({ space: 2 }) {
        ForEach(this.rainData.slice(0, 12), (item: RainForecast, index: number) => {
          Column() {
            // 柱状图
            Rect()
              .width(24)
              .height(this.getBarHeight(item.probability))
              .fill(this.getRainColor(item.intensity))
              .borderRadius(2);
          }
          .height(60)
          .justifyContent(FlexAlign.End);
        }, (item: RainForecast) => `rain_${item.timeMinutes}`);
      }
      .width('100%')
      .height(60)
      .margin({ top: DesignSystem.Spacing.S });

      // 时间标签
      Row() {
        Text('现在')
          .fontSize(10)
          .fontColor(this.getTextColor('tertiary'));
        
        Blank();
        
        Text('60分钟后')
          .fontSize(10)
          .fontColor(this.getTextColor('tertiary'));
      }
      .width('100%');
    }
    .width('100%')
    .padding(DesignSystem.Spacing.M)
    .backgroundColor(this.isNightMode ? DesignSystem.COLOR_GLASS_BG : DesignSystem.COLOR_GLASS_BG_DAY)
    .linearGradient(DesignSystem.GRADIENT_CARD_INTERNAL)
    .backdropBlur(DesignSystem.BLUR_RADIUS)
    .borderRadius(DesignSystem.CORNER_RADIUS_M)
    .border({ width: 1, color: this.isNightMode ? DesignSystem.COLOR_GLASS_BORDER : DesignSystem.COLOR_GLASS_BORDER_DAY })
    .shadow(DesignSystem.SHADOW_SOFT);
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

  private getMainMessage(): string {
    const nextRain = this.rainData.find(item => item.probability > 50);
    if (nextRain) {
      return `${nextRain.timeMinutes}分钟后有雨`;
    }
    return '未来60分钟无降雨';
  }

  private getSubMessage(): string {
    const maxProb = Math.max(...this.rainData.map(item => item.probability));
    return `最大降雨概率 ${maxProb}%`;
  }

  private getBarHeight(probability: number): number {
    return Math.max(4, (probability / 100) * 56);
  }

  private getRainColor(intensity: 'light' | 'moderate' | 'heavy'): string {
    switch (intensity) {
      case 'light':
        return '#64B5F6'; // 浅蓝
      case 'moderate':
        return '#2196F3'; // 中蓝
      case 'heavy':
        return '#1565C0'; // 深蓝
      default:
        return '#64B5F6';
    }
  }
}
