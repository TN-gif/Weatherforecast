export interface ChartPerformanceConfig {
  enableCaching: boolean;
  maxDataPoints: number;
  updateThrottleMs: number;
  renderingStrategy: RenderingStrategy;
  memoryThresholdMB: number;
}

export enum RenderingStrategy {
  IMMEDIATE = 'immediate',
  THROTTLED = 'throttled',
  BATCHED = 'batched'
}

export interface PerformanceMetrics {
  renderTime: number;
  memoryUsage: number;
  frameRate: number;
  dataPointCount: number;
  cacheHitRate: number;
}

interface CachedRender {
  key: string;
  data: string;
  timestamp: number;
}

export class ChartPerformanceOptimizer {
  private static instance: ChartPerformanceOptimizer | null = null;
  private config: ChartPerformanceConfig;
  private renderCache: Map<string, CachedRender> = new Map<string, CachedRender>();
  private lastRenderTime: number = 0;
  private frameCount: number = 0;
  private lastFrameTime: number = 0;

  private constructor() {
    this.config = this.getDefaultConfig();
  }

  static getInstance(): ChartPerformanceOptimizer {
    if (ChartPerformanceOptimizer.instance === null) {
      ChartPerformanceOptimizer.instance = new ChartPerformanceOptimizer();
    }
    return ChartPerformanceOptimizer.instance;
  }

  private getDefaultConfig(): ChartPerformanceConfig {
    const performanceLevel = AppStorage.get<string>('performanceLevel') || 'low';
    
    switch (performanceLevel) {
      case 'high':
        return {
          enableCaching: true,
          maxDataPoints: 48,
          updateThrottleMs: 100,
          renderingStrategy: RenderingStrategy.IMMEDIATE,
          memoryThresholdMB: 50
        };
      case 'medium':
        return {
          enableCaching: true,
          maxDataPoints: 24,
          updateThrottleMs: 200,
          renderingStrategy: RenderingStrategy.THROTTLED,
          memoryThresholdMB: 30
        };
      default:
        return {
          enableCaching: false,
          maxDataPoints: 12,
          updateThrottleMs: 500,
          renderingStrategy: RenderingStrategy.BATCHED,
          memoryThresholdMB: 20
        };
    }
  }

  /**
   * 优化数据点数量
   */
  optimizeDataPoints<T>(data: T[], maxPoints?: number): T[] {
    const limit = maxPoints || this.config.maxDataPoints;
    
    if (data.length <= limit) {
      return data;
    }

    // 使用采样算法减少数据点
    const step = Math.ceil(data.length / limit);
    const optimized: T[] = [];
    
    for (let i = 0; i < data.length; i += step) {
      optimized.push(data[i]);
    }
    
    // 确保包含最后一个数据点
    if (optimized[optimized.length - 1] !== data[data.length - 1]) {
      optimized.push(data[data.length - 1]);
    }
    
    console.info(`[ChartPerformanceOptimizer] Optimized data points: ${data.length} -> ${optimized.length}`);
    return optimized;
  }

  /**
   * 缓存渲染结果
   */
  getCachedRender(key: string): string | null {
    if (!this.config.enableCaching) {
      return null;
    }
    
    const cached = this.renderCache.get(key);
    return cached ? cached.data : null;
  }

  setCachedRender(key: string, value: string): void {
    if (!this.config.enableCaching) {
      return;
    }
    
    // 限制缓存大小
    if (this.renderCache.size > 50) {
      const firstKey: string = this.renderCache.keys().next().value as string;
      this.renderCache.delete(firstKey);
    }
    
    const cachedRender: CachedRender = {
      key,
      data: value,
      timestamp: Date.now()
    };
    
    this.renderCache.set(key, cachedRender);
  }

  /**
   * 检查是否应该跳过渲染（节流）
   */
  shouldSkipRender(): boolean {
    const now = Date.now();
    const timeSinceLastRender = now - this.lastRenderTime;
    
    if (timeSinceLastRender < this.config.updateThrottleMs) {
      return true;
    }
    
    this.lastRenderTime = now;
    return false;
  }

  /**
   * 记录渲染性能指标
   */
  recordRenderMetrics(renderTime: number, dataPointCount: number): void {
    const now = Date.now();
    
    // 计算帧率
    if (this.lastFrameTime > 0) {
      const frameTime = now - this.lastFrameTime;
      this.frameCount++;
      
      // 每秒重置帧计数
      if (this.frameCount >= 60) {
        const fps = 1000 / (frameTime / this.frameCount);
        console.info(`[ChartPerformanceOptimizer] FPS: ${fps.toFixed(1)}, Render time: ${renderTime}ms`);
        this.frameCount = 0;
      }
    }
    
    this.lastFrameTime = now;
    
    // 记录性能警告
    if (renderTime > 16) { // 超过16ms可能影响60fps
      console.warn(`[ChartPerformanceOptimizer] Slow render detected: ${renderTime}ms for ${dataPointCount} points`);
    }
  }

  /**
   * 获取性能指标
   */
  getPerformanceMetrics(): PerformanceMetrics {
    const cacheHitRate = this.renderCache.size > 0 ? 
      (this.renderCache.size / (this.renderCache.size + 10)) * 100 : 0;
    
    return {
      renderTime: this.lastRenderTime,
      memoryUsage: this.estimateMemoryUsage(),
      frameRate: this.estimateFrameRate(),
      dataPointCount: this.config.maxDataPoints,
      cacheHitRate: cacheHitRate
    };
  }

  /**
   * 估算内存使用量
   */
  private estimateMemoryUsage(): number {
    // 简单估算：缓存大小 * 平均对象大小
    return this.renderCache.size * 0.5; // MB
  }

  /**
   * 估算帧率
   */
  private estimateFrameRate(): number {
    if (this.lastFrameTime === 0) return 0;
    
    const now = Date.now();
    const frameTime = now - this.lastFrameTime;
    return frameTime > 0 ? 1000 / frameTime : 0;
  }

  /**
   * 清理缓存
   */
  clearCache(): void {
    this.renderCache.clear();
    console.info('[ChartPerformanceOptimizer] Cache cleared');
  }

  /**
   * 更新配置
   */
  updateConfig(newConfig: Partial<ChartPerformanceConfig>): void {
    const updatedConfig: ChartPerformanceConfig = {
      enableCaching: newConfig.enableCaching ?? this.config.enableCaching,
      maxDataPoints: newConfig.maxDataPoints ?? this.config.maxDataPoints,
      updateThrottleMs: newConfig.updateThrottleMs ?? this.config.updateThrottleMs,
      renderingStrategy: newConfig.renderingStrategy ?? this.config.renderingStrategy,
      memoryThresholdMB: newConfig.memoryThresholdMB ?? this.config.memoryThresholdMB
    };
    this.config = updatedConfig;
    console.info('[ChartPerformanceOptimizer] Config updated');
  }

  /**
   * 获取当前配置
   */
  getConfig(): ChartPerformanceConfig {
    const config: ChartPerformanceConfig = {
      enableCaching: this.config.enableCaching,
      maxDataPoints: this.config.maxDataPoints,
      updateThrottleMs: this.config.updateThrottleMs,
      renderingStrategy: this.config.renderingStrategy,
      memoryThresholdMB: this.config.memoryThresholdMB
    };
    return config;
  }

  /**
   * 检查内存使用是否超过阈值
   */
  isMemoryThresholdExceeded(): boolean {
    const currentUsage = this.estimateMemoryUsage();
    return currentUsage > this.config.memoryThresholdMB;
  }

  /**
   * 自动优化配置
   */
  autoOptimize(): void {
    const metrics = this.getPerformanceMetrics();
    
    // 如果渲染时间过长，降低数据点数量
    if (metrics.renderTime > 50) {
      this.config.maxDataPoints = Math.max(6, this.config.maxDataPoints - 6);
      console.info(`[ChartPerformanceOptimizer] Reduced max data points to ${this.config.maxDataPoints}`);
    }
    
    // 如果内存使用过高，清理缓存
    if (this.isMemoryThresholdExceeded()) {
      this.clearCache();
      this.config.enableCaching = false;
      console.warn('[ChartPerformanceOptimizer] Disabled caching due to memory pressure');
    }
    
    // 如果帧率过低，增加节流时间
    if (metrics.frameRate < 30 && metrics.frameRate > 0) {
      this.config.updateThrottleMs = Math.min(1000, this.config.updateThrottleMs + 100);
      console.info(`[ChartPerformanceOptimizer] Increased throttle to ${this.config.updateThrottleMs}ms`);
    }
  }
}
