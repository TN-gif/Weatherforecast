import relationalStore from '@ohos.data.relationalStore';
import type common from '@ohos.app.ability.common';
import { AppConstants } from '../../common/constants/AppConstants';
import { City, Coordinates } from '../models/WeatherModels';

export class CityStorage {
  private static instance: CityStorage | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private readonly currentSchemaVersion: number = 2;
  private readonly tempDbName: string = 'temp_weather_db';

  private constructor() {}

  static getInstance(): CityStorage {
    if (CityStorage.instance === null) {
      CityStorage.instance = new CityStorage();
    }
    return CityStorage.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.rdbStore) {
      console.debug('[CityStorage] ⚠️ 数据库已初始化，跳过');
      return;
    }
    
    console.info('[CityStorage] ⚙️ 开始初始化数据库...');
    const config: relationalStore.StoreConfig = {
      name: AppConstants.RDB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: false
    };
    
    try {
      const startTime = Date.now();
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      console.info(`[CityStorage] 📂 RdbStore获取成功，耗时: ${Date.now() - startTime}ms`);
      
      // 检查数据库完整性
      await this.checkIntegrity();
      
      // 执行数据库迁移
      await this.performMigration();
      
      // 确保表结构
      await this.ensureSchema();
      
      console.info('[CityStorage] ✅ 数据库初始化流程全部完成');
    } catch (error) {
      console.error('[CityStorage] ❌ 数据库初始化失败，尝试执行修复流程...', error);
      await this.repairDatabase(context, config);
    }
  }

  private async checkIntegrity(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized');
    }
    
    try {
      console.info('[CityStorage] Checking database integrity...');
      const result = await this.rdbStore.querySql('PRAGMA integrity_check;');
      
      if (result.rowCount > 0) {
        result.goToFirstRow();
        const integrityResult = result.getString(0);
        
        if (integrityResult !== 'ok') {
          console.error(`[CityStorage] Database integrity check failed: ${integrityResult}`);
          throw new Error('Database integrity compromised');
        }
      }
      
      console.info('[CityStorage] Database integrity check passed');
    } catch (error) {
      console.error('[CityStorage] Integrity check failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  private async performMigration(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    
    console.info('[CityStorage] Checking for database migrations...');
    
    try {
      const currentVersion = await this.getCurrentSchemaVersion();
      console.info(`[CityStorage] Current schema version: ${currentVersion}, target: ${this.currentSchemaVersion}`);
      
      if (currentVersion < this.currentSchemaVersion) {
        console.info('[CityStorage] Performing database migration...');
        
        if (currentVersion < 2) {
          await this.migrateV1ToV2();
        }
        
        await this.updateSchemaVersion(this.currentSchemaVersion);
        console.info('[CityStorage] Database migration completed');
      }
    } catch (error) {
      console.error('[CityStorage] Migration failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  private async migrateV1ToV2(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    
    console.info('[CityStorage] Migrating from V1 to V2...');
    
    try {
      // 检查是否需要添加新列
      const tableInfo = await this.rdbStore.querySql(`PRAGMA table_info(${AppConstants.CITY_TABLE});`);
      let hasTimeZoneColumn = false;
      
      if (tableInfo.rowCount > 0) {
        tableInfo.goToFirstRow();
        do {
          const columnName = tableInfo.getString(1);
          if (columnName === 'timeZoneOffsetMinutes') {
            hasTimeZoneColumn = true;
            break;
          }
        } while (tableInfo.goToNextRow());
      }
      
      if (!hasTimeZoneColumn) {
        await this.rdbStore.executeSql(
          `ALTER TABLE ${AppConstants.CITY_TABLE} ADD COLUMN timeZoneOffsetMinutes INTEGER DEFAULT 0`
        );
        console.info('[CityStorage] Added timeZoneOffsetMinutes column');
      }
    } catch (error) {
      console.error('[CityStorage] V1 to V2 migration failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  private async repairDatabase(context: common.UIAbilityContext, config: relationalStore.StoreConfig): Promise<void> {
    console.info('[CityStorage] Starting database repair...');
    
    try {
      // 尝试备份现有数据
      let backupData: City[] = [];
      if (this.rdbStore) {
        try {
          backupData = await this.getAllCitiesRaw();
          console.info(`[CityStorage] Backed up ${backupData.length} cities`);
        } catch (backupError) {
          console.warn('[CityStorage] Failed to backup data:', backupError);
        }
      }
      
      // 删除损坏的数据库
      if (this.rdbStore) {
        this.rdbStore = null;
      }
      await relationalStore.deleteRdbStore(context, AppConstants.RDB_NAME);
      
      // 重新创建数据库
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.ensureSchema();
      
      // 恢复数据
      if (backupData.length > 0) {
        console.info('[CityStorage] Restoring backup data...');
        await this.restoreData(backupData);
        console.info('[CityStorage] Data restoration completed');
      }
      
      console.info('[CityStorage] Database repair completed successfully');
    } catch (error) {
      console.error('[CityStorage] Database repair failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  private async getAllCitiesRaw(): Promise<City[]> {
    if (!this.rdbStore) {
      return [];
    }
    
    try {
      const resultSet = await this.rdbStore.querySql(`SELECT * FROM ${AppConstants.CITY_TABLE} ORDER BY displayOrder`);
      const cities: City[] = [];
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        do {
          const city = this.mapResultSetToCity(resultSet);
          if (city) {
            cities.push(city);
          }
        } while (resultSet.goToNextRow());
      }
      
      return cities;
    } catch (error) {
      console.error('[CityStorage] Failed to get raw cities:', error);
      return [];
    }
  }

  private async restoreData(cities: City[]): Promise<void> {
    if (!this.rdbStore || cities.length === 0) {
      return;
    }
    
    try {
      await this.rdbStore.executeSql(`DELETE FROM ${AppConstants.CITY_TABLE}`);
      
      let displayOrder = 0;
      for (const city of cities) {
        const valueBucket: relationalStore.ValuesBucket = {
          id: city.id,
          name: city.name,
          country: city.country,
          latitude: city.coordinates.latitude,
          longitude: city.coordinates.longitude,
          source: city.source,
          videoTheme: city.videoTheme,
          timeZoneOffsetMinutes: city.timeZoneOffsetMinutes,
          displayOrder: displayOrder++
        };
        
        await this.rdbStore.insert(AppConstants.CITY_TABLE, valueBucket);
      }
      
      console.info(`[CityStorage] Restored ${cities.length} cities`);
    } catch (error) {
      console.error('[CityStorage] Data restoration failed:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  private async getCurrentSchemaVersion(): Promise<number> {
    if (!this.rdbStore) {
      return 0;
    }
    
    try {
      // 确保元数据表存在
      await this.createMetadataTable();
      
      const resultSet = await this.rdbStore.querySql(
        `SELECT value FROM ${AppConstants.METADATA_TABLE} WHERE key = 'schema_version'`
      );
      
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        return parseInt(resultSet.getString(0)) || 1;
      }
      
      return 1; // 默认版本
    } catch (error) {
      console.warn('[CityStorage] Failed to get schema version:', error);
      return 1;
    }
  }

  private async updateSchemaVersion(version: number): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    
    const valueBucket: relationalStore.ValuesBucket = {
      'key': 'schema_version',
      'value': version.toString()
    };
    
    try {
      await this.rdbStore.insert(AppConstants.METADATA_TABLE, valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      console.info(`[CityStorage] Schema version updated to ${version}`);
    } catch (error) {
      console.error('[CityStorage] Failed to update schema version:', error);
    }
  }

  private async createMetadataTable(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    
    const sql = `CREATE TABLE IF NOT EXISTS ${AppConstants.METADATA_TABLE} (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )`;
    
    await this.rdbStore.executeSql(sql);
  }

  private mapResultSetToCity(resultSet: relationalStore.ResultSet): City | null {
    try {
      const coordinates: Coordinates = {
        latitude: resultSet.getDouble(resultSet.getColumnIndex('latitude')),
        longitude: resultSet.getDouble(resultSet.getColumnIndex('longitude'))
      };
      
      return new City(
        resultSet.getString(resultSet.getColumnIndex('id')),
        resultSet.getString(resultSet.getColumnIndex('name')),
        resultSet.getString(resultSet.getColumnIndex('country')),
        coordinates,
        resultSet.getLong(resultSet.getColumnIndex('source')),
        resultSet.getString(resultSet.getColumnIndex('videoTheme')),
        resultSet.getLong(resultSet.getColumnIndex('timeZoneOffsetMinutes'))
      );
    } catch (error) {
      console.error('[CityStorage] Failed to map result set to city:', error);
      return null;
    }
  }

  private async ensureSchema(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    
    await this.createMetadataTable();
    await this.createTables();
  }

  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    
    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS ${AppConstants.CITY_TABLE} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        source INTEGER NOT NULL,
        videoTheme TEXT NOT NULL,
        timeZoneOffsetMinutes INTEGER NOT NULL DEFAULT 0,
        displayOrder INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL DEFAULT 0,
        updatedAt INTEGER NOT NULL DEFAULT 0
      )
    `);
  }

  async loadCities(): Promise<City[]> {
    if (!this.rdbStore) {
      console.warn('[CityStorage] ❌ 尝试加载城市但数据库未初始化');
      return [];
    }
    
    console.info('[CityStorage] 📖 开始从数据库加载城市列表...');
    const startTime = Date.now();
    
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(AppConstants.CITY_TABLE);
    predicates.orderByAsc('displayOrder');
    
    try {
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates);
      const cities: City[] = [];
      
      console.debug(`[CityStorage] 🔍 查询返回行数: ${resultSet.rowCount}`);
      
      while (resultSet.goToNextRow()) {
        const city = this.mapResultSetToCity(resultSet);
        if (city) {
          cities.push(city);
        }
      }
      resultSet.close();
      
      console.info(`[CityStorage] ✅ 城市列表加载完成，共 ${cities.length} 条，耗时: ${Date.now() - startTime}ms`);
      return cities;
    } catch (error) {
      console.error('[CityStorage] ❌ 加载城市列表失败:', error);
      return [];
    }
  }

  async saveCities(cities: City[]): Promise<void> {
    if (!this.rdbStore) {
      console.warn('[CityStorage] ❌ 尝试保存城市但数据库未初始化');
      return;
    }
    
    console.info(`[CityStorage] 💾 开始保存城市列表，共 ${cities.length} 条...`);
    const startTime = Date.now();
    
    try {
      // 使用事务确保原子性
      this.rdbStore.beginTransaction();
      
      await this.rdbStore.executeSql(`DELETE FROM ${AppConstants.CITY_TABLE}`);
      console.debug('[CityStorage] 🧹 旧数据已清除');
      
      let displayOrder: number = 0;
      for (const city of cities) {
        const valueBucket: relationalStore.ValuesBucket = {
          id: city.id,
          name: city.name,
          country: city.country,
          latitude: city.coordinates.latitude,
          longitude: city.coordinates.longitude,
          source: city.source,
          videoTheme: city.videoTheme,
          timeZoneOffsetMinutes: city.timeZoneOffsetMinutes,
          displayOrder: displayOrder,
          createdAt: Date.now(),
          updatedAt: Date.now()
        };
        await this.rdbStore.insert(AppConstants.CITY_TABLE, valueBucket);
        displayOrder++;
      }
      
      this.rdbStore.commit();
      console.info(`[CityStorage] ✅ 城市列表保存成功，耗时: ${Date.now() - startTime}ms`);
    } catch (error) {
      console.error('[CityStorage] ❌ 保存城市列表失败，回滚事务:', error);
      this.rdbStore.rollBack();
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
}
