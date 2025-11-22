import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Story 2.5 性能测试运行器
///
/// 提供简单的命令行接口来运行Story 2.5的性能测试
///
/// 使用方法:
/// dart test/test/performance/story25_test_runner.dart [options]
///
/// 选项:
///   --quick       运行快速测试（默认）
///   --full        运行完整测试套件
///   --stress      运行压力测试
///   --benchmark   运行基准测试
///   --coverage    生成覆盖率报告
class Story25TestRunner {
  static const Map<String, List<String>> _testSuites = {
    'quick': [
      'test/integration/story25_performance_system_test.dart',
      '--reporter',
      'compact',
    ],
    'full': [
      'test/integration/story25_performance_system_test.dart',
      '--reporter', 'expanded',
      '--timeout', '300s', // 5分钟超时
    ],
    'stress': [
      'test/integration/story25_performance_system_test.dart',
      '--reporter', 'expanded',
      '--timeout', '600s', // 10分钟超时
      '--concurrency=1', // 串行执行以获得准确结果
    ],
    'benchmark': [
      'test/integration/story25_performance_system_test.dart',
      '--reporter',
      'json',
      '--timeout',
      '300s',
      '--concurrency=1',
    ],
    'coverage': [
      'test/integration/story25_performance_system_test.dart',
      '--coverage',
      '--reporter',
      'expanded',
      '--timeout',
      '300s',
    ],
  };

  static void main(List<String> arguments) async {
    print('🚀 Story 2.5 性能测试运行器');
    print('=' * 50);

    final mode = arguments.isNotEmpty ? arguments.first : 'quick';

    if (!_testSuites.containsKey(mode)) {
      print('❌ 未知的测试模式: $mode');
      _printUsage();
      exit(1);
    }

    print('📋 运行模式: $mode');
    print('🎯 测试范围: Story 2.5 性能优化系统');
    print('');

    try {
      await _runTestSuite(mode);
    } catch (e) {
      print('❌ 测试运行失败: $e');
      exit(1);
    }
  }

  static Future<void> _runTestSuite(String mode) async {
    final testArgs = _testSuites[mode]!;

    print('▶️  开始执行测试...');
    print('命令: flutter test ${testArgs.join(' ')}');
    print('');

    // 使用Process运行测试
    final process = await Process.start('flutter', ['test', ...testArgs]);

    // 实时输出测试结果
    process.stdout.transform(utf8.decoder).listen(print);
    process.stderr.transform(utf8.decoder).listen(print);

    final exitCode = await process.exitCode;

    print('');
    if (exitCode == 0) {
      print('✅ 测试完成 - 所有测试通过');

      // 如果是覆盖率测试，显示报告信息
      if (mode == 'coverage') {
        print('📊 覆盖率报告已生成');
        print('📁 报告位置: coverage/lcov.info');
        print('🌐 查看报告: open coverage/lcov-report/index.html');
      }
    } else {
      print('❌ 测试失败 - 退出码: $exitCode');
      exit(exitCode);
    }
  }

  static void _printUsage() {
    print('');
    print('使用方法:');
    print('  dart test/test/performance/story25_test_runner.dart [模式]');
    print('');
    print('可用模式:');
    print('  quick      - 快速测试 (默认)');
    print('  full       - 完整测试套件');
    print('  stress     - 压力测试');
    print('  benchmark  - 基准测试');
    print('  coverage   - 生成覆盖率报告');
    print('');
    print('示例:');
    print('  dart test/test/performance/story25_test_runner.dart');
    print('  dart test/test/performance/story25_test_runner.dart --full');
    print('  dart test/test/performance/story25_test_runner.dart --stress');
  }
}

/// 简化版测试运行器（用于没有命令行参数的情况）
void main([List<String>? arguments]) {
  Story25TestRunner.main(arguments ?? []);
}
