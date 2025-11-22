import { DesignSystem } from '../../common/theme/DesignSystem';

// 定义 Margin 类型接口
interface MarginConfig {
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
}

@Component
export struct WeatherSkeleton {
  @State private shimmerTranslate: number = -100;
  
  // 预定义常量，避免在 build 中声明变量
  private readonly emptyMargin: MarginConfig = {};
  private readonly topMargin: MarginConfig = { top: 60 };
  private readonly topMMargin: MarginConfig = { top: DesignSystem.Spacing.M };
  private readonly verticalMargin: MarginConfig = { top: 8, bottom: 8 };

  build() {
    Stack() {
      Column() {
        // Header Placeholder
        Row() {
          this.SkeletonBlock(120, 32, this.emptyMargin)
          Blank()
          this.SkeletonBlock(32, 32, this.emptyMargin)
        }
        .width('100%')
        .padding({ left: DesignSystem.Spacing.L, right: DesignSystem.Spacing.L, top: DesignSystem.Spacing.L })

        // Main Temperature Placeholder
        Column() {
          this.SkeletonBlock(180, 80, this.topMargin)
          this.SkeletonBlock(100, 24, this.topMMargin)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // Hourly Forecast Placeholder
        Row() {
          ForEach([1, 2, 3, 4, 5], () => {
            Column() {
              this.SkeletonBlock(40, 16, this.emptyMargin)
              this.SkeletonBlock(32, 32, this.verticalMargin)
              this.SkeletonBlock(40, 16, this.emptyMargin)
            }
            .margin({ right: DesignSystem.Spacing.L })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 80 })

        // Daily Forecast Placeholder
        Column() {
          ForEach([1, 2, 3], () => {
            Row() {
              this.SkeletonBlock(60, 16, this.emptyMargin)
              Blank()
              this.SkeletonBlock(32, 32, this.emptyMargin)
              Blank()
              this.SkeletonBlock(80, 16, this.emptyMargin)
            }
            .width('100%')
            .height(50)
          })
        }
        .width('100%')
        .padding(DesignSystem.Spacing.L)
        .margin({ top: DesignSystem.Spacing.L })
      }
      .width('100%')
      .height('100%')

      // Shimmer Overlay
      Row()
        .width('50%')
        .height('100%')
        .linearGradient({
          angle: 90,
          colors: [
            ['rgba(255,255,255,0)', 0.0],
            ['rgba(255,255,255,0.1)', 0.5],
            ['rgba(255,255,255,0)', 1.0]
          ]
        })
        .translate({ x: `${this.shimmerTranslate}%` })
        .onAppear(() => {
          animateTo({
            duration: 1500,
            curve: Curve.Linear,
            iterations: -1
          }, () => {
            this.shimmerTranslate = 200;
          })
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SkeletonBlock(width: number, height: number, margin: MarginConfig) {
    Row()
      .width(width)
      .height(height)
      .backgroundColor('rgba(255,255,255,0.1)')
      .borderRadius(4)
      .margin(margin)
  }
}
