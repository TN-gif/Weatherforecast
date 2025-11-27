import common from '@ohos.app.ability.common';
import { AppConstants } from '../../common/constants/AppConstants';
import { City, CitySource, Coordinates } from '../models/WeatherModels';
import { CityStorage } from '../storage/CityStorage';

export class CityRepository {
  private static instance: CityRepository;
  private storage: CityStorage = CityStorage.getInstance();
  private cities: City[] = [];

  private constructor() {
  }

  static getInstance(): CityRepository {
    if (!CityRepository.instance) {
      CityRepository.instance = new CityRepository();
    }
    return CityRepository.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    console.info('[CityRepository] ========== 初始化城市仓库 ==========');
    await this.storage.init(context);
    const storedCities: City[] = await this.storage.loadCities();
    this.cities = storedCities;
    console.info(`[CityRepository] ✅ 城市仓库初始化完成，加载了 ${this.cities.length} 个城市`);
    this.cities.forEach((city, index) => {
      console.debug(`[CityRepository]   ${index + 1}. ${city.name} (${city.id})`);
    });
  }

  getCities(): City[] {
    return [...this.cities];
  }

  async addCity(city: City): Promise<void> {
    console.info(`[CityRepository] ➕ 请求添加城市: ${city.name} (${city.id})`);
    
    if (this.cities.length >= AppConstants.MAX_CITIES) {
      console.warn(`[CityRepository] ⚠️ 城市数量已达上限 (${AppConstants.MAX_CITIES})，无法添加`);
      return;
    }
    
    const index: number = this.cities.findIndex((item: City) => item.id === city.id);
    if (index >= 0) {
      console.info(`[CityRepository] 🔄 城市已存在，更新信息: ${city.name}`);
      this.cities[index] = city;
    } else {
      console.info(`[CityRepository] ✅ 添加新城市: ${city.name}`);
      this.cities.push(city);
    }
    await this.storage.saveCities(this.cities);
    console.debug(`[CityRepository] 💾 城市列表已保存，当前数量: ${this.cities.length}`);
  }

  async updateCities(cities: City[]): Promise<void> {
    console.info(`[CityRepository] 🔄 批量更新城市列表，数量: ${cities.length}`);
    this.cities = [...cities];
    await this.storage.saveCities(this.cities);
    console.info('[CityRepository] ✅ 城市列表批量更新完成并保存');
  }

  hasCity(cityId: string): boolean {
    return this.cities.some((city: City) => city.id === cityId);
  }

  async getAllCities(): Promise<City[]> {
    return [...this.cities];
  }

  async removeCity(cityId: string): Promise<void> {
    console.info(`[CityRepository] 🗑️ 请求删除城市ID: ${cityId}`);
    const initialLength = this.cities.length;
    this.cities = this.cities.filter((city: City) => city.id !== cityId);
    
    if (this.cities.length < initialLength) {
      console.info(`[CityRepository] ✅ 城市删除成功，剩余数量: ${this.cities.length}`);
      await this.storage.saveCities(this.cities);
    } else {
      console.warn(`[CityRepository] ⚠️ 未找到要删除的城市ID: ${cityId}`);
    }
  }

  static createDefaultCity(): City {
    const coordinates: Coordinates = { latitude: 31.2304, longitude: 121.4737 };
    return new City(AppConstants.DEFAULT_CITY_ID, '上海', AppConstants.DEFAULT_COUNTRY, coordinates, CitySource.MOCK, 'sunny', 480);
  }
}
