import { AdviceItem } from '../../data/models/WeatherModels';

@Component
export struct AdviceList {
  @Prop items: AdviceItem[] = [];

  build() {
    Column() {
      ForEach(this.items, (item: AdviceItem) => {
        Row() {
          Text(item.icon)
            .fontSize(20)
            .margin({ right: 8 });
          Column() {
            Text(item.tone)
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)');
            Text(item.content)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .maxLines(2);
          }
        }
        .padding({ top: 12, bottom: 12, left: 16, right: 16 })
        .backgroundColor('rgba(255, 255, 255, 0.12)') // Unified: 12% White
        .backdropBlur(50) // Unified: Blur 50
        .borderRadius(20)
        .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.3)' }) // Unified: Border 0.5
        .shadow({
          radius: 10,
          color: 'rgba(0, 0, 0, 0.1)',
          offsetY: 0,
          offsetX: 0
        });
      }, (item: AdviceItem) => item.id);
    }
  }
}
