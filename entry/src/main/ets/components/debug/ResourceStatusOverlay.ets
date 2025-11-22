import { ResourceManager } from '../../common/utils/ResourceManager';
import { ResourceHealthReport, ResourceCheckResult } from '../../common/utils/ResourceHealthChecker';

@Component
export struct ResourceStatusOverlay {
  @State private showOverlay: boolean = false;
  @State private healthReport: ResourceHealthReport | null = null;
  private resourceManager: ResourceManager = ResourceManager.getInstance();

  aboutToAppear(): void {
    // 在开发模式下显示资源状态
    const isDevelopment = AppStorage.get<boolean>('isDevelopment') || false;
    this.showOverlay = isDevelopment;
    
    if (this.showOverlay) {
      this.loadHealthReport();
    }
  }

  private async loadHealthReport(): Promise<void> {
    try {
      this.healthReport = this.resourceManager.getLastHealthReport();
      if (!this.healthReport) {
        this.healthReport = await this.resourceManager.performHealthCheck();
      }
    } catch (error) {
      console.error('[ResourceStatusOverlay] Failed to load health report:', error);
    }
  }

  build() {
    Stack() {
      if (this.showOverlay && this.healthReport) {
      Column() {
        this.renderHeader();
        this.renderHealthSummary();
        this.renderThemeStatus();
        this.renderSuggestions();
      }
      .width(300)
      .padding(12)
      .backgroundColor('rgba(0, 0, 0, 0.8)')
      .borderRadius(8)
      .margin({ top: 100, right: 16 });
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
      Text('资源状态')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White);
      
      Blank();
      
      Button('刷新')
        .onClick(() => {
          this.loadHealthReport();
        })
        .fontSize(12)
        .height(24)
        .backgroundColor('rgba(255, 255, 255, 0.2)');
      
      Button('×')
        .onClick(() => {
          this.showOverlay = false;
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
  private renderHealthSummary(): void {
    if (this.healthReport) {
      Column() {
        Row() {
          Text('总体健康度:')
            .fontSize(14)
            .fontColor('rgba(255, 255, 255, 0.8)');
          
          Text(`${this.healthReport.overallHealth}%`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getHealthColor(this.healthReport.overallHealth));
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween);

        Row() {
          Text('健康主题:')
            .fontSize(14)
            .fontColor('rgba(255, 255, 255, 0.8)');
          
          Text(`${this.healthReport.healthyThemes}/${this.healthReport.totalThemes}`)
            .fontSize(14)
            .fontColor(Color.White);
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 4 });
      }
      .width('100%')
      .margin({ bottom: 12 });
    }
  }

  @Builder
  private renderThemeStatus(): void {
    if (this.healthReport) {
      Column() {
        Text('主题状态')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .margin({ bottom: 8 });

        ForEach(this.healthReport.results.slice(0, 6), (result: ResourceCheckResult) => {
          Row() {
            Text(result.isHealthy ? '✅' : '❌')
              .fontSize(12);
            
            Text(result.themeKey)
              .fontSize(12)
              .fontColor(result.isHealthy ? Color.White : 'rgba(255, 255, 255, 0.6)')
              .layoutWeight(1)
              .margin({ left: 4 });
            
            if (!result.isHealthy) {
              Text(`${result.missingResources.length}`)
                .fontSize(10)
                .fontColor('#FF6B6B')
                .backgroundColor('rgba(255, 107, 107, 0.2)')
                .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                .borderRadius(4);
            }
          }
          .width('100%')
          .margin({ bottom: 2 });
        }, (result: ResourceCheckResult) => result.themeKey);
      }
      .width('100%')
      .margin({ bottom: 12 });
    }
  }

  @Builder
  private renderSuggestions(): void {
    if (this.resourceManager.getResourceSuggestions().length > 0) {
      Column() {
        Text('建议')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .margin({ bottom: 8 });

        ForEach(this.resourceManager.getResourceSuggestions().slice(0, 3), (suggestion: string) => {
          Text(suggestion)
            .fontSize(11)
            .fontColor('rgba(255, 255, 255, 0.7)')
            .margin({ bottom: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }, (suggestion: string) => suggestion);
      }
      .width('100%');
    }
  }

  private getHealthColor(health: number): string {
    if (health >= 80) return '#4CAF50';
    if (health >= 60) return '#FFC107';
    if (health >= 40) return '#FF9800';
    return '#F44336';
  }
}
