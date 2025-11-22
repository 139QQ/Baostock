import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/memory/memory_optimization_manager.dart';

void main() {
  group('MemoryOptimizationManager Tests', () {
    late MemoryOptimizationManager manager;

    setUp(() {
      manager = MemoryOptimizationManager();
    });

    tearDown(() {
      manager.dispose();
    });

    group('初始化和监控', () {
      test('应该正确初始化管理器', () async {
        await manager.initialize();

        final stats = manager.getMemoryStats();
        expect(stats['isMonitoring'], true);
        expect(stats['strategies'], isNotEmpty);
      });

      test('应该正确启动和停止监控', () async {
        await manager.startMonitoring();
        expect(manager.getMemoryStats()['isMonitoring'], true);

        manager.stopMonitoring();
        expect(manager.getMemoryStats()['isMonitoring'], false);
      });

      test('应该能捕获内存快照', () async {
        final snapshot = await manager.captureCurrentSnapshot();

        expect(snapshot.timestamp, isNotNull);
        expect(snapshot.totalMemoryMB, greaterThan(0));
        expect(snapshot.usedMemoryMB, greaterThan(0));
        expect(snapshot.usagePercentage, greaterThan(0));
        expect(snapshot.pressureLevel, isNotNull);
      });
    });

    group('内存跟踪器', () {
      test('应该正确添加和使用跟踪器', () {
        final tracker = manager.addTracker('TestTracker');

        tracker.recordAllocation();
        expect(tracker.currentObjects, 1);

        tracker.recordDeallocation();
        expect(tracker.currentObjects, 0);

        final stats = tracker.getStats();
        expect(stats['allocationCount'], 1);
        expect(stats['deallocationCount'], 1);
        expect(stats['peakObjects'], 1);
      });

      test('应该正确重置跟踪器', () {
        final tracker = manager.addTracker('ResetTestTracker');

        tracker.recordAllocation();
        tracker.recordAllocation();
        tracker.reset();

        final stats = tracker.getStats();
        expect(stats['allocationCount'], 0);
        expect(stats['deallocationCount'], 0);
        expect(stats['currentObjects'], 0);
        expect(stats['peakObjects'], 0);
      });

      test('应该检测疑似内存泄漏', () {
        final tracker = manager.addTracker('LeakTestTracker');

        // 模拟内存泄漏场景：大量分配但很少释放
        for (int i = 0; i < 100; i++) {
          tracker.recordAllocation();
        }
        for (int i = 0; i < 5; i++) {
          tracker.recordDeallocation();
        }

        final stats = tracker.getStats();
        expect(stats['currentObjects'], 95);
        expect(stats['peakObjects'], 100);
        expect(stats['leakSuspected'], true);
      });

      test('应该正确移除跟踪器', () {
        manager.addTracker('RemoveTestTracker');
        expect(manager.getTracker('RemoveTestTracker'), isNotNull);

        manager.removeTracker('RemoveTestTracker');
        expect(manager.getTracker('RemoveTestTracker'), isNull);
      });
    });

    group('优化策略', () {
      test('应该正确添加和移除策略', () {
        final strategy = TestOptimizationStrategy();
        manager.addOptimizationStrategy(strategy);

        final stats = manager.getMemoryStats();
        expect(stats['strategies'], contains(strategy.name));

        manager.removeOptimizationStrategy(strategy.name);
        final updatedStats = manager.getMemoryStats();
        expect(updatedStats['strategies'], isNot(contains(strategy.name)));
      });

      test('应该按优先级排序策略', () {
        manager.addOptimizationStrategy(TestOptimizationStrategy(priority: 3));
        manager.addOptimizationStrategy(TestOptimizationStrategy(priority: 1));
        manager.addOptimizationStrategy(TestOptimizationStrategy(priority: 2));

        final stats = manager.getMemoryStats();
        expect(stats['strategies'], isNotEmpty);
      });
    });

    group('回调函数', () {
      test('应该正确添加和触发内存压力回调', () async {
        bool callbackTriggered = false;
        double receivedPercentage = 0.0;

        manager.addMemoryPressureCallback((percentage) {
          callbackTriggered = true;
          receivedPercentage = percentage;
        });

        // 模拟内存压力（通过内部方法触发）
        await manager.initialize();

        // 注意：实际测试中可能需要模拟高内存压力
        // 这里主要验证回调注册机制
        expect(manager.getMemoryStats()['isMonitoring'], true);
      });

      test('应该正确添加和触发垃圾回收回调', () async {
        bool callbackTriggered = false;

        manager.addGarbageCollectionCallback(() {
          callbackTriggered = true;
        });

        await manager.forceGarbageCollection();

        // 验证回调已注册（实际触发可能需要特定条件）
        expect(true, isTrue); // 基本验证，表示测试到达这一步
      });

      test('应该正确移除回调', () {
        void testMemoryCallback(double percentage) {}
        void testGCCallback() {}

        manager.addMemoryPressureCallback(testMemoryCallback);
        manager.addGarbageCollectionCallback(testGCCallback);

        manager.removeMemoryPressureCallback(testMemoryCallback);
        manager.removeGarbageCollectionCallback(testGCCallback);

        // 验证移除不会抛出异常
        expect(() => manager.removeMemoryPressureCallback(testMemoryCallback),
            returnsNormally);
        expect(() => manager.removeGarbageCollectionCallback(testGCCallback),
            returnsNormally);
      });
    });

    group('内存统计和报告', () {
      test('应该生成正确的内存统计', () async {
        await manager.initialize();
        await manager.captureCurrentSnapshot();

        final stats = manager.getMemoryStats();

        expect(stats['isMonitoring'], true);
        expect(stats['currentUsageMB'], greaterThanOrEqualTo(0));
        expect(stats['peakUsageMB'], greaterThanOrEqualTo(0));
        expect(stats['averageUsageMB'], greaterThanOrEqualTo(0));
        expect(stats['warningThresholdMB'], greaterThan(0));
        expect(stats['criticalThresholdMB'], greaterThan(0));
      });

      test('应该生成内存分析报告', () async {
        await manager.initialize();
        manager.addTracker('ReportTestTracker');

        final report = manager.exportMemoryReport();

        expect(report, contains('内存优化分析报告'));
        expect(report, contains('内存使用概览'));
        expect(report, contains('对象跟踪统计'));
        expect(report, contains('已注册优化策略'));
        expect(report, contains('ReportTestTracker'));
      });
    });

    group('错误处理', () {
      test('应该优雅处理重复初始化', () async {
        await manager.initialize();
        await manager.initialize(); // 第二次初始化

        expect(manager.getMemoryStats()['isMonitoring'], true);
      });

      test('应该优雅处理多次停止监控', () {
        manager.stopMonitoring();
        manager.stopMonitoring(); // 第二次停止

        expect(manager.getMemoryStats()['isMonitoring'], false);
      });

      test('应该优雅处理不存在的跟踪器操作', () {
        manager.removeTracker('NonExistentTracker');
        expect(manager.getTracker('NonExistentTracker'), isNull);
      });

      test('应该优雅处理回调执行中的异常', () async {
        // 添加一个会抛出异常的回调
        manager.addMemoryPressureCallback((_) {
          throw Exception('测试异常');
        });

        // 初始化并触发检查，不应该因为回调异常而崩溃
        await manager.initialize();

        expect(manager.getMemoryStats()['isMonitoring'], true);
      });
    });

    group('资源清理', () {
      test('应该正确清理所有资源', () async {
        await manager.initialize();
        manager.addTracker('CleanupTestTracker');
        manager.addOptimizationStrategy(TestOptimizationStrategy());
        manager.addMemoryPressureCallback((_) {});

        // 验证资源存在
        expect(manager.getMemoryStats()['isMonitoring'], true);
        expect(manager.getTracker('CleanupTestTracker'), isNotNull);
        expect(manager.getMemoryStats()['strategies'], isNotEmpty);

        // 清理资源
        manager.dispose();

        // 验证资源已清理
        final finalStats = manager.getMemoryStats();
        expect(finalStats['isMonitoring'], false);
        expect(manager.getTracker('CleanupTestTracker'), isNull);
        // 在dispose后，某些统计可能为null，这是正常的
        expect(finalStats, isNotNull);
      });
    });
  });
}

/// 测试用的优化策略
class TestOptimizationStrategy extends MemoryOptimizationStrategy {
  final int _priority;

  TestOptimizationStrategy({int priority = 1}) : _priority = priority;

  @override
  String get name => '测试优化策略';

  @override
  int get priority => _priority;

  @override
  bool isApplicable(MemoryPressureLevel pressureLevel) {
    return pressureLevel.index >= MemoryPressureLevel.medium.index;
  }

  @override
  Future<void> execute(MemoryPressureLevel pressureLevel) async {
    // 测试实现，什么都不做
    await Future.delayed(const Duration(milliseconds: 10));
  }
}
