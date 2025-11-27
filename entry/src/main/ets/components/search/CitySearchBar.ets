import { CitySearchService, CitySearchResult } from '../../data/services/CitySearchService';
import { DesignSystem } from '../../common/theme/DesignSystem';

export interface SearchBarCallbacks {
  onSearch: (keyword: string) => void;
  onResultSelect: (result: CitySearchResult) => void;
  onClear: () => void;
}

@Component
export struct CitySearchBar {
  @State private searchText: string = '';
  @State private isSearching: boolean = false;
  @State private searchResults: CitySearchResult[] = [];
  @State private showResults: boolean = false;
  @State private suggestions: string[] = [];

  private searchService: CitySearchService = CitySearchService.getInstance();
  private searchTimeoutId: number = -1;
  private readonly debounceDelay: number = 300;

  callbacks?: SearchBarCallbacks;

  aboutToAppear(): void {
    this.suggestions = this.searchService.getSearchSuggestions();
  }

  aboutToDisappear(): void {
    if (this.searchTimeoutId !== -1) {
      clearTimeout(this.searchTimeoutId);
    }
  }

  build() {
    Column() {
      // 搜索输入框
      this.buildSearchInput()

      // 搜索结果或建议
      if (this.showResults) {
        this.buildResultsList()
      }
    }
    .width('100%')
  }

  @Builder
  private buildSearchInput(): void {
    Row() {
      Image(DesignSystem.IconResources.SEARCH)
        .width(20)
        .height(20)
        .fillColor(DesignSystem.Colors.WHITE_70)
        .margin({ right: 12 })

      TextInput({
        placeholder: '搜索城市名称...',
        text: this.searchText
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .fontSize(16)
        .fontColor(DesignSystem.Colors.WHITE)
        .placeholderColor(DesignSystem.Colors.WHITE_50)
        .caretColor(DesignSystem.Colors.WHITE)
        .onChange((value: string) => {
          this.searchText = value;
          this.onSearchTextChange(value);
        })
        .onFocus(() => {
          this.showResults = true;
        })
        .onBlur(() => {
          this.hideResultsWithDelay();
        })

      if (this.searchText.length > 0) {
        Button() {
          Image(DesignSystem.IconResources.CLOSE)
            .width(16)
            .height(16)
            .fillColor(DesignSystem.Colors.WHITE_70)
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.clearSearch();
        })
      }

      if (this.isSearching) {
        LoadingProgress()
          .width(20)
          .height(20)
          .color(DesignSystem.Colors.WHITE)
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('rgba(255, 255, 255, 0.12)')
    .borderRadius(24)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private buildResultsList(): void {
    Column() {
      if (this.searchText.length === 0) {
        // 显示搜索建议
        this.buildSuggestions()
      } else if (this.searchResults.length > 0) {
        // 显示搜索结果
        this.buildSearchResults()
      } else if (!this.isSearching && this.searchText.length >= 2) {
        // 无结果提示
        this.buildNoResults()
      }
    }
    .width('100%')
    .margin({ top: 12 })
    .constraintSize({ maxHeight: 300 })
    .backgroundColor('rgba(255, 255, 255, 0.10)')
    .backdropBlur(30)
    .borderRadius(16)
    .border({ width: 1, color: DesignSystem.COLOR_GLASS_BORDER })
  }

  @Builder
  private buildSuggestions(): void {
    Column() {
      Text('搜索建议')
        .fontSize(13)
        .fontColor(DesignSystem.Colors.WHITE_70)
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      List() {
        ForEach(this.suggestions.slice(0, 6), (suggestion: string) => {
          ListItem() {
            Row() {
              Image(DesignSystem.IconResources.SEARCH)
                .width(16)
                .height(16)
                .fillColor(DesignSystem.Colors.WHITE_50)
                .margin({ right: 12 })

              Text(suggestion)
                .fontSize(15)
                .fontColor(DesignSystem.Colors.WHITE)
                .layoutWeight(1)
            }
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.searchText = suggestion;
              this.performSearch(suggestion);
            })
          }
        }, (suggestion: string) => suggestion)
      }
      .divider({
        strokeWidth: 1,
        color: 'rgba(255, 255, 255, 0.08)'
      })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildSearchResults(): void {
    List() {
      ForEach(this.searchResults, (result: CitySearchResult) => {
        ListItem() {
          Row() {
            Column() {
              Text(result.name)
                .fontSize(16)
                .fontColor(DesignSystem.Colors.WHITE)
                .fontWeight(DesignSystem.FontWeight.MEDIUM)
                .alignSelf(ItemAlign.Start)

              Text(this.formatLocation(result))
                .fontSize(13)
                .fontColor(DesignSystem.Colors.WHITE_70)
                .margin({ top: 2 })
                .alignSelf(ItemAlign.Start)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Image(DesignSystem.IconResources.ADD)
              .width(20)
              .height(20)
              .fillColor(DesignSystem.Colors.WHITE)
          }
          .width('100%')
          .height(60)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.selectResult(result);
          })
        }
      }, (result: CitySearchResult) => result.id)
    }
    .divider({
      strokeWidth: 1,
      color: 'rgba(255, 255, 255, 0.08)'
    })
  }

  @Builder
  private buildNoResults(): void {
    Column() {
      Image(DesignSystem.IconResources.SEARCH)
        .width(40)
        .height(40)
        .fillColor(DesignSystem.Colors.WHITE_50)
        .margin({ bottom: 12 })

      Text('未找到相关城市')
        .fontSize(15)
        .fontColor(DesignSystem.Colors.WHITE)
        .margin({ bottom: 4 })

      Text('请尝试其他关键词')
        .fontSize(13)
        .fontColor(DesignSystem.Colors.WHITE_70)
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private onSearchTextChange(value: string): void {
    // 清除之前的定时器
    if (this.searchTimeoutId !== -1) {
      clearTimeout(this.searchTimeoutId);
    }

    if (value.length === 0) {
      this.searchResults = [];
      this.callbacks?.onClear?.();
      return;
    }

    if (value.length < 2) {
      return;
    }

    // 防抖搜索
    this.searchTimeoutId = setTimeout(() => {
      this.performSearch(value);
    }, this.debounceDelay);
  }

  private async performSearch(keyword: string): Promise<void> {
    if (keyword.length < 2) {
      return;
    }

    this.isSearching = true;
    this.callbacks?.onSearch?.(keyword);

    try {
      const results = await this.searchService.searchCities(keyword);
      this.searchResults = results;
      console.info(`[CitySearchBar] Search completed: ${results.length} results`);
    } catch (error) {
      console.error('[CitySearchBar] Search failed:', error);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  private selectResult(result: CitySearchResult): void {
    console.info(`[CitySearchBar] Selected city: ${result.name}, ${result.country}`);
    this.callbacks?.onResultSelect?.(result);
    this.clearSearch();
  }

  private clearSearch(): void {
    this.searchText = '';
    this.searchResults = [];
    this.showResults = false;
    this.callbacks?.onClear?.();
  }

  private formatLocation(result: CitySearchResult): string {
    if (result.state) {
      return `${result.state}, ${result.country}`;
    }
    return result.country;
  }

  // 公共方法
  public focus(): void {
    this.showResults = true;
  }

  public hideResultsWithDelay(): void {
    // 延迟隐藏，允许点击结果
    setTimeout(() => {
      this.showResults = false;
    }, 200);
  }

  public setText(text: string): void {
    this.searchText = text;
    if (text.length >= 2) {
      this.performSearch(text);
    }
  }
}
