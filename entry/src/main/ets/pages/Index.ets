import { WeatherHomePage } from './home/WeatherHomePage';

@Entry
@Component
struct Index {
  build() {
    Stack() {
      WeatherHomePage();
    }
    .width('100%')
    .height('100%');
  }
}
