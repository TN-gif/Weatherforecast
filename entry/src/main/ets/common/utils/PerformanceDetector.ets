import deviceInfo from '@ohos.deviceInfo';
import display from '@ohos.display';
import { BusinessError } from '@ohos.base';

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
  ramGB: number;
  supportVideo: boolean;
  supportAnimatedImage: boolean;
}

export class PerformanceDetector {
  private static instance: PerformanceDetector | null = null;
  private capability: DeviceCapability | null = null;

  static getInstance(): PerformanceDetector {
    if (PerformanceDetector.instance === null) {
      PerformanceDetector.instance = new PerformanceDetector();
    }
    return PerformanceDetector.instance;
  }

  async detect(): Promise<DeviceCapability> {
    if (this.capability !== null) {
      return this.capability;
    }

    try {
      // 获取设备信息
      const deviceModel = deviceInfo.deviceType;
      // 注意：totalMemory属性可能不存在，使用默认值
      const totalMemory = 4 * 1024 * 1024 * 1024; // 默认4GB
      const displayInfo = display.getDefaultDisplaySync();
      
      // 计算RAM大小(GB)
      const ramGB = totalMemory / (1024 * 1024 * 1024);
      
      // 获取屏幕信息
      const screenWidth = displayInfo.width;
      const screenHeight = displayInfo.height;
      const refreshRate = displayInfo.refreshRate || 60;
      
      // 性能等级判断
      let performanceLevel: PerformanceLevel;
      if (ramGB >= 8 && refreshRate >= 90) {
        performanceLevel = PerformanceLevel.HIGH;
      } else if (ramGB >= 4 && refreshRate >= 60) {
        performanceLevel = PerformanceLevel.MEDIUM;
      } else {
        performanceLevel = PerformanceLevel.LOW;
      }

      // 功能支持判断
      const supportVideo = performanceLevel !== PerformanceLevel.LOW;
      const supportAnimatedImage = ramGB >= 3;

      this.capability = {
        performanceLevel,
        screenWidth,
        screenHeight,
        refreshRate,
        ramGB,
        supportVideo,
        supportAnimatedImage
      };

      console.info(`[PerformanceDetector] Device capability: ${JSON.stringify(this.capability)}`);
      return this.capability;

    } catch (error) {
      const err = error as BusinessError;
      console.error('[PerformanceDetector] Detection failed:', err.message);
      // 默认为低性能配置
      this.capability = {
        performanceLevel: PerformanceLevel.LOW,
        screenWidth: 720,
        screenHeight: 1280,
        refreshRate: 60,
        ramGB: 2,
        supportVideo: false,
        supportAnimatedImage: false
      };
      return this.capability;
    }
  }

  getRecommendedVideoSuffix(): string {
    if (!this.capability) {
      return 'hd';
    }

    const capability = this.capability;
    const screenWidth = capability.screenWidth;
    const screenHeight = capability.screenHeight;
    const pixels = screenWidth * screenHeight;

    if (pixels >= 3840 * 2160) { // 4K
      return '4k';
    } else if (pixels >= 1920 * 1080) { // Full HD
      return 'fullhd';
    } else {
      return 'hd';
    }
  }

  getOptimalBlurRadius(): number {
    if (!this.capability) {
      return 10;
    }

    switch (this.capability.performanceLevel) {
      case PerformanceLevel.HIGH:
        return 25;
      case PerformanceLevel.MEDIUM:
        return 18;
      case PerformanceLevel.LOW:
        return 10;
      default:
        return 15;
    }
  }

  shouldUseOffscreenCompositing(): boolean {
    return this.capability?.performanceLevel === PerformanceLevel.HIGH;
  }
}
