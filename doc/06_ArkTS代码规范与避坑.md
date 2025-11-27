# 06 ArkTS 代码规范与避坑

> 汇总自：`代码规范.md`，并辅以若干编译修复文档中的实践经验。

本文件是整个项目在与 ArkTS 编译器「反复博弈」后沉淀出的规范与避坑总结，建议作为本项目及后续 ArkTS 项目的统一编码约定。

---

## 一、类型系统与对象字面量

### 1.1 禁止裸用对象字面量与 `as` 断言

- ArkTS 要求对象字面量必须绑定到**显式声明的接口或类型别名**。
- 不允许通过 `as` 将对象字面量强制断言为某种类型。

**示例规范：**

- 定义类型：
  ```ts
  export type LogData = Record<string, string | number | boolean>;
  ```
- 使用前先声明变量：
  ```ts
  const data: LogData = { key: 'value' };
  logger.info('Tag', 'Msg', data);
  ```

### 1.2 避免索引签名接口，使用 `Record`

- `interface X { [key: string]: T }` 在 ArkTS 中不被推荐 / 支持；
- 统一改用 `type X = Record<string, T>`。

### 1.3 禁止对类属性使用字符串索引

- `obj['prop']` 只适用于 `Record` 类型；
- 对普通类实例应使用 `obj.prop` 访问。

### 1.4 设计系统常量必须先有接口

- 如设计系统中的颜色、间距、字号等聚合对象：
  - 先定义 `ColorsDef`、`SpacingDef` 等接口；
  - 再使用这些接口类型初始化静态常量。

---

## 二、UI 组件与 Builder 规范

### 2.1 `build()` 方法限制

- `build()` 是声明式 UI 描述，禁止：
  - 声明局部变量（`const` / `let` / `var`）；
  - 编写复杂逻辑或长分支；
  - 在方法中使用 `return` 直接结束渲染。
- 正确做法：
  - 始终返回一个根组件（如 `Stack` / `Column`）；
  - 使用条件渲染控制显示与隐藏；
  - 将复杂逻辑提取为普通方法或属性。

### 2.2 `@Builder` 方法限制

- 禁止：
  - 在 `@Builder` 方法内部声明局部变量；
  - 使用 `return` 提前结束；
  - 大量数据计算或副作用操作。
- 推荐：
  - 将计算结果存入组件字段或通过方法获取；
  - 在 Builder 中只保留 UI 结构与简单条件：
    ```ts
    @Builder
    private renderItems(): void {
      if (this.items.length > 0) {
        ForEach(this.items, item => {
          // ...
        });
      }
    }
    ```

---

## 三、异步与错误处理

### 3.1 Promise 与超时控制

- 构造 Promise 时必须显式声明泛型：
  ```ts
  new Promise<void>(resolve => setTimeout(resolve, 1000));
  ```
- 对网络请求等长耗时操作，统一使用 `Promise.race` 或封装好的工具函数实现超时控制。

### 3.2 `throw` 语句的类型安全

- 禁止直接 `throw error`（`error` 类型通常为 `unknown`）；
- 统一包装为 `Error`：
  ```ts
  catch (error) {
    const err = error instanceof Error ? error : new Error(String(error));
    throw err;
  }
  ```

### 3.3 避免 `any/unknown`

- 为所有 API 响应与内部数据结构定义接口；
- 仅在边界处使用 `unknown`，并立即进行类型缩小或转换。

---

## 四、长文件与代码组织

- 避免单文件过长（>300 行）与超长函数（>50 行）：
  - 大型页面如 `WeatherHomePage.ets`，应按功能拆分子组件；
  - 网络、存储、业务逻辑等尽量放在独立的 service / repository 中；
  - 通过调试与分析报告中给出的清单逐步拆解。
- 对复用逻辑（如日志、资源检查、网络诊断）统一抽象到 `common/utils` 或独立模块中。

---

## 五、配合本项目的推荐实践

- 开发前先阅读本规范，尤其是：
  - 对象 / 类型相关规则；
  - UI 组件与 Builder 的限制；
  - Promise / throw / any 的用法。
- 在遇到编译器错误时：
  - 先查错误码是否已在规范与修复文档中出现；
  - 按既有解决模式修复，保持代码风格一致。
- 将来扩展新功能时：
  - 优先参考已有组件与工具的写法；
  - 避免在旧坑附近引入新的不一致写法。

> 该规范与「02 开发问题与编译修复总览」相互印证：一个是经验总结，一个是修复过程记录，建议配合阅读。

