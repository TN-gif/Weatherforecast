import type common from '@ohos.app.ability.common';

let cachedContext: common.UIAbilityContext | null = null;

export class AppContextHolder {
  static setContext(context: common.UIAbilityContext): void {
    cachedContext = context;
  }

  static getContext(): common.UIAbilityContext | null {
    return cachedContext;
  }
}
