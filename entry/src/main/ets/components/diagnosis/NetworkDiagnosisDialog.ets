import { DiagnosisResult } from '../../common/utils/NetworkDiagnosis';

@CustomDialog
export struct NetworkDiagnosisDialog {
  controller?: CustomDialogController;
  diagnosisResult?: DiagnosisResult;
  networkScore: number = 0;
  issues: string[] = [];

  build() {
    Column() {
      // 标题
      Text('网络诊断报告')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      // 评分显示
      Row() {
        Text('网络质量评分')
          .fontSize(16)
          .layoutWeight(1);
        
        Text(`${this.networkScore}/100`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getScoreColor());
      }
      .width('100%')
      .margin({ bottom: 16 });

      // 详细信息
      if (this.diagnosisResult) {
        this.buildDetailInfo();
      }

      // 问题建议
      if (this.issues.length > 0) {
        this.buildIssuesList();
      }

      // 按钮
      Row() {
        Button('关闭')
          .onClick(() => {
            if (this.controller) {
              this.controller.close();
            }
          })
          .backgroundColor('#007AFF')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .layoutWeight(1);
      }
      .width('100%')
      .margin({ top: 20 });
    }
    .width('90%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12);
  }

  @Builder
  private buildDetailInfo(): void {
    Column() {
      Text('详细信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start);

      // 网络状态
      this.buildInfoRow('连接状态', 
        this.diagnosisResult!.networkStatus.isConnected ? '已连接' : '未连接',
        this.diagnosisResult!.networkStatus.isConnected);

      // 连接类型
      this.buildInfoRow('连接类型', this.diagnosisResult!.networkStatus.connectionType, true);

      // 连通性测试
      this.buildInfoRow('连通性测试', 
        this.diagnosisResult!.connectivityTest.success ? '正常' : '异常',
        this.diagnosisResult!.connectivityTest.success);

      // API健康检查
      this.buildInfoRow('API服务', 
        this.diagnosisResult!.apiHealthCheck.success ? '正常' : '异常',
        this.diagnosisResult!.apiHealthCheck.success);

      // DNS测试
      this.buildInfoRow('DNS解析', 
        this.diagnosisResult!.dnsTest.success ? '正常' : '异常',
        this.diagnosisResult!.dnsTest.success);
    }
    .width('100%')
    .margin({ bottom: 16 });
  }

  @Builder
  private buildInfoRow(label: string, value: string, isGood: boolean): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .layoutWeight(1);
      
      Text(value)
        .fontSize(14)
        .fontColor(isGood ? '#00AA00' : '#FF4444')
        .fontWeight(FontWeight.Medium);
    }
    .width('100%')
    .margin({ bottom: 8 });
  }

  @Builder
  private buildIssuesList(): void {
    Column() {
      Text('问题建议')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start);

      ForEach(this.issues.slice(0, 5), (issue: string, index: number) => {
        Row() {
          Text(`${index + 1}.`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ right: 8 });
          
          Text(issue)
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1);
        }
        .width('100%')
        .margin({ bottom: 6 })
        .alignItems(VerticalAlign.Top);
      }, (issue: string, index: number) => `issue_${index}`);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  private getScoreColor(): string {
    if (this.networkScore >= 80) {
      return '#00AA00'; // 绿色
    } else if (this.networkScore >= 60) {
      return '#FF8800'; // 橙色
    } else {
      return '#FF4444'; // 红色
    }
  }
}
