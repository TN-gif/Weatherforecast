import http from '@ohos.net.http';
import { Coordinates, WeatherSnapshot, WeatherApiConfig, WeatherCondition, CurrentWeather, HourlyForecast, DailyForecast, AdviceItem, RainForecast, WeatherAlert } from '../models/WeatherModels';
import { DesignSystem } from '../../common/theme/DesignSystem';

// 和风天气API响应接口 - 使用interface而非对象字面量
interface QWeatherNowData {
  temp: string;
  feelsLike: string;
  text: string;
  wind360: string;
  windDir: string;
  windScale: string;
  windSpeed: string;
  humidity: string;
  precip: string;
  pressure: string;
  vis: string;
  cloud: string;
  dew: string;
}

interface QWeatherNow {
  code: string;
  now: QWeatherNowData;
}

interface QWeatherHourlyItem {
  fxTime: string;
  temp: string;
  pop: string;
  text: string;
  wind360: string;
  windDir: string;
  windSpeed: string;
}

interface QWeatherHourly {
  code: string;
  hourly: QWeatherHourlyItem[];
}

interface QWeatherDailyItem {
  fxDate: string;
  tempMax: string;
  tempMin: string;
  textDay: string;
  textNight: string;
  iconDay: string;
  iconNight: string;
  precip: string;
  sunrise: string;  // 日出时间 HH:mm
  sunset: string;   // 日落时间 HH:mm
  uvIndex: string;  // 紫外线指数
  humidity: string; // 湿度
  pressure: string; // 气压
  vis: string;      // 能见度
}

interface QWeatherDaily {
  code: string;
  daily: QWeatherDailyItem[];
}

interface QWeatherWarningItem {
  id: string;
  sender: string;
  pubTime: string;
  title: string;
  startTime: string;
  endTime: string;
  status: string;
  level: string;
  type: string;
  typeName: string;
  text: string;
  related: string;
}

interface QWeatherWarning {
  code: string;
  warning: QWeatherWarningItem[];
}

interface QWeatherMinutelyItem {
  fxTime: string;
  precip: string;
  type: string;
}

// 天气指数响应接口
interface QWeatherIndicesDaily {
  date: string;
  type: string;  // '5' 表示紫外线指数
  name: string;
  level: string; // 1-5 级别
  category: string;
  text: string;
}

interface QWeatherIndices {
  code: string;
  daily: QWeatherIndicesDaily[];
}

interface QWeatherMinutely {
  code: string;
  summary: string;
  minutely: QWeatherMinutelyItem[];
}

// 空气质量首要污染物
interface QWeatherPrimaryPollutant {
  code: string;
  name: string;
  fullName: string;
}

// 空气质量AQI指数
interface QWeatherAirIndex {
  code: string;  // 指数类型：us-epa, qaqi等
  name: string;
  aqi: number;   // AQI值
  aqiDisplay: string;
  level: string;
  category: string;
  primaryPollutant?: QWeatherPrimaryPollutant;
}

// 污染物浓度
interface QWeatherConcentration {
  value: number;
  unit: string;
}

// 空气质量污染物
interface QWeatherPollutant {
  code: string;
  name: string;
  fullName: string;
  concentration: QWeatherConcentration;
}

// 空气质量元数据
interface QWeatherAirMetadata {
  tag: string;
}

// 监测站信息
interface QWeatherStation {
  id: string;
  name: string;
}

// 空气质量返回数据
interface QWeatherAir {
  metadata?: QWeatherAirMetadata;
  indexes: QWeatherAirIndex[];  // 多个AQI指数
  pollutants?: QWeatherPollutant[]; // 污染物浓度
  stations?: QWeatherStation[];
}

export class QWeatherService {
  private readonly config: WeatherApiConfig;
  private readonly timeoutMs: number = 15000;

  constructor(config: WeatherApiConfig) {
    this.config = config;
  }

  async fetchWeather(cityId: string, coordinates: Coordinates, timezoneOffsetMinutes?: number): Promise<WeatherSnapshot> {
    console.info(`[QWeatherService] ========== 开始获取和风天气数据 ==========`);
    console.info(`[QWeatherService] 🏙️ 城市ID: ${cityId}`);
    console.info(`[QWeatherService] 📍 坐标: ${coordinates.latitude.toFixed(4)},${coordinates.longitude.toFixed(4)}`);
    if (timezoneOffsetMinutes !== undefined) {
      console.info(`[QWeatherService] 🕒 时区偏移: ${timezoneOffsetMinutes}分钟 (UTC${timezoneOffsetMinutes >= 0 ? '+' : ''}${timezoneOffsetMinutes / 60})`);
    }
    const startTime = Date.now();

    try {
      const location = `${coordinates.longitude},${coordinates.latitude}`;
      console.info(`[QWeatherService] 🚀 发起7个并发请求 (Now, Hourly, Daily, Warning, Minutely, Air, Indices)...`);
      
      const allResults = await Promise.all([
        this.fetchNow(location),
        this.fetchHourly(location),
        this.fetchDaily(location),
        this.fetchWarning(location),
        this.fetchMinutely(location),
        this.fetchAir(location),
        this.fetchIndices(location)
      ]);

      console.info(`[QWeatherService] ✅ 所有并发请求完成，耗时: ${Date.now() - startTime}ms`);

      const nowData = allResults[0];
      const hourlyData = allResults[1];
      const dailyData = allResults[2];
      const warningData = allResults[3];
      const minutelyData = allResults[4];
      const airData = allResults[5];
      const indicesData = allResults[6];

      // 调试：检查返回数据结构
      console.debug(`[QWeatherService] 📊 数据结构检查:`);
      console.debug(`  - nowData: ${nowData ? 'OK' : 'NULL'}, has now: ${nowData && nowData.now ? 'YES' : 'NO'}`);
      console.debug(`  - hourlyData: ${hourlyData ? 'OK' : 'NULL'}, has hourly: ${hourlyData && hourlyData.hourly ? 'YES' : 'NO'}`);
      console.debug(`  - dailyData: ${dailyData ? 'OK' : 'NULL'}, has daily: ${dailyData && dailyData.daily ? 'YES' : 'NO'}`);
      console.debug(`  - warningData: ${warningData ? 'OK' : 'NULL'}`);
      console.debug(`  - minutelyData: ${minutelyData ? 'OK' : 'NULL'}`);
      console.debug(`  - airData: ${airData ? 'OK' : 'NULL'}, has indexes: ${airData && airData.indexes ? 'YES (' + airData.indexes.length + ')' : 'NO'}`);
      console.debug(`  - indicesData: ${indicesData ? 'OK' : 'NULL'}, has daily: ${indicesData && indicesData.daily ? 'YES (' + indicesData.daily.length + ')' : 'NO'}`);

      console.debug(`[QWeatherService] 开始映射数据模型...`);
      const snapshot = this.mapToSnapshot(cityId, nowData, hourlyData, dailyData, warningData, minutelyData, airData, indicesData, timezoneOffsetMinutes);
      console.info(`[QWeatherService] ========== 和风天气数据获取成功 ==========`);
      return snapshot;
    } catch (error) {
      console.error(`[QWeatherService] ❌ 获取失败 (${Date.now() - startTime}ms): ${(error as Error).message}`);
      throw new Error(`QWeatherService failed: ${(error as Error).message}`);
    }
  }

  private async fetchNow(location: string): Promise<QWeatherNow> {
    const url = `${this.config.baseUrl}/v7/weather/now?location=${location}&key=${this.config.apiKey}`;
    return await this.request<QWeatherNow>(url, 'weather/now');
  }

  private async fetchHourly(location: string): Promise<QWeatherHourly> {
    const url = `${this.config.baseUrl}/v7/weather/24h?location=${location}&key=${this.config.apiKey}`;
    return await this.request<QWeatherHourly>(url, 'weather/24h');
  }

  private async fetchDaily(location: string): Promise<QWeatherDaily> {
    const url = `${this.config.baseUrl}/v7/weather/7d?location=${location}&key=${this.config.apiKey}`;
    return await this.request<QWeatherDaily>(url, 'weather/7d');
  }

  private async fetchWarning(location: string): Promise<QWeatherWarning> {
    // 解析经纬度：location格式为 "经度,纬度"
    const coords = location.split(',');
    const longitude = coords[0];
    const latitude = coords[1];
    // 官方文档：/weatheralert/v1/current/{latitude}/{longitude}
    const url = `${this.config.baseUrl}/weatheralert/v1/current/${latitude}/${longitude}?key=${this.config.apiKey}`;
    return await this.request<QWeatherWarning>(url, 'warning/now');
  }

  private async fetchMinutely(location: string): Promise<QWeatherMinutely> {
    const url = `${this.config.baseUrl}/v7/minutely/5m?location=${location}&key=${this.config.apiKey}`;
    return await this.request<QWeatherMinutely>(url, 'minutely/5m');
  }

  private async fetchIndices(location: string): Promise<QWeatherIndices> {
    // type=5 表示紫外线指数
    const url = `${this.config.baseUrl}/v7/indices/1d?location=${location}&type=5&key=${this.config.apiKey}`;
    return await this.request<QWeatherIndices>(url, 'indices/1d');
  }

  private async fetchAir(location: string): Promise<QWeatherAir> {
    // 解析经纬度：location格式为 "经度,纬度"
    const coords = location.split(',');
    const longitude = coords[0];
    const latitude = coords[1];
    // 官方文档：/airquality/v1/current/{latitude}/{longitude}
    const url = `${this.config.baseUrl}/airquality/v1/current/${latitude}/${longitude}?key=${this.config.apiKey}`;
    return await this.request<QWeatherAir>(url, 'air/now');
  }

  private async request<T>(url: string, endpoint: string): Promise<T> {
    const httpRequest = http.createHttp();
    const startTime = Date.now();
    try {
      console.debug(`[QWeatherService] 📤 请求 ${endpoint}...`);
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: this.timeoutMs,
        readTimeout: this.timeoutMs
      });

      if (response.responseCode !== 200) {
        console.error(`[QWeatherService] ❌ ${endpoint} HTTP错误: ${response.responseCode}`);
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }

      const data = JSON.parse(response.result as string) as T;
      console.debug(`[QWeatherService] ✅ ${endpoint} 成功 (${Date.now() - startTime}ms)`);
      return data;
    } catch (error) {
      console.error(`[QWeatherService] ❌ ${endpoint} 失败 (${Date.now() - startTime}ms): ${(error as Error).message}`);
      throw new Error(`${endpoint} request failed: ${(error as Error).message}`);
    } finally {
      httpRequest.destroy();
    }
  }

  private mapToSnapshot(
    cityId: string,
    nowData: QWeatherNow,
    hourlyData: QWeatherHourly,
    dailyData: QWeatherDaily,
    warningData: QWeatherWarning,
    minutelyData: QWeatherMinutely,
    airData: QWeatherAir,
    indicesData: QWeatherIndices,
    timezoneOffsetMinutes?: number
  ): WeatherSnapshot {
    const condition = this.mapWeatherText(nowData.now.text);
    
    // 安全获取空气质量数据，处理API返回格式
    let aqiValue = 0;
    try {
      if (airData && airData.indexes && airData.indexes.length > 0) {
        // 优先使用us-epa标准的AQI
        const usEpaIndex = airData.indexes.find(index => index.code === 'us-epa');
        if (usEpaIndex) {
          aqiValue = Math.round(usEpaIndex.aqi);
        } else {
          // 如果没有us-epa，使用第一个可用的AQI
          aqiValue = Math.round(airData.indexes[0].aqi);
        }
        console.debug(`[QWeatherService] 📊 提取AQI值: ${aqiValue} (来源: ${usEpaIndex ? 'us-epa' : airData.indexes[0].code})`);
      }
    } catch (error) {
      console.warn(`[QWeatherService] ⚠️ 空气质量数据解析失败，使用默认值: ${error}`);
    }
    
    // 安全获取紫外线指数数据
    let uvIndex = 0;
    try {
      if (indicesData && indicesData.code === '200' && indicesData.daily && indicesData.daily.length > 0) {
        const uvData = indicesData.daily.find(item => item.type === '5');
        if (uvData) {
          uvIndex = parseInt(uvData.level); // 级别 1-5
          console.info(`[QWeatherService] ✅ 紫外线指数获取成功: ${uvIndex} (${uvData.category}) - ${uvData.text}`);
        } else {
          console.warn(`[QWeatherService] ⚠️ 指数数据中未找到type='5'的紫外线数据`);
        }
      } else {
        console.warn(`[QWeatherService] ⚠️ 指数数据无效: code=${indicesData?.code}, daily存在=${!!indicesData?.daily}, daily长度=${indicesData?.daily?.length}`);
      }
    } catch (error) {
      console.warn(`[QWeatherService] ⚠️ 紫外线指数数据解析失败，使用默认值: ${error}`);
    }
    
    // ✅ 从每日预报数据中提取日出日落时间（第一天）
    let sunrise = '06:00';
    let sunset = '18:00';
    if (dailyData && dailyData.daily && dailyData.daily.length > 0) {
      const todayData = dailyData.daily[0];
      console.info(`[QWeatherService] 📅 今日预报数据: sunrise=${todayData.sunrise}, sunset=${todayData.sunset}`);
      if (todayData.sunrise) sunrise = todayData.sunrise;
      if (todayData.sunset) sunset = todayData.sunset;
      console.info(`[QWeatherService] ✅ 日出日落获取成功: 🌅${sunrise} / 🌛${sunset}`);
    } else {
      console.warn(`[QWeatherService] ⚠️ 每日预报数据无效，使用默认值`);
    }
    
    const current: CurrentWeather = {
      temperatureC: parseFloat(nowData.now.temp),
      feelsLikeC: parseFloat(nowData.now.feelsLike),
      humidity: parseInt(nowData.now.humidity),
      windSpeedKph: parseFloat(nowData.now.windSpeed),
      windDirection: nowData.now.windDir,
      pressureHpa: parseInt(nowData.now.pressure),
      visibilityKm: parseInt(nowData.now.vis),
      uvIndex: uvIndex,  // ✅ 使用真实紫外线指数数据
      aqi: aqiValue,
      sunrise: sunrise,  // ✅ 使用每日预报中的真实日出时间
      sunset: sunset,    // ✅ 使用每日预报中的真实日落时间
      condition: condition
    };

    const hourly: HourlyForecast[] = hourlyData.hourly.slice(0, this.config.hourlyCount).map((h: QWeatherHourlyItem): HourlyForecast => {
      const hourlyItem: HourlyForecast = {
        time: h.fxTime,
        temperatureC: parseFloat(h.temp),
        precipitationProbability: parseInt(h.pop),
        iconCode: this.mapWeatherText(h.text).iconCode,
        description: h.text
      };
      return hourlyItem;
    });

    const daily: DailyForecast[] = dailyData.daily.slice(0, this.config.dailyCount).map((d: QWeatherDailyItem): DailyForecast => {
      // ⚠️ 和风天气每日预报API不包含pop（降水概率）字段
      // 只有precip（降水量）字段，根据降水量估算概率
      const precipVal = parseFloat(d.precip);
      let precipProbability = 0;
      if (precipVal > 10) { // 大雨
        precipProbability = 90;
      } else if (precipVal > 5) { // 中雨
        precipProbability = 70;
      } else if (precipVal > 0.1) { // 小雨
        precipProbability = 50;
      } else { // 无降水
        precipProbability = 10;
      }
      
      const dailyItem: DailyForecast = {
        date: d.fxDate,
        minTempC: parseFloat(d.tempMin),
        maxTempC: parseFloat(d.tempMax),
        iconCode: this.mapWeatherText(d.textDay).iconCode,
        description: d.textDay,
        precipitationProbability: precipProbability  // ✅ 根据降水量估算
      };
      return dailyItem;
    });

    const alerts = this.mapWarnings(warningData);
    const rainForecast = this.mapMinutely(minutelyData);
    const advice = this.generateAdvice(condition, current);

    // 🔧 修复：使用传入的实际时区偏移量，如果未提供则使用UTC+8作为默认值
    const actualTimezoneOffset = timezoneOffsetMinutes !== undefined ? timezoneOffsetMinutes : 480;
    console.info(`[QWeatherService] 🕒 使用时区偏移: ${actualTimezoneOffset}分钟 (UTC${actualTimezoneOffset >= 0 ? '+' : ''}${actualTimezoneOffset / 60})`);
    
    const snapshot: WeatherSnapshot = {
      cityId: cityId,
      lastUpdatedIso: new Date().toISOString(),
      timezoneOffsetMinutes: actualTimezoneOffset,
      current: current,
      hourly: hourly,
      daily: daily,
      advice: advice,
      alerts: alerts,
      rainForecast: rainForecast,
      dataSource: 'qweather'
    };
    return snapshot;
  }

  private mapWeatherText(text: string): WeatherCondition {
    if (text.includes('晴')) {
      const condition: WeatherCondition = { 
        description: text, 
        iconCode: 'sunny', 
        themeKey: 'sunny', 
        emotion: '阳光明媚，适合出行' 
      };
      return condition;
    }
    if (text.includes('云') || text.includes('阴')) {
      const condition: WeatherCondition = { 
        description: text, 
        iconCode: 'cloudy', 
        themeKey: 'sunny', 
        emotion: '多云天气，记得补水' 
      };
      return condition;
    }
    if (text.includes('雨')) {
      const condition: WeatherCondition = { 
        description: text, 
        iconCode: 'rainy', 
        themeKey: 'rainy', 
        emotion: '雨天路滑，注意安全' 
      };
      return condition;
    }
    if (text.includes('雪')) {
      const condition: WeatherCondition = { 
        description: text, 
        iconCode: 'snow', 
        themeKey: 'snow', 
        emotion: '雪天注意保暖' 
      };
      return condition;
    }
    if (text.includes('雷')) {
      const condition: WeatherCondition = { 
        description: text, 
        iconCode: 'storm', 
        themeKey: 'rainy', 
        emotion: '雷雨天气，减少外出' 
      };
      return condition;
    }
    const condition: WeatherCondition = { 
      description: text, 
      iconCode: 'sunny', 
      themeKey: 'sunny', 
      emotion: '天气不错' 
    };
    return condition;
  }

  private mapWarnings(warningData: QWeatherWarning): WeatherAlert[] {
    if (warningData.code !== '200' || !warningData.warning || warningData.warning.length === 0) {
      return [];
    }

    return warningData.warning.map((w: QWeatherWarningItem): WeatherAlert => {
      const severity = this.mapWarningLevel(w.level);
      const alert: WeatherAlert = {
        id: w.id,
        severity: severity,
        title: w.typeName,
        description: w.text,
        startTime: w.startTime,
        endTime: w.endTime,
        iconResource: DesignSystem.IconResources.RAIN
      };
      return alert;
    });
  }

  private mapWarningLevel(level: string): 'warning' | 'watch' | 'advisory' {
    if (level.includes('红') || level.includes('Red')) return 'warning';
    if (level.includes('橙') || level.includes('Orange')) return 'warning';
    if (level.includes('黄') || level.includes('Yellow')) return 'watch';
    return 'advisory';
  }

  private mapMinutely(minutelyData: QWeatherMinutely): RainForecast[] {
    if (minutelyData.code !== '200' || !minutelyData.minutely || minutelyData.minutely.length === 0) {
      return [];
    }

    return minutelyData.minutely.map((item: QWeatherMinutelyItem, index: number): RainForecast => {
      const precip = parseFloat(item.precip);
      const forecast: RainForecast = {
        timeMinutes: index * 5,
        probability: precip > 0 ? 100 : 0,
        intensity: precip < 0.5 ? 'light' : (precip < 2 ? 'moderate' : 'heavy')
      };
      return forecast;
    });
  }

  private generateAdvice(condition: WeatherCondition, current: CurrentWeather): AdviceItem[] {
    const advice: AdviceItem[] = [
      {
        id: 'advice_weather',
        icon: 'weather',
        tone: '天气提示',
        content: condition.emotion,
        priority: 1
      },
      {
        id: 'advice_temp',
        icon: 'sun',
        tone: '温度建议',
        content: current.temperatureC > 30 ? '天气炎热，注意防暑' : current.temperatureC < 10 ? '天气寒冷，注意保暖' : '温度适宜，舒适出行',
        priority: 2
      },
      {
        id: 'advice_aqi',
        icon: 'wind',
        tone: '空气质量',
        content: current.aqi > 100 ? '空气质量一般，减少户外活动' : '空气质量良好，适合户外运动',
        priority: 3
      }
    ];
    return advice;
  }
}
