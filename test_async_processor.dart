import 'dart:async';
import 'dart:math';

/// 简化的异步数据处理器测试（不依赖Flutter）
void main() async {
  print('🚀 开始异步数据处理器性能测试...\n');

  // 测试1: 小数据量同步处理
  await testSmallDataProcessing();

  // 测试2: 大数据量模拟异步处理
  await testLargeDataProcessing();

  // 测试3: 模拟分批处理
  await testBatchProcessing();

  print('\n✅ 所有异步处理器测试完成！');
}

/// 测试小数据量处理
Future<void> testSmallDataProcessing() async {
  print('📊 测试1: 小数据量同步处理');

  final stopwatch = Stopwatch()..start();
  final testData = generateTestData(500);

  // 模拟同步处理
  int processedCount = 0;
  for (final item in testData) {
    try {
      final fundCode = item['基金代码']?.toString() ?? '未知代码';
      final fundName = item['基金简称']?.toString() ?? '未知基金';
      final unitNav = double.tryParse(item['单位净值']?.toString() ?? '0.0') ?? 0.0;

      if (fundCode.isNotEmpty && fundName.isNotEmpty && unitNav > 0) {
        processedCount++;
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  stopwatch.stop();

  print('   - 数据量: ${testData.length} 条');
  print('   - 处理成功: $processedCount 条');
  print('   - 耗时: ${stopwatch.elapsedMilliseconds}ms');
  print(
      '   - 平均每条: ${(stopwatch.elapsedMilliseconds / testData.length).toStringAsFixed(3)}ms');
  print(
      '   - 处理速度: ${(testData.length / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(0)} 条/秒\n');
}

/// 测试大数据量异步处理
Future<void> testLargeDataProcessing() async {
  print('📊 测试2: 大数据量模拟异步处理');

  final stopwatch = Stopwatch()..start();
  final testData = generateTestData(10000);

  // 模拟分批异步处理
  int processedCount = 0;
  const batchSize = 200;
  final totalBatches = (testData.length / batchSize).ceil();

  print('   - 开始分批处理 ${testData.length} 条数据，批次大小: $batchSize');

  for (int i = 0; i < totalBatches; i++) {
    final batchStart = i * batchSize;
    final batchEnd = (batchStart + batchSize).clamp(0, testData.length);
    final batchData = testData.sublist(batchStart, batchEnd);

    // 处理当前批次
    for (final item in batchData) {
      try {
        final fundCode = item['基金代码']?.toString() ?? '未知代码';
        final fundName = item['基金简称']?.toString() ?? '未知基金';
        final unitNav =
            double.tryParse(item['单位净值']?.toString() ?? '0.0') ?? 0.0;

        if (fundCode.isNotEmpty && fundName.isNotEmpty && unitNav > 0) {
          processedCount++;
        }
      } catch (e) {
        // 静默处理错误
      }
    }

    // 报告进度
    final processedInBatch = batchData.length;
    final totalProcessed = (i + 1) * batchSize;
    if (totalProcessed % 2000 == 0 || i == totalBatches - 1) {
      final actualProcessed = totalProcessed.clamp(0, testData.length);
      final progress =
          (actualProcessed / testData.length * 100).toStringAsFixed(1);
      print('   - 进度: $actualProcessed/${testData.length} ($progress%)');
    }

    // 模拟异步让出控制权
    if (i < totalBatches - 1) {
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  stopwatch.stop();

  print('   - 处理成功: $processedCount 条');
  print('   - 总耗时: ${stopwatch.elapsedMilliseconds}ms');
  print(
      '   - 平均每条: ${(stopwatch.elapsedMilliseconds / testData.length).toStringAsFixed(3)}ms');
  print(
      '   - 处理速度: ${(testData.length / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(0)} 条/秒\n');
}

/// 测试分批处理性能
Future<void> testBatchProcessing() async {
  print('📊 测试3: 不同批次大小性能对比');

  final testData = generateTestData(5000);
  final batchSizes = [50, 100, 200, 500, 1000];

  for (final batchSize in batchSizes) {
    final stopwatch = Stopwatch()..start();
    int processedCount = 0;

    final totalBatches = (testData.length / batchSize).ceil();

    for (int i = 0; i < totalBatches; i++) {
      final batchStart = i * batchSize;
      final batchEnd = (batchStart + batchSize).clamp(0, testData.length);
      final batchData = testData.sublist(batchStart, batchEnd);

      // 处理批次
      for (final item in batchData) {
        try {
          final fundCode = item['基金代码']?.toString() ?? '未知代码';
          final unitNav =
              double.tryParse(item['单位净值']?.toString() ?? '0.0') ?? 0.0;

          if (fundCode.isNotEmpty && unitNav > 0) {
            processedCount++;
          }
        } catch (e) {
          // 静默处理错误
        }
      }

      // 模拟批次间延迟
      if (i < totalBatches - 1) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    stopwatch.stop();

    print('   - 批次大小 $batchSize: ${stopwatch.elapsedMilliseconds}ms '
        '(${(testData.length / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(0)} 条/秒)');
  }

  print('');
}

/// 生成测试数据
List<Map<String, dynamic>> generateTestData(int count) {
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
  ];

  for (int i = 0; i < count; i++) {
    data.add({
      '基金代码':
          '${random.nextInt(9) + 1}${random.nextInt(9) + 1}${random.nextInt(9) + 1}${random.nextInt(9) + 1}${random.nextInt(9) + 1}${random.nextInt(9) + 1}',
      '基金简称': '测试基金${i + 1}',
      '基金类型': ['股票型', '债券型', '混合型', '货币型'][random.nextInt(4)],
      '基金公司': '测试基金公司${random.nextInt(100) + 1}',
      '单位净值': (random.nextDouble() * 5 + 0.5).toStringAsFixed(4),
      '累计净值': (random.nextDouble() * 10 + 1).toStringAsFixed(4),
      '日增长率': (random.nextDouble() * 0.1 - 0.05).toStringAsFixed(4),
      '近1周': (random.nextDouble() * 0.2 - 0.1).toStringAsFixed(4),
      '近1月': (random.nextDouble() * 0.3 - 0.15).toStringAsFixed(4),
      '近3月': (random.nextDouble() * 0.5 - 0.25).toStringAsFixed(4),
      '近6月': (random.nextDouble() * 0.8 - 0.4).toStringAsFixed(4),
      '近1年': (random.nextDouble() * 2.0 - 1.0).toStringAsFixed(4),
      '近2年': (random.nextDouble() * 3.0 - 1.5).toStringAsFixed(4),
      '近3年': (random.nextDouble() * 4.0 - 2.0).toStringAsFixed(4),
      '今年来': (random.nextDouble() * 1.5 - 0.75).toStringAsFixed(4),
      '成立来': (random.nextDouble() * 5.0 - 2.5).toStringAsFixed(4),
      '日期': '2025-10-12',
      '手续费': '${(random.nextDouble() * 0.5).toStringAsFixed(2)}%',
    });
  }

  return data;
}
