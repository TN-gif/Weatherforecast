import resourceManager from '@ohos.resourceManager';
import { ThemeConstants, VideoThemeAsset, BackgroundMode } from '../constants/ThemeConstants';
import { LogHelper } from './LogHelper';

export interface ResourceCheckResult {
  themeKey: string;
  videoExists: boolean;
  animatedImageExists: boolean;
  lottieExists: boolean;
  isHealthy: boolean;
  missingResources: string[];
}

export interface ResourceHealthReport {
  totalThemes: number;
  healthyThemes: number;
  unhealthyThemes: number;
  results: ResourceCheckResult[];
  overallHealth: number; // 0-100 percentage
}

export class ResourceHealthChecker {
  private static instance: ResourceHealthChecker | null = null;
  private resourceManager: resourceManager.ResourceManager | null = null;
  private lastReport: ResourceHealthReport | null = null;

  private constructor() {}

  static getInstance(): ResourceHealthChecker {
    if (ResourceHealthChecker.instance === null) {
      ResourceHealthChecker.instance = new ResourceHealthChecker();
    }
    return ResourceHealthChecker.instance;
  }

  async init(resMgr: resourceManager.ResourceManager): Promise<void> {
    this.resourceManager = resMgr;
    LogHelper.info('ResourceHealthChecker', 'Initialized with resource manager');
  }

  async detect(): Promise<void> {
    this.lastReport = await this.performFullHealthCheck();
  }

  getRecommendedBackgroundMode(): BackgroundMode {
    if (!this.lastReport) {
      return BackgroundMode.GRADIENT;
    }
    // 如果健康度大于 50%，推荐 VIDEO 模式（如果支持），否则 GRADIENT
    // 这里简单返回 VIDEO，实际逻辑可以在 AtmosphereBackground 中进一步判断
    return this.lastReport.overallHealth > 50 ? BackgroundMode.VIDEO : BackgroundMode.GRADIENT;
  }

  /**
   * 执行完整的资源健康检查
   */
  async performFullHealthCheck(): Promise<ResourceHealthReport> {
    LogHelper.info('ResourceHealthChecker', '开始全面资源健康检查...');
    
    if (!this.resourceManager) {
      throw new Error('ResourceManager not initialized');
    }

    const themes = ThemeConstants.THEMES;
    const results: ResourceCheckResult[] = [];

    for (const theme of themes) {
      LogHelper.info('ResourceHealthChecker', `检查主题: ${theme.themeKey}`);
      const result = await this.checkThemeResources(theme);
      results.push(result);
      
      if (result.isHealthy) {
        LogHelper.info('ResourceHealthChecker', `✅ ${theme.themeKey} 健康`);
      } else {
        LogHelper.warn('ResourceHealthChecker', `❌ ${theme.themeKey} 缺失资源: ${result.missingResources.join(', ')}`);
      }
    }

    const healthyCount = results.filter(r => r.isHealthy).length;
    const overallHealth = Math.round((healthyCount / results.length) * 100);

    const report: ResourceHealthReport = {
      totalThemes: results.length,
      healthyThemes: healthyCount,
      unhealthyThemes: results.length - healthyCount,
      results: results,
      overallHealth: overallHealth
    };

    LogHelper.info('ResourceHealthChecker', `检查完成: ${overallHealth}% 健康`);
    return report;
  }

  /**
   * 检查单个主题的资源
   */
  private async checkThemeResources(theme: VideoThemeAsset): Promise<ResourceCheckResult> {
    const missingResources: string[] = [];
    
    // 检查视频资源
    const videoExists = theme.videoResource ? await this.checkRawFileExists(theme.videoResource) : true;
    if (theme.videoResource && !videoExists) {
      LogHelper.warn('ResourceHealthChecker', `视频资源不存在: ${theme.videoResource}`);
      missingResources.push(`video: ${theme.videoResource}`);
    }

    // 检查WebP动画资源
    const animatedImageExists = theme.animatedImageResource ? await this.checkRawFileExists(theme.animatedImageResource) : true;
    if (theme.animatedImageResource && !animatedImageExists) {
      LogHelper.warn('ResourceHealthChecker', `WebP动画资源不存在: ${theme.animatedImageResource}`);
      missingResources.push(`webp: ${theme.animatedImageResource}`);
    }

    // 检查Lottie资源
    const lottieExists = theme.lottieResource ? await this.checkRawFileExists(theme.lottieResource) : true;
    if (theme.lottieResource && !lottieExists) {
      LogHelper.warn('ResourceHealthChecker', `Lottie动画资源不存在: ${theme.lottieResource}`);
      missingResources.push(`lottie: ${theme.lottieResource}`);
    }

    const isHealthy = missingResources.length === 0;

    return {
      themeKey: theme.themeKey,
      videoExists,
      animatedImageExists,
      lottieExists,
      isHealthy,
      missingResources
    };
  }

  /**
   * 检查rawfile资源是否存在
   */
  private async checkRawFileExists(resourcePath: string): Promise<boolean> {
    if (!this.resourceManager) {
      return false;
    }

    try {
      // 移除rawfile/前缀，因为getRawFileDescriptor不需要这个前缀
      const cleanPath = resourcePath.replace(/^rawfile\//, '');
      const descriptor = await this.resourceManager.getRawFileDescriptor(cleanPath);
      
      if (descriptor && descriptor.fd >= 0) {
        // 关闭文件描述符
        try {
          await this.resourceManager.closeRawFileDescriptor(cleanPath);
        } catch (closeError) {
          LogHelper.warn('ResourceHealthChecker', `Failed to close descriptor for ${cleanPath}`);
        }
        return true;
      }
      return false;
    } catch (error) {
      LogHelper.debug('ResourceHealthChecker', `Resource not found: ${resourcePath}`);
      return false;
    }
  }

  /**
   * 获取缺失资源的建议
   */
  getSuggestions(report: ResourceHealthReport): string[] {
    const suggestions: string[] = [];

    if (report.overallHealth < 50) {
      suggestions.push('⚠️ 资源健康度过低，建议立即补充缺失的视频和动画文件');
    }

    const missingVideos = report.results.filter(r => !r.videoExists && r.missingResources.some(m => m.includes('video')));
    if (missingVideos.length > 0) {
      suggestions.push(`📹 缺失 ${missingVideos.length} 个视频文件，将自动降级到WebP动画`);
    }

    const missingWebP = report.results.filter(r => !r.animatedImageExists && r.missingResources.some(m => m.includes('webp')));
    if (missingWebP.length > 0) {
      suggestions.push(`🖼️ 缺失 ${missingWebP.length} 个WebP动画，将降级到静态渐变背景`);
    }

    const missingLottie = report.results.filter(r => !r.lottieExists && r.missingResources.some(m => m.includes('lottie')));
    if (missingLottie.length > 0) {
      suggestions.push(`✨ 缺失 ${missingLottie.length} 个Lottie动画，界面装饰效果将受影响`);
    }

    if (suggestions.length === 0) {
      suggestions.push('✅ 所有资源完整，可以享受完整的沉浸式体验');
    }

    return suggestions;
  }

  /**
   * 生成资源状态报告
   */
  generateReport(report: ResourceHealthReport): string {
    const lines: string[] = [];
    lines.push('=== 资源健康检查报告 ===');
    lines.push(`总体健康度: ${report.overallHealth}%`);
    lines.push(`健康主题: ${report.healthyThemes}/${report.totalThemes}`);
    lines.push('');

    for (const result of report.results) {
      const status = result.isHealthy ? '✅' : '❌';
      lines.push(`${status} ${result.themeKey}`);
      
      if (!result.isHealthy) {
        result.missingResources.forEach(missing => {
          lines.push(`   - 缺失: ${missing}`);
        });
      }
    }

    lines.push('');
    lines.push('=== 建议 ===');
    this.getSuggestions(report).forEach(suggestion => {
      lines.push(suggestion);
    });

    return lines.join('\n');
  }
}
