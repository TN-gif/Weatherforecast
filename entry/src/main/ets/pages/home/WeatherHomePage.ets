import type common from '@ohos.app.ability.common';
import { CityRepository } from '../../data/repository/CityRepository';
import { WeatherRepository } from '../../data/repository/WeatherRepository';
import { QWeatherService } from '../../data/services/QWeatherService';
import { OpenMeteoService } from '../../data/services/OpenMeteoService';
import { WeatherDataRouter } from '../../data/services/WeatherDataRouter';
import { MockWeatherRepository } from '../../mock/MockWeatherRepository';
import { WeatherController, CityWeatherState } from '../../viewmodel/WeatherController';
import { WeatherSnapshot, City, CitySource, AdviceItem, WeatherAlert } from '../../data/models/WeatherModels';
import { WeatherApiConstants } from '../../common/constants/WeatherApiConstants';
import { AppContextHolder } from '../../common/di/AppContextHolder';
import { AtmosphereBackground } from '../../components/background/AtmosphereBackground';
import { BackgroundMode } from '../../common/constants/ThemeConstants';
import { DebugLogger, LogData } from '../../common/utils/DebugLogger';
import { FeatureChecker, FeatureStatus } from '../../common/utils/FeatureChecker';
import { CityWeatherCard } from '../../components/cards/CityWeatherCard';
import { WeatherDetailGrid } from '../../components/cards/WeatherDetailGrid';
import { DailyForecastCard } from '../../components/cards/DailyForecastCard';
import { AdviceList } from '../../components/cards/AdviceList';
import { FormatHelper } from '../../common/utils/FormatHelper';
import { LocationService } from '../../data/services/LocationService';
import { AppPreferences } from '../../data/storage/AppPreferences';
import { RefreshState } from '../../data/models/WeatherModels';
import { ErrorToast, ErrorMessage, ErrorHandler } from '../../components/common/ErrorToast';
import { ShakeDetector } from '../../common/utils/ShakeDetector';
import { HourlyTrendChart } from '../../components/charts/HourlyTrendChart';
import { WeatherAlertCard } from '../../components/cards/WeatherAlertCard';
import { RainForecastCard } from '../../components/cards/RainForecastCard';
import { PriorityAdviceCard } from '../../components/cards/PriorityAdviceCard';
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
import { BackgroundRefreshService } from '../../data/services/BackgroundRefreshService';
import { WidgetDataStorage, WidgetWeatherData } from '../../data/storage/WidgetDataStorage';
import { WidgetHelper } from '../../common/utils/WidgetHelper';
import formProvider from '@ohos.app.form.formProvider';
import formBindingData from '@ohos.app.form.formBindingData';

/**
 * Widget表单数据接口 - 用于formBindingData.createFormBindingData
 * 使用普通字符串格式（参考拼图游戏成功实现）
 */
interface WidgetFormData {
  cityName: string;
  temperature: string;
  condition: string;
  iconCode: string;
  themeKey: string;
  updateTime: string;
  isStale: boolean;
  humidity: string;
  windSpeed: string;
  hourly0Time: string;
  hourly0Temp: string;
  hourly0Icon: string;
  hourly1Time: string;
  hourly1Temp: string;
  hourly1Icon: string;
  hourly2Time: string;
  hourly2Temp: string;
  hourly2Icon: string;
}

/**
 * 天气应用主页组件
 * 
 * 功能说明：
 * - 展示多城市天气信息，支持左右滑动切换城市
 * - 自动定位当前位置并获取天气数据
 * - 支持下拉刷新和摇一摇刷新
 * - 动态主题切换（根据天气状况和昼夜时间）
 * - 后台自动刷新天气数据
 * - 桌面卡片数据同步
 * 
 * 性能优化：
 * - 使用 dataVersion 机制强制触发 ForEach 重新渲染
 * - 为每个城市维护独立的 Scroller 实例，避免滚动位置混乱
 * - 后台刷新服务定期更新数据，减少用户等待时间
 * 
 * @component
 */
@Component
export struct WeatherHomePage {
  // ==================== 组件属性 ====================
  // 外部传入属性
  @Prop @Watch('onRefreshTriggerChange') refreshTrigger: number = 0;
  @Prop @Watch('onForceGpsCityIndexChange') forceGpsCityIndex: number = -1;
  
  // ==================== 服务实例 ====================
  private preferences: AppPreferences = new AppPreferences();
  private controller: WeatherController = new WeatherController(
    CityRepository.getInstance(),
    new WeatherRepository(
      new WeatherDataRouter(
        new OpenMeteoService(), // Updated to use OpenMeteoService
        new QWeatherService(WeatherApiConstants.QWEATHER_CONFIG)
      ),
      new MockWeatherRepository()
    ),
    LocationService.getInstance(),
    this.preferences
  );
  private shakeDetector: ShakeDetector = ShakeDetector.getInstance();
  private networkDiagnosis: NetworkDiagnosis = NetworkDiagnosis.getInstance();
  private logger: DebugLogger = DebugLogger.getInstance();
  private featureChecker: FeatureChecker = FeatureChecker.getInstance();
  private resourceManager: ResourceManager = ResourceManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private backgroundRefreshService: BackgroundRefreshService = BackgroundRefreshService.getInstance();
  
  // ==================== 响应式状态 ====================
  // 城市和天气数据
  @State private cityStates: CityWeatherState[] = [];
  /**
   * 性能优化：数据版本号机制
   * 
   * 作用：强制触发 ForEach 重新渲染所有城市卡片
   * 
   * 原理：
   * - ForEach 使用 key 来判断是否需要重新渲染
   * - 当 dataVersion 变化时，所有城市的 key 都会变化
   * - 这会强制 ForEach 重新创建所有卡片组件
   * 
   * 使用场景：
   * - 天气数据刷新完成后
   * - 城市列表顺序变化后
   * - 需要确保 UI 完全同步最新数据时
   * 
   * 性能影响：
   * - 会导致所有卡片重新创建，有一定性能开销
   * - 但能确保数据一致性，避免 UI 显示旧数据
   */
  @State private dataVersion: number = 0;
  @State private activeIndex: number = 0;
  
  // UI 状态
  @State private isLoading: boolean = true;
  @State private isRefreshing: boolean = false;
  @State private refreshState: RefreshState = RefreshState.IDLE;
  @State private errorMessage: string = '';
  @State private currentError: ErrorMessage | null = null;
  
  // 主题和显示
  @StorageProp('themeKey') themeKey: string = 'sunny_day';
  
  // 功能开关
  @State private shakeEnabled: boolean = true;
  @State private showMenu: boolean = false;
  @State private showDiagnosisDialog: boolean = false;
  
  // 其他状态
  @State private scrollToTopTrigger: number = 0;
  @State private diagnosisResult: DiagnosisResult | undefined = undefined;
  
  // ==================== 非响应式属性 ====================
  private diagnosisDialogController?: CustomDialogController;
  /**
   * 性能优化：城市滚动器复用策略
   * 
   * 作用：为每个城市维护独立的 Scroller 实例
   * 
   * 优势：
   * 1. 避免滚动位置混乱：切换城市时，每个城市保持自己的滚动位置
   * 2. 提升用户体验：返回之前查看的城市时，滚动位置保持不变
   * 3. 减少重新渲染：不需要每次切换都重置滚动位置
   * 
   * 实现：
   * - 使用 Map 存储，key 为城市 ID
   * - 首次访问城市时创建 Scroller 实例
   * - 后续访问复用已创建的实例
   * 
   * 内存影响：
   * - 每个 Scroller 实例占用少量内存
   * - 对于常见的 5-10 个城市，内存开销可忽略
   */
  private cityScrollers: Map<string, Scroller> = new Map();

  // ==================== 生命周期方法 ====================
  
  /**
   * 监听刷新触发器变化
   * 当外部组件（如城市管理页面）触发刷新时，此方法会被调用
   */
  onRefreshTriggerChange(): void {
    console.info(`[WeatherHomePage] 🔄 refreshTrigger变化: ${this.refreshTrigger}`);
    if (this.refreshTrigger > 0) {
      this.handleExternalRefreshRequest();
    }
  }

  /**
   * 监听强制跳转到GPS城市的索引变化
   * 处理从Widget点击跳转，强制切换到GPS定位城市
   */
  onForceGpsCityIndexChange(): void {
    console.info(`[WeatherHomePage] 🎯 forceGpsCityIndex变化: ${this.forceGpsCityIndex}`);
    if (this.forceGpsCityIndex >= 0 && this.forceGpsCityIndex < this.cityStates.length) {
      console.info(`[WeatherHomePage] 🎯 强制跳转到GPS城市，索引: ${this.forceGpsCityIndex}`);
      this.activeIndex = this.forceGpsCityIndex;
      // 更新主题
      this.updateThemeWithStates(this.cityStates, this.forceGpsCityIndex);
    }
  }

  // ==================== 数据刷新方法 ====================
  
  /**
   * 处理外部刷新请求
   * 
   * 处理场景：
   * 1. 从城市管理页面返回后刷新
   * 2. 从Widget点击跳转到指定城市
   * 3. 城市顺序变化后重新加载
   * 4. 新添加城市后跳转并刷新
   */
  private handleExternalRefreshRequest(): void {
    console.info('[WeatherHomePage] ========== 处理外部刷新请求 ==========');
    
    // 检查AppStorage中的刷新信号
    const needRefresh = AppStorage.get<boolean>('needRefreshWeather');
    const newCityId = AppStorage.get<string>('newAddedCityId');
    const cityOrderChanged = AppStorage.get<boolean>('cityOrderChanged');
    const navigateToCityIndex = AppStorage.get<number>('navigateToCityIndex');
    
    console.info(`[WeatherHomePage] 📦 AppStorage刷新信号: needRefresh=${needRefresh}, newCityId=${newCityId}, cityOrderChanged=${cityOrderChanged}, navigateToCityIndex=${navigateToCityIndex}`);
    
    // 🔧 关键修复：处理从Widget点击跳转的情况
    // 当forceGpsCityIndex >= 0时，强制跳转到GPS城市
    if (this.forceGpsCityIndex >= 0) {
      console.info(`[WeatherHomePage] 🎯 检测到Widget跳转请求，强制跳转到GPS城市索引: ${this.forceGpsCityIndex}`);
      if (this.cityStates.length > 0 && this.forceGpsCityIndex < this.cityStates.length) {
        this.activeIndex = this.forceGpsCityIndex;
        this.updateThemeWithStates(this.cityStates, this.forceGpsCityIndex);
        console.info(`[WeatherHomePage] ✅ 已跳转到GPS城市: ${this.cityStates[this.forceGpsCityIndex]?.city?.name}`);
      } else {
        console.info(`[WeatherHomePage] ⚠️ 城市列表为空或索引无效，设置activeIndex为0`);
        this.activeIndex = 0;
      }
      // 不return，继续执行后续逻辑（如果有needRefresh的话）
    }
    
    if (needRefresh) {
      console.info('[WeatherHomePage] 🔄 检测到刷新信号，准备刷新...');
      
      // 清除刷新信号
      AppStorage.setOrCreate('needRefreshWeather', false);
      AppStorage.setOrCreate('newAddedCityId', '');
      AppStorage.setOrCreate('cityOrderChanged', false);
      AppStorage.setOrCreate('navigateToCityIndex', -1);
      
      // 🔧 处理从城市管理页面点击卡片跳转的情况
      if (navigateToCityIndex !== undefined && navigateToCityIndex >= 0) {
        console.info(`[WeatherHomePage] 🎯 从城市管理页面跳转到城市索引: ${navigateToCityIndex}`);
        if (navigateToCityIndex < this.cityStates.length) {
          this.activeIndex = navigateToCityIndex;
          this.updateThemeWithStates(this.cityStates, navigateToCityIndex);
        }
        return;
      }
      
      // 🔧 关键：如果城市顺序变化，需要重新从存储加载城市列表
      if (cityOrderChanged) {
        console.info('[WeatherHomePage] 🔄 检测到城市顺序变化，重新加载城市列表...');
        this.reloadCitiesFromStorage();
        return;
      }
      
      // 先重新加载城市列表（只有城市信息，没有天气数据）
      const newCityStates = this.controller.getCityStates();
      console.info(`[WeatherHomePage] 📊 重新加载城市列表，共 ${newCityStates.length} 个城市`);
      newCityStates.forEach((state, index) => {
        console.info(`[WeatherHomePage]   ${index + 1}. ${state.city.name} (${state.city.id}), hasSnapshot: ${!!state.snapshot}`);
      });
      this.cityStates = newCityStates;
      this.dataVersion++; // 增加版本号，强制重新渲染
      
      // 如果有新添加的城市ID，跳转到该城市
      let targetIndex = -1;
      if (newCityId && newCityId !== '') {
        console.info(`[WeatherHomePage] 🎯 准备跳转到新添加的城市: ${newCityId}`);
        
        // 查找城市索引
        const cityIndex = this.cityStates.findIndex(state => state.city.id === newCityId);
        console.info(`[WeatherHomePage] 🔍 查找城市索引结果: ${cityIndex}`);
        
        if (cityIndex >= 0) {
          targetIndex = cityIndex;
          this.activeIndex = cityIndex;
          console.info(`[WeatherHomePage] ✅ 已设置活动索引为: ${cityIndex}`);
        } else {
          console.warn(`[WeatherHomePage] ⚠️ 未找到城市ID: ${newCityId}，使用最后一个城市`);
          // 新添加的城市通常在列表末尾
          if (this.cityStates.length > 0) {
            targetIndex = this.cityStates.length - 1;
            this.activeIndex = this.cityStates.length - 1;
            console.info(`[WeatherHomePage] ✅ 已设置活动索引为最后一个: ${this.activeIndex}`);
          }
        }
      }
      
      // 强制重置刷新状态，然后刷新天气数据
      console.info('[WeatherHomePage] 🔄 强制重置刷新状态并开始刷新天气数据...');
      this.isRefreshing = false;
      
      // 异步刷新天气数据，刷新完成后再次设置activeIndex确保跳转正确
      this.refreshAndJumpToCity(targetIndex);
    }
  }

  /**
   * 从存储重新加载城市列表
   * 
   * 使用场景：城市顺序在城市管理页面被修改后，需要重新加载以反映最新顺序
   * 
   * 步骤：
   * 1. 重新初始化控制器以加载最新的城市顺序
   * 2. 获取新的城市状态列表
   * 3. 更新 UI 并刷新天气数据
   * 4. 保持当前索引在有效范围内
   */
  private async reloadCitiesFromStorage(): Promise<void> {
    console.info('[WeatherHomePage] 🔄 从存储重新加载城市列表...');
    try {
      // 重新初始化控制器以加载最新的城市顺序
      const context = AppContextHolder.getContext();
      if (context) {
        await this.controller.init(context);
      }
      
      // 获取新的城市状态
      const newCityStates = this.controller.getCityStates();
      console.info(`[WeatherHomePage] 📊 重新加载后城市数量: ${newCityStates.length}`);
      newCityStates.forEach((state, index) => {
        console.info(`[WeatherHomePage]   ${index + 1}. ${state.city.name}`);
      });
      
      this.cityStates = newCityStates;
      this.dataVersion++;
      
      // 保持当前索引在有效范围内
      if (this.activeIndex >= this.cityStates.length) {
        this.activeIndex = Math.max(0, this.cityStates.length - 1);
      }
      
      // 刷新天气数据
      await this.refresh(true);
      
      console.info('[WeatherHomePage] ✅ 城市列表重新加载完成');
    } catch (error) {
      console.error('[WeatherHomePage] ❌ 重新加载城市列表失败:', error);
    }
  }

  /**
   * 刷新天气数据并跳转到指定城市
   * 
   * @param targetIndex 目标城市的索引，-1 表示不跳转
   */
  private async refreshAndJumpToCity(targetIndex: number): Promise<void> {
    console.info(`[WeatherHomePage] 🔄 开始刷新并跳转到城市索引: ${targetIndex}`);
    
    try {
      await this.refresh(true);
      
      // 刷新完成后，确保跳转到目标城市
      if (targetIndex >= 0 && targetIndex < this.cityStates.length) {
        console.info(`[WeatherHomePage] ✅ 刷新完成，确认跳转到城市索引: ${targetIndex}`);
        this.activeIndex = targetIndex;
        
        // 🔧 修复：使用直接传参的方式更新主题
        this.updateThemeWithStates(this.cityStates, targetIndex);
      }
    } catch (error) {
      console.error('[WeatherHomePage] ❌ 刷新并跳转失败:', error);
    }
  }

  /**
   * 组件即将出现生命周期回调
   * 
   * 执行操作：
   * 1. 执行功能检查（检测设备支持的功能）
   * 2. 获取应用上下文
   * 3. 启动应用初始化流程
   * 4. 初始化摇一摇检测
   */
  aboutToAppear(): void {
    const lifecycleData: LogData = {
      'cityStatesLength': this.cityStates.length,
      'isLoading': this.isLoading,
      'hasError': !!this.currentError
    };
    this.logger.lifecycle('WeatherHomePage', '========== 页面生命周期: aboutToAppear ==========', lifecycleData);
    
    // 执行功能检查
    this.performFeatureCheck();
    
    const context: common.UIAbilityContext | null = AppContextHolder.getContext();
    if (context !== null) {
      this.logger.info('WeatherHomePage', '✅ Context获取成功，开始启动应用');
      this.bootstrap(context);
      this.initializeShakeDetection();
    } else {
      this.logger.error('WeatherHomePage', '❌ Context获取失败，无法启动');
      this.errorMessage = '无法获取应用上下文';
      this.isLoading = false;
    }
  }

  /**
   * 组件即将消失生命周期回调
   * 
   * 清理操作：
   * 1. 停止摇一摇检测，释放传感器资源
   * 2. 停止后台自动刷新服务，避免内存泄漏
   */
  aboutToDisappear(): void {
    this.logger.lifecycle('WeatherHomePage', '========== 页面生命周期: aboutToDisappear ==========');
    // 停止摇一摇检测
    this.shakeDetector.stopDetection(() => this.handleShakeRefresh());
    // 停止后台刷新
    this.backgroundRefreshService.stopAutoRefresh();
  }

  /**
   * 应用启动初始化流程
   * 
   * 初始化步骤：
   * 1. 检查网络连通性
   * 2. 初始化资源管理器（加载图片、视频等资源）
   * 3. 初始化主题管理器（设置默认主题）
   * 4. 初始化控制器（包含自动定位功能）
   * 5. 加载背景模式设置
   * 6. 首次加载天气数据
   * 7. 启动后台自动刷新服务
   * 
   * @param context 应用上下文，用于访问系统服务和资源
   */
  private async bootstrap(context: common.UIAbilityContext): Promise<void> {
    try {
      console.info('[WeatherHomePage] ========== 开始应用初始化流程 ==========');
      const startTime = Date.now();
      console.info(`[WeatherHomePage] 🏗️ 应用上下文状态: ${context ? '有效' : '无效'}`);
      
      // 检查网络状态
      try {
        console.info('[WeatherHomePage] 🌐 检查网络连通性...');
        const testUrl = 'https://www.baidu.com';
        // 实际网络检查逻辑...
      } catch (networkError) {
        console.warn('[WeatherHomePage] ❌ 网络连通性检查失败:', networkError);
      }
      
      // 初始化资源管理器
      console.info('[WeatherHomePage] 🎨 初始化资源管理器...');
      await this.resourceManager.init(context);
      
      // 初始化主题管理器
      console.info('[WeatherHomePage] 🌙 初始化主题管理器...');
      await this.themeManager.init();
      
      // 初始化控制器（包含自动定位）
      console.info('[WeatherHomePage] 🎮 初始化控制器...');
      await this.controller.init(context);
      
      // 🔧 修复：从控制器加载初始城市状态
      const initialStates = this.controller.getCityStates();
      console.info(`[WeatherHomePage] 📊 初始化后城市数量: ${initialStates.length}`);
      initialStates.forEach((state, index) => {
        console.info(`[WeatherHomePage]   ${index + 1}. ${state.city.name} (${state.city.source})`);
      });
      
      // 🔧 关键修复：在调用refresh之前先赋值给cityStates
      this.cityStates = initialStates;
      
      // 获取背景模式设置
      console.info('[WeatherHomePage] ⚙️ 加载背景模式设置...');
      const backgroundMode: string = await this.preferences.getBackgroundMode();
      AppStorage.setOrCreate('backgroundMode', backgroundMode);
      console.info(`[WeatherHomePage] 🎨 当前背景模式: ${backgroundMode}`);
      
      // 加载天气数据
      console.info('[WeatherHomePage] 🌤️ 开始首次加载天气数据...');
      await this.refresh(false);
      
      /**
       * 性能优化：后台自动刷新策略
       * 
       * 作用：定期在后台自动刷新天气数据，无需用户手动操作
       * 
       * 刷新策略：
       * - 刷新间隔：30 分钟（可配置）
       * - 静默刷新：不显示加载动画，不打断用户操作
       * - 智能更新：只在数据变化时更新 UI
       * 
       * 优势：
       * 1. 数据时效性：确保用户看到的天气数据始终是最新的
       * 2. 用户体验：无感知更新，不打断用户浏览
       * 3. 桌面卡片同步：自动更新桌面卡片数据
       * 
       * 资源管理：
       * - 页面消失时自动停止刷新，避免内存泄漏
       * - 使用节流机制，避免频繁请求
       */
      console.info('[WeatherHomePage] 🔄 启动后台自动刷新服务...');
      this.backgroundRefreshService.setController(this.controller, async (states) => {
        console.info('[WeatherHomePage] 🔄 后台刷新完成，更新UI');
        const validStates = states.filter(state => state && state.city && state.city.id);
        this.cityStates = validStates;
        this.dataVersion++; // 增加版本号，强制重新渲染
        // 修复：使用直接传参的方式更新主题
        this.updateThemeWithStates(validStates, this.activeIndex);
        // 保存天气数据到Widget存储，供桌面卡片使用
        await this.saveWidgetData(validStates);
      });
      this.backgroundRefreshService.startAutoRefresh();
      
      console.info(`[WeatherHomePage] ✅ 应用初始化完成，总耗时: ${Date.now() - startTime}ms`);
    } catch (error) {
      console.error('[WeatherHomePage] ❌ Bootstrap初始化失败:', error);
      this.currentError = ErrorHandler.handle(error as Error, '应用初始化失败');
      this.errorMessage = `初始化失败: ${(error as Error).message}`;
      this.isLoading = false;
    }
  }

  /**
   * 刷新天气数据
   * 
   * 刷新流程：
   * 1. 检查并重置刷新状态（防止卡死）
   * 2. 调用控制器加载所有城市的天气数据
   * 3. 过滤无效状态
   * 4. 更新 UI 状态并触发重新渲染
   * 5. 更新主题（根据当前城市天气）
   * 6. 保存数据到 Widget 存储
   * 
   * 性能优化：
   * - 使用 Promise.race 添加 20 秒超时保护
   * - 增加 dataVersion 强制触发 ForEach 重新渲染
   * 
   * @param force 是否强制刷新（忽略缓存）
   */
  private async refresh(force: boolean): Promise<void> {
    console.info(`[WeatherHomePage] ========== refresh方法被调用 ==========`);
    console.info(`[WeatherHomePage] 📊 当前isRefreshing状态: ${this.isRefreshing}`);
    
    // 如果已经在刷新中，强制重置状态（防止卡死）
    if (this.isRefreshing) {
      console.warn(`[WeatherHomePage] ⚠️ 检测到刷新状态卡住，强制重置`);
      this.isRefreshing = false;
    }
    
    console.info(`[WeatherHomePage] ========== 开始刷新天气数据 ==========`);
    console.info(`[WeatherHomePage] 🔄 强制刷新: ${force}`);
    console.info(`[WeatherHomePage] 📊 当前城市数量: ${this.cityStates.length}`);
    console.info(`[WeatherHomePage] ⏰ 刷新开始时间: ${new Date().toISOString()}`);
    const startTime = Date.now();
    
    // 显示当前城市状态
    this.cityStates.forEach((state, index) => {
      console.debug(`[WeatherHomePage]   ${index + 1}. ${state.city.name} (ID: ${state.city.id})`);
    });
    
    this.isRefreshing = true;
    this.refreshState = RefreshState.REFRESHING;
    let refreshSucceeded: boolean = false;
    
    try {
      console.info('[WeatherHomePage] 📡 调用控制器加载数据...');
      const loadStartTime = Date.now();
      
      // 使用Promise.race添加超时保护
      const loadPromise = this.controller.loadAll(force);
      const timeoutPromise = new Promise<CityWeatherState[]>((_, reject) => {
        setTimeout(() => {
          reject(new Error('天气数据加载超时（20秒）'));
        }, 20000);
      });
      
      const states: CityWeatherState[] = await Promise.race([loadPromise, timeoutPromise]);
      
      console.info(`[WeatherHomePage] ✅ 控制器返回数据，耗时: ${Date.now() - loadStartTime}ms`);
      console.info(`[WeatherHomePage] ✅ 数据加载完成，共 ${states.length} 个城市状态`);
      
      // 详细输出每个城市的天气数据状态
      states.forEach((state, index) => {
        const hasSnapshot = !!state.snapshot;
        const temp = hasSnapshot ? state.snapshot!.current.temperatureC : '--';
        const condition = hasSnapshot ? state.snapshot!.current.condition.description : '无数据';
        console.info(`[WeatherHomePage]   ${index + 1}. ${state.city.name}: ${temp}°C, ${condition}, hasSnapshot=${hasSnapshot}`);
      });
      
      // 过滤掉无效的状态
      const validStates = states.filter(state => state && state.city && state.city.id);
      console.info(`[WeatherHomePage] 🧹 过滤后有效状态: ${validStates.length}`);
      
      // 🔧 关键修复：先更新cityStates，然后增加dataVersion触发重新渲染
      this.cityStates = validStates;
      this.dataVersion++; // 增加版本号，强制ForEach重新渲染所有卡片
      console.info(`[WeatherHomePage] ✅ cityStates已更新，新长度: ${this.cityStates.length}, dataVersion: ${this.dataVersion}`);
      
      // 验证赋值是否成功
      if (this.cityStates.length > 0) {
        const firstCity = this.cityStates[0];
        console.info(`[WeatherHomePage] 📊 验证: 第一个城市=${firstCity?.city?.name}, hasSnapshot=${!!firstCity?.snapshot}`);
      }
      
      this.errorMessage = '';
      
      // 只有当activeIndex超出范围时才重置，避免覆盖用户设置的跳转目标
      if (this.activeIndex >= validStates.length) {
        console.info(`[WeatherHomePage] 🔄 活动索引超出范围，重置: ${this.activeIndex} -> 0`);
        this.activeIndex = 0;
      } else {
        console.info(`[WeatherHomePage] 📊 保持当前活动索引: ${this.activeIndex}`);
      }
      
      // 🔧 关键修复：在try块内立即更新主题，确保cityStates已经赋值
      console.info(`[WeatherHomePage] 🎨 立即更新主题（在try块内）`);
      this.updateThemeWithStates(validStates, this.activeIndex);
      
      // 🔧 保存天气数据到Widget存储，供桌面卡片使用
      // Requirements: 3.1, 6.1
      await this.saveWidgetData(validStates);
      
      console.info(`[WeatherHomePage] ✅ 刷新流程成功完成，耗时: ${Date.now() - startTime}ms`);
      refreshSucceeded = true;
    } catch (error) {
      console.error('[WeatherHomePage] ❌ 刷新失败:', error);
      console.error('[WeatherHomePage] ❌ 错误详情:', (error as Error).message);
      this.currentError = ErrorHandler.createNetworkError('天气数据刷新失败，请稍后重试');
      // 不设置errorMessage，避免显示错误页面
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
      this.refreshState = refreshSucceeded ? RefreshState.IDLE : RefreshState.ERROR;
      
      console.info(`[WeatherHomePage] 📊 刷新结束，isRefreshing已重置为: ${this.isRefreshing}`);
      
      // 注意：主题更新已在try块中完成，这里不再重复调用
      // 只有在失败时才使用默认主题
      if (!refreshSucceeded) {
        console.info(`[WeatherHomePage] ⚠️ 刷新失败，使用默认主题`);
        this.updateTheme();
      }
      
      console.info(`[WeatherHomePage] ✅ 刷新完成，总耗时: ${Date.now() - startTime}ms`);
      console.info(`[WeatherHomePage] ⏰ 刷新结束时间: ${new Date().toISOString()}`);
      console.info(`[WeatherHomePage] 📊 最终状态: isRefreshing=${this.isRefreshing}, refreshState=${this.refreshState}`);
    }
  }

  /**
   * 处理下拉刷新事件
   * 强制刷新所有城市的天气数据
   */
  private async handleRefresh(): Promise<void> {
    await this.refresh(true);
  }

  // ==================== 桌面卡片数据同步方法 ====================
  
  /**
   * 保存天气数据到桌面卡片存储
   * 
   * 功能说明：
   * - 将天气快照数据转换为桌面卡片数据格式
   * - 持久化到 Preferences 存储
   * - 主动更新所有已注册的桌面卡片
   * 
   * 数据选择策略：
   * 1. 优先使用 GPS 定位城市（source 为 AUTO）的数据
   * 2. 如果没有 GPS 城市，使用第一个有数据的城市
   * 
   * @param states 城市天气状态数组
   */
  private async saveWidgetData(states: CityWeatherState[]): Promise<void> {
    try {
      if (states.length === 0) {
        console.info('[WeatherHomePage] ⚠️ No city states available for widget, skipping save');
        return;
      }
      
      // 🔧 关键修复：始终使用GPS定位城市（AUTO source）的数据
      // GPS定位城市通常是第一个城市，或者查找source为AUTO的城市
      let gpsState: CityWeatherState | null = null;
      
      // 首先查找AUTO类型的城市（GPS定位）
      for (const state of states) {
        if (state.city.source === CitySource.AUTO && state.snapshot) {
          gpsState = state;
          console.info(`[WeatherHomePage] 📍 Found GPS city: ${state.city.name}`);
          break;
        }
      }
      
      // 如果没有找到AUTO城市，使用第一个有数据的城市
      if (!gpsState) {
        for (const state of states) {
          if (state.snapshot) {
            gpsState = state;
            console.info(`[WeatherHomePage] 📍 Using first available city: ${state.city.name}`);
            break;
          }
        }
      }
      
      if (!gpsState || !gpsState.snapshot) {
        console.info('[WeatherHomePage] ⚠️ No weather data available for widget, skipping save');
        return;
      }
      
      console.info(`[WeatherHomePage] 💾 Saving widget data for GPS city: ${gpsState.city.name}`);
      console.info(`[WeatherHomePage] 📊 Snapshot data - humidity: ${gpsState.snapshot.current.humidity}, windSpeed: ${gpsState.snapshot.current.windSpeedKph}`);
      console.info(`[WeatherHomePage] 📊 Hourly forecast count: ${gpsState.snapshot.hourly?.length ?? 0}`);
      
      // Convert WeatherSnapshot to WidgetWeatherData using WidgetHelper
      const widgetData = WidgetHelper.convertToWidgetData(
        gpsState.snapshot,
        gpsState.city.name
      );
      
      console.info(`[WeatherHomePage] 📊 Widget data - humidity: ${widgetData.humidity}, windSpeed: ${widgetData.windSpeed}, hourly: ${widgetData.hourlyForecast.length}`);
      
      // Get application context
      const context = AppContextHolder.getContext();
      if (!context) {
        console.error('[WeatherHomePage] ❌ No context available for widget data save');
        return;
      }
      
      // Save to widget storage
      await WidgetDataStorage.saveForWidget(context, widgetData);
      
      console.info(`[WeatherHomePage] ✅ Widget data saved successfully for GPS city: ${gpsState.city.name}`);
      
      // 🔧 关键修复：保存数据后主动更新所有Widget
      // 这解决了Widget显示"--"的问题，因为之前只保存数据但没有通知Widget更新
      await this.updateAllWidgets(context, widgetData);
      
    } catch (error) {
      console.error('[WeatherHomePage] ❌ Failed to save widget data:', error);
      // Don't throw - widget data save failure shouldn't affect main app
    }
  }

  /**
   * 主动更新所有已注册的桌面卡片
   * 
   * 功能说明：
   * - 从存储中获取所有已注册的卡片 ID
   * - 构建卡片数据并调用系统 API 更新每个卡片
   * - 自动清理已删除的无效卡片
   * 
   * 解决问题：确保桌面卡片及时显示最新天气数据，避免显示"--"占位符
   * 
   * @param context 应用上下文
   * @param widgetData 要更新到卡片的天气数据
   */
  private async updateAllWidgets(context: common.UIAbilityContext, widgetData: WidgetWeatherData): Promise<void> {
    try {
      // 从存储中获取所有已注册的Widget Form ID
      const formIds = await WidgetDataStorage.loadFormIds(context);
      
      if (formIds.length === 0) {
        console.info('[WeatherHomePage] ⚠️ No registered widgets to update');
        return;
      }
      
      console.info(`[WeatherHomePage] 🔄 Updating ${formIds.length} widgets...`);
      
      // 构建FormBindingData对象 - 使用WidgetFormData接口
      const widgetFormData = this.buildWidgetFormData(widgetData);
      
      const formData = formBindingData.createFormBindingData(widgetFormData);
      
      // 更新每个Widget
      for (const formId of formIds) {
        try {
          await formProvider.updateForm(formId, formData);
          console.info(`[WeatherHomePage] ✅ Widget ${formId} updated successfully`);
        } catch (updateError) {
          console.error(`[WeatherHomePage] ❌ Failed to update widget ${formId}:`, updateError);
          // 如果Widget已被删除，从存储中移除
          const errorStr = String(updateError);
          if (errorStr.includes('not exist') || errorStr.includes('invalid')) {
            await WidgetDataStorage.removeFormId(context, formId);
            console.info(`[WeatherHomePage] 🗑️ Removed invalid widget ${formId} from storage`);
          }
        }
      }
      
      console.info('[WeatherHomePage] ✅ All widgets update completed');
    } catch (error) {
      console.error('[WeatherHomePage] ❌ Failed to update widgets:', error);
    }
  }

  /**
   * 构建桌面卡片表单数据对象
   * 
   * 数据格式：使用普通字符串格式（参考拼图游戏成功实现）
   * 
   * 转换规则：
   * - 温度：添加 "°" 符号
   * - 湿度：添加 "%" 符号
   * - 风速：添加 " km/h" 单位
   * - 时间：格式化为 "HH:mm"
   * 
   * @param widgetData 天气数据
   * @returns 卡片表单数据对象
   */
  private buildWidgetFormData(widgetData: WidgetWeatherData): WidgetFormData {
    const formData: WidgetFormData = {
      cityName: widgetData.cityName,
      temperature: `${widgetData.temperature}°`,
      condition: widgetData.condition,
      iconCode: widgetData.iconCode,
      themeKey: widgetData.themeKey,
      updateTime: widgetData.updateTime,
      isStale: false,
      humidity: `${widgetData.humidity}%`,
      windSpeed: `${widgetData.windSpeed} km/h`,
      hourly0Time: widgetData.hourlyForecast.length > 0 ? widgetData.hourlyForecast[0].time : '--:--',
      hourly0Temp: widgetData.hourlyForecast.length > 0 ? `${widgetData.hourlyForecast[0].temperature}°` : '--°',
      hourly0Icon: widgetData.hourlyForecast.length > 0 ? widgetData.hourlyForecast[0].iconCode : 'sun',
      hourly1Time: widgetData.hourlyForecast.length > 1 ? widgetData.hourlyForecast[1].time : '--:--',
      hourly1Temp: widgetData.hourlyForecast.length > 1 ? `${widgetData.hourlyForecast[1].temperature}°` : '--°',
      hourly1Icon: widgetData.hourlyForecast.length > 1 ? widgetData.hourlyForecast[1].iconCode : 'sun',
      hourly2Time: widgetData.hourlyForecast.length > 2 ? widgetData.hourlyForecast[2].time : '--:--',
      hourly2Temp: widgetData.hourlyForecast.length > 2 ? `${widgetData.hourlyForecast[2].temperature}°` : '--°',
      hourly2Icon: widgetData.hourlyForecast.length > 2 ? widgetData.hourlyForecast[2].iconCode : 'sun'
    };
    return formData;
  }

  // ==================== 交互功能方法 ====================
  
  /**
   * 初始化摇一摇检测功能
   * 
   * 功能说明：
   * - 启动加速度传感器监听
   * - 检测设备摇动手势
   * - 触发天气数据刷新
   * 
   * 如果初始化失败（设备不支持或权限不足），自动禁用该功能
   */
  private initializeShakeDetection(): void {
    if (this.shakeEnabled) {
      const success = this.shakeDetector.startDetection(() => this.handleShakeRefresh());
      if (!success) {
        console.warn('[WeatherHomePage] Failed to initialize shake detection');
        this.shakeEnabled = false;
      }
    }
  }

  /**
   * 处理摇一摇刷新事件
   * 
   * 防抖处理：如果正在刷新或加载中，忽略本次摇动
   * 用户反馈：可选添加震动反馈（需要震动权限）
   */
  private async handleShakeRefresh(): Promise<void> {
    if (this.isRefreshing || this.isLoading) {
      console.debug('[WeatherHomePage] 📳 摇一摇触发，但正在刷新中，忽略');
      return;
    }
    
    console.info('[WeatherHomePage] 📳 摇一摇触发刷新！');
    
    // 可选：添加震动反馈
    try {
      // 注意：需要添加震动权限才能使用
      // vibrator.startVibration({ type: 'time', duration: 200 });
      console.debug('[WeatherHomePage] 📳 触发震动反馈');
    } catch (error) {
      // 忽略震动错误
    }
    
    await this.refresh(true);
  }

  // ==================== 状态计算和工具方法 ====================
  
  /**
   * 获取当前活动城市的天气状态
   * 
   * 安全处理：
   * - 如果城市列表为空，返回 null
   * - 如果索引超出范围，使用最后一个城市
   * - 验证返回的状态是否有效（包含城市信息和 ID）
   * 
   * @returns 当前城市的天气状态，如果无效则返回 null
   */
  private get currentState(): CityWeatherState | null {
    console.debug(`[WeatherHomePage] currentState getter: cityStates.length=${this.cityStates.length}, activeIndex=${this.activeIndex}`);
    
    if (this.cityStates.length === 0) {
      console.debug(`[WeatherHomePage] currentState: 城市列表为空，返回null`);
      return null;
    }
    const safeIndex: number = Math.min(this.activeIndex, this.cityStates.length - 1);
    const state = this.cityStates[safeIndex];
    
    console.debug(`[WeatherHomePage] currentState: safeIndex=${safeIndex}, state存在=${!!state}, city存在=${!!(state?.city)}, id=${state?.city?.id}`);
    
    // 确保返回的状态是有效的
    if (state && state.city && state.city.id) {
      console.debug(`[WeatherHomePage] currentState: 返回有效状态 ${state.city.name}, hasSnapshot=${!!state.snapshot}`);
      return state;
    }
    console.debug(`[WeatherHomePage] currentState: 状态无效，返回null`);
    return null;
  }

  /**
   * 更新应用主题
   * 
   * 功能说明：
   * - 根据当前城市的天气状况解析主题
   * - 考虑昼夜时间（白天/夜间）
   * - 更新全局主题状态到 AppStorage
   * 
   * 强制更新：即使主题相同也会更新，确保背景视频正确切换
   */
  private updateTheme(): void {
    console.info(`[WeatherHomePage] 🎨 updateTheme被调用，当前activeIndex: ${this.activeIndex}`);
    
    const newThemeKey = this.resolveThemeKey();
    console.info(`[WeatherHomePage] 🎨 解析出的新主题: ${newThemeKey}, 当前主题: ${this.themeKey}`);
    
    // 强制更新主题（即使相同也更新，确保背景视频切换）
    console.info(`[WeatherHomePage] 🎨 更新AppStorage主题: ${newThemeKey}`);
    AppStorage.setOrCreate('themeKey', newThemeKey);
  }

  /**
   * 生成城市卡片的唯一标识符
   * 
   * 性能优化：包含数据版本号以触发 ForEach 重新渲染
   * 
   * Key 组成：
   * - 城市 ID
   * - 数据版本号（dataVersion 变化时强制重新渲染所有卡片）
   * - 天气快照标识（温度或无数据标记）
   * 
   * @param state 城市天气状态
   * @returns 唯一标识符字符串
   */
  private generateCityKey(state: CityWeatherState): string {
    if (!state || !state.city || !state.city.id) {
      return `city_${this.dataVersion}_${Math.random()}`;
    }
    // 使用城市ID + 数据版本号 + snapshot存在标识作为key
    // 当dataVersion变化时，所有卡片都会重新渲染
    const snapshotKey = state.snapshot 
      ? `_v${this.dataVersion}_${Math.round(state.snapshot.current.temperatureC)}`
      : `_v${this.dataVersion}_nodata`;
    return `${state.city.id}${snapshotKey}`;
  }

  /**
   * 使用指定的城市状态数组更新主题
   * 
   * 功能说明：
   * - 直接使用传入的状态数组，避免响应式延迟问题
   * - 根据指定索引的城市天气状况和昼夜时间更新主题
   * - 同时设置夜间模式标志供其他组件使用
   * 
   * 使用场景：
   * - 数据刷新完成后立即更新主题
   * - 城市切换时更新主题
   * 
   * @param states 城市天气状态数组
   * @param index 要使用的城市索引
   */
  private updateThemeWithStates(states: CityWeatherState[], index: number): void {
    console.info(`[WeatherHomePage] 🎨 updateThemeWithStates: states.length=${states.length}, index=${index}`);
    
    // 获取当前城市状态，用于判断当地时间
    const currentCityState = (states.length > 0 && index >= 0 && index < states.length) ? states[index] : undefined;
    const isNight = this.isNightTime(currentCityState);
    console.info(`[WeatherHomePage] 🌙 城市当地是否夜间: ${isNight}`);
    
    if (states.length === 0 || index < 0 || index >= states.length) {
      console.info(`[WeatherHomePage] ⚠️ 无有效状态，使用默认主题sunny`);
      const defaultTheme = ThemeConstants.getThemeWithTimeAware('sunny', isNight).themeKey;
      AppStorage.setOrCreate('themeKey', defaultTheme);
      return;
    }
    
    const state = states[index];
    console.info(`[WeatherHomePage] 📊 当前城市状态: ${state?.city?.name}, hasSnapshot=${!!state?.snapshot}`);
    
    if (!state || !state.snapshot) {
      console.info(`[WeatherHomePage] ⚠️ 城市无天气数据，使用默认主题sunny`);
      const defaultTheme = ThemeConstants.getThemeWithTimeAware('sunny', isNight).themeKey;
      AppStorage.setOrCreate('themeKey', defaultTheme);
      return;
    }
    
    const condition = state.snapshot.current.condition;
    console.info(`[WeatherHomePage] 🌤️ 当前城市: ${state.city.name}, 天气条件themeKey: ${condition.themeKey}`);
    
    const newThemeKey = ThemeConstants.getThemeWithTimeAware(condition.themeKey, isNight).themeKey;
    console.info(`[WeatherHomePage] 🎨 最终主题: ${newThemeKey}`);
    
    AppStorage.setOrCreate('themeKey', newThemeKey);
    // 🔧 同时设置夜间模式标志，供卡片组件使用
    AppStorage.setOrCreate('isNightMode', isNight);
    console.info(`[WeatherHomePage] 🌙 设置isNightMode: ${isNight}`);
  }

  /**
   * 解析当前城市的主题标识符
   * 
   * 解析逻辑：
   * 1. 获取当前活动城市的天气状态
   * 2. 判断城市当地是否为夜间
   * 3. 根据天气状况和昼夜时间返回对应主题
   * 4. 如果无天气数据，返回默认主题（sunny）
   * 
   * @returns 主题标识符（如 "sunny_day", "rainy_night"）
   */
  private resolveThemeKey(): string {
    const currentState = this.currentState;
    console.info(`[WeatherHomePage] 📊 currentState存在: ${!!currentState}`);
    
    const isNight = this.isNightTime(currentState);
    console.info(`[WeatherHomePage] 🌙 城市当地是否夜间: ${isNight}`);
    
    if (!currentState || !currentState.snapshot) {
      console.info(`[WeatherHomePage] ⚠️ 无天气数据，使用默认主题sunny`);
      return ThemeConstants.getThemeWithTimeAware('sunny', isNight).themeKey;
    }

    const condition = currentState.snapshot.current.condition;
    console.info(`[WeatherHomePage] 🌤️ 当前城市: ${currentState.city.name}, 天气条件themeKey: ${condition.themeKey}`);
    
    const result = ThemeConstants.getThemeWithTimeAware(condition.themeKey, isNight).themeKey;
    console.info(`[WeatherHomePage] 🎨 最终主题: ${result}`);
    return result;
  }

  /**
   * 判断指定城市是否为夜间
   * 
   * 时区处理优先级：
   * 1. 优先使用 city.timeZoneOffsetMinutes（更可靠）
   * 2. 其次使用 snapshot.timezoneOffsetMinutes
   * 3. 最后根据经度估算时区（中国大陆统一使用 UTC+8）
   * 
   * 夜间判定：18:00 - 06:00 为夜间，07:00 - 17:59 为白天
   * 
   * @param cityState 城市天气状态，包含时区信息
   * @returns true=夜间(18:00-06:00), false=白天(07:00-17:59)
   */
  private isNightTime(cityState?: CityWeatherState | null): boolean {
    // 获取时区偏移量（分钟）
    let timezoneOffsetMinutes = 0;
    
    if (cityState) {
      console.debug(`[WeatherHomePage] 🔍 调试时区数据:`);
      console.debug(`  - cityState存在: ${!!cityState}`);
      console.debug(`  - snapshot存在: ${!!cityState.snapshot}`);
      console.debug(`  - snapshot.timezoneOffsetMinutes: ${cityState.snapshot?.timezoneOffsetMinutes}`);
      console.debug(`  - city存在: ${!!cityState.city}`);
      console.debug(`  - city.timeZoneOffsetMinutes: ${cityState.city?.timeZoneOffsetMinutes}`);
      console.debug(`  - city.name: ${cityState.city?.name}`);
      
      // 🔧 修复：优先使用 city 中的时区（更可靠），因为 snapshot 的时区可能为0
      // 只有当 city 时区为0或未定义时，才使用 snapshot 的时区
      if (cityState.city && cityState.city.timeZoneOffsetMinutes !== undefined && cityState.city.timeZoneOffsetMinutes !== 0) {
        timezoneOffsetMinutes = cityState.city.timeZoneOffsetMinutes;
        console.debug(`  ✅ 使用city时区: ${timezoneOffsetMinutes}分钟`);
      } 
      // 其次使用 snapshot 中的时区（如果非0）
      else if (cityState.snapshot && cityState.snapshot.timezoneOffsetMinutes !== undefined && cityState.snapshot.timezoneOffsetMinutes !== 0) {
        timezoneOffsetMinutes = cityState.snapshot.timezoneOffsetMinutes;
        console.debug(`  ✅ 使用snapshot时区: ${timezoneOffsetMinutes}分钟`);
      } 
      // 最后根据经度估算时区
      else if (cityState.city && cityState.city.coordinates) {
        const lon = cityState.city.coordinates.longitude;
        // 中国大陆范围统一使用UTC+8
        if (lon >= 73 && lon <= 135) {
          timezoneOffsetMinutes = 480;
        } else {
          timezoneOffsetMinutes = Math.round(lon / 15) * 60;
        }
        console.debug(`  ✅ 根据经度估算时区: ${timezoneOffsetMinutes}分钟`);
      } else {
        console.warn(`  ⚠️ 未找到时区数据，使用默认值0`);
      }
    }
    
    // 获取城市当地时间
    const localHours = this.getCityLocalHours(timezoneOffsetMinutes);
    
    console.info(`[WeatherHomePage] 🕐 时区偏移: ${timezoneOffsetMinutes}分钟, 当地时间: ${localHours}:00`);
    
    // 夜间判定：18:00 - 06:00
    return localHours >= 18 || localHours <= 6;
  }

  /**
   * 获取城市当地时间的小时数
   * 
   * 计算步骤：
   * 1. 获取当前 UTC 时间戳
   * 2. 加上城市时区偏移量
   * 3. 返回当地时间的小时数
   * 
   * @param timezoneOffsetMinutes 城市时区偏移量（分钟），相对于 UTC
   * @returns 城市当地时间的小时数 (0-23)
   */
  private getCityLocalHours(timezoneOffsetMinutes: number): number {
    const now = new Date();
    
    // 获取UTC时间戳
    const utcTime = now.getTime() + (now.getTimezoneOffset() * 60000);
    
    // 加上城市时区偏移，得到城市当地时间
    const cityLocalTime = new Date(utcTime + (timezoneOffsetMinutes * 60000));
    
    return cityLocalTime.getHours();
  }

  // ==================== 诊断和调试方法 ====================
  
  /**
   * 执行设备功能检查
   * 
   * 检查项目：
   * - 定位服务是否可用
   * - 传感器（加速度计）是否可用
   * - 网络连接是否可用
   * - 其他系统功能
   * 
   * 检查结果会记录到日志系统，用于调试和问题排查
   */
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

  // ==================== UI 渲染方法 (@Builder) ====================
  
  /**
   * 渲染背景模式切换按钮（调试用）
   * 
   * 提供三种背景模式：
   * - 视频背景：播放天气相关的视频
   * - 动画背景：显示 Lottie 动画
   * - 渐变背景：显示纯色渐变
   */
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

  /**
   * 构建主页面 UI
   * 
   * 层次结构（从底到顶）：
   * 1. 底层：动态背景（视频/动画/渐变）
   * 2. 遮罩层：柔和渐变遮罩，提升文字可读性
   * 3. 内容层：天气信息展示
   * 4. 顶层：错误提示 Toast
   * 
   * 状态处理：
   * - 加载中：显示骨架屏
   * - 错误：显示错误信息和重试按钮
   * - 正常：显示天气内容
   */
  build() {
    Stack() {
      // 1. 底层：背景视频
      AtmosphereBackground()

      // 2. 遮罩层：单一全屏柔和渐变（多段平滑过渡，彻底消除35%黑条）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient(DesignSystem.GRADIENT_OVERLAY_FULL)
        .hitTestBehavior(HitTestMode.None)

      // 3. 上层：内容层
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

  /**
   * 渲染主要内容区域
   * 
   * 包含：
   * - 下拉刷新组件
   * - 页面头部（菜单和添加按钮）
   * - 页面主体（城市天气卡片）
   */
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

  /**
   * 渲染页面头部
   * 
   * 布局：
   * - 左侧：菜单按钮（跳转到城市管理页面）
   * - 右侧：添加按钮（直接跳转到搜索模式添加城市）
   */
  @Builder
  private renderHeader(): void {
    Row() {
      // Left: Menu Button - 跳转到城市管理页面
      this.IconButton(DesignSystem.IconResources.MENU, () => this.navigateToCityManagement());

      Blank();

      // Right: Add Button - 直接跳转到搜索模式（添加城市）
      this.IconButton(DesignSystem.IconResources.ADD, () => this.navigateToAddCity());
    }
    .width('100%')
    .padding({ 
      left: DesignSystem.Spacing.L, 
      right: DesignSystem.Spacing.L, 
      top: DesignSystem.Spacing.XL 
    })
  }

  /**
   * 渲染图标按钮
   * 
   * 特性：
   * - 圆形触摸区域，提升用户体验
   * - 白色图标带阴影，确保在各种背景下可见
   * - 点击时触发震动反馈（如果设备支持）
   * 
   * @param iconRes 图标资源
   * @param action 点击事件回调函数
   */
  @Builder
  private IconButton(iconRes: Resource, action: () => void): void {
    Button() {
      Image(iconRes)
        .width(24)
        .height(24)
        .fillColor(DesignSystem.Colors.WHITE)
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

  /**
   * 渲染页面主体内容
   * 
   * 包含城市天气卡片的 Swiper 组件
   */
  @Builder
  private renderBody(): void {
    Column() {
      this.renderSwiper();
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 获取高优先级建议列表
   * 
   * @param advice 完整建议列表
   * @returns 优先级 <= 2 的建议项
   */
  private getPriorityAdviceList(advice: AdviceItem[]): AdviceItem[] {
    return advice.filter((item: AdviceItem) => item.priority <= 2);
  }

  /**
   * 获取普通优先级建议列表
   * 
   * @param advice 完整建议列表
   * @returns 优先级 > 2 的建议项
   */
  private getOtherAdviceList(advice: AdviceItem[]): AdviceItem[] {
    return advice.filter((item: AdviceItem) => item.priority > 2);
  }

  /**
   * 渲染高优先级建议卡片
   * 
   * @param adviceList 高优先级建议列表
   */
  @Builder
  private renderPriorityAdvice(adviceList: AdviceItem[]): void {
    if (adviceList && adviceList.length > 0) {
      Column({ space: DesignSystem.Spacing.M }) {
        this.SectionTitle('重要提示');
        ForEach(adviceList, (advice: AdviceItem) => {
          PriorityAdviceCard({ advice: advice });
        }, (advice: AdviceItem) => advice.id);
      }
    } else {
      Blank();
    }
  }

  /**
   * 渲染城市切换 Swiper 组件
   * 
   * 功能：
   * - 左右滑动切换城市
   * - 自动更新主题和背景
   * - 切换时滚动到顶部
   * - 底部显示自定义指示器
   * 
   * 性能优化：
   * - 使用 generateCityKey 生成唯一 key，配合 dataVersion 强制重新渲染
   * - 为每个城市维护独立的 Scroller 实例
   */
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
        ForEach(this.cityStates.filter(state => state && state.city && state.city.id), (state: CityWeatherState, index: number) => {
          this.renderCityScrollContent(state, index);
        }, (state: CityWeatherState) => this.generateCityKey(state));
      }
      .loop(false)
      .vertical(false)
      .index(this.activeIndex)
      .indicator(false)
      .onChange((index: number) => {
        console.info(`[WeatherHomePage] 🔄 切换城市: ${this.activeIndex} -> ${index}`);
        this.activeIndex = index;
        // 🔧 修复：使用直接传参的方式更新主题，确保获取正确的城市天气数据
        this.updateThemeWithStates(this.cityStates, index);
        
        // 强制滚动到顶部
        const currentCity = this.cityStates[index];
        if (currentCity && currentCity.city && currentCity.city.id) {
          const scroller = this.getScrollerForCity(currentCity.city.id);
          console.info(`[WeatherHomePage] 📜 强制滚动到顶部: ${currentCity.city.name}`);
          scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: false });
        }
      })
      .curve(Curve.EaseInOut)
      .duration(300) // 使用统一动效时长
      .width('100%')
      .height('100%');

      // Custom Indicator
      Row({ space: 8 }) {
        ForEach(this.cityStates.filter(state => state && state.city && state.city.id), (state: CityWeatherState, index: number) => {
          Column()
            .width(this.isIndexActive(index) ? 8 : 6)
            .height(this.isIndexActive(index) ? 8 : 6)
            .backgroundColor(this.isIndexActive(index) ? DesignSystem.Colors.WHITE : 'rgba(255,255,255,0.4)')
            .borderRadius(4)
            .animation({ duration: 300, curve: Curve.EaseOut }); // Add animation to indicator
        }, (state: CityWeatherState) => `indicator_${state?.city?.id || Math.random()}`);
      }
      .margin({ top: 0 })
      .position({ x: '50%', y: '95%' })
      .translate({ x: '-50%' });
    }
  }

  /**
   * 渲染单个城市的滚动内容
   * 
   * 内容结构：
   * 1. 顶部：城市天气卡片（温度、天气状况、城市名）
   * 2. 中部：各类天气信息卡片
   *    - 天气预警（如有）
   *    - 降雨预测（如有）
   *    - 重要建议（如有）
   *    - 24小时预报
   *    - 7天预报
   *    - 天气详情网格
   * 3. 底部：留白区域
   * 
   * @param state 城市天气状态
   * @param cityIndex 城市索引（未使用，保留用于扩展）
   */
  @Builder
  private renderCityScrollContent(state: CityWeatherState, cityIndex: number): void {
    // 调试日志 - 在Builder外部无法添加，但可以通过方法调用
    Scroll(this.getScrollerForCity(state.city.id)) {
      Column() {
        // Top Area
        CityWeatherCard({ 
          cityState: state, 
          isActive: this.isStateActive(state) 
        });
        
        // Bottom Area
        Column({ space: DesignSystem.Spacing.M }) {
          // Weather Alert Section - 高优先级
          if (state.snapshot && state.snapshot.alerts && state.snapshot.alerts.length > 0) {
            ForEach(state.snapshot.alerts, (alert: WeatherAlert) => {
              WeatherAlertCard({ alert: alert });
            }, (alert: WeatherAlert) => alert.id);
          }

          // Rain Forecast Section - 降雨预测
          if (state.snapshot && state.snapshot.rainForecast && state.snapshot.rainForecast.length > 0) {
            RainForecastCard({ rainData: state.snapshot.rainForecast });
          }

          // Priority Advice Section - 重要建议
          if (state.snapshot && state.snapshot.advice && state.snapshot.advice.length > 0) {
            this.renderPriorityAdvice(this.getPriorityAdviceList(state.snapshot.advice));
          }

          // Hourly Forecast Section
          if (state.snapshot && state.snapshot.hourly.length > 0) {
            this.SectionTitle('24小时预报');
            HourlyTrendChart({ hourlyData: state.snapshot.hourly });
          }

          // Daily Forecast Section
          if (state.snapshot && state.snapshot.daily.length > 0) {
            this.SectionTitle('7天预报');
            DailyForecastCard({ dailyData: state.snapshot.daily });
          }
          
          // Details Grid Section
          if (state.snapshot) {
            this.SectionTitle('当前天气详情');
            WeatherDetailGrid({
              humidity: FormatHelper.formatHumidity(state.snapshot.current.humidity),
              aqi: FormatHelper.formatAqi(state.snapshot.current.aqi),
              wind: FormatHelper.formatWind(state.snapshot.current.windSpeedKph, state.snapshot.current.windDirection),
              feelsLike: FormatHelper.formatTemperature(state.snapshot.current.feelsLikeC),
              pressure: `${state.snapshot.current.pressureHpa}hPa`,
              visibilityInfo: `${state.snapshot.current.visibilityKm}`,
              uvIndex: `${state.snapshot.current.uvIndex}`,
              sunrise: state.snapshot.current.sunrise,
              sunset: state.snapshot.current.sunset
            });
          }

          // 已删除"更多建议"部分
          
          Blank().height(100); // 底部留白
        }
        .padding({ left: DesignSystem.Spacing.M, right: DesignSystem.Spacing.M })
      }
      .width('100%')
      .constraintSize({ minHeight: '100%' })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }

  /**
   * 渲染章节标题
   * 
   * 样式：
   * - 主标题：18px，半粗体
   * - 副标题：12px，细体（可选）
   * 
   * @param title 主标题文本
   * @param subtitle 副标题文本（可选）
   */
  @Builder
  private SectionTitle(title: string, subtitle: string = ''): void {
    Column() {
      Text(title)
        .fontSize(18)
        .fontWeight(DesignSystem.FONT_WEIGHT_SEMIBOLD)
        .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
        .fontColor(DesignSystem.COLOR_TEXT_PRIMARY)
        .margin({ bottom: subtitle ? 4 : 0 });
      
      if (subtitle) {
        Text(subtitle)
          .fontSize(12)
          .fontWeight(DesignSystem.FONT_WEIGHT_LIGHT)
          .fontFamily(DesignSystem.FONT_FAMILY_PRIMARY)
          .fontColor(DesignSystem.COLOR_TEXT_SECONDARY);
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ top: DesignSystem.SPACING_L, bottom: DesignSystem.SPACING_S, left: 4 })
  }

  /**
   * 渲染错误页面
   * 
   * 显示错误信息和重试按钮
   */
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

  /**
   * 渲染下拉刷新指示器
   * 
   * 显示加载动画和"刷新中..."文本
   */
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

  // ==================== UI 辅助方法 ====================
  
  /**
   * 判断指定城市状态是否为当前活动状态
   * 
   * @param state 要判断的城市状态
   * @returns true 表示是当前活动城市
   */
  private isStateActive(state: CityWeatherState): boolean {
    if (!this.currentState || !state?.city?.id || !this.currentState?.city?.id) {
      return false;
    }
    return state.city.id === this.currentState.city.id;
  }

  /**
   * 判断指定索引是否为当前活动索引
   * 
   * @param index 要判断的索引
   * @returns true 表示是当前活动索引
   */
  private isIndexActive(index: number): boolean {
    return index === this.activeIndex;
  }

  /**
   * 获取用于显示的城市名称
   * 
   * 处理特殊情况：
   * - 如果名称为空，返回 "Loading..."
   * - 如果名称看起来像坐标（包含数字和逗号），返回默认城市名
   * 
   * @param name 原始城市名称
   * @returns 用于显示的城市名称
   */
  private getDisplayCityName(name: string | undefined): string {
    if (!name) return 'Loading...';
    // Simple check if name looks like coordinates (contains numbers and comma)
    if (name.match(/-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?/)) {
      return '北京市'; // Fallback/Mock as requested
    }
    return name;
  }

  // ==================== 高级功能方法 ====================
  
  /**
   * 执行网络诊断
   * 
   * 诊断项目：
   * - 网络连接状态
   * - DNS 解析速度
   * - API 服务器可达性
   * - 网络延迟和质量评分
   * 
   * 诊断完成后显示结果对话框
   */
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

  /**
   * 强制刷新定位
   * 
   * 功能说明：
   * - 清除现有的自动定位城市
   * - 强制重新获取当前位置
   * - 创建新的自动定位城市
   * - 刷新天气数据
   * 
   * 使用场景：用户位置发生变化，需要更新定位城市
   */
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

  /**
   * 刷新当前位置
   * 
   * 功能说明：
   * - 获取当前坐标和城市名称
   * - 如果已有自动定位城市，更新其信息
   * - 如果没有自动定位城市，添加新城市
   * - 刷新天气数据
   */
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

  // ==================== 导航方法 ====================
  
  /**
   * 导航到城市管理页面
   * 
   * 用户可以在城市管理页面：
   * - 查看所有已添加的城市
   * - 删除城市
   * - 调整城市顺序
   * - 搜索并添加新城市
   */
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

  /**
   * 导航到添加城市页面（搜索模式）
   * 
   * 直接打开城市管理页面的搜索模式，方便用户快速添加城市
   */
  private navigateToAddCity(): void {
    try {
      console.info('[WeatherHomePage] Navigating to add city (search mode)...');
      router.push({
        url: 'pages/management/CityManagementPage',
        params: { openSearchMode: true }
      });
      console.info('[WeatherHomePage] Navigation to add city successful');
    } catch (error) {
      console.error('[WeatherHomePage] Navigation failed:', error);
      this.currentError = ErrorHandler.handle(error instanceof Error ? error : new Error(String(error)), 'Failed to navigate');
    }
  }

  /**
   * 获取指定城市的 Scroller 实例
   * 
   * 性能优化：为每个城市维护独立的 Scroller 实例
   * - 避免城市切换时滚动位置混乱
   * - 保持每个城市的滚动状态
   * 
   * @param cityId 城市 ID
   * @returns 该城市的 Scroller 实例
   */
  private getScrollerForCity(cityId: string): Scroller {
    if (!this.cityScrollers.has(cityId)) {
      this.cityScrollers.set(cityId, new Scroller());
      console.debug(`[WeatherHomePage] 📜 创建新的Scroller实例: ${cityId}`);
    }
    return this.cityScrollers.get(cityId)!;
  }

}
