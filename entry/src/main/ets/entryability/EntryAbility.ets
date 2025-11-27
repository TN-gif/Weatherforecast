import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppContextHolder } from '../common/di/AppContextHolder';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    AppContextHolder.setContext(this.context);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    
    // Check if launched from widget
    this.handleWidgetLaunch(want);
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    // Handle widget launch when app is already running
    this.handleWidgetLaunch(want);
  }
  
  /**
   * Handle launch from widget - set flag to navigate to GPS city
   */
  private handleWidgetLaunch(want: Want): void {
    const params = want.parameters;
    if (params) {
      const message = params['message'] as string;
      const forceGpsCity = params['forceGpsCity'] as string;
      
      hilog.info(DOMAIN, 'testTag', `[EntryAbility] 📱 Launch params - message: ${message}, forceGpsCity: ${forceGpsCity}`);
      
      if (message === 'OpenFromWidget' && forceGpsCity === 'true') {
        // Set AppStorage flag to force navigation to GPS city (index 0)
        AppStorage.setOrCreate('forceGpsCityNavigation', true);
        hilog.info(DOMAIN, 'testTag', '[EntryAbility] 🎯 Set forceGpsCityNavigation flag');
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    // 注意：卡片更新由 EntryFormAbility 负责
    // 主应用和卡片进程使用独立的 Preferences 存储，无法跨进程共享 form IDs
    // 卡片会在以下情况自动更新：
    // 1. 系统定时更新 (form_config.json 中的 scheduledUpdateTime)
    // 2. 用户点击卡片上的刷新按钮
    // 3. 卡片可见性变化时
  }
}
