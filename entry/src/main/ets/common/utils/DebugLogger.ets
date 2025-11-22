/**
 * 详尽的调试日志系统
 * 用于诊断功能显示问题
 */

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

// 使用 Record 替代接口索引签名
export type LogData = Record<string, string | number | boolean | string[] | undefined>;

export class DebugLogger {
  private static instance: DebugLogger | null = null;
  private readonly TAG = '[AuroraWeather]';
  private logLevel: LogLevel = LogLevel.DEBUG;
  private logs: string[] = [];
  private maxLogs: number = 1000;

  static getInstance(): DebugLogger {
    if (DebugLogger.instance === null) {
      DebugLogger.instance = new DebugLogger();
    }
    return DebugLogger.instance;
  }

  private constructor() {
    console.info('[DebugLogger] 🚀 调试日志系统已启动');
  }

  private formatMessage(
    prefix: string, 
    component: string, 
    message: string, 
    data?: LogData
  ): string {
    const timestamp = new Date().toISOString();
    const dataStr = data ? ` | 数据: ${JSON.stringify(data)}` : '';
    return `[${timestamp}] [${prefix}] [${component}] ${message}${dataStr}`;
  }

  private addLog(formattedMessage: string): void {
    this.logs.push(formattedMessage);
    if (this.logs.length > this.maxLogs) {
      this.logs.shift();
    }
  }

  debug(component: string, message: string, data?: LogData): void {
    if (this.logLevel <= LogLevel.DEBUG) {
      const formatted = this.formatMessage('🔍 DEBUG', component, message, data);
      console.debug(formatted);
      this.addLog(formatted);
    }
  }

  info(component: string, message: string, data?: LogData): void {
    if (this.logLevel <= LogLevel.INFO) {
      const formatted = this.formatMessage('ℹ️ INFO', component, message, data);
      console.info(formatted);
      this.addLog(formatted);
    }
  }

  warn(component: string, message: string, data?: LogData): void {
    if (this.logLevel <= LogLevel.WARN) {
      const formatted = this.formatMessage('⚠️ WARN', component, message, data);
      console.warn(formatted);
      this.addLog(formatted);
    }
  }

  error(component: string, message: string, error?: Error | string): void {
    if (this.logLevel <= LogLevel.ERROR) {
      let errorData: LogData;
      if (error instanceof Error) {
        errorData = { 
          'message': error.message, 
          'stack': error.stack ?? '' 
        };
      } else {
        errorData = { 
          'message': String(error) 
        };
      }
      const formatted = this.formatMessage('❌ ERROR', component, message, errorData);
      console.error(formatted);
      this.addLog(formatted);
    }
  }

  // 功能状态检查专用方法
  checkFeature(component: string, featureName: string, isAvailable: boolean, details?: LogData): void {
    const status = isAvailable ? '✅ 启用' : '❌ 禁用';
    const message = `功能检查: ${featureName} - ${status}`;
    this.info(component, message, details);
  }

  // 组件生命周期日志
  lifecycle(component: string, message: string, data?: LogData): void {
    this.info(component, `🔄 生命周期: ${message}`, data);
  }

  // 用户交互日志
  userAction(component: string, action: string, data?: LogData): void {
    this.info(component, `👆 用户操作: ${action}`, data);
  }

  // 性能监控日志
  performance(component: string, message: string, duration: number, data?: LogData): void {
    const performanceData: LogData = { 'duration': duration };
    if (data) {
      const keys = Object.keys(data);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        performanceData[key] = data[key];
      }
    }
    this.info(component, message, performanceData);
  }

  // 获取所有日志
  getAllLogs(): string[] {
    return [...this.logs];
  }

  // 清空日志
  clearLogs(): void {
    this.logs = [];
    this.info('DebugLogger', '🧹 日志已清空');
  }

  // 导出日志到字符串
  exportLogs(): string {
    return this.logs.join('\n');
  }
}
