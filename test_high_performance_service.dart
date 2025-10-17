import 'dart:io';
import 'dart:math' as math;
import 'lib/src/features/fund/presentation/fund_exploration/domain/data/services/high_performance_fund_service.dart';

/// 测试高性能基金服务
void main() async {
  print('========================================');
  print('高性能基金服务测试');
  print('========================================');
  print();

  // 测试高性能服务
  await testHighPerformanceService();

  print('\n测试完成！');
}

/// 测试高性能基金服务
Future<void> testHighPerformanceService() async {
  print('🚀 测试高性能基金服务');
  print('-' * 30);

  try {
    final service = HighPerformanceFundService();

    // 测试获取基金排行数据
    print('正在获取基金排行数据...');
    final stopwatch = Stopwatch()..start();

    final rankings = await service.getFundRankings(
      symbol: '全部',
      priority: HighPerformanceFundService.RequestPriority.high,
      enableCache: true,
    );

    stopwatch.stop();

    print('✅ 请求成功！');
    print('⏱️ 耗时: ${stopwatch.elapsedMilliseconds}ms');
    print('📊 获取数据条数: ${rankings.length}');

    if (rankings.isNotEmpty) {
      print('\n📋 前3条数据示例:');
      for (int i = 0; i < math.min(3, rankings.length); i++) {
        final ranking = rankings[i];
        print('  ${i + 1}. ${ranking.fundName} (${ranking.fundCode})');
        print('     类型: ${ranking.fundType} | 公司: ${ranking.company}');
        print('     单位净值: ${ranking.unitNav} | 日增长率: ${ranking.dailyReturn}%');
        print('     日期: ${ranking.date}');
        print();
      }
    }

    // 测试性能统计
    final stats = service.getPerformanceStats();
    print('\n📈 性能统计:');
    print('  总请求数: ${stats['requests']}');
    print('  缓存命中: ${stats['cacheHits']}');
    print('  平均响应时间: ${stats['averageResponseTime']}ms');
    print('  错误率: ${(stats['errorRate'] * 100).toStringAsFixed(2)}%');
    print('  活跃连接数: ${stats['activeConnections']}');
    print('  缓存响应数: ${stats['cachedResponses']}');

    // 测试缓存功能
    print('\n🔁 测试缓存功能...');
    final stopwatch2 = Stopwatch()..start();

    final cachedRankings = await service.getFundRankings(
      symbol: '全部',
      priority: HighPerformanceFundService.RequestPriority.normal,
      enableCache: true,
    );

    stopwatch2.stop();

    print('✅ 缓存请求成功！');
    print('⏱️ 缓存耗时: ${stopwatch2.elapsedMilliseconds}ms');
    print('📊 缓存数据条数: ${cachedRankings.length}');

    // 测试不同基金类型
    print('\n🔄 测试不同基金类型...');
    final types = ['股票型', '混合型', '债券型'];

    for (final type in types) {
      print('\n测试基金类型: $type');
      final typeRankings = await service.getFundRankings(
        symbol: type,
        priority: HighPerformanceFundService.RequestPriority.normal,
        enableCache: true,
      );
      print('  获取到 ${typeRankings.length} 条 $type 基金数据');

      if (typeRankings.isNotEmpty) {
        final firstFund = typeRankings.first;
        print('  示例: ${firstFund.fundName} - 日收益率: ${firstFund.dailyReturn}%');
      }
    }

    // 清理服务
    await service.dispose();
    print('\n✅ 服务已清理');
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}
