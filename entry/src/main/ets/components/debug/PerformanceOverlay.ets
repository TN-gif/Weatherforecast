import { PerformanceLevel } from '../../common/utils/PerformanceDetector';

interface DeviceCapabilityInfo {
  performanceLevel: PerformanceLevel;
  screenWidth: number;
  screenHeight: number;
  refreshRate: number;
  ramGB: number;
  supportVideo: boolean;
  supportAnimatedImage: boolean;
}

@Component
export struct PerformanceOverlay {
  @StorageLink('performanceLevel') performanceLevel: PerformanceLevel = PerformanceLevel.LOW;
  @StorageLink('deviceCapability') deviceCapability: DeviceCapabilityInfo = {
    performanceLevel: PerformanceLevel.LOW,
    screenWidth: 720,
    screenHeight: 1280,
    refreshRate: 60,
    ramGB: 2,
    supportVideo: false,
    supportAnimatedImage: false
  };
  @State private fps: number = 0;
  @State private memoryUsage: number = 0;
  @State private isVisible: boolean = false;
  private fpsCounter: FPSCounter = new FPSCounter();

  aboutToAppear(): void {
    // 只在开发模式下显示
    const isDevelopment = AppStorage.get<boolean>('isDevelopment') || false;
    this.isVisible = isDevelopment;
    
    if (this.isVisible) {
      this.fpsCounter.start((fps: number) => {
        this.fps = fps;
      });
      this.startMemoryMonitoring();
    }
  }

  aboutToDisappear(): void {
    this.fpsCounter.stop();
  }

  build() {
    // 修复@Entry组件单根节点问题，确保总是返回一个组件
    Stack() {
      if (!this.isVisible) {
        // 不可见时返回空容器
        Column();
      } else {
      Column() {
        Text(`性能等级: ${this.performanceLevel}`)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('rgba(0,0,0,0.7)')
          .padding(4)
          .borderRadius(4);

        Text(`FPS: ${this.fps.toFixed(1)}`)
          .fontSize(12)
          .fontColor(this.getFPSColor())
          .backgroundColor('rgba(0,0,0,0.7)')
          .padding(4)
          .borderRadius(4)
          .margin({ top: 4 });

        Text(`内存: ${this.memoryUsage.toFixed(1)}MB`)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('rgba(0,0,0,0.7)')
          .padding(4)
          .borderRadius(4)
          .margin({ top: 4 });

        Text(`摇一摇: ${this.getShakeStatus()}`)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('rgba(0,0,0,0.7)')
          .padding(4)
          .borderRadius(4)
          .margin({ top: 4 });
      }
      .alignItems(HorizontalAlign.Start);
      }
    }
    .position({ x: 20, y: 80 })
    .zIndex(999);
  }

  private getFPSColor(): string {
    if (this.fps >= 55) return '#4CAF50'; // 绿色 - 良好
    if (this.fps >= 45) return '#FF9800'; // 橙色 - 一般
    return '#F44336'; // 红色 - 差
  }

  private getShakeStatus(): string {
    // 这里可以获取摇一摇检测状态
    return '启用';
  }

  private startMemoryMonitoring(): void {
    setInterval(() => {
      try {
        // 注意：实际的内存监控需要使用系统API
        // 这里使用模拟数据
        this.memoryUsage = Math.random() * 100 + 50;
      } catch (error) {
        console.error('[PerformanceOverlay] Memory monitoring error:', error);
      }
    }, 2000);
  }
}

class FPSCounter {
  private frames: number[] = [];
  private intervalId: number | null = null;
  private callback: ((fps: number) => void) | null = null;

  start(callback: (fps: number) => void): void {
    this.callback = callback;
    this.frames = [];
    
    // 使用setInterval替代requestAnimationFrame
    this.intervalId = setInterval(() => {
      const now = Date.now();
      this.frames.push(now);
      
      // 只保留最近1秒的帧
      this.frames = this.frames.filter(time => time > now - 1000);
      
      // 计算FPS
      const fps = this.frames.length;
      if (this.callback) {
        this.callback(fps);
      }
    }, 16); // 约60FPS
  }

  stop(): void {
    if (this.intervalId !== null) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.callback = null;
    this.frames = [];
  }
}
