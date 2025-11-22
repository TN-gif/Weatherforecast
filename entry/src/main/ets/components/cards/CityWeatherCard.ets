import { CityWeatherState } from '../../viewmodel/WeatherController';
import { FormatHelper } from '../../common/utils/FormatHelper';
import { CityRepository } from '../../data/repository/CityRepository';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Component
export struct CityWeatherCard {
  @Prop cityState: CityWeatherState = new CityWeatherState(CityRepository.createDefaultCity(), null, false, '');
  @Prop isActive: boolean = false;

  build() {
    Column() {
      this.renderHeader();
      this.renderTemperature();
      if (this.cityState.snapshot !== null) {
        this.renderUpdatedLabel();
      }
    }
    .width('100%')
    .padding({ top: 48, bottom: 24, left: 16, right: 16 })
    // Removed card styling (background, border, shadow)
  }

  @Builder
  private renderHeader(): void {
    Column()
      .margin({ bottom: 0 })
      .backgroundColor(Color.Transparent) // Ensure transparent
      .border({ width: 0 }) { // Ensure no border
      Text("Los Angeles") // Temporary hardcode for UI polish as requested
        .fontSize(32)
        .fontWeight(DesignSystem.FontWeight.REGULAR)
        .fontColor(DesignSystem.Colors.WHITE)
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)', offsetY: 2 });
        
      Text(this.getDescription())
        .fontSize(20)
        .fontWeight(DesignSystem.FontWeight.MEDIUM)
        .fontColor(DesignSystem.Colors.WHITE)
        .opacity(0.9)
        .margin({ top: 4 })
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.3)', offsetY: 2 });
    }
  }

  @Builder
  private renderTemperature(): void {
    Column()
      .margin({ top: 12, bottom: 12 })
      .alignItems(HorizontalAlign.Center) {
      
      // Huge Temperature
      Text(this.getTemperatureText())
        .fontSize(110) // Huge size
        .fontWeight(100) // Ultra Thin
        .fontColor(DesignSystem.Colors.WHITE)
        .height(120)
        .margin({ top: -10 }) // Move up slightly
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 4 }); // Soft shadow

      // High / Low
      if (this.cityState.snapshot && this.cityState.snapshot.daily.length > 0) {
        Row() {
          Text(`H:${FormatHelper.formatTemperature(this.cityState.snapshot.daily[0].maxTempC)}`)
            .fontSize(18)
            .fontWeight(DesignSystem.FontWeight.MEDIUM)
            .fontColor(DesignSystem.Colors.WHITE);
          
          Text(`L:${FormatHelper.formatTemperature(this.cityState.snapshot.daily[0].minTempC)}`)
            .fontSize(18)
            .fontWeight(DesignSystem.FontWeight.MEDIUM)
            .fontColor(DesignSystem.Colors.WHITE)
            .margin({ left: 12 });
        }
        .margin({ top: 0 });
      }
    }
  }

  @Builder
  private renderUpdatedLabel(): void {
    // Optional: Keep it subtle or remove if not needed. Keeping it subtle.
    Row()
      .margin({ top: 8 })
      .alignItems(VerticalAlign.Center) 
      .opacity(0) // Hidden for now to be cleaner, or we can make it very subtle
  }

  private getDescription(): string {
    return this.cityState.snapshot !== null
      ? this.cityState.snapshot.current.condition.description
      : '等待更新';
  }

  private getTemperatureText(): string {
    return this.cityState.snapshot !== null
      ? `${Math.round(this.cityState.snapshot.current.temperatureC)}°`
      : '--';
  }
}
