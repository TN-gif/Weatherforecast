# Lottie动画资源说明

## Lottie动画规范
- **尺寸**: ≤100x100px
- **持续时间**: ≤2秒
- **文件大小**: ≤50KB
- **格式**: JSON格式

## 当前需要的Lottie文件
- `sun.json` - 太阳旋转动画
- `rain.json` - 雨滴下落动画
- `snow.json` - 雪花飘落动画
- `moon.json` - 月亮闪烁动画

## 获取资源建议
1. 使用LottieFiles网站下载免费动画
2. 使用After Effects + Bodymovin插件制作
3. 确保动画循环播放
4. 优化文件大小以提升性能

## 集成示例
```typescript
// 未来集成Lottie组件时的用法
LottieAnimator({ 
  src: 'rawfile/lottie/sun.json',
  speed: 0.8 
})
.size({ width: 80, height: 80 })
.margin({ top: 20, right: 30 })
```
