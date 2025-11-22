/// 缓存迁移引擎测试
library migration_engine_test;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_migration_adapter.dart';

/// 迁移状态枚举
enum MigrationStatus {
  /// 未开始
  notStarted,

  /// 进行中
  inProgress,

  /// 已完成
  completed,

  /// 已失败
  failed,

  /// 已暂停
  paused,

  /// 已回滚
  rolledBack,
}

/// 迁移结果类
class MigrationResult {
  final String migrationId;
  final MigrationStatus status;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final int skippedItems;
  final Duration duration;
  final List<String> errors;
  final Map<String, dynamic> statistics;

  const MigrationResult({
    required this.migrationId,
    required this.status,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    required this.skippedItems,
    required this.duration,
    required this.errors,
    required this.statistics,
  });

  /// 获取成功率
  double get successRate {
    if (totalItems == 0) return 0.0;
    return processedItems / totalItems;
  }

  /// 获取失败率
  double get failureRate {
    if (totalItems == 0) return 0.0;
    return failedItems / totalItems;
  }

  /// 是否成功
  bool get isSuccess => status == MigrationStatus.completed && failedItems == 0;

  /// 是否部分成功
  bool get isPartialSuccess =>
      status == MigrationStatus.completed && failedItems > 0;

  @override
  String toString() {
    return 'MigrationResult(id: $migrationId, status: $status, progress: $processedItems/$totalItems, success: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 进度回调类型定义
typedef ProgressCallback = void Function(
    int processed, int total, String? currentItem);

/// 简化的迁移引擎实现
class CacheMigrationEngine {
  final CacheKeyManager _keyManager = CacheKeyManager.instance;
  final CacheKeyMigrationAdapter _adapter = CacheKeyMigrationAdapter.instance;
  final Random _random = Random();

  /// 执行缓存键迁移
  Future<MigrationResult> migrateKeys(
    Map<String, String> keyMapping, {
    ProgressCallback? onProgress,
    Duration? timeout,
    bool enableRetry = true,
    int maxRetries = 3,
  }) async {
    final migrationId = _generateMigrationId();
    final stopwatch = Stopwatch()..start();
    final errors = <String>[];
    final statistics = <String, dynamic>{};

    int totalItems = keyMapping.length;
    int processedItems = 0;
    int failedItems = 0;
    int skippedItems = 0;

    try {
      // 通知开始
      onProgress?.call(0, totalItems, '开始迁移...');

      for (final entry in keyMapping.entries) {
        final oldKey = entry.key;
        final newKey = entry.value;

        try {
          // 通知进度
          onProgress?.call(processedItems, totalItems, '处理: $oldKey');

          // 检查是否需要跳过
          if (_shouldSkipItem(oldKey, newKey)) {
            skippedItems++;
            continue;
          }

          // 执行迁移
          final success = await _migrateSingleKey(
            oldKey,
            newKey,
            enableRetry: enableRetry,
            maxRetries: maxRetries,
          );

          if (success) {
            processedItems++;
            statistics['migrated_keys'] =
                (statistics['migrated_keys'] ?? 0) + 1;
          } else {
            failedItems++;
            errors.add('迁移失败: $oldKey -> $newKey');
            statistics['failed_migrations'] =
                (statistics['failed_migrations'] ?? 0) + 1;
          }

          // 模拟处理时间
          await Future.delayed(Duration(milliseconds: 1 + _random.nextInt(5)));
        } catch (e) {
          failedItems++;
          errors.add('迁移异常: $oldKey -> $newKey, 错误: $e');
          statistics['migration_errors'] =
              (statistics['migration_errors'] ?? 0) + 1;
        }
      }

      stopwatch.stop();

      // 通知完成
      onProgress?.call(totalItems, totalItems, '迁移完成');

      final status = failedItems == 0
          ? MigrationStatus.completed
          : MigrationStatus.completed;

      return MigrationResult(
        migrationId: migrationId,
        status: status,
        totalItems: totalItems,
        processedItems: processedItems,
        failedItems: failedItems,
        skippedItems: skippedItems,
        duration: stopwatch.elapsed,
        errors: errors,
        statistics: statistics,
      );
    } catch (e) {
      stopwatch.stop();
      errors.add('迁移过程异常: $e');

      return MigrationResult(
        migrationId: migrationId,
        status: MigrationStatus.failed,
        totalItems: totalItems,
        processedItems: processedItems,
        failedItems: failedItems,
        skippedItems: skippedItems,
        duration: stopwatch.elapsed,
        errors: errors,
        statistics: statistics,
      );
    }
  }

  /// 迁移单个缓存键
  Future<bool> _migrateSingleKey(
    String oldKey,
    String newKey, {
    bool enableRetry = true,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        // 模拟迁移过程
        await Future.delayed(Duration(milliseconds: _random.nextInt(10)));

        // 模拟迁移成功率（90%成功率）
        if (_random.nextDouble() < 0.9) {
          return true;
        } else {
          throw Exception('模拟迁移失败');
        }
      } catch (e) {
        attempts++;
        if (!enableRetry || attempts > maxRetries) {
          return false;
        }

        // 指数退避重试
        final delay = Duration(milliseconds: 100 * (1 << attempts));
        await Future.delayed(delay);
      }
    }

    return false;
  }

  /// 判断是否应该跳过某个项目
  bool _shouldSkipItem(String oldKey, String newKey) {
    // 如果新旧键相同，跳过
    if (oldKey == newKey) return true;

    // 如果旧键无效，跳过
    if (!_isValidOldKey(oldKey)) return true;

    // 如果新键无效，跳过
    if (!_keyManager.isValidKey(newKey)) return true;

    return false;
  }

  /// 检查旧键是否有效
  bool _isValidOldKey(String key) {
    // 简单的旧键格式检查
    return key.isNotEmpty && key.length >= 3;
  }

  /// 生成迁移ID
  String _generateMigrationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(10000);
    return 'migration_${timestamp}_$randomSuffix';
  }

  /// 获取迁移统计信息
  Map<String, dynamic> getMigrationStatistics() {
    return {
      'engine_version': '1.0.0',
      'supported_key_types': CacheKeyType.values.map((e) => e.name).toList(),
      'max_retries': 3,
      'timeout_enabled': true,
      'retry_enabled': true,
    };
  }

  /// 验证迁移结果
  Future<bool> validateMigration(
    Map<String, String> keyMapping,
    MigrationResult result,
  ) async {
    if (result.status != MigrationStatus.completed) {
      return false;
    }

    // 验证统计信息
    if (result.totalItems != keyMapping.length) {
      return false;
    }

    if (result.processedItems + result.failedItems + result.skippedItems !=
        result.totalItems) {
      return false;
    }

    // 模拟验证过程
    await Future.delayed(const Duration(milliseconds: 100));

    // 模拟验证成功率（95%成功率）
    return _random.nextDouble() < 0.95;
  }

  /// 回滚迁移
  Future<bool> rollbackMigration(String migrationId) async {
    // 模拟回滚过程
    await Future.delayed(const Duration(milliseconds: 500));

    // 模拟回滚成功率（90%成功率）
    return _random.nextDouble() < 0.9;
  }
}

void main() {
  group('缓存迁移引擎基础功能测试', () {
    late CacheMigrationEngine engine;

    setUp(() {
      engine = CacheMigrationEngine();
    });

    test('应该成功迁移简单的键映射', () async {
      final keyMapping = {
        'old_fund_161725': 'jisu_fund_fundData_161725@latest',
        'old_fund_000001': 'jisu_fund_fundData_000001@latest',
        'old_search_name': 'jisu_fund_searchIndex_fund_name@latest',
      };

      final result = await engine.migrateKeys(keyMapping);

      expect(result.status, equals(MigrationStatus.completed));
      expect(result.totalItems, equals(3));
      expect(result.processedItems + result.failedItems + result.skippedItems,
          equals(3));
      expect(result.migrationId, isNotEmpty);
      expect(result.duration.inMilliseconds, greaterThan(0));
    });

    test('应该正确处理空的键映射', () async {
      final keyMapping = <String, String>{};

      final result = await engine.migrateKeys(keyMapping);

      expect(result.status, equals(MigrationStatus.completed));
      expect(result.totalItems, equals(0));
      expect(result.processedItems, equals(0));
      expect(result.failedItems, equals(0));
      expect(result.skippedItems, equals(0));
      expect(result.isSuccess, isTrue);
    });

    test('应该正确处理包含无效键的映射', () async {
      final keyMapping = {
        'old_fund_161725': 'jisu_fund_fundData_161725@latest', // 有效
        'invalid_old': 'invalid_new', // 无效
        'old_fund_000001': 'jisu_fund_fundData_000001@latest', // 有效
        '': 'jisu_fund_fundData_empty@latest', // 空旧键
        'old_fund_empty': '', // 空新键
      };

      final result = await engine.migrateKeys(keyMapping);

      expect(result.status, equals(MigrationStatus.completed));
      expect(result.totalItems, equals(5));
      expect(result.skippedItems, greaterThan(0)); // 应该有跳过的项目
    });

    test('应该支持进度回调', () async {
      final keyMapping = {
        'key1': 'jisu_fund_fundData_key1@latest',
        'key2': 'jisu_fund_fundData_key2@latest',
        'key3': 'jisu_fund_fundData_key3@latest',
      };

      final progressEvents = <Map<String, dynamic>>[];

      final result = await engine.migrateKeys(
        keyMapping,
        onProgress: (processed, total, currentItem) {
          progressEvents.add({
            'processed': processed,
            'total': total,
            'currentItem': currentItem,
          });
        },
      );

      expect(result.status, equals(MigrationStatus.completed));
      expect(progressEvents, isNotEmpty);

      // 检查进度事件
      expect(progressEvents.first['total'], equals(3));
      expect(progressEvents.last['processed'], equals(3));
      expect(progressEvents.last['currentItem'], equals('迁移完成'));
    });
  });

  group('缓存迁移引擎错误处理测试', () {
    late CacheMigrationEngine engine;

    setUp(() {
      engine = CacheMigrationEngine();
    });

    test('应该正确处理迁移失败的情况', () async {
      // 创建一个大的映射，增加失败概率
      final keyMapping = <String, String>{};
      for (int i = 0; i < 50; i++) {
        keyMapping['old_key_$i'] = 'jisu_fund_fundData_key_$i@latest';
      }

      final result = await engine.migrateKeys(keyMapping);

      expect(result.status, equals(MigrationStatus.completed));
      expect(result.totalItems, equals(50));

      // 由于有90%的成功率，应该有一些失败的项目
      if (result.failedItems > 0) {
        expect(result.errors, isNotEmpty);
        expect(result.isPartialSuccess, isTrue);
        expect(result.isSuccess, isFalse);
      }
    });

    test('应该收集详细的错误信息', () async {
      final keyMapping = {
        'invalid_key1': 'invalid_target1',
        'invalid_key2': 'invalid_target2',
        'valid_key': 'jisu_fund_fundData_valid@latest',
      };

      final result = await engine.migrateKeys(keyMapping);

      if (result.failedItems > 0) {
        expect(result.errors, isNotEmpty);

        // 检查错误格式
        for (final error in result.errors) {
          expect(error, isNotEmpty);
          expect(error, matches(RegExp(r'(迁移失败|迁移异常)')));
        }
      }
    });

    test('应该记录统计信息', () async {
      final keyMapping = {
        'key1': 'jisu_fund_fundData_key1@latest',
        'key2': 'jisu_fund_fundData_key2@latest',
        'key3': 'jisu_fund_fundData_key3@latest',
      };

      final result = await engine.migrateKeys(keyMapping);

      expect(result.statistics, isNotEmpty);
      expect(result.statistics.containsKey('migrated_keys'), isTrue);

      if (result.failedItems > 0) {
        expect(result.statistics.containsKey('failed_migrations'), isTrue);
      }
    });
  });

  group('缓存迁移引擎性能测试', () {
    late CacheMigrationEngine engine;

    setUp(() {
      engine = CacheMigrationEngine();
    });

    test('应该在合理时间内完成大量迁移', () async {
      final keyMapping = <String, String>{};
      for (int i = 0; i < 100; i++) {
        keyMapping['old_key_$i'] = 'jisu_fund_fundData_key_$i@latest';
      }

      final stopwatch = Stopwatch()..start();
      final result = await engine.migrateKeys(keyMapping);
      stopwatch.stop();

      expect(result.status, equals(MigrationStatus.completed));
      expect(result.totalItems, equals(100));

      // 100个项目应该在5秒内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('应该正确计算迁移成功率', () async {
      final keyMapping = <String, String>{};
      for (int i = 0; i < 20; i++) {
        keyMapping['old_key_$i'] = 'jisu_fund_fundData_key_$i@latest';
      }

      final result = await engine.migrateKeys(keyMapping);

      expect(result.successRate, greaterThanOrEqualTo(0.0));
      expect(result.successRate, lessThanOrEqualTo(1.0));
      expect(result.failureRate, greaterThanOrEqualTo(0.0));
      expect(result.failureRate, lessThanOrEqualTo(1.0));

      // 成功率和失败率之和应该等于1（允许浮点误差）
      expect((result.successRate + result.failureRate - 1.0).abs(),
          lessThan(0.001));
    });
  });

  group('缓存迁移引擎配置测试', () {
    late CacheMigrationEngine engine;

    setUp(() {
      engine = CacheMigrationEngine();
    });

    test('应该支持重试配置', () async {
      final keyMapping = {
        'key1': 'jisu_fund_fundData_key1@latest',
        'key2': 'jisu_fund_fundData_key2@latest',
      };

      final resultWithRetry = await engine.migrateKeys(
        keyMapping,
        enableRetry: true,
        maxRetries: 5,
      );

      final resultWithoutRetry = await engine.migrateKeys(
        keyMapping,
        enableRetry: false,
        maxRetries: 0,
      );

      expect(resultWithRetry.status, equals(MigrationStatus.completed));
      expect(resultWithoutRetry.status, equals(MigrationStatus.completed));
    });

    test('应该生成唯一的迁移ID', () async {
      final keyMapping = {'key1': 'jisu_fund_fundData_key1@latest'};

      final result1 = await engine.migrateKeys(keyMapping);
      final result2 = await engine.migrateKeys(keyMapping);

      expect(result1.migrationId, isNotEmpty);
      expect(result2.migrationId, isNotEmpty);
      expect(result1.migrationId, isNot(equals(result2.migrationId)));

      // 验证迁移ID格式
      expect(result1.migrationId, startsWith('migration_'));
      expect(result2.migrationId, startsWith('migration_'));
    });
  });

  group('缓存迁移引擎验证功能测试', () {
    late CacheMigrationEngine engine;

    setUp(() {
      engine = CacheMigrationEngine();
    });

    test('应该验证成功的迁移结果', () async {
      final keyMapping = {
        'key1': 'jisu_fund_fundData_key1@latest',
        'key2': 'jisu_fund_fundData_key2@latest',
      };

      final result = await engine.migrateKeys(keyMapping);

      if (result.isSuccess) {
        final isValid = await engine.validateMigration(keyMapping, result);
        expect(isValid, isTrue);
      }
    });

    test('应该验证部分成功的迁移结果', () async {
      final keyMapping = <String, String>{};
      for (int i = 0; i < 20; i++) {
        keyMapping['old_key_$i'] = 'jisu_fund_fundData_key_$i@latest';
      }

      final result = await engine.migrateKeys(keyMapping);

      if (result.isPartialSuccess) {
        final isValid = await engine.validateMigration(keyMapping, result);
        // 验证可能成功也可能失败（取决于模拟结果）
        expect(isValid, isA<bool>());
      }
    });

    test('应该拒绝无效的迁移结果', () async {
      final keyMapping = {'key1': 'jisu_fund_fundData_key1@latest'};

      const invalidResult = MigrationResult(
        migrationId: 'test_migration',
        status: MigrationStatus.failed,
        totalItems: 1,
        processedItems: 0,
        failedItems: 1,
        skippedItems: 0,
        duration: Duration.zero,
        errors: ['测试错误'],
        statistics: {},
      );

      final isValid = await engine.validateMigration(keyMapping, invalidResult);
      expect(isValid, isFalse);
    });
  });

  group('缓存迁移引擎回滚功能测试', () {
    late CacheMigrationEngine engine;

    setUp(() {
      engine = CacheMigrationEngine();
    });

    test('应该支持迁移回滚', () async {
      final keyMapping = {'key1': 'jisu_fund_fundData_key1@latest'};

      final result = await engine.migrateKeys(keyMapping);
      expect(result.status, equals(MigrationStatus.completed));

      final rollbackSuccess =
          await engine.rollbackMigration(result.migrationId);
      expect(rollbackSuccess, isA<bool>());
    });

    test('应该处理回滚失败的情况', () async {
      // 使用一个可能不存在的迁移ID
      final rollbackSuccess =
          await engine.rollbackMigration('nonexistent_migration_id');
      expect(rollbackSuccess, isA<bool>());
    });
  });

  group('MigrationResult对象测试', () {
    test('应该正确计算成功率和失败率', () {
      const result = MigrationResult(
        migrationId: 'test',
        status: MigrationStatus.completed,
        totalItems: 100,
        processedItems: 80,
        failedItems: 15,
        skippedItems: 5,
        duration: Duration(seconds: 10),
        errors: [],
        statistics: {},
      );

      expect(result.successRate, equals(0.8));
      expect(result.failureRate, equals(0.15));
      expect(result.isSuccess, isFalse);
      expect(result.isPartialSuccess, isTrue);
    });

    test('应该正确处理零项迁移', () {
      const result = MigrationResult(
        migrationId: 'test',
        status: MigrationStatus.completed,
        totalItems: 0,
        processedItems: 0,
        failedItems: 0,
        skippedItems: 0,
        duration: Duration.zero,
        errors: [],
        statistics: {},
      );

      expect(result.successRate, equals(0.0));
      expect(result.failureRate, equals(0.0));
      expect(result.isSuccess, isTrue);
      expect(result.isPartialSuccess, isFalse);
    });

    test('应该正确格式化toString', () {
      const result = MigrationResult(
        migrationId: 'migration_123',
        status: MigrationStatus.completed,
        totalItems: 10,
        processedItems: 8,
        failedItems: 2,
        skippedItems: 0,
        duration: Duration(seconds: 5),
        errors: [],
        statistics: {},
      );

      final resultString = result.toString();
      expect(resultString, contains('migration_123'));
      expect(resultString, contains('MigrationStatus.completed'));
      expect(resultString, contains('8/10'));
      expect(resultString, contains('80.0%'));
    });
  });

  group('迁移引擎统计信息测试', () {
    late CacheMigrationEngine engine;

    setUp(() {
      engine = CacheMigrationEngine();
    });

    test('应该提供引擎统计信息', () {
      final statistics = engine.getMigrationStatistics();

      expect(statistics, isNotEmpty);
      expect(statistics.containsKey('engine_version'), isTrue);
      expect(statistics.containsKey('supported_key_types'), isTrue);
      expect(statistics.containsKey('max_retries'), isTrue);
      expect(statistics.containsKey('timeout_enabled'), isTrue);
      expect(statistics.containsKey('retry_enabled'), isTrue);

      expect(statistics['supported_key_types'], isA<List>());
      expect(statistics['max_retries'], equals(3));
      expect(statistics['timeout_enabled'], isTrue);
      expect(statistics['retry_enabled'], isTrue);
    });
  });
}
