import { DebugLogger } from '../../common/utils/DebugLogger';

@Component
export struct LogViewer {
  @State private showViewer: boolean = false;
  @State private logs: string[] = [];
  @State private autoRefresh: boolean = true;
  private logger: DebugLogger = DebugLogger.getInstance();
  private refreshTimer: number = -1;

  aboutToAppear(): void {
    // 在开发模式下显示日志查看器
    const isDevelopment = AppStorage.get<boolean>('isDevelopment') || false;
    this.showViewer = isDevelopment;
    
    if (this.showViewer) {
      this.refreshLogs();
      this.startAutoRefresh();
    }
  }

  aboutToDisappear(): void {
    this.stopAutoRefresh();
  }

  private refreshLogs(): void {
    this.logs = this.logger.getAllLogs();
  }

  private startAutoRefresh(): void {
    if (this.autoRefresh && this.refreshTimer === -1) {
      this.refreshTimer = setInterval(() => {
        this.refreshLogs();
      }, 1000);
    }
  }

  private stopAutoRefresh(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  build() {
    if (this.showViewer) {
      Stack() {
        Column() {
          this.renderHeader();
          this.renderLogList();
          this.renderControls();
        }
        .width(400)
        .height(500)
        .padding(12)
        .backgroundColor('rgba(0, 0, 0, 0.95)')
        .borderRadius(8)
        .margin({ top: 50, right: 16 });
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .position({ x: 0, y: 0 })
      .zIndex(999);
    }
  }

  @Builder
  private renderHeader(): void {
    Row() {
      Text('📋')
        .fontSize(20)
        .margin({ right: 8 });
      
      Text('调试日志查看器')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White);
      
      Blank();
      
      Button('×')
        .onClick(() => {
          this.showViewer = false;
        })
        .fontSize(16)
        .width(24)
        .height(24)
        .backgroundColor('rgba(255, 0, 0, 0.3)');
    }
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  private renderLogList(): void {
    Column() {
      Text(`日志条数: ${this.logs.length}`)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.6)')
        .margin({ bottom: 8 });

      List() {
        ForEach(this.logs.slice(-50), (log: string, index: number) => {
          ListItem() {
            Text(log)
              .fontSize(10)
              .fontColor(this.getLogColor(log))
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .padding({ top: 2, bottom: 2 });
          }
        }, (log: string, index: number) => `log-${index}`);
      }
      .height(350)
      .scrollBar(BarState.Auto)
      .backgroundColor('rgba(255,255,255,0.05)')
      .borderRadius(4)
      .padding(8);
    }
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  private renderControls(): void {
    Row() {
      Button('刷新')
        .onClick(() => {
          this.refreshLogs();
        })
        .fontSize(12)
        .height(28)
        .backgroundColor('rgba(76, 175, 80, 0.8)')
        .layoutWeight(1);
      
      Button(this.autoRefresh ? '停止自动' : '开始自动')
        .onClick(() => {
          this.autoRefresh = !this.autoRefresh;
          if (this.autoRefresh) {
            this.startAutoRefresh();
          } else {
            this.stopAutoRefresh();
          }
        })
        .fontSize(12)
        .height(28)
        .backgroundColor('rgba(33, 150, 243, 0.8)')
        .layoutWeight(1)
        .margin({ left: 8 });
      
      Button('清空')
        .onClick(() => {
          this.logger.clearLogs();
          this.refreshLogs();
        })
        .fontSize(12)
        .height(28)
        .backgroundColor('rgba(255, 152, 0, 0.8)')
        .layoutWeight(1)
        .margin({ left: 8 });
    }
    .width('100%');
  }

  private getLogColor(log: string): string {
    if (log.includes('ERROR')) {
      return '#FF6B6B';
    } else if (log.includes('WARN')) {
      return '#FFB74D';
    } else if (log.includes('INFO')) {
      return '#4FC3F7';
    } else if (log.includes('DEBUG')) {
      return '#81C784';
    }
    return '#FFFFFF';
  }
}
