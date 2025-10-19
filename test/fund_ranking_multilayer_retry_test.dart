import 'dart:async';

import 'package:flutter/foundation.dart';
import 'src/features/fund/presentation/domain/services/multi_layer_retry_service.dart';
import 'src/features/fund/domain/entities/fund_ranking.dart';

/// 基金排行多层重试机制测试
///
/// 测试多层重试服务的各种场景，包括：
/// 1. 正常数据获取
/// 2. 网络错误重试
/// 3. 缓存降级
/// 4. 备用API切换
/// 5. 示例数据生成
/// 6. 性能统计
void main() async {
  // 初始化日志 - 使用现有的配置方法
  // AppLogger 已经在应用启动时初始化

  if (kDebugMode) {
    debugPrint('🧪 开始基金排行多层重试机制测试');
  }

  await runMultiLayerRetryTests();

  if (kDebugMode) {
    debugPrint('✅ 多层重试机制测试完成');
  }
}

/// 运行多层重试测试
Future<void> runMultiLayerRetryTests() async {
  final retryService = MultiLayerRetryService();

  try {
    // 测试1：正常数据获取
    await testNormalDataFetching(retryService);

    // 测试2：缓存机制
    await testCacheMechanism(retryService);

    // 测试3：统计信息
    await testStatistics(retryService);

    // 测试4：预热缓存
    await testCacheWarmup(retryService);

    // 测试5：错误处理
    await testErrorHandling(retryService);

    // 测试6：性能测试
    await testPerformance(retryService);
  } finally {
    // 清理资源
    retryService.dispose();
  }
}

/// 测试1：正常数据获取
Future<void> testNormalDataFetching(MultiLayerRetryService service) async {
  if (kDebugMode) {
    debugPrint('\n📋 测试1: 正常数据获取');
  }

  try {
    final startTime = DateTime.now();
    final result = await service.getFundRankingsWithRetry(
      symbol: '全部',
      forceRefresh: false,
      timeoutSeconds: 30,
    );

    final duration = DateTime.now().difference(startTime);

    if (kDebugMode) {
      debugPrint('✅ 数据获取成功: ${result.length}条记录');
      debugPrint('⏱️ 耗时: ${duration.inMilliseconds}ms');

      if (result.isNotEmpty) {
        final firstFund = result.first;
        debugPrint('📊 第一只基金: ${firstFund.fundName} (${firstFund.fundCode})');
        debugPrint('💰 单位净值: ${firstFund.unitNav.toStringAsFixed(4)}');
        debugPrint('📈 日收益率: ${firstFund.dailyReturn.toStringAsFixed(2)}%');
      }
    }

    // 验证数据质量
    _validateDataQuality(result, '正常数据获取');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 测试1失败: $e');
    }
    rethrow;
  }
}

/// 测试2：缓存机制
Future<void> testCacheMechanism(MultiLayerRetryService service) async {
  if (kDebugMode) {
    debugPrint('\n📋 测试2: 缓存机制');
  }

  try {
    // 第一次请求（应该从API获取）
    final startTime1 = DateTime.now();
    final result1 = await service.getFundRankingsWithRetry(symbol: '股票型');
    final duration1 = DateTime.now().difference(startTime1);

    if (kDebugMode) {
      debugPrint(
          '🔄 第一次请求: ${result1.length}条, 耗时: ${duration1.inMilliseconds}ms');
    }

    // 第二次请求（应该从缓存获取）
    final startTime2 = DateTime.now();
    final result2 = await service.getFundRankingsWithRetry(symbol: '股票型');
    final duration2 = DateTime.now().difference(startTime2);

    if (kDebugMode) {
      debugPrint(
          '💾 第二次请求: ${result2.length}条, 耗时: ${duration2.inMilliseconds}ms');

      // 验证缓存效果
      final speedup = duration1.inMilliseconds / duration2.inMilliseconds;
      debugPrint('🚀 缓存加速比: ${speedup.toStringAsFixed(2)}x');

      if (speedup > 5.0) {
        debugPrint('✅ 缓存机制工作正常');
      } else {
        debugPrint('⚠️ 缓存机制可能存在问题');
      }
    }

    // 强制刷新测试
    final startTime3 = DateTime.now();
    final result3 = await service.getFundRankingsWithRetry(
      symbol: '股票型',
      forceRefresh: true,
    );
    final duration3 = DateTime.now().difference(startTime3);

    if (kDebugMode) {
      debugPrint(
          '🔄 强制刷新: ${result3.length}条, 耗时: ${duration3.inMilliseconds}ms');
    }

    _validateDataQuality(result1, '缓存测试-第一次请求');
    _validateDataQuality(result2, '缓存测试-第二次请求');
    _validateDataQuality(result3, '缓存测试-强制刷新');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 测试2失败: $e');
    }
    rethrow;
  }
}

/// 测试3：统计信息
Future<void> testStatistics(MultiLayerRetryService service) async {
  if (kDebugMode) {
    debugPrint('\n📋 测试3: 统计信息');
  }

  try {
    // 执行几次请求以产生统计数据
    await service.getFundRankingsWithRetry(symbol: '混合型');
    await service.getFundRankingsWithRetry(symbol: '混合型'); // 重复请求测试缓存
    await service.getFundRankingsWithRetry(symbol: '债券型');

    // 获取统计信息
    final stats = service.getStatistics();

    if (kDebugMode) {
      debugPrint('📊 重试服务统计信息:');
      debugPrint('  总请求数: ${stats['totalRequests']}');
      debugPrint('  成功率: ${stats['successRate']?.toStringAsFixed(2)}%');
      debugPrint('  失败次数: ${stats['failureCount']}');
      debugPrint(
          '  平均请求时间: ${stats['averageRequestTime']?.toStringAsFixed(2)}ms');
      debugPrint('  缓存大小: ${stats['cacheSize']}');

      debugPrint('  成功来源统计:');
      final successSources = stats['successSources'] as Map<String, int>;
      successSources.forEach((source, count) {
        debugPrint('    $source: $count 次');
      });
    }

    // 验证统计信息的合理性
    final totalRequests = stats['totalRequests'] as int;
    final successRate = stats['successRate'] as double;

    if (totalRequests > 0 && successRate >= 0.0 && successRate <= 100.0) {
      if (kDebugMode) {
        debugPrint('✅ 统计信息验证通过');
      }
    } else {
      if (kDebugMode) {
        debugPrint('❌ 统计信息验证失败');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 测试3失败: $e');
    }
    rethrow;
  }
}

/// 测试4：预热缓存
Future<void> testCacheWarmup(MultiLayerRetryService service) async {
  if (kDebugMode) {
    debugPrint('\n📋 测试4: 缓存预热');
  }

  try {
    // 清空现有缓存
    service.clearCache();
    if (kDebugMode) {
      debugPrint('🧹 缓存已清空');
    }

    // 执行预热
    final startTime = DateTime.now();
    await service.warmupCache();
    final duration = DateTime.now().difference(startTime);

    if (kDebugMode) {
      debugPrint('🔥 缓存预热完成，耗时: ${duration.inMilliseconds}ms');
    }

    // 验证预热效果
    final stats = service.getStatistics();
    final cacheSize = stats['cacheSize'] as int;

    if (kDebugMode) {
      debugPrint('💾 预热后缓存大小: $cacheSize');
    }

    // 测试预热后的请求速度
    final testStartTime = DateTime.now();
    final result = await service.getFundRankingsWithRetry(symbol: '全部');
    final testDuration = DateTime.now().difference(testStartTime);

    if (kDebugMode) {
      debugPrint('⚡ 预热后请求速度: ${testDuration.inMilliseconds}ms');

      if (testDuration.inMilliseconds < 100) {
        debugPrint('✅ 预热效果良好');
      } else {
        debugPrint('⚠️ 预热效果一般');
      }
    }

    _validateDataQuality(result, '缓存预热测试');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 测试4失败: $e');
    }
    rethrow;
  }
}

/// 测试5：错误处理
Future<void> testErrorHandling(MultiLayerRetryService service) async {
  if (kDebugMode) {
    debugPrint('\n📋 测试5: 错误处理');
  }

  try {
    // 测试无效符号处理
    final result1 =
        await service.getFundRankingsWithRetry(symbol: 'INVALID_SYMBOL');

    if (kDebugMode) {
      debugPrint('🔍 无效符号处理: ${result1.length}条记录');

      if (result1.isNotEmpty) {
        debugPrint('✅ 无效符号降级处理正常');
      } else {
        debugPrint('⚠️ 无效符号返回空数据');
      }
    }

    // 测试极短超时
    try {
      final result2 = await service.getFundRankingsWithRetry(
        symbol: '全部',
        timeoutSeconds: 1, // 极短超时
      );

      if (kDebugMode) {
        debugPrint('⏱️ 极短超时处理: ${result2.length}条记录');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⏱️ 极短超时异常处理: $e');
      }
    }

    // 验证服务仍然可用
    final result3 = await service.getFundRankingsWithRetry(symbol: '混合型');

    if (kDebugMode) {
      debugPrint('🔄 服务恢复测试: ${result3.length}条记录');

      if (result3.isNotEmpty) {
        debugPrint('✅ 错误处理和恢复正常');
      } else {
        debugPrint('⚠️ 服务恢复可能有问题');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 测试5失败: $e');
    }
    rethrow;
  }
}

/// 测试6：性能测试
Future<void> testPerformance(MultiLayerRetryService service) async {
  if (kDebugMode) {
    debugPrint('\n📋 测试6: 性能测试');
  }

  try {
    final testSymbols = ['全部', '股票型', '混合型', '债券型'];
    final results = <String, List<FundRanking>>{};
    final durations = <String, int>{};

    // 并发性能测试
    final startTime = DateTime.now();

    final futures = testSymbols.map((symbol) async {
      final requestStart = DateTime.now();
      final result = await service.getFundRankingsWithRetry(symbol: symbol);
      final requestDuration = DateTime.now().difference(requestStart);

      results[symbol] = result;
      durations[symbol] = requestDuration.inMilliseconds;

      return result;
    });

    await Future.wait(futures);
    final totalDuration = DateTime.now().difference(startTime);

    if (kDebugMode) {
      debugPrint('🚀 并发性能测试结果:');
      debugPrint('  总耗时: ${totalDuration.inMilliseconds}ms');
      debugPrint(
          '  平均每个请求: ${totalDuration.inMilliseconds / testSymbols.length}ms');

      durations.forEach((symbol, duration) {
        final recordCount = results[symbol]?.length ?? 0;
        debugPrint('  $symbol: $duration ms ($recordCount 条记录)');
      });
    }

    // 串行性能测试（用于对比）
    service.clearCache(); // 清空缓存确保公平对比

    final serialStartTime = DateTime.now();
    for (final symbol in testSymbols) {
      await service.getFundRankingsWithRetry(symbol: symbol);
    }
    final serialDuration = DateTime.now().difference(serialStartTime);

    if (kDebugMode) {
      debugPrint('🐌 串行性能测试结果:');
      debugPrint('  总耗时: ${serialDuration.inMilliseconds}ms');
      debugPrint(
          '  平均每个请求: ${serialDuration.inMilliseconds / testSymbols.length}ms');

      final speedup =
          serialDuration.inMilliseconds / totalDuration.inMilliseconds;
      debugPrint('🚀 并发加速比: ${speedup.toStringAsFixed(2)}x');
    }

    // 数据质量验证
    results.forEach((symbol, data) {
      _validateDataQuality(data, '性能测试-$symbol');
    });

    if (kDebugMode) {
      debugPrint('✅ 性能测试完成');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 测试6失败: $e');
    }
    rethrow;
  }
}

/// 数据质量验证
void _validateDataQuality(List<FundRanking> data, String testName) {
  if (data.isEmpty) {
    if (kDebugMode) {
      debugPrint('⚠️ $testName: 数据为空');
    }
    return;
  }

  // 基本数据完整性检查
  var validCount = 0;
  var invalidCount = 0;

  for (final fund in data) {
    bool isValid = true;

    // 检查必需字段
    if (fund.fundCode.isEmpty || fund.fundName.isEmpty) {
      isValid = false;
    }

    // 检查数值合理性
    if (fund.unitNav <= 0 || fund.accumulatedNav <= 0) {
      isValid = false;
    }

    // 检查收益率合理性（-100% 到 +1000%）
    if (fund.dailyReturn < -100 ||
        fund.dailyReturn > 1000 ||
        fund.return1Y < -100 ||
        fund.return1Y > 1000) {
      isValid = false;
    }

    if (isValid) {
      validCount++;
    } else {
      invalidCount++;
    }
  }

  if (kDebugMode) {
    debugPrint('📊 $testName 数据质量: 有效 $validCount 条, 无效 $invalidCount 条');

    if (invalidCount > 0) {
      final invalidRate = (invalidCount / data.length * 100);
      debugPrint('⚠️ 无效数据率: ${invalidRate.toStringAsFixed(2)}%');

      if (invalidRate > 10.0) {
        debugPrint('❌ 数据质量较差');
      } else {
        debugPrint('✅ 数据质量可接受');
      }
    } else {
      debugPrint('✅ 数据质量良好');
    }
  }
}

/// 打印测试摘要
void printTestSummary(MultiLayerRetryService service) {
  final stats = service.getStatistics();

  if (kDebugMode) {
    debugPrint('\n📋 测试摘要');
    debugPrint('=' * 50);
    debugPrint('总请求数: ${stats['totalRequests']}');
    debugPrint('成功率: ${stats['successRate']?.toStringAsFixed(2)}%');
    debugPrint('失败次数: ${stats['failureCount']}');
    debugPrint('平均请求时间: ${stats['averageRequestTime']?.toStringAsFixed(2)}ms');
    debugPrint('缓存大小: ${stats['cacheSize']}');

    debugPrint('\n成功来源统计:');
    final successSources = stats['successSources'] as Map<String, int>;
    successSources.forEach((source, count) {
      final percentage =
          (count / stats['totalRequests'] * 100).toStringAsFixed(1);
      debugPrint('  $source: $count 次 ($percentage%)');
    });

    debugPrint('\n${'=' * 50}');
    debugPrint('🎉 多层重试机制测试完成！');
  }
}
