import relationalStore from '@ohos.data.relationalStore';
import type common from '@ohos.app.ability.common';
import { AppConstants } from '../../common/constants/AppConstants';
import { WeatherSnapshot } from '../models/WeatherModels';

export class WeatherCacheStorage {
  private static instance: WeatherCacheStorage | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {}

  static getInstance(): WeatherCacheStorage {
    if (WeatherCacheStorage.instance === null) {
      WeatherCacheStorage.instance = new WeatherCacheStorage();
    }
    return WeatherCacheStorage.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.rdbStore) {
      return;
    }
    const config: relationalStore.StoreConfig = {
      name: AppConstants.RDB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: false
    };
    this.rdbStore = await relationalStore.getRdbStore(context, config);
    await this.createTable();
  }

  private async createTable(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS ${AppConstants.WEATHER_TABLE} (
        cityId TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        lastUpdated INTEGER NOT NULL
      )
    `);
  }

  async saveSnapshot(snapshot: WeatherSnapshot): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      cityId: snapshot.cityId,
      payload: JSON.stringify(snapshot),
      lastUpdated: Date.now()
    };
    await this.rdbStore.insert(
      AppConstants.WEATHER_TABLE,
      valueBucket,
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    );
  }

  async loadSnapshot(cityId: string): Promise<WeatherSnapshot | null> {
    if (!this.rdbStore) {
      return null;
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(AppConstants.WEATHER_TABLE);
    predicates.equalTo('cityId', cityId);
    const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates);
    try {
      if (!resultSet.goToFirstRow()) {
        return null;
      }
      const payload: string = resultSet.getString(resultSet.getColumnIndex('payload'));
      return JSON.parse(payload) as WeatherSnapshot;
    } catch (error) {
      console.error('[WeatherCacheStorage] Failed to parse cache, removing entry');
      await this.clear(cityId);
      return null;
    } finally {
      resultSet.close();
    }
  }

  async clear(cityId: string): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(AppConstants.WEATHER_TABLE);
    predicates.equalTo('cityId', cityId);
    await this.rdbStore.delete(predicates);
  }
}
