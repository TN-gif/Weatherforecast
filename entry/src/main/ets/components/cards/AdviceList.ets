import { AdviceItem } from '../../data/models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct AdviceList {
  @Prop items: AdviceItem[] = [];

  build() {
    // 横向滑动卡片列表
    List({ space: DesignSystem.SPACING_M }) {
      ForEach(this.items, (item: AdviceItem) => {
        ListItem() {
          this.renderAdviceCard(item);
        }
      }, (item: AdviceItem) => item.id)
    }
    .listDirection(Axis.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height(100)
  }

  @Builder
  private renderAdviceCard(item: AdviceItem): void {
    Column({ space: DesignSystem.SPACING_S }) {
      // 图标（居中）
      Text(item.icon)
        .fontSize(28)
        .textAlign(TextAlign.Center);

      // 标题
      Text(item.tone)
        .fontSize(14)
        .fontWeight(DesignSystem.FONT_WEIGHT_MEDIUM)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(DesignSystem.COLOR_TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1);

      // 描述
      Text(item.content)
        .fontSize(12)
        .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(DesignSystem.COLOR_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width(150)  // 固定宽度小卡片
    .height(90)
    .padding(DesignSystem.SPACING_M)
    .backgroundColor(DesignSystem.COLOR_GLASS_BG)
    .linearGradient(DesignSystem.GRADIENT_CARD_INTERNAL)  // 【关键】卡片内部渐变
    .backdropBlur(DesignSystem.BLUR_RADIUS)
    .borderRadius(DesignSystem.CORNER_RADIUS_M)
    .border({ width: 1, color: DesignSystem.COLOR_GLASS_BORDER })
    .shadow(DesignSystem.SHADOW_SOFT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
