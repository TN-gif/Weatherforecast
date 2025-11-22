import { City } from '../../data/models/WeatherModels';
import { CityRepository } from '../../data/repository/CityRepository';
import { CityManagementTester, TestSuite, TestResult } from '../../common/utils/CityManagementTester';
import { AppContextHolder } from '../../common/di/AppContextHolder';

@Component
export struct DatabaseInspector {
  @State private showInspector: boolean = false;
  @State private cities: City[] = [];
  @State private isLoading: boolean = false;
  @State private testResults: TestSuite[] = [];
  @State private isRunningTests: boolean = false;
  @State private selectedTab: number = 0;

  private cityRepository: CityRepository = CityRepository.getInstance();
  private tester: CityManagementTester = CityManagementTester.getInstance();

  aboutToAppear(): void {
    // 在开发模式下显示数据库检查器
    const isDevelopment = AppStorage.get<boolean>('isDevelopment') || false;
    this.showInspector = isDevelopment;
    
    if (this.showInspector) {
      this.loadCities();
    }
  }

  build() {
    Stack() {
      if (this.showInspector) {
      Column() {
        this.renderHeader();
        this.renderTabs();
        
        if (this.selectedTab === 0) {
          this.renderCityList();
        } else {
          this.renderTestResults();
        }
      }
      .width(350)
      .height(500)
      .padding(16)
      .backgroundColor('rgba(0, 0, 0, 0.9)')
      .borderRadius(12)
      .margin({ top: 50, left: 16 });
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .position({ x: 0, y: 0 });
  }

  @Builder
  private renderHeader(): void {
    Row() {
      Text('数据库检查器')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White);
      
      Blank();
      
      Button('刷新')
        .onClick(() => {
          this.loadCities();
        })
        .fontSize(12)
        .height(28)
        .backgroundColor('rgba(0, 122, 255, 0.8)');
      
      Button('×')
        .onClick(() => {
          this.showInspector = false;
        })
        .fontSize(16)
        .width(28)
        .height(28)
        .backgroundColor('rgba(255, 0, 0, 0.6)')
        .margin({ left: 8 });
    }
    .width('100%')
    .margin({ bottom: 16 });
  }

  @Builder
  private renderTabs(): void {
    Row() {
      Button('城市数据')
        .onClick(() => {
          this.selectedTab = 0;
        })
        .fontSize(14)
        .fontColor(this.selectedTab === 0 ? Color.White : 'rgba(255,255,255,0.6)')
        .backgroundColor(this.selectedTab === 0 ? 'rgba(0, 122, 255, 0.8)' : 'transparent')
        .layoutWeight(1)
        .height(36);
      
      Button('功能测试')
        .onClick(() => {
          this.selectedTab = 1;
        })
        .fontSize(14)
        .fontColor(this.selectedTab === 1 ? Color.White : 'rgba(255,255,255,0.6)')
        .backgroundColor(this.selectedTab === 1 ? 'rgba(0, 122, 255, 0.8)' : 'transparent')
        .layoutWeight(1)
        .height(36);
    }
    .width('100%')
    .margin({ bottom: 16 });
  }

  @Builder
  private renderCityList(): void {
    Column() {
      Row() {
        Text(`城市总数: ${this.cities.length}`)
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.8)');
        
        Blank();
        
        if (this.isLoading) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color(Color.White);
        }
      }
      .width('100%')
      .margin({ bottom: 12 });

      if (this.cities.length === 0) {
        Text('暂无城市数据')
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.6)')
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(100);
      } else {
        List({ space: 8 }) {
          ForEach(this.cities, (city: City, index: number) => {
            ListItem() {
              this.renderCityItem(city, index);
            }
          }, (city: City) => city.id);
        }
        .width('100%')
        .height(300)
        .scrollBar(BarState.Auto);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private renderCityItem(city: City, index: number): void {
    Column() {
      Row() {
        Text(`${index + 1}.`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.6)')
          .width(20);
        
        Column() {
          Text(city.name)
            .fontSize(14)
            .fontColor(Color.White)
            .alignSelf(ItemAlign.Start);
          
          Text(`${city.country} | ${city.source === 0 ? '自动' : '手动'}`)
            .fontSize(11)
            .fontColor('rgba(255,255,255,0.6)')
            .alignSelf(ItemAlign.Start)
            .margin({ top: 2 });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
        
        Text(`${city.coordinates.latitude.toFixed(2)}, ${city.coordinates.longitude.toFixed(2)}`)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.5)');
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);
    }
    .width('100%')
    .padding(8)
    .backgroundColor('rgba(255,255,255,0.1)')
    .borderRadius(6);
  }

  @Builder
  private renderTestResults(): void {
    Column() {
      Row() {
        Text('功能测试')
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.8)');
        
        Blank();
        
        Button(this.isRunningTests ? '测试中...' : '运行测试')
          .onClick(() => {
            this.runTests();
          })
          .enabled(!this.isRunningTests)
          .fontSize(12)
          .height(28)
          .backgroundColor('rgba(0, 200, 0, 0.8)');
      }
      .width('100%')
      .margin({ bottom: 12 });

      if (this.isRunningTests) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(Color.White)
            .margin({ bottom: 8 });
          
          Text('正在执行测试...')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)');
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center);
      } else if (this.testResults.length === 0) {
        Text('点击"运行测试"开始功能验证')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.6)')
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(200);
      } else {
        this.renderTestSuites();
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private renderTestSuites(): void {
    List({ space: 8 }) {
      ForEach(this.testResults, (suite: TestSuite) => {
        ListItem() {
          this.renderTestSuite(suite);
        }
      }, (suite: TestSuite) => suite.suiteName);
    }
    .width('100%')
    .height(300)
    .scrollBar(BarState.Auto);
  }

  @Builder
  private renderTestSuite(suite: TestSuite): void {
    Column() {
      // 测试套件标题
      Row() {
        Text(suite.suiteName)
          .fontSize(13)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium);
        
        Blank();
        
        Text(`${suite.passedTests}/${suite.totalTests}`)
          .fontSize(11)
          .fontColor(suite.failedTests === 0 ? '#4CAF50' : '#FF5722');
      }
      .width('100%')
      .margin({ bottom: 6 });

      // 进度条
      Row() {
        Row()
          .width(`${(suite.passedTests / suite.totalTests) * 100}%`)
          .height(4)
          .backgroundColor('#4CAF50');
      }
      .width('100%')
      .height(4)
      .backgroundColor('rgba(255,255,255,0.2)')
      .borderRadius(2)
      .margin({ bottom: 8 });

      // 失败的测试
      if (suite.failedTests > 0) {
        Column() {
          ForEach(suite.results.filter(r => !r.passed), (result: TestResult) => {
            Text(`❌ ${result.testName}: ${result.message}`)
              .fontSize(10)
              .fontColor('#FF5722')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ bottom: 2 });
          }, (result: TestResult) => result.testName);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }

      // 耗时信息
      Text(`耗时: ${suite.totalDuration}ms`)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.5)')
        .alignSelf(ItemAlign.End);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('rgba(255,255,255,0.1)')
    .borderRadius(8);
  }

  private async loadCities(): Promise<void> {
    try {
      this.isLoading = true;
      const context = AppContextHolder.getContext();
      
      if (context) {
        await this.cityRepository.init(context);
      }
      
      this.cities = await this.cityRepository.getAllCities();
    } catch (error) {
      console.error('[DatabaseInspector] Failed to load cities:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private async runTests(): Promise<void> {
    try {
      this.isRunningTests = true;
      this.testResults = [];
      
      const context = AppContextHolder.getContext();
      if (context) {
        await this.tester.init(context);
        this.testResults = await this.tester.runFullTestSuite();
      }
    } catch (error) {
      console.error('[DatabaseInspector] Failed to run tests:', error);
    } finally {
      this.isRunningTests = false;
    }
  }
}
