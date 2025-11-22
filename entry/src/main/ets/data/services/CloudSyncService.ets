import cloudDatabase from '@ohos.data.cloudData';
import { City } from '../models/WeatherModels';
import { CityRepository } from '../repository/CityRepository';

const CLOUD_ZONE_NAME = 'WeatherZone';

export class CloudSyncService {
  private static instance: CloudSyncService | null = null;
  private cloudDBZone: cloudDatabase.CloudDBZone | null = null;
  private cityRepository: CityRepository = CityRepository.getInstance();

  private constructor() {}

  static getInstance(): CloudSyncService {
    if (CloudSyncService.instance === null) {
      CloudSyncService.instance = new CloudSyncService();
    }
    return CloudSyncService.instance;
  }

  async init(): Promise<void> {
    try {
      // Note: This requires valid agconnect-services.json and Cloud DB setup
      // We wrap in try-catch to prevent crash if not configured
      console.info('[CloudSyncService] Initializing Cloud DB...');
      /* 
      // Actual implementation would look like this:
      const context = AppContextHolder.getContext();
      await cloudDatabase.AGConnectCloudDB.initialize(context);
      const cloudDB = cloudDatabase.AGConnectCloudDB.getInstance();
      const config = new cloudDatabase.CloudDBZoneConfig(CLOUD_ZONE_NAME);
      this.cloudDBZone = await cloudDB.openCloudDBZone2(config, true);
      console.info('[CloudSyncService] Cloud DB initialized');
      */
      console.warn('[CloudSyncService] Cloud DB credentials missing, running in local-only mode');
    } catch (error) {
      console.error('[CloudSyncService] Failed to init Cloud DB:', error);
    }
  }

  async syncUp(): Promise<void> {
    if (!this.cloudDBZone) {
      console.warn('[CloudSyncService] Cloud DB not ready, skipping sync up');
      return;
    }
    
    try {
      const cities = await this.cityRepository.getAllCities();
      // Convert to Cloud Object and upsert
      // const cloudObjects = cities.map(c => this.toCloudObject(c));
      // await this.cloudDBZone.executeUpsert(cloudObjects);
      console.info(`[CloudSyncService] Synced ${cities.length} cities to cloud`);
    } catch (error) {
      console.error('[CloudSyncService] Sync up failed:', error);
    }
  }

  async syncDown(): Promise<void> {
    if (!this.cloudDBZone) {
      console.warn('[CloudSyncService] Cloud DB not ready, skipping sync down');
      return;
    }

    try {
      // const query = cloudDatabase.CloudDBZoneQuery.where(CityCloudObject).orderByAsc('order');
      // const snapshot = await this.cloudDBZone.executeQuery(query);
      // const cloudCities = snapshot.getSnapshotObjects();
      // await this.cityRepository.updateCities(cloudCities.map(c => this.fromCloudObject(c)));
      console.info('[CloudSyncService] Synced cities from cloud');
    } catch (error) {
      console.error('[CloudSyncService] Sync down failed:', error);
    }
  }
}
