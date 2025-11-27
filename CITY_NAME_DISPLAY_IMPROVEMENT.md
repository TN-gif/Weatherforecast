# 城市名称显示精准化改进

## 问题描述

之前的城市名称显示逻辑过于简略，导致：
- "唐山"只显示"中国"
- 区级城市无法显示所属的市
- 国际城市信息不够详细

## 改进方案

### 设计原则：大字简洁、小字详细

- **大字部分**（32号字体）：只显示城市名称主要部分，保持简洁
- **小字部分**（14号字体）：显示完整的行政区划信息，提供详细上下文

### 1. 城市搜索结果构建（CitySearchService.mapQWeatherToSearchResult）

**改进前：**
```typescript
const result: CitySearchResult = {
  id: id,
  name: item.name,  // 只保存城市名
  country: item.country,
  state: item.adm1 || undefined,  // 只保存省份
  ...
};
```

**改进后：**
```typescript
// 对于中国城市，构建完整的行政区划显示
if (item.country === '中国' || item.country === 'China') {
  if (item.adm2 && item.adm2 !== item.name) {
    // 显示"城市名, 市级, 省级"
    // 例如："路南区, 唐山市, 河北省"
    if (item.adm1 && item.adm1 !== item.adm2) {
      displayName = `${item.name}, ${item.adm2}, ${item.adm1}`;
    } else {
      displayName = `${item.name}, ${item.adm2}`;
    }
  } else if (item.adm1 && item.adm1 !== item.name) {
    // 显示"城市名, 省级"
    // 例如："唐山, 河北省"
    displayName = `${item.name}, ${item.adm1}`;
  }
}
```

### 2. 城市名称显示（CityWeatherCard - 大字小字分离）

**UI 布局结构：**
```
┌─────────────────────────────┐
│      唐山          ← 大字（32号）简洁显示
│   河北省 唐山市    ← 小字（14号）详细显示
│      晴朗          ← 天气描述
│   体感 25° · 空气 优
│       28°         ← 主温度
│  最高 30° 最低 20°
└─────────────────────────────┘
```

**1. 大字部分（32号字体）** - `getCityNameSimple()`：
```typescript
// 只显示城市名称主要部分
const parts = name.split(',').map(part => part.trim());
return parts[0];  

// 示例：
// "唐山, 河北省" → "唐山"
// "路南区, 唐山市, 河北省" → "路南区"
// "北京, 中国" → "北京"
```

**2. 小字部分（14号字体）** - `getLocationDetail()`：
```typescript
// 显示完整的行政区划信息（不包含城市名本身）
if (parts.length === 3) {
  // 中国城市：显示"省 市"格式
  return `${parts[2]} ${parts[1]}`;
}

// 示例：
// "唐山, 河北省" → "河北省"
// "路南区, 唐山市, 河北省" → "河北省 唐山市"
// "北京, 中国" → null（不显示"中国"）
// "Manhattan, New York, United States" → "New York, United States"
```

### 3. GPS逆地理编码（GeoServiceRouter.reverseGeocode）

同样应用了完整的行政区划构建逻辑，确保GPS定位获取的城市名称也能显示完整信息。

### 4. 城市管理页面（CityManagementPage）

**改进了两个显示方法：**

1. **getCityDisplayName()** - 城市卡片的大字显示
   - 只显示城市名称的主要部分
   - 例如："路南区, 唐山市, 河北省" → "路南区"

2. **getCitySubtitle()** - 城市卡片的小字显示
   - 定位城市：显示"当前位置"
   - 中国城市：显示"省 市"格式（如"河北省 唐山市"）
   - 国际城市：显示"州/省, 国家"

3. **getSearchResultDisplayName()** - 搜索结果的大字显示
   - 只显示城市名称的主要部分

4. **getSearchResultSubtitle()** - 搜索结果的小字显示
   - 显示完整的行政区划信息

## 显示效果对比

### 中国城市

| 原始数据 | 改进前 | 改进后（大字） | 改进后（小字） |
|---------|--------|--------------|--------------|
| name: "唐山"<br>adm1: "河北省"<br>adm2: "唐山市" | "中国" | **唐山** | 河北省 |
| name: "路南区"<br>adm1: "河北省"<br>adm2: "唐山市" | "中国" | **路南区** | 河北省 唐山市 |
| name: "朝阳区"<br>adm1: "北京市"<br>adm2: "北京市" | "中国" | **朝阳区** | 北京市 |
| name: "北京"<br>adm1: "北京市"<br>adm2: null | "中国" | **北京** | （不显示） |

### 国际城市

| 原始数据 | 改进前 | 改进后（大字） | 改进后（小字） |
|---------|--------|--------------|--------------|
| name: "Tokyo"<br>adm1: "Tokyo"<br>country: "Japan" | "Tokyo" | **Tokyo** | Japan |
| name: "Manhattan"<br>adm1: "New York"<br>country: "United States" | "Manhattan" | **Manhattan** | New York, United States |

## 技术细节

### 和风天气API返回的数据结构

```typescript
interface QWeatherLocationItem {
  name: string;      // 城市名称（如"唐山"、"路南区"）
  adm1: string;      // 一级行政区（如"河北省"）
  adm2: string;      // 二级行政区（如"唐山市"）
  country: string;   // 国家（如"中国"）
  ...
}
```

### 显示规则

#### 数据构建阶段（CitySearchService）

1. **中国城市**：
   - 有 adm2 且不同于 name：构建 "name, adm2, adm1"
   - 只有 adm1 且不同于 name：构建 "name, adm1"
   - 都相同或都没有：只保存 "name"

2. **国际城市**：
   - 有 adm1 且不同于 name：构建 "name, adm1, country"
   - 没有 adm1 或相同：构建 "name, country"

#### UI显示阶段（CityWeatherCard）

1. **大字显示**（32号字体）：
   - 始终只显示第一部分（城市名）
   - 保持简洁，易于快速识别

2. **小字显示**（14号字体）：
   - 2部分（如"北京, 中国"）：不显示"中国"（避免冗余）
   - 3部分（如"路南区, 唐山市, 河北省"）：
     - 中国城市：显示"省 市"格式（如"河北省 唐山市"）
     - 国际城市：显示"州/省, 国家"格式
   - 提供完整的地理上下文

## 视觉效果示例

### 示例1：唐山市
```
┌─────────────────────────────┐
│        唐山         ← 大字：简洁
│      河北省         ← 小字：详细
│        晴朗
│   体感 25° · 空气 优
│         28°
│   最高 30° 最低 20°
└─────────────────────────────┘
```

### 示例2：路南区
```
┌─────────────────────────────┐
│       路南区        ← 大字：简洁
│   河北省 唐山市     ← 小字：详细
│        多云
│   体感 23° · 空气 良
│         26°
│   最高 28° 最低 18°
└─────────────────────────────┘
```

### 示例3：北京
```
┌─────────────────────────────┐
│        北京         ← 大字：简洁
│                     ← 小字：不显示（避免"中国"冗余）
│        晴朗
│   体感 22° · 空气 优
│         25°
│   最高 28° 最低 15°
└─────────────────────────────┘
```

## 测试建议

1. 搜索"唐山"，验证：
   - 大字显示："唐山"
   - 小字显示："河北省"

2. 搜索"路南区"，验证：
   - 大字显示："路南区"
   - 小字显示："河北省 唐山市"

3. 搜索"朝阳区"，验证：
   - 大字显示："朝阳区"
   - 小字显示："北京市"或其他城市的朝阳区

4. 搜索"北京"，验证：
   - 大字显示："北京"
   - 小字显示：不显示（避免冗余）

5. 使用GPS定位，验证显示完整的行政区划

6. 搜索国际城市（如"Tokyo"），验证：
   - 大字显示："Tokyo"
   - 小字显示："Japan"

## 相关文件

- `entry/src/main/ets/data/services/CitySearchService.ets` - 城市搜索结果构建
- `entry/src/main/ets/data/services/GeoServiceRouter.ets` - GPS逆地理编码
- `entry/src/main/ets/components/cards/CityWeatherCard.ets` - 主页城市天气卡片显示
- `entry/src/main/ets/pages/management/CityManagementPage.ets` - 城市管理页面显示和搜索结果显示（大字小字分离）
