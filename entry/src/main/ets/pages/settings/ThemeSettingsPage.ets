import router from '@ohos.router';
import { ThemeManager, ThemeMode, ThemeConfig } from '../../common/theme/ThemeManager';
import { ThemedCard, ThemedText, ThemedButton, ThemedDivider } from '../../components/common/ThemedCard';
import { AppContextHolder } from '../../common/di/AppContextHolder';

@Entry
@Component
struct ThemeSettingsPage {
  @State private currentMode: ThemeMode = ThemeMode.AUTO;
  @State private isLoading: boolean = false;
  @StorageLink('currentTheme') private theme: ThemeConfig = this.getDefaultTheme();
  @StorageLink('isDarkMode') private isDarkMode: boolean = false;

  private themeManager: ThemeManager = ThemeManager.getInstance();

  aboutToAppear(): void {
    this.loadCurrentSettings();
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
    Column() {
      // 标题栏
      this.buildHeader();
      
      // 主题预览
      this.buildThemePreview();
      
      // 主题选项
      this.buildThemeOptions();
      
      // 主题说明
      this.buildThemeDescription();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.backgroundColor)
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    });
  }

  @Builder
  private buildHeader(): void {
    Row() {
      Button() {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .fillColor(this.theme.textPrimaryColor);
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back();
      });

      ThemedText({
        text: '主题设置',
        fontSize: 20,
        fontWeight: FontWeight.Bold,
        textType: 'primary'
      })
        .layoutWeight(1)
        .textAlign(TextAlign.Center);

      // 占位符保持居中
      Column()
        .width(40)
        .height(40);
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.theme.surfaceColor)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .shadow({
      radius: 4,
      color: this.theme.shadowColor,
      offsetY: 2
    });
  }

  @Builder
  private buildThemePreview(): void {
    ThemedCard({
      margin: 16,
      children: () => {
        Column() {
          Row() {
            ThemedText({
              text: '主题预览',
              fontSize: 18,
              fontWeight: FontWeight.Medium,
              textType: 'primary'
            });
            
            Blank();
            
            Text(this.isDarkMode ? '🌙' : '☀️')
              .fontSize(24);
          }
          .width('100%')
          .margin({ bottom: 16 });

          // 预览卡片
          Column() {
            Row() {
              Column() {
                ThemedText({
                  text: '北京',
                  fontSize: 16,
                  fontWeight: FontWeight.Medium,
                  textType: 'primary'
                });
                
                ThemedText({
                  text: '晴天',
                  fontSize: 12,
                  textType: 'secondary',
                  margin: { top: 2 }
                });
              }
              .alignItems(HorizontalAlign.Start);
              
              Blank();
              
              ThemedText({
                text: '24°',
                fontSize: 32,
                fontWeight: FontWeight.Bold,
                textType: 'primary'
              });
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.theme.cardColor)
            .borderRadius(12)
            .backdropBlur(10);
          }
          .width('100%');
        }
      }
    });
  }

  @Builder
  private buildThemeOptions(): void {
    ThemedCard({
      margin: { left: 16, right: 16, bottom: 16 },
      children: () => {
        Column() {
          ThemedText({
            text: '主题模式',
            fontSize: 18,
            fontWeight: FontWeight.Medium,
            textType: 'primary',
            margin: { bottom: 16 }
          });

          // 自动模式
          this.buildThemeOption(
            ThemeMode.AUTO,
            '跟随系统',
            '根据时间自动切换浅色和深色主题',
            '🔄'
          );

          ThemedDivider({ margin: { top: 12, bottom: 12 } });

          // 浅色模式
          this.buildThemeOption(
            ThemeMode.LIGHT,
            '浅色模式',
            '适合白天使用，提供清晰的阅读体验',
            '☀️'
          );

          ThemedDivider({ margin: { top: 12, bottom: 12 } });

          // 深色模式
          this.buildThemeOption(
            ThemeMode.DARK,
            '深色模式',
            '适合夜间使用，减少眼部疲劳',
            '🌙'
          );
        }
      }
    });
  }

  @Builder
  private buildThemeOption(mode: ThemeMode, title: string, description: string, icon: string): void {
    Row() {
      Text(icon)
        .fontSize(24)
        .margin({ right: 12 });
      
      Column() {
        ThemedText({
          text: title,
          fontSize: 16,
          fontWeight: FontWeight.Medium,
          textType: 'primary'
        })
          .alignSelf(ItemAlign.Start);
        
        ThemedText({
          text: description,
          fontSize: 12,
          textType: 'secondary',
          margin: { top: 4 }
        })
          .alignSelf(ItemAlign.Start);
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
      
      Radio({ value: mode, group: 'themeGroup' })
        .checked(this.currentMode === mode)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectThemeMode(mode);
          }
        });
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectThemeMode(mode);
    });
  }

  @Builder
  private buildThemeDescription(): void {
    ThemedCard({
      margin: { left: 16, right: 16, bottom: 16 },
      children: () => {
        Column() {
          Row() {
            Text('💡')
              .fontSize(20)
              .margin({ right: 8 });
            
            ThemedText({
              text: '主题建议',
              fontSize: 16,
              fontWeight: FontWeight.Medium,
              textType: 'primary'
            });
          }
          .margin({ bottom: 12 });

          ThemedText({
            text: this.themeManager.getThemeSuggestion(),
            fontSize: 14,
            textType: 'secondary'
          });

          if (this.currentMode === ThemeMode.AUTO) {
            ThemedDivider({ margin: { top: 12, bottom: 12 } });
            
            ThemedText({
              text: '自动切换时间：',
              fontSize: 14,
              fontWeight: FontWeight.Medium,
              textType: 'primary',
              margin: { bottom: 8 }
            });
            
            ThemedText({
              text: '• 浅色模式：06:00 - 18:00\n• 深色模式：18:00 - 06:00',
              fontSize: 12,
              textType: 'secondary'
            });
          }
        }
      }
    });
  }

  private async loadCurrentSettings(): Promise<void> {
    try {
      this.currentMode = this.themeManager.getCurrentMode();
    } catch (error) {
      console.error('[ThemeSettingsPage] Failed to load settings:', error);
    }
  }

  private async selectThemeMode(mode: ThemeMode): Promise<void> {
    if (this.currentMode === mode || this.isLoading) {
      return;
    }

    try {
      this.isLoading = true;
      this.currentMode = mode;
      
      // 应用主题
      await this.themeManager.setThemeMode(mode);
      
      console.info(`[ThemeSettingsPage] Theme mode changed to: ${mode}`);
    } catch (error) {
      console.error('[ThemeSettingsPage] Failed to change theme:', error);
      // 恢复原来的选择
      this.currentMode = this.themeManager.getCurrentMode();
    } finally {
      this.isLoading = false;
    }
  }
}
