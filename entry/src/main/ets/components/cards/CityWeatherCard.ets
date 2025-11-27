// ============================================================================
// Imports
// ============================================================================
import { CityWeatherState } from '../../viewmodel/WeatherController';
import { FormatHelper } from '../../common/utils/FormatHelper';
import { CityRepository } from '../../data/repository/CityRepository';
import { DesignSystem } from '../../common/theme/DesignSystem';

// ============================================================================
// 城市天气卡片组件
// ============================================================================

/**
 * 城市天气卡片组件
 * 
 * 用于在主页面展示单个城市的天气信息，包括城市名称、天气描述、
 * 当前温度、体感温度、空气质量以及当日最高最低温度。
 * 
 * 使用场景：
 * - 主页面的城市天气轮播卡片
 * - 城市管理页面的天气预览
 * 
 * @component
 * @param cityState - 城市天气状态数据，包含城市信息和天气快照
 * @param isActive - 是否为当前激活的卡片（用于动画和交互）
 */
@Component
export struct CityWeatherCard {
  // ============================================================================
  // 组件属性
  // ============================================================================
  
  /** 城市天气状态数据 */
  @Prop cityState: CityWeatherState = new CityWeatherState(CityRepository.createDefaultCity(), null, false, '');
  
  /** 是否为当前激活的卡片 */
  @Prop isActive: boolean = false;
  
  /** 夜间模式标志（影响文本颜色） */
  @StorageProp('isNightMode') isNightMode: boolean = true;

  // ============================================================================
  // 生命周期方法
  // ============================================================================
  
  aboutToAppear(): void {
    console.info(`[CityWeatherCard] 📊 组件创建: ${this.cityState?.city?.name}, hasSnapshot=${!!this.cityState?.snapshot}`);
    if (this.cityState?.snapshot) {
      console.info(`[CityWeatherCard] 🌡️ 温度: ${this.cityState.snapshot.current.temperatureC}°C, 天气: ${this.cityState.snapshot.current.condition.description}`);
    }
  }

  // ============================================================================
  // 主构建方法
  // ============================================================================
  
  build() {
    Column() {
      this.renderCityName()
      this.renderLocationDetail()
      this.renderDescription()
      this.renderSummaryLine()
      this.renderMainTemperature()
      this.renderHighLowTemp()
    }
    .width('100%')
    .padding({ 
      top: DesignSystem.SPACING_L, 
      left: DesignSystem.SPACING_M, 
      right: DesignSystem.SPACING_M,
      bottom: DesignSystem.SPACING_M 
    })
  }

  // ============================================================================
  // UI 渲染方法组
  // ============================================================================
  
  /**
   * 渲染城市名称（大字部分 - 简洁显示）
   * 只显示城市名称的主要部分，不包含行政区划
   */
  @Builder
  private renderCityName() {
    Text(this.getCityNameSimple())
      .fontSize(32)
      .fontWeight(DesignSystem.FONT_WEIGHT_SEMIBOLD)
      .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
      .fontColor(this.getTextColor('primary'))
      .textAlign(TextAlign.Center)
      .width('100%')
      .textShadow(this.getTextShadow('normal'))
  }

  /**
   * 渲染地理位置详情（小字部分 - 详细显示）
   * 显示完整的行政区划信息，如"河北省 唐山市"
   */
  @Builder
  private renderLocationDetail() {
    if (this.getLocationDetail()) {
      Text(this.getLocationDetail())
        .fontSize(14)
        .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor('secondary'))
        .opacity(0.85)
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)
        .width('100%')
        .textShadow(this.getTextShadow('normal'))
    }
  }

  /**
   * 渲染天气描述
   */
  @Builder
  private renderDescription() {
    Text(this.getDescription())
      .fontSize(18)
      .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
      .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
      .fontColor(this.getTextColor('primary'))
      .opacity(0.9)
      .margin({ top: DesignSystem.SPACING_XS })
      .textAlign(TextAlign.Center)
      .width('100%')
      .textShadow(this.getTextShadow('normal'))
  }

  /**
   * 渲染摘要行（体感温度和空气质量）
   */
  @Builder
  private renderSummaryLine() {
    if (this.cityState.snapshot) {
      Row({ space: DesignSystem.SPACING_S }) {
        Text(`体感 ${FormatHelper.formatTemperature(this.cityState.snapshot.current.feelsLikeC)}`)
          .fontSize(14)
          .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(this.getTextColor('secondary'))

        Text('·')
          .fontSize(14)
          .fontColor(this.getTextColor('tertiary'))

        Text(`空气 ${FormatHelper.formatAqi(this.cityState.snapshot.current.aqi)}`)
          .fontSize(14)
          .fontWeight(DesignSystem.FONT_WEIGHT_REGULAR)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(this.getTextColor('secondary'))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ top: DesignSystem.SPACING_S })
    }
  }

  /**
   * 渲染主温度显示
   */
  @Builder
  private renderMainTemperature() {
    Text(this.getTemperatureText())
      .fontSize(110)
      .fontWeight(DesignSystem.FONT_WEIGHT_LIGHT)
      .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
      .fontColor(this.getTextColor('primary'))
      .height(120)
      .letterSpacing(-2)
      .margin({ top: DesignSystem.SPACING_S })
      .textAlign(TextAlign.Center)
      .width('100%')
      .textShadow(this.getTextShadow('large'))
  }

  /**
   * 渲染最高最低温度
   */
  @Builder
  private renderHighLowTemp() {
    if (this.cityState.snapshot && this.cityState.snapshot.daily.length > 0) {
      Text(`最高 ${FormatHelper.formatTemperature(this.cityState.snapshot.daily[0].maxTempC)} 最低 ${FormatHelper.formatTemperature(this.cityState.snapshot.daily[0].minTempC)}`)
        .fontSize(16)
        .fontWeight(DesignSystem.FONT_WEIGHT_MEDIUM)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(this.getTextColor('primary'))
        .margin({ top: DesignSystem.SPACING_S })
        .textAlign(TextAlign.Center)
        .width('100%')
        .textShadow(this.getTextShadow('normal'))
    }
  }

  // ============================================================================
  // 样式计算方法组
  // ============================================================================
  
  /**
   * 获取文本颜色
   * 
   * 根据夜间模式和颜色级别返回对应的文本颜色。
   * 
   * @param level 颜色级别（'primary' | 'secondary' | 'tertiary'）
   * @returns 颜色字符串
   */
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

  /**
   * 获取文本阴影样式
   * 
   * 统一的阴影计算方法，根据文本类型返回对应的阴影配置。
   * 白天和夜间都使用深色阴影，因为文字都是白色。
   * 
   * @param shadowType 阴影类型（'large' 用于主温度显示，'normal' 用于普通文本）
   * @returns 阴影配置对象
   */
  private getTextShadow(shadowType: 'large' | 'normal' = 'normal'): ShadowOptions {
    if (shadowType === 'large') {
      // 大温度数字使用更明显的阴影
      return { radius: 10, color: 'rgba(0, 0, 0, 0.4)', offsetX: 0, offsetY: 2 };
    } else {
      // 普通文本使用标准阴影
      return { radius: 6, color: 'rgba(0, 0, 0, 0.35)', offsetX: 0, offsetY: 1 };
    }
  }

  // ============================================================================
  // 数据处理方法组
  // ============================================================================
  
  /**
   * 获取简单城市名称（用于大字显示）
   * 
   * 只返回城市名称的主要部分，不包含行政区划信息。
   * 例如：
   * - "唐山, 河北省" → "唐山"
   * - "路南区, 唐山市, 河北省" → "路南区"
   * - "北京, 中国" → "北京"
   * 
   * @returns 简洁的城市名称
   */
  private getCityNameSimple(): string {
    const name: string = this.cityState.city.name;
    
    // 如果没有逗号，直接返回
    if (!name.includes(',')) {
      return name;
    }
    
    // 分割城市名称，只返回第一部分
    const parts = name.split(',').map(part => part.trim());
    return parts[0];
  }

  /**
   * 获取地理位置详情（用于小字显示）
   * 
   * 返回完整的行政区划信息，不包含城市名称本身。
   * 例如：
   * - "唐山, 河北省" → "河北省"
   * - "路南区, 唐山市, 河北省" → "河北省 唐山市"
   * - "北京, 中国" → null（不显示国家）
   * - "Manhattan, New York, United States" → "New York, United States"
   * 
   * @returns 地理位置详情字符串，如果没有额外信息则返回 null
   */
  private getLocationDetail(): string | null {
    const name: string = this.cityState.city.name;
    
    // 如果没有逗号，没有额外信息
    if (!name.includes(',')) {
      return null;
    }
    
    // 分割城市名称
    const parts = name.split(',').map(part => part.trim());
    
    // 如果只有2部分
    if (parts.length === 2) {
      // 如果第二部分是"中国"或"China"，不显示（避免冗余）
      if (parts[1] === '中国' || parts[1] === 'China') {
        return null;
      }
      // 否则显示第二部分（如国家名）
      return parts[1];
    }
    
    // 如果有3部分（如"路南区, 唐山市, 河北省"）
    if (parts.length === 3) {
      // 对于中国城市，显示"省 市"的格式
      if (this.cityState.city.country === '中国' || this.cityState.city.country === 'China') {
        return `${parts[2]} ${parts[1]}`;
      }
      // 对于国际城市，显示"州/省, 国家"
      return `${parts[1]}, ${parts[2]}`;
    }
    
    // 如果有更多部分，显示后面的部分
    return parts.slice(1).join(', ');
  }

  /**
   * 获取天气描述
   * 
   * @returns 天气描述文本，无数据时返回 '--'
   */
  private getDescription(): string {
    return this.cityState.snapshot !== null
      ? this.cityState.snapshot.current.condition.description
      : '--';
  }

  /**
   * 获取温度文本
   * 
   * @returns 格式化的温度文本（如 "25°"），无数据时返回 '--'
   */
  private getTemperatureText(): string {
    return this.cityState.snapshot !== null
      ? `${Math.round(this.cityState.snapshot.current.temperatureC)}°`
      : '--';
  }
}
