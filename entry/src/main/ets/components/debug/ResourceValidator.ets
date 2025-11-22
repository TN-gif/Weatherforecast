import { ThemeConstants, VideoThemeAsset } from '../../common/constants/ThemeConstants';

interface ResourceValidationResult {
  resourcePath: string;
  exists: boolean;
  size?: number;
  type: 'video' | 'webp' | 'lottie';
  status: 'success' | 'warning' | 'error';
  message: string;
}

@Component
export struct ResourceValidator {
  @State private showValidator: boolean = false;
  @State private validationResults: ResourceValidationResult[] = [];
  @State private isValidating: boolean = false;
  @State private totalResources: number = 0;
  @State private validResources: number = 0;

  aboutToAppear(): void {
    // 在开发模式下显示资源验证器
    const isDevelopment = AppStorage.get<boolean>('isDevelopment') || false;
    this.showValidator = isDevelopment;
  }

  build() {
    Stack() {
      if (this.showValidator) {
      Column() {
        this.renderHeader();
        this.renderValidationSummary();
        this.renderValidationResults();
        this.renderActionButtons();
      }
      .width(350)
      .padding(16)
      .backgroundColor('rgba(0, 0, 0, 0.9)')
      .borderRadius(12)
      .margin({ bottom: 120, right: 16 });
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
      Text('📁')
        .fontSize(20)
        .margin({ right: 8 });
      
      Text('资源验证器')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White);
      
      Blank();
      
      Button('×')
        .onClick(() => {
          this.showValidator = false;
        })
        .fontSize(16)
        .width(24)
        .height(24)
        .backgroundColor('rgba(255, 0, 0, 0.3)');
    }
    .width('100%')
    .margin({ bottom: 16 });
  }

  @Builder
  private renderValidationSummary(): void {
    Column() {
      Text('验证摘要')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .margin({ bottom: 8 });

      Row() {
        Text(`总资源: ${this.totalResources}`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)');
        
        Blank();
        
        Text(`有效: ${this.validResources}`)
          .fontSize(12)
          .fontColor('#4CAF50');
        
        Text(`无效: ${this.totalResources - this.validResources}`)
          .fontSize(12)
          .fontColor('#F44336')
          .margin({ left: 8 });
      }
      .width('100%');

      // 进度条
      Progress({
        value: this.validResources,
        total: this.totalResources || 1,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(4)
        .margin({ top: 8 })
        .color(this.validResources === this.totalResources ? '#4CAF50' : '#FF9800');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(255,255,255,0.1)')
    .borderRadius(8)
    .margin({ bottom: 16 });
  }

  @Builder
  private renderValidationResults(): void {
    if (this.validationResults.length > 0) {
      Column() {
      Text('验证结果')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .margin({ bottom: 12 });

      List() {
        ForEach(this.validationResults, (result: ResourceValidationResult, index: number) => {
          ListItem() {
            this.renderResultItem(result);
          }
        });
      }
      .height(200)
      .scrollBar(BarState.Auto);
      }
      .width('100%')
      .margin({ bottom: 16 });
    }
  }

  @Builder
  private renderResultItem(result: ResourceValidationResult): void {
    Row() {
      Text(this.getStatusIcon(result.status))
        .fontSize(16)
        .margin({ right: 8 });
      
      Column() {
        Text(this.getFileName(result.resourcePath))
          .fontSize(11)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        
        Text(result.message)
          .fontSize(10)
          .fontColor(this.getStatusColor(result.status))
          .margin({ top: 2 });
        
        if (result.size) {
          Text(`大小: ${this.formatFileSize(result.size)}`)
            .fontSize(9)
            .fontColor('rgba(255,255,255,0.6)')
            .margin({ top: 2 });
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .backgroundColor('rgba(255,255,255,0.05)')
    .borderRadius(4)
    .margin({ bottom: 4 });
  }

  @Builder
  private renderActionButtons(): void {
    Row() {
      Button('开始验证')
        .onClick(() => {
          this.startValidation();
        })
        .fontSize(12)
        .height(32)
        .backgroundColor(this.isValidating ? 'rgba(255,255,255,0.3)' : 'rgba(76, 175, 80, 0.8)')
        .enabled(!this.isValidating)
        .layoutWeight(1);
      
      Button('清除结果')
        .onClick(() => {
          this.clearResults();
        })
        .fontSize(12)
        .height(32)
        .backgroundColor('rgba(255,152,0,0.8)')
        .layoutWeight(1)
        .margin({ left: 8 });
    }
    .width('100%');
  }

  private async startValidation(): Promise<void> {
    if (this.isValidating) {
      return;
    }

    this.isValidating = true;
    this.validationResults = [];
    this.totalResources = 0;
    this.validResources = 0;

    try {
      // 验证所有主题资源
      const themes = ThemeConstants.THEMES;
      const allResources: string[] = [];

      // 收集所有资源路径
      themes.forEach(theme => {
        if (theme.videoResource) {
          allResources.push(theme.videoResource);
        }
        if (theme.animatedImageResource) {
          allResources.push(theme.animatedImageResource);
        }
        if (theme.lottieResource) {
          allResources.push(theme.lottieResource);
        }
      });

      this.totalResources = allResources.length;

      // 验证每个资源
      for (const resourcePath of allResources) {
        const result = await this.validateResource(resourcePath);
        this.validationResults.push(result);
        
        if (result.status === 'success') {
          this.validResources++;
        }
      }

      console.info(`[ResourceValidator] Validation completed: ${this.validResources}/${this.totalResources} resources valid`);
    } catch (error) {
      console.error('[ResourceValidator] Validation failed:', error);
    } finally {
      this.isValidating = false;
    }
  }

  private async validateResource(resourcePath: string): Promise<ResourceValidationResult> {
    try {
      // 模拟资源检查 (实际项目中应该使用真实的文件检查API)
      const fileName = this.getFileName(resourcePath);
      const type = this.getResourceType(resourcePath);
      
      // 基于文件名模拟验证结果
      const exists = true; // 假设文件存在
      let size = 0;
      let status: 'success' | 'warning' | 'error' = 'success';
      let message = '资源有效';

      // 模拟文件大小检查
      if (type === 'video') {
        size = Math.random() * 15000000; // 0-15MB
        if (size > 10000000) {
          status = 'warning';
          message = '文件过大，建议压缩';
        }
      } else if (type === 'webp') {
        size = Math.random() * 500000; // 0-500KB
      } else if (type === 'lottie') {
        size = Math.random() * 50000; // 0-50KB
      }

      return {
        resourcePath,
        exists,
        size,
        type,
        status,
        message
      };
    } catch (error) {
      return {
        resourcePath,
        exists: false,
        type: this.getResourceType(resourcePath),
        status: 'error',
        message: '资源不存在或无法访问'
      };
    }
  }

  private getResourceType(resourcePath: string): 'video' | 'webp' | 'lottie' {
    if (resourcePath.endsWith('.mp4')) {
      return 'video';
    } else if (resourcePath.endsWith('.webp')) {
      return 'webp';
    } else if (resourcePath.endsWith('.json')) {
      return 'lottie';
    }
    return 'video';
  }

  private getFileName(resourcePath: string): string {
    return resourcePath.split('/').pop() || resourcePath;
  }

  private getStatusIcon(status: string): string {
    switch (status) {
      case 'success':
        return '✅';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      default:
        return '❓';
    }
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'success':
        return '#4CAF50';
      case 'warning':
        return '#FF9800';
      case 'error':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes}B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)}KB`;
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
    }
  }

  private clearResults(): void {
    this.validationResults = [];
    this.totalResources = 0;
    this.validResources = 0;
  }
}
