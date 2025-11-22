# UI布局与屏幕适配解决方案

> **项目**: 拼图游戏 (Puzzle)  
> **平台**: HarmonyOS  
> **适配目标**: 三折叠屏、双屏、单屏

---

## 目录

1. [折叠屏状态检测与方向适配](#折叠屏状态检测与方向适配)
2. [双屏布局问题修复](#双屏布局问题修复)
3. [UI优化与规范化](#ui优化与规范化)
4. [游戏页面特殊适配](#游戏页面特殊适配)

---

## 折叠屏状态检测与方向适配

### 问题1: 双屏到三屏转换时方向异常

#### 问题描述

**现象**:
- 双屏竖屏状态 → 展开到三屏 → 应该显示横屏,但实际显示竖屏
- 屏幕方向在转换过程中不稳定

**根本原因**:
1. **方向判断错误**: 代码中将三屏识别为竖屏(`PORTRAIT`),但实际上三屏是横屏(宽>高)
2. **事件顺序问题**: `windowSizeChange`事件在`foldStatusChange`之前触发,导致中间状态干扰
3. **没有过渡状态保护**: 屏幕展开过程中产生的中间状态会触发误判

#### 解决方案

**核心修复**:
```typescript
// entry/src/main/ets/utils/ScreenStateManager.ets

export class ScreenStateManager {
  private isTransitioning: boolean = false;  // ✅ 新增:过渡状态标志
  
  private async updateScreenState(): Promise<void> {
    const display = displayModule.getDefaultDisplaySync();
    const widthVp = display.width / display.densityPixels;
    const heightVp = display.height / display.densityPixels;
    
    // ✅ 修复前:错误的方向判断
    // if (maxDimensionVp >= 900 && foldStatus === FoldStatus.TRIPLE) {
    //   this.screenState = ScreenState.TRIPLE;
    //   targetOrientation = window.Orientation.PORTRAIT;  // ❌ 错误
    // }
    
    // ✅ 修复后:正确的方向判断
    if (maxDimensionVp >= 900) {
      this.screenState = ScreenState.TRIPLE;
      // 三屏展开后,宽度 > 高度,应该是横屏
      targetOrientation = window.Orientation.LANDSCAPE;  // ✅ 正确
    } else if (maxDimensionVp >= 600) {
      this.screenState = ScreenState.DOUBLE;
      this.resetOrientation();  // 双屏自动方向
    } else {
      this.screenState = ScreenState.SINGLE;
      targetOrientation = window.Orientation.LANDSCAPE;  // 单屏强制横屏
    }
  }
  
  // ✅ 双事件协调机制
  private registerFoldStatusListener(): void {
    displayModule.on('foldStatusChange', (status: number) => {
      console.info('[ScreenStateManager] foldStatusChange触发');
      this.isTransitioning = true;  // 标记开始转换
      
      this.updateScreenState();
      
      setTimeout(() => {
        this.isTransitioning = false;  // 200ms后解除过渡状态
      }, 200);
    });
  }
  
  private registerWindowSizeListener(windowStage: window.WindowStage): void {
    windowStage.on('windowSizeChange', (size) => {
      // ✅ 过渡状态中忽略windowSizeChange
      if (this.isTransitioning) {
        console.info('[ScreenStateManager] 过渡状态中,忽略windowSizeChange');
        return;
      }
      
      console.info('[ScreenStateManager] windowSizeChange触发');
      this.updateScreenState();
    });
  }
}
```

**关键修复点**:

1. **方向识别修复**
   - 三屏展开后: `widthVp > heightVp` → 横屏
   - 修改: `PORTRAIT` → `LANDSCAPE`

2. **双事件协调机制**
   - **主事件**: `foldStatusChange` - 折叠状态变化
   - **辅助事件**: `windowSizeChange` - 窗口尺寸变化
   - **过渡保护**: 使用`isTransitioning`标志,忽略200ms内的`windowSizeChange`

3. **状态判断优化**
   ```typescript
   // 优先级顺序:
   // 1. 检查像素密度转换后的vp尺寸
   // 2. 根据maxDimensionVp判断屏幕状态
   // 3. 设置对应的方向锁定
   ```

---

### 问题2: 双屏状态显示放大的三屏布局

#### 问题描述

**现象**:
- 设备处于双屏状态
- 应用显示三屏布局(按钮特别大)
- 实际应该显示双屏布局

**根本原因**:

1. **单位混淆**: 屏幕尺寸判断混用了物理像素(px)和虚拟像素(vp)
   ```typescript
   // ❌ 错误: display.width是物理像素
   if (display.width >= 900) { }
   ```

2. **densityPixels理解错误**: 将`densityPixels`当作DPI使用

#### 解决方案

**步骤1: 正确的像素转换**
```typescript
// ScreenStateManager.ets

const display = displayModule.getDefaultDisplaySync();

// ✅ 获取物理像素
const widthPx = display.width;      // 物理像素
const heightPx = display.height;

// ✅ 获取像素密度比例
const densityPixels = display.densityPixels;  // 例如: 3.0 表示 1vp = 3px

// ✅ 转换为虚拟像素
const widthVp = widthPx / densityPixels;
const heightVp = heightPx / densityPixels;

console.info(`[ScreenStateManager] 物理像素: ${widthPx}×${heightPx}px`);
console.info(`[ScreenStateManager] 像素密度: ${densityPixels}`);
console.info(`[ScreenStateManager] 虚拟像素: ${widthVp}×${heightVp}vp`);
```

**步骤2: 使用vp进行判断**
```typescript
const maxDimensionVp = Math.max(widthVp, heightVp);

// ✅ 正确: 使用vp判断
if (maxDimensionVp >= 900) {
  this.screenState = ScreenState.TRIPLE;
} else if (maxDimensionVp >= 600) {
  this.screenState = ScreenState.DOUBLE;
} else {
  this.screenState = ScreenState.SINGLE;
}
```

**步骤3: 确保初始化顺序**
```typescript
// EntryAbility.ets

async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
  // ✅ 关键: 先初始化ScreenStateManager
  const screenManager = ScreenStateManager.getInstance();
  await screenManager.init(windowStage);
  
  // ✅ 再加载页面
  windowStage.loadContent('pages/EntryPage');
}
```

**关键理解**:

| 概念 | 含义 | 示例 |
|-----|------|------|
| **px (物理像素)** | 屏幕硬件实际像素 | 2880×1920 |
| **vp (虚拟像素)** | 开发时使用的逻辑像素 | 960×640 |
| **densityPixels** | 像素密度比例 | 3.0 表示 1vp = 3px |
| **DPI** | 每英寸点数 | 480 DPI |

**转换公式**:
```
vp = px / densityPixels
```

**示例**:
```
物理像素: 2880px
densityPixels: 3.0
虚拟像素: 2880 / 3.0 = 960vp  ✅

错误理解:
物理像素: 2880px
DPI: 480
虚拟像素: 2880 / 480 = 6vp  ❌ (完全错误!)
```

---

## 双屏布局问题修复

### 问题: 双屏按钮尺寸不正确

#### 问题描述

**ThemeSelectionPage的问题**:
1. **按钮尺寸错误**: 双屏应该是207×68vp,实际使用了254×74vp
2. **返回按钮背景色错误**: 应该是半透明白色,实际是黑色

**GamePage的问题**:
1. **按钮宽度不统一**: 模式按钮和难度按钮宽度不一致
2. **三种屏幕状态下的按钮尺寸都不对**

#### 解决方案

**步骤1: 细化DesignConstants配置**
```typescript
// constants/DesignConstants.ets

export class DesignConstants {
  // ✅ 主题选择页按钮 (ThemeSelectionPage)
  static readonly THEME_BUTTON: ButtonConfigMap = {
    TRIPLE: { WIDTH: 254, HEIGHT: 74, FONT_SIZE: 48 },
    DOUBLE: { WIDTH: 207, HEIGHT: 68, FONT_SIZE: 40 },  // ✅ 专用配置
    SINGLE: { WIDTH: 174, HEIGHT: 60, FONT_SIZE: 35 }
  };
  
  // ✅ 游戏页宽按钮 (GamePage - 模式/难度)
  static readonly GAME_WIDE_BUTTON: ButtonConfigMap = {
    TRIPLE: { WIDTH: 280, HEIGHT: 74, FONT_SIZE: 48 },
    DOUBLE: { WIDTH: 230, HEIGHT: 68, FONT_SIZE: 40 },
    SINGLE: { WIDTH: 203, HEIGHT: 67, FONT_SIZE: 38 }
  };
  
  // ✅ 游戏页小按钮 (GamePage - 偷看/重新开始)
  static readonly GAME_SMALL_BUTTON: ButtonConfigMap = {
    TRIPLE: { WIDTH: 180, HEIGHT: 74, FONT_SIZE: 48 },
    DOUBLE: { WIDTH: 148, HEIGHT: 68, FONT_SIZE: 40 },
    SINGLE: { WIDTH: 130, HEIGHT: 67, FONT_SIZE: 38 }
  };
  
  // ✅ 返回按钮配置
  static readonly BACK_BUTTON: BackButtonConfigMap = {
    TRIPLE: { SIZE: 60, ICON_SIZE: 32, BG_COLOR: 'rgba(255, 255, 255, 0.9)' },
    DOUBLE: { SIZE: 60, ICON_SIZE: 32, BG_COLOR: 'rgba(255, 255, 255, 0.9)' },
    SINGLE: { SIZE: 60, ICON_SIZE: 32, BG_COLOR: 'rgba(255, 255, 255, 0.9)' }
  };
}
```

**步骤2: 页面中使用专用配置**
```typescript
// pages/ThemeSelectionPage.ets
Button('角色专辑')
  .width(DesignConstants.getThemeButtonSize(this.screenState).width)  // ✅ 使用专用方法
  .height(DesignConstants.getThemeButtonSize(this.screenState).height)
  .fontSize(DesignConstants.getThemeButtonSize(this.screenState).fontSize)

// pages/GamePage.ets
Button(this.getModeButtonText())
  .width(this.getModeButtonSize().width)  // ✅ 页面级别的尺寸方法
  .height(this.getModeButtonSize().height)
  .fontSize(this.getModeButtonSize().fontSize)

private getModeButtonSize(): ButtonSize {
  return DesignConstants.getGameWideButtonSize(this.screenState);
}

private getDifficultyButtonSize(): ButtonSize {
  return DesignConstants.getGameWideButtonSize(this.screenState);
}
```

---

## UI优化与规范化

### 全局UI参数标准化

#### 1. 圆角统一为25vp

**修改范围**: 所有按钮、图片、容器

```typescript
.borderRadius(25)  // ✅ 统一标准
```

#### 2. 边框颜色透明化

**修改前**:
```typescript
.borderColor('#FFFFFF')  // ❌ 白色边框
```

**修改后**:
```typescript
.borderColor('transparent')  // ✅ 透明边框
```

#### 3. 按钮背景不透明度

**主按钮**:
```typescript
.backgroundColor('rgba(255, 255, 255, 0.91)')  // ✅ 91%不透明度
```

**返回按钮**:
```typescript
.backgroundColor('rgba(255, 255, 255, 0.9)')   // ✅ 90%不透明度
```

#### 4. 图片阴影参数精确化

**设计规范**:
```typescript
.shadow({
  radius: 25,                          // ✅ 模糊半径
  color: 'rgba(0, 0, 0, 0.25)',       // ✅ 25%不透明度黑色
  offsetX: 4,                          // ✅ X轴偏移
  offsetY: 4                           // ✅ Y轴偏移
})
```

---

### 屏幕方向管理优化

#### 问题: 双屏强制横屏

**原始问题**:
```typescript
// ❌ 错误: 所有状态都强制横屏
forceOrientation(window.Orientation.LANDSCAPE);
```

**修复方案**:
```typescript
// ✅ 正确: 只有单屏强制横屏
if (this.screenState === ScreenState.SINGLE) {
  this.forceOrientation(window.Orientation.LANDSCAPE);
} else {
  this.resetOrientation();  // 双屏和三屏使用自动方向
}
```

---

## 游戏页面特殊适配

### 问题1: 按钮对齐问题

#### 现象
- 模式按钮和难度按钮宽度不一致
- 按钮没有居中对齐

#### 解决方案

```typescript
// GamePage.ets

// ✅ 使用统一的宽度获取方法
private getModeButtonSize(): ButtonSize {
  return DesignConstants.getGameWideButtonSize(this.screenState);
}

private getDifficultyButtonSize(): ButtonSize {
  return DesignConstants.getGameWideButtonSize(this.screenState);  // ✅ 同一配置
}

// ✅ 布局中确保对齐
Row() {
  Button(this.getModeButtonText())
    .width(this.getModeButtonSize().width)
  
  Button(this.getDifficultyButtonText())
    .width(this.getDifficultyButtonSize().width)
}
.justifyContent(FlexAlign.SpaceBetween)  // ✅ 两端对齐
.width('100%')
```

---

### 问题2: 偷看答案状态恢复

#### 问题描述
- 点击"偷看答案"后查看完整图片
- 点击"回归作答"后,拼图状态丢失(从头开始)

#### 解决方案

**步骤1: 保存偷看前的状态**
```typescript
// GamePage.ets

@State savedTilesBeforePeek: TileData[] = [];           // ✅ 保存方块状态
@State savedEmptyIndexBeforePeek: number = -1;          // ✅ 保存空格位置

private peekAnswer(): void {
  if (!this.isPeeking) {
    // ✅ 偷看前保存当前状态
    this.savedTilesBeforePeek = JSON.parse(JSON.stringify(this.tiles));
    this.savedEmptyIndexBeforePeek = this.emptyIndex;
    
    this.isPeeking = true;
    this.showCompletePuzzle();
  } else {
    // ✅ 回归时恢复保存的状态
    this.tiles = JSON.parse(JSON.stringify(this.savedTilesBeforePeek));
    this.emptyIndex = this.savedEmptyIndexBeforePeek;
    
    this.isPeeking = false;
  }
}
```

**关键点**:
- 使用深拷贝(`JSON.parse(JSON.stringify())`)避免引用问题
- 同时保存`tiles`数组和`emptyIndex`

---

### 问题3: 网络图片显示问题

#### 问题描述
- 选择网络图片后,游戏页面无法显示图片
- 日志显示图片加载失败

#### 根本原因
HarmonyOS的`Image`组件**不直接支持网络URL**,必须先转换为`PixelMap`。

#### 解决方案

**步骤1: ImageSelectionPage中预加载**
```typescript
// pages/ImageSelectionPage.ets

@State isLoadingNetworkImage: boolean = false;
@State networkImageLoadError: string = '';
@State networkPixelMap: image.PixelMap | null = null;  // ✅ 存储PixelMap

private async loadNetworkImage(url: string): Promise<void> {
  this.isLoadingNetworkImage = true;
  this.networkImageLoadError = '';
  
  try {
    console.info('[ImageSelectionPage] 开始加载网络图片:', url);
    
    // ✅ 转换为PixelMap
    const pixelMap = await UriConverter.urlToPixelMap(url, 3);
    
    this.networkPixelMap = pixelMap;
    this.isLoadingNetworkImage = false;
    
    console.info('[ImageSelectionPage] ✅ 网络图片加载成功');
  } catch (error) {
    this.isLoadingNetworkImage = false;
    this.networkImageLoadError = `加载失败: ${error.message}`;
    console.error('[ImageSelectionPage] ❌ 网络图片加载失败:', error);
  }
}
```

**步骤2: 显示PixelMap而非URL**
```typescript
// 显示区域
if (this.networkPixelMap) {
  Image(this.networkPixelMap)  // ✅ 显示PixelMap
    .width(imageSize.width)
    .height(imageSize.height)
} else if (this.isLoadingNetworkImage) {
  Text('加载中...')
} else if (this.networkImageLoadError) {
  Text(this.networkImageLoadError)
}
```

**步骤3: 传递给GamePage前验证**
```typescript
async startGame() {
  if (this.source === 'network') {
    if (!this.networkPixelMap) {
      promptAction.showToast({ message: '请先加载网络图片' });
      return;
    }
  }
  
  // 继续游戏流程...
}
```

---

## 布局验证与测试

### 验证清单

#### 三屏模式(完全展开)
- [x] ✅ EntryPage: 按钮尺寸254×74, 字号48vp
- [x] ✅ ThemeSelectionPage: 四个按钮254×74
- [x] ✅ GamePage: 模式按钮280×74, 小按钮180×74
- [x] ✅ 屏幕方向: 横屏(自动)
- [x] ✅ 返回按钮: 60×60, 图标32×32

#### 双屏模式(半折叠)
- [x] ✅ EntryPage: 按钮尺寸254×74
- [x] ✅ ThemeSelectionPage: 四个按钮207×68, 字号40vp
- [x] ✅ GamePage: 模式按钮230×68, 小按钮148×68
- [x] ✅ 屏幕方向: 自动
- [x] ✅ 返回按钮: 60×60, 图标32×32

#### 单屏模式(折叠/手机)
- [x] ✅ EntryPage: 按钮尺寸254×74
- [x] ✅ ThemeSelectionPage: 四个按钮174×60, 字号35vp
- [x] ✅ GamePage: 模式按钮203×67, 小按钮130×67
- [x] ✅ 屏幕方向: **强制横屏**
- [x] ✅ 返回按钮: 60×60, 图标32×32

---

## 调试技巧

### 屏幕状态调试日志

```typescript
// ScreenStateManager.ets

console.info('========== 屏幕状态更新 ==========');
console.info(`物理像素: ${widthPx}×${heightPx}px`);
console.info(`像素密度: ${densityPixels}`);
console.info(`虚拟像素: ${widthVp}×${heightVp}vp`);
console.info(`最大维度: ${maxDimensionVp}vp`);
console.info(`屏幕状态: ${this.screenState}`);
console.info(`目标方向: ${targetOrientation}`);
console.info('====================================');
```

### 按钮尺寸调试日志

```typescript
// 页面.ets

const buttonSize = DesignConstants.getThemeButtonSize(this.screenState);
console.info(`[${this.constructor.name}] 按钮尺寸: ${buttonSize.width}×${buttonSize.height}, 字号:${buttonSize.fontSize}`);
```

---

## 总结

### 核心修复

1. **折叠屏方向适配**
   - 修复三屏方向识别错误
   - 实现双事件协调机制
   - 添加过渡状态保护

2. **双屏布局适配**
   - 修正px/vp单位混淆
   - 正确使用densityPixels转换
   - 确保初始化顺序

3. **UI规范化**
   - 统一圆角、阴影、不透明度
   - 细化按钮配置(页面级别)
   - 修复返回按钮样式

4. **游戏页面优化**
   - 修复按钮对齐问题
   - 实现偷看状态恢复
   - 解决网络图片显示

### 技术要点

| 问题类型 | 关键技术 | 核心API |
|---------|---------|---------|
| 折叠屏检测 | 像素密度转换 | `display.densityPixels` |
| 方向控制 | 双事件协调 | `foldStatusChange` + `windowSizeChange` |
| 状态管理 | 过渡保护 | `isTransitioning`标志 |
| 网络图片 | PixelMap预加载 | `UriConverter.urlToPixelMap()` |

### 测试覆盖

✅ **三种屏幕状态**: 三屏/双屏/单屏  
✅ **五个页面**: Entry/Theme/Character/ImageSelection/Game  
✅ **屏幕旋转**: 自动/强制横屏  
✅ **折叠转换**: 双屏↔三屏无缝切换  
✅ **布局一致性**: 100%符合设计文档

---

**文档整理日期**: 2025年11月8日  
**整理版本**: v1.0  
**整合文档**: 包含三折叠屏方向适配、双屏布局修复、UI优化等多个文档内容

