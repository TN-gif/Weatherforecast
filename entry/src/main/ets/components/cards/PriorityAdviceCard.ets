import { AdviceItem } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct PriorityAdviceCard {
  @Prop advice: AdviceItem;
  @StorageProp('isNightMode') isNightMode: boolean = true;

  build() {
    Row() {
      // 图标
      Image(this.getAdviceIcon())
        .width(32)
        .height(32)
        .fillColor(this.getTextColor('primary'))
        .margin({ right: DesignSystem.Spacing.M });
      
      Column({ space: DesignSystem.Spacing.XS }) {
        // 标题
        Text(this.advice.tone)
          .fontSize(18)
          .fontWeight(DesignSystem.FontWeight.SEMIBOLD)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(this.getTextColor('primary'));
        
        // 行动建议
        Text(this.advice.content)
          .fontSize(14)
          .fontWeight(DesignSystem.FontWeight.REGULAR)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(this.getTextColor('secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
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

  private getAdviceIcon(): Resource {
    // 根据建议类型返回对应图标
    const iconLower = this.advice.icon.toLowerCase();
    
    if (iconLower.includes('rain') || iconLower.includes('伞')) {
      return DesignSystem.IconResources.RAIN;
    } else if (iconLower.includes('sun') || iconLower.includes('阳')) {
      return DesignSystem.IconResources.SUN;
    } else if (iconLower.includes('wind') || iconLower.includes('风')) {
      return DesignSystem.IconResources.WIND;
    } else if (iconLower.includes('cloud') || iconLower.includes('云')) {
      return DesignSystem.IconResources.CLOUDY;
    } else {
      return DesignSystem.IconResources.SUN; // 默认图标
    }
  }
}
