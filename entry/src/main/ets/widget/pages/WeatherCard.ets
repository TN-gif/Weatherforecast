@Entry
@Component
struct WeatherCard {
  @LocalStorageProp('temperature') temperature: string = '24°';
  @LocalStorageProp('city') city: string = 'Shanghai';
  @LocalStorageProp('condition') condition: string = 'Sunny';
  @LocalStorageProp('updateTime') updateTime: string = '12:00';

  build() {
    Stack() {
      // Background Gradient
      LinearGradient({
        angle: 135,
        colors: [['#4facfe', 0.0], ['#00f2fe', 1.0]]
      })
      .width('100%')
      .height('100%')

      Column() {
        Row() {
          Text(this.city)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
          
          Blank()
          
          Text(this.updateTime)
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.7)')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12 })

        Row() {
          Text(this.temperature)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          
          Blank()
          
          Column() {
            // Simple Icon Placeholder (Circle)
            Circle({ width: 24, height: 24 })
              .fill('#FFD700') // Sun color
            Text(this.condition)
              .fontSize(12)
              .fontColor('#FFFFFF')
              .margin({ top: 4 })
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        'action': 'router',
        'abilityName': 'EntryAbility',
        'params': {
          'message': 'Open from Widget'
        }
      });
    })
  }
}
