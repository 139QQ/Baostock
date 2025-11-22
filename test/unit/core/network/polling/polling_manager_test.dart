import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_type.dart';
import 'package:jisu_fund_analyzer/src/core/network/hybrid/data_fetch_strategy.dart';
import 'package:jisu_fund_analyzer/src/core/network/polling/polling_manager.dart';

void main() {
  group('PollingTask', () {
    test('应该正确初始化任务', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
        maxRetries: 3,
        timeout: const Duration(seconds: 30),
      );

      expect(task.dataType, DataType.fundNetValue);
      expect(task.interval, const Duration(minutes: 5));
      expect(task.enabled, isTrue);
      expect(task.maxRetries, 3);
      expect(task.timeout, const Duration(seconds: 30));
      expect(task.executionCount, 0);
      expect(task.successCount, 0);
      expect(task.failureCount, 0);
      expect(task.successRate, 0.0);
      expect(task.lastError, isNull);
    });

    test('应该正确记录执行成功', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      final initialTime = DateTime.now();
      task.recordSuccess();

      expect(task.executionCount, 1);
      expect(task.successCount, 1);
      expect(task.failureCount, 0);
      expect(task.successRate, 1.0);
      expect(task.lastError, isNull);
      expect(task.lastExecutionTime.isAfter(initialTime), isTrue);
      expect(task.nextExecutionTime.isAfter(task.lastExecutionTime), isTrue);
    });

    test('应该正确记录执行失败', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      const errorMessage = 'Network error';
      final initialTime = DateTime.now();
      task.recordFailure(errorMessage);

      expect(task.executionCount, 1);
      expect(task.successCount, 0);
      expect(task.failureCount, 1);
      expect(task.successRate, 0.0);
      expect(task.lastError, errorMessage);
      expect(task.lastExecutionTime.isAfter(initialTime), isTrue);
      expect(task.nextExecutionTime.isAfter(task.lastExecutionTime), isTrue);
    });

    test('应该正确计算成功率', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      expect(task.successRate, 0.0);

      task.recordSuccess();
      expect(task.successRate, 1.0);

      task.recordFailure();
      expect(task.successRate, 0.5);

      task.recordSuccess();
      expect(task.successRate, 2 / 3);
    });

    test('应该正确判断是否需要执行', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      expect(task.shouldExecute, isTrue); // 初始化时应该立即执行

      task.recordSuccess();
      expect(task.shouldExecute, isFalse); // 刚执行过，不需要立即执行

      // 模拟时间推进
      task.nextExecutionTime =
          DateTime.now().subtract(const Duration(seconds: 1));
      expect(task.shouldExecute, isTrue); // 超过执行时间，需要执行

      task.enabled = false;
      expect(task.shouldExecute, isFalse); // 禁用的任务不应该执行
    });

    test('应该正确重置统计信息', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      task.recordSuccess();
      task.recordFailure('Test error');

      task.resetStats();

      expect(task.executionCount, 0);
      expect(task.successCount, 0);
      expect(task.failureCount, 0);
      expect(task.successRate, 0.0);
      expect(task.lastError, isNull);
    });

    test('应该正确计算下次执行时间', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
        maxRetries: 3,
      );

      // 正常情况
      final normalNextTime = task.calculateNextExecutionTime();
      expect(normalNextTime.difference(DateTime.now()),
          const Duration(minutes: 5));

      // 重试情况
      task.recordFailure('Error 1');
      final retryNextTime = task.calculateNextExecutionTime(retry: true);
      expect(retryNextTime.difference(DateTime.now()).inSeconds,
          lessThan(75)); // 5分钟/4 = 75秒
    });

    test('应该正确序列化为JSON', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
        maxRetries: 3,
        timeout: const Duration(seconds: 30),
        parameters: {'fundCode': '000001'},
      );

      task.recordSuccess();
      task.recordFailure('Test error');

      final json = task.toJson();

      expect(json['id'], task.id);
      expect(json['dataType'], 'fund_net_value');
      expect(json['interval'], 300); // 5分钟 = 300秒
      expect(json['enabled'], isTrue);
      expect(json['parameters'], {'fundCode': '000001'});
      expect(json['maxRetries'], 3);
      expect(json['timeout'], 30);
      expect(json['executionCount'], 2);
      expect(json['successCount'], 1);
      expect(json['failureCount'], 1);
      expect(json['successRate'], 0.5);
      expect(json['lastError'], 'Test error');
      expect(json['lastExecutionTime'], isA<String>());
      expect(json['nextExecutionTime'], isA<String>());
    });
  });

  group('PollingStatistics', () {
    test('应该正确初始化统计信息', () {
      final stats = PollingStatistics();

      expect(stats.totalExecutions, 0);
      expect(stats.successCount, 0);
      expect(stats.failureCount, 0);
      expect(stats.totalLatencyMs, 0);
      expect(stats.minLatencyMs, 0);
      expect(stats.maxLatencyMs, 0);
      expect(stats.successRate, 0.0);
      expect(stats.averageLatencyMs, 0.0);
      expect(stats.lastExecutionTime, isNull);
    });

    test('应该正确记录执行', () {
      final stats = PollingStatistics();

      // 记录成功执行
      stats.recordExecution(true, const Duration(milliseconds: 100));
      expect(stats.totalExecutions, 1);
      expect(stats.successCount, 1);
      expect(stats.failureCount, 0);
      expect(stats.totalLatencyMs, 100);
      expect(stats.minLatencyMs, 100);
      expect(stats.maxLatencyMs, 100);
      expect(stats.successRate, 1.0);
      expect(stats.averageLatencyMs, 100.0);

      // 记录失败执行
      stats.recordExecution(false, const Duration(milliseconds: 200));
      expect(stats.totalExecutions, 2);
      expect(stats.successCount, 1);
      expect(stats.failureCount, 1);
      expect(stats.totalLatencyMs, 300);
      expect(stats.minLatencyMs, 100);
      expect(stats.maxLatencyMs, 200);
      expect(stats.successRate, 0.5);
      expect(stats.averageLatencyMs, 150.0);
    });

    test('应该正确计算平均值和比率', () {
      final stats = PollingStatistics();

      stats.recordExecution(true, const Duration(milliseconds: 50));
      stats.recordExecution(true, const Duration(milliseconds: 150));
      stats.recordExecution(false, const Duration(milliseconds: 100));

      expect(stats.successRate, 2 / 3);
      expect(stats.averageLatencyMs, 100.0);
    });

    test('应该正确重置统计信息', () {
      final stats = PollingStatistics();

      stats.recordExecution(true, const Duration(milliseconds: 100));
      stats.recordExecution(false, const Duration(milliseconds: 200));

      stats.reset();

      expect(stats.totalExecutions, 0);
      expect(stats.successCount, 0);
      expect(stats.failureCount, 0);
      expect(stats.totalLatencyMs, 0);
      expect(stats.minLatencyMs, 0);
      expect(stats.maxLatencyMs, 0);
      expect(stats.successRate, 0.0);
      expect(stats.averageLatencyMs, 0.0);
      expect(stats.lastExecutionTime, isNull);
    });

    test('应该正确序列化为JSON', () {
      final stats = PollingStatistics();

      stats.recordExecution(true, const Duration(milliseconds: 100));
      stats.recordExecution(false, const Duration(milliseconds: 200));

      final json = stats.toJson();

      expect(json['totalExecutions'], 2);
      expect(json['successCount'], 1);
      expect(json['failureCount'], 1);
      expect(json['successRate'], 0.5);
      expect(json['averageLatencyMs'], 150);
      expect(json['minLatencyMs'], 100);
      expect(json['maxLatencyMs'], 200);
      expect(json['lastExecutionTime'], isA<String>());
    });
  });

  group('PollingManagerState', () {
    test('应该提供正确的状态描述', () {
      expect(PollingManagerState.idle.description, '空闲');
      expect(PollingManagerState.starting.description, '启动中');
      expect(PollingManagerState.running.description, '运行中');
      expect(PollingManagerState.stopping.description, '停止中');
      expect(PollingManagerState.stopped.description, '已停止');
      expect(PollingManagerState.error.description, '错误');
    });
  });

  group('PollingManager - 基础功能测试', () {
    late PollingManager manager;

    setUp(() {
      manager = PollingManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('应该正确初始化并达到idle状态', () {
      expect(manager.state, PollingManagerState.idle);
    });

    test('应该正确更新管理器状态', () async {
      final states = <PollingManagerState>[];
      final subscription = manager.stateStream.listen(states.add);

      await manager.start();
      await manager.stop();

      expect(states, contains(PollingManagerState.idle));
      expect(states, contains(PollingManagerState.starting));
      expect(states, contains(PollingManagerState.running));
      expect(states, contains(PollingManagerState.stopping));
      expect(states, contains(PollingManagerState.stopped));

      await subscription.cancel();
    });

    test('重复启动应该忽略', () async {
      await manager.start();
      await manager.start(); // 第二次启动应该被忽略

      expect(manager.state, PollingManagerState.running);
    });

    test('重复停止应该忽略', () async {
      await manager.start();
      await manager.stop();
      await manager.stop(); // 第二次停止应该被忽略

      expect(manager.state, PollingManagerState.stopped);
    });

    test('应该正确添加轮询任务', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      manager.addTask(task);

      final retrievedTasks = manager.getTasksByDataType(DataType.fundNetValue);
      expect(retrievedTasks, contains(task));
      expect(manager.state, PollingManagerState.idle);
    });

    test('应该正确移除轮询任务', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      manager.addTask(task);
      manager.removeTask(task.id);

      final retrievedTasks = manager.getTasksByDataType(DataType.fundNetValue);
      expect(retrievedTasks, isEmpty);
    });

    test('应该根据数据类型移除任务', () {
      final task1 = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );
      final task2 = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 10),
      );
      final task3 = PollingTask(
        dataType: DataType.marketIndex,
        interval: const Duration(minutes: 1),
      );

      manager.addTask(task1);
      manager.addTask(task2);
      manager.addTask(task3);

      manager.removeTasksByDataType(DataType.fundNetValue);

      expect(manager.getTasksByDataType(DataType.fundNetValue), isEmpty);
      expect(manager.getTasksByDataType(DataType.marketIndex), contains(task3));
    });

    test('应该为相同数据类型创建多个任务', () {
      final task1 = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );
      final task2 = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 10),
      );

      manager.addTask(task1);
      manager.addTask(task2);

      final retrievedTasks = manager.getTasksByDataType(DataType.fundNetValue);
      expect(retrievedTasks.length, 2);
      expect(retrievedTasks, contains(task1));
      expect(retrievedTasks, contains(task2));
    });

    test('应该正确设置默认任务', () {
      // 检查默认任务是否被设置
      final fundNetValueTasks =
          manager.getTasksByDataType(DataType.fundNetValue);
      final fundBasicInfoTasks =
          manager.getTasksByDataType(DataType.fundBasicInfo);
      final marketTradingDataTasks =
          manager.getTasksByDataType(DataType.marketTradingData);
      final dataQualityMetricsTasks =
          manager.getTasksByDataType(DataType.dataQualityMetrics);

      expect(fundNetValueTasks, isNotEmpty);
      expect(fundBasicInfoTasks, isNotEmpty);
      expect(marketTradingDataTasks, isNotEmpty);
      expect(dataQualityMetricsTasks, isNotEmpty);
    });

    test('应该提供数据流', () {
      final stream = manager.getDataStream(DataType.fundNetValue);
      expect(stream, isNotNull);
      expect(stream, isA<Stream<DataItem>>());
    });

    test('应该为不同数据类型提供独立的数据流', () {
      final fundStream = manager.getDataStream(DataType.fundNetValue);
      final marketStream = manager.getDataStream(DataType.marketIndex);

      expect(fundStream, isNotNull);
      expect(marketStream, isNotNull);
      expect(identical(fundStream, marketStream), isFalse);
    });

    test('应该正确调整任务频率', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      manager.addTask(task);
      manager.adjustTaskFrequency(task.id, const Duration(minutes: 10));

      expect(task.interval, const Duration(minutes: 10));
    });

    test('调整不存在任务的频率应该不报错', () {
      expect(() {
        manager.adjustTaskFrequency(
            'non-existent-task', const Duration(minutes: 10));
      }, returnsNormally);
    });

    test('应该正确启用和禁用任务', () {
      final task = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      );

      manager.addTask(task);

      // 禁用任务
      manager.setTaskEnabled(task.id, false);
      expect(task.enabled, isFalse);

      // 启用任务
      manager.setTaskEnabled(task.id, true);
      expect(task.enabled, isTrue);
    });

    test('启用/禁用不存在任务应该不报错', () {
      expect(() {
        manager.setTaskEnabled('non-existent-task', false);
      }, returnsNormally);
    });

    test('应该提供完整的统计信息', () {
      final stats = manager.getStatistics();

      expect(stats.containsKey('state'), isTrue);
      expect(stats.containsKey('totalTasks'), isTrue);
      expect(stats.containsKey('enabledTasks'), isTrue);
      expect(stats.containsKey('tasks'), isTrue);
      expect(stats.containsKey('statistics'), isTrue);
      expect(stats.containsKey('activityTracker'), isTrue);
      expect(stats.containsKey('frequencyAdjuster'), isTrue);
    });

    test('应该提供指定数据类型的统计信息', () {
      manager.addTask(PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      ));

      final stats = manager.getStatisticsForType(DataType.fundNetValue);
      expect(stats, isNotNull);
      expect(stats!.totalExecutions, 0);
      expect(stats.successCount, 0);
      expect(stats.failureCount, 0);
    });

    test('应该正确返回不存在数据类型的统计信息', () {
      final stats =
          manager.getStatisticsForType(DataType.historicalPerformance);
      expect(stats, isNull);
    });

    test('应该正确释放所有资源', () {
      manager.addTask(PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(minutes: 5),
      ));

      manager.dispose();

      expect(manager.state, PollingManagerState.stopped);
    });
  });

  group('PollingManager - 集成测试', () {
    test('完整的轮询管理器工作流程', () async {
      final manager = PollingManager();

      // 添加自定义任务
      final customTask = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(seconds: 1), // 短间隔用于测试
        parameters: {'fundCode': '000001'},
      );

      manager.addTask(customTask);

      // 监听数据流
      final dataItems = <DataItem>[];
      final subscription =
          manager.getDataStream(DataType.fundNetValue)?.listen(dataItems.add);

      // 启动轮询
      await manager.start();
      expect(manager.state, PollingManagerState.running);

      // 等待一段时间让轮询执行
      await Future.delayed(const Duration(milliseconds: 1500));

      // 停止轮询
      await manager.stop();
      expect(manager.state, PollingManagerState.stopped);

      await subscription?.cancel();
      manager.dispose();

      // 验证统计信息
      final finalStats = manager.getStatistics();
      expect(finalStats['totalTasks'], greaterThan(0));
    });

    test('应该正确处理任务调度', () async {
      final manager = PollingManager();

      final fastTask = PollingTask(
        dataType: DataType.fundNetValue,
        interval: const Duration(milliseconds: 100),
      );

      final slowTask = PollingTask(
        dataType: DataType.marketIndex,
        interval: const Duration(milliseconds: 200),
      );

      manager.addTask(fastTask);
      manager.addTask(slowTask);

      await manager.start();

      // 等待任务执行
      await Future.delayed(const Duration(milliseconds: 300));

      await manager.stop();
      manager.dispose();

      // 验证任务被调度执行
      expect(fastTask.executionCount, greaterThan(0));
      expect(slowTask.executionCount, greaterThan(0));
    });
  });
}
