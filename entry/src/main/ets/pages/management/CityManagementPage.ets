import router from '@ohos.router';
import { City, CitySource, WeatherSnapshot } from '../../data/models/WeatherModels';
import { CityRepository } from '../../data/repository/CityRepository';
import { CitySearchService, CitySearchResult } from '../../data/services/CitySearchService';
import { ErrorToast, ErrorMessage, ErrorHandler } from '../../components/common/ErrorToast';
import { AppContextHolder } from '../../common/di/AppContextHolder';
import { DesignSystem } from '../../common/theme/DesignSystem';
import { ThemeConstants } from '../../common/constants/ThemeConstants';
import { WeatherCacheStorage } from '../../data/storage/WeatherCacheStorage';

// 路由参数接口
interface RouterParams {
  openSearchMode?: boolean;
}

// 城市与天气数据的组合
interface CityWeatherInfo {
  city: City;
  snapshot: WeatherSnapshot | null;
  videoPath: string;
  isNight: boolean;
}

@Entry
@Component
struct CityManagementPage {
  @State private cities: City[] = [];
  @State private cityWeatherInfos: CityWeatherInfo[] = [];
  @State private isLoading: boolean = true;
  @State private isSearchMode: boolean = false;
  @State private currentError: ErrorMessage | null = null;
  @State private isAddingCity: boolean = false;
  @State private isDragging: boolean = false;
  @State private dragIndex: number = -1;

  private cityRepository: CityRepository = CityRepository.getInstance();
  private searchService: CitySearchService = CitySearchService.getInstance();
  private weatherCache: WeatherCacheStorage = WeatherCacheStorage.getInstance();

  aboutToAppear(): void {
    console.info('[CityManagementPage] ========== 城市管理页面显示 ==========');
    
    // 检查是否需要直接打开搜索模式
    const params = router.getParams() as RouterParams | undefined;
    if (params && params.openSearchMode === true) {
      console.info('[CityManagementPage] 📍 从路由参数检测到需要打开搜索模式');
      this.isSearchMode = true;
    }
    
    this.loadCitiesWithWeather();
  }

  build() {
    Stack() {
      // 纯白背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F7FA')

      // 内容层
      Column() {
        // 头部导航栏
        this.buildHeader()

        // 搜索区域（搜索模式下显示）
        if (this.isSearchMode) {
          this.buildSearchSection()
        }

        // 城市列表
        if (this.isLoading) {
          this.buildLoading()
        } else {
          this.buildCityList()
        }
      }
      .width('100%')
      .height('100%')

      // 错误提示
      ErrorToast({ errorMessage: $currentError })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildHeader(): void {
    Row() {
      // 返回按钮
      Button() {
        Image(DesignSystem.IconResources.BACK)
          .width(24)
          .height(24)
          .fillColor('#333333')
      }
      .width(44)
      .height(44)
      .backgroundColor(Color.Transparent)
      .type(ButtonType.Circle)
      .onClick(() => {
        router.back();
      })

      // 标题
      Text('城市管理')
        .fontSize(20)
        .fontWeight(DesignSystem.FontWeight.SEMIBOLD)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 搜索/关闭按钮
      Button() {
        Image(this.isSearchMode ? DesignSystem.IconResources.CLOSE : DesignSystem.IconResources.ADD)
          .width(24)
          .height(24)
          .fillColor('#333333')
      }
      .width(44)
      .height(44)
      .backgroundColor(Color.Transparent)
      .type(ButtonType.Circle)
      .onClick(() => {
        this.toggleSearchMode();
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: DesignSystem.Spacing.M, right: DesignSystem.Spacing.M, top: DesignSystem.Spacing.S })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private buildSearchSection(): void {
    Column() {
      this.buildLightSearchBar()
      this.buildPopularCities()
    }
    .width('100%')
    .padding(DesignSystem.Spacing.M)
    .backgroundColor('#FFFFFF')
    .margin({ top: 1 })
    .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: -20 } })
    .transition({ type: TransitionType.Delete, opacity: 0, translate: { y: -20 } })
  }

  @Builder
  private buildLightSearchBar(): void {
    Row() {
      Image(DesignSystem.IconResources.SEARCH)
        .width(20)
        .height(20)
        .fillColor('#999999')
        .margin({ right: 12 })

      TextInput({ placeholder: '搜索城市名称...' })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .fontSize(16)
        .fontColor('#333333')
        .placeholderColor('#999999')
        .onChange((value: string) => {
          this.onSearchTextChange(value);
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F0F0F5')
    .borderRadius(24)
    .alignItems(VerticalAlign.Center)
  }

  @State private searchText: string = '';
  @State private searchResults: CitySearchResult[] = [];
  @State private isSearching: boolean = false;
  private searchTimeoutId: number = -1;

  private onSearchTextChange(value: string): void {
    this.searchText = value;
    
    if (this.searchTimeoutId !== -1) {
      clearTimeout(this.searchTimeoutId);
    }

    if (value.length < 2) {
      this.searchResults = [];
      return;
    }

    this.searchTimeoutId = setTimeout(() => {
      this.performSearch(value);
    }, 300);
  }

  private async performSearch(keyword: string): Promise<void> {
    this.isSearching = true;
    try {
      const results = await this.searchService.searchCities(keyword);
      this.searchResults = results;
    } catch (error) {
      console.error('[CityManagementPage] Search failed:', error);
    } finally {
      this.isSearching = false;
    }
  }

  @Builder
  private buildPopularCities(): void {
    Column() {
      if (this.searchResults.length > 0) {
        Text('搜索结果')
          .fontSize(14)
          .fontWeight(DesignSystem.FontWeight.MEDIUM)
          .fontColor('#666666')
          .margin({ top: DesignSystem.Spacing.M, bottom: DesignSystem.Spacing.S })
          .alignSelf(ItemAlign.Start)

        List() {
          ForEach(this.searchResults, (result: CitySearchResult) => {
            ListItem() {
              Row() {
                Column() {
                  Text(this.getSearchResultDisplayName(result))
                    .fontSize(16)
                    .fontColor('#333333')
                    .fontWeight(DesignSystem.FontWeight.MEDIUM)
                  Text(this.getSearchResultSubtitle(result))
                    .fontSize(13)
                    .fontColor('#666666')
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Image(DesignSystem.IconResources.ADD)
                  .width(20)
                  .height(20)
                  .fillColor('#007AFF')
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                this.addCity(result);
              })
            }
          }, (result: CitySearchResult) => result.id)
        }
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
        .constraintSize({ maxHeight: 200 })
      } else {
        Text('热门城市')
          .fontSize(14)
          .fontWeight(DesignSystem.FontWeight.MEDIUM)
          .fontColor('#666666')
          .margin({ top: DesignSystem.Spacing.L, bottom: DesignSystem.Spacing.S })
          .alignSelf(ItemAlign.Start)

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.searchService.getPopularCities(), (city: CitySearchResult) => {
            Text(city.name)
              .fontSize(14)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor('#F0F0F5')
              .borderRadius(20)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.addCity(city);
              })
          }, (city: CitySearchResult) => city.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildLoading(): void {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#666666')
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildCityList(): void {
    List({ space: DesignSystem.Spacing.M }) {
      ForEach(this.cityWeatherInfos, (info: CityWeatherInfo, index: number) => {
        ListItem() {
          this.buildCityCard(info, index)
        }
        .swipeAction({
          end: this.buildDeleteButton(info.city, index)
        })
      }, (info: CityWeatherInfo) => info.city.id)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({
      left: DesignSystem.Spacing.M,
      right: DesignSystem.Spacing.M,
      top: DesignSystem.Spacing.M,
      bottom: DesignSystem.Spacing.XXL
    })
    .scrollBar(BarState.Off)
    .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
      console.info(`[CityManagementPage] 🎯 开始拖动: index=${itemIndex}`);
      this.isDragging = true;
      this.dragIndex = itemIndex;
      return this.buildDragPreview(this.cityWeatherInfos[itemIndex].city);
    })
    .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
      console.info(`[CityManagementPage] 📍 拖动结束: from=${itemIndex}, to=${insertIndex}, success=${isSuccess}`);
      if (isSuccess && itemIndex !== insertIndex) {
        this.reorderCities(itemIndex, insertIndex);
      }
      this.isDragging = false;
      this.dragIndex = -1;
    })
  }

  @Builder
  private buildDragPreview(city: City): void {
    Row() {
      Text(this.getCityDisplayName(city))
        .fontSize(18)
        .fontColor('#FFFFFF')
        .fontWeight(DesignSystem.FontWeight.MEDIUM)
    }
    .width(200)
    .height(60)
    .padding(DesignSystem.Spacing.M)
    .backgroundColor('rgba(0, 122, 255, 0.9)')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildCityCard(info: CityWeatherInfo, index: number): void {
    Stack() {
      // 背景视频层 - 优化：降低视频质量设置以提升性能
      Video({ src: $rawfile(info.videoPath) })
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .autoPlay(true)
        .loop(true)
        .muted(true)
        .controls(false)
        .borderRadius(20)

      // 遮罩层 - 统一使用深色遮罩，确保白色文字可读
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(info.isNight ? 'rgba(0, 0, 0, 0.30)' : 'rgba(0, 0, 0, 0.25)')
        .borderRadius(20)

      // 内容层
      Row() {
        // 左侧：城市信息
        Column() {
          Row() {
            Text(this.getCityDisplayName(info.city))
              .fontSize(22)
              .fontColor('#FFFFFF')
              .fontWeight(DesignSystem.FontWeight.SEMIBOLD)
              .textShadow({ radius: 4, color: 'rgba(0,0,0,0.35)', offsetX: 0, offsetY: 1 })

            // 定位图标
            if (info.city.source === CitySource.AUTO) {
              Image(DesignSystem.IconResources.LOCATION_PIN)
                .width(16)
                .height(16)
                .fillColor('#FFFFFF')
                .margin({ left: 6 })
            }
          }

          // 显示天气信息
          if (info.snapshot) {
            Text(`${Math.round(info.snapshot.current.temperatureC)}° ${info.snapshot.current.condition.description}`)
              .fontSize(14)
              .fontColor('rgba(255, 255, 255, 0.90)')
              .margin({ top: 4 })
              .textShadow({ radius: 3, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 1 })
          } else {
            Text(this.getCitySubtitle(info.city))
              .fontSize(13)
              .fontColor('rgba(255, 255, 255, 0.80)')
              .margin({ top: 4 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 右侧：拖动手柄
        if (index > 0) {
          Image(DesignSystem.IconResources.REORDER)
            .width(24)
            .height(24)
            .fillColor('rgba(255, 255, 255, 0.70)')
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: DesignSystem.Spacing.L, right: DesignSystem.Spacing.L })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(100)
    .borderRadius(20)
    .clip(true)
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetY: 4,
      offsetX: 0
    })
    .opacity(this.isDragging && this.dragIndex === index ? 0.5 : 1)
    .onClick(() => {
      // 点击卡片跳转到对应城市的天气页面
      this.navigateToCityWeather(index);
    })
  }

  @Builder
  private buildDeleteButton(city: City, index: number): void {
    if (index === 0) {
      Column()
        .width(0)
        .height(0)
    } else {
      Button() {
        Image(DesignSystem.IconResources.CLOSE)
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
      .width(70)
      .height(90)
      .backgroundColor('#FF3B30')
      .borderRadius(16)
      .margin({ left: 8 })
      .onClick(() => {
        this.deleteCity(city, index);
      })
    }
  }

  // ========== 导航方法 ==========

  /**
   * 点击城市卡片，跳转到主页并切换到对应城市
   */
  private navigateToCityWeather(cityIndex: number): void {
    console.info(`[CityManagementPage] 🏠 点击城市卡片，跳转到城市索引: ${cityIndex}`);
    
    // 设置要跳转的城市索引
    AppStorage.setOrCreate('navigateToCityIndex', cityIndex);
    AppStorage.setOrCreate('needRefreshWeather', true);
    
    // 返回主页
    router.back();
  }

  // ========== 辅助方法 ==========

  private getVideoPathForCityWeather(city: City, snapshot: WeatherSnapshot | null): string {
    let weatherThemeKey = 'sunny';
    
    if (snapshot && snapshot.current && snapshot.current.condition) {
      weatherThemeKey = snapshot.current.condition.themeKey || 'sunny';
    } else if (city.videoTheme) {
      weatherThemeKey = city.videoTheme;
    }
    
    const isNight = this.isNightTimeForCity(city, snapshot);
    const theme = ThemeConstants.getThemeWithTimeAware(weatherThemeKey, isNight);
    let videoPath = theme.videoResource || 'rawfile/weather/sunny_day.mp4';
    
    if (videoPath.startsWith('rawfile/')) {
      videoPath = videoPath.substring(8);
    }
    
    console.info(`[CityManagementPage] 🎬 城市 ${city.name} 视频路径: ${videoPath} (天气: ${weatherThemeKey}, 夜间: ${isNight})`);
    
    return videoPath;
  }

  private isNightTimeForCity(city: City, snapshot: WeatherSnapshot | null): boolean {
    let timezoneOffsetMinutes = 0;
    
    if (city.timeZoneOffsetMinutes !== undefined && city.timeZoneOffsetMinutes !== 0) {
      timezoneOffsetMinutes = city.timeZoneOffsetMinutes;
    } else if (snapshot && snapshot.timezoneOffsetMinutes !== undefined && snapshot.timezoneOffsetMinutes !== 0) {
      timezoneOffsetMinutes = snapshot.timezoneOffsetMinutes;
    } else if (city.coordinates) {
      const lon = city.coordinates.longitude;
      if (lon >= 73 && lon <= 135) {
        timezoneOffsetMinutes = 480;
      } else {
        timezoneOffsetMinutes = Math.round(lon / 15) * 60;
      }
    }
    
    const now = new Date();
    const utcTime = now.getTime() + (now.getTimezoneOffset() * 60000);
    const cityLocalTime = new Date(utcTime + (timezoneOffsetMinutes * 60000));
    const localHours = cityLocalTime.getHours();
    
    return localHours >= 18 || localHours <= 6;
  }

  /**
   * 获取搜索结果的显示名称（大字部分）
   * 
   * @param result 搜索结果
   * @returns 显示名称
   */
  private getSearchResultDisplayName(result: CitySearchResult): string {
    const name = result.name;
    
    // 如果没有逗号，直接返回
    if (!name.includes(',')) {
      return name;
    }
    
    // 分割城市名称，只返回第一部分
    const parts = name.split(',').map(part => part.trim());
    return parts[0];
  }

  /**
   * 获取搜索结果的副标题（小字部分）
   * 
   * @param result 搜索结果
   * @returns 副标题
   */
  private getSearchResultSubtitle(result: CitySearchResult): string {
    const name = result.name;
    
    // 如果没有逗号，显示国家
    if (!name.includes(',')) {
      return result.country;
    }
    
    // 分割城市名称
    const parts = name.split(',').map(part => part.trim());
    
    // 如果只有2部分
    if (parts.length === 2) {
      // 如果第二部分是"中国"或"China"，不显示（避免冗余）
      if (parts[1] === '中国' || parts[1] === 'China') {
        return '';
      }
      // 否则显示第二部分
      return parts[1];
    }
    
    // 如果有3部分（如"路南区, 唐山市, 河北省"）
    if (parts.length === 3) {
      // 对于中国城市，显示"省 市"的格式
      if (result.country === '中国' || result.country === 'China') {
        return `${parts[2]} ${parts[1]}`;
      }
      // 对于国际城市，显示"州/省, 国家"
      return `${parts[1]}, ${parts[2]}`;
    }
    
    // 如果有更多部分，显示后面的部分
    return parts.slice(1).join(', ');
  }

  /**
   * 获取城市显示名称（大字部分）
   * 
   * 智能处理城市名称显示：
   * - 对于中国城市，显示城市名称的主要部分
   * - 对于国际城市，显示城市名称
   * 
   * 例如：
   * - "唐山, 河北省" → "唐山"
   * - "路南区, 唐山市, 河北省" → "路南区"
   * - "北京, 中国" → "北京"
   * 
   * @param city 城市对象
   * @returns 城市显示名称
   */
  private getCityDisplayName(city: City): string {
    const name = city.name;
    
    // 如果没有逗号，直接返回
    if (!name.includes(',')) {
      return name;
    }
    
    // 分割城市名称，只返回第一部分
    const parts = name.split(',').map(part => part.trim());
    return parts[0];
  }

  /**
   * 获取城市副标题（小字部分）
   * 
   * 显示完整的行政区划信息或位置标识：
   * - 定位城市：显示"当前位置"
   * - 中国城市：显示"省 市"格式（如"河北省 唐山市"）
   * - 国际城市：显示"州/省, 国家"
   * 
   * 例如：
   * - GPS定位 → "当前位置"
   * - "唐山, 河北省" → "河北省"
   * - "路南区, 唐山市, 河北省" → "河北省 唐山市"
   * - "北京, 中国" → ""（不显示国家）
   * - "Manhattan, New York, United States" → "New York, United States"
   * 
   * @param city 城市对象
   * @returns 城市副标题
   */
  private getCitySubtitle(city: City): string {
    // 定位城市显示"当前位置"
    if (city.source === CitySource.AUTO) {
      return '当前位置';
    }
    
    const name = city.name;
    
    // 如果没有逗号，尝试显示国家
    if (!name.includes(',')) {
      return city.country || '';
    }
    
    // 分割城市名称
    const parts = name.split(',').map(part => part.trim());
    
    // 如果只有2部分
    if (parts.length === 2) {
      // 如果第二部分是"中国"或"China"，不显示（避免冗余）
      if (parts[1] === '中国' || parts[1] === 'China') {
        return '';
      }
      // 否则显示第二部分（如国家名）
      return parts[1];
    }
    
    // 如果有3部分（如"路南区, 唐山市, 河北省"）
    if (parts.length === 3) {
      // 对于中国城市，显示"省 市"的格式
      if (city.country === '中国' || city.country === 'China') {
        return `${parts[2]} ${parts[1]}`;
      }
      // 对于国际城市，显示"州/省, 国家"
      return `${parts[1]}, ${parts[2]}`;
    }
    
    // 如果有更多部分，显示后面的部分
    return parts.slice(1).join(', ');
  }

  private async reorderCities(fromIndex: number, toIndex: number): Promise<void> {
    console.info(`[CityManagementPage] 🔄 重新排序城市: ${fromIndex} -> ${toIndex}`);
    
    if (fromIndex === 0 || toIndex === 0) {
      console.warn('[CityManagementPage] ⚠️ 不允许移动定位城市');
      this.currentError = ErrorHandler.createWarningMessage('定位城市无法移动');
      return;
    }

    try {
      const newInfos = [...this.cityWeatherInfos];
      const movedInfo = newInfos.splice(fromIndex, 1)[0];
      newInfos.splice(toIndex, 0, movedInfo);
      this.cityWeatherInfos = newInfos;
      
      const newCities = newInfos.map(info => info.city);
      this.cities = newCities;
      await this.cityRepository.updateCities(newCities);
      
      AppStorage.setOrCreate('needRefreshWeather', true);
      AppStorage.setOrCreate('cityOrderChanged', true);
      
      console.info('[CityManagementPage] ✅ 城市顺序已更新');
    } catch (error) {
      console.error('[CityManagementPage] ❌ 重新排序失败:', error);
      this.currentError = ErrorHandler.handle(error as Error, '排序失败');
      await this.loadCitiesWithWeather();
    }
  }

  // ========== 数据操作方法 ==========

  private async loadCitiesWithWeather(): Promise<void> {
    try {
      console.info('[CityManagementPage] 🔄 开始加载城市列表和天气数据...');
      this.isLoading = true;

      const context = AppContextHolder.getContext();
      if (context) {
        await this.cityRepository.init(context);
        await this.weatherCache.init(context);
      }

      this.cities = await this.cityRepository.getAllCities();
      console.info(`[CityManagementPage] ✅ 城市列表加载完成，共 ${this.cities.length} 个城市`);

      const infos: CityWeatherInfo[] = [];
      for (const city of this.cities) {
        const snapshot = await this.weatherCache.loadSnapshot(city.id);
        const isNight = this.isNightTimeForCity(city, snapshot);
        const videoPath = this.getVideoPathForCityWeather(city, snapshot);
        const info: CityWeatherInfo = {
          city: city,
          snapshot: snapshot,
          videoPath: videoPath,
          isNight: isNight
        };
        infos.push(info);
        console.info(`[CityManagementPage]   - ${city.name}: 缓存=${snapshot ? '有' : '无'}, 夜间=${isNight}, 视频=${videoPath}`);
      }
      this.cityWeatherInfos = infos;

      this.searchService.setExistingCities(this.cities.map(city => city.id));
    } catch (error) {
      console.error('[CityManagementPage] ❌ 加载城市失败:', error);
      this.currentError = ErrorHandler.handle(error as Error, '加载城市列表失败');
    } finally {
      this.isLoading = false;
    }
  }

  private async addCity(searchResult: CitySearchResult): Promise<void> {
    if (this.isAddingCity) {
      return;
    }

    console.info(`[CityManagementPage] ➕ 准备添加城市: ${searchResult.name}`);

    try {
      this.isAddingCity = true;
      const city = this.searchService.convertToCity(searchResult);

      await this.cityRepository.addCity(city);
      console.info(`[CityManagementPage] ✅ 城市添加成功: ${city.name}`);

      await this.loadCitiesWithWeather();
      this.isSearchMode = false;
      this.searchText = '';
      this.searchResults = [];

      this.currentError = ErrorHandler.createInfoMessage(`已添加 ${city.name}`);

      AppStorage.setOrCreate('needRefreshWeather', true);
      AppStorage.setOrCreate('newAddedCityId', city.id);

      setTimeout(() => {
        router.back();
      }, 300);
    } catch (error) {
      console.error('[CityManagementPage] ❌ 添加城市失败:', error);
      this.currentError = ErrorHandler.handle(error as Error, '添加城市失败');
    } finally {
      this.isAddingCity = false;
    }
  }

  private async deleteCity(city: City, index: number): Promise<void> {
    console.info(`[CityManagementPage] 🗑️ 请求删除城市: ${city.name}`);

    if (index === 0) {
      this.currentError = ErrorHandler.createWarningMessage('无法删除当前定位城市');
      return;
    }

    try {
      await this.cityRepository.removeCity(city.id);
      console.info(`[CityManagementPage] ✅ 城市删除成功: ${city.name}`);

      await this.loadCitiesWithWeather();
      
      AppStorage.setOrCreate('needRefreshWeather', true);
      
      this.currentError = ErrorHandler.createInfoMessage(`已删除 ${city.name}`);
    } catch (error) {
      console.error('[CityManagementPage] ❌ 删除城市失败:', error);
      this.currentError = ErrorHandler.handle(error as Error, '删除城市失败');
    }
  }

  private toggleSearchMode(): void {
    this.isSearchMode = !this.isSearchMode;
    if (!this.isSearchMode) {
      this.searchText = '';
      this.searchResults = [];
    }
    console.info(`[CityManagementPage] 🔍 切换搜索模式: ${this.isSearchMode ? '开启' : '关闭'}`);
  }
}
