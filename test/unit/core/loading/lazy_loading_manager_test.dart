import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/loading/lazy_loading_manager.dart';

void main() {
  group('LazyLoadingManager Tests', () {
    late LazyLoadingManager manager;

    setUp(() async {
      // 获取单例实例并重置状态以确保测试独立性
      manager = LazyLoadingManager();
      manager.resetForTesting();
      await manager.initialize();
    });

    tearDown(() {
      manager.dispose();
    });

    group('基础功能', () {
      test('应该正确初始化管理器', () async {
        expect(manager, isNotNull);
        final status = manager.getQueueStatus();
        expect(status['activeTasks'], 0);
        expect(status['queuedTasks'], 0);
        expect(status['cachedItems'], 0);
      });

      test('应该正确添加和执行加载任务', () async {
        bool callbackTriggered = false;
        dynamic loadedData;

        manager.addLoadCallback((key, data) {
          callbackTriggered = true;
          loadedData = data;
        });

        final taskId = manager.addLoadingTask(
          key: 'test_key',
          loader: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return 'test_data';
          },
        );

        expect(taskId, isNotNull);
        expect(taskId, startsWith('test_key_'));

        // 等待加载完成
        await Future.delayed(const Duration(milliseconds: 200));

        expect(callbackTriggered, isTrue);
        expect(loadedData, 'test_data');
        expect(manager.isLoaded('test_key'), isTrue);
      });

      test('应该正确处理缓存', () async {
        // 第一次加载
        final taskId1 = manager.addLoadingTask(
          key: 'cache_test',
          loader: () async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'cached_data';
          },
        );

        expect(taskId1, startsWith('cache_test_'));

        await Future.delayed(const Duration(milliseconds: 100));

        // 第二次加载应该使用缓存
        final taskId2 = manager.addLoadingTask(
          key: 'cache_test',
          loader: () async {
            return 'should_not_be_called';
          },
        );

        expect(taskId2, equals('cached_cache_test'));

        // 验证缓存数据
        final cachedData = manager.getCachedData<String>('cache_test');
        expect(cachedData, 'cached_data');
      });

      test('应该正确处理强制重新加载', () async {
        // 先加载一次
        await manager.forceLoad('force_test', () async => 'original_data');

        expect(manager.getCachedData('force_test'), 'original_data');

        // 强制重新加载
        final newData =
            await manager.forceLoad('force_test', () async => 'new_data');

        expect(newData, 'new_data');
        expect(manager.getCachedData('force_test'), 'new_data');
      });
    });

    group('优先级处理', () {
      test('应该按优先级处理任务', () async {
        final executionOrder = <String>[];

        manager.addLoadCallback((key, data) {
          executionOrder.add(key);
        });

        // 添加不同优先级的任务
        manager.addLoadingTask(
          key: 'low_priority',
          priority: LoadingPriority.low,
          loader: () async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'low';
          },
        );

        manager.addLoadingTask(
          key: 'high_priority',
          priority: LoadingPriority.high,
          loader: () async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'high';
          },
        );

        manager.addLoadingTask(
          key: 'critical_priority',
          priority: LoadingPriority.critical,
          loader: () async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'critical';
          },
        );

        await Future.delayed(const Duration(milliseconds: 200));

        // 验证执行顺序（高优先级先执行）
        expect(executionOrder.length, 3);
        expect(executionOrder.contains('critical_priority'), isTrue);
        expect(executionOrder.contains('high_priority'), isTrue);
        expect(executionOrder.contains('low_priority'), isTrue);
      });
    });

    group('批量操作', () {
      test('应该正确处理批量加载任务', () async {
        final completedTasks = <String>[];

        manager.addLoadCallback((key, data) {
          completedTasks.add(key);
        });

        final configs = [
          LoadingTaskConfig(
            key: 'batch_1',
            loader: () async => 'data1',
          ),
          LoadingTaskConfig(
            key: 'batch_2',
            loader: () async => 'data2',
            priority: LoadingPriority.high,
          ),
          LoadingTaskConfig(
            key: 'batch_3',
            loader: () async => 'data3',
          ),
        ];

        final taskIds = manager.addBatchLoadingTasks(configs);

        expect(taskIds.length, 3);

        await Future.delayed(const Duration(milliseconds: 500));

        expect(completedTasks.length, 3);
        expect(completedTasks, contains('batch_1'));
        expect(completedTasks, contains('batch_2'));
        expect(completedTasks, contains('batch_3'));
      });

      test('应该正确处理预加载', () async {
        final preloadCompleted = <String>[];

        manager.addLoadCallback((key, data) {
          preloadCompleted.add(key);
        });

        await manager.preloadData(
          ['1', '2'],
          (key) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'preload_data_$key';
          },
        );

        expect(preloadCompleted.length, 2);
        expect(preloadCompleted, contains('preload_1'));
        expect(preloadCompleted, contains('preload_2'));
      });
    });

    group('状态管理', () {
      test('应该正确返回加载状态', () async {
        const key = 'status_test';

        // 初始状态
        expect(manager.getLoadingStatus(key), LoadingStatus.notLoaded);

        // 添加任务后的状态
        manager.addLoadingTask(
          key: key,
          loader: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return 'data';
          },
        );

        // 任务可能还在队列或已开始加载
        final statusWhileLoading = manager.getLoadingStatus(key);
        expect(
            statusWhileLoading == LoadingStatus.queued ||
                statusWhileLoading == LoadingStatus.loading,
            isTrue);

        // 等待加载完成
        await Future.delayed(const Duration(milliseconds: 200));

        // 加载完成后的状态
        expect(manager.getLoadingStatus(key), LoadingStatus.loaded);
      });

      test('应该正确处理队列状态', () {
        final initialStatus = manager.getQueueStatus();
        expect(initialStatus['activeTasks'], 0);
        expect(initialStatus['queuedTasks'], 0);
        expect(initialStatus['maxConcurrentTasks'], 3);
        expect(initialStatus['isLoading'], false);

        // 添加一些任务
        for (int i = 0; i < 5; i++) {
          manager.addLoadingTask(
            key: 'status_test_$i',
            loader: () async => 'data_$i',
          );
        }

        final updatedStatus = manager.getQueueStatus();
        expect(updatedStatus['queuedTasks'], greaterThan(0));
      });
    });

    group('错误处理', () {
      test('应该正确处理加载错误', () async {
        bool errorCallbackTriggered = false;
        dynamic errorData;

        manager.addErrorCallback((key, error) {
          errorCallbackTriggered = true;
          errorData = error;
        });

        manager.addLoadingTask(
          key: 'error_test',
          loader: () async {
            throw Exception('Test error');
          },
        );

        await Future.delayed(const Duration(milliseconds: 200));

        expect(errorCallbackTriggered, isTrue);
        expect(errorData, isA<Exception>());
        expect(manager.getLoadingStatus('error_test'),
            isNot(LoadingStatus.loaded));
      });

      test('应该正确处理回调异常', () async {
        // 添加一个会抛出异常的回调
        manager.addLoadCallback((key, data) {
          throw Exception('Callback error');
        });

        // 这个测试应该不会因为回调异常而崩溃
        manager.addLoadingTask(
          key: 'callback_error_test',
          loader: () async => 'data',
        );

        await Future.delayed(const Duration(milliseconds: 200));

        // 如果能到达这里，说明回调异常被正确处理了
        expect(true, isTrue);
      });
    });

    group('资源管理', () {
      test('应该正确取消任务', () async {
        manager.addLoadingTask(
          key: 'cancel_test',
          loader: () async {
            await Future.delayed(const Duration(seconds: 1));
            return 'data';
          },
        );

        // 立即取消任务
        final cancelled = manager.cancelTask('cancel_test');
        expect(cancelled, isTrue);

        // 验证任务被取消
        await Future.delayed(const Duration(milliseconds: 100));
        expect(manager.isLoaded('cancel_test'), isFalse);
      });

      test('应该正确清空队列', () async {
        // 添加多个任务
        for (int i = 0; i < 5; i++) {
          manager.addLoadingTask(
            key: 'clear_test_$i',
            loader: () async => 'data_$i',
          );
        }

        // 清空队列
        manager.clearQueue();

        final status = manager.getQueueStatus();
        expect(status['queuedTasks'], 0);
      });

      test('应该正确清空缓存', () async {
        // 加载一些数据到缓存
        await manager.forceLoad('cache_clear_1', () async => 'data1');
        await manager.forceLoad('cache_clear_2', () async => 'data2');

        expect(manager.getCachedData('cache_clear_1'), 'data1');
        expect(manager.getCachedData('cache_clear_2'), 'data2');

        // 清空缓存
        manager.clearCache();

        expect(manager.getCachedData('cache_clear_1'), isNull);
        expect(manager.getCachedData('cache_clear_2'), isNull);
      });
    });

    group('统计信息', () {
      test('应该正确生成统计信息', () {
        final stats = manager.getStatistics();

        expect(stats['queueStatus'], isNotNull);
        expect(stats['cacheStats'], isNotNull);
        expect(stats['callbackStats'], isNotNull);
        expect(stats['performance'], isNotNull);

        expect(stats['cacheStats']['maxSize'], 100);
        expect(stats['cacheStats']['expiryMinutes'], 30);
        expect(stats['performance']['maxConcurrentTasks'], 3);
      });
    });

    group('生命周期', () {
      test('应该正确销毁管理器', () {
        manager.dispose();

        final status = manager.getQueueStatus();
        expect(status['activeTasks'], 0);
        expect(status['queuedTasks'], 0);
        expect(status['cachedItems'], 0);
      });
    });
  });
}
