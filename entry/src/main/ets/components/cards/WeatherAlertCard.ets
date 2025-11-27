import { WeatherAlert } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct WeatherAlertCard {
  @Prop alert: WeatherAlert;
  @State private isExpanded: boolean = false;

  build() {
    Column() {
      // 主要内容
      Row() {
        Image(this.alert.iconResource)
          .width(28)
          .height(28)
          .fillColor(this.getAlertColor())
          .margin({ right: DesignSystem.Spacing.M });
        
        Column({ space: DesignSystem.Spacing.XS }) {
          Text(this.alert.title)
            .fontSize(16)
            .fontWeight(DesignSystem.FontWeight.SEMIBOLD)
            .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
            .fontColor(this.getAlertColor());
          
          Text(this.alert.description)
            .fontSize(14)
            .fontWeight(DesignSystem.FontWeight.REGULAR)
            .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
            .fontColor(this.getAlertTextColor())
            .maxLines(this.isExpanded ? 10 : 2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        // 展开箭头（使用已有 more 图标替代）
        Image($r('app.media.more'))
          .width(20)
          .height(20)
          .fillColor(this.getAlertColor())
          .rotate({ angle: this.isExpanded ? 180 : 0 })
          .animation({ duration: 300, curve: Curve.EaseOut });
      }
      .width('100%')
      .padding(DesignSystem.Spacing.M)
      .onClick(() => {
        animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
          this.isExpanded = !this.isExpanded;
        });
      });
    }
    .width('100%')
    .backgroundColor(this.getAlertBgColor())
    .borderRadius(DesignSystem.CORNER_RADIUS_M)
    .border({ width: 1, color: this.getAlertBorderColor() })
    .shadow(DesignSystem.SHADOW_SOFT);
  }

  private getAlertColor(): string {
    switch (this.alert.severity) {
      case 'warning':
        return '#FF9500'; // 橙色
      case 'watch':
        return '#FF3B30'; // 红色
      case 'advisory':
        return '#5AC8FA'; // 蓝色
      default:
        return '#FF9500';
    }
  }

  private getAlertBgColor(): string {
    switch (this.alert.severity) {
      case 'warning':
        return 'rgba(255, 149, 0, 0.15)';
      case 'watch':
        return 'rgba(255, 59, 48, 0.15)';
      case 'advisory':
        return 'rgba(90, 200, 250, 0.15)';
      default:
        return 'rgba(255, 149, 0, 0.15)';
    }
  }

  private getAlertBorderColor(): string {
    switch (this.alert.severity) {
      case 'warning':
        return 'rgba(255, 149, 0, 0.3)';
      case 'watch':
        return 'rgba(255, 59, 48, 0.3)';
      case 'advisory':
        return 'rgba(90, 200, 250, 0.3)';
      default:
        return 'rgba(255, 149, 0, 0.3)';
    }
  }

  private getAlertTextColor(): string {
    return DesignSystem.Colors.TEXT_PRIMARY;
  }
}
