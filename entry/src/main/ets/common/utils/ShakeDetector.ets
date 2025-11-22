import sensor from '@ohos.sensor';
import { BusinessError } from '@ohos.base';

export interface ShakeConfig {
  threshold: number;        // 摇动阈值
  debounceTime: number;     // 防抖时间(ms)
  enabled: boolean;         // 是否启用
}

export class ShakeDetector {
  private static instance: ShakeDetector | null = null;
  private sensorId: number | null = null;
  private lastUpdate: number = 0;
  private lastX: number = 0;
  private lastY: number = 0;
  private lastZ: number = 0;
  private lastShakeTime: number = 0;
  private config: ShakeConfig = {
    threshold: 15,
    debounceTime: 1000,
    enabled: true
  };
  private callbacks: Array<() => void> = [];

  static getInstance(): ShakeDetector {
    if (ShakeDetector.instance === null) {
      ShakeDetector.instance = new ShakeDetector();
    }
    return ShakeDetector.instance;
  }

  updateConfig(config: Partial<ShakeConfig>): void {
    // 修复展开运算符问题，改为显式属性赋值
    if (config.threshold !== undefined) {
      this.config.threshold = config.threshold;
    }
    if (config.debounceTime !== undefined) {
      this.config.debounceTime = config.debounceTime;
    }
    if (config.enabled !== undefined) {
      this.config.enabled = config.enabled;
    }
  }

  startDetection(callback: () => void): boolean {
    if (!this.config.enabled) {
      console.warn('[ShakeDetector] Shake detection is disabled');
      return false;
    }

    try {
      // 添加回调
      if (!this.callbacks.includes(callback)) {
        this.callbacks.push(callback);
      }

      // 如果已经在监听，直接返回
      if (this.sensorId !== null) {
        return true;
      }

      // 开始监听加速度传感器
      sensor.on(sensor.SensorId.ACCELEROMETER, (data) => {
        this.handleAccelerometerData(data);
      }, {
        interval: 100000000 // 100ms间隔，单位纳秒
      });
      
      // 设置一个标识表示正在监听
      this.sensorId = 1;

      console.info('[ShakeDetector] Shake detection started');
      return true;

    } catch (error) {
      const err = error as BusinessError;
      console.error('[ShakeDetector] Failed to start detection:', err.message);
      return false;
    }
  }

  stopDetection(callback?: () => void): void {
    if (callback) {
      // 移除特定回调
      const index = this.callbacks.indexOf(callback);
      if (index > -1) {
        this.callbacks.splice(index, 1);
      }
    } else {
      // 清空所有回调
      this.callbacks = [];
    }

    // 如果没有回调了，停止传感器监听
    if (this.callbacks.length === 0 && this.sensorId !== null) {
      try {
        sensor.off(sensor.SensorId.ACCELEROMETER);
        this.sensorId = null;
        console.info('[ShakeDetector] Shake detection stopped');
      } catch (error) {
        const err = error as BusinessError;
        console.error('[ShakeDetector] Failed to stop detection:', err.message);
      }
    }
  }

  private handleAccelerometerData(data: sensor.AccelerometerResponse): void {
    const currentTime = Date.now();
    
    // 限制检测频率
    if ((currentTime - this.lastUpdate) < 100) {
      return;
    }

    // 计算加速度变化
    const deltaX = Math.abs(data.x - this.lastX);
    const deltaY = Math.abs(data.y - this.lastY);
    const deltaZ = Math.abs(data.z - this.lastZ);
    const totalDelta = deltaX + deltaY + deltaZ;

    // 检测摇动
    if (totalDelta > this.config.threshold) {
      // 防抖处理
      if ((currentTime - this.lastShakeTime) > this.config.debounceTime) {
        this.lastShakeTime = currentTime;
        this.triggerShake();
      }
    }

    // 更新上次数据
    this.lastUpdate = currentTime;
    this.lastX = data.x;
    this.lastY = data.y;
    this.lastZ = data.z;
  }

  private triggerShake(): void {
    console.info('[ShakeDetector] Shake detected, triggering callbacks');
    
    // 触发所有回调
    this.callbacks.forEach(callback => {
      try {
        callback();
      } catch (error) {
        console.error('[ShakeDetector] Callback error:', error);
      }
    });
  }

  isDetecting(): boolean {
    return this.sensorId !== null;
  }

  getConfig(): ShakeConfig {
    // 修复展开运算符问题，改为显式属性复制
    return {
      threshold: this.config.threshold,
      debounceTime: this.config.debounceTime,
      enabled: this.config.enabled
    };
  }
}
