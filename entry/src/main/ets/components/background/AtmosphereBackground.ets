import { DebugLogger, LogData } from '../../common/utils/DebugLogger';
import { BackgroundMode, ThemeConstants } from '../../common/constants/ThemeConstants';

@Component
export struct AtmosphereBackground {
  @StorageProp('backgroundMode') backgroundMode: BackgroundMode = BackgroundMode.VIDEO;
  @StorageProp('themeKey') @Watch('onThemeChange') themeKey: string = 'sunny_day';
  
  @State private videoPrepared: boolean = false;
  @State private retryCount: number = 0;
  @State private currentVideoSource: string = '';
  @State private nextVideoSource: string = '';
  @State private isTransitioning: boolean = false;
  
  private logger: DebugLogger = DebugLogger.getInstance();
  
  // 视频资源路径
  @State private videoSource: string = '';
  // 视频控制器 - 用于性能优化
  private videoController: VideoController = new VideoController();

  aboutToAppear(): void {
    const initData: LogData = {
      'themeKey': this.themeKey,
      'backgroundMode': String(this.backgroundMode)
    };
    this.logger.lifecycle('AtmosphereBackground', 'aboutToAppear 开始', initData);
    
    // 强制设置为VIDEO模式
    this.backgroundMode = BackgroundMode.VIDEO;
    this.updateVideoSource();
    this.currentVideoSource = this.videoSource;
    
    this.logger.lifecycle('AtmosphereBackground', 'aboutToAppear 完成');
  }

  private updateVideoSource(): void {
    // 🔧 修复：使用 ThemeConstants 获取正确的视频路径
    const theme = ThemeConstants.getTheme(this.themeKey);
    let rawPath = theme.videoResource || 'rawfile/weather/sunny_day.mp4';
    
    // 移除 'rawfile/' 前缀，因为 $rawfile() 会自动添加
    if (rawPath.startsWith('rawfile/')) {
      rawPath = rawPath.substring(8); // 移除 'rawfile/'
    }
    
    this.videoSource = rawPath;
    this.retryCount = 0; // Reset retry count on theme change
    
    const assetData: LogData = {
      'themeKey': this.themeKey,
      'videoSource': this.videoSource,
      'fullPath': `rawfile/${this.videoSource}`
    };
    this.logger.info('AtmosphereBackground', '📁 视频资源路径', assetData);
  }

  private onThemeChange(): void {
    const logData: LogData = {
      'newTheme': this.themeKey
    };
    this.logger.info('AtmosphereBackground', '🎨 主题变更', logData);
    
    // 🔧 性能优化：只有当视频源真正变化时才更新
    const oldSource = this.videoSource;
    this.updateVideoSource();
    
    if (oldSource !== this.videoSource) {
      this.videoPrepared = false;
      this.currentVideoSource = this.videoSource;
    }
  }

  build() {
    Stack() {
      // 只渲染视频背景，不允许任何降级
      this.renderVideoBackground();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black) // 兜底背景色，防止视频加载前的白屏
  }

  @Builder
  private renderVideoBackground(): void {
    // 🔧 性能优化：使用视频控制器，减少不必要的重建
    Video({ 
      src: $rawfile(this.currentVideoSource),
      controller: this.videoController
    })
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Cover)
      .autoPlay(true)
      .loop(true)
      .muted(true)
      .controls(false)
      // 🔧 性能优化：使用稳定的key，避免频繁重建
      .key(`video_main_${this.currentVideoSource}`)
      .onError((error) => {
        const errorData: LogData = {
          'videoSource': this.currentVideoSource,
          'themeKey': this.themeKey,
          'errorInfo': error ? JSON.stringify(error) : 'Unknown error',
          'retryCount': this.retryCount
        };
        this.logger.error('AtmosphereBackground', '❌ 视频加载错误', new Error('Video load failed'));
        this.logger.info('AtmosphereBackground', '📊 视频错误详情', errorData);
        
        // 简单的重试逻辑
        if (this.retryCount < 3) {
           this.retryCount++;
           console.info(`[AtmosphereBackground] Retrying video load... (${this.retryCount}/3)`);
           // 延迟重试，避免频繁请求
           setTimeout(() => {
             this.currentVideoSource = this.videoSource;
           }, 500);
        }
      })
      .onPrepared((event) => {
        const preparedData: LogData = {
          'videoSource': this.currentVideoSource,
          'themeKey': this.themeKey,
          'duration': event?.duration || 0
        };
        this.videoPrepared = true;
        this.logger.info('AtmosphereBackground', '✅ 视频准备完成', preparedData);
        console.info('[AtmosphereBackground] 视频准备完成');
      })
      .onStart(() => {
        this.logger.info('AtmosphereBackground', '▶️ 视频开始播放');
        console.info('[AtmosphereBackground] 视频开始播放');
      })
      .onFinish(() => {
        this.logger.info('AtmosphereBackground', '✅ 视频播放完成');
      })
  }
}
