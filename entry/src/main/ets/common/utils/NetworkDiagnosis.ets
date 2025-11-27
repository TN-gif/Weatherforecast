import http from '@ohos.net.http';
import connection from '@ohos.net.connection';
import { WeatherApiConstants } from '../../common/constants/WeatherApiConstants';

export interface DiagnosisResult {
  networkStatus: NetworkStatus;
  connectivityTest: ConnectivityTest;
  apiHealthCheck: ApiHealthCheck;
  dnsTest: DnsTest;
  timestamp: number;
}

export interface NetworkStatus {
  isConnected: boolean;
  connectionType: string;
  signalStrength?: number;
}

export interface ConnectivityTest {
  success: boolean;
  latency?: number;
  error?: string;
}

export interface ApiHealthCheck {
  success: boolean;
  responseTime?: number;
  statusCode?: number;
  error?: string;
}

export interface DnsTest {
  success: boolean;
  resolveTime?: number;
  error?: string;
}

export class NetworkDiagnosis {
  private static instance: NetworkDiagnosis | null = null;

  private constructor() {}

  static getInstance(): NetworkDiagnosis {
    if (NetworkDiagnosis.instance === null) {
      NetworkDiagnosis.instance = new NetworkDiagnosis();
    }
    return NetworkDiagnosis.instance;
  }

  async performFullDiagnosis(): Promise<DiagnosisResult> {
    console.info('[NetworkDiagnosis] Starting full network diagnosis...');
    
    const startTime = Date.now();
    
    try {
      // 避免解构声明，使用数组索引访问
      const settled = await Promise.allSettled([
        this.checkNetworkStatus(),
        this.testConnectivity(),
        this.checkApiHealth(),
        this.testDNS()
      ]);

      const networkStatusResult = settled[0];
      const connectivityTestResult = settled[1];
      const apiHealthCheckResult = settled[2];
      const dnsTestResult = settled[3];

      const result: DiagnosisResult = {
        networkStatus: networkStatusResult.status === 'fulfilled' ? networkStatusResult.value : this.getFailedNetworkStatus(),
        connectivityTest: connectivityTestResult.status === 'fulfilled' ? connectivityTestResult.value : this.getFailedConnectivityTest(),
        apiHealthCheck: apiHealthCheckResult.status === 'fulfilled' ? apiHealthCheckResult.value : this.getFailedApiHealthCheck(),
        dnsTest: dnsTestResult.status === 'fulfilled' ? dnsTestResult.value : this.getFailedDnsTest(),
        timestamp: Date.now()
      };

      const totalTime = Date.now() - startTime;
      console.info(`[NetworkDiagnosis] Diagnosis completed in ${totalTime}ms`);
      
      return result;
    } catch (error) {
      console.error('[NetworkDiagnosis] Diagnosis failed:', error);
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  async checkNetworkStatus(): Promise<NetworkStatus> {
    try {
      console.info('[NetworkDiagnosis] Checking network status...');
      
      const netHandle = await connection.getDefaultNet();
      const capabilities = await connection.getNetCapabilities(netHandle);
      
      const isConnected = capabilities.bearerTypes.length > 0;
      let connectionType = 'Unknown';
      
      if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
        connectionType = 'Cellular';
      } else if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
        connectionType = 'WiFi';
      } else if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET)) {
        connectionType = 'Ethernet';
      }

      console.info(`[NetworkDiagnosis] Network status: ${isConnected ? 'Connected' : 'Disconnected'} (${connectionType})`);
      
      return {
        isConnected: isConnected,
        connectionType: connectionType
      };
    } catch (error) {
      console.error('[NetworkDiagnosis] Network status check failed:', error);
      return {
        isConnected: false,
        connectionType: 'Unknown'
      };
    }
  }

  async testConnectivity(): Promise<ConnectivityTest> {
    const testUrls = [
      'https://www.baidu.com',
      'https://www.google.com',
      'https://httpbin.org/get'
    ];

    console.info('[NetworkDiagnosis] Testing connectivity...');
    
    for (const url of testUrls) {
      try {
        const result = await this.pingTest(url);
        if (result.success) {
          console.info(`[NetworkDiagnosis] Connectivity test passed: ${url} (${result.latency}ms)`);
          return result;
        }
      } catch (error) {
        console.warn(`[NetworkDiagnosis] Connectivity test failed for ${url}:`, error);
      }
    }

    console.error('[NetworkDiagnosis] All connectivity tests failed');
    return {
      success: false,
      error: 'All connectivity tests failed'
    };
  }

  async checkApiHealth(): Promise<ApiHealthCheck> {
    // 使用 Open-Meteo API 进行健康检查（免费，无需API Key）
    const apiUrl = 'https://api.open-meteo.com/v1/forecast?latitude=31.2304&longitude=121.4737&current=temperature_2m';
    
    console.info('[NetworkDiagnosis] Checking API health...');
    
    const httpRequest = http.createHttp();
    const startTime = Date.now();
    
    try {
      const response = await httpRequest.request(apiUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      const responseTime = Date.now() - startTime;
      const success = response.responseCode === 200;
      
      console.info(`[NetworkDiagnosis] API health check: ${success ? 'Healthy' : 'Unhealthy'} (${responseTime}ms, status: ${response.responseCode})`);
      
      return {
        success: success,
        responseTime: responseTime,
        statusCode: response.responseCode
      };
    } catch (error) {
      const responseTime = Date.now() - startTime;
      console.error(`[NetworkDiagnosis] API health check failed (${responseTime}ms):`, error);
      
      return {
        success: false,
        responseTime: responseTime,
        error: (error as Error).message
      };
    } finally {
      httpRequest.destroy();
    }
  }

  async testDNS(): Promise<DnsTest> {
    const testDomain = 'api.open-meteo.com';
    
    console.info(`[NetworkDiagnosis] Testing DNS resolution for ${testDomain}...`);
    
    const httpRequest = http.createHttp();
    const startTime = Date.now();
    
    try {
      // 使用HEAD请求测试DNS解析
      const response = await httpRequest.request(`https://${testDomain}`, {
        method: http.RequestMethod.HEAD,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 5000,
        readTimeout: 5000
      });

      const resolveTime = Date.now() - startTime;
      const success = response.responseCode < 500; // 4xx也算DNS解析成功
      
      console.info(`[NetworkDiagnosis] DNS test: ${success ? 'Success' : 'Failed'} (${resolveTime}ms)`);
      
      return {
        success: success,
        resolveTime: resolveTime
      };
    } catch (error) {
      const resolveTime = Date.now() - startTime;
      console.error(`[NetworkDiagnosis] DNS test failed (${resolveTime}ms):`, error);
      
      return {
        success: false,
        resolveTime: resolveTime,
        error: (error as Error).message
      };
    } finally {
      httpRequest.destroy();
    }
  }

  private async pingTest(url: string): Promise<ConnectivityTest> {
    const httpRequest = http.createHttp();
    const startTime = Date.now();
    
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.HEAD,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 5000,
        readTimeout: 5000
      });

      const latency = Date.now() - startTime;
      const success = response.responseCode < 400;
      
      return {
        success: success,
        latency: latency
      };
    } catch (error) {
      const latency = Date.now() - startTime;
      return {
        success: false,
        latency: latency,
        error: (error as Error).message
      };
    } finally {
      httpRequest.destroy();
    }
  }

  // 失败状态的默认值
  private getFailedNetworkStatus(): NetworkStatus {
    return {
      isConnected: false,
      connectionType: 'Unknown'
    };
  }

  private getFailedConnectivityTest(): ConnectivityTest {
    return {
      success: false,
      error: 'Connectivity test failed'
    };
  }

  private getFailedApiHealthCheck(): ApiHealthCheck {
    return {
      success: false,
      error: 'API health check failed'
    };
  }

  private getFailedDnsTest(): DnsTest {
    return {
      success: false,
      error: 'DNS test failed'
    };
  }

  // 诊断结果分析
  analyzeResults(result: DiagnosisResult): string[] {
    const issues: string[] = [];
    const suggestions: string[] = [];

    // 网络连接检查
    if (!result.networkStatus.isConnected) {
      issues.push('设备未连接到网络');
      suggestions.push('请检查WiFi或移动数据连接');
    }

    // 连通性检查
    if (!result.connectivityTest.success) {
      issues.push('网络连通性测试失败');
      suggestions.push('请检查网络设置或尝试切换网络');
    } else if (result.connectivityTest.latency && result.connectivityTest.latency > 3000) {
      issues.push('网络延迟较高');
      suggestions.push('网络速度较慢，可能影响应用体验');
    }

    // API健康检查
    if (!result.apiHealthCheck.success) {
      issues.push('天气API服务异常');
      suggestions.push('天气服务暂时不可用，请稍后重试');
    } else if (result.apiHealthCheck.responseTime && result.apiHealthCheck.responseTime > 5000) {
      issues.push('API响应时间过长');
      suggestions.push('天气数据加载可能较慢');
    }

    // DNS检查
    if (!result.dnsTest.success) {
      issues.push('DNS解析失败');
      suggestions.push('请检查DNS设置或尝试使用其他DNS服务器');
    }

    return [...issues, ...suggestions];
  }

  // 获取网络质量评分 (0-100)
  getNetworkQualityScore(result: DiagnosisResult): number {
    let score = 0;

    // 网络连接 (25分)
    if (result.networkStatus.isConnected) {
      score += 25;
      if (result.networkStatus.connectionType === 'WiFi') {
        score += 5; // WiFi额外加分
      }
    }

    // 连通性 (25分)
    if (result.connectivityTest.success) {
      score += 20;
      if (result.connectivityTest.latency && result.connectivityTest.latency < 1000) {
        score += 5; // 低延迟额外加分
      }
    }

    // API健康 (30分)
    if (result.apiHealthCheck.success) {
      score += 25;
      if (result.apiHealthCheck.responseTime && result.apiHealthCheck.responseTime < 2000) {
        score += 5; // 快速响应额外加分
      }
    }

    // DNS (20分)
    if (result.dnsTest.success) {
      score += 15;
      if (result.dnsTest.resolveTime && result.dnsTest.resolveTime < 500) {
        score += 5; // 快速解析额外加分
      }
    }

    return Math.min(100, Math.max(0, score));
  }
}
