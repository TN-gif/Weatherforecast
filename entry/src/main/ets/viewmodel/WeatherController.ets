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
      console.info('[WeatherController] ⚠️ 控制器已初始化，跳过重复初始化');
      return;
    }
    
    console.info('[WeatherController] ========== 开始控制器初始化 ==========');
    const startTime = Date.now();
    
    try {
      // 并行初始化存储组件
      console.info('[WeatherController] 📦 初始化存储组件...');
      const storageStartTime = Date.now();
      await Promise.all([
        this.cityRepository.init(context),
        this.weatherRepository.init(context),
        this.preferences.init(context)
      ]);
      console.debug(`[WeatherController] ✅ 存储组件初始化完成，耗时: ${Date.now() - storageStartTime}ms`);
      
      // 🔧 修复：更新所有现有城市的时区数据
      console.info('[WeatherController] 🕒 检查并更新城市时区数据...');
      await this.updateCityTimezones();
      
      // 初始化位置服务
      console.info('[WeatherController] 📍 初始化位置服务...');
      this.locationService.init(context);
      
      // 每次启动都更新定位
      console.info('[WeatherController] 🎯 每次启动都进行GPS定位更新...');
      await this.updateAutoLocationCity();
      
      this.initialized = true;
      console.info(`[WeatherController] ✅ 控制器初始化成功，总耗时: ${Date.now() - startTime}ms`);
    } catch (error) {
      console.error('[WeatherController] ❌ 初始化失败:', error);
      throw new Error(`Controller initialization failed: ${(error as Error).message}`);
    }
  }

  /**
   * 更新所有城市的时区数据
   * 用于修复旧数据中时区为0的问题
   */
  private async updateCityTimezones(): Promise<void> {
    const cities: City[] = this.cityRepository.getCities();
    let needUpdate = false;
    
    const updatedCities: City[] = cities.map((city: City) => {
      // 如果时区为0，说明是旧数据，需要更新
      if (city.timeZoneOffsetMinutes === 0) {
        needUpdate = true;
        const newTimezone = this.estimateTimezone(city.coordinates);
        console.info(`[WeatherController] 🔧 更新城市时区: ${city.name}, 0 -> ${newTimezone}分钟`);
        return new City(
          city.id,
          city.name,
          city.country,
          city.coordinates,
          city.source,
          city.videoTheme,
          newTimezone
        );
      }
      return city;
    });
    
    if (needUpdate) {
      await this.cityRepository.updateCities(updatedCities);
      console.info('[WeatherController] ✅ 城市时区数据更新完成');
    } else {
      console.info('[WeatherController] ✅ 所有城市时区数据正常，无需更新');
    }
  }

  /**
   * 根据经纬度估算时区
   */
  private estimateTimezone(coordinates: Coordinates): number {
    // 中国大陆统一使用UTC+8（东八区），经度范围约73°E-135°E
    if (coordinates.longitude >= 73 && coordinates.longitude <= 135 && 
        coordinates.latitude >= 18 && coordinates.latitude <= 54) {
      return 480; // UTC+8 = 480分钟
    }
    
    // 其他地区，按经度估算（每15度=1小时）
    return Math.round(coordinates.longitude / 15) * 60;
  }

  getCityStates(): CityWeatherState[] {
    const cities: City[] = this.cityRepository.getCities();
    return cities.map(city => new CityWeatherState(city, null, false, ''));
  }

  async loadAll(forceRefresh: boolean): Promise<CityWeatherState[]> {
    console.info(`[WeatherController] ========== 开始加载所有城市天气 ==========`);
    console.info(`[WeatherController] 🔄 强制刷新: ${forceRefresh}`);
    console.debug(`[WeatherController] ⚙️ 控制器状态: initialized=${this.initialized}`);
    const loadStartTime = Date.now();
    
    // 如果是强制刷新，尝试更新GPS定位（但不阻塞天气加载）
    if (forceRefresh) {
      console.info('[WeatherController] 🎯 强制刷新时尝试更新GPS定位（异步，不阻塞）...');
      // 使用异步方式更新定位，不等待结果
      this.updateAutoLocationCity().catch((error: Error) => {
        console.warn('[WeatherController] ⚠️ GPS定位更新失败（不影响天气加载）:', error.message);
      });
    }
    
    // 重新获取城市列表（可能已被异步更新）
    const cities: City[] = this.cityRepository.getCities();
    console.info(`[WeatherController] 📋 待加载城市列表 (${cities.length}个):`);
    cities.forEach((city, index) => {
      console.info(`  ${index + 1}. ${city.name} [${city.id}] (${city.source})`);
    });
    
    if (cities.length === 0) {
      console.error('[WeatherController] ❌ 城市列表为空，无法加载天气');
      throw new Error('没有找到任何城市数据');
    }
    
    const startTime = Date.now();
    console.info(`[WeatherController] ⏳ 开始并行加载 ${cities.length} 个城市的天气数据...`);
    
    const promises: Promise<CityWeatherState>[] = cities.map(async (city: City, index: number) => {
      try {
        console.info(`[WeatherController] [${index + 1}/${cities.length}] ⏳ 开始加载: ${city.name}`);
        const cityStartTime = Date.now();
        
        // 为每个城市的天气加载添加超时控制（15秒）
        const weatherPromise = this.weatherRepository.loadWeather(city, forceRefresh);
        const timeoutPromise = new Promise<WeatherSnapshot>((_, reject) => {
          setTimeout(() => reject(new Error('天气数据加载超时')), 15000);
        });
        
        const snapshot: WeatherSnapshot = await Promise.race([weatherPromise, timeoutPromise]);
        
        const cityDuration = Date.now() - cityStartTime;
        console.info(`[WeatherController] [${index + 1}/${cities.length}] ✅ 加载成功: ${city.name}, 耗时: ${cityDuration}ms`);
        return new CityWeatherState(city, snapshot, false, '');
      } catch (error) {
        const err = error as Error;
        console.error(`[WeatherController] [${index + 1}/${cities.length}] ❌ 加载失败: ${city.name}, 错误: ${err.message}`);
        return new CityWeatherState(city, null, false, `加载失败: ${err.message}`);
      }
    });
    
    console.info(`[WeatherController] ⏳ 等待所有城市加载完成...`);
    const results = await Promise.all(promises);
    
    const successCount = results.filter(state => state.snapshot !== null).length;
    const failCount = results.length - successCount;
    const totalDuration = Date.now() - startTime;
    
    console.info(`[WeatherController] ========== 批量加载完成 ==========`);
    console.info(`[WeatherController] 📊 统计: 总数=${results.length}, 成功=${successCount}, 失败=${failCount}, 总耗时=${totalDuration}ms`);
    console.info(`[WeatherController] 📊 loadAll总耗时: ${Date.now() - loadStartTime}ms`);
    
    return results;
  }

  private async updateAutoLocationCity(): Promise<void> {
    console.info('[WeatherController] ========== 更新自动定位城市 ==========');
    
    const autoLocationEnabled: boolean = await this.preferences.isAutoLocationEnabled();
    console.debug(`[WeatherController] 自动定位开关状态: ${autoLocationEnabled}`);
    
    if (!autoLocationEnabled) {
      console.info('[WeatherController] 🚫 自动定位已禁用，跳过定位更新');
      await this.ensureDefaultCity();
      return;
    }
    
    try {
      console.info('[WeatherController] 📡 获取当前GPS位置（超时10秒）...');
      
      // 添加超时控制，避免长时间等待
      const locationPromise = this.locationService.getCurrentLocation();
      const timeoutPromise = new Promise<Coordinates>((_, reject) => {
        setTimeout(() => reject(new Error('GPS定位超时')), 10000);
      });
      
      const coordinates: Coordinates = await Promise.race([locationPromise, timeoutPromise]);
      console.info(`[WeatherController] ✅ 坐标获取成功: ${coordinates.latitude.toFixed(4)}, ${coordinates.longitude.toFixed(4)}`);
      
      console.info('[WeatherController] 🗺️ 解析城市名称（超时5秒）...');
      const cityNamePromise = this.locationService.getCityNameFromCoordinates(coordinates);
      const cityNameTimeoutPromise = new Promise<string>((_, reject) => {
        setTimeout(() => reject(new Error('城市名称解析超时')), 5000);
      });
      
      const cityName: string = await Promise.race([cityNamePromise, cityNameTimeoutPromise]);
      console.info(`[WeatherController] ✅ 城市名称解析成功: ${cityName}`);
      
      console.info('[WeatherController] 🏗️ 创建/更新自动定位城市对象...');
      const autoCity: City = this.createAutoCity(coordinates, cityName);
      
      // 获取现有城市列表
      const existingCities: City[] = this.cityRepository.getCities();
      const nonAutoCities: City[] = existingCities.filter((city: City) => city.source !== CitySource.AUTO);
      
      // 将自动定位城市放在第一位
      const updatedCities: City[] = [autoCity, ...nonAutoCities];
      await this.cityRepository.updateCities(updatedCities);
      
      console.info(`[WeatherController] ✅ 自动定位城市已更新: ${cityName}`);
      console.info('[WeatherController] ========== 自动定位更新成功 ==========');
    } catch (error) {
      console.error('[WeatherController] ❌ 自动定位失败，确保有默认城市');
      console.error('[WeatherController] 错误详情:', error);
      await this.ensureDefaultCity();
    }
  }

  private async ensureDefaultCity(): Promise<void> {
    console.info('[WeatherController] 🔍 检查是否存在已保存城市...');
    const existing: City[] = this.cityRepository.getCities();
    if (existing.length > 0) {
      console.info(`[WeatherController] ✅ 发现 ${existing.length} 个已保存城市，无需添加默认城市`);
      return;
    }
    
    console.info('[WeatherController] 🏠 添加默认城市 (上海)...');
    await this.cityRepository.updateCities([CityRepository.createDefaultCity()]);
    console.info('[WeatherController] ✅ 默认城市添加成功');
  }

  private createAutoCity(coordinates: Coordinates, cityName: string): City {
    const id: string = `auto_${Math.round(coordinates.latitude * 1000)}_${Math.round(coordinates.longitude * 1000)}`;
    
    // 🔧 修复：使用更精确的时区估算
    // 中国大陆统一使用UTC+8（东八区），经度范围约73°E-135°E
    let estimatedTimezoneOffset: number;
    
    if (coordinates.longitude >= 73 && coordinates.longitude <= 135 && 
        coordinates.latitude >= 18 && coordinates.latitude <= 54) {
      // 中国大陆范围，统一使用UTC+8
      estimatedTimezoneOffset = 480; // UTC+8 = 480分钟
      console.info(`[WeatherController] 🕒 检测到中国大陆坐标，使用UTC+8时区`);
    } else {
      // 其他地区，按经度估算（每15度=1小时）
      estimatedTimezoneOffset = Math.round(coordinates.longitude / 15) * 60;
      console.info(`[WeatherController] 🕒 非中国大陆坐标，按经度估算时区`);
    }
    
    console.info(`[WeatherController] 🕒 自动定位城市时区: 经度=${coordinates.longitude.toFixed(2)}, 纬度=${coordinates.latitude.toFixed(2)}, 时区偏移=${estimatedTimezoneOffset}分钟 (UTC${estimatedTimezoneOffset >= 0 ? '+' : ''}${estimatedTimezoneOffset / 60})`);
    
    return new City(id, cityName, 'Auto', coordinates, CitySource.AUTO, 'sunny', estimatedTimezoneOffset);
  }
}
