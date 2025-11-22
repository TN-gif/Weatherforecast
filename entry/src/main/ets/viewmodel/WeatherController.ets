import common from '@ohos.app.ability.common';
import { City, CitySource, Coordinates, WeatherSnapshot } from '../data/models/WeatherModels';
import { CityRepository } from '../data/repository/CityRepository';
import { WeatherRepository } from '../data/repository/WeatherRepository';
import { LocationService } from '../data/services/LocationService';
import { AppPreferences } from '../data/storage/AppPreferences';

export class CityWeatherState {
  readonly city: City;
  readonly snapshot: WeatherSnapshot | null;
  readonly isLoading: boolean;
  readonly errorMessage: string;

  constructor(city: City, snapshot: WeatherSnapshot | null, isLoading: boolean, errorMessage: string) {
    this.city = city;
    this.snapshot = snapshot;
    this.isLoading = isLoading;
    this.errorMessage = errorMessage;
  }
}

export class WeatherController {
  private readonly cityRepository: CityRepository;
  private readonly weatherRepository: WeatherRepository;
  private readonly locationService: LocationService;
  private readonly preferences: AppPreferences;
  private initialized: boolean = false;

  constructor(
    cityRepository: CityRepository,
    weatherRepository: WeatherRepository,
    locationService: LocationService,
    preferences: AppPreferences
  ) {
    this.cityRepository = cityRepository;
    this.weatherRepository = weatherRepository;
    this.locationService = locationService;
    this.preferences = preferences;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) {
      console.info('[WeatherController] Already initialized, skipping');
      return;
    }
    
    console.info('[WeatherController] Starting initialization');
    
    try {
      // 并行初始化存储组件
      console.info('[WeatherController] Initializing storage components');
      await Promise.all([
        this.cityRepository.init(context),
        this.weatherRepository.init(context),
        this.preferences.init(context)
      ]);
      
      // 初始化位置服务
      console.info('[WeatherController] Initializing location service');
      this.locationService.init(context);
      
      // 确保有初始城市
      console.info('[WeatherController] Ensuring initial city');
      await this.ensureInitialCity();
      
      this.initialized = true;
      console.info('[WeatherController] Initialization completed successfully');
    } catch (error) {
      console.error('[WeatherController] Initialization failed:', error);
      throw new Error(`Controller initialization failed: ${(error as Error).message}`);
    }
  }

  getCityStates(): CityWeatherState[] {
    const cities: City[] = this.cityRepository.getCities();
    return cities.map(city => new CityWeatherState(city, null, false, ''));
  }

  async loadAll(forceRefresh: boolean): Promise<CityWeatherState[]> {
    console.info(`[WeatherController] ========== 开始加载所有城市天气 ==========`);
    console.info(`[WeatherController] 强制刷新: ${forceRefresh}`);
    console.info(`[WeatherController] 控制器初始化状态: ${this.initialized}`);
    
    const cities: City[] = this.cityRepository.getCities();
    console.info(`[WeatherController] 找到 ${cities.length} 个城市需要加载`);
    
    if (cities.length === 0) {
      console.error('[WeatherController] ❌ 没有找到任何城市数据');
      console.error('[WeatherController] 这可能是因为城市仓库未正确初始化');
      throw new Error('没有找到任何城市数据');
    }
    
    // 打印所有城市信息
    cities.forEach((city, index) => {
      console.info(`[WeatherController] 城市${index + 1}: ${city.name} (${city.id}) - ${JSON.stringify(city.coordinates)}`);
    });
    
    const promises: Promise<CityWeatherState>[] = cities.map(async (city: City, index: number) => {
      try {
        console.info(`[WeatherController] 开始加载城市 ${index + 1}/${cities.length}: ${city.name}`);
        const loadStartTime = Date.now();
        const snapshot: WeatherSnapshot = await this.weatherRepository.loadWeather(city, forceRefresh);
        const loadTime = Date.now() - loadStartTime;
        console.info(`[WeatherController] ✅ 城市 ${city.name} 加载成功，耗时: ${loadTime}ms`);
        return new CityWeatherState(city, snapshot, false, '');
      } catch (error) {
        const err = error as Error;
        console.error(`[WeatherController] ❌ 城市 ${city.name} 加载失败: ${err.message}`);
        return new CityWeatherState(city, null, false, `加载失败: ${err.message}`);
      }
    });
    
    console.info(`[WeatherController] 等待所有城市加载完成...`);
    const results = await Promise.all(promises);
    
    const successCount = results.filter(state => state.snapshot !== null).length;
    const failCount = results.length - successCount;
    console.info(`[WeatherController] ========== 城市加载完成 ==========`);
    console.info(`[WeatherController] 成功: ${successCount}个, 失败: ${failCount}个`);
    
    return results;
  }

  private async ensureInitialCity(): Promise<void> {
    console.info('[WeatherController] Checking for existing cities');
    const existing: City[] = this.cityRepository.getCities();
    if (existing.length > 0) {
      console.info(`[WeatherController] Found ${existing.length} existing cities`);
      return;
    }
    
    console.info('[WeatherController] No existing cities, creating initial city');
    const autoLocationEnabled: boolean = await this.preferences.isAutoLocationEnabled();
    
    if (autoLocationEnabled) {
      try {
        console.info('[WeatherController] ========== 开始自动定位流程 ==========');
        console.info('[WeatherController] 🎯 自动定位已启用，开始获取当前位置');
        
        const coordinates: Coordinates = await this.locationService.getCurrentLocation();
        console.info(`[WeatherController] ✅ 坐标获取成功: ${coordinates.latitude}, ${coordinates.longitude}`);
        
        console.info('[WeatherController] 🗺️ 开始解析城市名称...');
        const cityName: string = await this.locationService.getCityNameFromCoordinates(coordinates);
        console.info(`[WeatherController] ✅ 城市名称解析成功: ${cityName}`);
        
        console.info('[WeatherController] 🏙️ 创建自动定位城市...');
        const autoCity: City = this.createAutoCity(coordinates, cityName);
        console.info(`[WeatherController] 📍 自动城市信息: ID=${autoCity.id}, 名称=${autoCity.name}, 坐标=${autoCity.coordinates.latitude},${autoCity.coordinates.longitude}`);
        
        await this.cityRepository.addCity(autoCity);
        console.info(`[WeatherController] ✅ 自动定位城市添加成功: ${cityName}`);
        console.info('[WeatherController] ========== 自动定位流程完成 ==========');
        return;
      } catch (error) {
        console.error('[WeatherController] ❌ 自动定位失败，切换到默认城市');
        console.error('[WeatherController] 错误详情:', error);
      }
    } else {
      console.info('[WeatherController] 🚫 自动定位已禁用，使用默认城市');
    }
    
    console.info('[WeatherController] Adding default city (Shanghai)');
    await this.cityRepository.updateCities([CityRepository.createDefaultCity()]);
    console.info('[WeatherController] Default city added successfully');
  }

  private createAutoCity(coordinates: Coordinates, cityName: string): City {
    const id: string = `auto_${Math.round(coordinates.latitude * 1000)}_${Math.round(coordinates.longitude * 1000)}`;
    return new City(id, cityName, 'Auto', coordinates, CitySource.AUTO, 'sunny', 0);
  }
}
