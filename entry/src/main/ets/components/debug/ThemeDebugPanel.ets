import { ThemeManager, ThemeMode, ThemeConfig } from '../../common/theme/ThemeManager';

@Component
export struct ThemeDebugPanel {
  @State private showPanel: boolean = false;
  @State private currentMode: ThemeMode = ThemeMode.AUTO;
  @StorageLink('currentTheme') private theme: ThemeConfig = this.getDefaultTheme();
  @StorageLink('isDarkMode') private isDarkMode: boolean = false;

  private themeManager: ThemeManager = ThemeManager.getInstance();

  aboutToAppear(): void {
    // 在开发模式下显示主题调试面板
    const isDevelopment = AppStorage.get<boolean>('isDevelopment') || false;
    this.showPanel = isDevelopment;
    
    if (this.showPanel) {
      this.loadCurrentMode();
    }
  }

  private getDefaultTheme(): ThemeConfig {
    return {
      primaryColor: '#87CEEB',
      backgroundColor: '#F5F7FA',
      surfaceColor: '#FFFFFF',
      cardColor: 'rgba(255, 255, 255, 0.9)',
      textPrimaryColor: '#1A1A1A',
      textSecondaryColor: '#666666',
      textHintColor: '#999999',
      dividerColor: 'rgba(0, 0, 0, 0.1)',
      shadowColor: 'rgba(0, 0, 0, 0.1)',
      cardOpacity: 0.15,
      chartColor: '#2196F3',
      accentColor: '#4A90E2',
      errorColor: '#F44336',
      successColor: '#4CAF50',
      warningColor: '#FF9800'
    };
  }

  build() {
    Stack() {
      if (this.showPanel) {
      Column() {
        this.renderHeader();
        this.renderCurrentStatus();
        this.renderThemeControls();
        this.renderColorPalette();
      }
      .width(320)
      .padding(16)
      .backgroundColor('rgba(0, 0, 0, 0.9)')
      .borderRadius(12)
      .margin({ bottom: 50, right: 16 });
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
      // 移除装饰性emoji
      
      Text('主题调试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White);
      
      Blank();
      
      Button('×')
        .onClick(() => {
          this.showPanel = false;
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
  private renderCurrentStatus(): void {
    Column() {
      Text('当前状态')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .margin({ bottom: 8 });

      Row() {
        Text('模式:')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)');
        
        Text(this.getModeDisplayName(this.currentMode))
          .fontSize(12)
          .fontColor(Color.White)
          .margin({ left: 8 });
        
        Blank();
        
        Image(this.isDarkMode ? $r('app.media.moon') : $r('app.media.sun'))
          .width(16)
          .height(16)
          .fillColor(Color.White);
      }
      .width('100%');

      Row() {
        Text('时间:')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)');
        
        Text(this.getCurrentTimeString())
          .fontSize(12)
          .fontColor(Color.White)
          .margin({ left: 8 });
        
        Blank();
        
        Text(this.themeManager.isNightMode() ? '夜间' : '白天')
          .fontSize(12)
          .fontColor(this.themeManager.isNightMode() ? '#64B5F6' : '#FFD54F')
          .backgroundColor('rgba(255,255,255,0.1)')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4);
      }
      .width('100%')
      .margin({ top: 4 });
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(255,255,255,0.1)')
    .borderRadius(8)
    .margin({ bottom: 16 });
  }

  @Builder
  private renderThemeControls(): void {
    Column() {
      Text('快速切换')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .margin({ bottom: 12 });

      Row() {
        Button('自动')
          .onClick(() => {
            this.switchTheme(ThemeMode.AUTO);
          })
          .fontSize(11)
          .height(32)
          .backgroundColor(this.currentMode === ThemeMode.AUTO ? 'rgba(100, 181, 246, 0.8)' : 'rgba(255,255,255,0.2)')
          .layoutWeight(1);
        
        Button('浅色')
          .onClick(() => {
            this.switchTheme(ThemeMode.LIGHT);
          })
          .fontSize(11)
          .height(32)
          .backgroundColor(this.currentMode === ThemeMode.LIGHT ? 'rgba(255, 213, 79, 0.8)' : 'rgba(255,255,255,0.2)')
          .layoutWeight(1)
          .margin({ left: 8 });
        
        Button('深色')
          .onClick(() => {
            this.switchTheme(ThemeMode.DARK);
          })
          .fontSize(11)
          .height(32)
          .backgroundColor(this.currentMode === ThemeMode.DARK ? 'rgba(66, 66, 66, 0.8)' : 'rgba(255,255,255,0.2)')
          .layoutWeight(1)
          .margin({ left: 8 });
      }
      .width('100%');
    }
    .width('100%')
    .margin({ bottom: 16 });
  }

  @Builder
  private renderColorPalette(): void {
    Column() {
      Text('色彩方案')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .margin({ bottom: 12 });

      // 主要颜色
      this.renderColorRow('主色调', this.theme.primaryColor);
      this.renderColorRow('强调色', this.theme.accentColor);
      this.renderColorRow('背景色', this.theme.backgroundColor);
      this.renderColorRow('卡片色', this.theme.cardColor);
      
      Divider()
        .color('rgba(255,255,255,0.2)')
        .margin({ top: 8, bottom: 8 });
      
      // 文本颜色
      this.renderColorRow('主文本', this.theme.textPrimaryColor);
      this.renderColorRow('次文本', this.theme.textSecondaryColor);
      this.renderColorRow('提示文本', this.theme.textHintColor);
    }
    .width('100%');
  }

  @Builder
  private renderColorRow(label: string, color: string): void {
    Row() {
      Text(label)
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.8)')
        .layoutWeight(1);
      
      Row() {
        Column()
          .width(16)
          .height(16)
          .backgroundColor(color)
          .borderRadius(2)
          .border({ width: 1, color: 'rgba(255,255,255,0.3)' });
        
        Text(color)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.6)')
          .margin({ left: 6 });
      }
    }
    .width('100%')
    .margin({ bottom: 4 });
  }

  private loadCurrentMode(): void {
    this.currentMode = this.themeManager.getCurrentMode();
  }

  private async switchTheme(mode: ThemeMode): Promise<void> {
    try {
      await this.themeManager.setThemeMode(mode);
      this.currentMode = mode;
      console.info(`[ThemeDebugPanel] Switched to ${mode} mode`);
    } catch (error) {
      console.error('[ThemeDebugPanel] Failed to switch theme:', error);
    }
  }

  private getModeDisplayName(mode: ThemeMode): string {
    switch (mode) {
      case ThemeMode.AUTO:
        return '自动';
      case ThemeMode.LIGHT:
        return '浅色';
      case ThemeMode.DARK:
        return '深色';
      default:
        return '未知';
    }
  }

  private getCurrentTimeString(): string {
    const now = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  }
}
