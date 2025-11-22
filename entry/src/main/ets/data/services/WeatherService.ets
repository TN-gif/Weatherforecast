import http from '@ohos.net.http';
import { Coordinates, WeatherSnapshot, WeatherApiConfig, WeatherCondition, CurrentWeather, HourlyForecast, DailyForecast, AdviceItem } from '../models/WeatherModels';

interface OpenMeteoCurrentWeather {
  temperature: number;
  windspeed: number;
  winddirection: number;
  weathercode: number;
  time: string;
}

interface OpenMeteoHourlyBlock {
  time: string[];
  temperature_2m: number[];
  precipitation_probability: number[];
}

interface OpenMeteoDailyBlock {
  time: string[];
  temperature_2m_max: number[];
  temperature_2m_min: number[];
  precipitation_probability_max: number[];
  weathercode: number[];
}

interface OpenMeteoResponse {
  current_weather: OpenMeteoCurrentWeather;
  hourly: OpenMeteoHourlyBlock;
  daily: OpenMeteoDailyBlock;
  timezone_abbreviation: string;
  utc_offset_seconds: number;
}

interface RetryConfig {
  readonly maxRetries: number;
  readonly baseDelay: number;
  readonly backoffMultiplier: number;
  readonly timeoutMs: number;
  readonly maxDelay: number;
}

export class WeatherService {
  private readonly config: WeatherApiConfig;
  private readonly retryConfig: RetryConfig = {
    maxRetries: 3,
    baseDelay: 400,
    backoffMultiplier: 2,
    timeoutMs: 20000, // 增加到20秒，适应网络条件
    maxDelay: 4000
  };

  constructor(config: WeatherApiConfig) {
    this.config = config;
  }

  async fetchWeather(cityId: string, coordinates: Coordinates): Promise<WeatherSnapshot> {
    console.info(`[WeatherService] ========== 开始获取天气数据 ==========`);
    console.info(`[WeatherService] 城市ID: ${cityId}`);
    console.info(`[WeatherService] 坐标: 纬度=${coordinates.latitude}, 经度=${coordinates.longitude}`);
    console.info(`[WeatherService] API配置: ${JSON.stringify(this.config)}`);
    
    const query: string = this.buildQuery(coordinates);
    console.info(`[WeatherService] 完整请求URL: ${query}`);
    let attempt: number = 1;

    while (attempt <= this.retryConfig.maxRetries) {
      console.info(`[WeatherService] 尝试第 ${attempt}/${this.retryConfig.maxRetries} 次请求`);
      const httpRequest: http.HttpRequest = http.createHttp();
      const startTime = Date.now();
      
      try {
        console.info(`[WeatherService] 开始HTTP请求...`);
        const payload: OpenMeteoResponse = await this.performRequest(httpRequest, query);
        const requestTime = Date.now() - startTime;
        console.info(`[WeatherService] HTTP请求成功，耗时: ${requestTime}ms`);
        
        console.info(`[WeatherService] 开始验证响应数据...`);
        this.validatePayload(payload);
        console.info(`[WeatherService] 数据验证通过`);
        
        console.info(`[WeatherService] 开始转换数据格式...`);
        const snapshot = this.mapToSnapshot(cityId, payload);
        console.info(`[WeatherService] ========== 天气数据获取成功 ==========`);
        return snapshot;
      } catch (error) {
        const requestTime = Date.now() - startTime;
        const err = error as Error;
        console.error(`[WeatherService] 第${attempt}次请求失败，耗时: ${requestTime}ms`);
        console.error(`[WeatherService] 错误类型: ${err.name}`);
        console.error(`[WeatherService] 错误信息: ${err.message}`);
        console.error(`[WeatherService] 错误堆栈: ${err.stack}`);
        
        if (!this.isRetryableError(err) || attempt === this.retryConfig.maxRetries) {
          console.error(`[WeatherService] ========== 天气数据获取最终失败 ==========`);
          throw new Error(`Weather fetch failed after ${attempt} attempts: ${err.message}`);
        }
        const delay: number = this.calculateDelay(attempt);
        console.warn(`[WeatherService] 将在 ${delay}ms 后重试...`);
        await this.sleep(delay);
      } finally {
        httpRequest.destroy();
        attempt++;
      }
    }
    throw new Error('WeatherService exhausted retries');
  }

  private buildQuery(coordinates: Coordinates): string {
    return `${this.config.baseUrl}?latitude=${coordinates.latitude}&longitude=${coordinates.longitude}` +
      `&current_weather=true&hourly=temperature_2m,precipitation_probability` +
      `&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max` +
      `&forecast_days=${this.config.dailyCount}&timezone=auto`;
  }

  private async performRequest(httpRequest: http.HttpRequest, query: string): Promise<OpenMeteoResponse> {
    console.info(`[WeatherService] 配置HTTP请求参数...`);
    const requestConfig: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: this.retryConfig.timeoutMs,
      readTimeout: this.retryConfig.timeoutMs
    };
    console.info(`[WeatherService] 请求配置: ${JSON.stringify(requestConfig)}`);
    
    console.info(`[WeatherService] 等待HTTP响应...`);
    const response: http.HttpResponse = await httpRequest.request(query, requestConfig);
    
    console.info(`[WeatherService] 收到HTTP响应`);
    console.info(`[WeatherService] 响应码: ${response.responseCode}`);
    console.info(`[WeatherService] 响应头: ${JSON.stringify(response.header)}`);
    
    if (response.responseCode !== 200) {
      console.error(`[WeatherService] HTTP错误: ${response.responseCode}`);
      console.error(`[WeatherService] 响应内容: ${response.result}`);
      throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
    }

    const responseText = response.result as string;
    console.info(`[WeatherService] 响应数据长度: ${responseText.length} 字符`);
    console.info(`[WeatherService] 响应数据预览: ${responseText.substring(0, 200)}...`);
    
    try {
      const jsonData = JSON.parse(responseText) as OpenMeteoResponse;
      console.info(`[WeatherService] JSON解析成功`);
      return jsonData;
    } catch (parseError) {
      console.error(`[WeatherService] JSON解析失败: ${(parseError as Error).message}`);
      console.error(`[WeatherService] 原始响应: ${responseText}`);
      throw new Error(`JSON parse error: ${(parseError as Error).message}`);
    }
  }

  private validatePayload(payload: OpenMeteoResponse): void {
    if (!payload.current_weather || !payload.hourly || !payload.daily) {
      throw new Error('invalid_payload');
    }
    if (!payload.hourly.temperature_2m || !payload.hourly.time) {
      throw new Error('invalid_hourly_block');
    }
    if (!payload.daily.temperature_2m_max || !payload.daily.time) {
      throw new Error('invalid_daily_block');
    }
  }

  private isRetryableError(error: Error): boolean {
    const message: string = (error.message || '').toLowerCase();
    if (message.includes('404') || message.includes('401') || message.includes('invalid')) {
      return false;
    }
    return true;
  }

  private calculateDelay(attempt: number): number {
    const exponential: number = this.retryConfig.baseDelay * Math.pow(this.retryConfig.backoffMultiplier, attempt - 1);
    const capped: number = Math.min(exponential, this.retryConfig.maxDelay);
    const jitter: number = capped * 0.25 * (Math.random() * 2 - 1);
    return Math.floor(capped + jitter);
  }

  private sleep(duration: number): Promise<void> {
    return new Promise((resolve: () => void) => setTimeout(resolve, duration));
  }

  private mapToSnapshot(cityId: string, payload: OpenMeteoResponse): WeatherSnapshot {
    const condition: WeatherCondition = this.mapWeatherCode(payload.current_weather.weathercode);
    const current: CurrentWeather = {
      temperatureC: payload.current_weather.temperature,
      feelsLikeC: payload.current_weather.temperature,
      humidity: 65,
      windSpeedKph: payload.current_weather.windspeed,
      windDirection: `${payload.current_weather.winddirection.toFixed(0)}°`,
      pressureHpa: 1012,
      visibilityKm: 10,
      uvIndex: 4,
      aqi: 45,
      sunrise: '06:10',
      sunset: '18:45',
      condition: condition
    };

    const hourly: HourlyForecast[] = [];
    let index: number = 0;
    while (index < payload.hourly.time.length && index < this.config.hourlyCount) {
      hourly.push({
        time: payload.hourly.time[index],
        temperatureC: payload.hourly.temperature_2m[index],
        precipitationProbability: payload.hourly.precipitation_probability[index],
        iconCode: condition.iconCode,
        description: condition.description
      });
      index++;
    }

    const daily: DailyForecast[] = [];
    let dailyIndex: number = 0;
    while (dailyIndex < payload.daily.time.length && dailyIndex < this.config.dailyCount) {
      const dayCondition: WeatherCondition = this.mapWeatherCode(payload.daily.weathercode[dailyIndex]);
      daily.push({
        date: payload.daily.time[dailyIndex],
        minTempC: payload.daily.temperature_2m_min[dailyIndex],
        maxTempC: payload.daily.temperature_2m_max[dailyIndex],
        iconCode: dayCondition.iconCode,
        description: dayCondition.description,
        precipitationProbability: payload.daily.precipitation_probability_max[dailyIndex]
      });
      dailyIndex++;
    }

    const advice: AdviceItem[] = this.generateAdvice(condition, current);

    const weatherSnapshot: WeatherSnapshot = {
      cityId: cityId,
      lastUpdatedIso: new Date().toISOString(),
      timezoneOffsetMinutes: payload.utc_offset_seconds / 60,
      current: current,
      hourly: hourly,
      daily: daily,
      advice: advice,
      dataSource: 'open-meteo'
    };
    return weatherSnapshot;
  }

  private mapWeatherCode(code: number): WeatherCondition {
    if (code === 0) {
      const sunnyCondition: WeatherCondition = { description: '晴朗', iconCode: 'sunny', themeKey: 'sunny', emotion: '晴空适合出行' };
      return sunnyCondition;
    }
    if (code >= 1 && code <= 3) {
      const cloudyCondition: WeatherCondition = { description: '多云', iconCode: 'cloudy', themeKey: 'sunny', emotion: '多云也别忘了补水' };
      return cloudyCondition;
    }
    if (code >= 45 && code <= 48) {
      const fogCondition: WeatherCondition = { description: '雾霾', iconCode: 'fog', themeKey: 'rainy', emotion: '能见度低，注意安全' };
      return fogCondition;
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      const rainyCondition: WeatherCondition = { description: '小雨', iconCode: 'rainy', themeKey: 'rainy', emotion: '雨天配咖啡更有味道' };
      return rainyCondition;
    }
    if (code >= 71 && code <= 77) {
      const snowCondition: WeatherCondition = { description: '降雪', iconCode: 'snow', themeKey: 'snow', emotion: '雪天请注意保暖' };
      return snowCondition;
    }
    const nightCondition: WeatherCondition = { description: '夜间', iconCode: 'night', themeKey: 'night', emotion: '夜色温柔，早点休息' };
    return nightCondition;
  }

  private generateAdvice(condition: WeatherCondition, current: CurrentWeather): AdviceItem[] {
    const rows: AdviceItem[] = [
      {
        id: 'advice_weather',
        icon: '🌤',
        tone: '亲和',
        content: condition.emotion
      },
      {
        id: 'advice_uv',
        icon: '🧴',
        tone: '体贴',
        content: current.uvIndex > 6 ? '紫外线强，记得防晒' : '紫外线温和，放心出行'
      },
      {
        id: 'advice_aqi',
        icon: '😷',
        tone: '提醒',
        content: current.aqi > 100 ? '空气一般，出门可备口罩' : '空气质量不错，尽情呼吸'
      }
    ];
    return rows;
  }
}
