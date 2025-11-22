import type common from '@ohos.app.ability.common';
import { WeatherService } from '../services/WeatherService';
import { WeatherCacheStorage } from '../storage/WeatherCacheStorage';
import { City, WeatherSnapshot } from '../models/WeatherModels';
import { MockWeatherRepository } from '../../mock/MockWeatherRepository';

export class WeatherRepository {
  private readonly service: WeatherService;
  private readonly cacheStorage: WeatherCacheStorage = WeatherCacheStorage.getInstance();
  private readonly mockRepository: MockWeatherRepository;

  constructor(service: WeatherService, mockRepository: MockWeatherRepository) {
    this.service = service;
    this.mockRepository = mockRepository;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    await this.cacheStorage.init(context);
  }

  async loadWeather(city: City, forceRefresh: boolean): Promise<WeatherSnapshot> {
    console.info(`[WeatherRepository] ========== 开始加载天气数据 ==========`);
    console.info(`[WeatherRepository] 城市: ${city.name} (${city.id})`);
    console.info(`[WeatherRepository] 强制刷新: ${forceRefresh}`);
    console.info(`[WeatherRepository] 城市坐标: ${JSON.stringify(city.coordinates)}`);
    
    // 检查缓存
    console.info(`[WeatherRepository] 检查缓存数据...`);
    const cached: WeatherSnapshot | null = await this.cacheStorage.loadSnapshot(city.id);
    
    if (cached) {
      const cacheAge = Date.now() - new Date(cached.lastUpdatedIso).getTime();
      const cacheAgeMinutes = Math.floor(cacheAge / (60 * 1000));
      const isValid = this.isCacheValid(cached);
      console.info(`[WeatherRepository] 找到缓存数据，年龄: ${cacheAgeMinutes}分钟，有效: ${isValid}`);
      console.info(`[WeatherRepository] 缓存数据: 城市ID=${cached.cityId}, 温度: ${cached.current.temperatureC}°C`);
      
      if (!forceRefresh && isValid) {
        console.info('[WeatherRepository] ========== 使用有效缓存数据 ==========');
        return cached;
      }
    } else {
      console.info(`[WeatherRepository] 未找到缓存数据`);
    }
    
    try {
      console.info('[WeatherRepository] 开始从网络获取新数据...');
      const fetchStartTime = Date.now();
      const snapshot: WeatherSnapshot = await this.service.fetchWeather(city.id, city.coordinates);
      const fetchTime = Date.now() - fetchStartTime;
      console.info(`[WeatherRepository] 网络数据获取成功，耗时: ${fetchTime}ms`);
      console.info(`[WeatherRepository] 新数据: 城市ID=${snapshot.cityId}, 温度: ${snapshot.current.temperatureC}°C`);
      
      console.info(`[WeatherRepository] 保存到缓存...`);
      await this.cacheStorage.saveSnapshot(snapshot);
      console.info('[WeatherRepository] ========== 返回新获取的数据 ==========');
      return snapshot;
    } catch (error) {
      const err = error as Error;
      console.error(`[WeatherRepository] 网络获取失败: ${err.name} - ${err.message}`);
      
      // 尝试使用缓存（即使过期）
      if (cached) {
        console.warn('[WeatherRepository] ========== 使用过期缓存数据作为降级 ==========');
        console.warn(`[WeatherRepository] 降级数据: 城市ID=${cached.cityId}, 温度: ${cached.current.temperatureC}°C`);
        return cached;
      }
      
      // 最后使用Mock数据
      console.warn('[WeatherRepository] ========== 使用Mock数据作为最终降级 ==========');
      const mock: WeatherSnapshot = this.mockRepository.getSnapshot(city.id);
      console.warn(`[WeatherRepository] Mock数据: 城市ID=${mock.cityId}, 温度: ${mock.current.temperatureC}°C`);
      
      try {
        await this.cacheStorage.saveSnapshot(mock);
        console.info(`[WeatherRepository] Mock数据已保存到缓存`);
      } catch (saveError) {
        console.error(`[WeatherRepository] Mock数据保存失败: ${(saveError as Error).message}`);
      }
      
      return mock;
    }
  }

  private isCacheValid(snapshot: WeatherSnapshot): boolean {
    const lastUpdate: number = new Date(snapshot.lastUpdatedIso).getTime();
    const diffMinutes: number = (Date.now() - lastUpdate) / (60 * 1000);
    const cacheMinutes: number = this.getCacheDuration(snapshot);
    return diffMinutes < cacheMinutes;
  }

  private getCacheDuration(snapshot: WeatherSnapshot): number {
    const iconCode: string = snapshot.current.condition.iconCode.toLowerCase();
    if (iconCode.includes('thunder') || iconCode.includes('storm')) {
      return 10;
    }
    if (iconCode.includes('rain') || iconCode.includes('snow') || iconCode.includes('fog')) {
      return 20;
    }
    if (snapshot.daily.length > 0) {
      const forecast = snapshot.daily[0];
      if (forecast.maxTempC - forecast.minTempC > 15) {
        return 25;
      }
    }
    if (iconCode.includes('sunny') || iconCode.includes('clear')) {
      return 45;
    }
    return 30;
  }
}
