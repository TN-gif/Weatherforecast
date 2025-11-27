# ArkTS编译错误快速修复

## 错误信息
```
ERROR: 10905209 ArkTS Compiler Error
Error Message: Only UI component syntax can be written here.
At File: entry/src/main/ets/pages/home/WeatherHomePage.ets:575:5
```

## 错误原因

在 `@Builder` 方法内声明了局部变量 `const scroller`，违反了ArkTS规范。

根据 `代码规范.md` 第2.1节：
> `@Builder` 方法内禁止声明局部变量
> ArkTS 的 `build()` 和 `@Builder` 方法是声明式 UI 描述，不允许在其中定义局部变量或执行复杂逻辑。

## 错误代码

```typescript
@Builder
private renderCityScrollContent(state: CityWeatherState, cityIndex: number): void {
  const scroller = this.getScrollerForCity(state.city.id);  // ❌ 错误：局部变量声明
  
  Scroll(scroller) {
    // ...
  }
}
```

## 修复方案

直接在Scroll组件中调用方法，不声明局部变量：

```typescript
@Builder
private renderCityScrollContent(state: CityWeatherState, cityIndex: number): void {
  Scroll(this.getScrollerForCity(state.city.id)) {  // ✅ 正确：直接调用方法
    // ...
  }
}
```

## 修复文件

- `entry/src/main/ets/pages/home/WeatherHomePage.ets` (第575行)

## 验证结果

✅ 所有文件通过诊断检查，无编译错误

## ArkTS规范要点

### ❌ 禁止在 @Builder 中：
1. 声明局部变量（const、let、var）
2. 执行复杂逻辑
3. 使用 if-else 语句（应使用三元运算符或条件渲染）

### ✅ 正确做法：
1. 将变量提升为组件属性
2. 将逻辑提取为类方法
3. 直接在UI组件中调用方法
4. 使用条件渲染（`if (condition) { Component() }`）

## 相关规范参考

详见项目根目录 `代码规范.md` 第2章：UI 组件开发规范
