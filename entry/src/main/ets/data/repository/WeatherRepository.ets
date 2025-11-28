import type common from '@ohos.app.ability.common';
import { WeatherDataRouter } from '../services/WeatherDataRouter';
import { WeatherCacheStorage } from '../storage/WeatherCacheStorage';
import { City, WeatherSnapshot } from '../models/WeatherModels';
import { MockWeatherRepository } from '../../mock/MockWeatherRepository';

export class WeatherRepository {
  private readonly router: WeatherDataRouter;
  private readonly cacheStorage: WeatherCacheStorage = WeatherCacheStorage.getInstance();
  private readonly mockRepository: MockWeatherRepository;

  constructor(router: WeatherDataRouter, mockRepository: MockWeatherRepository) {
    this.router = router;
    this.mockRepository = mockRepository;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    await this.cacheStorage.init(context);
  }

  async loadWeather(city: City, forceRefresh: boolean): Promise<WeatherSnapshot> {
    console.info(`[WeatherRepository] ========== 开始加载天气数据 ==========`);
    console.info(`[WeatherRepository] 🏙️ 城市: ${city.name} (${city.id})`);
    console.info(`[WeatherRepository] 🔄 强制刷新: ${forceRefresh}`);
    console.debug(`[WeatherRepository] 📍 坐标: ${JSON.stringify(city.coordinates)}`);
    
    // 1.检查缓存
    console.debug(`[WeatherRepository] 💾 检查本地缓存...`);
    const cached: WeatherSnapshot | null = await this.cacheStorage.loadSnapshot(city.id);
    
    if (cached) {
      const cacheAge = Date.now() - new Date(cached.lastUpdatedIso).getTime();
      const cacheAgeMinutes = Math.floor(cacheAge / (60 * 1000));
      const isValid = this.isCacheValid(cached);
      
      console.info(`[WeatherRepository] 📝 缓存状态: 年龄=${cacheAgeMinutes}分钟, 有效=${isValid}`);
      console.debug(`[WeatherRepository] 缓存详情: Temp=${cached.current.temperatureC}°C, Source=${cached.dataSource}`);
      
      if (!forceRefresh && isValid) {
        console.info('[WeatherRepository] ✅ 使用有效缓存数据，跳过网络请求');
        console.info('[WeatherRepository] ========== 加载完成 (缓存) ==========');
        return cached;
      } else {
        console.info(`[WeatherRepository] ⚠️ 缓存${forceRefresh ? '被强制刷新忽略' : '已过期'}，准备发起网络请求`);
      }
    } else {
      console.info(`[WeatherRepository] ⚠️ 未找到本地缓存`);
    }
    
    try {
      // 2. 网络请求
      console.info('[WeatherRepository] 🌐 开始从网络获取新数据...');
      const fetchStartTime = Date.now();
      // 🔧 修复：传入城市的时区信息
      const snapshot: WeatherSnapshot = await this.router.fetchWeather(city.id, city.coordinates, city.timeZoneOffsetMinutes);
      const fetchTime = Date.now() - fetchStartTime;
      
      console.info(`[WeatherRepository] ✅ 网络数据获取成功，耗时: ${fetchTime}ms`);
      console.info(`[WeatherRepository] 📊 新数据概览: Temp=${snapshot.current.temperatureC}°C, Alerts=${snapshot.alerts.length}, Rain=${snapshot.rainForecast.length}`);
      
      console.debug(`[WeatherRepository] 💾 保存新数据到缓存...`);
      await this.cacheStorage.saveSnapshot(snapshot);
      
      console.info('[WeatherRepository] ========== 加载完成 (网络) ==========');
      return snapshot;
    } catch (error) {
      const err = error as Error;
      console.error(`[WeatherRepository] ❌ 网络获取失败: ${err.name} - ${err.message}`);
      
      // 3. 降级方案
      if (cached) {
        console.warn('[WeatherRepository] ⚠️ 网络失败，降级使用过期缓存数据');
        console.info(`[WeatherRepository] ========== 加载完成 (降级缓存) ==========`);
        return cached;
      }
      
      // 最后使用Mock数据
      console.warn('[WeatherRepository] ⚠️ 无缓存可用，最终降级使用Mock数据');
      const mock: WeatherSnapshot = this.mockRepository.getSnapshot(city.id);
      console.info(`[WeatherRepository] 🎭 Mock数据生成: Temp=${mock.current.temperatureC}°C`);
      
      try {
        await this.cacheStorage.saveSnapshot(mock);
        console.debug(`[WeatherRepository] Mock数据已保存到缓存`);
      } catch (saveError) {
        console.error(`[WeatherRepository] Mock数据保存失败: ${(saveError as Error).message}`);
      }
      
      console.info('[WeatherRepository] ========== 加载完成 (Mock) ==========');
      return mock;
    }
  }

  private isCacheValid(snapshot: WeatherSnapshot): boolean {
    const lastUpdate: number = new Date(snapshot.lastUpdatedIso).getTime();
    const diffMinutes: number = (Date.now() - lastUpdate) / (60 * 1000);
    const cacheMinutes: number = this.getCacheDuration(snapshot);
    
    const isValid = diffMinutes < cacheMinutes;
    if (!isValid) {
      console.debug(`[WeatherRepository] ⌛ 缓存失效: 已存${diffMinutes.toFixed(1)}分钟 > 有效期${cacheMinutes}分钟`);
    }
    return isValid;
  }

  private getCacheDuration(snapshot: WeatherSnapshot): number {
    const iconCode: string = snapshot.current.condition.iconCode.toLowerCase();
    let duration = 30; // 默认30分钟
    let reason = '默认策略';

    if (iconCode.includes('thunder') || iconCode.includes('storm')) {
      duration = 10;
      reason = '恶劣天气(雷暴)';
    } else if (iconCode.includes('rain') || iconCode.includes('snow') || iconCode.includes('fog')) {
      duration = 20;
      reason = '变化天气(雨雪雾)';
    } else if (snapshot.daily.length > 0) {
      const forecast = snapshot.daily[0];
      if (forecast.maxTempC - forecast.minTempC > 15) {
        duration = 25;
        reason = '温差大';
      }
    } else if (iconCode.includes('sunny') || iconCode.includes('clear')) {
      duration = 45;
      reason = '稳定天气(晴朗)';
    }
    
    // console.debug(`[WeatherRepository] ⏱️ 计算缓存有效期: ${duration}分钟 (${reason})`);
    return duration;
  }
}
