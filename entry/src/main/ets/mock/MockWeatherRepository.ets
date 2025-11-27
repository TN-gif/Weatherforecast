import { WeatherSnapshot, WeatherCondition, CurrentWeather, HourlyForecast, DailyForecast, AdviceItem, WeatherAlert, RainForecast } from '../data/models/WeatherModels';
import { DesignSystem } from '../common/theme/DesignSystem';

export class MockWeatherRepository {
  private readonly snapshot: WeatherSnapshot;

  constructor() {
    const condition: WeatherCondition = {
      description: '晴朗',
      iconCode: 'sunny',
      themeKey: 'sunny',
      emotion: '光束穿过云层，今天也要元气满满'
    };

    const current: CurrentWeather = {
      temperatureC: 28.4,
      feelsLikeC: 30.1,
      humidity: 55,
      windSpeedKph: 12,
      windDirection: '东南风',
      pressureHpa: 1010,
      visibilityKm: 12,
      uvIndex: 6,
      aqi: 48,
      sunrise: '05:42',
      sunset: '18:52',
      condition: condition
    };

    const hourly: HourlyForecast[] = [
      { time: '2024-08-30T09:00:00', temperatureC: 26, precipitationProbability: 10, iconCode: 'sunny', description: '日光慵懒' },
      { time: '2024-08-30T12:00:00', temperatureC: 29, precipitationProbability: 5, iconCode: 'sunny', description: '正午小憩' },
      { time: '2024-08-30T15:00:00', temperatureC: 30, precipitationProbability: 15, iconCode: 'sunny', description: '微风拂面' },
      { time: '2024-08-30T18:00:00', temperatureC: 27, precipitationProbability: 20, iconCode: 'sunset', description: '晚霞浪漫' },
      { time: '2024-08-30T21:00:00', temperatureC: 24, precipitationProbability: 25, iconCode: 'night', description: '夜色温柔' }
    ];

    const daily: DailyForecast[] = [
      { date: '2024-08-30', minTempC: 24, maxTempC: 31, iconCode: 'sunny', description: '晴朗舒适', precipitationProbability: 15 },
      { date: '2024-08-31', minTempC: 25, maxTempC: 32, iconCode: 'cloudy', description: '多云有风', precipitationProbability: 20 },
      { date: '2024-09-01', minTempC: 22, maxTempC: 29, iconCode: 'rainy', description: '局部阵雨', precipitationProbability: 60 },
      { date: '2024-09-02', minTempC: 21, maxTempC: 28, iconCode: 'sunny', description: '清爽晴天', precipitationProbability: 10 }
    ];

    const advice: AdviceItem[] = [
      { id: 'ad1', icon: 'sun', tone: '防晒提醒', content: '紫外线指数偏高，外出记得带伞或帽子', priority: 1 },
      { id: 'ad2', icon: 'drop', tone: '补水建议', content: '湿度适中，随身小水杯可以保持元气', priority: 2 },
      { id: 'ad3', icon: 'wind', tone: '出行提示', content: '今日风力适中，适合户外活动', priority: 3 }
    ];

    // 生成天气预警数据（基于天气条件）
    const alerts: WeatherAlert[] = [];
    // 如果降雨概率高，添加预警
    if (daily[2].precipitationProbability > 50) {
      const rainAlert: WeatherAlert = {
        id: 'alert_rain_001',
        severity: 'warning',
        title: '明日降雨提醒',
        description: '预计明日有中到大雨，请提前准备雨具，注意出行安全',
        startTime: daily[2].date + 'T06:00:00',
        endTime: daily[2].date + 'T20:00:00',
        iconResource: DesignSystem.IconResources.RAIN
      };
      alerts.push(rainAlert);
    }

    // 生成未来60分钟降雨预测
    const rainForecast: RainForecast[] = [];
    const now = new Date();
    const baseProb = current.humidity > 60 ? 20 : 5; // 基础概率
    
    for (let i = 0; i < 12; i++) { // 每5分钟一个点，共60分钟
      const minutes = i * 5;
      const prob = baseProb + Math.sin(i * 0.5) * 15; // 模拟波动
      const probability = Math.max(0, Math.min(100, prob));
      
      let intensity: 'light' | 'moderate' | 'heavy' = 'light';
      if (probability > 70) intensity = 'heavy';
      else if (probability > 40) intensity = 'moderate';
      
      const forecastItem: RainForecast = {
        timeMinutes: minutes,
        probability: Math.round(probability),
        intensity: intensity
      };
      rainForecast.push(forecastItem);
    }

    this.snapshot = {
      cityId: 'mock_city',
      lastUpdatedIso: new Date().toISOString(),
      timezoneOffsetMinutes: 480,
      current: current,
      hourly: hourly,
      daily: daily,
      advice: advice,
      alerts: alerts,
      rainForecast: rainForecast,
      dataSource: 'mock'
    };
  }

  getSnapshot(cityId: string): WeatherSnapshot {
    const base: WeatherSnapshot = this.snapshot;
    const mockSnapshot: WeatherSnapshot = {
      cityId: cityId,
      lastUpdatedIso: base.lastUpdatedIso,
      timezoneOffsetMinutes: base.timezoneOffsetMinutes,
      current: base.current,
      hourly: base.hourly,
      daily: base.daily,
      advice: base.advice,
      alerts: base.alerts,
      rainForecast: base.rainForecast,
      dataSource: base.dataSource
    };
    return mockSnapshot;
  }
}
