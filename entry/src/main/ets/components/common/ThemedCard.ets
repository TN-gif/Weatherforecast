import { ThemeConfig } from '../../common/theme/ThemeManager';

@Component
export struct ThemedCard {
  @Prop children?: () => void;
  @Prop padding?: Padding | Length;
  @Prop margin?: Margin | Length;
  @Prop borderRadius?: Length;
  @Prop width?: Length;
  @Prop height?: Length;
  @Prop clickable?: boolean;
  @Prop onCardClick?: () => void;
  
  @StorageLink('currentTheme') private theme: ThemeConfig = this.getDefaultTheme();
  @StorageLink('isDarkMode') private isDarkMode: boolean = false;
  @State private isPressed: boolean = false;

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
      if (this.children) {
        this.children();
      }
    }
    .width(this.width || '100%')
    .height(this.height)
    .padding(this.padding || 16)
    .margin(this.margin)
    .backgroundColor(this.theme.cardColor)
    .borderRadius(this.borderRadius || 16)
    .backdropBlur(10)
    .shadow({
      radius: this.isDarkMode ? 8 : 4,
      color: this.theme.shadowColor,
      offsetY: this.isDarkMode ? 4 : 2
    })
    .scale({ 
      x: this.isPressed ? 0.98 : 1, 
      y: this.isPressed ? 0.98 : 1 
    })
    .animation({
      duration: 150,
      curve: Curve.EaseOut
    })
    .onTouch((event: TouchEvent) => {
      if (!this.clickable) return;
      
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
        if (event.type === TouchType.Up && this.onCardClick) {
          this.onCardClick();
        }
      }
    });
  }
}

@Component
export struct ThemedText {
  @Prop text: string = '';
  @Prop fontSize?: number | string;
  @Prop fontWeight?: FontWeight;
  @Prop textType?: 'primary' | 'secondary' | 'hint' = 'primary';
  @Prop textAlign?: TextAlign;
  @Prop maxLines?: number;
  @Prop textOverflow?: TextOverflow;
  @Prop margin?: Margin | Length;
  
  @StorageLink('currentTheme') private theme: ThemeConfig = this.getDefaultTheme();

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

  private getTextColor(): string {
    switch (this.textType) {
      case 'primary':
        return this.theme.textPrimaryColor;
      case 'secondary':
        return this.theme.textSecondaryColor;
      case 'hint':
        return this.theme.textHintColor;
      default:
        return this.theme.textPrimaryColor;
    }
  }

  build() {
    Text(this.text)
      .fontSize(this.fontSize || 14)
      .fontWeight(this.fontWeight || FontWeight.Normal)
      .fontColor(this.getTextColor())
      .textAlign(this.textAlign || TextAlign.Start)
      .maxLines(this.maxLines)
      .textOverflow(this.textOverflow)
      .margin(this.margin)
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      });
  }
}

@Component
export struct ThemedButton {
  @Prop text: string = '';
  @Prop buttonType?: 'primary' | 'secondary' | 'text' = 'primary';
  @Prop width?: Length;
  @Prop height?: Length;
  @Prop fontSize?: number | string;
  @Prop enabled?: boolean = true;
  @Prop onButtonClick?: () => void;
  
  @StorageLink('currentTheme') private theme: ThemeConfig = this.getDefaultTheme();
  @State private isPressed: boolean = false;

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

  private getButtonStyle(): { backgroundColor: string, textColor: string } {
    if (!this.enabled) {
      return {
        backgroundColor: this.theme.dividerColor,
        textColor: this.theme.textHintColor
      };
    }

    switch (this.buttonType) {
      case 'primary':
        return {
          backgroundColor: this.theme.accentColor,
          textColor: '#FFFFFF'
        };
      case 'secondary':
        return {
          backgroundColor: this.theme.surfaceColor,
          textColor: this.theme.textPrimaryColor
        };
      case 'text':
        return {
          backgroundColor: 'transparent',
          textColor: this.theme.accentColor
        };
      default:
        return {
          backgroundColor: this.theme.accentColor,
          textColor: '#FFFFFF'
        };
    }
  }

  build() {
    Button(this.text)
      .width(this.width)
      .height(this.height || 40)
      .fontSize(this.fontSize || 14)
      .fontColor(this.getButtonStyle().textColor)
      .backgroundColor(this.getButtonStyle().backgroundColor)
      .borderRadius(8)
      .enabled(this.enabled)
      .opacity(this.enabled ? (this.isPressed ? 0.8 : 1) : 0.5)
      .scale({ 
        x: this.isPressed ? 0.95 : 1, 
        y: this.isPressed ? 0.95 : 1 
      })
      .animation({
        duration: 150,
        curve: Curve.EaseOut
      })
      .onTouch((event: TouchEvent) => {
        if (!this.enabled) return;
        
        if (event.type === TouchType.Down) {
          this.isPressed = true;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false;
          if (event.type === TouchType.Up && this.onButtonClick) {
            this.onButtonClick();
          }
        }
      });
  }
}

@Component
export struct ThemedDivider {
  @Prop margin?: Margin | Length;
  @Prop strokeWidth?: number;
  
  @StorageLink('currentTheme') private theme: ThemeConfig = this.getDefaultTheme();

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
    Divider()
      .color(this.theme.dividerColor)
      .strokeWidth(this.strokeWidth || 1)
      .margin(this.margin)
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      });
  }
}
