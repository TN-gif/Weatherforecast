import router from '@ohos.router';
import { City, CitySource } from '../../data/models/WeatherModels';
import { CityRepository } from '../../data/repository/CityRepository';
import { CitySearchBar, SearchBarCallbacks } from '../../components/search/CitySearchBar';
import { CitySearchService, CitySearchResult } from '../../data/services/CitySearchService';
import { ErrorToast, ErrorMessage, ErrorHandler } from '../../components/common/ErrorToast';
import { AppContextHolder } from '../../common/di/AppContextHolder';
import { DesignSystem } from '../../common/theme/DesignSystem';

@Entry
@Component
struct CityManagementPage {
  @State private cities: City[] = [];
  @State private isLoading: boolean = true;
  @State private isSearchMode: boolean = false;
  @State private currentError: ErrorMessage | null = null;
  @State private isAddingCity: boolean = false;

  private cityRepository: CityRepository = CityRepository.getInstance();
  private searchService: CitySearchService = CitySearchService.getInstance();

  aboutToAppear(): void {
    console.info('[CityManagementPage] Page appearing');
    this.loadCities();
  }

  build() {
    Stack() {
      // 共享背景（移除sharedTransition，因为新API不再支持通过router params传递）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F7') // Apple风格的浅灰色
      
      Column() {
        // Header
        this.buildHeader();

        // Search Section
        if (this.isSearchMode) {
          this.buildSearchSection();
        }

        // City List
        if (this.isLoading) {
          this.buildLoading();
        } else {
          this.buildCityList();
        }
      }
      .width('100%')
      .height('100%')

      // Error Toast
      ErrorToast({ errorMessage: $currentError });
    }
  }

  @Builder
  private buildHeader(): void {
    Row() {
      Button() {
        Path()
          .commands(DesignSystem.Icons.BACK)
          .fill(DesignSystem.Colors.BLACK)
          .width(24)
          .height(24)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back();
      });

      Text('City Management')
        .fontSize(18)
        .fontWeight(DesignSystem.FontWeight.MEDIUM)
        .fontColor(DesignSystem.Colors.BLACK)
        .layoutWeight(1)
        .textAlign(TextAlign.Center);

      // Search/Add Button
      Button() {
        Path()
          .commands(this.isSearchMode ? DesignSystem.Icons.PLUS : DesignSystem.Icons.PLUS) // Reuse PLUS for now, maybe rotate for close?
          .fill(DesignSystem.Colors.BLACK) // Blue for action
          .width(24)
          .height(24)
          .rotate({ angle: this.isSearchMode ? 45 : 0 }) // Rotate to X if searching
          .animation({ duration: 300 })
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.toggleSearchMode();
      });
    }
    .width('100%')
    .height(56)
    .padding({ left: DesignSystem.Spacing.M, right: DesignSystem.Spacing.M })
    .backgroundColor(DesignSystem.Colors.WHITE_90)
    .backdropBlur(20)
  }

  @Builder
  private buildSearchSection(): void {
    Column() {
      CitySearchBar({
        callbacks: {
          onSearch: (keyword: string) => {
            console.info(`[CityManagementPage] Searching for: ${keyword}`);
          },
          onResultSelect: (result: CitySearchResult) => {
            this.addCity(result);
          },
          onClear: () => {
            console.info('[CityManagementPage] Search cleared');
          }
        } as SearchBarCallbacks
      });

      this.buildPopularCities();
    }
    .width('100%')
    .padding(DesignSystem.Spacing.M)
    .backgroundColor(DesignSystem.Colors.WHITE)
    .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: -20 } })
    .transition({ type: TransitionType.Delete, opacity: 0, translate: { y: -20 } })
  }

  @Builder
  private buildPopularCities(): void {
    Column() {
      Text('Popular Cities')
        .fontSize(14)
        .fontWeight(DesignSystem.FontWeight.REGULAR)
        .fontColor(DesignSystem.Colors.BLACK_50)
        .margin({ top: DesignSystem.Spacing.L, bottom: DesignSystem.Spacing.S })
        .alignSelf(ItemAlign.Start);

      Grid() {
        ForEach(this.searchService.getPopularCities(), (city: CitySearchResult) => {
          GridItem() {
            Text(city.name)
              .fontSize(14)
              .fontColor(DesignSystem.Colors.BLACK)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .backgroundColor('#F0F0F5')
              .borderRadius(8)
              .onClick(() => {
                this.addCity(city);
              });
          }
        }, (city: CitySearchResult) => city.id)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private buildLoading(): void {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(DesignSystem.Colors.BLACK_50)
        .margin({ bottom: 16 });
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildCityList(): void {
    List({ space: DesignSystem.Spacing.S }) {
      ForEach(this.cities, (city: City, index: number) => {
        ListItem() {
          this.buildCityItem(city, index);
        }
        .swipeAction({ 
          end: this.buildDeleteButton(city, index) 
        });
      }, (city: City) => city.id)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: DesignSystem.Spacing.M, right: DesignSystem.Spacing.M, top: DesignSystem.Spacing.M })
  }

  @Builder
  private buildCityItem(city: City, index: number): void {
    Row() {
      Column() {
        Text(city.name)
          .fontSize(20)
          .fontColor(DesignSystem.Colors.WHITE)
          .fontWeight(DesignSystem.FontWeight.MEDIUM);

        Row() {
          if (city.source === CitySource.AUTO) {
            Path()
              .commands(DesignSystem.Icons.LOCATION)
              .fill(DesignSystem.Colors.WHITE)
              .width(12)
              .height(12)
              .margin({ right: 4 })
            Text('Current Location')
              .fontSize(12)
              .fontColor(DesignSystem.Colors.WHITE);
          } else {
             Text(city.country)
              .fontSize(12)
              .fontColor(DesignSystem.Colors.WHITE_70);
          }
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // Weather Icon (Placeholder for now, ideally dynamic)
      Path()
        .commands(DesignSystem.Icons.SUN) // Dynamic based on weather?
        .fill(DesignSystem.Colors.WHITE)
        .width(32)
        .height(32)
    }
    .width('100%')
    .height(100)
    .padding(DesignSystem.Spacing.L)
    .borderRadius(16)
    // Dynamic background based on weather/time? For now, simple gradient
    .linearGradient({
      angle: 135,
      colors: index === 0 ? 
        [['#59ADC4', 0.0], ['#2878AC', 1.0]] : // Blue for current
        [['#48484A', 0.0], ['#2C2C2E', 1.0]]   // Dark Gray for others
    })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 4 })
  }

  @Builder
  private buildDeleteButton(city: City, index: number): void {
    Button() {
      Column() {
        Path()
          .commands(DesignSystem.Icons.PLUS) // Rotate to X
          .fill(DesignSystem.Colors.WHITE)
          .width(24)
          .height(24)
          .rotate({ angle: 45 })
      }
    }
    .width(80)
    .height(100) // Match item height
    .backgroundColor(DesignSystem.Colors.ERROR)
    .borderRadius(16)
    .margin({ left: 8 })
    .onClick(() => {
      this.deleteCity(city, index);
    });
  }

  // ... existing methods (loadCities, addCity, deleteCity, toggleSearchMode) ...
  private async loadCities(): Promise<void> {
    try {
      console.info('[CityManagementPage] Loading cities...');
      this.isLoading = true;

      const context = AppContextHolder.getContext();
      if (context) {
        await this.cityRepository.init(context);
      }

      this.cities = await this.cityRepository.getAllCities();
      this.searchService.setExistingCities(this.cities.map(city => city.id));
    } catch (error) {
      console.error('[CityManagementPage] Failed to load cities:', error);
      this.currentError = ErrorHandler.handle(error as Error, 'Failed to load cities');
    } finally {
      this.isLoading = false;
    }
  }

  private async addCity(searchResult: CitySearchResult): Promise<void> {
    if (this.isAddingCity) return;
    try {
      this.isAddingCity = true;
      const city = this.searchService.convertToCity(searchResult);
      await this.cityRepository.addCity(city);
      await this.loadCities();
      this.isSearchMode = false;
      this.currentError = ErrorHandler.createInfoMessage(`Added ${city.name}`);
    } catch (error) {
      this.currentError = ErrorHandler.handle(error as Error, 'Failed to add city');
    } finally {
      this.isAddingCity = false;
    }
  }

  private async deleteCity(city: City, index: number): Promise<void> {
    if (index === 0) {
      this.currentError = ErrorHandler.createWarningMessage('Cannot delete default city');
      return;
    }
    try {
      await this.cityRepository.removeCity(city.id);
      await this.loadCities();
      this.currentError = ErrorHandler.createInfoMessage(`Deleted ${city.name}`);
    } catch (error) {
      this.currentError = ErrorHandler.handle(error as Error, 'Failed to delete city');
    }
  }

  private toggleSearchMode(): void {
    this.isSearchMode = !this.isSearchMode;
  }
}
