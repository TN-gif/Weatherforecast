import { WeatherHomePage } from './home/WeatherHomePage';

@Entry
@Component
struct Index {
  @State private refreshTrigger: number = 0;
  @State private forceGpsCityIndex: number = -1;

  onPageShow(): void {
    console.info('[Index] ========== 页面显示 (onPageShow) ==========');
    
    // 检查AppStorage中的刷新信号
    const needRefresh = AppStorage.get<boolean>('needRefreshWeather');
    const newCityId = AppStorage.get<string>('newAddedCityId');
    
    // 🔧 检查是否从Widget点击进入，需要强制跳转到GPS城市
    const forceGpsCity = AppStorage.get<boolean>('forceGpsCityNavigation');
    
    console.info(`[Index] 📦 AppStorage刷新信号: needRefresh=${needRefresh}, newCityId=${newCityId}, forceGpsCity=${forceGpsCity}`);
    
    if (forceGpsCity) {
      console.info('[Index] 🎯 检测到Widget跳转信号，强制跳转到GPS城市（索引0）');
      // 清除标志
      AppStorage.setOrCreate('forceGpsCityNavigation', false);
      // 设置跳转到GPS城市（索引0）
      this.forceGpsCityIndex = 0;
      // 触发刷新
      this.refreshTrigger = Date.now();
    } else if (needRefresh) {
      console.info('[Index] 🔄 检测到刷新信号，触发WeatherHomePage刷新');
      // 触发子组件刷新
      this.refreshTrigger = Date.now();
    }
  }

  build() {
    Stack() {
      WeatherHomePage({ 
        refreshTrigger: this.refreshTrigger,
        forceGpsCityIndex: this.forceGpsCityIndex
      });
    }
    .width('100%')
    .height('100%');
  }
}
