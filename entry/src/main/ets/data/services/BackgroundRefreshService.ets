import { WeatherController, CityWeatherState } from '../../viewmodel/WeatherController';

export type RefreshCallback = (states: CityWeatherState[]) => void;

export class BackgroundRefreshService {
  private static instance: BackgroundRefreshService;
  private refreshIntervalId: number = -1;
  private controller: WeatherController | null = null;
  private refreshCallback: RefreshCallback | null = null;
  private isRefreshing: boolean = false;
  private refreshCount: number = 0;
  private readonly REFRESH_INTERVAL_MS: number = 5 * 60 * 1000; // 5分钟刷新一次

  private constructor() {
    console.info('[BackgroundRefreshService] 🏗️ 后台刷新服务实例创建');
  }

  static getInstance(): BackgroundRefreshService {
    if (!BackgroundRefreshService.instance) {
      BackgroundRefreshService.instance = new BackgroundRefreshService();
    }
    return BackgroundRefreshService.instance;
  }

  setController(controller: WeatherController, callback: RefreshCallback): void {
    this.controller = controller;
    this.refreshCallback = callback;
    console.info('[BackgroundRefreshService] ✅ 控制器和回调已设置');
  }

  startAutoRefresh(): void {
    if (this.refreshIntervalId !== -1) {
      console.warn('[BackgroundRefreshService] ⚠️ 自动刷新已在运行中');
      return;
    }

    console.info('[BackgroundRefreshService] 🔄 启动后台自动刷新服务');
    console.info(`[BackgroundRefreshService] ⏱️ 刷新间隔: ${this.REFRESH_INTERVAL_MS / 1000}秒 (${this.REFRESH_INTERVAL_MS / 60000}分钟)`);

    this.refreshIntervalId = setInterval(() => {
      this.performBackgroundRefresh();
    }, this.REFRESH_INTERVAL_MS);

    console.info('[BackgroundRefreshService] ✅ 后台自动刷新服务已启动');
  }

  stopAutoRefresh(): void {
    if (this.refreshIntervalId === -1) {
      console.warn('[BackgroundRefreshService] ⚠️ 自动刷新未运行');
      return;
    }

    console.info('[BackgroundRefreshService] 🛑 停止后台自动刷新服务');
    console.info(`[BackgroundRefreshService] 📊 本次运行期间共执行了 ${this.refreshCount} 次后台刷新`);
    clearInterval(this.refreshIntervalId);
    this.refreshIntervalId = -1;
    this.refreshCount = 0;
    console.info('[BackgroundRefreshService] ✅ 后台自动刷新服务已停止');
  }

  private async performBackgroundRefresh(): Promise<void> {
    console.info(`[BackgroundRefreshService] ⏰ 定时器触发，准备执行第 ${this.refreshCount + 1} 次后台刷新`);
    
    if (this.isRefreshing) {
      console.debug('[BackgroundRefreshService] ⏸️ 上一次刷新尚未完成，跳过本次刷新');
      return;
    }

    if (!this.controller) {
      console.warn('[BackgroundRefreshService] ⚠️ 控制器未设置，无法执行刷新');
      return;
    }

    try {
      this.isRefreshing = true;
      this.refreshCount++;
      const startTime = Date.now();
      console.info(`[BackgroundRefreshService] 🔄 开始第 ${this.refreshCount} 次后台刷新天气数据...`);
      console.info(`[BackgroundRefreshService] ⏰ 开始时间: ${new Date().toISOString()}`);

      // 后台刷新不更新GPS定位，只刷新天气数据
      const states = await this.controller.loadAll(false);

      const duration = Date.now() - startTime;
      console.info(`[BackgroundRefreshService] ✅ 第 ${this.refreshCount} 次后台刷新完成，耗时: ${duration}ms`);
      console.info(`[BackgroundRefreshService] 📊 获取到 ${states.length} 个城市的天气数据`);

      // 通知UI更新
      if (this.refreshCallback) {
        const validStates = states.filter(state => state && state.city && state.city.id);
        this.refreshCallback(validStates);
        console.info(`[BackgroundRefreshService] 📢 已通知UI更新，有效状态数: ${validStates.length}`);
      }
    } catch (error) {
      console.error(`[BackgroundRefreshService] ❌ 第 ${this.refreshCount} 次后台刷新失败:`, error);
      console.error('[BackgroundRefreshService] ❌ 错误详情:', (error as Error).message);
    } finally {
      this.isRefreshing = false;
      console.info(`[BackgroundRefreshService] 📊 后台刷新状态重置: isRefreshing=${this.isRefreshing}`);
    }
  }

  isRunning(): boolean {
    return this.refreshIntervalId !== -1;
  }

  getRefreshCount(): number {
    return this.refreshCount;
  }
}
