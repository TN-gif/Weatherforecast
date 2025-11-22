import { AppPreferences } from '../../data/storage/AppPreferences';

export enum ThemeMode {
  AUTO = 'auto',
  LIGHT = 'light',
  DARK = 'dark'
}

export interface ThemeConfig {
  primaryColor: string;
  backgroundColor: string;
  surfaceColor: string;
  cardColor: string;
  textPrimaryColor: string;
  textSecondaryColor: string;
  textHintColor: string;
  dividerColor: string;
  shadowColor: string;
  cardOpacity: number;
  chartColor: string;
  accentColor: string;
  errorColor: string;
  successColor: string;
  warningColor: string;
}

export interface ThemeTransition {
  duration: number;
  curve: Curve;
  delay: number;
}

export class ThemeManager {
  private static instance: ThemeManager | null = null;
  private currentTheme: ThemeMode = ThemeMode.AUTO;
  private currentConfig: ThemeConfig;
  private preferences: AppPreferences = new AppPreferences();
  private transitionCallbacks: Array<(config: ThemeConfig) => void> = [];
  private autoSwitchTimer: number | null = null;

  private constructor() {
    this.currentConfig = this.getLightTheme();
  }

  static getInstance(): ThemeManager {
    if (ThemeManager.instance === null) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  async init(): Promise<void> {
    // 加载用户偏好
    const savedTheme = await this.preferences.getThemeMode();
    this.currentTheme = savedTheme as ThemeMode || ThemeMode.AUTO;
    
    // 应用主题
    await this.applyTheme();
    
    // 启动自动切换监听
    this.startAutoSwitchMonitoring();
    
    console.info(`[ThemeManager] Initialized with theme: ${this.currentTheme}`);
  }

  /**
   * 获取浅色主题配置
   */
  private getLightTheme(): ThemeConfig {
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

  /**
   * 获取深色主题配置
   */
  private getDarkTheme(): ThemeConfig {
    return {
      primaryColor: '#2C3E50',
      backgroundColor: '#121212',
      surfaceColor: '#1E1E1E',
      cardColor: 'rgba(30, 30, 30, 0.9)',
      textPrimaryColor: '#FFFFFF',
      textSecondaryColor: '#B3B3B3',
      textHintColor: '#666666',
      dividerColor: 'rgba(255, 255, 255, 0.1)',
      shadowColor: 'rgba(0, 0, 0, 0.3)',
      cardOpacity: 0.25,
      chartColor: '#4CAF50',
      accentColor: '#64B5F6',
      errorColor: '#EF5350',
      successColor: '#66BB6A',
      warningColor: '#FFA726'
    };
  }

  /**
   * 判断当前是否为夜间模式
   */
  isNightMode(): boolean {
    const now = new Date();
    const hours = now.getHours();
    return hours >= 18 || hours <= 6;
  }

  /**
   * 获取系统主题模式
   */
  private getSystemThemeMode(): ThemeMode {
    // 在实际应用中，这里应该读取系统主题设置
    // 目前基于时间判断
    return this.isNightMode() ? ThemeMode.DARK : ThemeMode.LIGHT;
  }

  /**
   * 应用主题
   */
  async applyTheme(): Promise<void> {
    let targetMode: ThemeMode;
    
    if (this.currentTheme === ThemeMode.AUTO) {
      targetMode = this.getSystemThemeMode();
    } else {
      targetMode = this.currentTheme;
    }
    
    const newConfig = targetMode === ThemeMode.DARK ? 
      this.getDarkTheme() : this.getLightTheme();
    
    // 执行主题切换动画
    await this.switchTheme(newConfig);
    
    console.info(`[ThemeManager] Applied theme: ${targetMode}`);
  }

  /**
   * 平滑切换主题
   */
  private async switchTheme(newConfig: ThemeConfig): Promise<void> {
    const transition: ThemeTransition = {
      duration: 300,
      curve: Curve.EaseInOut,
      delay: 0
    };
    
    // 通知所有监听器开始过渡
    this.notifyTransitionStart(newConfig, transition);
    
    // 等待动画完成
    await new Promise<void>((resolve) => setTimeout(resolve, transition.duration));
    
    // 更新当前配置
    this.currentConfig = newConfig;
    
    // 保存到AppStorage供全局使用
    AppStorage.setOrCreate('currentTheme', newConfig);
    AppStorage.setOrCreate('isDarkMode', this.isDarkMode());
    
    // 通知所有监听器完成过渡
    this.notifyTransitionComplete(newConfig);
  }

  /**
   * 设置主题模式
   */
  async setThemeMode(mode: ThemeMode): Promise<void> {
    if (this.currentTheme === mode) {
      return;
    }
    
    this.currentTheme = mode;
    
    // 保存用户偏好
    await this.preferences.setThemeMode(mode);
    
    // 应用新主题
    await this.applyTheme();
    
    // 重新启动自动切换监听
    this.restartAutoSwitchMonitoring();
    
    console.info(`[ThemeManager] Theme mode changed to: ${mode}`);
  }

  /**
   * 获取当前主题配置
   */
  getCurrentConfig(): ThemeConfig {
    const config: ThemeConfig = {
      primaryColor: this.currentConfig.primaryColor,
      backgroundColor: this.currentConfig.backgroundColor,
      surfaceColor: this.currentConfig.surfaceColor,
      cardColor: this.currentConfig.cardColor,
      textPrimaryColor: this.currentConfig.textPrimaryColor,
      textSecondaryColor: this.currentConfig.textSecondaryColor,
      textHintColor: this.currentConfig.textHintColor,
      dividerColor: this.currentConfig.dividerColor,
      shadowColor: this.currentConfig.shadowColor,
      cardOpacity: this.currentConfig.cardOpacity,
      chartColor: this.currentConfig.chartColor,
      accentColor: this.currentConfig.accentColor,
      errorColor: this.currentConfig.errorColor,
      successColor: this.currentConfig.successColor,
      warningColor: this.currentConfig.warningColor
    };
    return config;
  }

  /**
   * 获取当前主题模式
   */
  getCurrentMode(): ThemeMode {
    return this.currentTheme;
  }

  /**
   * 判断当前是否为深色模式
   */
  isDarkMode(): boolean {
    if (this.currentTheme === ThemeMode.AUTO) {
      return this.isNightMode();
    }
    return this.currentTheme === ThemeMode.DARK;
  }

  /**
   * 注册主题变化监听器
   */
  addTransitionListener(callback: (config: ThemeConfig) => void): void {
    this.transitionCallbacks.push(callback);
  }

  /**
   * 移除主题变化监听器
   */
  removeTransitionListener(callback: (config: ThemeConfig) => void): void {
    const index = this.transitionCallbacks.indexOf(callback);
    if (index > -1) {
      this.transitionCallbacks.splice(index, 1);
    }
  }

  /**
   * 通知过渡开始
   */
  private notifyTransitionStart(config: ThemeConfig, transition: ThemeTransition): void {
    // 触发全局动画
    animateTo({
      duration: transition.duration,
      curve: transition.curve,
      delay: transition.delay
    }, () => {
      // 动画回调
    });
  }

  /**
   * 通知过渡完成
   */
  private notifyTransitionComplete(config: ThemeConfig): void {
    this.transitionCallbacks.forEach(callback => {
      try {
        callback(config);
      } catch (error) {
        console.error('[ThemeManager] Transition callback error:', error);
      }
    });
  }

  /**
   * 启动自动切换监听
   */
  private startAutoSwitchMonitoring(): void {
    if (this.currentTheme !== ThemeMode.AUTO) {
      return;
    }
    
    // 每分钟检查一次是否需要切换主题
    this.autoSwitchTimer = setInterval(() => {
      this.checkAutoSwitch();
    }, 60000); // 60秒检查一次
    
    console.info('[ThemeManager] Auto switch monitoring started');
  }

  /**
   * 停止自动切换监听
   */
  private stopAutoSwitchMonitoring(): void {
    if (this.autoSwitchTimer !== null) {
      clearInterval(this.autoSwitchTimer);
      this.autoSwitchTimer = null;
      console.info('[ThemeManager] Auto switch monitoring stopped');
    }
  }

  /**
   * 重新启动自动切换监听
   */
  private restartAutoSwitchMonitoring(): void {
    this.stopAutoSwitchMonitoring();
    this.startAutoSwitchMonitoring();
  }

  /**
   * 检查是否需要自动切换
   */
  private async checkAutoSwitch(): Promise<void> {
    if (this.currentTheme !== ThemeMode.AUTO) {
      return;
    }
    
    const systemMode = this.getSystemThemeMode();
    const currentIsDark = this.isDarkMode();
    const shouldBeDark = systemMode === ThemeMode.DARK;
    
    if (currentIsDark !== shouldBeDark) {
      console.info(`[ThemeManager] Auto switching theme: ${shouldBeDark ? 'dark' : 'light'}`);
      await this.applyTheme();
    }
  }

  /**
   * 销毁主题管理器
   */
  destroy(): void {
    this.stopAutoSwitchMonitoring();
    this.transitionCallbacks.length = 0;
    console.info('[ThemeManager] Destroyed');
  }

  /**
   * 获取主题切换建议
   */
  getThemeSuggestion(): string {
    const now = new Date();
    const hours = now.getHours();
    
    if (hours >= 6 && hours < 18) {
      return '当前是白天时间，建议使用浅色主题以获得更好的阅读体验';
    } else {
      return '当前是夜间时间，建议使用深色主题以减少眼部疲劳';
    }
  }
}
