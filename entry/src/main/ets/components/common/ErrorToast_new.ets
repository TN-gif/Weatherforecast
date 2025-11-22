import { LocationErrorCode } from '../../data/models/WeatherModels';

export interface ErrorMessage {
  code?: number;
  message: string;
  type: 'error' | 'warning' | 'info';
}

interface ErrorMapEntry {
  message: string;
  type: 'error' | 'warning' | 'info';
}

@Component
export struct ErrorToast {
  @Link errorMessage: ErrorMessage | null;
  @State private isVisible: boolean = false;

  aboutToAppear(): void {
    if (this.errorMessage) {
      this.isVisible = true;
      // 自动隐藏
      setTimeout(() => {
        this.isVisible = false;
        setTimeout(() => {
          this.errorMessage = null;
        }, 300);
      }, 4000);
    }
  }

  build() {
    if (this.errorMessage && this.isVisible) {
      Column() {
        Row() {
          Text(this.getErrorIcon())
            .fontSize(16)
            .margin({ right: 8 });
          
          Text(this.errorMessage.message)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .flexGrow(1);
          
          Button('×')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .backgroundColor(Color.Transparent)
            .width(24)
            .height(24)
            .onClick(() => {
              this.isVisible = false;
              setTimeout(() => {
                this.errorMessage = null;
              }, 300);
            });
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.getBackgroundColor())
        .borderRadius(8)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
      }
      .width('90%')
      .margin({ top: 10, left: '5%', right: '5%' })
      .zIndex(1000)
      .transition({
        type: TransitionType.Insert,
        opacity: 0,
        translate: { y: -50 }
      })
      .transition({
        type: TransitionType.Delete,
        opacity: 0,
        translate: { y: -50 }
      })
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
    }
  }

  private getErrorIcon(): string {
    if (!this.errorMessage) return '';
    
    switch (this.errorMessage.type) {
      case 'error':
        return '❌';
      case 'warning':
        return '⚠️';
      case 'info':
        return 'ℹ️';
      default:
        return '❌';
    }
  }

  private getBackgroundColor(): string {
    if (!this.errorMessage) return '#FF4444';
    
    switch (this.errorMessage.type) {
      case 'error':
        return '#FF4444';
      case 'warning':
        return '#FF8800';
      case 'info':
        return '#4488FF';
      default:
        return '#FF4444';
    }
  }
}

export class ErrorHandler {
  static handle(error: Error | LocationErrorCode, customMessage?: string): ErrorMessage {
    if (typeof error === 'number') {
      return ErrorHandler.handleLocationError(error, customMessage);
    }
    
    // 通用错误处理
    const errorMessage: ErrorMessage = {
      message: customMessage || error.message || '未知错误',
      type: 'error'
    };
    return errorMessage;
  }

  private static handleLocationError(code: LocationErrorCode, customMessage?: string): ErrorMessage {
    // 定义错误映射表
    const permissionDeniedEntry: ErrorMapEntry = { message: '需要位置权限才能获取当前天气', type: 'warning' };
    const locationSwitchOffEntry: ErrorMapEntry = { message: '请开启位置服务', type: 'warning' };
    const locationTimeoutEntry: ErrorMapEntry = { message: '定位超时，使用默认位置', type: 'info' };
    const contextUnavailableEntry: ErrorMapEntry = { message: '应用上下文不可用', type: 'error' };
    const networkErrorEntry: ErrorMapEntry = { message: '网络连接异常', type: 'error' };
    const unknownErrorEntry: ErrorMapEntry = { message: '定位服务异常', type: 'error' };

    const errorMap = new Map<LocationErrorCode, ErrorMapEntry>([
      [LocationErrorCode.PERMISSION_DENIED, permissionDeniedEntry],
      [LocationErrorCode.LOCATION_SWITCH_OFF, locationSwitchOffEntry],
      [LocationErrorCode.LOCATION_TIMEOUT, locationTimeoutEntry],
      [LocationErrorCode.CONTEXT_UNAVAILABLE, contextUnavailableEntry],
      [LocationErrorCode.NETWORK_ERROR, networkErrorEntry],
      [LocationErrorCode.UNKNOWN_ERROR, unknownErrorEntry]
    ]);

    const errorInfo = errorMap.get(code) || unknownErrorEntry;
    
    const errorMessage: ErrorMessage = {
      code: code,
      message: customMessage || errorInfo.message,
      type: errorInfo.type
    };
    
    return errorMessage;
  }

  static createNetworkError(message?: string): ErrorMessage {
    const errorMessage: ErrorMessage = {
      code: LocationErrorCode.NETWORK_ERROR,
      message: message || '网络连接失败，请检查网络设置',
      type: 'error'
    };
    return errorMessage;
  }

  static createInfoMessage(message: string): ErrorMessage {
    const errorMessage: ErrorMessage = {
      message: message,
      type: 'info'
    };
    return errorMessage;
  }

  static createWarningMessage(message: string): ErrorMessage {
    const errorMessage: ErrorMessage = {
      message: message,
      type: 'warning'
    };
    return errorMessage;
  }
}
