# 小羊扫雷 - UI开发与修复综合文档

**最后更新**: 2025年10月11日  
**涵盖内容**: 页面开发、字体系统、UI/UX优化、屏幕适配

---

## 📋 目录

1. [页面开发概述](#页面开发概述)
2. [字体系统实现](#字体系统实现)
3. [UI/UX优化](#uiux优化)
4. [屏幕适配方案](#屏幕适配方案)
5. [沉浸式状态栏](#沉浸式状态栏)
6. [常见问题与解决方案](#常见问题与解决方案)

---

## 页面开发概述

### 主要页面结构

```
Index.ets (主页面)
├── CharacterSelectScreen (选择小羊)
├── Menu (主菜单)
│   ├── AchievementsScreen (成就)
│   ├── GameSelection (游戏选择)
│   └── SettingsScreen (设置)
├── LevelSelectScreen (关卡选择)
│   ├── 挑战模式
│   └── 自定义模式
├── AdventureMapScreen (冒险地图)
└── GameBoard (游戏界面)
    ├── CellComponent (格子组件)
    ├── GameHUD (游戏信息显示)
    └── GameControls (游戏控制)
```

### 页面状态管理

```typescript
// 游戏状态类型
type GameState = 
  | 'character_select'  // 选择小羊
  | 'menu'              // 主菜单
  | 'challenge_select'  // 挑战模式选择
  | 'adventure_map'     // 冒险地图
  | 'challenge_game'    // 挑战游戏中
  | 'adventure_game';   // 冒险游戏中

// 导航标签类型
type NavTab = 'achievements' | 'game' | 'settings';
```

---

## 字体系统实现

### 自定义字体注册

#### 字体文件位置
```
entry/src/main/resources/rawfile/fonts/
└── Muyao-Softbrush-Regular.ttf
```

#### 字体管理器

```typescript
// FontManager.ets
export class FontManager {
  private static readonly CUSTOM_FONT_FAMILY: string = 'MuyaoSoftbrush';
  private static readonly CUSTOM_FONT_PATH: string = 'fonts/Muyao-Softbrush-Regular.ttf';
  private static readonly FALLBACK_FONT: string = 'sans-serif';
  
  static getFontFamily(): string {
    return FontManager.CUSTOM_FONT_FAMILY;
  }
  
  static getFallbackFont(): string {
    return FontManager.FALLBACK_FONT;
  }
}
```

#### 字体注册（EntryAbility.ets）

```typescript
import font from '@ohos.font';

onCreate(want, launchParam) {
  // 注册自定义字体
  this.registerCustomFont();
  
  // 保存context到AppStorage
  AppStorage.setOrCreate('context', this.context);
}

private registerCustomFont(): void {
  try {
    font.registerFontSync({
      familyName: FontManager.getFontFamily(),
      familySrc: $rawfile(FontManager.getCustomFontPath())
    });
    console.log('[FONT] 自定义字体注册成功');
  } catch (error) {
    console.error('[FONT] 字体注册失败:', error);
  }
}
```

### 字体使用规范

#### 在组件中使用字体

```typescript
// 方式1: 使用FontManager
Text('草原 大作战')
  .fontFamily(`${FontManager.getFontFamily()}, ${FontManager.getFallbackFont()}`)
  .fontSize(82)
  .fontColor(Color.Black);

// 方式2: 直接指定
Text('请选择 你的小羊')
  .fontFamily('MuyaoSoftbrush, sans-serif')
  .fontSize(60)
  .fontColor(Color.Black);
```

#### 字体回退机制

```typescript
// 使用逗号分隔的字体列表，实现回退
.fontFamily('MuyaoSoftbrush, HarmonyOS Sans, sans-serif')
```

**说明**: 如果自定义字体加载失败，自动使用HarmonyOS Sans或系统默认字体。

### 字体问题修复历史

#### 问题1: 字体未加载

**症状**: 所有文本显示为系统默认字体

**原因**: 字体注册时机错误或路径不正确

**解决方案**:
1. 在`EntryAbility.onCreate()`中注册
2. 使用`registerFontSync()`而非已弃用的`registerFont()`
3. 确认字体文件路径正确

#### 问题2: 部分文字不显示

**症状**: 中文或特殊字符显示为方块

**原因**: 字体文件不包含相应字符集

**解决方案**:
1. 使用支持中文的字体文件
2. 添加字体回退机制
3. 测试常用文字显示

---

## UI/UX优化

### 响应式设计

#### 屏幕密度适配

```typescript
// 使用vp（虚拟像素）单位
Column()
  .width('100%')
  .height('100%')
  .padding(32)  // 自动适配不同屏幕密度
```

#### 百分比布局

```typescript
// 使用百分比实现响应式
Row() {
  Column()
    .width('48%')  // 左列
  Column()
    .width('48%')  // 右列
}
.width('100%')
.justifyContent(FlexAlign.SpaceBetween);
```

### 交互反馈

#### 点击反馈

```typescript
Button('确认选择')
  .onClick(() => {
    // 触觉反馈
    HapticFeedbackUtils.vibrate();
    
    // 音效反馈
    audioManager.playSound('click');
    
    // 执行操作
    this.handleConfirm();
  });
```

#### 长按反馈

```typescript
Cell()
  .onLongPress(() => {
    // 触觉反馈
    HapticFeedbackUtils.vibrate();
    
    // 音效反馈
    audioManager.playSound('flag');
    
    // 插旗操作
    viewModel.flagCell(row, col);
  });
```

### 动画效果

#### 页面转场动画

```typescript
if (this.gameState === 'character_select') {
  CharacterSelectScreen()
    .transition(TransitionEffect.OPACITY
      .animation({ duration: 300, curve: Curve.EaseInOut }));
}
```

#### 按钮点击动画

```typescript
Button('开始游戏')
  .scale(this.isPressed ? 0.95 : 1.0)
  .animation({ duration: 100, curve: Curve.Sharp })
  .onTouch((event: TouchEvent) => {
    if (event.type === TouchType.Down) {
      this.isPressed = true;
    } else if (event.type === TouchType.Up) {
      this.isPressed = false;
    }
  });
```

#### 格子翻开动画

```typescript
Cell()
  .opacity(cell.isRevealed ? 1.0 : 0.0)
  .scale(cell.isRevealed ? 1.0 : 0.8)
  .animation({
    duration: 200,
    curve: Curve.EaseOut
  });
```

---

## 屏幕适配方案

### 屏幕尺寸适配

#### 获取屏幕信息

```typescript
import display from '@ohos.display';

private getScreenInfo() {
  const displayInfo = display.getDefaultDisplaySync();
  const screenWidth = displayInfo.width;
  const screenHeight = displayInfo.height;
  const density = displayInfo.densityDPI;
  
  console.log(`Screen: ${screenWidth}x${screenHeight}, DPI: ${density}`);
}
```

#### 动态计算尺寸

```typescript
// 棋盘大小根据屏幕宽度动态计算
private calculateBoardSize(): number {
  const screenWidth = this.getScreenWidth();
  const padding = 32;  // vp
  const availableWidth = screenWidth - padding * 2;
  
  return Math.min(availableWidth, 400);  // 最大400vp
}
```

### 横竖屏适配

```typescript
Column() {
  if (this.isLandscape) {
    // 横屏布局
    Row() {
      GameBoard().width('60%');
      GameInfo().width('40%');
    }
  } else {
    // 竖屏布局
    Column() {
      GameInfo().height('20%');
      GameBoard().height('80%');
    }
  }
}
```

### 折叠屏适配

```typescript
// 检测折叠状态
import screen from '@ohos.screen';

private checkFoldStatus() {
  screen.on('foldStatusChange', (status) => {
    if (status === screen.FoldStatus.FOLD_STATUS_EXPANDED) {
      // 展开状态
      this.applyExpandedLayout();
    } else if (status === screen.FoldStatus.FOLD_STATUS_FOLDED) {
      // 折叠状态
      this.applyFoldedLayout();
    }
  });
}
```

---

## 沉浸式状态栏

### 实现沉浸式效果

#### 设置窗口全屏

```typescript
// EntryAbility.ets
onWindowStageCreate(windowStage: window.WindowStage) {
  windowStage.getMainWindow((err, windowClass) => {
    if (err.code) {
      console.error('获取窗口失败');
      return;
    }
    
    // 设置全屏
    windowClass.setWindowLayoutFullScreen(true, (err) => {
      if (err.code) {
        console.error('设置全屏失败');
        return;
      }
      
      // 设置状态栏透明
      windowClass.setWindowSystemBarEnable(['status', 'navigation']);
      
      // 设置状态栏颜色
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',  // 透明
        navigationBarColor: '#00000000',
        statusBarContentColor: '#FF000000',  // 黑色内容
        navigationBarContentColor: '#FF000000'
      });
    });
  });
}
```

#### 处理安全区域

```typescript
// 获取安全区域
import window from '@ohos.window';

private getSafeArea() {
  const windowClass = window.getLastWindow(this.context);
  const safeArea = windowClass.getWindowAvoidArea(
    window.AvoidAreaType.TYPE_SYSTEM
  );
  
  return {
    top: safeArea.topRect.height,
    bottom: safeArea.bottomRect.height
  };
}

// 应用安全区域padding
Column() {
  // 内容
}
.padding({
  top: this.safeArea.top,
  bottom: this.safeArea.bottom
});
```

---

## 常见问题与解决方案

### 问题1: 触摸事件穿透 ❌

**症状**: 音量滑块无法拖动，装饰性组件阻挡了触摸

**原因**: Stack布局中上层组件默认会拦截触摸事件

**解决方案**:
```typescript
// 为装饰性组件添加 hitTestBehavior
Column()  // 背景条
  .hitTestBehavior(HitTestMode.None);  // 允许触摸穿透

Text('50%')  // 百分比文字
  .hitTestBehavior(HitTestMode.None);  // 允许触摸穿透

Slider()  // 实际可交互组件
  .width('100%');
```

### 问题2: @Builder 参数不响应 ❌

**症状**: 使用@Builder封装组件，参数变化时UI不更新

**原因**: @Builder方法的参数是按值传递，不支持响应式

**解决方案**:
```typescript
// ❌ 错误：使用@Builder参数
@Builder VolumeBar(value: number) {
  Text(`${value}%`);  // value不会更新
}

// ✅ 正确：直接使用@State
Column() {
  Text(`${this.volume}%`);  // 响应式更新
}
```

### 问题3: 属性命名冲突 ❌

**症状**: `@State scale` 编译错误

**原因**: scale是ArkUI内置属性，不能作为@State变量名

**解决方案**:
```typescript
// ❌ 错误
@State scale: number = 1.0;

// ✅ 正确：使用语义化前缀
@State boardScale: number = 1.0;
@State boardOffsetX: number = 0;
@State boardOffsetY: number = 0;
```

### 问题4: 背景图片路径错误 ❌

**症状**: 背景图片不显示

**原因**: 文件名与代码中的路径不匹配

**解决方案**:
1. 确认rawfile目录中的实际文件名
2. 使用$rawfile()语法
3. 路径区分大小写

```typescript
// ✅ 正确路径
Image($rawfile('images/background/喜羊羊.jpg'))
```

### 问题5: Text换行问题 ❌

**症状**: 长文本不换行或换行位置不对

**解决方案**:
```typescript
Text('很长的文本内容...')
  .width('100%')
  .maxLines(2)  // 最多2行
  .textOverflow({ overflow: TextOverflow.Ellipsis })  // 超出显示...
  .wordBreak(WordBreak.BREAK_ALL);  // 强制换行
```

---

## 主题系统集成

### ThemeProvider使用

```typescript
// 在组件中使用主题
@Component
export struct MyComponent {
  @ObjectLink provider: ThemeProvider;
  
  build() {
    Column() {
      Image($rawfile(this.provider.flagImage))
      Text(this.provider.characterName)
        .fontColor(this.provider.primaryColor);
    }
    .backgroundColor(this.provider.backgroundColor);
  }
}
```

### 主题切换动画

```typescript
// 切换主题时添加过渡动画
private switchTheme(character: string) {
  animateTo({
    duration: 300,
    curve: Curve.EaseInOut
  }, () => {
    themeProvider.switchTheme(character);
  });
}
```

---

## 性能优化建议

### 1. 懒加载图片

```typescript
Image($rawfile('images/large.jpg'))
  .objectFit(ImageFit.Cover)
  .interpolation(ImageInterpolation.High)
  .renderMode(ImageRenderMode.Original)
  .syncLoad(false);  // 异步加载
```

### 2. 列表优化

```typescript
List() {
  LazyForEach(this.dataSource, (item) => {
    ListItem() {
      // 复杂组件
    }
  }, item => item.id);
}
.cachedCount(3);  // 缓存3个未显示的item
```

### 3. 减少重绘

```typescript
// 使用@ObjectLink而非@State
@ObjectLink cell: Cell;  // 只有cell变化时才重绘

// 而不是
@State board: Cell[][];  // 整个board变化都会重绘
```

---

## 测试清单

### UI显示测试
- [ ] 所有文本正确显示（中文、英文、数字）
- [ ] 自定义字体生效
- [ ] 图片正常加载
- [ ] 背景图片显示正确
- [ ] 图标清晰无变形

### 交互测试
- [ ] 按钮点击响应
- [ ] 滑块拖动流畅
- [ ] 长按功能正常
- [ ] 双击识别准确
- [ ] 手势操作顺畅

### 适配测试
- [ ] 不同屏幕尺寸显示正常
- [ ] 横竖屏切换无问题
- [ ] 折叠屏适配正确
- [ ] 状态栏显示正常
- [ ] 安全区域处理正确

### 性能测试
- [ ] 页面切换流畅（< 300ms）
- [ ] 滚动无卡顿
- [ ] 动画帧率稳定（60fps）
- [ ] 内存占用合理
- [ ] 无内存泄漏

---

## 总结

### 核心要点

1. **字体系统**: 使用FontManager统一管理，添加回退机制
2. **响应式设计**: 使用vp单位和百分比布局
3. **交互反馈**: 结合触觉、音效、动画提升体验
4. **屏幕适配**: 处理不同尺寸、横竖屏、折叠屏
5. **沉浸式体验**: 全屏显示，处理安全区域
6. **性能优化**: 懒加载、缓存、减少重绘

### 开发建议

1. 优先使用系统组件
2. 遵循HarmonyOS设计规范
3. 重视无障碍支持
4. 充分测试不同设备
5. 注意性能监控

---

**文档编写**: AI Assistant  
**最后更新**: 2025年10月11日  
**版本**: v1.0  
**状态**: ✅ 完成

