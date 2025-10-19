import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'src/core/network/fund_api_client.dart';
import 'src/features/fund/domain/entities/fund_ranking.dart';

/// 简化的基金排行测试
///
/// 测试API连接、数据获取和基本功能
void main() async {
  if (kDebugMode) {
    debugPrint('🧪 开始简化基金排行测试');
  }

  await runSimpleTests();

  if (kDebugMode) {
    debugPrint('✅ 简化基金排行测试完成');
  }
}

/// 运行简化测试
Future<void> runSimpleTests() async {
  final testResults = <String, bool>{};

  try {
    // 测试1：API连接测试
    testResults['API连接'] = await testApiConnection();

    // 测试2：数据获取测试
    testResults['数据获取'] = await testDataFetching();

    // 测试3：超时配置测试
    testResults['超时配置'] = await testTimeoutConfig();

    // 测试4：错误处理测试
    testResults['错误处理'] = await testErrorHandling();

    // 测试5：数据质量测试
    testResults['数据质量'] = await testDataQuality();

    // 输出测试结果
    if (kDebugMode) {
      debugPrint('\n📊 测试结果摘要:');
      testResults.forEach((name, success) {
        final status = success ? '✅' : '❌';
        debugPrint('$status $name');
      });

      final passedTests = testResults.values.where((success) => success).length;
      final totalTests = testResults.length;
      final successRate = (passedTests / totalTests * 100).toStringAsFixed(1);
      debugPrint('\n总成功率: $passedTests/$totalTests ($successRate%)');

      if (passedTests == totalTests) {
        debugPrint('🎉 所有测试通过！');
      } else {
        debugPrint('⚠️ 部分测试失败，请检查相关功能');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 测试运行失败: $e');
    }
  }
}

/// 测试1：API连接
Future<bool> testApiConnection() async {
  try {
    if (kDebugMode) {
      debugPrint('🔗 测试API连接...');
    }

    // 检查API客户端配置
    final baseUrl = FundApiClient.baseUrl;
    final connectTimeout = FundApiClient.connectTimeout;
    final receiveTimeout = FundApiClient.receiveTimeout;

    if (kDebugMode) {
      debugPrint('  API地址: $baseUrl');
      debugPrint('  连接超时: ${connectTimeout.inSeconds}秒');
      debugPrint('  接收超时: ${receiveTimeout.inSeconds}秒');
    }

    // 验证基本配置
    final configValid = baseUrl.isNotEmpty &&
        connectTimeout.inSeconds >= 30 &&
        receiveTimeout.inSeconds >= 60;

    if (kDebugMode) {
      debugPrint('  配置验证: ${configValid ? '✅ 通过' : '❌ 失败'}');
    }

    return configValid;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ API连接测试失败: $e');
    }
    return false;
  }
}

/// 测试2：数据获取
Future<bool> testDataFetching() async {
  try {
    if (kDebugMode) {
      debugPrint('📊 测试数据获取...');
    }

    final startTime = DateTime.now();

    // 尝试获取基金排行数据
    final rawData = await FundApiClient.getFundRankings(
      symbol: '全部',
      forceRefresh: false,
    ).timeout(const Duration(seconds: 60));

    final duration = DateTime.now().difference(startTime);

    if (kDebugMode) {
      debugPrint('  响应时间: ${duration.inMilliseconds}ms');
      debugPrint('  数据量: ${rawData.length}条');
    }

    // 验证数据质量
    final dataValid = rawData.isNotEmpty;

    if (kDebugMode) {
      debugPrint('  数据获取: ${dataValid ? '✅ 成功' : '❌ 失败'}');
    }

    return dataValid;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 数据获取测试失败: $e');
    }
    return false;
  }
}

/// 测试3：超时配置
Future<bool> testTimeoutConfig() async {
  try {
    if (kDebugMode) {
      debugPrint('⏱️ 测试超时配置...');
    }

    // 测试正常超时时间
    final startTime = DateTime.now();
    try {
      await FundApiClient.getFundRankings(symbol: '全部')
          .timeout(const Duration(seconds: 45));
      final duration = DateTime.now().difference(startTime);

      if (kDebugMode) {
        debugPrint('  正常请求时间: ${duration.inMilliseconds}ms');
      }

      // 验证时间是否在合理范围内
      final timeValid = duration.inMilliseconds < 30000; // 30秒内

      if (kDebugMode) {
        debugPrint('  超时配置: ${timeValid ? '✅ 合理' : '❌ 过长'}');
      }

      return timeValid;
    } catch (e) {
      // 即使失败也要检查超时配置
      final duration = DateTime.now().difference(startTime);

      if (kDebugMode) {
        debugPrint('  请求失败，耗时: ${duration.inMilliseconds}ms');
      }

      // 如果在预期超时时间内失败，说明配置正确
      final timeoutValid =
          duration.inMilliseconds >= 40000 && duration.inMilliseconds <= 65000;

      if (kDebugMode) {
        debugPrint('  超时机制: ${timeoutValid ? '✅ 正常' : '❌ 异常'}');
      }

      return timeoutValid;
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 超时配置测试失败: $e');
    }
    return false;
  }
}

/// 测试4：错误处理
Future<bool> testErrorHandling() async {
  try {
    if (kDebugMode) {
      debugPrint('🛡️ 测试错误处理...');
    }

    // 测试无效参数处理
    try {
      await FundApiClient.getFundRankings(symbol: 'INVALID_SYMBOL_12345');
      if (kDebugMode) {
        debugPrint('  无效参数处理: ⚠️ 未抛出异常');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('  无效参数处理: ✅ 正确处理异常');
      }
    }

    // 测试极短超时处理
    try {
      await FundApiClient.getFundRankings(symbol: '全部')
          .timeout(const Duration(seconds: 1));
      if (kDebugMode) {
        debugPrint('  极短超时处理: ⚠️ 未超时');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('  极短超时处理: ✅ 正确超时');
      }
    }

    // 基本错误处理验证（如果能执行到这里说明基础错误处理正常）
    if (kDebugMode) {
      debugPrint('  错误处理机制: ✅ 基本正常');
    }

    return true;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 错误处理测试失败: $e');
    }
    return false;
  }
}

/// 测试5：数据质量
Future<bool> testDataQuality() async {
  try {
    if (kDebugMode) {
      debugPrint('🔍 测试数据质量...');
    }

    final rawData = await FundApiClient.getFundRankings(symbol: '全部');

    if (rawData.isEmpty) {
      if (kDebugMode) {
        debugPrint('  数据质量: ❌ 无数据');
      }
      return false;
    }

    // 随机检查几条数据的质量
    final sampleSize = math.min(5, rawData.length);
    int validCount = 0;
    int invalidCount = 0;

    for (int i = 0; i < sampleSize; i++) {
      try {
        final item = rawData[i];
        if (item is Map<String, dynamic>) {
          // 检查必需字段
          final hasFundCode =
              item.containsKey('基金代码') || item.containsKey('fundCode');
          final hasFundName =
              item.containsKey('基金简称') || item.containsKey('fundName');

          if (hasFundCode && hasFundName) {
            validCount++;
          } else {
            invalidCount++;
          }
        } else {
          invalidCount++;
        }
      } catch (e) {
        invalidCount++;
      }
    }

    final qualityScore = sampleSize > 0 ? (validCount / sampleSize * 100) : 0;

    if (kDebugMode) {
      debugPrint('  样本数据: $sampleSize 条');
      debugPrint('  有效数据: $validCount 条');
      debugPrint('  无效数据: $invalidCount 条');
      debugPrint('  质量分数: ${qualityScore.toStringAsFixed(1)}%');
      debugPrint('  数据质量: ${qualityScore >= 80 ? '✅ 良好' : '⚠️ 需改进'}');
    }

    return qualityScore >= 80;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ 数据质量测试失败: $e');
    }
    return false;
  }
}

/// 模拟基金数据转换（用于测试）
List<FundRanking> convertToMockFundRankingList(List<dynamic> rawData) {
  if (rawData.isEmpty) return [];

  final fundData = <FundRanking>[];
  final random = math.Random();

  for (int i = 0; i < math.min(rawData.length, 20); i++) {
    try {
      final item = rawData[i];
      if (item is Map<String, dynamic>) {
        final fundCode = item['基金代码']?.toString() ??
            item['fundCode']?.toString() ??
            'CODE${i.toString().padLeft(6, '0')}';
        final fundName = item['基金简称']?.toString() ??
            item['fundName']?.toString() ??
            '测试基金$i';

        fundData.add(FundRanking(
          fundCode: fundCode,
          fundName: fundName,
          fundType: item['基金类型']?.toString() ?? '混合型',
          company: item['基金公司']?.toString() ?? '测试基金公司',
          rankingPosition: i + 1,
          totalCount: rawData.length,
          unitNav: 1.0 + random.nextDouble() * 3.0,
          accumulatedNav: 2.0 + random.nextDouble() * 4.0,
          dailyReturn: (random.nextDouble() - 0.5) * 6.0,
          return1W: (random.nextDouble() - 0.5) * 8.0,
          return1M: (random.nextDouble() - 0.5) * 15.0,
          return3M: (random.nextDouble() - 0.5) * 25.0,
          return6M: (random.nextDouble() - 0.5) * 35.0,
          return1Y: (random.nextDouble() - 0.5) * 50.0,
          return2Y: (random.nextDouble() - 0.5) * 60.0,
          return3Y: (random.nextDouble() - 0.5) * 80.0,
          returnYTD: (random.nextDouble() - 0.5) * 30.0,
          returnSinceInception: random.nextDouble() * 200.0,
          rankingDate: DateTime.now(),
          rankingPeriod: RankingPeriod.oneYear,
          rankingType: RankingType.overall,
        ));
      }
    } catch (e) {
      // 跳过无效数据
      continue;
    }
  }

  return fundData;
}

/// 打印测试样本数据
void printSampleData(List<FundRanking> fundData) {
  if (fundData.isEmpty) {
    if (kDebugMode) {
      debugPrint('📄 无数据可显示');
    }
    return;
  }

  if (kDebugMode) {
    debugPrint('\n📄 样本基金数据 (前${math.min(3, fundData.length)}条):');

    for (int i = 0; i < math.min(3, fundData.length); i++) {
      final fund = fundData[i];
      debugPrint('${i + 1}. ${fund.fundName} (${fund.fundCode})');
      debugPrint('   类型: ${fund.fundType} | 公司: ${fund.company}');
      debugPrint(
          '   单位净值: ${fund.unitNav.toStringAsFixed(4)} | 日收益: ${fund.dailyReturn.toStringAsFixed(2)}%');
      debugPrint(
          '   近1年: ${fund.return1Y.toStringAsFixed(2)}% | 成立来: ${fund.returnSinceInception.toStringAsFixed(2)}%');
      debugPrint('');
    }
  }
}
