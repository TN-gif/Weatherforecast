import { DebugLogger, LogData } from '../../common/utils/DebugLogger';
import { BackgroundMode } from '../../common/constants/ThemeConstants';

@Component
export struct AtmosphereBackground {
  @StorageProp('backgroundMode') backgroundMode: BackgroundMode = BackgroundMode.VIDEO;
  @StorageProp('themeKey') @Watch('onThemeChange') themeKey: string = 'sunny_day';
  
  @State private videoPrepared: boolean = false;
  
  private logger: DebugLogger = DebugLogger.getInstance();
  
  // 视频资源路径
  private videoSource?: string;

  aboutToAppear(): void {
    const initData: LogData = {
      'themeKey': this.themeKey,
      'backgroundMode': String(this.backgroundMode)
    };
    this.logger.lifecycle('AtmosphereBackground', 'aboutToAppear 开始', initData);
    
    // 强制设置为VIDEO模式
    this.backgroundMode = BackgroundMode.VIDEO;
    this.updateVideoSource();
    
    this.logger.lifecycle('AtmosphereBackground', 'aboutToAppear 完成');
  }

  aboutToRender(): void {
    this.updateVideoSource();
  }

  private updateVideoSource(): void {
    this.videoSource = `weather/${this.themeKey}.mp4`;
    
    const assetData: LogData = {
      'themeKey': this.themeKey,
      'videoSource': this.videoSource
    };
    this.logger.info('AtmosphereBackground', '📁 视频资源路径', assetData);
  }

  private onThemeChange(): void {
    const logData: LogData = {
      'newTheme': this.themeKey
    };
    this.logger.info('AtmosphereBackground', '🎨 主题变更', logData);
    this.videoPrepared = false;
    this.updateVideoSource();
  }

  build() {
    Stack() {
      // 只渲染视频背景，不允许任何降级
      this.renderVideoBackground();
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private renderVideoBackground(): void {
    if (this.videoSource) {
      Video({ src: $rawfile(this.videoSource) })
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .autoPlay(true)
        .loop(true)
        .muted(true)
        .controls(false)
        .onError((error) => {
          const errorData: LogData = {
            'videoSource': this.videoSource || '',
            'themeKey': this.themeKey,
            'errorInfo': error ? JSON.stringify(error) : 'Unknown error'
          };
          this.logger.error('AtmosphereBackground', '❌ 视频加载错误', new Error('Video load failed'));
          this.logger.info('AtmosphereBackground', '📊 视频错误详情', errorData);
        })
        .onPrepared((event) => {
          const preparedData: LogData = {
            'videoSource': this.videoSource || '',
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
}
