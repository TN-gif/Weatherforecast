import resourceManager from '@ohos.resourceManager';
import type common from '@ohos.app.ability.common';
import { ResourceHealthChecker, ResourceHealthReport } from './ResourceHealthChecker';
import { LogHelper } from './LogHelper';

export class ResourceManager {
  private static instance: ResourceManager | null = null;
  private resourceManager: resourceManager.ResourceManager | null = null;
  private healthChecker: ResourceHealthChecker = ResourceHealthChecker.getInstance();
  private lastHealthReport: ResourceHealthReport | null = null;

  private constructor() {}

  static getInstance(): ResourceManager {
    if (ResourceManager.instance === null) {
      ResourceManager.instance = new ResourceManager();
    }
    return ResourceManager.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.resourceManager = context.resourceManager;
      await this.healthChecker.init(this.resourceManager);
      
      // 执行初始健康检查
      await this.performHealthCheck();
      
      LogHelper.info('ResourceManager', 'Health check completed successfully');
    } catch (error) {
      LogHelper.error('ResourceManager', 'Initialization failed', error);
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 执行资源健康检查
   */
  async performHealthCheck(): Promise<ResourceHealthReport> {
    if (!this.resourceManager) {
      throw new Error('ResourceManager not initialized');
    }

    try {
      LogHelper.info('ResourceManager', '开始资源健康检查...');
      const report = await this.healthChecker.performFullHealthCheck();
      this.lastHealthReport = report;
      
      // 输出检查报告
      const reportText = this.healthChecker.generateReport(report);
      LogHelper.info('ResourceManager', `资源健康检查报告:\n${reportText}`);
      
      return report;
    } catch (error) {
      LogHelper.error('ResourceManager', 'Health check failed', error instanceof Error ? error : new Error(String(error)));
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 获取最后一次健康检查报告
   */
  getLastHealthReport(): ResourceHealthReport | null {
    return this.lastHealthReport;
  }

  /**
   * 检查特定资源是否存在
   */
  async checkResourceExists(resourcePath: string): Promise<boolean> {
    if (!this.resourceManager) {
      return false;
    }

    try {
      const cleanPath = resourcePath.replace(/^rawfile\//, '');
      const descriptor = await this.resourceManager.getRawFileDescriptor(cleanPath);
      
      if (descriptor && descriptor.fd >= 0) {
        await this.resourceManager.closeRawFileDescriptor(cleanPath);
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取资源建议
   */
  getResourceSuggestions(): string[] {
    if (!this.lastHealthReport) {
      return ['请先执行资源健康检查'];
    }
    
    return this.healthChecker.getSuggestions(this.lastHealthReport);
  }

  /**
   * 获取资源健康度百分比
   */
  getResourceHealthPercentage(): number {
    if (!this.lastHealthReport) {
      return 0;
    }
    
    return this.lastHealthReport.overallHealth;
  }

  /**
   * 是否需要降级到渐变背景
   */
  shouldFallbackToGradient(): boolean {
    if (!this.lastHealthReport) {
      return true;
    }
    
    // 如果健康度低于30%，建议降级到渐变背景
    return this.lastHealthReport.overallHealth < 30;
  }

  /**
   * 获取可用的主题列表
   */
  getAvailableThemes(): string[] {
    if (!this.lastHealthReport) {
      return [];
    }
    
    return this.lastHealthReport.results
      .filter(result => result.isHealthy)
      .map(result => result.themeKey);
  }

  /**
   * 获取缺失资源的主题列表
   */
  getMissingResourceThemes(): string[] {
    if (!this.lastHealthReport) {
      return [];
    }
    
    return this.lastHealthReport.results
      .filter(result => !result.isHealthy)
      .map(result => result.themeKey);
  }
}
