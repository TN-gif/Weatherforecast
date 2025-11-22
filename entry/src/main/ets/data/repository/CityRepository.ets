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
    await this.storage.init(context);
    const storedCities: City[] = await this.storage.loadCities();
    this.cities = storedCities;
  }

  getCities(): City[] {
    return [...this.cities];
  }

  async addCity(city: City): Promise<void> {
    if (this.cities.length >= AppConstants.MAX_CITIES) {
      return;
    }
    const index: number = this.cities.findIndex((item: City) => item.id === city.id);
    if (index >= 0) {
      this.cities[index] = city;
    } else {
      this.cities.push(city);
    }
    await this.storage.saveCities(this.cities);
  }

  async updateCities(cities: City[]): Promise<void> {
    this.cities = [...cities];
    await this.storage.saveCities(this.cities);
  }

  hasCity(cityId: string): boolean {
    return this.cities.some((city: City) => city.id === cityId);
  }

  async getAllCities(): Promise<City[]> {
    return [...this.cities];
  }

  async removeCity(cityId: string): Promise<void> {
    this.cities = this.cities.filter((city: City) => city.id !== cityId);
    await this.storage.saveCities(this.cities);
  }

  static createDefaultCity(): City {
    const coordinates: Coordinates = { latitude: 31.2304, longitude: 121.4737 };
    return new City(AppConstants.DEFAULT_CITY_ID, '上海', AppConstants.DEFAULT_COUNTRY, coordinates, CitySource.MOCK, 'sunny', 480);
  }
}
