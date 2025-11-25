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
    }
    .width('100%')
    // 减少顶部 Padding，因为 Header 已经很高了
    .padding({ top: 32, bottom: 16, left: 16, right: 16 })
  }

  @Builder
  private renderHeader(): void {
    Column({ space: 4 }) { // 增加文字间的行间距
      Text(this.getCityName())
        .fontSize(34) // 稍微调大一点点
        .fontWeight(DesignSystem.FontWeight.MEDIUM) // 使用 Medium 增加份量
        .fontColor(DesignSystem.Colors.WHITE)
        // 增加文字阴影，防止在亮色背景下看不清
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 2 });
        
      Text(this.getDescription())
        .fontSize(20)
        .fontWeight(DesignSystem.FontWeight.REGULAR)
        .fontColor(DesignSystem.Colors.WHITE_90) // 稍微透一点
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.15)', offsetY: 1 });
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private renderTemperature(): void {
    Column() {
      // 巨大的温度数字
      Text(this.getTemperatureText())
        .fontSize(110)
        .fontWeight(DesignSystem.FontWeight.THIN) // 极细字体是高级感的关键
        .fontColor(DesignSystem.Colors.WHITE)
        .height(120) // 限制高度，防止占用过多空间
        .margin({ top: -10 }) // 负 Margin，让数字向上贴近文字，更紧凑
        .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 4 }); // 柔和的大阴影

      // 高低温
      if (this.cityState.snapshot && this.cityState.snapshot.daily.length > 0) {
        Row() {
          Text(`最高 ${FormatHelper.formatTemperature(this.cityState.snapshot.daily[0].maxTempC)}`)
            .fontSize(18)
            .fontWeight(DesignSystem.FontWeight.MEDIUM)
            .fontColor(DesignSystem.Colors.WHITE);
          
          Text(`最低 ${FormatHelper.formatTemperature(this.cityState.snapshot.daily[0].minTempC)}`)
            .fontSize(18)
            .fontWeight(DesignSystem.FontWeight.MEDIUM)
            .fontColor(DesignSystem.Colors.WHITE_90)
            .margin({ left: 12 });
        }
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)', offsetY: 1 });
      }
    }
    .margin({ top: 4, bottom: 12 })
    .alignItems(HorizontalAlign.Center)
  }

  private getCityName(): string {
    // 如果城市名包含逗号（如坐标），则显示 Mock 城市名，防止丑陋的坐标显示
    const name = this.cityState.city.name;
    if (name.includes(',')) {
      return 'Cupertino'; // 致敬 Apple 总部，或者显示 "当前位置"
    }
    return name;
  }

  private getDescription(): string {
    return this.cityState.snapshot !== null
      ? this.cityState.snapshot.current.condition.description
      : '--';
  }

  private getTemperatureText(): string {
    return this.cityState.snapshot !== null
      ? `${Math.round(this.cityState.snapshot.current.temperatureC)}°`
      : '--';
  }
}
