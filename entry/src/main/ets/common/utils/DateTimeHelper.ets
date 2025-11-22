export class DateTimeHelper {
  static getLocalTimeString(dateIso: string, offsetMinutes: number): string {
    const date: Date = new Date(dateIso);
    const localMillis: number = date.getTime() + offsetMinutes * 60 * 1000;
    const localDate: Date = new Date(localMillis);
    return `${DateTimeHelper.pad(localDate.getHours())}:${DateTimeHelper.pad(localDate.getMinutes())}`;
  }

  static getDayLabel(dateIso: string): string {
    const date: Date = new Date(dateIso);
    const weekdays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.getDay()];
  }

  static pad(value: number): string {
    if (value < 10) {
      return `0${value}`;
    }
    return value.toString();
  }
}
