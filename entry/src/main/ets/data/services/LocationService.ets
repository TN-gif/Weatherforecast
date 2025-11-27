import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import type common from '@ohos.app.ability.common';
import bundleManager from '@ohos.bundle.bundleManager';
import { Coordinates, LocationError, LocationErrorCode } from '../models/WeatherModels';
import { AppConstants } from '../../common/constants/AppConstants';
import { BusinessError } from '@ohos.base';
import http from '@ohos.net.http';
import { DevicePerformanceDetector } from '../../common/utils/DevicePerformanceDetector';
import { GeoServiceRouter } from './GeoServiceRouter';

interface IPLocationResponse {
  latitude: number;
  longitude: number;
  city?: string;
  country?: string;
}

export class LocationService {
  private static instance: LocationService | null = null;
  private context: common.UIAbilityContext | null = null;
  private readonly geoRouter: GeoServiceRouter = new GeoServiceRouter();

  private constructor() {}

  static getInstance(): LocationService {
    if (LocationService.instance === null) {
      LocationService.instance = new LocationService();
    }
    return LocationService.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.context = context;
  }

  async getCurrentLocation(): Promise<Coordinates> {
    console.info('[LocationService] ========== 开始获取当前位置 ==========');
    const startTime = Date.now();
    
    try {
      const coordinates = await this.getLocationWithFallback();
      const duration = Date.now() - startTime;
      console.info(`[LocationService] ✅ 位置获取成功，耗时: ${duration}ms`);
      console.info(`[LocationService] 📍 坐标: ${coordinates.latitude}, ${coordinates.longitude}`);
      return coordinates;
    } catch (error) {
      const duration = Date.now() - startTime;
      console.error(`[LocationService] ❌ 位置获取失败，耗时: ${duration}ms`);
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  async getLocationWithFallback(): Promise<Coordinates> {
    console.info('[LocationService] 🎯 开始多级定位降级策略');
    
    // 第一级：精确GPS定位
    try {
      console.info('[LocationService] 📡 尝试GPS精确定位...');
      const preciseLocation = await this.getPreciseLocation();
      console.info('[LocationService] ✅ GPS定位成功');
      console.info(`[LocationService] 📍 GPS坐标: ${preciseLocation.latitude}, ${preciseLocation.longitude}`);
      return preciseLocation;
    } catch (error) {
      const locationError = error as LocationError;
      console.warn(`[LocationService] ❌ GPS定位失败: 错误码=${locationError.code}, 消息=${locationError.message}`);
      
      // 第二级：IP定位
      try {
        console.info('[LocationService] 🌐 尝试IP定位...');
        const ipLocation = await this.fallbackToIPLocation();
        if (ipLocation) {
          console.info('[LocationService] ✅ IP定位成功');
          console.info(`[LocationService] 📍 IP坐标: ${ipLocation.latitude}, ${ipLocation.longitude}`);
          return ipLocation;
        } else {
          console.warn('[LocationService] ❌ IP定位返回空结果');
        }
      } catch (ipError) {
        console.error('[LocationService] ❌ IP定位异常:', ipError);
      }
      
      // 第三级：默认位置
      console.info('[LocationService] 🏠 使用默认位置 (上海)');
      const defaultLocation = this.getDefaultLocation();
      console.info(`[LocationService] 📍 默认坐标: ${defaultLocation.latitude}, ${defaultLocation.longitude}`);
      return defaultLocation;
    }
  }

  private async getPreciseLocation(): Promise<Coordinates> {
    console.info('[LocationService] 🎯 开始GPS精确定位流程');
    
    if (!this.context) {
      console.error('[LocationService] ❌ Context不可用');
      throw new LocationError(LocationErrorCode.CONTEXT_UNAVAILABLE, 'Context not available');
    }
    console.debug('[LocationService] ✅ Context有效');

    // 移除模拟器检查，允许在模拟器中使用GPS
    console.debug('[LocationService] ✅ 继续GPS定位流程');
    
    try {
      console.debug('[LocationService] 🔐 检查定位权限...');
      await this.ensureLocationPermission();
      console.debug('[LocationService] ✅ 定位权限已授予');
      
      console.debug('[LocationService] 🔌 检查定位开关...');
      await this.ensureLocationEnabled();
      console.debug('[LocationService] ✅ 定位开关已开启');
      
      console.info('[LocationService] 📡 开始调用系统GPS接口...');
      console.debug('[LocationService] GPS配置: priority=FIRST_FIX, timeout=15000ms');
      const gpsStartTime = Date.now();
      
      const position: geoLocationManager.Location = await geoLocationManager.getCurrentLocation({
        priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
        scenario: geoLocationManager.LocationRequestScenario.UNSET,
        timeoutMs: 15000
      });
      
      const gpsDuration = Date.now() - gpsStartTime;
      console.info(`[LocationService] ✅ GPS定位成功，耗时: ${gpsDuration}ms`);
      
      const coordinates: Coordinates = {
        latitude: position.latitude,
        longitude: position.longitude
      };
      console.debug(`[LocationService] 📍 原始GPS坐标: lat=${coordinates.latitude}, lon=${coordinates.longitude}`);
      console.debug(`[LocationService] GPS精度: ${position.accuracy || 'N/A'}米`);
      
      return coordinates;
    } catch (error) {
      const businessError = error as BusinessError;
      const errorCode = this.mapBusinessErrorToLocationError(businessError.code);
      const errorMessage = businessError.message || 'Location service error';
      console.error(`[LocationService] ❌ GPS定位失败: 错误码=${businessError.code}, 消息=${errorMessage}`);
      throw new LocationError(errorCode, errorMessage);
    }
  }

  private mapBusinessErrorToLocationError(code: number): LocationErrorCode {
    switch (code) {
      case 201:
        return LocationErrorCode.PERMISSION_DENIED;
      case 301:
        return LocationErrorCode.LOCATION_SWITCH_OFF;
      case 800:
        return LocationErrorCode.LOCATION_TIMEOUT;
      default:
        return LocationErrorCode.UNKNOWN_ERROR;
    }
  }

  async requestLocationPermission(): Promise<boolean> {
    if (!this.context) {
      console.error('[LocationService] Context not available for permission request');
      return false;
    }
    
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      console.info('[LocationService] Requesting location permissions...');
      const grantStatus = await atManager.requestPermissionsFromUser(
        this.context,
        [
          AppConstants.LOCATION_PERMISSION as Permissions,
          AppConstants.APPROX_LOCATION_PERMISSION as Permissions
        ]
      );
      
      const allGranted = grantStatus.authResults.every(grant => grant === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
      console.info(`[LocationService] Permission request result: ${allGranted ? 'granted' : 'denied'}`);
      return allGranted;
    } catch (err) {
      console.error(`[LocationService] Permission request failed: ${JSON.stringify(err)}`);
      return false;
    }
  }

  private async ensureLocationPermission(): Promise<void> {
    console.debug('[LocationService] 🔐 开始权限验证流程');
    
    if (!this.context) {
      console.error('[LocationService] ❌ Context不可用，无法检查权限');
      throw new LocationError(LocationErrorCode.CONTEXT_UNAVAILABLE, 'Context not available');
    }
    
    const atManager = abilityAccessCtrl.createAtManager();
    const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    const tokenId = bundleInfo.appInfo.accessTokenId;
    console.debug(`[LocationService] 应用Token ID: ${tokenId}`);
    
    const permissions: Permissions[] = [
      AppConstants.LOCATION_PERMISSION as Permissions,
      AppConstants.APPROX_LOCATION_PERMISSION as Permissions
    ];
    
    console.debug(`[LocationService] 需要检查 ${permissions.length} 个权限`);
    
    for (let i = 0; i < permissions.length; i++) {
      const permission = permissions[i];
      console.debug(`[LocationService] 检查权限 ${i + 1}/${permissions.length}: ${permission}`);
      
      const grantStatus = await atManager.checkAccessToken(tokenId, permission);
      
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.debug(`[LocationService] ✅ 权限已授予: ${permission}`);
      } else if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        console.warn(`[LocationService] ⚠️ 权限未授予: ${permission}，尝试请求...`);
        const hasPermission = await this.requestLocationPermission();
        if (!hasPermission) {
          console.error(`[LocationService] ❌ 权限请求被拒绝: ${permission}`);
          throw new LocationError(LocationErrorCode.PERMISSION_DENIED, 'Location permission denied');
        }
        console.info(`[LocationService] ✅ 权限请求成功: ${permission}`);
      }
    }
    
    console.debug('[LocationService] ✅ 所有定位权限验证通过');
  }

  private async ensureLocationEnabled(): Promise<void> {
    console.debug('[LocationService] 🔌 检查系统定位开关状态...');
    const enabled: boolean = await geoLocationManager.isLocationEnabled();
    
    if (!enabled) {
      console.error('[LocationService] ❌ 系统定位开关未开启');
      throw new LocationError(LocationErrorCode.LOCATION_SWITCH_OFF, 'Location disabled');
    }
    
    console.debug('[LocationService] ✅ 系统定位开关已开启');
  }

  private async handleLocationError(error: BusinessError): Promise<Coordinates> {
    const code: number = error.code ?? 0;
    console.warn(`[LocationService] location failed, code=${code}, message=${error.message}`);
    if (code === LocationErrorCode.PERMISSION_DENIED) {
      throw new Error('需要开启定位权限才能自动定位');
    }
    if (code === LocationErrorCode.LOCATION_TIMEOUT) {
      const ipLocation: Coordinates | null = await this.fallbackToIPLocation();
      if (ipLocation !== null) {
        return ipLocation;
      }
    }
    return this.getDefaultLocation();
  }

  private async fallbackToIPLocation(): Promise<Coordinates | null> {
    console.info('[LocationService] 🌐 开始IP定位降级流程');
    const request: http.HttpRequest = http.createHttp();
    
    try {
      const ipApiUrl = 'https://ipapi.co/json/';
      console.debug(`[LocationService] IP定位API: ${ipApiUrl}`);
      console.debug('[LocationService] 请求超时配置: connect=5s, read=5s');
      
      const startTime = Date.now();
      
      const ipRequestConfig: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 5000,
        readTimeout: 5000
      };
      
      console.debug('[LocationService] 发送IP定位请求...');
      const response: http.HttpResponse = await request.request(ipApiUrl, ipRequestConfig);
      const duration = Date.now() - startTime;
      
      console.debug(`[LocationService] IP定位响应: status=${response.responseCode}, 耗时=${duration}ms`);
      
      if (response.responseCode !== 200) {
        console.warn(`[LocationService] ❌ IP定位API返回错误状态码: ${response.responseCode}`);
        return null;
      }
      
      const payload = JSON.parse(response.result as string) as IPLocationResponse;
      console.debug(`[LocationService] IP定位响应数据: ${JSON.stringify(payload)}`);
      
      if (payload.latitude && payload.longitude) {
        const ipCoordinates: Coordinates = {
          latitude: payload.latitude,
          longitude: payload.longitude
        };
        console.info(`[LocationService] ✅ IP定位成功: lat=${ipCoordinates.latitude}, lon=${ipCoordinates.longitude}`);
        if (payload.city) {
          console.debug(`[LocationService] IP定位城市: ${payload.city}`);
        }
        return ipCoordinates;
      } else {
        console.warn('[LocationService] ❌ IP定位响应缺少坐标数据');
        return null;
      }
    } catch (err) {
      console.error('[LocationService] ❌ IP定位异常:', err);
      return null;
    } finally {
      request.destroy();
      console.debug('[LocationService] HTTP请求已清理');
    }
  }

  /**
   * 反向地理编码：根据坐标获取城市名称（使用智能路由）
   */
  async getCityNameFromCoordinates(coordinates: Coordinates): Promise<string> {
    console.info('[LocationService] ========== 开始反向地理编码（智能路由） ==========');
    console.info(`[LocationService] 🗺️ 输入坐标: ${coordinates.latitude}, ${coordinates.longitude}`);
    
    const startTime = Date.now();
    
    try {
      const cityName = await this.geoRouter.reverseGeocode(coordinates);
      const duration = Date.now() - startTime;
      
      if (cityName) {
        console.info(`[LocationService] ✅ 智能路由成功，耗时: ${duration}ms`);
        console.info(`[LocationService] 🏙️ 城市名称: ${cityName}`);
        return cityName;
      } else {
        console.warn(`[LocationService] ❌ 智能路由返回空，耗时: ${duration}ms`);
        console.info('[LocationService] 🔄 切换到坐标推测模式');
        return this.getFallbackCityName(coordinates);
      }
      
    } catch (error) {
      const duration = Date.now() - startTime;
      console.error(`[LocationService] ❌ 智能路由异常，耗时: ${duration}ms:`, error);
      console.info('[LocationService] 🔄 切换到坐标推测模式');
      return this.getFallbackCityName(coordinates);
    }
  }

  /**
   * 获取备用城市名称（基于坐标范围推测）
   */
  private getFallbackCityName(coordinates: Coordinates): string {
    console.info('[LocationService] 🧭 开始坐标范围推测');
    const lat = coordinates.latitude;
    const lng = coordinates.longitude;
    console.info(`[LocationService] 📐 分析坐标: 纬度=${lat}, 经度=${lng}`);
    
    let cityName: string;
    
    // 中国主要城市坐标范围判断
    if (lat >= 39.8 && lat <= 40.2 && lng >= 116.2 && lng <= 116.6) {
      cityName = '北京';
      console.info('[LocationService] 🏛️ 坐标匹配: 北京市范围');
    } else if (lat >= 31.1 && lat <= 31.4 && lng >= 121.3 && lng <= 121.7) {
      cityName = '上海';
      console.info('[LocationService] 🏙️ 坐标匹配: 上海市范围');
    } else if (lat >= 22.4 && lat <= 22.8 && lng >= 113.8 && lng <= 114.6) {
      cityName = '深圳';
      console.info('[LocationService] 🌆 坐标匹配: 深圳市范围');
    } else if (lat >= 23.0 && lat <= 23.4 && lng >= 113.1 && lng <= 113.5) {
      cityName = '广州';
      console.info('[LocationService] 🏢 坐标匹配: 广州市范围');
    } else if (lat >= 30.4 && lat <= 30.8 && lng >= 104.0 && lng <= 104.2) {
      cityName = '成都';
      console.info('[LocationService] 🐼 坐标匹配: 成都市范围');
    } else if (lat >= 29.4 && lat <= 29.8 && lng >= 106.3 && lng <= 106.8) {
      cityName = '重庆';
      console.info('[LocationService] 🌉 坐标匹配: 重庆市范围');
    } else if (lat >= 36.0 && lat <= 36.4 && lng >= 120.2 && lng <= 120.5) {
      cityName = '青岛';
      console.info('[LocationService] 🌊 坐标匹配: 青岛市范围');
    } else if (lat >= 32.0 && lat <= 32.2 && lng >= 118.6 && lng <= 119.0) {
      cityName = '南京';
      console.info('[LocationService] 🏮 坐标匹配: 南京市范围');
    } else if (lat >= 30.2 && lat <= 30.4 && lng >= 120.0 && lng <= 120.3) {
      cityName = '杭州';
      console.info('[LocationService] 🏞️ 坐标匹配: 杭州市范围');
    } else if (lat >= 38.8 && lat <= 39.2 && lng >= 117.1 && lng <= 117.4) {
      cityName = '天津';
      console.info('[LocationService] 🚢 坐标匹配: 天津市范围');
    } else {
      // 根据大致区域判断
      if (lat >= 18 && lat <= 54 && lng >= 73 && lng <= 135) {
        cityName = '中国境内';
        console.info('[LocationService] 🇨🇳 坐标在中国境内，但未匹配到具体城市');
      } else {
        cityName = `位置 ${lat.toFixed(2)}, ${lng.toFixed(2)}`;
        console.info('[LocationService] 🌍 坐标在中国境外或无法识别');
      }
    }
    
    console.info(`[LocationService] ✅ 坐标推测结果: ${cityName}`);
    return cityName;
  }

  private getDefaultLocation(): Coordinates {
    const defaultCoordinates: Coordinates = {
      latitude: 31.2304,
      longitude: 121.4737
    };
    return defaultCoordinates;
  }
}
