import { ChartPerformanceOptimizer, PerformanceMetrics } from '../../common/utils/ChartPerformanceOptimizer';

@Component
export struct ChartPerformanceMonitor {
  @State private showMonitor: boolean = false;
  @State private metrics: PerformanceMetrics | null = null;
  @State private isMonitoring: boolean = false;
  @State private updateInterval: number | null = null;

  private optimizer: ChartPerformanceOptimizer = ChartPerformanceOptimizer.getInstance();

  aboutToAppear(): void {
    // 在开发模式下显示性能监控
    const isDevelopment = AppStorage.get<boolean>('isDevelopment') || false;
    this.showMonitor = isDevelopment;
    
    if (this.showMonitor) {
      this.startMonitoring();
    }
  }

  aboutToDisappear(): void {
    this.stopMonitoring();
  }

  build() {
    Stack() {
      if (this.showMonitor) {
      Column() {
        this.renderHeader();
        this.renderMetrics();
        this.renderControls();
      }
      .width(280)
      .padding(12)
      .backgroundColor('rgba(0, 0, 0, 0.85)')
      .borderRadius(8)
      .margin({ top: 200, right: 16 });
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .position({ x: 0, y: 0 });
  }

  @Builder
  private renderHeader(): void {
    Row() {
      Text('图表性能监控')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White);
      
      Blank();
      
      Button(this.isMonitoring ? '停止' : '开始')
        .onClick(() => {
          if (this.isMonitoring) {
            this.stopMonitoring();
          } else {
            this.startMonitoring();
          }
        })
        .fontSize(12)
        .height(24)
        .backgroundColor(this.isMonitoring ? 'rgba(255, 0, 0, 0.6)' : 'rgba(0, 200, 0, 0.6)');
      
      Button('×')
        .onClick(() => {
          this.showMonitor = false;
        })
        .fontSize(16)
        .width(24)
        .height(24)
        .backgroundColor('rgba(255, 0, 0, 0.3)')
        .margin({ left: 8 });
    }
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  private renderMetrics(): void {
    if (this.metrics) {
      Column() {
        this.renderMetricItem('渲染时间', `${this.metrics.renderTime.toFixed(1)}ms`, this.getRenderTimeColor(this.metrics.renderTime));
        this.renderMetricItem('帧率', `${this.metrics.frameRate.toFixed(1)} FPS`, this.getFrameRateColor(this.metrics.frameRate));
        this.renderMetricItem('内存使用', `${this.metrics.memoryUsage.toFixed(1)}MB`, this.getMemoryColor(this.metrics.memoryUsage));
        this.renderMetricItem('数据点数', `${this.metrics.dataPointCount}`, Color.White);
        this.renderMetricItem('缓存命中率', `${this.metrics.cacheHitRate.toFixed(1)}%`, this.getCacheHitColor(this.metrics.cacheHitRate));
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    } else {
      Text('暂无性能数据')
        .fontSize(14)
        .fontColor('rgba(255,255,255,0.6)')
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(100);
    }
  }

  @Builder
  private renderMetricItem(label: string, value: string, color: string | Color): void {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.8)')
        .layoutWeight(1);
      
      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(color);
    }
    .width('100%')
    .margin({ bottom: 6 });
  }

  @Builder
  private renderControls(): void {
    Column() {
      Divider()
        .color('rgba(255,255,255,0.2)')
        .margin({ top: 8, bottom: 8 });
      
      Text('性能控制')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .margin({ bottom: 8 });

      Row() {
        Button('清理缓存')
          .onClick(() => {
            this.optimizer.clearCache();
          })
          .fontSize(11)
          .height(28)
          .backgroundColor('rgba(255, 165, 0, 0.6)')
          .layoutWeight(1);
        
        Button('自动优化')
          .onClick(() => {
            this.optimizer.autoOptimize();
          })
          .fontSize(11)
          .height(28)
          .backgroundColor('rgba(0, 122, 255, 0.6)')
          .layoutWeight(1)
          .margin({ left: 8 });
      }
      .width('100%');

      Text('性能控制')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('rgba(255,255,255,0.8)')
        .margin({ top: 8, bottom: 4 });
      
      Text(`最大数据点: ${this.optimizer.getConfig().maxDataPoints}`)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.6)');
      
      Text(`节流间隔: ${this.optimizer.getConfig().updateThrottleMs}ms`)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.6)');
      
      Text(`缓存: ${this.optimizer.getConfig().enableCaching ? '启用' : '禁用'}`)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.6)');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  private startMonitoring(): void {
    this.isMonitoring = true;
    this.updateMetrics();
    
    this.updateInterval = setInterval(() => {
      this.updateMetrics();
    }, 1000);
  }

  private stopMonitoring(): void {
    this.isMonitoring = false;
    
    if (this.updateInterval !== null) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
  }

  private updateMetrics(): void {
    this.metrics = this.optimizer.getPerformanceMetrics();
  }

  private getRenderTimeColor(renderTime: number): string {
    if (renderTime < 16) return '#4CAF50'; // 绿色 - 良好
    if (renderTime < 33) return '#FFC107'; // 黄色 - 一般
    return '#F44336'; // 红色 - 差
  }

  private getFrameRateColor(frameRate: number): string {
    if (frameRate >= 50) return '#4CAF50'; // 绿色 - 流畅
    if (frameRate >= 30) return '#FFC107'; // 黄色 - 可接受
    return '#F44336'; // 红色 - 卡顿
  }

  private getMemoryColor(memory: number): string {
    if (memory < 20) return '#4CAF50'; // 绿色 - 正常
    if (memory < 40) return '#FFC107'; // 黄色 - 注意
    return '#F44336'; // 红色 - 警告
  }

  private getCacheHitColor(hitRate: number): string {
    if (hitRate >= 80) return '#4CAF50'; // 绿色 - 优秀
    if (hitRate >= 50) return '#FFC107'; // 黄色 - 良好
    return '#F44336'; // 红色 - 需要优化
  }
}
