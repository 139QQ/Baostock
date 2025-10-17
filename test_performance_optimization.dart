import 'dart:math';

/// 大数据量性能测试脚本
/// 模拟解析大量基金数据以验证性能优化效果
void main() {
  print('🚀 开始大数据量性能测试...');

  final stopwatch = Stopwatch()..start();

  // 生成36901条模拟数据
  final testData = generateTestData(36901);
  print('📊 生成了${testData.length}条测试数据，耗时: ${stopwatch.elapsedMilliseconds}ms');

  // 重置计时器
  stopwatch.reset();
  stopwatch.start();

  // 解析数据（模拟FundRankingDto.fromJson的过程）
  int processedCount = 0;
  for (final item in testData) {
    try {
      // 模拟JSON解析过程（不包含debug日志）
      final fundCode = item['基金代码']?.toString() ?? '未知代码';
      final fundName = item['基金简称']?.toString() ?? '未知基金';
      final unitNav = double.tryParse(item['单位净值']?.toString() ?? '0.0') ?? 0.0;

      // 模拟一些基本的数据处理
      if (fundCode.isNotEmpty && fundName.isNotEmpty && unitNav > 0) {
        processedCount++;
      }

      // 每10000条记录输出一次进度（比原来的每100条更少）
      if (processedCount % 10000 == 0) {
        print('⏳ 已处理 $processedCount 条记录...');
      }
    } catch (e) {
      // 静默处理错误，不输出日志
    }
  }

  stopwatch.stop();

  print('✅ 性能测试完成!');
  print('📈 处理结果:');
  print('   - 总记录数: ${testData.length}');
  print('   - 成功处理: $processedCount');
  print('   - 处理时间: ${stopwatch.elapsedMilliseconds}ms');
  print(
      '   - 平均每条: ${(stopwatch.elapsedMilliseconds / testData.length).toStringAsFixed(3)}ms');
  print(
      '   - 处理速度: ${(testData.length / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(0)} 条/秒');

  // 性能评估
  final avgTimePerRecord = stopwatch.elapsedMilliseconds / testData.length;
  if (avgTimePerRecord < 0.1) {
    print('🎉 性能优秀! 平均每条记录处理时间小于0.1ms');
  } else if (avgTimePerRecord < 1.0) {
    print('✅ 性能良好! 平均每条记录处理时间小于1ms');
  } else {
    print('⚠️ 性能需要优化! 平均每条记录处理时间大于1ms');
  }
}

/// 生成测试数据
List<Map<String, dynamic>> generateTestData(int count) {
  final random = Random();
  final data = <Map<String, dynamic>>[];

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
