# 基金对比功能 API 文档

## 概述

本文档描述了基金对比功能所使用的API接口、数据结构和集成方法。

## API 端点

### 基础信息

- **基础URL**: `http://154.44.25.92:8080`
- **超时配置**: 连接45秒，接收120秒，发送45秒
- **重试机制**: 最大重试5次，重试间隔2秒
- **编码**: UTF-8

### 获取基金对比数据

```http
GET /api/public/fund_portfolio_em?symbol={fundCode}&symbol={fundCode}&...
```

**参数:**
- `symbol` (重复): 基金代码，支持多个

**示例:**
```http
GET /api/public/fund_portfolio_em?symbol=000001&symbol=110022
```

**响应:**
```json
{
  "data": [
    {
      "fund_code": "000001",
      "fund_name": "华夏成长混合",
      "fund_type": "混合型",
      "total_return": "15.6%",
      "annualized_return": "14.2%",
      "volatility": "18.6%",
      "sharpe_ratio": "0.763",
      "max_drawdown": "-21.3%",
      "ranking": 15,
      "update_date": "2024-01-15",
      "benchmark": "沪深300",
      "beat_benchmark_percent": "2.3%",
      "beat_category_percent": "5.7%",
      "category": "混合型",
      "category_ranking": 23,
      "total_category_count": 456
    }
  ]
}
```

### 获取基金历史数据

```http
GET /api/public/fund_history_info_em?symbol={fundCode}&period={period}
```

**参数:**
- `symbol`: 基金代码
- `period`: 时间段 (1=1个月, 3=3个月, 6=6个月, 12=1年, 36=3年)

**示例:**
```http
GET /api/public/fund_history_info_em?symbol=000001&period=12
```

**响应:**
```json
{
  "fund_name": "华夏成长混合",
  "fund_type": "混合型",
  "data": [
    {
      "date": "2024-01-01",
      "nav": "2.5432",
      "cumulative_nav": "3.1234",
      "daily_return": "0.0156"
    }
  ]
}
```

### 获取基金实时净值

```http
GET /api/public/fund_value_em?symbol={fundCode}
```

**参数:**
- `symbol`: 基金代码

**响应:**
```json
{
  "fund_code": "000001",
  "fund_name": "华夏成长混合",
  "unit_nav": "2.5432",
  "accumulated_nav": "3.1234",
  "nav_date": "2024-01-15",
  "daily_return": "0.0156"
}
```

## 数据结构

### MultiDimensionalComparisonCriteria

```dart
class MultiDimensionalComparisonCriteria {
  final List<String> fundCodes;        // 基金代码列表 (2-5个)
  final List<RankingPeriod> periods;   // 时间段列表
  final ComparisonMetric metric;       // 对比指标
  final bool includeStatistics;        // 是否包含统计信息
  final ComparisonSortBy sortBy;       // 排序方式
  final String? name;                  // 对比名称 (可选)
}
```

**验证规则:**
- 基金数量: 2-5个
- 时间段: 最多5个
- 必填字段: fundCodes, periods, metric

### FundRanking

```dart
class FundRanking {
  final String fundCode;              // 基金代码
  final String fundName;              // 基金名称
  final String fundType;              // 基金类型
  final double totalReturn;           // 累计收益率
  final double annualizedReturn;      // 年化收益率
  final double volatility;            // 波动率
  final double sharpeRatio;           // 夏普比率
  final double maxDrawdown;           // 最大回撤
  final int ranking;                  // 排名
  final RankingPeriod period;         // 时间段
  final String updateDate;            // 更新日期
  final String benchmark;             // 基准指数
  final double beatBenchmarkPercent;  // 超越基准百分比
  final double beatCategoryPercent;   // 超越同类百分比
  final String category;              // 基金分类
  final int categoryRanking;          // 同类排名
  final int totalCategoryCount;       // 同类总数
}
```

### ComparisonResult

```dart
class ComparisonResult {
  final MultiDimensionalComparisonCriteria criteria;  // 对比条件
  final List<FundComparisonData> fundData;          // 基金数据
  final ComparisonStatistics statistics;             // 统计信息
  final DateTime? lastUpdated;                      // 最后更新时间
  final bool hasError;                              // 是否有错误
  final String? errorMessage;                       // 错误信息
}
```

### ComparisonStatistics

```dart
class ComparisonStatistics {
  final double averageReturn;            // 平均收益率
  final double maxReturn;                // 最高收益率
  final double minReturn;                // 最低收益率
  final double averageVolatility;        // 平均波动率
  final double maxVolatility;            // 最高波动率
  final double minVolatility;            // 最低波动率
  final double averageSharpeRatio;       // 平均夏普比率
  final double returnStdDev;             // 收益标准差
  final Map<String, Map<String, double>> correlationMatrix; // 相关性矩阵
}
```

## 集成示例

### 基础API调用

```dart
import 'package:baostock/src/core/network/fund_api_client.dart';

final apiClient = FundApiClient();

// 获取基金对比数据
try {
  final result = await apiClient.getFundsForComparison(['000001', '110022']);
  print('基金数据: $result');
} catch (e) {
  print('获取数据失败: $e');
}
```

### 批量API调用

```dart
// 并行获取多只基金数据
final futures = fundCodes.map((code) =>
  apiClient.getFundsForComparison([code])
).toList();

final results = await Future.wait(futures);
```

### 带重试的API调用

```dart
import 'package:baostock/src/features/fund/presentation/utils/comparison_error_handler.dart';

final result = await ComparisonErrorHandler.executeWithErrorHandling(
  () => apiClient.getFundsForComparison(fundCodes),
  fallbackValue: defaultData,
  retryConfig: RetryConfig(maxRetries: 3),
);
```

## 错误处理

### HTTP状态码

| 状态码 | 含义 | 处理方式 |
|--------|------|----------|
| 200 | 成功 | 正常处理 |
| 400 | 请求参数错误 | 检查参数格式 |
| 401 | 未授权 | 检查身份认证 |
| 403 | 权限不足 | 联系管理员 |
| 404 | 资源不存在 | 检查基金代码 |
| 429 | 请求频率限制 | 降低请求频率 |
| 500 | 服务器内部错误 | 重试或联系支持 |
| 502 | 网关错误 | 重试 |
| 503 | 服务不可用 | 等待后重试 |
| 504 | 网关超时 | 增加超时时间 |

### 错误响应格式

```json
{
  "error": "错误描述",
  "message": "详细错误信息",
  "code": "ERROR_CODE",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### 错误处理示例

```dart
try {
  final result = await apiClient.getFundsForComparison(fundCodes);
  // 处理成功响应
} on SocketException catch (e) {
  // 网络错误
  throw ComparisonError(
    type: ComparisonErrorType.network,
    message: '网络连接失败',
    details: e.toString(),
  );
} on TimeoutException catch (e) {
  // 超时错误
  throw ComparisonError(
    type: ComparisonErrorType.timeout,
    message: '请求超时',
    details: '超时时间: ${e.duration}',
  );
} on HttpException catch (e) {
  // HTTP错误
  final statusCode = int.tryParse(e.message);
  throw ComparisonErrorHandler.parseApiError(e.response, statusCode);
}
```

## 缓存策略

### 缓存配置

```dart
class CacheConfig {
  static const Duration defaultExpiration = Duration(hours: 1);
  static const Duration maxExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // 最大缓存条目数
}
```

### 缓存键生成

```dart
String generateCacheKey(MultiDimensionalComparisonCriteria criteria) {
  final sortedFunds = List<String>.from(criteria.fundCodes)..sort();
  final sortedPeriods = List<String>.from(
    criteria.periods.map((p) => p.name),
  )..sort();

  return jsonEncode({
    'funds': sortedFunds,
    'periods': sortedPeriods,
    'metric': criteria.metric.name,
  });
}
```

### 缓存使用示例

```dart
// 检查缓存
final cacheKey = generateCacheKey(criteria);
final cachedResult = cacheManager.get(cacheKey);

if (cachedResult != null && !isCacheExpired(cachedResult)) {
  return cachedResult;
}

// 获取新数据并缓存
final result = await apiClient.getFundsForComparison(criteria.fundCodes);
await cacheManager.set(cacheKey, result, expiration: Duration(hours: 1));
```

## 性能优化

### 请求优化

1. **批量请求**: 一次请求多只基金数据
2. **并行请求**: 同时请求不同时间段数据
3. **缓存优先**: 优先使用缓存数据
4. **增量更新**: 只更新变化的数据

### 数据处理优化

```dart
// 使用Isolate处理大量数据
final result = await compute(_processLargeDataSet, rawData);

// 流式处理大数据集
final stream = _processDataStream(apiResponse);
await for (final batch in stream) {
  updateUI(batch);
}
```

### 内存管理

```dart
// 及时释放不需要的资源
class ComparisonManager {
  List<FundData> _data = [];

  Future<void> loadData() async {
    _data = await apiClient.getData();
  }

  void dispose() {
    _data.clear(); // 释放内存
  }
}
```

## 测试

### API测试

```dart
void main() {
  group('Fund API Tests', () {
    test('should get fund comparison data', () async {
      final apiClient = FundApiClient();
      final result = await apiClient.getFundsForComparison(['000001']);

      expect(result, isNotNull);
      expect(result['data'], isNotEmpty);
    });

    test('should handle network errors', () async {
      final apiClient = FundApiClient();

      expect(
        () => apiClient.getFundsForComparison(['INVALID_CODE']),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

### Mock数据

```dart
class MockFundApiClient extends Mock implements FundApiClient {
  @override
  Future<Map<String, dynamic>> getFundsForComparison(List<String> fundCodes) async {
    return {
      'data': [
        {
          'fund_code': fundCodes.first,
          'fund_name': 'Mock Fund',
          'total_return': '10.5%',
        }
      ]
    };
  }
}
```

## 监控和日志

### 请求监控

```dart
class ApiMonitor {
  static void logRequest(String endpoint, Map<String, dynamic> params) {
    AppLogger.info('API请求', {
      'endpoint': endpoint,
      'params': params,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void logResponse(String endpoint, int statusCode, int duration) {
    AppLogger.info('API响应', {
      'endpoint': endpoint,
      'statusCode': statusCode,
      'duration': '${duration}ms',
    });
  }
}
```

### 性能监控

```dart
class PerformanceMonitor {
  static void trackApiCall(String apiName, Duration duration) {
    // 发送性能数据到监控系统
    Analytics.track('api_call', {
      'api_name': apiName,
      'duration_ms': duration.inMilliseconds,
    });
  }
}
```

## 安全考虑

### 数据验证

```dart
void validateFundCode(String fundCode) {
  if (!RegExp(r'^\d{6}$').hasMatch(fundCode)) {
    throw ArgumentError('无效的基金代码格式');
  }
}

void validateResponse(Map<String, dynamic> response) {
  if (response['data'] == null) {
    throw Exception('API响应格式异常');
  }
}
```

### 速率限制

```dart
class RateLimiter {
  final Map<String, DateTime> _lastRequests = {};
  final Duration _minInterval;

  RateLimiter(this._minInterval);

  Future<void> waitForAllowed(String endpoint) async {
    final lastRequest = _lastRequests[endpoint];
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      if (elapsed < _minInterval) {
        await Future.delayed(_minInterval - elapsed);
      }
    }
    _lastRequests[endpoint] = DateTime.now();
  }
}
```

---

*API版本: v1.0*
*最后更新: 2024年1月*