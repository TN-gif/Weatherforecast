# Design Document: ArkTS Code Refactoring and Documentation

## Overview

本设计文档定义了天气应用 ArkTS 代码重构与注释规范化的技术方案。重构目标是提升代码质量、可维护性和可读性，通过系统化的方法消除代码重复，分离 UI 与业务逻辑，优化状态管理，并统一使用中文注释和 TSDoc 文档规范。

核心原则：
1. **UI 表现与业务逻辑功能不变** - 重构前后行为完全一致
2. **DRY 原则** - 消除重复代码，提取可复用组件
3. **关注点分离** - UI 结构与业务逻辑清晰分离
4. **性能优先** - 优化状态管理，减少不必要的重渲染
5. **文档优先** - 代码即文档，注释解释设计意图

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  ArkTS Refactoring System                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Code Analysis Layer                      │   │
│  │  - Identify duplicate UI patterns                     │   │
│  │  - Detect mixed UI/logic code                         │   │
│  │  - Find overused @State decorators                    │   │
│  │  - Locate English comments                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Refactoring Transformation Layer            │   │
│  │  - Extract @Builder functions                         │   │
│  │  - Create @Component custom components                │   │
│  │  - Extract private methods                            │   │
│  │  - Optimize state management                          │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │          Documentation Enhancement Layer              │   │
│  │  - Add TSDoc comments                                 │   │
│  │  - Translate English to Chinese                       │   │
│  │  - Add step-by-step logic comments                    │   │
│  │  - Document performance optimizations                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. RefactoringAnalyzer (重构分析器)

分析现有代码，识别需要重构的模式。

```typescript
interface DuplicatePattern {
  type: 'UI' | 'Logic';
  occurrences: CodeLocation[];
  complexity: 'Simple' | 'Complex';
  recommendation: 'Builder' | 'Component' | 'Method';
}

interface CodeLocation {
  filePath: string;
  startLine: number;
  endLine: number;
  code: string;
}

interface StateUsageAnalysis {
  variableName: string;
  decorator: '@State' | '@Prop' | '@Link' | 'none';
  affectsUI: boolean;
  recommendation: string;
}

class RefactoringAnalyzer {
  // 识别重复的 UI 模式
  static identifyDuplicateUI(filePath: string): DuplicatePattern[];
  
  // 识别混合的 UI/逻辑代码
  static identifyMixedCode(filePath: string): CodeLocation[];
  
  // 分析状态变量使用情况
  static analyzeStateUsage(filePath: string): StateUsageAnalysis[];
  
  // 识别英文注释
  static identifyEnglishComments(filePath: string): CodeLocation[];
}
```

### 2. UIExtractor (UI 提取器)

提取重复的 UI 代码为 @Builder 或 @Component。

```typescript
interface BuilderFunction {
  name: string;
  parameters: Parameter[];
  body: string;
  documentation: string;
}

interface CustomComponent {
  name: string;
  props: ComponentProp[];
  state: ComponentState[];
  builders: BuilderFunction[];
  methods: Method[];
  documentation: string;
}

interface Parameter {
  name: string;
  type: string;
  description: string;
}

class UIExtractor {
  // 提取为 @Builder 函数
  static extractAsBuilder(pattern: DuplicatePattern): BuilderFunction;
  
  // 提取为 @Component 组件
  static extractAsComponent(pattern: DuplicatePattern): CustomComponent;
  
  // 生成参数化代码
  static parameterizeCode(code: string, differences: string[]): string;
}
```

### 3. LogicSeparator (逻辑分离器)

分离 UI 结构与业务逻辑。

```typescript
interface ExtractedMethod {
  name: string;
  parameters: Parameter[];
  returnType: string;
  body: string;
  documentation: string;
  calledFrom: string[];
}

class LogicSeparator {
  // 从 build() 中提取计算逻辑
  static extractCalculations(buildMethod: string): ExtractedMethod[];
  
  // 从 build() 中提取数据处理逻辑
  static extractDataProcessing(buildMethod: string): ExtractedMethod[];
  
  // 简化 build() 方法
  static simplifyBuildMethod(buildMethod: string, extracted: ExtractedMethod[]): string;
  
  // 生成方法调用代码
  static generateMethodCall(method: ExtractedMethod): string;
}
```

### 4. StateOptimizer (状态优化器)

优化状态管理，减少不必要的响应式变量。

```typescript
interface StateOptimization {
  variableName: string;
  currentDecorator: string;
  recommendedDecorator: string;
  reason: string;
  impact: 'High' | 'Medium' | 'Low';
}

class StateOptimizer {
  // 分析变量是否需要响应式
  static analyzeReactivityNeed(variable: string, usage: string[]): boolean;
  
  // 推荐最佳装饰器
  static recommendDecorator(variable: string, analysis: StateUsageAnalysis): string;
  
  // 生成优化建议
  static generateOptimizations(filePath: string): StateOptimization[];
  
  // 应用优化
  static applyOptimization(filePath: string, optimization: StateOptimization): void;
}
```

### 5. DocumentationEnhancer (文档增强器)

添加和改进代码注释。

```typescript
interface TSDocComment {
  summary: string;
  description: string;
  params: ParamDoc[];
  returns: ReturnDoc | null;
  examples: string[];
}

interface ParamDoc {
  name: string;
  type: string;
  description: string;
}

interface ReturnDoc {
  type: string;
  description: string;
}

class DocumentationEnhancer {
  // 生成 TSDoc 注释
  static generateTSDoc(component: CustomComponent | Method): TSDocComment;
  
  // 翻译英文注释为中文
  static translateComment(englishComment: string): string;
  
  // 添加步骤注释
  static addStepComments(method: string): string;
  
  // 添加性能优化注释
  static addPerformanceComments(code: string, optimization: string): string;
}
```

### 6. CodeFormatter (代码格式化器)

统一代码结构和格式。

```typescript
interface FileStructure {
  imports: string[];
  interfaces: string[];
  builders: BuilderFunction[];
  component: CustomComponent;
  privateMethods: Method[];
}

class CodeFormatter {
  // 重组文件结构
  static reorganizeFile(filePath: string): FileStructure;
  
  // 生成格式化后的代码
  static formatCode(structure: FileStructure): string;
  
  // 添加分组注释
  static addGroupComments(structure: FileStructure): string;
  
  // 验证命名规范
  static validateNaming(structure: FileStructure): ValidationResult[];
}
```

## Data Models

### RefactoringTask

重构任务数据结构。

```typescript
interface RefactoringTask {
  id: string;
  filePath: string;
  type: 'UI_Deduplication' | 'Logic_Separation' | 'State_Optimization' | 'Documentation';
  priority: 'High' | 'Medium' | 'Low';
  description: string;
  estimatedImpact: string;
  status: 'Pending' | 'In_Progress' | 'Completed' | 'Skipped';
  changes: CodeChange[];
}

interface CodeChange {
  type: 'Add' | 'Modify' | 'Delete';
  location: CodeLocation;
  before: string;
  after: string;
  reason: string;
}
```

### RefactoringReport

重构报告数据结构。

```typescript
interface RefactoringReport {
  filePath: string;
  timestamp: number;
  tasks: RefactoringTask[];
  metrics: RefactoringMetrics;
  issues: RefactoringIssue[];
}

interface RefactoringMetrics {
  linesRemoved: number;
  linesAdded: number;
  duplicatesEliminated: number;
  stateVariablesOptimized: number;
  commentsAdded: number;
  commentsTranslated: number;
}

interface RefactoringIssue {
  severity: 'Error' | 'Warning' | 'Info';
  message: string;
  location: CodeLocation;
  suggestion: string;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

基于需求分析，本项目的大部分需求是关于代码质量、组织和文档规范，这些更适合通过代码审查和静态分析来验证，而不是运行时属性测试。以下是可以通过属性测试验证的核心正确性属性：

### Property 1: UI 渲染一致性（重构前后）

*For any* refactored component and any valid input state, the rendered UI output SHALL be visually identical to the original implementation, verified through snapshot comparison or visual regression testing.

**Validates: Requirements 1.3, 1.5**

**测试策略**: 使用快照测试或视觉回归测试，对比重构前后的渲染输出。

### Property 2: 交互行为一致性（重构前后）

*For any* refactored component and any user interaction (click, swipe, input), the resulting state changes and UI updates SHALL be identical to the original implementation.

**Validates: Requirements 1.3, 1.5**

**测试策略**: 记录原始组件的交互行为，在重构后的组件上重放相同的交互序列，验证结果一致。

### Property 3: 逻辑提取等价性

*For any* logic extracted from build() method into a private method, calling the extracted method with the same inputs SHALL produce the same output as the original inline code.

**Validates: Requirements 2.5**

**测试策略**: 对提取前后的逻辑进行单元测试，使用相同的输入验证输出一致性。

### Property 4: 响应式变量正确性

*For any* variable decorated with @State/@Prop/@Link, modifying its value SHALL trigger UI re-render of components that depend on it. For any variable without reactive decorators, modifying its value SHALL NOT trigger UI re-render.

**Validates: Requirements 3.1, 3.2**

**测试策略**: 监控组件渲染次数，验证状态变化是否正确触发或不触发重渲染。

### Property 5: 选择性重渲染

*For any* state change in a component, only the UI elements that depend on that specific state SHALL re-render, while unrelated UI elements SHALL NOT re-render.

**Validates: Requirements 3.4**

**测试策略**: 使用渲染追踪工具，验证状态变化时只有相关组件重新渲染。

### Property 6: 状态管理行为一致性（重构前后）

*For any* refactored component with optimized state management, the UI update behavior in response to state changes SHALL be identical to the original implementation.

**Validates: Requirements 3.5**

**测试策略**: 对比重构前后的状态更新序列，验证 UI 响应一致性。

### Property 7: 错误处理行为一致性（重构前后）

*For any* error scenario (network failure, invalid input, resource not found), the refactored code SHALL handle the error and display fallback UI in the same way as the original implementation.

**Validates: Requirements 8.5**

**测试策略**: 注入各种错误场景，验证重构前后的错误处理行为一致。

**注意**: 以下需求更适合通过静态分析和代码审查验证，而不是运行时属性测试：
- 代码组织规范（Requirements 1.1, 1.2, 1.4, 2.1-2.4, 6.1-6.5）
- 注释和文档规范（Requirements 4.1-4.5, 5.1-5.5, 7.1-7.4, 8.1-8.4）
- 代码质量指标（Requirements 3.3, 6.3, 7.5）

这些需求将通过以下方式验证：
- **静态代码分析工具**: 检查代码结构、命名规范、注释语言
- **代码审查**: 人工检查代码质量、文档完整性、设计意图
- **Linter 规则**: 自动检查代码风格和组织规范

## Error Handling

### Refactoring Errors

- **Syntax errors after refactoring**: Validate code with compiler before committing changes
- **Broken references**: Update all references when extracting code
- **Type mismatches**: Ensure parameter types match usage

### Documentation Errors

- **Translation failures**: Keep original English in comments if translation is uncertain
- **Missing TSDoc tags**: Generate warnings for incomplete documentation
- **Inconsistent terminology**: Maintain a glossary of technical terms

### Validation Errors

- **UI behavior changes**: Revert changes if visual output differs
- **Performance regressions**: Monitor render times before and after refactoring
- **State management issues**: Test all state updates after optimization

## Testing Strategy

### Unit Testing

使用 HarmonyOS 的 @ohos/hypium 测试框架进行单元测试。

测试范围：
1. 提取的 @Builder 函数的渲染输出
2. 提取的私有方法的计算结果
3. 状态变量的响应性行为

### Property-Based Testing

使用 fast-check 库进行属性测试，验证核心属性在各种输入下的正确性。

配置要求：
- 每个属性测试运行最少 100 次迭代
- 使用智能生成器约束输入空间

测试标注格式：
```typescript
// **Feature: arkts-refactor, Property 1: UI 行为不变性**
```

### Visual Regression Testing

1. 截图对比：重构前后的 UI 截图对比
2. 交互测试：验证所有用户交互行为一致
3. 动画测试：验证动画效果和时长一致

### Manual Testing Scenarios

1. 在 Previewer 中预览重构后的组件
2. 在真机上测试所有交互功能
3. 验证性能指标（渲染时间、内存使用）
4. 检查代码可读性和可维护性

## Refactoring Workflow

### Phase 1: Analysis (分析阶段)

1. 扫描所有 .ets 文件
2. 识别重复的 UI 模式
3. 检测混合的 UI/逻辑代码
4. 分析状态变量使用情况
5. 生成重构任务列表

### Phase 2: UI Refactoring (UI 重构阶段)

1. 提取重复 UI 为 @Builder 函数
2. 封装复杂组件为 @Component
3. 参数化差异部分
4. 验证 UI 行为一致性

### Phase 3: Logic Separation (逻辑分离阶段)

1. 从 build() 中提取计算逻辑
2. 从 build() 中提取数据处理逻辑
3. 简化 build() 方法结构
4. 验证功能正确性

### Phase 4: State Optimization (状态优化阶段)

1. 分析每个状态变量的使用情况
2. 移除不必要的响应式装饰器
3. 优化状态更新逻辑
4. 验证 UI 更新行为

### Phase 5: Documentation (文档化阶段)

1. 为所有组件添加 TSDoc
2. 翻译英文注释为中文
3. 添加步骤注释和性能注释
4. 验证文档完整性

### Phase 6: Validation (验证阶段)

1. 运行所有单元测试
2. 执行属性测试
3. 进行视觉回归测试
4. 生成重构报告

## Refactoring Priorities

### High Priority Files

1. **WeatherHomePage.ets** - 主页面，代码量大，逻辑复杂
2. **CityWeatherCard.ets** - 核心组件，使用频繁
3. **WeatherWidget2x2.ets** - 桌面卡片，需要优化性能

### Medium Priority Files

1. **HourlyTrendChart.ets** - 图表组件，性能敏感
2. **DailyForecastCard.ets** - 列表组件，可能有重复代码
3. **WeatherDetailGrid.ets** - 网格组件，结构可优化

### Low Priority Files

1. 工具类文件（已经较为简洁）
2. 常量定义文件（无需重构）
3. 模型定义文件（结构清晰）

## Performance Considerations

### State Management Optimization

- 减少 @State 变量数量可以减少响应式系统开销
- 使用普通变量替代不影响 UI 的状态变量
- 避免在 build() 中进行复杂计算

### Component Reusability

- 使用 @Reusable 装饰器标记可复用组件
- 提取通用组件到 common 目录
- 减少组件创建和销毁的开销

### Render Optimization

- 使用 @Builder 函数减少代码重复
- 避免深层嵌套的 UI 结构
- 使用 LazyForEach 处理长列表

## Code Style Guidelines

### Naming Conventions

- 组件名：PascalCase（例如：WeatherCard）
- 方法名：camelCase（例如：calculateTemperature）
- 常量名：UPPER_SNAKE_CASE（例如：MAX_TEMPERATURE）
- 私有方法：camelCase with private keyword

### Comment Style

- TSDoc：使用 /** ... */ 格式
- 行内注释：使用 // 格式
- 步骤注释：使用 // 步骤 1: ... 格式
- 性能注释：使用 // 性能优化: ... 格式

### Code Organization

```typescript
// 1. Imports
import ...

// 2. Interfaces
interface ...

// 3. @Builder Functions
@Builder
function ...

// 4. @Component
@Component
export struct ComponentName {
  // 4.1 Props
  @Prop ...
  
  // 4.2 State
  @State ...
  
  // 4.3 Lifecycle
  aboutToAppear() { ... }
  
  // 4.4 Build Method
  build() { ... }
  
  // 4.5 @Builder Methods
  @Builder
  private renderSection() { ... }
  
  // 4.6 Private Methods
  private calculateValue() { ... }
}
```

## Migration Strategy

### Incremental Refactoring

1. 一次重构一个文件
2. 每次重构后立即测试
3. 提交前进行完整验证
4. 保持代码库始终可运行

### Rollback Plan

1. 使用 Git 版本控制
2. 每个文件重构后单独提交
3. 如果发现问题，可以快速回滚
4. 保留重构前的代码备份

### Team Collaboration

1. 重构任务分配给团队成员
2. 使用统一的重构模板
3. 定期代码审查
4. 共享重构经验和最佳实践
