export class FormatHelper {
  static formatTemperature(value: number): string {
    return `${Math.round(value)}°`;
  }

  static formatWind(speedKph: number, direction: string): string {
    return `${speedKph.toFixed(0)} km/h ${direction}`;
  }

  static formatAqi(aqi: number): string {
    if (aqi <= 50) {
      return `优 (${aqi})`;
    }
    if (aqi <= 100) {
      return `良 (${aqi})`;
    }
    if (aqi <= 150) {
      return `轻度 (${aqi})`;
    }
    return `较差 (${aqi})`;
  }

  static formatHumidity(value: number): string {
    return `${value.toFixed(0)}%`;
  }

  static formatUpdatedTime(isoString: string): string {
    const date: Date = new Date(isoString);
    const hours: string = date.getHours().toString().padStart(2, '0');
    const minutes: string = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
}
