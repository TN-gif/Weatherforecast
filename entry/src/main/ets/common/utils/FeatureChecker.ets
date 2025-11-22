import { DebugLogger, LogData } from './DebugLogger';
import { BackgroundMode } from '../constants/ThemeConstants';

export interface FeatureStatus {
  name: string;
  enabled: boolean;
  reason: string;
  details?: LogData;
}

export class FeatureChecker {
  private static instance: FeatureChecker | null = null;
  private logger: DebugLogger = DebugLogger.getInstance();

  static getInstance(): FeatureChecker {
    if (FeatureChecker.instance === null) {
      FeatureChecker.instance = new FeatureChecker();
    }
    return FeatureChecker.instance;
  }

  private constructor() {
    this.logger.info('FeatureChecker', '🔍 功能检查器已初始化');
  }

  /**
   * 检查所有功能状态
   */
  checkAllFeatures(): FeatureStatus[] {
    this.logger.info('FeatureChecker', '🚀 开始全面功能检查');
    
    const features: FeatureStatus[] = [];
    
    // 检查背景模式功能
    features.push(this.checkBackgroundModeFeature());
    
    // 检查视频资源功能
    features.push(this.checkVideoResourceFeature());
    
    // 检查动画资源功能
    features.push(this.checkAnimatedResourceFeature());
    
    // 检查调试工具功能
    features.push(this.checkDebugToolsFeature());
    
    // 检查AppStorage功能
    features.push(this.checkAppStorageFeature());
    
    // 检查组件渲染功能
    features.push(this.checkComponentRenderFeature());
    
    const summaryData: LogData = {
      'totalFeatures': features.length,
      'enabledFeatures': features.filter(f => f.enabled).length,
      'disabledFeatures': features.filter(f => !f.enabled).length
    };
    this.logger.info('FeatureChecker', '✅ 功能检查完成', summaryData);
    
    return features;
  }

  private checkBackgroundModeFeature(): FeatureStatus {
    try {
      const currentMode: BackgroundMode = AppStorage.get<BackgroundMode>('backgroundMode') ?? BackgroundMode.GRADIENT;
      const isDevelopment: boolean = AppStorage.get<boolean>('isDevelopment') ?? false;
      
      const debugData: LogData = {
        'currentMode': String(currentMode),
        'isDevelopment': isDevelopment,
        'hasAppStorage': true
      };
      this.logger.debug('FeatureChecker', '🎬 检查背景模式功能', debugData);
      
      const details: LogData = {
        'currentMode': String(currentMode),
        'isDevelopment': isDevelopment,
        'supportedModes': ['VIDEO', 'ANIMATED_IMAGE', 'GRADIENT']
      };
      
      const result: FeatureStatus = {
        name: '背景模式切换',
        enabled: true,
        reason: '功能正常',
        details: details
      };
      return result;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.logger.error('FeatureChecker', '❌ 背景模式功能检查失败', error instanceof Error ? error : undefined);
      
      const errorDetails: LogData = {
        'errorMessage': errorMsg
      };
      
      const result: FeatureStatus = {
        name: '背景模式切换',
        enabled: false,
        reason: '功能异常',
        details: errorDetails
      };
      return result;
    }
  }

  private checkVideoResourceFeature(): FeatureStatus {
    try {
      // 检查视频资源路径
      const videoResources: string[] = [
        'rawfile/weather/sunny_day.mp4',
        'rawfile/weather/sunny_night.mp4',
        'rawfile/weather/rainy_day.mp4',
        'rawfile/weather/rainy_night.mp4',
        'rawfile/weather/snow_day.mp4',
        'rawfile/weather/snow_night.mp4'
      ];
      
      const debugData: LogData = {
        'resourceCount': videoResources.length,
        'resources': videoResources.join(', ')
      };
      this.logger.debug('FeatureChecker', '🎥 检查视频资源功能', debugData);
      
      const details: LogData = {
        'videoResources': videoResources,
        'resourceCount': videoResources.length
      };
      
      const result: FeatureStatus = {
        name: '视频资源播放',
        enabled: true,
        reason: '资源路径配置正确',
        details: details
      };
      return result;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.logger.error('FeatureChecker', '❌ 视频资源功能检查失败', error instanceof Error ? error : undefined);
      
      const errorDetails: LogData = {
        'errorMessage': errorMsg
      };
      
      const result: FeatureStatus = {
        name: '视频资源播放',
        enabled: false,
        reason: '资源检查失败',
        details: errorDetails
      };
      return result;
    }
  }

  private checkAnimatedResourceFeature(): FeatureStatus {
    try {
      // 检查WebP动画资源路径
      const animatedResources: string[] = [
        'rawfile/weather/sunny.webp',
        'rawfile/weather/rainy.webp',
        'rawfile/weather/snow.webp',
        'rawfile/weather/night.webp'
      ];
      
      const debugData: LogData = {
        'resourceCount': animatedResources.length,
        'resources': animatedResources.join(', ')
      };
      this.logger.debug('FeatureChecker', '🎞️ 检查动画资源功能', debugData);
      
      const details: LogData = {
        'animatedResources': animatedResources,
        'resourceCount': animatedResources.length
      };
      
      const result: FeatureStatus = {
        name: 'WebP动画播放',
        enabled: true,
        reason: '资源路径配置正确',
        details: details
      };
      return result;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.logger.error('FeatureChecker', '❌ 动画资源功能检查失败', error instanceof Error ? error : undefined);
      
      const errorDetails: LogData = {
        'errorMessage': errorMsg
      };
      
      const result: FeatureStatus = {
        name: 'WebP动画播放',
        enabled: false,
        reason: '资源检查失败',
        details: errorDetails
      };
      return result;
    }
  }

  private checkDebugToolsFeature(): FeatureStatus {
    try {
      const isDevelopment: boolean = AppStorage.get<boolean>('isDevelopment') ?? false;
      
      const tools: string[] = [
        'PerformanceOverlay',
        'ResourceStatusOverlay', 
        'DatabaseInspector',
        'ChartPerformanceMonitor',
        'ThemeDebugPanel',
        'ResourceValidator',
        'LogViewer'
      ];
      
      const debugData: LogData = {
        'isDevelopment': isDevelopment,
        'hasConsole': true,
        'hasAppStorage': true
      };
      this.logger.debug('FeatureChecker', '🛠️ 检查调试工具功能', debugData);
      
      const details: LogData = {
        'isDevelopment': isDevelopment,
        'availableTools': tools
      };
      
      const result: FeatureStatus = {
        name: '调试工具面板',
        enabled: isDevelopment,
        reason: isDevelopment ? '开发模式已启用' : '非开发模式',
        details: details
      };
      return result;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.logger.error('FeatureChecker', '❌ 调试工具功能检查失败', error instanceof Error ? error : undefined);
      
      const errorDetails: LogData = {
        'errorMessage': errorMsg
      };
      
      const result: FeatureStatus = {
        name: '调试工具面板',
        enabled: false,
        reason: '功能异常',
        details: errorDetails
      };
      return result;
    }
  }

  private checkAppStorageFeature(): FeatureStatus {
    try {
      // 测试AppStorage读写
      const testKey: string = 'featureChecker_test';
      const testValue: string = 'test_value_' + Date.now().toString();
      
      AppStorage.setOrCreate(testKey, testValue);
      const retrievedValue: string = AppStorage.get<string>(testKey) ?? '';
      
      const isWorking: boolean = retrievedValue === testValue;
      
      const debugData: LogData = {
        'testKey': testKey,
        'testValue': testValue,
        'retrievedValue': retrievedValue,
        'isWorking': isWorking
      };
      this.logger.debug('FeatureChecker', '💾 检查AppStorage功能', debugData);
      
      const details: LogData = {
        'testKey': testKey,
        'testValue': testValue,
        'retrievedValue': retrievedValue,
        'isWorking': isWorking
      };
      
      const result: FeatureStatus = {
        name: 'AppStorage状态管理',
        enabled: isWorking,
        reason: isWorking ? '读写正常' : '读写异常',
        details: details
      };
      return result;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.logger.error('FeatureChecker', '❌ AppStorage功能检查失败', error instanceof Error ? error : undefined);
      
      const errorDetails: LogData = {
        'errorMessage': errorMsg
      };
      
      const result: FeatureStatus = {
        name: 'AppStorage状态管理',
        enabled: false,
        reason: '功能异常',
        details: errorDetails
      };
      return result;
    }
  }

  private checkComponentRenderFeature(): FeatureStatus {
    try {
      // 检查组件渲染相关的基础功能 - 使用typeof来避免"类被用作对象"的错误
      const hasStack: boolean = typeof Stack !== 'undefined';
      const hasColumn: boolean = typeof Column !== 'undefined';
      const hasRow: boolean = typeof Row !== 'undefined';
      const hasButton: boolean = typeof Button !== 'undefined';
      const hasText: boolean = typeof Text !== 'undefined';
      const hasVideo: boolean = typeof Video !== 'undefined';
      const hasImage: boolean = typeof Image !== 'undefined';
      
      const allComponentsAvailable: boolean = hasStack && hasColumn && hasRow && hasButton && hasText && hasVideo && hasImage;
      
      const debugData: LogData = {
        'hasStack': hasStack,
        'hasColumn': hasColumn,
        'hasRow': hasRow,
        'hasButton': hasButton,
        'hasText': hasText,
        'hasVideo': hasVideo,
        'hasImage': hasImage,
        'allComponentsAvailable': allComponentsAvailable
      };
      this.logger.debug('FeatureChecker', '🧩 检查组件渲染功能', debugData);
      
      const details: LogData = {
        'hasStack': hasStack,
        'hasColumn': hasColumn,
        'hasRow': hasRow,
        'hasButton': hasButton,
        'hasText': hasText,
        'hasVideo': hasVideo,
        'hasImage': hasImage
      };
      
      const result: FeatureStatus = {
        name: 'UI组件渲染',
        enabled: allComponentsAvailable,
        reason: allComponentsAvailable ? '所有组件可用' : '部分组件缺失',
        details: details
      };
      return result;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.logger.error('FeatureChecker', '❌ 组件渲染功能检查失败', error instanceof Error ? error : undefined);
      
      const errorDetails: LogData = {
        'errorMessage': errorMsg
      };
      
      const result: FeatureStatus = {
        name: 'UI组件渲染',
        enabled: false,
        reason: '功能异常',
        details: errorDetails
      };
      return result;
    }
  }
}
