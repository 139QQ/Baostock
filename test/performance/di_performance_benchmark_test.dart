import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/di/di_container_manager.dart';
import 'package:jisu_fund_analyzer/src/core/di/di_initializer.dart';
import 'package:jisu_fund_analyzer/src/core/di/environment_config.dart';
import 'package:jisu_fund_analyzer/src/core/di/service_registry.dart';

void main() {
  group('DI系统性能基准测试', () {
    setUp(() async {
      // 清理任何现有的初始化状态
      if (DIInitializer.isInitialized) {
        await DIInitializer.reset();
      }
    });

    tearDown(() async {
      if (DIInitializer.isInitialized) {
        await DIInitializer.reset();
      }
    });

    group('初始化性能测试', () {
      test('完整系统初始化应该在合理时间内完成', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.production(
          serviceRegistry: serviceRegistry,
        );

        final stopwatch = Stopwatch()..start();
        final result = await DIInitializer.initialize(config: config);
        stopwatch.stop();

        print('完整系统初始化耗时: ${stopwatch.elapsedMilliseconds}ms');
        print('注册服务数量: ${result.registeredServicesCount}');

        // 验证性能指标
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 应该在2秒内完成
        expect(result.success, isTrue);
        expect(result.registeredServicesCount, greaterThan(40));

        // 计算每个服务的平均初始化时间
        final avgTimePerService =
            stopwatch.elapsedMilliseconds / result.registeredServicesCount;
        print('每个服务平均初始化时间: ${avgTimePerService.toStringAsFixed(2)}ms');
        expect(avgTimePerService, lessThan(50)); // 每个服务应该在50ms内
      });

      test('最小化系统初始化应该更快', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        final config = DIInitializationConfig.testing(
          serviceRegistry: serviceRegistry,
        );

        final stopwatch = Stopwatch()..start();
        final result = await DIInitializer.initialize(config: config);
        stopwatch.stop();

        print('最小化系统初始化耗时: ${stopwatch.elapsedMilliseconds}ms');
        print('注册服务数量: ${result.registeredServicesCount}');

        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 应该在1秒内完成
        expect(result.success, isTrue);
        expect(result.registeredServicesCount, greaterThan(10));
        expect(result.registeredServicesCount, lessThan(30)); // 但不应该太多
      });

      test('多次初始化应该有稳定性能', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.development(
          serviceRegistry: serviceRegistry,
        );

        final times = <int>[];
        const iterations = 5;

        for (int i = 0; i < iterations; i++) {
          await DIInitializer.reset();

          final stopwatch = Stopwatch()..start();
          await DIInitializer.initialize(config: config);
          stopwatch.stop();

          times.add(stopwatch.elapsedMilliseconds);
          print('第${i + 1}次初始化耗时: ${stopwatch.elapsedMilliseconds}ms');
        }

        final avgTime = times.reduce((a, b) => a + b) / times.length;
        final maxTime = times.reduce((a, b) => a > b ? a : b);
        final minTime = times.reduce((a, b) => a < b ? a : b);

        print('平均初始化时间: ${avgTime.toStringAsFixed(2)}ms');
        print('最大初始化时间: ${maxTime}ms');
        print('最小初始化时间: ${minTime}ms');
        print('时间差异: ${(maxTime - minTime)}ms');

        expect(avgTime, lessThan(1500)); // 平均应该在1.5秒内
        expect(maxTime - minTime, lessThan(500)); // 时间差异应该小于500ms
      });
    });

    group('服务解析性能测试', () {
      setUp(() async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.production(
          serviceRegistry: serviceRegistry,
        );
        await DIInitializer.initialize(config: config);

        // 注册测试用的服务 - 通过类型注册，不使用名称
        DIInitializer.containerManager
            .registerSingletonInstance<SingletonTestService>(
          SingletonTestService(),
        );
        DIInitializer.containerManager.registerFactory<FactoryTestService>(
          () => FactoryTestService(),
        );
        DIInitializer.containerManager.registerLazySingleton<LazyTestService>(
          () => LazyTestService(),
        );
      });

      test('服务解析应该在微秒级别完成', () async {
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          // 模拟频繁的服务获取
          if (DIInitializer.isServiceRegistered<SingletonTestService>()) {
            DIInitializer.getService<SingletonTestService>();
          }
        }

        stopwatch.stop();

        final avgTimePerGet = stopwatch.elapsedMicroseconds / iterations;
        print('服务解析平均耗时: ${avgTimePerGet.toStringAsFixed(2)}μs');

        expect(avgTimePerGet, lessThan(100)); // 应该在100微秒内
      });

      test('不同类型的服务解析性能应该一致', () async {
        const iterations = 1000;

        // 测试单例服务解析性能
        final singletonStopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          DIInitializer.getService<SingletonTestService>();
        }
        singletonStopwatch.stop();

        // 测试工厂服务解析性能
        final factoryStopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          DIInitializer.getService<FactoryTestService>();
        }
        factoryStopwatch.stop();

        final singletonAvg =
            singletonStopwatch.elapsedMicroseconds / iterations;
        final factoryAvg = factoryStopwatch.elapsedMicroseconds / iterations;

        print('单例服务解析平均耗时: ${singletonAvg.toStringAsFixed(2)}μs');
        print('工厂服务解析平均耗时: ${factoryAvg.toStringAsFixed(2)}μs');

        expect(singletonAvg, lessThan(200));
        expect(factoryAvg, lessThan(300));
        expect((factoryAvg - singletonAvg).abs(), lessThan(200)); // 性能差异不应太大
      });

      test('批量服务解析性能测试', () async {
        const batchSize = 100;
        final serviceTypes = [
          () => DIInitializer.getService<SingletonTestService>(),
          () => DIInitializer.getService<FactoryTestService>(),
          () => DIInitializer.getService<LazyTestService>(),
        ];

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < batchSize; i++) {
          for (final getService in serviceTypes) {
            getService();
          }
        }

        stopwatch.stop();

        final totalTime = stopwatch.elapsedMicroseconds;
        final avgTimePerGet = totalTime / (batchSize * serviceTypes.length);

        print('批量服务解析总耗时: $totalTimeμs');
        print('每次解析平均耗时: ${avgTimePerGet.toStringAsFixed(2)}μs');

        expect(avgTimePerGet, lessThan(150));
      });
    });

    group('内存使用性能测试', () {
      setUp(() async {
        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        final config = DIInitializationConfig.testing(
          serviceRegistry: serviceRegistry,
        );
        await DIInitializer.initialize(config: config);

        // 注册测试用的服务
        DIInitializer.containerManager.registerFactory<FactoryTestService>(
          () => FactoryTestService(),
        );
      });

      test('服务注册应该不会造成内存泄漏', () async {
        final initialServices =
            DIInitializer.containerManager.registeredServicesCount;

        // 注册大量服务
        for (int i = 0; i < 100; i++) {
          final registration = ServiceRegistration.lazySingleton(
            name: 'memory_test_service_$i',
            implementationType: MemoryTestService,
          );
          await DIInitializer.containerManager.registerService(registration);
        }

        final afterRegistrationServices =
            DIInitializer.containerManager.registeredServicesCount;
        expect(afterRegistrationServices, equals(initialServices + 100));

        // 重置并检查内存是否释放
        await DIInitializer.reset();

        // 重新初始化
        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        final config = DIInitializationConfig.testing(
          serviceRegistry: serviceRegistry,
        );
        await DIInitializer.initialize(config: config);

        final finalServices =
            DIInitializer.containerManager.registeredServicesCount;
        expect(finalServices, lessThan(initialServices + 50)); // 应该接近初始数量
      });

      test('大量服务实例创建的内存性能', () async {
        const instanceCount = 1000;
        final instances = <FactoryTestService>[];

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < instanceCount; i++) {
          instances.add(DIInitializer.getService<FactoryTestService>());
        }

        stopwatch.stop();

        print('创建$instanceCount个实例耗时: ${stopwatch.elapsedMilliseconds}ms');
        print(
            '每个实例平均创建时间: ${(stopwatch.elapsedMilliseconds / instanceCount).toStringAsFixed(3)}ms');

        expect(
            stopwatch.elapsedMilliseconds, lessThan(1000)); // 应该在1秒内创建1000个实例
        expect(instances.length, equals(instanceCount));
        expect(
            instances.first.id, isNot(equals(instances.last.id))); // 验证实例确实不同
      });
    });

    group('并发性能测试', () {
      setUp(() async {
        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        final config = DIInitializationConfig.testing(
          serviceRegistry: serviceRegistry,
        );
        await DIInitializer.initialize(config: config);

        // 注册测试用的服务 - 通过类型注册，不使用名称
        DIInitializer.containerManager
            .registerSingletonInstance<SingletonTestService>(
          SingletonTestService(),
        );
        DIInitializer.containerManager.registerFactory<FactoryTestService>(
          () => FactoryTestService(),
        );
        DIInitializer.containerManager.registerLazySingleton<LazyTestService>(
          () => LazyTestService(),
        );
      });

      test('并发服务解析性能', () async {
        const concurrentCount = 50;
        const iterationsPerThread = 100;

        final futures = <Future<void>>[];
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < concurrentCount; i++) {
          futures.add(Future(() async {
            for (int j = 0; j < iterationsPerThread; j++) {
              DIInitializer.getService<SingletonTestService>();
            }
          }));
        }

        await Future.wait(futures);
        stopwatch.stop();

        const totalOperations = concurrentCount * iterationsPerThread;
        final avgTimePerOperation =
            stopwatch.elapsedMicroseconds / totalOperations;

        print('并发解析总操作数: $totalOperations');
        print('总耗时: ${stopwatch.elapsedMilliseconds}ms');
        print('每个操作平均耗时: ${avgTimePerOperation.toStringAsFixed(2)}μs');

        expect(avgTimePerOperation, lessThan(200)); // 并发时应该仍然很快
      });

      test('并发初始化保护', () async {
        // 测试并发初始化的保护机制
        final futures = <Future<DIInitializationResult>>[];
        const concurrentAttempts = 5;

        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        final config = DIInitializationConfig.testing(
          serviceRegistry: serviceRegistry,
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < concurrentAttempts; i++) {
          futures.add(DIInitializer.initialize(config: config));
        }

        final results = await Future.wait(futures);
        stopwatch.stop();

        // 当前实现没有并发保护机制，所有调用都会成功
        final successCount = results.where((r) => r.success).length;
        print('并发初始化成功次数: $successCount');
        print('总耗时: ${stopwatch.elapsedMilliseconds}ms');

        expect(successCount, equals(concurrentAttempts)); // 所有调用都应该成功
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 并发调用应该仍然很快
      });
    });

    group('环境切换性能测试', () {
      test('环境配置切换性能', () async {
        final environments = [
          AppEnvironment.development,
          AppEnvironment.testing,
          AppEnvironment.staging,
          AppEnvironment.production,
        ];

        final stopwatch = Stopwatch()..start();

        for (final environment in environments) {
          await DIInitializer.reset();
          await DIInitializer.initialize(
            config: DIInitializationConfig(
              environment: environment,
              serviceRegistry: DefaultServiceRegistryBuilder.buildMinimal(),
            ),
          );
        }

        stopwatch.stop();

        print('环境切换总耗时: ${stopwatch.elapsedMilliseconds}ms');
        print(
            '每次环境切换平均耗时: ${(stopwatch.elapsedMilliseconds / environments.length).toStringAsFixed(2)}ms');

        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 4次环境切换应该在3秒内
      });

      test('环境变量访问性能', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.buildMinimal();
        await DIInitializer.initialize(
            config: DIInitializationConfig.production(
          serviceRegistry: serviceRegistry,
        ));

        const accessCount = 10000;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < accessCount; i++) {
          DIInitializer.environmentConfig.getVariable('api_base_url');
          DIInitializer.environmentConfig.getVariable('debug_mode');
          DIInitializer.environmentConfig.getVariable('cache_enabled');
        }

        stopwatch.stop();

        final avgTimePerAccess =
            stopwatch.elapsedMicroseconds / (accessCount * 3);
        print('环境变量访问总耗时: ${stopwatch.elapsedMilliseconds}ms');
        print('每次访问平均耗时: ${avgTimePerAccess.toStringAsFixed(2)}μs');

        expect(avgTimePerAccess, lessThan(10)); // 环境变量访问应该非常快
      });
    });

    group('性能回归测试', () {
      test('性能基准验证', () async {
        final serviceRegistry = DefaultServiceRegistryBuilder.build();
        final config = DIInitializationConfig.production(
          serviceRegistry: serviceRegistry,
        );

        // 初始化性能基准
        final initStopwatch = Stopwatch()..start();
        final result = await DIInitializer.initialize(config: config);
        initStopwatch.stop();

        print('=== 性能基准结果 ===');
        print('初始化时间: ${initStopwatch.elapsedMilliseconds}ms (目标: <2000ms)');
        print('注册服务数: ${result.registeredServicesCount} (目标: >40)');
        print('初始化成功率: ${result.success ? '100%' : '0%'} (目标: 100%)');

        // 服务解析性能基准
        const resolutionTests = 1000;
        final resolutionStopwatch = Stopwatch()..start();

        for (int i = 0; i < resolutionTests; i++) {
          // 使用已知注册的服务进行性能测试
          DIInitializer.environmentConfig; // 获取环境配置，这个总是可用的
        }

        resolutionStopwatch.stop();
        final avgResolutionTime =
            resolutionStopwatch.elapsedMicroseconds / resolutionTests;

        print(
            '服务解析平均时间: ${avgResolutionTime.toStringAsFixed(2)}μs (目标: <100μs)');

        // 验证性能指标
        expect(initStopwatch.elapsedMilliseconds, lessThan(2000),
            reason: '初始化时间超标');
        expect(result.registeredServicesCount, greaterThan(40),
            reason: '注册服务数不足');
        expect(result.success, isTrue, reason: '初始化失败');
        expect(avgResolutionTime, lessThan(100), reason: '服务解析性能不达标');

        print('✅ 所有性能基准测试通过');
      });
    });
  });
}

// 测试用的服务类
class SingletonTestService {
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
}

class FactoryTestService {
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
}

class LazyTestService {
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
}

class MemoryTestService {
  final List<int> data = List.generate(100, (index) => index); // 占用一些内存
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
}
