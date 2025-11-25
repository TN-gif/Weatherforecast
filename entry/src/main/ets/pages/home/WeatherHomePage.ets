import type common from '@ohos.app.ability.common';
import { CityRepository } from '../../data/repository/CityRepository';
import { WeatherRepository } from '../../data/repository/WeatherRepository';
import { WeatherService } from '../../data/services/WeatherService';
import { MockWeatherRepository } from '../../mock/MockWeatherRepository';
import { WeatherController, CityWeatherState } from '../../viewmodel/WeatherController';
import { WeatherSnapshot, City, CitySource } from '../../data/models/WeatherModels';
import { WeatherApiConstants } from '../../common/constants/WeatherApiConstants';
import { AppContextHolder } from '../../common/di/AppContextHolder';
import { AtmosphereBackground } from '../../components/background/AtmosphereBackground';
import { BackgroundMode } from '../../common/constants/ThemeConstants';
import { DebugLogger, LogData } from '../../common/utils/DebugLogger';
import { FeatureChecker, FeatureStatus } from '../../common/utils/FeatureChecker';
import { CityWeatherCard } from '../../components/cards/CityWeatherCard';
import { WeatherDetailGrid } from '../../components/cards/WeatherDetailGrid';
import { AdviceList } from '../../components/cards/AdviceList';
import { FormatHelper } from '../../common/utils/FormatHelper';
import { LocationService } from '../../data/services/LocationService';
import { AppPreferences } from '../../data/storage/AppPreferences';
import { RefreshState } from '../../data/models/WeatherModels';
import { ErrorToast, ErrorMessage, ErrorHandler } from '../../components/common/ErrorToast';
import { ShakeDetector } from '../../common/utils/ShakeDetector';
import { HourlyTrendChart } from '../../components/charts/HourlyTrendChart';
import { PerformanceOverlay } from '../../components/debug/PerformanceOverlay';
import { ResourceStatusOverlay } from '../../components/debug/ResourceStatusOverlay';
import { DatabaseInspector } from '../../components/debug/DatabaseInspector';
import { ChartPerformanceMonitor } from '../../components/debug/ChartPerformanceMonitor';
import { ThemeDebugPanel } from '../../components/debug/ThemeDebugPanel';
import { ResourceValidator } from '../../components/debug/ResourceValidator';
import { LogViewer } from '../../components/debug/LogViewer';
import { NetworkDiagnosis, DiagnosisResult } from '../../common/utils/NetworkDiagnosis';
import { NetworkDiagnosisDialog } from '../../components/diagnosis/NetworkDiagnosisDialog';
import { ResourceManager } from '../../common/utils/ResourceManager';
import { ThemeConstants } from '../../common/constants/ThemeConstants';
import { ThemeManager } from '../../common/theme/ThemeManager';
import router from '@ohos.router';
import { DesignSystem } from '../../common/theme/DesignSystem';
import { WeatherSkeleton } from '../../components/common/WeatherSkeleton';
import vibrator from '@ohos.vibrator';

@Component
export struct WeatherHomePage {
  private preferences: AppPreferences = new AppPreferences();
  private controller: WeatherController = new WeatherController(
    CityRepository.getInstance(),
    new WeatherRepository(new WeatherService(WeatherApiConstants.OPEN_METEO_CONFIG), new MockWeatherRepository()),
    LocationService.getInstance(),
    this.preferences
  );
  private shakeDetector: ShakeDetector = ShakeDetector.getInstance();
  @State private cityStates: CityWeatherState[] = [];
  @State private isLoading: boolean = true;
  @State private errorMessage: string = '';
  @StorageProp('themeKey') themeKey: string = 'sunny_day';
  @State private activeIndex: number = 0;
  @State private isRefreshing: boolean = false;
  @State private refreshState: RefreshState = RefreshState.IDLE;
  @State private shakeEnabled: boolean = true;
  @State private currentError: ErrorMessage | null = null;
  @State private showMenu: boolean = false;
  @State private showDiagnosisDialog: boolean = false;
  @State private diagnosisResult: DiagnosisResult | undefined = undefined;
  private networkDiagnosis: NetworkDiagnosis = NetworkDiagnosis.getInstance();
  private logger: DebugLogger = DebugLogger.getInstance();
  private featureChecker: FeatureChecker = FeatureChecker.getInstance();
  private resourceManager: ResourceManager = ResourceManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private diagnosisDialogController?: CustomDialogController;

  aboutToAppear(): void {
    const lifecycleData: LogData = {
      'cityStatesLength': this.cityStates.length,
      'isLoading': this.isLoading,
      'hasError': !!this.currentError
    };
    this.logger.lifecycle('WeatherHomePage', 'aboutToAppear 开始', lifecycleData);
    
    // 执行功能检查
    this.performFeatureCheck();
    
    const context: common.UIAbilityContext | null = AppContextHolder.getContext();
    if (context !== null) {
      this.logger.info('WeatherHomePage', '✅ Context获取成功，开始启动');
      this.bootstrap(context);
      this.initializeShakeDetection();
    } else {
      this.logger.error('WeatherHomePage', '❌ Context获取失败');
      this.errorMessage = '无法获取应用上下文';
      this.isLoading = false;
    }
  }

  aboutToDisappear(): void {
    this.logger.lifecycle('WeatherHomePage', 'aboutToDisappear 开始');
    // 停止摇一摇检测
    this.shakeDetector.stopDetection(() => this.handleShakeRefresh());
  }

  private async bootstrap(context: common.UIAbilityContext): Promise<void> {
    try {
      console.info('[WeatherHomePage] ========== 开始应用初始化 ==========');
      console.info(`[WeatherHomePage] 🏗️ 应用上下文: ${context ? '有效' : '无效'}`);
      
      // 检查网络状态
      try {
        console.info('[WeatherHomePage] 🌐 检查网络连通性...');
        const testUrl = 'https://www.baidu.com';
        console.info(`[WeatherHomePage] 🔗 测试URL: ${testUrl}`);
      } catch (networkError) {
        console.warn('[WeatherHomePage] ❌ 网络连通性检查失败:', networkError);
      }
      
      // 初始化资源管理器
      console.info('[WeatherHomePage] 🎨 开始初始化资源管理器...');
      await this.resourceManager.init(context);
      console.info('[WeatherHomePage] ✅ 资源管理器初始化完成');
      
      // 初始化主题管理器
      console.info('[WeatherHomePage] 🌙 开始初始化主题管理器...');
      await this.themeManager.init();
      console.info('[WeatherHomePage] ✅ 主题管理器初始化完成');
      
      // 初始化控制器（包含自动定位）
      console.info('[WeatherHomePage] 🎮 开始初始化控制器...');
      await this.controller.init(context);
      console.info('[WeatherHomePage] ✅ 控制器初始化完成');
      
      // 检查初始化后的城市数据
      const cities = this.controller.getCityStates();
      console.info(`[WeatherHomePage] 📊 初始化后城市数量: ${cities.length}`);
      cities.forEach((state, index) => {
        console.info(`[WeatherHomePage] 🏙️ 城市${index + 1}: ${state.city.name} (${state.city.source})`);
      });
      
      // 获取背景模式设置
      console.info('[WeatherHomePage] 🎨 加载背景模式设置...');
      const backgroundMode: string = await this.preferences.getBackgroundMode();
      AppStorage.setOrCreate('backgroundMode', backgroundMode);
      console.info(`[WeatherHomePage] 🎨 背景模式: ${backgroundMode}`);
      
      // 加载天气数据
      console.info('[WeatherHomePage] 🌤️ 开始加载天气数据...');
      await this.refresh(false);
      
      console.info('[WeatherHomePage] ========== 应用初始化完成 ==========');
    } catch (error) {
      console.error('[WeatherHomePage] Bootstrap failed:', error);
      this.currentError = ErrorHandler.handle(error as Error, '应用初始化失败');
      this.errorMessage = `初始化失败: ${(error as Error).message}`;
      this.isLoading = false;
    }
  }

  private async refresh(force: boolean): Promise<void> {
    if (this.isRefreshing) {
      console.warn(`[WeatherHomePage] ⏸️ 刷新已在进行中，忽略新的刷新请求`);
      return;
    }
    
    console.info(`[WeatherHomePage] ========== 开始刷新天气数据 ==========`);
    console.info(`[WeatherHomePage] 🔄 强制刷新: ${force}`);
    console.info(`[WeatherHomePage] 📊 当前城市数量: ${this.cityStates.length}`);
    console.info(`[WeatherHomePage] 👆 当前活动索引: ${this.activeIndex}`);
    
    // 显示当前城市状态
    this.cityStates.forEach((state, index) => {
      console.info(`[WeatherHomePage] 🏙️ 城市${index + 1}: ${state.city.name} (ID: ${state.city.id}, 来源: ${state.city.source})`);
    });
    
    this.isRefreshing = true;
    this.refreshState = RefreshState.REFRESHING;
    try {
      const states: CityWeatherState[] = await this.controller.loadAll(force);
      console.info(`[WeatherHomePage] Loaded ${states.length} city states`);
      
      // 过滤掉无效的状态
      const validStates = states.filter(state => state && state.city && state.city.id);
      console.info(`[WeatherHomePage] Valid states: ${validStates.length}`);
      
      this.cityStates = validStates;
      this.errorMessage = '';
      
      if (this.activeIndex >= validStates.length) {
        this.activeIndex = 0;
      }
      
      console.info('[WeatherHomePage] Refresh completed successfully');
    } catch (error) {
      console.error('[WeatherHomePage] Refresh failed:', error);
      this.currentError = ErrorHandler.createNetworkError('天气数据刷新失败，请稍后重试');
      this.errorMessage = `天气服务暂不可用: ${(error as Error).message}`;
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
      this.refreshState = RefreshState.IDLE;
      console.info('[WeatherHomePage] Refresh process completed');
    }
  }

  private async handleRefresh(): Promise<void> {
    await this.refresh(true);
  }

  private initializeShakeDetection(): void {
    if (this.shakeEnabled) {
      const success = this.shakeDetector.startDetection(() => this.handleShakeRefresh());
      if (!success) {
        console.warn('[WeatherHomePage] Failed to initialize shake detection');
        this.shakeEnabled = false;
      }
    }
  }

  private async handleShakeRefresh(): Promise<void> {
    if (this.isRefreshing || this.isLoading) {
      return;
    }
    
    console.info('[WeatherHomePage] Shake refresh triggered');
    
    // 可选：添加震动反馈
    try {
      // 注意：需要添加震动权限才能使用
      // vibrator.startVibration({ type: 'time', duration: 200 });
    } catch (error) {
      // 忽略震动错误
    }
    
    await this.refresh(true);
  }

  private get currentState(): CityWeatherState | null {
    if (this.cityStates.length === 0) {
      return null;
    }
    const safeIndex: number = Math.min(this.activeIndex, this.cityStates.length - 1);
    const state = this.cityStates[safeIndex];
    // 确保返回的状态是有效的
    if (state && state.city && state.city.id) {
      return state;
    }
    return null;
  }

  private resolveThemeKey(): string {
    if (!this.currentState || !this.currentState.snapshot) {
      return this.isNightTime() ? 'night' : 'sunny';
    }

    const condition = this.currentState.snapshot.current.condition;
    const isNight = this.isNightTime();
    
    // 优先使用condition中的themeKey，然后根据时间调整
    let baseTheme = condition.themeKey;
    
    // 根据时间调整主题
    if (baseTheme === 'rainy') {
      return isNight ? 'rainy_night' : 'rainy_day';
    } else if (baseTheme === 'snow') {
      return isNight ? 'snow_night' : 'snow_day';
    } else if (baseTheme === 'sunny') {
      return isNight ? 'night' : 'sunny';
    } else {
      return isNight ? 'night' : 'sunny';
    }
  }

  private isNightTime(): boolean {
    const now = new Date();
    const hours = now.getHours();
    return hours >= 18 || hours <= 6;
  }

  private performFeatureCheck(): void {
    this.logger.info('WeatherHomePage', '🔍 开始执行功能检查');
    
    const features: FeatureStatus[] = this.featureChecker.checkAllFeatures();
    
    features.forEach((feature: FeatureStatus) => {
      const featureData: LogData = {
        'reason': feature.reason,
        'enabled': feature.enabled
      };
      this.logger.checkFeature('WeatherHomePage', feature.name, feature.enabled, featureData);
    });
    
    const enabledCount = features.filter(f => f.enabled).length;
    const totalCount = features.length;
    
    const enabledFeatureNames = features.filter(f => f.enabled).map(f => f.name).join(', ');
    const disabledFeatureNames = features.filter(f => !f.enabled).map(f => f.name).join(', ');
    
    const summaryData: LogData = {
      'enabledFeatures': enabledFeatureNames,
      'disabledFeatures': disabledFeatureNames,
      'enabledCount': enabledCount,
      'totalCount': totalCount
    };
    
    this.logger.info('WeatherHomePage', `📊 功能检查完成: ${enabledCount}/${totalCount} 个功能可用`, summaryData);
  }

  @Builder
  private renderBackgroundModeSwitch(): void {
    Row() {
      Button('视频背景')
        .onClick(() => {
          AppStorage.setOrCreate('backgroundMode', BackgroundMode.VIDEO);
          console.info('[WeatherHomePage] 🎬 切换到视频背景模式');
        })
        .fontSize(12)
        .height(32)
        .backgroundColor('rgba(76, 175, 80, 0.8)')
        .margin({ right: 8 });
      
      Button('动画背景')
        .onClick(() => {
          AppStorage.setOrCreate('backgroundMode', BackgroundMode.ANIMATED_IMAGE);
          console.info('[WeatherHomePage] 🎞️ 切换到动画背景模式');
        })
        .fontSize(12)
        .height(32)
        .backgroundColor('rgba(33, 150, 243, 0.8)')
        .margin({ right: 8 });
      
      Button('渐变背景')
        .onClick(() => {
          AppStorage.setOrCreate('backgroundMode', BackgroundMode.GRADIENT);
          console.info('[WeatherHomePage] 🌈 切换到渐变背景模式');
        })
        .fontSize(12)
        .height(32)
        .backgroundColor('rgba(156, 39, 176, 0.8)');
    }
    .position({ x: 16, y: 100 })
    .zIndex(1000);
  }

  build() {
    Stack() {
      // 1. 背景层
      AtmosphereBackground()

      // 2. 遮罩层：增加一点点渐变，让底部文字更清晰
      // 全局压暗
      Rect()
        .width('100%')
        .height('100%')
        .fill(Color.Black)
        .opacity(0.3) // 保持 0.3，太黑了不好看
        .hitTestBehavior(HitTestMode.None)
      
      // 底部渐变遮罩（可选，增加 Grid 区域的可读性）
      Column()
        .width('100%')
        .height('50%')
        .linearGradient({
          angle: 180,
          colors: [['rgba(0,0,0,0)', 0], ['rgba(0,0,0,0.2)', 1]]
        })
        .position({ y: '50%' })
        .hitTestBehavior(HitTestMode.None)

      // 3. 内容层
      if (this.isLoading) {
        WeatherSkeleton();
      } else if (this.errorMessage !== '') {
        this.renderError();
      } else {
        this.renderContent();
      }

      // Error Toast
      ErrorToast({ errorMessage: $currentError });
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private renderContent(): void {
    Refresh({ refreshing: $$this.isRefreshing, builder: this.refreshBuilder }) {
      Column() {
        this.renderHeader();
        this.renderBody();
      }
      .width('100%')
      .height('100%')
    }
    .onRefreshing(() => {
      this.handleRefresh();
    })
  }

  @Builder
  private renderHeader(): void {
    Row() {
      // Left: Menu Button (Icon only)
      this.IconButton(DesignSystem.Icons.MENU, () => this.navigateToCityManagement());

      Blank();

      // Right: Add Button (Icon only)
      this.IconButton(DesignSystem.Icons.PLUS, () => this.navigateToCityManagement());
    }
    .width('100%')
    .padding({ 
      left: DesignSystem.Spacing.L, 
      right: DesignSystem.Spacing.L, 
      top: DesignSystem.Spacing.XL 
    })
  }

  @Builder
  private IconButton(iconPath: string, action: () => void): void {
    Button() {
      Path()
        .commands(iconPath)
        .fill(DesignSystem.Colors.WHITE)
        .width(24)
        .height(24)
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
    }
    .width(44)
    .height(44)
    .backgroundColor(Color.Transparent) // No background
    .type(ButtonType.Circle) // Ensure circle touch area
    .onClick(() => {
      try {
        vibrator.startVibration({ type: 'time', duration: 50 }, { id: 0, usage: 'touch' });
      } catch (e) {
        // Ignore if vibration not supported
      }
      action();
    })
  }

  @Builder
  private renderBody(): void {
    Column() {
      this.renderSwiper();
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  private renderSwiper(): void {
    if (this.cityStates.length === 0) {
      Column() {
        // City Name (Left)
        Text(this.getDisplayCityName(this.currentState?.city?.name))
          .fontSize(24)
          .fontWeight(DesignSystem.FontWeight.BOLD)
          .fontColor(DesignSystem.Colors.WHITE);
        Button('添加城市')
          .onClick(() => this.navigateToCityManagement())
          .margin({ top: 16 });
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center);
    } else {
      Swiper() {
        ForEach(this.cityStates.filter(state => state && state.city && state.city.id), (state: CityWeatherState) => {
          Scroll() {
            Column() {
              // Top Area
              CityWeatherCard({ 
                cityState: state, 
                isActive: this.isStateActive(state) 
              });
              
              // Bottom Area
              Column({ space: 12 }) { // 减小卡片间的垂直间距
                // Hourly Forecast
                if (state.snapshot && state.snapshot.hourly.length > 0) {
                  HourlyTrendChart({ hourlyData: state.snapshot.hourly });
                }
                
                // Details Grid
                if (state.snapshot) {
                  WeatherDetailGrid({
                    humidity: FormatHelper.formatHumidity(state.snapshot.current.humidity),
                    aqi: FormatHelper.formatAqi(state.snapshot.current.aqi),
                    wind: FormatHelper.formatWind(state.snapshot.current.windSpeedKph, state.snapshot.current.windDirection),
                    feelsLike: FormatHelper.formatTemperature(state.snapshot.current.feelsLikeC),
                    pressure: `${state.snapshot.current.pressureHpa}hPa`,
                    visibilityInfo: `${state.snapshot.current.visibilityKm}`, // Removed 'km' here, added in Grid logic
                    uvIndex: `${state.snapshot.current.uvIndex}`
                  });
                }

                // Advice List
                if (state.snapshot && state.snapshot.advice.length > 0) {
                  AdviceList({ items: state.snapshot.advice });
                }
                
                Blank().height(100); // 底部留白
              }
              .padding({ left: 16, right: 16 }) // 保持左右间距
            }
            .width('100%')
            // 确保内容至少有一屏高，保证可以滚动，产生回弹效果
            .constraintSize({ minHeight: '100%' }) 
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring) // 关键：iOS 风格的回弹
          .width('100%')
          .height('100%')
        }, (state: CityWeatherState) => state?.city?.id || `city_${Math.random()}`);
      }
      .loop(false)
      .vertical(false)
      .index(this.activeIndex)
      .indicator(false) // Hide default indicator
      .onChange((index: number) => {
        this.activeIndex = index;
      })
      .width('100%')
      .height('100%');

      // Custom Indicator
      Row({ space: 8 }) {
        ForEach(this.cityStates.filter(state => state && state.city && state.city.id), (state: CityWeatherState, index: number) => {
          Column()
            .width(this.isIndexActive(index) ? 8 : 6)
            .height(this.isIndexActive(index) ? 8 : 6)
            .backgroundColor(this.isIndexActive(index) ? DesignSystem.Colors.WHITE : 'rgba(255,255,255,0.4)')
            .borderRadius(4);
        }, (state: CityWeatherState) => state?.city?.id || `indicator_${Math.random()}`);
      }
      .margin({ top: 0 }) // Adjust position if needed, maybe overlay?
      .position({ x: '50%', y: '95%' }) // Position at bottom
      .translate({ x: '-50%' });
    }
  }

  @Builder
  private renderError(): void {
    Column() {
      Text(this.errorMessage)
        .fontSize(18)
        .fontColor('#FFB2B2')
        .margin({ bottom: 16 });
      Button('重试')
        .onClick(() => this.refresh(true));
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private refreshBuilder(): void {
    Row() {
      LoadingProgress()
        .width(24)
        .height(24)
        .color(DesignSystem.Colors.WHITE);
      Text('刷新中...')
        .fontSize(14)
        .fontColor(DesignSystem.Colors.WHITE_70)
        .margin({ left: DesignSystem.Spacing.S });
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
  }

  private isStateActive(state: CityWeatherState): boolean {
    if (!this.currentState || !state?.city?.id || !this.currentState?.city?.id) {
      return false;
    }
    return state.city.id === this.currentState.city.id;
  }

  private isIndexActive(index: number): boolean {
    return index === this.activeIndex;
  }

  private getDisplayCityName(name: string | undefined): string {
    if (!name) return 'Loading...';
    // Simple check if name looks like coordinates (contains numbers and comma)
    if (name.match(/-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?/)) {
      return '北京市'; // Fallback/Mock as requested
    }
    return name;
  }

  private async performNetworkDiagnosis(): Promise<void> {
    try {
      console.info('[WeatherHomePage] Starting network diagnosis...');
      this.currentError = ErrorHandler.createInfoMessage('正在进行网络诊断...');
      
      const result = await this.networkDiagnosis.performFullDiagnosis();
      const score = this.networkDiagnosis.getNetworkQualityScore(result);
      
      // 更新诊断结果
      this.diagnosisResult = result;
      
      // 重新创建对话框控制器
      this.diagnosisDialogController = new CustomDialogController({
        builder: NetworkDiagnosisDialog({
          diagnosisResult: this.diagnosisResult,
          networkScore: score,
          issues: this.networkDiagnosis.analyzeResults(result)
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center
      });
      
      // 显示诊断对话框
      if (this.diagnosisDialogController) {
        this.diagnosisDialogController.open();
      }
      
      this.currentError = ErrorHandler.createInfoMessage(`网络诊断完成 (评分: ${score}/100)`);
      console.info('[WeatherHomePage] Network diagnosis completed:', result);
    } catch (error) {
      console.error('[WeatherHomePage] Network diagnosis failed:', error);
      this.currentError = ErrorHandler.handle(error as Error, '网络诊断失败');
    }
  }

  private async forceLocationRefresh(): Promise<void> {
    try {
      console.info('[WeatherHomePage] ========== 强制定位刷新 ==========');
      this.currentError = ErrorHandler.createInfoMessage('正在强制刷新定位...');
      
      // 清除现有的自动定位城市
      const cities = this.controller.getCityStates();
      const nonAutoCities = cities.filter(state => state.city.source !== CitySource.AUTO);
      console.info(`[WeatherHomePage] 🗑️ 清除自动定位城市，保留 ${nonAutoCities.length} 个手动城市`);
      
      // 强制重新获取位置
      console.info('[WeatherHomePage] 🎯 开始强制定位...');
      const coordinates = await LocationService.getInstance().getCurrentLocation();
      console.info(`[WeatherHomePage] ✅ 强制定位成功: ${coordinates.latitude}, ${coordinates.longitude}`);
      
      // 获取城市名称
      const cityName = await LocationService.getInstance().getCityNameFromCoordinates(coordinates);
      console.info(`[WeatherHomePage] 🏙️ 城市名称: ${cityName}`);
      
      // 创建新的自动定位城市
      const newAutoCity = new City(
        `auto_${Math.round(coordinates.latitude * 1000)}_${Math.round(coordinates.longitude * 1000)}`,
        cityName,
        'Auto',
        coordinates,
        CitySource.AUTO,
        'sunny',
        0
      );
      
      console.info(`[WeatherHomePage] 📍 新建自动城市: ${newAutoCity.name} (${newAutoCity.id})`);
      
      // 更新城市列表
      const updatedCities = [newAutoCity, ...nonAutoCities.map(state => state.city)];
      await CityRepository.getInstance().updateCities(updatedCities);
      
      // 刷新界面
      await this.refresh(true);
      
      this.currentError = ErrorHandler.createInfoMessage(`定位刷新完成: ${cityName}`);
      console.info('[WeatherHomePage] ========== 强制定位刷新完成 ==========');
    } catch (error) {
      console.error('[WeatherHomePage] 强制定位刷新失败:', error);
      this.currentError = ErrorHandler.handle(error as Error, '强制定位刷新失败');
    }
  }

  private async refreshCurrentLocation(): Promise<void> {
    try {
      console.info('[WeatherHomePage] Refreshing current location...');
      this.currentError = ErrorHandler.createInfoMessage('正在获取当前位置...');
      
      // 获取当前坐标
      const coordinates = await LocationService.getInstance().getCurrentLocation();
      console.info(`[WeatherHomePage] Got coordinates: ${coordinates.latitude}, ${coordinates.longitude}`);
      
      // 获取城市名称
      const cityName = await LocationService.getInstance().getCityNameFromCoordinates(coordinates);
      console.info(`[WeatherHomePage] Got city name: ${cityName}`);
      
      // 查找是否已有自动定位的城市
      const cities = this.controller.getCityStates();
      const autoCity = cities.find(state => state.city.source === CitySource.AUTO);
      
      if (autoCity) {
        // 更新现有的自动定位城市
        const updatedCity = new City(
          autoCity.city.id,
          cityName,
          'Auto',
          coordinates,
          CitySource.AUTO,
          autoCity.city.videoTheme,
          autoCity.city.timeZoneOffsetMinutes
        );
        
        // 更新城市列表
        const updatedCities = cities.map(state => 
          state.city.source === CitySource.AUTO ? updatedCity : state.city
        );
        
        await CityRepository.getInstance().updateCities(updatedCities);
        
        // 刷新天气数据
        await this.refresh(true);
        
        this.currentError = ErrorHandler.createInfoMessage(`位置已更新为: ${cityName}`);
      } else {
        // 添加新的自动定位城市
        const newAutoCity = new City(
          `auto_${Math.round(coordinates.latitude * 1000)}_${Math.round(coordinates.longitude * 1000)}`,
          cityName,
          'Auto',
          coordinates,
          CitySource.AUTO,
          'sunny',
          0
        );
        
        await CityRepository.getInstance().addCity(newAutoCity);
        await this.refresh(true);
        
        this.currentError = ErrorHandler.createInfoMessage(`已添加当前位置: ${cityName}`);
      }
      
      console.info(`[WeatherHomePage] Location refresh completed: ${cityName}`);
    } catch (error) {
      console.error('[WeatherHomePage] Location refresh failed:', error);
      this.currentError = ErrorHandler.handle(error as Error, '获取当前位置失败');
    }
  }

  private navigateToCityManagement(): void {
    try {
      console.info('[WeatherHomePage] Navigating to city management...');
      router.push({
        url: 'pages/management/CityManagementPage'
      });
      console.info('[WeatherHomePage] Navigation to city management successful');
    } catch (error) {
      console.error('[WeatherHomePage] Navigation failed:', error);
      this.currentError = ErrorHandler.handle(error instanceof Error ? error : new Error(String(error)), 'Failed to navigate');
    }
  }
}
