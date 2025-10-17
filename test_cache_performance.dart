import 'dart:math';
import 'lib/src/core/cache/hive_cache_manager.dart';

/// 测试大数据量缓存性能
Future<void> testLargeDataCachePerformance() async {
  print('🚀 开始测试大数据量缓存性能...\n');

  // 初始化缓存
  await HiveCacheManager.init();
  final cacheManager = HiveCacheManager.instance;

  // 生成测试数据
  final testDataSizes = [100, 500, 1000, 2000, 5000];

  for (final size in testDataSizes) {
    print('📊 测试数据量: $size 条记录');

    // 生成测试基金数据
    final testData = _generateTestFundData(size);

    // 测试缓存写入性能
    final stopwatch = Stopwatch()..start();
    await cacheManager.cacheFunds('test_$size', testData, pageSize: 200);
    stopwatch.stop();

    print('⏱️  缓存写入耗时: ${stopwatch.elapsedMilliseconds}ms');

    // 测试缓存读取性能 - 全量读取
    stopwatch.reset();
    stopwatch.start();
    final allData = cacheManager.getCachedFunds('test_$size');
    stopwatch.stop();

    print('⏱️  全量读取耗时: ${stopwatch.elapsedMilliseconds}ms');
    print('✅ 数据完整性: ${allData?.length == size ? '通过' : '失败'}');

    // 测试分页读取性能
    const pageSize = 50;
    final totalPages = (size / pageSize).ceil();
    var totalReadTime = 0;

    for (int page = 0; page < min(5, totalPages); page++) {
      // 只测试前5页
      final offset = page * pageSize;

      stopwatch.reset();
      stopwatch.start();
      final pageData = cacheManager.getCachedFunds('test_$size',
          limit: pageSize, offset: offset);
      stopwatch.stop();

      totalReadTime += stopwatch.elapsedMilliseconds;

      if (pageData != null) {
        print(
            '   📖 第${page + 1}页读取: ${stopwatch.elapsedMilliseconds}ms (${pageData.length}条)');
      }
    }

    if (totalPages > 5) {
      print('⏱️  分页读取平均耗时: ${totalReadTime / min(5, totalPages)}ms/页');
    }

    // 获取缓存统计信息
    final stats = cacheManager.getCacheStats();
    print(
        '📈 缓存统计: ${stats['fundTotalItems']} 条总数据，${stats['fundPaginatedPages']} 个分页');

    print('');
  }

  // 测试清理过期缓存性能
  print('🧹 测试清理过期缓存性能...');

  // 生成一些过期数据
  final oldData = _generateTestFundData(1000);
  await cacheManager.cacheFunds('old_data', oldData);

  final stopwatch = Stopwatch()..start();
  await cacheManager.clearExpiredCache(batchSize: 30);
  stopwatch.stop();

  print('⏱️  清理过期缓存耗时: ${stopwatch.elapsedMilliseconds}ms');

  // 最终统计
  final finalStats = cacheManager.getCacheStats();
  print('\n📊 最终缓存统计:');
  print('   普通缓存项: ${finalStats['fundRegularItems']} 条');
  print('   分页缓存项: ${finalStats['fundPaginatedItems']} 条');
  print('   分页总数: ${finalStats['fundPaginatedPages']} 页');
  print('   总缓存条目: ${finalStats['totalCacheSize']} 个');

  print('\n✅ 大数据量缓存性能测试完成！');
}

/// 生成测试基金数据
List<Map<String, dynamic>> _generateTestFundData(int count) {
  final random = Random();
  final data = <Map<String, dynamic>>[];

  final fundNames = [
    '易方达蓝筹精选混合',
    '富国天惠成长混合',
    '兴全合润混合',
    '汇添富价值精选',
    '嘉实优质企业混合',
    '华夏回报混合',
    '南方绩优成长混合',
    '广发稳健增长混合',
    '上投摩根中国优势混合',
    '景顺长城鼎益混合',
    '中欧新蓝筹混合',
    '银华富裕主题混合'
  ];

  for (int i = 0; i < count; i++) {
    final fundName =
        fundNames[random.nextInt(fundNames.length)] + (i + 1).toString();
    data.add({
      '基金代码': (random.nextInt(999999) + 100000).toString().padLeft(6, '0'),
      '基金名称': fundName,
      '单位净值': (random.nextDouble() * 5 + 0.5).toStringAsFixed(4),
      '累计净值': (random.nextDouble() * 10 + 1).toStringAsFixed(4),
      '日增长率': '${(random.nextDouble() * 10 - 5).toStringAsFixed(2)}%',
      '近1月': '${(random.nextDouble() * 20 - 10).toStringAsFixed(2)}%',
      '近3月': '${(random.nextDouble() * 30 - 15).toStringAsFixed(2)}%',
      '近6月': '${(random.nextDouble() * 40 - 20).toStringAsFixed(2)}%',
      '近1年': '${(random.nextDouble() * 50 - 25).toStringAsFixed(2)}%',
      '规模': '${(random.nextInt(900) + 100)}亿元',
      '基金经理': '基金经理${(i % 10) + 1}',
      '基金公司':
          '${['易方达', '富国', '兴全', '汇添富', '嘉实', '华夏'][random.nextInt(6)]}基金管理有限公司'
    });
  }

  return data;
}

void main() {
  testLargeDataCachePerformance();
}
