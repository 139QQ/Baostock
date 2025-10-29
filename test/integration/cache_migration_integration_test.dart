/// 缓存迁移集成测试
library cache_migration_integration_test;

import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_migration_adapter.dart';

/// 集成测试场景类型
enum IntegrationTestScenario {
  /// 基本迁移流程
  basicMigration,

  /// 大规模数据迁移
  largeScaleMigration,

  /// 错误恢复迁移
  errorRecoveryMigration,

  /// 回滚场景测试
  rollbackScenario,

  /// 并发迁移测试
  concurrentMigration,

  /// 混合键类型迁移
  mixedKeyTypeMigration,
}

/// 集成测试结果类
class IntegrationTestResult {
  final IntegrationTestScenario scenario;
  final bool success;
  final Duration duration;
  final Map<String, dynamic> metrics;
  final List<String> errors;
  final String? details;

  const IntegrationTestResult({
    required this.scenario,
    required this.success,
    required this.duration,
    required this.metrics,
    required this.errors,
    this.details,
  });

  @override
  String toString() {
    return 'IntegrationTestResult(scenario: $scenario, success: $success, duration: ${duration.inSeconds}s, errors: ${errors.length})';
  }
}

/// 模拟的迁移引擎（用于集成测试）
class MockMigrationEngine {
  final CacheKeyManager _keyManager = CacheKeyManager.instance;
  final Random _random = Random();

  /// 模拟完整的迁移流程
  Future<Map<String, String>> simulateMigration(
    Map<String, String> oldKeys, {
    Duration? delay,
    double failureRate = 0.1,
  }) async {
    final migrationResults = <String, String>{};

    for (final entry in oldKeys.entries) {
      final oldKey = entry.key;
      final newValue = entry.value;

      try {
        // 模拟处理延迟
        await Future.delayed(
            delay ?? Duration(milliseconds: 1 + _random.nextInt(10)));

        // 模拟失败概率
        if (_random.nextDouble() < failureRate) {
          throw Exception('模拟迁移失败: $oldKey');
        }

        // 生成新的标准键
        final newKey = _generateStandardKey(oldKey, newValue);
        migrationResults[oldKey] = newKey;
      } catch (e) {
        // 在真实场景中，这里会记录错误日志
        print('迁移项目失败: $oldKey, 错误: $e');
      }
    }

    return migrationResults;
  }

  /// 生成标准格式的缓存键
  String _generateStandardKey(String oldKey, String metadata) {
    // 基于旧键内容智能生成新键
    if (oldKey.contains(RegExp(r'\d{6}'))) {
      // 基金代码格式
      final match = RegExp(r'(\d{6})').firstMatch(oldKey);
      if (match != null) {
        final fundCode = match.group(1)!;
        return _keyManager.fundDataKey(fundCode);
      }
    }

    if (oldKey.contains('search') || oldKey.contains('index')) {
      return _keyManager.searchIndexKey('fund_search');
    }

    if (oldKey.contains('user') || oldKey.contains('preference')) {
      return _keyManager.userPreferenceKey('user_settings');
    }

    if (oldKey.contains('cache') || oldKey.contains('version')) {
      return _keyManager.metadataKey('system_metadata');
    }

    // 默认生成临时数据键
    return _keyManager.temporaryKey('migrated_data');
  }
}

/// 缓存迁移集成测试器
class CacheMigrationIntegrationTester {
  final MockMigrationEngine _migrationEngine = MockMigrationEngine();
  final CacheKeyManager _keyManager = CacheKeyManager.instance;
  final Random _random = Random();

  /// 运行所有集成测试场景
  Future<List<IntegrationTestResult>> runAllScenarios() async {
    final results = <IntegrationTestResult>[];

    for (final scenario in IntegrationTestScenario.values) {
      print('运行集成测试场景: $scenario');
      final result = await runScenario(scenario);
      results.add(result);
      print(
          '场景 $scenario ${result.success ? "成功" : "失败"} (${result.duration.inMilliseconds}ms)');
    }

    return results;
  }

  /// 运行单个测试场景
  Future<IntegrationTestResult> runScenario(
      IntegrationTestScenario scenario) async {
    final stopwatch = Stopwatch()..start();
    final errors = <String>[];
    final metrics = <String, dynamic>{};

    try {
      switch (scenario) {
        case IntegrationTestScenario.basicMigration:
          return await _runBasicMigrationScenario(stopwatch, metrics, errors);
        case IntegrationTestScenario.largeScaleMigration:
          return await _runLargeScaleMigrationScenario(
              stopwatch, metrics, errors);
        case IntegrationTestScenario.errorRecoveryMigration:
          return await _runErrorRecoveryScenario(stopwatch, metrics, errors);
        case IntegrationTestScenario.rollbackScenario:
          return await _runRollbackScenario(stopwatch, metrics, errors);
        case IntegrationTestScenario.concurrentMigration:
          return await _runConcurrentMigrationScenario(
              stopwatch, metrics, errors);
        case IntegrationTestScenario.mixedKeyTypeMigration:
          return await _runMixedKeyTypeMigrationScenario(
              stopwatch, metrics, errors);
      }
    } catch (e) {
      stopwatch.stop();
      errors.add('场景执行异常: $e');
      return IntegrationTestResult(
        scenario: scenario,
        success: false,
        duration: stopwatch.elapsed,
        metrics: metrics,
        errors: errors,
        details: '场景执行过程中发生异常',
      );
    }
  }

  /// 基本迁移场景
  Future<IntegrationTestResult> _runBasicMigrationScenario(
    Stopwatch stopwatch,
    Map<String, dynamic> metrics,
    List<String> errors,
  ) async {
    // 准备测试数据
    final oldKeys = {
      'fund_161725_data': '基金详情数据',
      'fund_000001_info': '基金基本信息',
      'search_fund_name_index': '基金名称搜索索引',
      'user_theme_preference': '用户主题偏好',
    };

    // 执行迁移
    final migrationResults = await _migrationEngine.simulateMigration(
      oldKeys,
      failureRate: 0.05, // 5% 失败率
    );

    // 验证结果
    final validKeys =
        migrationResults.values.where(_keyManager.isValidKey).toList();
    final invalidKeys = migrationResults.values
        .where((key) => !_keyManager.isValidKey(key))
        .toList();

    metrics['total_keys'] = oldKeys.length;
    metrics['migrated_keys'] = migrationResults.length;
    metrics['valid_keys'] = validKeys.length;
    metrics['invalid_keys'] = invalidKeys.length;
    metrics['success_rate'] = validKeys.length / oldKeys.length;

    if (invalidKeys.isNotEmpty) {
      errors.add(
          '生成了 ${invalidKeys.length} 个无效键: ${invalidKeys.take(3).join(', ')}');
    }

    stopwatch.stop();

    return IntegrationTestResult(
      scenario: IntegrationTestScenario.basicMigration,
      success: errors.isEmpty && validKeys.isNotEmpty,
      duration: stopwatch.elapsed,
      metrics: metrics,
      errors: errors,
      details:
          '基本迁移测试完成，成功率 ${(metrics['success_rate'] * 100).toStringAsFixed(1)}%',
    );
  }

  /// 大规模迁移场景
  Future<IntegrationTestResult> _runLargeScaleMigrationScenario(
    Stopwatch stopwatch,
    Map<String, dynamic> metrics,
    List<String> errors,
  ) async {
    // 生成大规模测试数据
    final oldKeys = <String, String>{};

    // 生成1000个不同类型的旧键
    for (int i = 0; i < 1000; i++) {
      final keyType = _random.nextInt(5);
      switch (keyType) {
        case 0:
          oldKeys['fund_${i.toString().padLeft(6, '0')}_data'] = '基金数据 $i';
          break;
        case 1:
          oldKeys['search_index_$i'] = '搜索索引 $i';
          break;
        case 2:
          oldKeys['user_preference_$i'] = '用户偏好 $i';
          break;
        case 3:
          oldKeys['cache_metadata_$i'] = '缓存元数据 $i';
          break;
        case 4:
          oldKeys['temp_data_$i'] = '临时数据 $i';
          break;
      }
    }

    // 执行大规模迁移
    final migrationResults = await _migrationEngine.simulateMigration(
      oldKeys,
      delay: Duration(milliseconds: 1), // 较小的延迟以加快测试
      failureRate: 0.08, // 8% 失败率
    );

    // 分析结果
    final validKeys =
        migrationResults.values.where(_keyManager.isValidKey).toList();
    final keyTypeCounts = <String, int>{};

    for (final key in validKeys) {
      final info = _keyManager.parseKey(key);
      if (info != null) {
        keyTypeCounts[info.type.name] =
            (keyTypeCounts[info.type.name] ?? 0) + 1;
      }
    }

    metrics['total_keys'] = oldKeys.length;
    metrics['migrated_keys'] = migrationResults.length;
    metrics['valid_keys'] = validKeys.length;
    metrics['invalid_keys'] = oldKeys.length - validKeys.length;
    metrics['success_rate'] = validKeys.length / oldKeys.length;
    metrics['key_type_distribution'] = keyTypeCounts;
    metrics['throughput'] =
        validKeys.length / stopwatch.elapsedMilliseconds * 1000; // 键/秒

    if (metrics['success_rate'] < 0.85) {
      errors.add(
          '大规模迁移成功率过低: ${(metrics['success_rate'] * 100).toStringAsFixed(1)}%');
    }

    stopwatch.stop();

    return IntegrationTestResult(
      scenario: IntegrationTestScenario.largeScaleMigration,
      success: errors.isEmpty && validKeys.length > 850, // 至少85%成功率
      duration: stopwatch.elapsed,
      metrics: metrics,
      errors: errors,
      details:
          '大规模迁移完成，处理 ${oldKeys.length} 个键，吞吐量 ${metrics['throughput'].toStringAsFixed(1)} 键/秒',
    );
  }

  /// 错误恢复场景
  Future<IntegrationTestResult> _runErrorRecoveryScenario(
    Stopwatch stopwatch,
    Map<String, dynamic> metrics,
    List<String> errors,
  ) async {
    // 准备包含易出错项的测试数据
    final oldKeys = {
      'fund_161725_data': '正常数据',
      'corrupted_key_1': '损坏数据1',
      'fund_000001_info': '正常数据',
      'corrupted_key_2': '损坏数据2',
      'search_fund_name': '正常数据',
      'corrupted_key_3': '损坏数据3',
      'user_theme_setting': '正常数据',
      'corrupted_key_4': '损坏数据4',
      'corrupted_key_5': '损坏数据5',
    };

    int attempts = 0;
    const maxAttempts = 3;
    Map<String, String>? finalResults;

    // 实现重试机制
    while (attempts < maxAttempts) {
      attempts++;

      try {
        final results = await _migrationEngine.simulateMigration(
          oldKeys,
          failureRate: 0.3, // 30% 失败率，模拟错误场景
        );

        final validCount = results.values.where(_keyManager.isValidKey).length;

        if (validCount >= oldKeys.length * 0.6) {
          // 至少60%成功
          finalResults = results;
          break;
        } else {
          print('尝试 $attempts: 成功率过低 (${validCount}/${oldKeys.length})，重试...');
          await Future.delayed(Duration(milliseconds: 100 * attempts));
        }
      } catch (e) {
        errors.add('尝试 $attempts 失败: $e');
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 200 * attempts));
        }
      }
    }

    if (finalResults == null) {
      errors.add('经过 $maxAttempts 次尝试后仍然无法完成迁移');
    }

    final validKeys =
        finalResults?.values.where(_keyManager.isValidKey).toList() ?? [];

    metrics['total_keys'] = oldKeys.length;
    metrics['attempts'] = attempts;
    metrics['max_attempts'] = maxAttempts;
    metrics['final_valid_keys'] = validKeys.length;
    metrics['success_rate'] = validKeys.length / oldKeys.length;
    metrics['recovery_success'] = finalResults != null;

    stopwatch.stop();

    return IntegrationTestResult(
      scenario: IntegrationTestScenario.errorRecoveryMigration,
      success: finalResults != null && validKeys.isNotEmpty,
      duration: stopwatch.elapsed,
      metrics: metrics,
      errors: errors,
      details:
          '错误恢复测试完成，使用 $attempts 次尝试，最终成功率 ${(metrics['success_rate'] * 100).toStringAsFixed(1)}%',
    );
  }

  /// 回滚场景
  Future<IntegrationTestResult> _runRollbackScenario(
    Stopwatch stopwatch,
    Map<String, dynamic> metrics,
    List<String> errors,
  ) async {
    // 准备测试数据
    final oldKeys = {
      'fund_161725_backup': '重要基金数据',
      'fund_000001_backup': '重要基金数据2',
      'search_index_backup': '搜索索引备份',
      'user_settings_backup': '用户设置备份',
    };

    // 创建回滚点（模拟）
    final rollbackPoint =
        'rollback_point_${DateTime.now().millisecondsSinceEpoch}';

    // 执行迁移
    final migrationResults = await _migrationEngine.simulateMigration(
      oldKeys,
      failureRate: 0.1,
    );

    // 模拟检测到问题需要回滚
    final needRollback = migrationResults.length < oldKeys.length * 0.8;

    if (needRollback) {
      // 模拟回滚过程
      print('检测到迁移问题，执行回滚到回滚点: $rollbackPoint');
      await Future.delayed(Duration(milliseconds: 100));

      // 验证回滚成功（模拟）
      final rollbackSuccess = _random.nextDouble() < 0.9; // 90% 回滚成功率

      if (!rollbackSuccess) {
        errors.add('回滚操作失败');
      }

      metrics['rollback_required'] = true;
      metrics['rollback_success'] = rollbackSuccess;
      metrics['rollback_point'] = rollbackPoint;
    } else {
      metrics['rollback_required'] = false;
      metrics['rollback_success'] = true; // 不需要回滚就是成功
    }

    metrics['total_keys'] = oldKeys.length;
    metrics['migrated_keys'] = migrationResults.length;
    metrics['migration_success_rate'] =
        migrationResults.length / oldKeys.length;

    stopwatch.stop();

    return IntegrationTestResult(
      scenario: IntegrationTestScenario.rollbackScenario,
      success: !needRollback || (metrics['rollback_success'] as bool),
      duration: stopwatch.elapsed,
      metrics: metrics,
      errors: errors,
      details: needRollback
          ? '迁移需要回滚，回滚${metrics['rollback_success'] ? "成功" : "失败"}'
          : '迁移成功，无需回滚',
    );
  }

  /// 并发迁移场景
  Future<IntegrationTestResult> _runConcurrentMigrationScenario(
    Stopwatch stopwatch,
    Map<String, dynamic> metrics,
    List<String> errors,
  ) async {
    // 准备多个独立的迁移任务
    final migrationTasks = <Map<String, String>>[];
    const taskCount = 5;

    for (int i = 0; i < taskCount; i++) {
      final task = <String, String>{};
      for (int j = 0; j < 20; j++) {
        task['task_${i}_key_${j}'] = '任务 $i 数据 $j';
      }
      migrationTasks.add(task);
    }

    // 并发执行迁移任务
    final futures = migrationTasks
        .map((task) =>
            _migrationEngine.simulateMigration(task, failureRate: 0.05))
        .toList();

    final results = await Future.wait(futures);

    // 分析并发结果
    int totalKeys = 0;
    int totalMigrated = 0;
    int totalValid = 0;

    for (int i = 0; i < results.length; i++) {
      final taskResult = results[i];
      final validKeys =
          taskResult.values.where(_keyManager.isValidKey).toList();

      totalKeys += migrationTasks[i].length;
      totalMigrated += taskResult.length;
      totalValid += validKeys.length;

      if (validKeys.length < migrationTasks[i].length * 0.8) {
        errors.add(
            '任务 $i 成功率过低: ${validKeys.length}/${migrationTasks[i].length}');
      }
    }

    metrics['total_tasks'] = taskCount;
    metrics['total_keys'] = totalKeys;
    metrics['total_migrated'] = totalMigrated;
    metrics['total_valid'] = totalValid;
    metrics['overall_success_rate'] = totalValid / totalKeys;
    metrics['average_task_success_rate'] = results
            .map((r) =>
                r.values.where(_keyManager.isValidKey).length /
                (r.values.isNotEmpty ? r.values.length : 1))
            .reduce((a, b) => a + b) /
        results.length;

    stopwatch.stop();

    return IntegrationTestResult(
      scenario: IntegrationTestScenario.concurrentMigration,
      success: errors.isEmpty && totalValid > totalKeys * 0.8,
      duration: stopwatch.elapsed,
      metrics: metrics,
      errors: errors,
      details:
          '并发迁移完成，${taskCount} 个任务，总成功率 ${(metrics['overall_success_rate'] * 100).toStringAsFixed(1)}%',
    );
  }

  /// 混合键类型迁移场景
  Future<IntegrationTestResult> _runMixedKeyTypeMigrationScenario(
    Stopwatch stopwatch,
    Map<String, dynamic> metrics,
    List<String> errors,
  ) async {
    // 准备包含所有类型的测试数据
    final oldKeys = <String, String>{
      // 基金数据类型
      'fund_161725_detail': '基金161725详情',
      'fund_000001_basic': '基金000001基本信息',
      'fund_list_equity': '股票型基金列表',
      'fund_list_bond': '债券型基金列表',
      'fund_ranking_performance': '基金业绩排行',

      // 搜索索引类型
      'search_fund_name_index': '基金名称索引',
      'search_fund_code_index': '基金代码索引',
      'search_fund_company_index': '基金公司索引',
      'search_history_user123': '用户搜索历史',

      // 用户偏好类型
      'user_theme_dark': '深色主题偏好',
      'user_language_zh': '中文语言偏好',
      'user_notification_settings': '通知设置',
      'user_filter_preferences': '筛选偏好',

      // 元数据类型
      'cache_version_info': '缓存版本信息',
      'api_version_config': 'API版本配置',
      'system_update_time': '系统更新时间',
      'data_quality_metrics': '数据质量指标',

      // 临时数据类型
      'temp_session_abc123': '临时会话数据',
      'temp_search_results_xyz': '临时搜索结果',
      'temp_batch_operation_456': '批量操作临时数据',
    };

    // 执行迁移
    final migrationResults = await _migrationEngine.simulateMigration(
      oldKeys,
      failureRate: 0.03, // 低失败率
    );

    // 分析键类型分布
    final typeDistribution = <String, int>{};
    final validKeys = <String>[];

    for (final newKey in migrationResults.values) {
      if (_keyManager.isValidKey(newKey)) {
        validKeys.add(newKey);

        final info = _keyManager.parseKey(newKey);
        if (info != null) {
          typeDistribution[info.type.name] =
              (typeDistribution[info.type.name] ?? 0) + 1;
        }
      }
    }

    // 验证是否覆盖了所有预期类型
    final expectedTypes = CacheKeyType.values.map((t) => t.name).toSet();
    final actualTypes = typeDistribution.keys.toSet();
    final missingTypes = expectedTypes.difference(actualTypes);

    if (missingTypes.isNotEmpty) {
      errors.add('缺失的键类型: ${missingTypes.join(', ')}');
    }

    metrics['total_keys'] = oldKeys.length;
    metrics['migrated_keys'] = migrationResults.length;
    metrics['valid_keys'] = validKeys.length;
    metrics['success_rate'] = validKeys.length / oldKeys.length;
    metrics['type_distribution'] = typeDistribution;
    metrics['expected_types'] = expectedTypes.length;
    metrics['actual_types'] = actualTypes.length;
    metrics['coverage_rate'] = actualTypes.length / expectedTypes.length;

    stopwatch.stop();

    return IntegrationTestResult(
      scenario: IntegrationTestScenario.mixedKeyTypeMigration,
      success:
          errors.isEmpty && actualTypes.length >= expectedTypes.length * 0.8,
      duration: stopwatch.elapsed,
      metrics: metrics,
      errors: errors,
      details:
          '混合键类型迁移完成，类型覆盖率 ${(metrics['coverage_rate'] * 100).toStringAsFixed(1)}%',
    );
  }

  /// 生成测试报告
  String generateTestReport(List<IntegrationTestResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== 缓存迁移集成测试报告 ===');
    buffer.writeln('测试时间: ${DateTime.now()}');
    buffer.writeln('');

    final totalScenarios = results.length;
    final successfulScenarios = results.where((r) => r.success).length;
    final totalDuration =
        results.fold<Duration>(Duration.zero, (sum, r) => sum + r.duration);

    buffer.writeln('总体结果:');
    buffer.writeln('  测试场景数: $totalScenarios');
    buffer.writeln('  成功场景数: $successfulScenarios');
    buffer.writeln(
        '  成功率: ${(successfulScenarios / totalScenarios * 100).toStringAsFixed(1)}%');
    buffer.writeln('  总耗时: ${totalDuration.inSeconds}秒');
    buffer.writeln('');

    buffer.writeln('详细结果:');
    for (final result in results) {
      buffer.writeln('  ${result.scenario.name}:');
      buffer.writeln('    状态: ${result.success ? "成功" : "失败"}');
      buffer.writeln('    耗时: ${result.duration.inMilliseconds}ms');
      if (result.details != null) {
        buffer.writeln('    详情: ${result.details}');
      }
      if (result.errors.isNotEmpty) {
        buffer.writeln('    错误:');
        for (final error in result.errors) {
          buffer.writeln('      - $error');
        }
      }
      buffer.writeln('');
    }

    // 性能指标汇总
    buffer.writeln('性能指标汇总:');
    final averageDuration = totalDuration.inMilliseconds / totalScenarios;
    buffer.writeln('  平均场景耗时: ${averageDuration.toStringAsFixed(1)}ms');

    for (final result in results) {
      if (result.metrics.containsKey('success_rate')) {
        final rate = (result.metrics['success_rate'] as double) * 100;
        buffer.writeln(
            '  ${result.scenario.name} 成功率: ${rate.toStringAsFixed(1)}%');
      }
    }

    return buffer.toString();
  }
}

void main() {
  group('缓存迁移集成测试', () {
    late CacheMigrationIntegrationTester tester;

    setUp(() {
      tester = CacheMigrationIntegrationTester();
    });

    test('应该成功运行所有集成测试场景', () async {
      final results = await tester.runAllScenarios();

      expect(results, hasLength(IntegrationTestScenario.values.length));

      // 至少一半的场景应该成功
      final successfulScenarios = results.where((r) => r.success).toList();
      expect(successfulScenarios.length,
          greaterThanOrEqualTo(results.length ~/ 2));

      // 生成测试报告
      final report = tester.generateTestReport(results);
      print(report);

      // 验证报告包含关键信息
      expect(report, contains('缓存迁移集成测试报告'));
      expect(report, contains('总体结果'));
      expect(report, contains('详细结果'));
      expect(report, contains('性能指标汇总'));
    });

    test('应该正确处理基本迁移场景', () async {
      final result =
          await tester.runScenario(IntegrationTestScenario.basicMigration);

      expect(result.scenario, equals(IntegrationTestScenario.basicMigration));
      expect(result.metrics, contains('total_keys'));
      expect(result.metrics, contains('success_rate'));
      expect(result.metrics['total_keys'], greaterThan(0));
    });

    test('应该正确处理大规模迁移场景', () async {
      final result =
          await tester.runScenario(IntegrationTestScenario.largeScaleMigration);

      expect(
          result.scenario, equals(IntegrationTestScenario.largeScaleMigration));
      expect(result.metrics['total_keys'], equals(1000));
      expect(result.metrics, contains('throughput'));
      expect(result.metrics['throughput'], greaterThan(0));
    });

    test('应该正确处理错误恢复场景', () async {
      final result = await tester
          .runScenario(IntegrationTestScenario.errorRecoveryMigration);

      expect(result.scenario,
          equals(IntegrationTestScenario.errorRecoveryMigration));
      expect(result.metrics, contains('attempts'));
      expect(result.metrics, contains('recovery_success'));
      expect(result.metrics['attempts'], greaterThanOrEqualTo(1));
    });

    test('应该正确处理回滚场景', () async {
      final result =
          await tester.runScenario(IntegrationTestScenario.rollbackScenario);

      expect(result.scenario, equals(IntegrationTestScenario.rollbackScenario));
      expect(result.metrics, contains('rollback_required'));
      expect(result.metrics, contains('migration_success_rate'));
    });

    test('应该正确处理并发迁移场景', () async {
      final result =
          await tester.runScenario(IntegrationTestScenario.concurrentMigration);

      expect(
          result.scenario, equals(IntegrationTestScenario.concurrentMigration));
      expect(result.metrics, contains('total_tasks'));
      expect(result.metrics, contains('overall_success_rate'));
      expect(result.metrics['total_tasks'], equals(5));
    });

    test('应该正确处理混合键类型迁移场景', () async {
      final result = await tester
          .runScenario(IntegrationTestScenario.mixedKeyTypeMigration);

      expect(result.scenario,
          equals(IntegrationTestScenario.mixedKeyTypeMigration));
      expect(result.metrics, contains('type_distribution'));
      expect(result.metrics, contains('coverage_rate'));
      expect(result.metrics['coverage_rate'], greaterThan(0));
    });

    test('应该生成完整的测试报告', () async {
      final results = await tester.runAllScenarios();
      final report = tester.generateTestReport(results);

      // 验证报告格式和内容
      expect(report, isNotEmpty);
      expect(report, contains('=== 缓存迁移集成测试报告 ==='));
      expect(report, contains('总体结果'));
      expect(report, contains('详细结果'));
      expect(report, contains('性能指标汇总'));

      // 验证包含所有场景
      for (final scenario in IntegrationTestScenario.values) {
        expect(report, contains(scenario.name));
      }
    });

    test('应该正确处理集成测试中的异常情况', () async {
      // 测试异常处理能力
      try {
        // 运行一个可能失败的场景
        final result = await tester
            .runScenario(IntegrationTestScenario.errorRecoveryMigration);

        // 即使有错误，也应该返回结果而不是抛出异常
        expect(result, isA<IntegrationTestResult>());
        expect(result.scenario,
            equals(IntegrationTestScenario.errorRecoveryMigration));
      } catch (e) {
        fail('集成测试不应该抛出未处理的异常: $e');
      }
    });
  });

  group('集成测试性能验证', () {
    test('所有测试场景应该在合理时间内完成', () async {
      const timeout = Duration(minutes: 2);
      final stopwatch = Stopwatch()..start();

      final tester = CacheMigrationIntegrationTester();
      await tester.runAllScenarios();

      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(timeout),
          reason: '所有集成测试场景应该在${timeout.inMinutes}分钟内完成');
    });

    test('应该正确验证生成的缓存键质量', () async {
      final tester = CacheMigrationIntegrationTester();
      final results = await tester.runAllScenarios();

      for (final result in results) {
        if (result.metrics.containsKey('success_rate')) {
          final successRate = result.metrics['success_rate'] as double;
          expect(successRate, greaterThan(0.5),
              reason: '${result.scenario} 的成功率应该大于50%');
        }
      }
    });
  });
}
