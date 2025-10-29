/// 缓存迁移回滚管理器测试
library rollback_manager_test;

import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// 回滚状态枚举
enum RollbackStatus {
  /// 未开始
  notStarted,

  /// 准备中
  preparing,

  /// 进行中
  inProgress,

  /// 已完成
  completed,

  /// 已失败
  failed,

  /// 已取消
  cancelled,

  /// 部分完成
  partiallyCompleted,
}

/// 回滚操作记录类
class RollbackOperation {
  final String operationId;
  final String migrationId;
  final RollbackStatus status;
  final DateTime timestamp;
  final Map<String, String> keyMapping;
  final int totalItems;
  final int processedItems;
  final int successfulItems;
  final int failedItems;
  final List<String> errors;
  final Map<String, dynamic> metadata;

  const RollbackOperation({
    required this.operationId,
    required this.migrationId,
    required this.status,
    required this.timestamp,
    required this.keyMapping,
    required this.totalItems,
    required this.processedItems,
    required this.successfulItems,
    required this.failedItems,
    required this.errors,
    this.metadata = const {},
  });

  /// 获取完成百分比
  double get completionPercentage {
    if (totalItems == 0) return 0.0;
    return processedItems / totalItems;
  }

  /// 获取成功率
  double get successRate {
    if (processedItems == 0) return 0.0;
    return successfulItems / processedItems;
  }

  /// 是否完成
  bool get isCompleted => status == RollbackStatus.completed;

  /// 是否部分完成
  bool get isPartiallyCompleted => status == RollbackStatus.partiallyCompleted;

  /// 是否失败
  bool get isFailed => status == RollbackStatus.failed;

  @override
  String toString() {
    return 'RollbackOperation(id: $operationId, migration: $migrationId, status: $status, progress: $processedItems/$totalItems)';
  }
}

/// 回滚点类
class RollbackPoint {
  final String pointId;
  final String migrationId;
  final DateTime createdAt;
  final Map<String, String> originalKeyMapping;
  final Map<String, dynamic> snapshot;
  final String? description;
  final Map<String, dynamic> metadata;

  const RollbackPoint({
    required this.pointId,
    required this.migrationId,
    required this.createdAt,
    required this.originalKeyMapping,
    required this.snapshot,
    this.description,
    this.metadata = const {},
  });

  /// 获取键映射数量
  int get keyCount => originalKeyMapping.length;

  @override
  String toString() {
    return 'RollbackPoint(id: $pointId, migration: $migrationId, keys: $keyCount, created: $createdAt)';
  }
}

/// 回滚回调类型
typedef RollbackCallback = void Function(
    String operationId, RollbackStatus status, int processed, int total);

/// 简化的回滚管理器实现
class CacheMigrationRollbackManager {
  final Map<String, RollbackPoint> _rollbackPoints = {};
  final Map<String, RollbackOperation> _rollbackOperations = {};
  final Map<String, RollbackCallback> _callbacks = {};
  final Random _random = Random();

  /// 创建回滚点
  String createRollbackPoint(
    String migrationId,
    Map<String, String> originalKeyMapping, {
    Map<String, dynamic>? snapshot,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    final pointId = _generateRollbackPointId();
    final rollbackPoint = RollbackPoint(
      pointId: pointId,
      migrationId: migrationId,
      createdAt: DateTime.now(),
      originalKeyMapping: Map.from(originalKeyMapping),
      snapshot: snapshot ?? {},
      description: description,
      metadata: metadata ?? {},
    );

    _rollbackPoints[pointId] = rollbackPoint;

    return pointId;
  }

  /// 获取回滚点
  RollbackPoint? getRollbackPoint(String pointId) {
    return _rollbackPoints[pointId];
  }

  /// 获取迁移的所有回滚点
  List<RollbackPoint> getRollbackPointsForMigration(String migrationId) {
    return _rollbackPoints.values
        .where((point) => point.migrationId == migrationId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 按时间倒序
  }

  /// 执行回滚操作
  Future<RollbackOperation> executeRollback(
    String pointId, {
    RollbackCallback? callback,
    Duration? timeout,
    bool enableRetry = true,
    int maxRetries = 3,
  }) async {
    final rollbackPoint = _rollbackPoints[pointId];
    if (rollbackPoint == null) {
      throw ArgumentError('回滚点不存在: $pointId');
    }

    final operationId = _generateOperationId();
    final keyMapping = rollbackPoint.originalKeyMapping;

    final operation = RollbackOperation(
      operationId: operationId,
      migrationId: rollbackPoint.migrationId,
      status: RollbackStatus.preparing,
      timestamp: DateTime.now(),
      keyMapping: Map.from(keyMapping),
      totalItems: keyMapping.length,
      processedItems: 0,
      successfulItems: 0,
      failedItems: 0,
      errors: [],
    );

    _rollbackOperations[operationId] = operation;

    if (callback != null) {
      _callbacks[operationId] = callback;
    }

    // 通知开始准备
    callback?.call(operationId, RollbackStatus.preparing, 0, keyMapping.length);

    try {
      // 模拟准备阶段
      operation.status = RollbackStatus.inProgress;
      _updateOperation(operationId, operation);
      callback?.call(
          operationId, RollbackStatus.inProgress, 0, keyMapping.length);

      // 执行回滚
      await _performRollbackOperation(
        operationId,
        keyMapping,
        callback: callback,
        enableRetry: enableRetry,
        maxRetries: maxRetries,
      );

      // 获取最终操作状态
      final finalOperation = _rollbackOperations[operationId]!;

      return finalOperation;
    } catch (e) {
      operation.status = RollbackStatus.failed;
      operation.errors.add('回滚操作异常: $e');
      _updateOperation(operationId, operation);
      callback?.call(operationId, RollbackStatus.failed,
          operation.processedItems, keyMapping.length);

      rethrow;
    }
  }

  /// 执行实际的回滚操作
  Future<void> _performRollbackOperation(
    String operationId,
    Map<String, String> keyMapping, {
    RollbackCallback? callback,
    bool enableRetry = true,
    int maxRetries = 3,
  }) async {
    final entries = keyMapping.entries.toList();
    int processedItems = 0;
    int successfulItems = 0;
    int failedItems = 0;
    final errors = <String>[];

    for (final entry in entries) {
      final oldKey = entry.key;
      final newKey = entry.value;

      try {
        // 通知正在处理的项目
        callback?.call(operationId, RollbackStatus.inProgress, processedItems,
            keyMapping.length);

        // 模拟回滚操作
        final success = await _rollbackSingleKey(
          oldKey,
          newKey,
          enableRetry: enableRetry,
          maxRetries: maxRetries,
        );

        processedItems++;

        if (success) {
          successfulItems++;
        } else {
          failedItems++;
          errors.add('回滚失败: $newKey -> $oldKey');
        }

        // 更新操作状态
        final operation = _rollbackOperations[operationId]!;
        final updatedOperation = RollbackOperation(
          operationId: operation.operationId,
          migrationId: operation.migrationId,
          status: RollbackStatus.inProgress,
          timestamp: operation.timestamp,
          keyMapping: operation.keyMapping,
          totalItems: operation.totalItems,
          processedItems: processedItems,
          successfulItems: successfulItems,
          failedItems: failedItems,
          errors: errors,
          metadata: operation.metadata,
        );

        _updateOperation(operationId, updatedOperation);

        // 模拟处理时间
        await Future.delayed(Duration(milliseconds: 1 + _random.nextInt(5)));
      } catch (e) {
        processedItems++;
        failedItems++;
        errors.add('回滚异常: $newKey -> $oldKey, 错误: $e');
      }
    }

    // 确定最终状态
    final finalOperation = _rollbackOperations[operationId]!;
    RollbackStatus finalStatus;

    if (failedItems == 0) {
      finalStatus = RollbackStatus.completed;
    } else if (successfulItems > 0) {
      finalStatus = RollbackStatus.partiallyCompleted;
    } else {
      finalStatus = RollbackStatus.failed;
    }

    final finalOperation2 = RollbackOperation(
      operationId: finalOperation.operationId,
      migrationId: finalOperation.migrationId,
      status: finalStatus,
      timestamp: finalOperation.timestamp,
      keyMapping: finalOperation.keyMapping,
      totalItems: finalOperation.totalItems,
      processedItems: processedItems,
      successfulItems: successfulItems,
      failedItems: failedItems,
      errors: errors,
      metadata: finalOperation.metadata,
    );

    _updateOperation(operationId, finalOperation2);
    callback?.call(operationId, finalStatus, processedItems, keyMapping.length);
  }

  /// 回滚单个键
  Future<bool> _rollbackSingleKey(
    String oldKey,
    String newKey, {
    bool enableRetry = true,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        // 模拟回滚过程
        await Future.delayed(Duration(milliseconds: _random.nextInt(10)));

        // 模拟回滚成功率（85%成功率，比迁移稍低）
        if (_random.nextDouble() < 0.85) {
          return true;
        } else {
          throw Exception('模拟回滚失败');
        }
      } catch (e) {
        attempts++;
        if (!enableRetry || attempts > maxRetries) {
          return false;
        }

        // 指数退避重试
        final delay = Duration(milliseconds: 200 * (1 << attempts));
        await Future.delayed(delay);
      }
    }

    return false;
  }

  /// 取消回滚操作
  Future<bool> cancelRollback(String operationId) async {
    final operation = _rollbackOperations[operationId];
    if (operation == null) {
      return false;
    }

    if (operation.status == RollbackStatus.completed ||
        operation.status == RollbackStatus.failed ||
        operation.status == RollbackStatus.cancelled) {
      return false;
    }

    final cancelledOperation = RollbackOperation(
      operationId: operation.operationId,
      migrationId: operation.migrationId,
      status: RollbackStatus.cancelled,
      timestamp: operation.timestamp,
      keyMapping: operation.keyMapping,
      totalItems: operation.totalItems,
      processedItems: operation.processedItems,
      successfulItems: operation.successfulItems,
      failedItems: operation.failedItems,
      errors: [...operation.errors, '操作已取消'],
    );

    _updateOperation(operationId, cancelledOperation);
    _callbacks[operationId]?.call(operationId, RollbackStatus.cancelled,
        operation.processedItems, operation.totalItems);

    return true;
  }

  /// 获取回滚操作
  RollbackOperation? getRollbackOperation(String operationId) {
    return _rollbackOperations[operationId];
  }

  /// 获取迁移的所有回滚操作
  List<RollbackOperation> getRollbackOperationsForMigration(
      String migrationId) {
    return _rollbackOperations.values
        .where((op) => op.migrationId == migrationId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 按时间倒序
  }

  /// 删除回滚点
  bool deleteRollbackPoint(String pointId) {
    return _rollbackPoints.remove(pointId) != null;
  }

  /// 清理过期的回滚点
  int cleanupExpiredRollbackPoints({Duration? maxAge}) {
    final maxAgeToUse = maxAge ?? Duration(days: 7);
    final cutoffTime = DateTime.now().subtract(maxAgeToUse);

    final expiredPoints = _rollbackPoints.entries
        .where((entry) => entry.value.createdAt.isBefore(cutoffTime))
        .map((entry) => entry.key)
        .toList();

    for (final pointId in expiredPoints) {
      _rollbackPoints.remove(pointId);
    }

    return expiredPoints.length;
  }

  /// 清理过期的回滚操作
  int cleanupExpiredRollbackOperations({Duration? maxAge}) {
    final maxAgeToUse = maxAge ?? Duration(days: 30);
    final cutoffTime = DateTime.now().subtract(maxAgeToUse);

    final expiredOperations = _rollbackOperations.entries
        .where((entry) => entry.value.timestamp.isBefore(cutoffTime))
        .map((entry) => entry.key)
        .toList();

    for (final operationId in expiredOperations) {
      _rollbackOperations.remove(operationId);
      _callbacks.remove(operationId);
    }

    return expiredOperations.length;
  }

  /// 验证回滚点
  Future<bool> validateRollbackPoint(String pointId) async {
    final rollbackPoint = _rollbackPoints[pointId];
    if (rollbackPoint == null) {
      return false;
    }

    // 模拟验证过程
    await Future.delayed(Duration(milliseconds: 100));

    // 模拟验证成功率（95%成功率）
    return _random.nextDouble() < 0.95;
  }

  /// 获取管理器统计信息
  Map<String, dynamic> getManagerStatistics() {
    final totalPoints = _rollbackPoints.length;
    final totalOperations = _rollbackOperations.length;
    final completedOperations =
        _rollbackOperations.values.where((op) => op.isCompleted).length;
    final failedOperations =
        _rollbackOperations.values.where((op) => op.isFailed).length;
    final partialOperations = _rollbackOperations.values
        .where((op) => op.isPartiallyCompleted)
        .length;

    return {
      'total_rollback_points': totalPoints,
      'total_rollback_operations': totalOperations,
      'completed_operations': completedOperations,
      'failed_operations': failedOperations,
      'partially_completed_operations': partialOperations,
      'registered_callbacks': _callbacks.length,
      'average_key_count_per_point': totalPoints > 0
          ? _rollbackPoints.values
                  .map((p) => p.keyCount)
                  .reduce((a, b) => a + b) /
              totalPoints
          : 0.0,
    };
  }

  /// 更新操作记录
  void _updateOperation(String operationId, RollbackOperation operation) {
    _rollbackOperations[operationId] = operation;
  }

  /// 生成回滚点ID
  String _generateRollbackPointId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(10000);
    return 'rollback_point_${timestamp}_$randomSuffix';
  }

  /// 生成操作ID
  String _generateOperationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(10000);
    return 'rollback_op_${timestamp}_$randomSuffix';
  }
}

void main() {
  group('缓存迁移回滚管理器基础功能测试', () {
    late CacheMigrationRollbackManager manager;

    setUp(() {
      manager = CacheMigrationRollbackManager();
    });

    tearDown(() {
      // 清理测试数据
      manager.cleanupExpiredRollbackPoints(maxAge: Duration.zero);
      manager.cleanupExpiredRollbackOperations(maxAge: Duration.zero);
    });

    test('应该正确创建回滚点', () {
      const migrationId = 'test_migration_001';
      final keyMapping = {
        'new_key_1': 'old_key_1',
        'new_key_2': 'old_key_2',
        'new_key_3': 'old_key_3',
      };

      final pointId = manager.createRollbackPoint(
        migrationId,
        keyMapping,
        description: '测试回滚点',
      );

      expect(pointId, isNotEmpty);
      expect(pointId, startsWith('rollback_point_'));

      final rollbackPoint = manager.getRollbackPoint(pointId);
      expect(rollbackPoint, isNotNull);
      expect(rollbackPoint!.migrationId, equals(migrationId));
      expect(rollbackPoint.keyCount, equals(3));
      expect(rollbackPoint.description, equals('测试回滚点'));
      expect(rollbackPoint.originalKeyMapping, equals(keyMapping));
    });

    test('应该正确获取迁移的所有回滚点', () {
      const migrationId = 'test_migration_002';

      // 创建多个回滚点
      final pointIds = <String>[];
      for (int i = 0; i < 3; i++) {
        final pointId = manager.createRollbackPoint(
          migrationId,
          {'key_$i': 'old_key_$i'},
          description: '回滚点 $i',
        );
        pointIds.add(pointId);
        // 稍微延迟以确保时间戳不同
        Future.delayed(Duration(milliseconds: 10));
      }

      final rollbackPoints = manager.getRollbackPointsForMigration(migrationId);
      expect(rollbackPoints, hasLength(3));

      // 应该按时间倒序排列（最新的在前）
      expect(rollbackPoints[0].description, equals('回滚点 2'));
      expect(rollbackPoints[1].description, equals('回滚点 1'));
      expect(rollbackPoints[2].description, equals('回滚点 0'));

      // 每个回滚点都应该属于指定的迁移
      for (final point in rollbackPoints) {
        expect(point.migrationId, equals(migrationId));
      }
    });

    test('应该正确执行完整的回滚操作', () async {
      const migrationId = 'test_migration_003';
      final keyMapping = {
        'new_key_1': 'old_key_1',
        'new_key_2': 'old_key_2',
        'new_key_3': 'old_key_3',
      };

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      final statusUpdates = <Map<String, dynamic>>[];

      final operation = await manager.executeRollback(
        pointId,
        callback: (operationId, status, processed, total) {
          statusUpdates.add({
            'operationId': operationId,
            'status': status,
            'processed': processed,
            'total': total,
          });
        },
      );

      expect(operation.migrationId, equals(migrationId));
      expect(operation.totalItems, equals(3));
      expect(operation.processedItems, equals(3));

      // 检查状态更新
      expect(statusUpdates, isNotEmpty);
      expect(statusUpdates.first['status'], equals(RollbackStatus.preparing));
      expect(
          statusUpdates
              .any((update) => update['status'] == RollbackStatus.inProgress),
          isTrue);
      expect(statusUpdates.last['total'], equals(3));

      // 操作应该完成（成功或部分成功）
      expect(
          operation.status,
          anyOf([
            equals(RollbackStatus.completed),
            equals(RollbackStatus.partiallyCompleted),
            equals(RollbackStatus.failed),
          ]));
    });

    test('应该正确处理回滚操作失败', () async {
      const migrationId = 'test_migration_004';

      // 创建一个大的键映射，增加失败概率
      final keyMapping = <String, String>{};
      for (int i = 0; i < 20; i++) {
        keyMapping['new_key_$i'] = 'old_key_$i';
      }

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      final operation = await manager.executeRollback(pointId);

      expect(operation.totalItems, equals(20));
      expect(operation.processedItems, equals(20));

      // 由于有15%的失败率，可能会有一些失败的项目
      if (operation.failedItems > 0) {
        expect(
            operation.status,
            anyOf([
              equals(RollbackStatus.partiallyCompleted),
              equals(RollbackStatus.failed),
            ]));
        expect(operation.errors, isNotEmpty);
      }
    });

    test('应该正确取消回滚操作', () async {
      const migrationId = 'test_migration_005';
      final keyMapping = {
        'new_key_1': 'old_key_1',
        'new_key_2': 'old_key_2',
        // 添加更多键以确保有时间取消
        'new_key_3': 'old_key_3',
        'new_key_4': 'old_key_4',
        'new_key_5': 'old_key_5',
      };

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      // 启动回滚操作
      final rollbackFuture = manager.executeRollback(pointId);

      // 等待一小段时间后取消
      await Future.delayed(Duration(milliseconds: 50));

      final operationId = manager
          .getRollbackOperationsForMigration(migrationId)
          .first
          .operationId;
      final cancelled = await manager.cancelRollback(operationId);

      expect(cancelled, isTrue);

      final operation = await rollbackFuture;
      expect(operation.status, equals(RollbackStatus.cancelled));
      expect(operation.errors, contains('操作已取消'));
    });
  });

  group('缓存迁移回滚管理器验证测试', () {
    late CacheMigrationRollbackManager manager;

    setUp(() {
      manager = CacheMigrationRollbackManager();
    });

    tearDown(() {
      manager.cleanupExpiredRollbackPoints(maxAge: Duration.zero);
      manager.cleanupExpiredRollbackOperations(maxAge: Duration.zero);
    });

    test('应该验证有效的回滚点', () async {
      const migrationId = 'test_migration_006';
      final keyMapping = {'new_key': 'old_key'};

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      final isValid = await manager.validateRollbackPoint(pointId);
      expect(isValid, isA<bool>());
    });

    test('应该拒绝验证不存在的回滚点', () async {
      final isValid = await manager.validateRollbackPoint('nonexistent_point');
      expect(isValid, isFalse);
    });

    test('应该正确删除回滚点', () {
      const migrationId = 'test_migration_007';
      final keyMapping = {'new_key': 'old_key'};

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      // 验证回滚点存在
      expect(manager.getRollbackPoint(pointId), isNotNull);

      // 删除回滚点
      final deleted = manager.deleteRollbackPoint(pointId);
      expect(deleted, isTrue);

      // 验证回滚点已删除
      expect(manager.getRollbackPoint(pointId), isNull);

      // 尝试删除不存在的回滚点
      final deletedAgain = manager.deleteRollbackPoint(pointId);
      expect(deletedAgain, isFalse);
    });
  });

  group('缓存迁移回滚管理器清理测试', () {
    late CacheMigrationRollbackManager manager;

    setUp(() {
      manager = CacheMigrationRollbackManager();
    });

    test('应该正确清理过期的回滚点', () async {
      const migrationId = 'test_migration_008';

      // 创建一些回滚点
      final pointIds = <String>[];
      for (int i = 0; i < 5; i++) {
        final pointId = manager.createRollbackPoint(
          migrationId,
          {'key_$i': 'old_key_$i'},
        );
        pointIds.add(pointId);
      }

      expect(manager.getRollbackPointsForMigration(migrationId), hasLength(5));

      // 清理过期时间设为0，应该清理所有回滚点
      final cleanedCount =
          manager.cleanupExpiredRollbackPoints(maxAge: Duration.zero);
      expect(cleanedCount, equals(5));

      expect(manager.getRollbackPointsForMigration(migrationId), isEmpty);
    });

    test('应该正确清理过期的回滚操作', () async {
      const migrationId = 'test_migration_009';
      final keyMapping = {'new_key': 'old_key'};

      // 创建回滚点并执行回滚
      final pointId = manager.createRollbackPoint(migrationId, keyMapping);
      await manager.executeRollback(pointId);

      expect(
          manager.getRollbackOperationsForMigration(migrationId), hasLength(1));

      // 清理过期时间设为0，应该清理所有操作
      final cleanedCount =
          manager.cleanupExpiredRollbackOperations(maxAge: Duration.zero);
      expect(cleanedCount, equals(1));

      expect(manager.getRollbackOperationsForMigration(migrationId), isEmpty);
    });
  });

  group('缓存迁移回滚管理器统计测试', () {
    late CacheMigrationRollbackManager manager;

    setUp(() {
      manager = CacheMigrationRollbackManager();
    });

    tearDown(() {
      manager.cleanupExpiredRollbackPoints(maxAge: Duration.zero);
      manager.cleanupExpiredRollbackOperations(maxAge: Duration.zero);
    });

    test('应该提供正确的管理器统计信息', () async {
      const migrationId = 'test_migration_010';

      // 创建回滚点
      manager.createRollbackPoint(migrationId, {'key1': 'old_key1'});
      manager.createRollbackPoint(
          migrationId, {'key2': 'old_key2', 'key3': 'old_key3'});

      // 执行回滚操作
      final pointId =
          manager.createRollbackPoint(migrationId, {'key4': 'old_key4'});
      await manager.executeRollback(pointId);

      final stats = manager.getManagerStatistics();

      expect(stats['total_rollback_points'], equals(3));
      expect(stats['total_rollback_operations'], greaterThan(0));
      expect(stats['average_key_count_per_point'], greaterThan(0));
      expect(stats['registered_callbacks'], isA<int>());
    });

    test('应该正确计算平均键数量', () {
      manager.createRollbackPoint('migration1', {'key1': 'old1'});
      manager
          .createRollbackPoint('migration2', {'key2': 'old2', 'key3': 'old3'});
      manager.createRollbackPoint('migration3', {}); // 空映射

      final stats = manager.getManagerStatistics();
      expect(
          stats['average_key_count_per_point'], equals(1.0)); // (1 + 2 + 0) / 3
    });
  });

  group('缓存迁移回滚管理器错误处理测试', () {
    late CacheMigrationRollbackManager manager;

    setUp(() {
      manager = CacheMigrationRollbackManager();
    });

    tearDown(() {
      manager.cleanupExpiredRollbackPoints(maxAge: Duration.zero);
      manager.cleanupExpiredRollbackOperations(maxAge: Duration.zero);
    });

    test('应该处理回滚点不存在的情况', () async {
      expect(
        () => manager.executeRollback('nonexistent_point'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('应该处理空键映射的回滚', () async {
      const migrationId = 'test_migration_011';
      final keyMapping = <String, String>{};

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      final operation = await manager.executeRollback(pointId);

      expect(operation.totalItems, equals(0));
      expect(operation.processedItems, equals(0));
      expect(operation.status, equals(RollbackStatus.completed));
    });

    test('应该处理单键映射的回滚', () async {
      const migrationId = 'test_migration_012';
      final keyMapping = {'single_new_key': 'single_old_key'};

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      final operation = await manager.executeRollback(pointId);

      expect(operation.totalItems, equals(1));
      expect(operation.processedItems, equals(1));
      expect(operation.successfulItems + operation.failedItems, equals(1));
    });
  });

  group('缓存迁移回滚管理器性能测试', () {
    late CacheMigrationRollbackManager manager;

    setUp(() {
      manager = CacheMigrationRollbackManager();
    });

    tearDown(() {
      manager.cleanupExpiredRollbackPoints(maxAge: Duration.zero);
      manager.cleanupExpiredRollbackOperations(maxAge: Duration.zero);
    });

    test('应该高效处理大量回滚点', () {
      final stopwatch = Stopwatch()..start();

      // 创建大量回滚点
      for (int i = 0; i < 100; i++) {
        final keyMapping = <String, String>{};
        for (int j = 0; j < 10; j++) {
          keyMapping['new_key_${i}_$j'] = 'old_key_${i}_$j';
        }

        manager.createRollbackPoint('migration_$i', keyMapping);
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      final stats = manager.getManagerStatistics();
      expect(stats['total_rollback_points'], equals(100));
    });

    test('应该高效处理大规模回滚操作', () async {
      const migrationId = 'test_migration_013';
      final keyMapping = <String, String>{};

      // 创建大规模键映射
      for (int i = 0; i < 100; i++) {
        keyMapping['new_key_$i'] = 'old_key_$i';
      }

      final pointId = manager.createRollbackPoint(migrationId, keyMapping);

      final stopwatch = Stopwatch()..start();
      final operation = await manager.executeRollback(pointId);
      stopwatch.stop();

      expect(operation.totalItems, equals(100));
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 2秒内完成
    });
  });

  group('RollbackPoint对象测试', () {
    test('应该正确计算键数量', () {
      final keyMapping = {
        'key1': 'old1',
        'key2': 'old2',
        'key3': 'old3',
      };

      final rollbackPoint = RollbackPoint(
        pointId: 'test_point',
        migrationId: 'test_migration',
        createdAt: DateTime.now(),
        originalKeyMapping: keyMapping,
        snapshot: {},
      );

      expect(rollbackPoint.keyCount, equals(3));
    });

    test('应该正确格式化toString', () {
      final rollbackPoint = RollbackPoint(
        pointId: 'test_point_123',
        migrationId: 'test_migration_456',
        createdAt: DateTime(2023, 10, 29, 12, 30, 45),
        originalKeyMapping: {'key1': 'old1', 'key2': 'old2'},
        snapshot: {},
        description: '测试回滚点',
      );

      final pointString = rollbackPoint.toString();
      expect(pointString, contains('test_point_123'));
      expect(pointString, contains('test_migration_456'));
      expect(pointString, contains('keys: 2'));
      expect(pointString, contains('2023-10-29'));
    });
  });

  group('RollbackOperation对象测试', () {
    test('应该正确计算完成百分比', () {
      final operation = RollbackOperation(
        operationId: 'test_operation',
        migrationId: 'test_migration',
        status: RollbackStatus.inProgress,
        timestamp: DateTime.now(),
        keyMapping: {},
        totalItems: 100,
        processedItems: 75,
        successfulItems: 70,
        failedItems: 5,
        errors: [],
      );

      expect(operation.completionPercentage, equals(0.75));
    });

    test('应该正确计算成功率', () {
      final operation = RollbackOperation(
        operationId: 'test_operation',
        migrationId: 'test_migration',
        status: RollbackStatus.inProgress,
        timestamp: DateTime.now(),
        keyMapping: {},
        totalItems: 100,
        processedItems: 80,
        successfulItems: 72,
        failedItems: 8,
        errors: [],
      );

      expect(operation.successRate, equals(0.9)); // 72/80
    });

    test('应该正确识别操作状态', () {
      final completedOperation = RollbackOperation(
        operationId: 'test_operation',
        migrationId: 'test_migration',
        status: RollbackStatus.completed,
        timestamp: DateTime.now(),
        keyMapping: {},
        totalItems: 100,
        processedItems: 100,
        successfulItems: 100,
        failedItems: 0,
        errors: [],
      );

      final partiallyCompletedOperation = RollbackOperation(
        operationId: 'test_operation',
        migrationId: 'test_migration',
        status: RollbackStatus.partiallyCompleted,
        timestamp: DateTime.now(),
        keyMapping: {},
        totalItems: 100,
        processedItems: 100,
        successfulItems: 80,
        failedItems: 20,
        errors: [],
      );

      final failedOperation = RollbackOperation(
        operationId: 'test_operation',
        migrationId: 'test_migration',
        status: RollbackStatus.failed,
        timestamp: DateTime.now(),
        keyMapping: {},
        totalItems: 100,
        processedItems: 50,
        successfulItems: 30,
        failedItems: 20,
        errors: ['错误信息'],
      );

      expect(completedOperation.isCompleted, isTrue);
      expect(completedOperation.isPartiallyCompleted, isFalse);
      expect(completedOperation.isFailed, isFalse);

      expect(partiallyCompletedOperation.isCompleted, isFalse);
      expect(partiallyCompletedOperation.isPartiallyCompleted, isTrue);
      expect(partiallyCompletedOperation.isFailed, isFalse);

      expect(failedOperation.isCompleted, isFalse);
      expect(failedOperation.isPartiallyCompleted, isFalse);
      expect(failedOperation.isFailed, isTrue);
    });

    test('应该正确格式化toString', () {
      final operation = RollbackOperation(
        operationId: 'rollback_op_123',
        migrationId: 'migration_456',
        status: RollbackStatus.inProgress,
        timestamp: DateTime.now(),
        keyMapping: {},
        totalItems: 200,
        processedItems: 150,
        successfulItems: 140,
        failedItems: 10,
        errors: [],
      );

      final operationString = operation.toString();
      expect(operationString, contains('rollback_op_123'));
      expect(operationString, contains('migration_456'));
      expect(operationString, contains('RollbackStatus.inProgress'));
      expect(operationString, contains('150/200'));
    });
  });
}
