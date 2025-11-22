import { LocationErrorCode } from '../../data/models/WeatherModels';

export interface ErrorMessage {
  code?: number;
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
    // 定义错误信息接口
    interface ErrorInfo {
      message: string;
      type: 'error' | 'warning' | 'info';
    }

    // 定义各种错误信息
    const permissionDeniedInfo: ErrorInfo = { message: '需要位置权限才能获取当前天气', type: 'warning' };
    const locationSwitchOffInfo: ErrorInfo = { message: '请开启位置服务', type: 'warning' };
    const locationTimeoutInfo: ErrorInfo = { message: '定位超时，使用默认位置', type: 'info' };
    const contextUnavailableInfo: ErrorInfo = { message: '应用上下文不可用', type: 'error' };
    const networkErrorInfo: ErrorInfo = { message: '网络连接异常', type: 'error' };
    const unknownErrorInfo: ErrorInfo = { message: '定位服务异常', type: 'error' };
    const defaultErrorInfo: ErrorInfo = { message: '未知错误', type: 'error' };

    // 创建错误映射数组
    const errorEntries: Array<[LocationErrorCode, ErrorInfo]> = [
      [LocationErrorCode.PERMISSION_DENIED, permissionDeniedInfo],
      [LocationErrorCode.LOCATION_SWITCH_OFF, locationSwitchOffInfo],
      [LocationErrorCode.LOCATION_TIMEOUT, locationTimeoutInfo],
      [LocationErrorCode.CONTEXT_UNAVAILABLE, contextUnavailableInfo],
      [LocationErrorCode.NETWORK_ERROR, networkErrorInfo],
      [LocationErrorCode.UNKNOWN_ERROR, unknownErrorInfo]
    ];

    const errorMap = new Map<LocationErrorCode, ErrorInfo>(errorEntries);
    const errorInfo = errorMap.get(code) || defaultErrorInfo;
    
    const result: ErrorMessage = {
      code: code,
      message: customMessage || errorInfo.message,
      type: errorInfo.type
    };
    
    return result;
  }

  static createNetworkError(message?: string): ErrorMessage {
    const networkError: ErrorMessage = {
      code: LocationErrorCode.NETWORK_ERROR,
      message: message || '网络连接失败，请检查网络设置',
      type: 'error'
    };
    return networkError;
  }

  static createInfoMessage(message: string): ErrorMessage {
    const infoMessage: ErrorMessage = {
      message: message,
      type: 'info'
    };
    return infoMessage;
  }

  static createWarningMessage(message: string): ErrorMessage {
    const warningMessage: ErrorMessage = {
      message: message,
      type: 'warning'
    };
    return warningMessage;
  }
}
