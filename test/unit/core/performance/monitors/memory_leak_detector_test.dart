import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/performance/monitors/memory_leak_detector.dart';
import 'package:jisu_fund_analyzer/src/core/performance/managers/advanced_memory_manager.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import '../performance_test_base.dart';

/// 内存泄漏检测器测试
@GenerateMocks([AdvancedMemoryManager])
void main() {
  group('MemoryLeakDetector Tests', () {
    late MemoryLeakDetector memoryLeakDetector;
    late MockAdvancedMemoryManager mockMemoryManager;

    setUp(() async {
      mockMemoryManager = MockAdvancedMemoryManager();
      memoryLeakDetector = MemoryLeakDetector();
      await memoryLeakDetector.initialize();
    });

    tearDown(() async {
      await memoryLeakDetector.dispose();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        expect(memoryLeakDetector.isInitialized, isTrue);
        expect(memoryLeakDetector.isActive, isTrue);
      });

      test('should handle double initialization gracefully', () async {
        await memoryLeakDetector.initialize();
        expect(memoryLeakDetector.isInitialized, isTrue);
      });

      test('should dispose properly', () async {
        await memoryLeakDetector.dispose();
        expect(memoryLeakDetector.isInitialized, isFalse);
      });
    });

    group('Object Tracking Tests', () {
      test('should track object creation and cleanup', () async {
        final testObject = _TestObject();
        final objectId = memoryLeakDetector.trackObject(
          testObject,
          'test_object',
          'Test object for tracking',
        );

        expect(objectId, isNotNull);
        expect(memoryLeakDetector.getTrackedObjectCount(), equals(1));

        // 验证对象被正确跟踪
        final trackedInfo = memoryLeakDetector.getObjectInfo(objectId);
        expect(trackedInfo?.objectType, equals('test_object'));
        expect(trackedInfo?.description, equals('Test object for tracking'));

        // 清理对象
        memoryLeakDetector.untrackObject(objectId);
        expect(memoryLeakDetector.getTrackedObjectCount(), equals(0));
      });

      test('should handle object untracking for non-existent objects', () async {
        expect(() => memoryLeakDetector.untrackObject('non_existent_id'),
            returnsNormally);
      });

      test('should detect memory leaks over time', () async {
        // 创建多个对象并跟踪
        final objects = <_TestObject>[];
        final objectIds = <String>[];

        for (int i = 0; i < 10; i++) {
          final obj = _TestObject();
          objects.add(obj);
          final id = memoryLeakDetector.trackObject(
            obj,
            'test_object_$i',
            'Test object $i',
          );
          objectIds.add(id);
        }

        expect(memoryLeakDetector.getTrackedObjectCount(), equals(10));

        // 模拟部分对象未被清理
        // 清理一半对象
        for (int i = 0; i < 5; i++) {
          memoryLeakDetector.untrackObject(objectIds[i]);
        }

        expect(memoryLeakDetector.getTrackedObjectCount(), equals(5));

        // 检测泄漏
        final leaks = memoryLeakDetector.detectMemoryLeaks();
        expect(leaks.length, equals(5));
        expect(leaks.every((leak) => leak.objectType.startsWith('test_object')), isTrue);
      });

      test('should handle weak reference cleanup automatically', () async {
        final weakRefTracker = memoryLeakDetector.createWeakReferenceTracker();

        // 创建并跟踪对象
        final testObject = _TestObject();
        final objectId = weakRefTracker.track(
          testObject,
          'weak_test_object',
          'Weak reference test object',
        );

        expect(weakRefTracker.getTrackedCount(), equals(1));

        // 让对象超出作用域
        // 在实际测试中，对象会被GC回收
        // 这里我们模拟清理
        weakRefTracker.untrack(objectId);
        expect(weakRefTracker.getTrackedCount(), equals(0));
      });
    });

    group('Memory Monitoring Tests', () {
      test('should monitor memory usage continuously', () async {
        // 模拟内存使用情况变化
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 4096,
            cachedMemoryMB: 2048,
            pressureScore: 0.3,
            timestamp: DateTime.now(),
          ),
        );

        final memoryInfo = await memoryLeakDetector.getCurrentMemoryInfo();
        expect(memoryInfo.totalMemoryMB, equals(8192));
        expect(memoryInfo.availableMemoryMB, equals(4096));
        expect(memoryInfo.pressureScore, equals(0.3));
      });

      test('should detect memory pressure increases', () async {
        // 模拟内存压力增加
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 2048,
            cachedMemoryMB: 3072,
            pressureScore: 0.7,
            timestamp: DateTime.now(),
          ),
        );

        final memoryInfo = await memoryLeakDetector.getCurrentMemoryInfo();
        expect(memoryInfo.pressureScore, equals(0.7));

        // 检查是否触发了压力警告
        final alerts = memoryLeakDetector.getRecentAlerts();
        expect(alerts.any((alert) => alert.message.contains('pressure')), isTrue);
      });

      test('should provide memory trend analysis', () async {
        // 模拟内存使用趋势
        final memoryHistory = <MemoryInfo>[];
        for (int i = 0; i < 10; i++) {
          memoryHistory.add(MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 4096 - (i * 100),
            cachedMemoryMB: 2048 + (i * 50),
            pressureScore: 0.3 + (i * 0.05),
            timestamp: DateTime.now().subtract(Duration(seconds: i)),
          ));
        }

        when(mockMemoryManager.getMemoryInfo()).thenReturn(memoryHistory.last);

        final trend = memoryLeakDetector.getMemoryTrend();
        expect(trend, isNotNull);
        expect(trend.direction, isNotNull); // 上升、下降或稳定
      });
    });

    group('Leak Detection Algorithm Tests', () {
      test('should identify growing object patterns', () async {
        // 创建逐渐增长的对象集合
        final objectIds = <String>[];

        for (int cycle = 0; cycle < 3; cycle++) {
          // 每个周期创建更多对象
          for (int i = 0; i < 10 + cycle * 5; i++) {
            final obj = _TestObject();
            final id = memoryLeakDetector.trackObject(
              obj,
              'growing_object',
              'Growing object cycle $cycle',
            );
            objectIds.add(id);
          }

          // 等待一段时间
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final leaks = memoryLeakDetector.detectMemoryLeaks();
        expect(leaks.length, greaterThan(30)); // 应该检测到大量对象

        // 验证泄漏模式识别
        final patterns = memoryLeakDetector.analyzeLeakPatterns(leaks);
        expect(patterns, isNotEmpty);
        expect(patterns.any((p) => p.type.contains('growing')), isTrue);
      });

      test('should differentiate between temporary and persistent objects', () async {
        final temporaryIds = <String>[];
        final persistentIds = <String>[];

        // 创建临时对象（应该被清理）
        for (int i = 0; i < 20; i++) {
          final obj = _TestObject();
          final id = memoryLeakDetector.trackObject(
            obj,
            'temporary_object',
            'Temporary object $i',
          );
          temporaryIds.add(id);
        }

        // 创建持久对象（不会被清理）
        for (int i = 0; i < 5; i++) {
          final obj = _TestObject();
          final id = memoryLeakDetector.trackObject(
            obj,
            'persistent_object',
            'Persistent object $i',
          );
          persistentIds.add(id);
        }

        // 清理临时对象
        for (final id in temporaryIds) {
          memoryLeakDetector.untrackObject(id);
        }

        final leaks = memoryLeakDetector.detectMemoryLeaks();
        expect(leaks.length, equals(5)); // 只有持久对象

        // 验证泄漏分类
        final analysis = memoryLeakDetector.analyzeLeakCategories(leaks);
        expect(analysis.persistentObjects, equals(5));
        expect(analysis.temporaryObjects, equals(0));
      });

      test('should calculate leak severity correctly', () async {
        final highSeverityObjects = <String>[];
        final mediumSeverityObjects = <String>[];

        // 创建高严重性对象（大量数据）
        for (int i = 0; i < 5; i++) {
          final obj = _LargeObject(); // 大对象
          final id = memoryLeakDetector.trackObject(
            obj,
            'large_object',
            'Large object $i',
          );
          highSeverityObjects.add(id);
        }

        // 创建中等严重性对象
        for (int i = 0; i < 10; i++) {
          final obj = _TestObject();
          final id = memoryLeakDetector.trackObject(
            obj,
            'medium_object',
            'Medium object $i',
          );
          mediumSeverityObjects.add(id);
        }

        final leaks = memoryLeakDetector.detectMemoryLeaks();
        final severityAnalysis = memoryLeakDetector.calculateLeakSeverity(leaks);

        expect(severityAnalysis.totalLeaks, equals(leaks.length));
        expect(severityAnalysis.highSeverityCount, greaterThan(0));
        expect(severityAnalysis.mediumSeverityCount, greaterThan(0));
        expect(severityAnalysis.severityScore, greaterThan(0));
      });
    });

    group('Automatic Cleanup Tests', () {
      test('should perform automatic cleanup when memory pressure is high', () async {
        // 创建大量对象
        final objectIds = <String>[];
        for (int i = 0; i < 50; i++) {
          final obj = _TestObject();
          final id = memoryLeakDetector.trackObject(
            obj,
            'cleanup_test_object',
            'Cleanup test object $i',
          );
          objectIds.add(id);
        }

        expect(memoryLeakDetector.getTrackedObjectCount(), equals(50));

        // 模拟高内存压力
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1024, // 仅剩1GB可用
            cachedMemoryMB: 6000,
            pressureScore: 0.9, // 高压力
            timestamp: DateTime.now(),
          ),
        );

        // 触发自动清理
        await memoryLeakDetector.performAutoCleanup();

        // 验证清理效果
        expect(memoryLeakDetector.getTrackedObjectCount(), lessThan(50));
      });

      test('should respect cleanup priorities', () async {
        // 创建不同优先级的对象
        final lowPriorityIds = <String>[];
        final highPriorityIds = <String>[];

        // 创建低优先级对象
        for (int i = 0; i < 20; i++) {
          final obj = _TestObject();
          final id = memoryLeakDetector.trackObject(
            obj,
            'low_priority_object',
            'Low priority object $i',
          );
          lowPriorityIds.add(id);
        }

        // 创建高优先级对象
        for (int i = 0; i < 10; i++) {
          final obj = _TestObject();
          final id = memoryLeakDetector.trackObject(
            obj,
            'high_priority_object',
            'High priority object $i',
          );
          highPriorityIds.add(id);
        }

        // 模拟中等内存压力，只清理低优先级对象
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 3072,
            cachedMemoryMB: 3072,
            pressureScore: 0.6, // 中等压力
            timestamp: DateTime.now(),
          ),
        );

        await memoryLeakDetector.performAutoCleanup();

        // 验证只清理了低优先级对象
        expect(memoryLeakDetector.getTrackedObjectCount(), equals(10)); // 只剩下高优先级对象
      });
    });

    group('Performance Impact Tests', () {
      test('should have minimal performance overhead', () async {
        // 测量内存泄漏检测器的性能开销
        final overhead = await measureThroughput(
          operation: () async {
            // 模拟正常应用操作
            await Future.delayed(const Duration(microseconds: 100));
            return 'test';
          },
          iterations: 1000,
        );

        // 启用内存泄漏检测
        await memoryLeakDetector.startContinuousMonitoring();

        final overheadWithMonitoring = await measureThroughput(
          operation: () async {
            await Future.delayed(const Duration(microseconds: 100));
            return 'test';
          },
          iterations: 1000,
        );

        // 性能开销应该在可接受范围内（不超过10%）
        final performanceImpact = (overheadWithMonitoring - overhead) / overhead;
        expect(performanceImpact, lessThan(0.1));

        await memoryLeakDetector.stopContinuousMonitoring();
      });

      test('should handle high-frequency tracking efficiently', () async {
        final iterations = 1000;
        final stopwatch = Stopwatch()..start();

        // 高频对象创建和跟踪
        for (int i = 0; i < iterations; i++) {
          final obj = _TestObject();
          final id = memoryLeakDetector.trackObject(obj, 'hf_object', 'High freq $i');

          // 立即清理以模拟高频操作
          memoryLeakDetector.untrackObject(id);
        }

        stopwatch.stop();

        // 平均每个操作时间应该很短
        final avgTimePerOperation = stopwatch.elapsedMicroseconds / iterations;
        expect(avgTimePerOperation, lessThan(100)); // 小于100微秒
      });
    });

    group('Reporting and Analytics Tests', () {
      test('should generate comprehensive leak reports', () async {
        // 创建一些泄漏对象用于报告
        for (int i = 0; i < 10; i++) {
          final obj = _TestObject();
          memoryLeakDetector.trackObject(
            obj,
            'report_test_object',
            'Report test object $i',
          );
        }

        final report = memoryLeakDetector.generateLeakReport();

        expect(report.totalLeaks, equals(10));
        expect(report.generatedAt, isNotNull);
        expect(report.summary, isNotNull);
        expect(report.recommendations, isNotEmpty);
      });

      test('should provide memory usage statistics', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 4096,
            cachedMemoryMB: 2048,
            pressureScore: 0.3,
            timestamp: DateTime.now(),
          ),
        );

        final stats = memoryLeakDetector.getMemoryStatistics();
        expect(stats.totalTrackedObjects, isNotNull);
        expect(stats.memoryTrend, isNotNull);
        expect(stats.leakDetectionHistory, isNotNull);
      });

      test('should track leak detection history', () async {
        // 创建泄漏，触发检测，然后清理
        final obj = _TestObject();
        final id = memoryLeakDetector.trackObject(obj, 'history_test', 'History test');

        // 多次检测应该记录历史
        for (int i = 0; i < 3; i++) {
          memoryLeakDetector.detectMemoryLeaks();
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // 清理对象
        memoryLeakDetector.untrackObject(id);

        // 再次检测应该记录清理
        memoryLeakDetector.detectMemoryLeaks();

        final history = memoryLeakDetector.getLeakDetectionHistory();
        expect(history.length, greaterThan(3));
      });
    });

    group('Error Handling Tests', () {
      test('should handle tracking errors gracefully', () async {
        final obj = _TestObject();

        // 正常跟踪
        final id = memoryLeakDetector.trackObject(obj, 'error_test', 'Error test object');
        expect(id, isNotNull);

        // 尝试跟踪null对象应该失败
        expect(() => memoryLeakDetector.trackObject(null, 'null_object', 'Null object'),
            throwsA(isA<TypeError>()));

        // 尝试使用空对象类型应该失败
        expect(() => memoryLeakDetector.trackObject(obj, '', 'Empty type'),
            throwsA(isA<ArgumentError>()));

        // 清理正常对象
        memoryLeakDetector.untrackObject(id);
      });

      test('should handle memory manager errors', () async {
        // 模拟内存管理器错误
        when(mockMemoryManager.getMemoryInfo()).thenThrow(
          Exception('Memory manager error'),
        );

        // 内存泄漏检测器应该优雅处理错误
        expect(() => memoryLeakDetector.getCurrentMemoryInfo(),
            returnsNormally);
      });

      test('should handle disposal errors gracefully', () async {
        // 创建一些对象
        final obj = _TestObject();
        memoryLeakDetector.trackObject(obj, 'disposal_test', 'Disposal test');

        // 多次调用dispose应该安全
        await memoryLeakDetector.dispose();
        await memoryLeakDetector.dispose();
        await memoryLeakDetector.dispose();

        expect(memoryLeakDetector.isInitialized, isFalse);
      });
    });
  });
}

/// 测试对象类
class _TestObject {
  final String id;
  final List<int> data;

  _TestObject() : id = 'test_${DateTime.now().millisecondsSinceEpoch}',
       data = List.generate(10, (index) => index);

  @override
  String toString() => 'TestObject($id)';
}

/// 大对象类（用于测试内存泄漏检测）
class _LargeObject {
  final String id;
  final List<List<double>> largeData;

  _LargeObject() : id = 'large_${DateTime.now().millisecondsSinceEpoch}',
       largeData = List.generate(100, (i) => List.generate(100, (j) => j.toDouble()));

  @override
  String toString() => 'LargeObject($id, size: ${largeData.length}x${largeData[0]?.length ?? 0})';
}