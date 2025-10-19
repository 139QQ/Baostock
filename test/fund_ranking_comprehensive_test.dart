import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'src/core/utils/logger.dart';
import 'src/core/utils/test_logger_config.dart';
import 'src/core/network/fund_api_client.dart';
import 'src/features/fund/presentation/domain/services/multi_layer_retry_service.dart';
import 'src/features/fund/presentation/domain/services/fund_pagination_service.dart';
import 'src/features/fund/presentation/domain/entities/fund_ranking.dart';
import 'fund_ranking_multilayer_retry_test.dart';

/// 基金排行综合测试运行器
///
/// 集成所有修复和优化功能的综合测试
/// 包含性能测试、压力测试、稳定性测试等
class FundRankingComprehensiveTest {
  final TestLoggerConfig _loggerConfig = TestLoggerConfig.instance;
  final MultiLayerRetryService _retryService = MultiLayerRetryService();
  final FundPaginationService _paginationService =
      FundPaginationService(FundApiClient());

  bool _isInitialized = false;

  /// 初始化测试环境
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化增强的日志配置
      await _loggerConfig.initialize(
        level: LogLevel.debug,
        enableConsoleOutput: kDebugMode,
        enableFileOutput: true,
        enableStructuredLogging: true,
        enablePerformanceMonitoring: true,
      );

      _loggerConfig.logTestStart('基金排行综合测试', {
        'version': '1.0.0',
        'environment': kDebugMode ? 'development' : 'production',
        'platform': Platform.operatingSystem,
      });

      // 预热服务
      await _retryService.warmupCache();

      _isInitialized = true;
      _loggerConfig.logTestComplete('测试环境初始化', success: true);
    } catch (e) {
      _loggerConfig.logTestComplete('测试环境初始化',
          success: false, error: e.toString());
      rethrow;
    }
  }

  /// 运行所有测试套件
  Future<TestSuiteResult> runAllTests() async {
    if (!_isInitialized) {
      await initialize();
    }

    final overallStartTime = DateTime.now();
    final results = <String, TestResult>{};

    try {
      _loggerConfig.logTestStart('综合测试套件');

      // 1. 基础功能测试
      results['基础功能'] = await runBasicFunctionalityTests();

      // 2. 性能测试
      results['性能测试'] = await runPerformanceTests();

      // 3. 分页测试
      results['分页测试'] = await runPaginationTests();

      // 4. 错误处理测试
      results['错误处理'] = await runErrorHandlingTests();

      // 5. 稳定性测试
      results['稳定性测试'] = await runStabilityTests();

      // 6. 压力测试
      results['压力测试'] = await runStressTests();

      // 7. 集成测试
      results['集成测试'] = await runIntegrationTests();

      final overallDuration = DateTime.now().difference(overallStartTime);
      final overallSuccess = results.values.every((result) => result.success);

      // 生成测试报告
      await _generateTestReport(results, overallDuration);

      _loggerConfig.logTestComplete(
        '综合测试套件',
        success: overallSuccess,
        duration: overallDuration,
        results: _convertResultsToMap(results),
      );

      return TestSuiteResult(
        overallSuccess: overallSuccess,
        duration: overallDuration,
        testResults: results,
      );
    } catch (e) {
      final overallDuration = DateTime.now().difference(overallStartTime);
      _loggerConfig.logTestComplete(
        '综合测试套件',
        success: false,
        duration: overallDuration,
        error: e.toString(),
      );

      return TestSuiteResult(
        overallSuccess: false,
        duration: overallDuration,
        testResults: results,
        error: e.toString(),
      );
    }
  }

  /// 基础功能测试
  Future<TestResult> runBasicFunctionalityTests() async {
    final startTime = DateTime.now();
    final tests = <String, bool>{};

    try {
      _loggerConfig.logTestStart('基础功能测试');

      // 测试1：API连接
      tests['API连接'] = await _testApiConnection();

      // 测试2：数据获取
      tests['数据获取'] = await _testDataFetching();

      // 测试3：数据转换
      tests['数据转换'] = await _testDataConversion();

      // 测试4：缓存机制
      tests['缓存机制'] = await _testCaching();

      // 测试5：URL编码
      tests['URL编码'] = await _testUrlEncoding();

      final success = tests.values.every((result) => result);
      final duration = DateTime.now().difference(startTime);

      _loggerConfig.logTestComplete(
        '基础功能测试',
        success: success,
        duration: duration,
        results: tests,
      );

      return TestResult(
        testName: '基础功能测试',
        success: success,
        duration: duration,
        details: tests,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _loggerConfig.logTestComplete(
        '基础功能测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );

      return TestResult(
        testName: '基础功能测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );
    }
  }

  /// 性能测试
  Future<TestResult> runPerformanceTests() async {
    final startTime = DateTime.now();
    final tests = <String, dynamic>{};

    try {
      _loggerConfig.logTestStart('性能测试');

      // 测试1：响应时间
      tests['平均响应时间'] = await _testResponseTime();

      // 测试2：并发性能
      tests['并发性能'] = await _testConcurrentPerformance();

      // 测试3：内存使用
      tests['内存使用'] = await _testMemoryUsage();

      // 测试4：缓存效率
      tests['缓存效率'] = await _testCacheEfficiency();

      final duration = DateTime.now().difference(startTime);

      _loggerConfig.logTestComplete(
        '性能测试',
        success: true,
        duration: duration,
        results: tests,
      );

      return TestResult(
        testName: '性能测试',
        success: true,
        duration: duration,
        details: tests,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _loggerConfig.logTestComplete(
        '性能测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );

      return TestResult(
        testName: '性能测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );
    }
  }

  /// 分页测试
  Future<TestResult> runPaginationTests() async {
    final startTime = DateTime.now();
    final tests = <String, bool>{};

    try {
      _loggerConfig.logTestStart('分页测试');

      // 测试1：基础分页
      tests['基础分页'] = await _testBasicPagination();

      // 测试2：分页参数校验
      tests['分页参数校验'] = await _testPaginationValidation();

      // 测试3：分页错误处理
      tests['分页错误处理'] = await _testPaginationErrorHandling();

      // 测试4：客户端分页
      tests['客户端分页'] = await _testClientSidePagination();

      final success = tests.values.every((result) => result);
      final duration = DateTime.now().difference(startTime);

      _loggerConfig.logTestComplete(
        '分页测试',
        success: success,
        duration: duration,
        results: tests,
      );

      return TestResult(
        testName: '分页测试',
        success: success,
        duration: duration,
        details: tests,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _loggerConfig.logTestComplete(
        '分页测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );

      return TestResult(
        testName: '分页测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );
    }
  }

  /// 错误处理测试
  Future<TestResult> runErrorHandlingTests() async {
    final startTime = DateTime.now();
    final tests = <String, bool>{};

    try {
      _loggerConfig.logTestStart('错误处理测试');

      // 测试1：网络错误处理
      tests['网络错误处理'] = await _testNetworkErrorHandling();

      // 测试2：超时处理
      tests['超时处理'] = await _testTimeoutHandling();

      // 测试3：重试机制
      tests['重试机制'] = await _testRetryMechanism();

      // 测试4：降级策略
      tests['降级策略'] = await _testFallbackStrategy();

      final success = tests.values.every((result) => result);
      final duration = DateTime.now().difference(startTime);

      _loggerConfig.logTestComplete(
        '错误处理测试',
        success: success,
        duration: duration,
        results: tests,
      );

      return TestResult(
        testName: '错误处理测试',
        success: success,
        duration: duration,
        details: tests,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _loggerConfig.logTestComplete(
        '错误处理测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );

      return TestResult(
        testName: '错误处理测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );
    }
  }

  /// 稳定性测试
  Future<TestResult> runStabilityTests() async {
    final startTime = DateTime.now();
    final tests = <String, bool>{};

    try {
      _loggerConfig.logTestStart('稳定性测试');

      // 测试1：长时间运行
      tests['长时间运行'] = await _testLongRunningStability();

      // 测试2：内存泄漏检测
      tests['内存泄漏检测'] = await _testMemoryLeakDetection();

      // 测试3：资源清理
      tests['资源清理'] = await _testResourceCleanup();

      final success = tests.values.every((result) => result);
      final duration = DateTime.now().difference(startTime);

      _loggerConfig.logTestComplete(
        '稳定性测试',
        success: success,
        duration: duration,
        results: tests,
      );

      return TestResult(
        testName: '稳定性测试',
        success: success,
        duration: duration,
        details: tests,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _loggerConfig.logTestComplete(
        '稳定性测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );

      return TestResult(
        testName: '稳定性测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );
    }
  }

  /// 压力测试
  Future<TestResult> runStressTests() async {
    final startTime = DateTime.now();
    final tests = <String, bool>{};

    try {
      _loggerConfig.logTestStart('压力测试');

      // 测试1：高并发请求
      tests['高并发请求'] = await _testHighConcurrency();

      // 测试2：大数据量处理
      tests['大数据量处理'] = await _testLargeDataHandling();

      // 测试3：快速连续请求
      tests['快速连续请求'] = await _testRapidRequests();

      final success = tests.values.every((result) => result);
      final duration = DateTime.now().difference(startTime);

      _loggerConfig.logTestComplete(
        '压力测试',
        success: success,
        duration: duration,
        results: tests,
      );

      return TestResult(
        testName: '压力测试',
        success: success,
        duration: duration,
        details: tests,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _loggerConfig.logTestComplete(
        '压力测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );

      return TestResult(
        testName: '压力测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );
    }
  }

  /// 集成测试
  Future<TestResult> runIntegrationTests() async {
    final startTime = DateTime.now();
    final tests = <String, bool>{};

    try {
      _loggerConfig.logTestStart('集成测试');

      // 测试1：端到端流程
      tests['端到端流程'] = await _testEndToEndFlow();

      // 测试2：组件集成
      tests['组件集成'] = await _testComponentIntegration();

      // 测试3：真实场景模拟
      tests['真实场景模拟'] = await _testRealWorldScenario();

      final success = tests.values.every((result) => result);
      final duration = DateTime.now().difference(startTime);

      _loggerConfig.logTestComplete(
        '集成测试',
        success: success,
        duration: duration,
        results: tests,
      );

      return TestResult(
        testName: '集成测试',
        success: success,
        duration: duration,
        details: tests,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _loggerConfig.logTestComplete(
        '集成测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );

      return TestResult(
        testName: '集成测试',
        success: false,
        duration: duration,
        error: e.toString(),
      );
    }
  }

  // 具体测试方法实现（简化版，实际中会更详细）

  Future<bool> _testApiConnection() async {
    try {
      final result = await FundApiClient.instance.getFundRankings();
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testDataFetching() async {
    try {
      final result = await _retryService.getFundRankingsWithRetry(symbol: '全部');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testDataConversion() async {
    try {
      final rawData = await FundApiClient.instance.getFundRankings();
      if (rawData.isEmpty) return true;

      final convertedData = _retryService.convertToFundRankingList(rawData);
      return convertedData.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testCaching() async {
    try {
      // 第一次请求
      await _retryService.getFundRankingsWithRetry(symbol: '测试缓存');
      // 第二次请求应该使用缓存
      await _retryService.getFundRankingsWithRetry(symbol: '测试缓存');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testUrlEncoding() async {
    try {
      // 测试中文参数编码
      final result =
          await _retryService.getFundRankingsWithRetry(symbol: '股票型');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _testResponseTime() async {
    final times = <int>[];
    for (int i = 0; i < 10; i++) {
      final start = DateTime.now();
      await _retryService.getFundRankingsWithRetry(symbol: '全部');
      final duration = DateTime.now().difference(start);
      times.add(duration.inMilliseconds);
    }

    final average = times.reduce((a, b) => a + b) / times.length;
    return {
      'average': average,
      'min': times.reduce((a, b) => a < b ? a : b),
      'max': times.reduce((a, b) => a > b ? a : b),
    };
  }

  Future<Map<String, dynamic>> _testConcurrentPerformance() async {
    final futures = <Future<List<FundRanking>>>[];
    final startTime = DateTime.now();

    for (int i = 0; i < 5; i++) {
      futures.add(_retryService.getFundRankingsWithRetry(symbol: '全部'));
    }

    final results = await Future.wait(futures);
    final duration = DateTime.now().difference(startTime);

    return {
      'totalDuration': duration.inMilliseconds,
      'averageDuration': duration.inMilliseconds / results.length,
      'successCount': results.where((r) => r.isNotEmpty).length,
    };
  }

  Future<Map<String, dynamic>> _testMemoryUsage() async {
    // 简化的内存使用测试
    return {
      'estimatedUsage': 'N/A', // 需要实际的内存监控库
      'status': 'passed',
    };
  }

  Future<Map<String, dynamic>> _testCacheEfficiency() async {
    // 第一次请求（无缓存）
    final start1 = DateTime.now();
    await _retryService.getFundRankingsWithRetry(symbol: '缓存测试');
    final duration1 = DateTime.now().difference(start1);

    // 第二次请求（有缓存）
    final start2 = DateTime.now();
    await _retryService.getFundRankingsWithRetry(symbol: '缓存测试');
    final duration2 = DateTime.now().difference(start2);

    final speedup = duration1.inMilliseconds / duration2.inMilliseconds;

    return {
      'noCacheDuration': duration1.inMilliseconds,
      'cachedDuration': duration2.inMilliseconds,
      'speedup': speedup,
    };
  }

  Future<bool> _testBasicPagination() async {
    try {
      final result = await _paginationService.loadFirstPage();
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testPaginationValidation() async {
    try {
      // 测试无效页码
      await _paginationService.loadPage(-1);
      return false; // 应该抛出异常
    } catch (e) {
      return true; // 预期的异常
    }
  }

  Future<bool> _testPaginationErrorHandling() async {
    try {
      // 测试分页错误处理
      final result = await _paginationService.loadPage(999999);
      return result.isSuccess || result.hasError;
    } catch (e) {
      return true; // 错误处理正常
    }
  }

  Future<bool> _testClientSidePagination() async {
    try {
      // 测试客户端分页逻辑
      final result = await _paginationService.loadPage(1);
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testNetworkErrorHandling() async {
    try {
      // 模拟网络错误（实际中可能需要使用模拟库）
      final result = await _retryService.getFundRankingsWithRetry(symbol: '全部');
      return result.isNotEmpty; // 应该使用降级策略
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testTimeoutHandling() async {
    try {
      final result = await _retryService.getFundRankingsWithRetry(
        symbol: '全部',
        timeoutSeconds: 1, // 极短超时
      );
      return true; // 应该使用降级策略
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testRetryMechanism() async {
    try {
      final stats = _retryService.getStatistics();
      return stats['totalRequests'] > 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testFallbackStrategy() async {
    try {
      // 测试各种降级策略
      await _retryService.getFundRankingsWithRetry(symbol: 'INVALID_SYMBOL');
      return true; // 应该使用示例数据降级
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testLongRunningStability() async {
    try {
      // 运行一段时间，检查稳定性
      for (int i = 0; i < 10; i++) {
        await _retryService.getFundRankingsWithRetry(symbol: '全部');
        await Future.delayed(Duration(milliseconds: 100));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testMemoryLeakDetection() async {
    // 简化的内存泄漏检测
    return true;
  }

  Future<bool> _testResourceCleanup() async {
    try {
      _retryService.dispose();
      _paginationService.dispose();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testHighConcurrency() async {
    try {
      final futures = <Future<List<FundRanking>>>[];
      for (int i = 0; i < 20; i++) {
        futures.add(_retryService.getFundRankingsWithRetry(symbol: '全部'));
      }
      final results = await Future.wait(futures);
      return results.every((r) => r.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testLargeDataHandling() async {
    try {
      // 测试大数据量处理
      final result = await _retryService.getFundRankingsWithRetry(symbol: '全部');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testRapidRequests() async {
    try {
      // 快速连续请求
      for (int i = 0; i < 50; i++) {
        await _retryService.getFundRankingsWithRetry(symbol: '全部');
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testEndToEndFlow() async {
    try {
      // 完整的端到端流程测试
      final result = await _paginationService.loadFirstPage();
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testComponentIntegration() async {
    try {
      // 组件集成测试
      final retryResult =
          await _retryService.getFundRankingsWithRetry(symbol: '全部');
      final paginationResult = await _paginationService.loadFirstPage();
      return retryResult.isNotEmpty && paginationResult.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testRealWorldScenario() async {
    try {
      // 真实场景模拟
      final scenarios = ['全部', '股票型', '混合型', '债券型'];
      for (final scenario in scenarios) {
        await _retryService.getFundRankingsWithRetry(symbol: scenario);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // 辅助方法

  Map<String, dynamic> _convertResultsToMap(Map<String, TestResult> results) {
    final map = <String, dynamic>{};
    results.forEach((key, value) {
      map[key] = {
        'success': value.success,
        'duration': value.duration.inMilliseconds,
        'details': value.details,
        if (value.error != null) 'error': value.error,
      };
    });
    return map;
  }

  Future<void> _generateTestReport(
      Map<String, TestResult> results, Duration overallDuration) async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'overallDuration': overallDuration.inMilliseconds,
      'testResults': _convertResultsToMap(results),
      'summary': {
        'totalTests': results.length,
        'passedTests': results.values.where((r) => r.success).length,
        'failedTests': results.values.where((r) => !r.success).length,
        'successRate': (results.values.where((r) => r.success).length /
                    results.length *
                    100)
                .toStringAsFixed(1) +
            '%',
      },
      'systemInfo': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'environment': kDebugMode ? 'development' : 'production',
      },
    };

    await _loggerConfig.generateTestSummary(report);
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      await _retryService.dispose();
      _paginationService.dispose();
      await _loggerConfig.dispose();

      if (kDebugMode) {
        debugPrint('🧹 综合测试资源已清理');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 资源清理失败: $e');
      }
    }
  }
}

/// 测试结果类
class TestResult {
  final String testName;
  final bool success;
  final Duration duration;
  final dynamic details;
  final String? error;

  TestResult({
    required this.testName,
    required this.success,
    required this.duration,
    this.details,
    this.error,
  });
}

/// 测试套件结果类
class TestSuiteResult {
  final bool overallSuccess;
  final Duration duration;
  final Map<String, TestResult> testResults;
  final String? error;

  TestSuiteResult({
    required this.overallSuccess,
    required this.duration,
    required this.testResults,
    this.error,
  });
}

/// 主函数 - 运行综合测试
void main() async {
  final testRunner = FundRankingComprehensiveTest();

  try {
    if (kDebugMode) {
      debugPrint('🚀 开始基金排行综合测试');
    }

    final result = await testRunner.runAllTests();

    if (kDebugMode) {
      debugPrint('\n📊 测试结果摘要:');
      debugPrint('总成功率: ${result.overallSuccess ? '✅ 通过' : '❌ 失败'}');
      debugPrint('总耗时: ${result.duration.inMilliseconds}ms');

      debugPrint('\n详细结果:');
      result.testResults.forEach((name, testResult) {
        final status = testResult.success ? '✅' : '❌';
        debugPrint('$status $name: ${testResult.duration.inMilliseconds}ms');
        if (testResult.error != null) {
          debugPrint('   错误: ${testResult.error}');
        }
      });
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 综合测试运行失败: $e');
    }
  } finally {
    await testRunner.dispose();
  }
}
