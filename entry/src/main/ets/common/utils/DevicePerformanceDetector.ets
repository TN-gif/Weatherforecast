import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo';
import { BackgroundMode } from '../constants/ThemeConstants';

export enum PerformanceLevel {
  HIGH = 'high',
  MEDIUM = 'medium',
  LOW = 'low'
}

export interface DeviceCapability {
  performanceLevel: PerformanceLevel;
  screenWidth: number;
  screenHeight: number;
  refreshRate: number;
  isSimulator: boolean;
}

export class DevicePerformanceDetector {
  private static instance: DevicePerformanceDetector | null = null;
  private capability: DeviceCapability | null = null;

  private constructor() {}

  static getInstance(): DevicePerformanceDetector {
    if (DevicePerformanceDetector.instance === null) {
      DevicePerformanceDetector.instance = new DevicePerformanceDetector();
    }
    return DevicePerformanceDetector.instance;
  }

  async detect(): Promise<DeviceCapability> {
    if (this.capability) {
      return this.capability;
    }
    
    const isSimulator = this.checkIsSimulator();
    console.info(`[DevicePerformanceDetector] Is Simulator: ${isSimulator}`);

    try {
      const displayInfo: display.Display = display.getDefaultDisplaySync();
      const capability: DeviceCapability = {
        performanceLevel: this.resolvePerformanceLevel(displayInfo, isSimulator),
        screenWidth: displayInfo.width,
        screenHeight: displayInfo.height,
        refreshRate: displayInfo.refreshRate,
        isSimulator: isSimulator
      };
      this.capability = capability;
      return capability;
    } catch (error) {
      console.warn('[DevicePerformanceDetector] Failed to query display info, fallback to LOW');
      const fallback: DeviceCapability = {
        performanceLevel: PerformanceLevel.LOW,
        screenWidth: 1280,
        screenHeight: 720,
        refreshRate: 60,
        isSimulator: isSimulator
      };
      this.capability = fallback;
      return fallback;
    }
  }

  private checkIsSimulator(): boolean {
    // @ohos.deviceInfo 的属性直接可用，不需要 deviceInfo.deviceInfo
    const marketName: string = deviceInfo.marketName ?? '';
    const brand: string = deviceInfo.brand ?? '';
    const productModel: string = deviceInfo.productModel ?? '';
    
    return marketName.toLowerCase().includes('emulator') || 
           brand.toLowerCase().includes('emulator') ||
           productModel.toLowerCase().includes('emulator') ||
           productModel.toLowerCase().includes('sdk_gphone'); // 常见于 Android/Harmony 模拟器
  }

  private resolvePerformanceLevel(info: display.Display, isSimulator: boolean): PerformanceLevel {
    // Simulator usually has poor GPU emulation for video
    if (isSimulator) {
      return PerformanceLevel.LOW;
    }

    if (info.width >= 2400 && info.refreshRate >= 120) {
      return PerformanceLevel.HIGH;
    }
    if (info.width >= 1080 && info.refreshRate >= 90) {
      return PerformanceLevel.MEDIUM;
    }
    return PerformanceLevel.LOW;
  }

  private isLowEndDevice(): boolean {
    return this.capability?.performanceLevel === PerformanceLevel.LOW;
  }

  getRecommendedBackgroundMode(): BackgroundMode {
    // 强制使用VIDEO模式，不允许任何降级
    console.info('[DevicePerformanceDetector] Forcing VIDEO mode for all devices');
    return BackgroundMode.VIDEO;
  }

  getRecommendedVideoSuffix(): string {
    if (!this.capability || this.capability.isSimulator) {
      return 'hd';
    }
    if (this.capability.screenWidth >= 2400) {
      return '4k';
    }
    if (this.capability.screenWidth >= 1920) {
      return 'fullhd';
    }
    return 'hd';
  }
}
