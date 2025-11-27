import relationalStore from '@ohos.data.relationalStore';
import type common from '@ohos.app.ability.common';
import { AppConstants } from '../../common/constants/AppConstants';
import { WeatherSnapshot } from '../models/WeatherModels';

export class WeatherCacheStorage {
  private static instance: WeatherCacheStorage | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  // 🔧 缓存版本号 - 当数据结构或格式化逻辑变化时递增此版本号
  private static readonly CACHE_VERSION: number = 2; // 修复日出日落格式化后更新版本

  private constructor() {}

  static getInstance(): WeatherCacheStorage {
    if (WeatherCacheStorage.instance === null) {
      WeatherCacheStorage.instance = new WeatherCacheStorage();
    }
    return WeatherCacheStorage.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.rdbStore) {
      console.debug('[WeatherCacheStorage] ⚠️ 缓存数据库已初始化，跳过');
      return;
    }
    console.info('[WeatherCacheStorage] ⚙️ 初始化缓存数据库...');
    const config: relationalStore.StoreConfig = {
      name: AppConstants.RDB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: false
    };
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTable();
      console.info('[WeatherCacheStorage] ✅ 缓存数据库初始化成功');
    } catch (error) {
      console.error('[WeatherCacheStorage] ❌ 缓存数据库初始化失败:', error);
    }
  }

  private async createTable(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS ${AppConstants.WEATHER_TABLE} (
        cityId TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        lastUpdated INTEGER NOT NULL,
        cacheVersion INTEGER DEFAULT 1
      )
    `);
  }

  async saveSnapshot(snapshot: WeatherSnapshot): Promise<void> {
    if (!this.rdbStore) {
      console.warn('[WeatherCacheStorage] ❌ 尝试保存缓存但数据库未初始化');
      return;
    }
    
    console.debug(`[WeatherCacheStorage] 💾 保存天气缓存: ${snapshot.cityId} (版本: ${WeatherCacheStorage.CACHE_VERSION})`);
    const startTime = Date.now();
    
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        cityId: snapshot.cityId,
        payload: JSON.stringify(snapshot),
        lastUpdated: Date.now(),
        cacheVersion: WeatherCacheStorage.CACHE_VERSION
      };
      await this.rdbStore.insert(
        AppConstants.WEATHER_TABLE,
        valueBucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );
      console.debug(`[WeatherCacheStorage] ✅ 缓存保存成功，耗时: ${Date.now() - startTime}ms`);
    } catch (error) {
      console.error(`[WeatherCacheStorage] ❌ 缓存保存失败 (${snapshot.cityId}):`, error);
    }
  }

  async loadSnapshot(cityId: string): Promise<WeatherSnapshot | null> {
    if (!this.rdbStore) {
      return null;
    }
    
    console.debug(`[WeatherCacheStorage] 📖 读取天气缓存: ${cityId}`);
    const startTime = Date.now();
    
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(AppConstants.WEATHER_TABLE);
    predicates.equalTo('cityId', cityId);
    
    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates);
      try {
        if (!resultSet.goToFirstRow()) {
          console.debug(`[WeatherCacheStorage] ⚠️ 未找到缓存: ${cityId}`);
          return null;
        }
        
        // 🔧 检查缓存版本号
        const cacheVersionIndex = resultSet.getColumnIndex('cacheVersion');
        let cacheVersion = 1; // 默认版本1（旧数据没有此字段）
        if (cacheVersionIndex >= 0) {
          cacheVersion = resultSet.getLong(cacheVersionIndex);
        }
        
        if (cacheVersion < WeatherCacheStorage.CACHE_VERSION) {
          console.warn(`[WeatherCacheStorage] ⚠️ 缓存版本过旧 (${cacheVersion} < ${WeatherCacheStorage.CACHE_VERSION})，清除旧缓存: ${cityId}`);
          await this.clear(cityId);
          return null;
        }
        
        const payload: string = resultSet.getString(resultSet.getColumnIndex('payload'));
        const snapshot = JSON.parse(payload) as WeatherSnapshot;
        console.debug(`[WeatherCacheStorage] ✅ 缓存读取成功 (${cityId}, 版本: ${cacheVersion})，耗时: ${Date.now() - startTime}ms`);
        return snapshot;
      } catch (error) {
        console.error(`[WeatherCacheStorage] ❌ 缓存解析失败 (${cityId}), 清除损坏数据:`, error);
        await this.clear(cityId);
        return null;
      } finally {
        resultSet.close();
      }
    } catch (error) {
      console.error(`[WeatherCacheStorage] ❌ 缓存查询失败 (${cityId}):`, error);
      return null;
    }
  }

  async clear(cityId: string): Promise<void> {
    if (!this.rdbStore) return;
    console.info(`[WeatherCacheStorage] 🗑️ 清除缓存: ${cityId}`);
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(AppConstants.WEATHER_TABLE);
      predicates.equalTo('cityId', cityId);
      await this.rdbStore.delete(predicates);
    } catch (error) {
      console.error(`[WeatherCacheStorage] ❌ 清除缓存失败 (${cityId}):`, error);
    }
  }
}
