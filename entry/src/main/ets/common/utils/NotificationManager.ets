import notificationManager from '@ohos.notificationManager';
import { WeatherSnapshot } from '../models/WeatherModels';

export class NotificationManager {
  private static instance: NotificationManager | null = null;

  private constructor() {}

  static getInstance(): NotificationManager {
    if (NotificationManager.instance === null) {
      NotificationManager.instance = new NotificationManager();
    }
    return NotificationManager.instance;
  }

  async checkAndSendAlert(snapshot: WeatherSnapshot): Promise<void> {
    if (!snapshot || !snapshot.daily || snapshot.daily.length === 0) {
      return;
    }

    const today = snapshot.daily[0];
    const condition = today.condition.text;
    
    // Simple logic: Alert if rain or snow
    if (condition.includes('雨') || condition.includes('雪') || condition.includes('Rain') || condition.includes('Snow')) {
      await this.sendNotification(
        'Weather Alert',
        `Forecast for today: ${condition}. Don't forget your umbrella!`,
        1001
      );
    }
    
    // Alert if temperature drop (mock logic for now)
    if (today.minTempC < 5) {
       await this.sendNotification(
        'Temperature Drop',
        `It's getting cold (${today.minTempC}°C). Dress warmly!`,
        1002
      );
    }
  }

  private async sendNotification(title: string, text: string, id: number): Promise<void> {
    try {
      const request: notificationManager.NotificationRequest = {
        id: id,
        content: {
          contentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: text,
            additionalText: 'Aurora Weather'
          }
        },
        deliveryTime: new Date().getTime()
      };
      
      await notificationManager.publish(request);
      console.info(`[NotificationManager] Notification sent: ${title}`);
    } catch (error) {
      console.error(`[NotificationManager] Failed to send notification: ${error}`);
    }
  }
}
