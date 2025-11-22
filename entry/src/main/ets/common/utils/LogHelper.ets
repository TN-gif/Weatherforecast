/**
 * 日志辅助工具类
 * 用于统一管理应用日志输出和问题诊断
 */
enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

interface LogLevelMap {
  DEBUG: number;
  INFO: number;
  WARN: number;
  ERROR: number;
}

export class LogHelper {
  private static readonly LOG_LEVELS: LogLevelMap = {
    DEBUG: LogLevel.DEBUG,
    INFO: LogLevel.INFO,
    WARN: LogLevel.WARN,
    ERROR: LogLevel.ERROR
  };

  private static currentLevel = LogLevel.DEBUG;

  /**
   * 设置日志级别
   */
  static setLogLevel(level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR'): void {
    switch (level) {
      case 'DEBUG':
        LogHelper.currentLevel = LogLevel.DEBUG;
        break;
      case 'INFO':
        LogHelper.currentLevel = LogLevel.INFO;
        break;
      case 'WARN':
        LogHelper.currentLevel = LogLevel.WARN;
        break;
      case 'ERROR':
        LogHelper.currentLevel = LogLevel.ERROR;
        break;
    }
  }

  /**
   * 输出调试信息
   */
  static debug(tag: string, message: string, data?: string): void {
    if (LogHelper.currentLevel <= LogLevel.DEBUG) {
      const timestamp = new Date().toISOString();
      const dataStr = data ? (typeof data === 'string' ? data : JSON.stringify(data)) : '';
      console.debug(`[${timestamp}] [DEBUG] [${tag}] ${message}`, dataStr);
    }
  }

  /**
   * 输出信息
   */
  static info(tag: string, message: string, data?: string): void {
    if (LogHelper.currentLevel <= LogLevel.INFO) {
      const timestamp = new Date().toISOString();
      const dataStr = data ? (typeof data === 'string' ? data : JSON.stringify(data)) : '';
      console.info(`[${timestamp}] [INFO] [${tag}] ${message}`, dataStr);
    }
  }

  /**
   * 输出警告
   */
  static warn(tag: string, message: string, data?: string): void {
    if (LogHelper.currentLevel <= LogLevel.WARN) {
      const timestamp = new Date().toISOString();
      const dataStr = data ? (typeof data === 'string' ? data : JSON.stringify(data)) : '';
      console.warn(`[${timestamp}] [WARN] [${tag}] ${message}`, dataStr);
    }
  }

  /**
   * 输出错误
   */
  static error(tag: string, message: string, error?: string | Error): void {
    if (LogHelper.currentLevel <= LogLevel.ERROR) {
      const timestamp = new Date().toISOString();
      console.error(`[${timestamp}] [ERROR] [${tag}] ${message}`);
      if (error) {
        if (error instanceof Error) {
          console.error(`[${timestamp}] [ERROR] [${tag}] Stack: ${error.stack}`);
        } else {
          const errorStr = typeof error === 'string' ? error : JSON.stringify(error);
          console.error(`[${timestamp}] [ERROR] [${tag}] Data: ${errorStr}`);
        }
      }
    }
  }

  /**
   * 输出性能统计
   */
  static performance(tag: string, operation: string, startTime: number, endTime?: number): void {
    const actualEndTime = endTime || Date.now();
    const duration = actualEndTime - startTime;
    LogHelper.info(tag, `⏱️ ${operation} 耗时: ${duration}ms`);
  }

  /**
   * 输出网络请求日志
   */
  static network(tag: string, method: string, url: string, status?: number, duration?: number): void {
    const statusText = status ? `[${status}]` : '[PENDING]';
    const durationText = duration ? ` (${duration}ms)` : '';
    LogHelper.info(tag, `🌐 ${method} ${url} ${statusText}${durationText}`);
  }

  /**
   * 输出数据流日志
   */
  static dataFlow(tag: string, source: string, target: string, dataType: string, success: boolean = true): void {
    const status = success ? '✅' : '❌';
    LogHelper.info(tag, `📊 ${status} ${dataType}: ${source} → ${target}`);
  }

  /**
   * 输出系统状态
   */
  static systemStatus(tag: string, component: string, status: 'INIT' | 'READY' | 'ERROR' | 'LOADING'): void {
    const statusEmoji: Record<string, string> = {
      'INIT': '🔧',
      'READY': '✅',
      'ERROR': '❌',
      'LOADING': '⏳'
    };
    LogHelper.info(tag, `${statusEmoji[status]} ${component}: ${status}`);
  }

  /**
   * 创建问题诊断报告
   */
  static createDiagnosticReport(): string {
    const timestamp = new Date().toISOString();
    return `
========== 天气应用诊断报告 ==========
生成时间: ${timestamp}
应用版本: 1.0.0
平台: HarmonyOS
日志级别: ${Object.keys(LogHelper.LOG_LEVELS)[LogHelper.currentLevel]}

请查看控制台日志以获取详细的执行流程信息。
关键日志标签:
- [WeatherService]: 网络请求和API调用
- [WeatherRepository]: 数据缓存和降级策略  
- [WeatherController]: 城市管理和数据协调
- [WeatherHomePage]: UI交互和用户操作
- [CacheStorage]: 数据持久化
- [LocationService]: 定位服务

常见问题排查:
1. 网络连接: 查看 WeatherService 的 HTTP 请求日志
2. 数据缓存: 查看 WeatherRepository 的缓存策略日志
3. 城市数据: 查看 WeatherController 的城市加载日志
4. UI更新: 查看 WeatherHomePage 的刷新流程日志
=====================================
    `;
  }
}
