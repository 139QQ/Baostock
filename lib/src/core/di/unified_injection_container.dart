import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cache/hive_cache_manager.dart';
import '../presentation/bloc/cache_bloc.dart';
import '../../features/fund/presentation/fund_exploration/domain/repositories/cache_repository.dart';
import '../../features/fund/presentation/fund_exploration/domain/data/repositories/hive_cache_repository.dart';
import '../../features/fund/presentation/fund_exploration/domain/data/services/fund_service.dart';
import '../../features/fund/presentation/bloc/fund_ranking_bloc.dart';
import '../../features/fund/domain/usecases/get_fund_rankings.dart';
import '../../features/fund/domain/repositories/fund_repository.dart';
import '../../features/fund/data/repositories/fund_repository_impl.dart';
import '../../features/fund/data/datasources/fund_remote_data_source.dart';
import '../../features/fund/data/datasources/fund_local_data_source.dart';

/// 统一依赖注入容器
///
/// 提供应用中所有服务的统一注册和管理
/// 支持懒加载、单例模式和工厂模式
class UnifiedInjectionContainer {
  static final GetIt _sl = GetIt.instance;
  static GetIt get sl => _sl;

  /// 是否已初始化
  static bool _isInitialized = false;

  /// 初始化所有依赖
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. 基础设施层
      await _registerInfrastructure();

      // 2. 数据层
      await _registerDataLayer();

      // 3. 领域层
      await _registerDomainLayer();

      // 4. 表现层
      await _registerPresentationLayer();

      _isInitialized = true;
      print('✅ 统一依赖注入容器初始化成功');
    } catch (e) {
      print('❌ 统一依赖注入容器初始化失败: $e');
      rethrow;
    }
  }

  /// 注册基础设施层依赖
  static Future<void> _registerInfrastructure() async {
    // HTTP客户端
    _sl.registerLazySingleton<http.Client>(
      () => http.Client(),
      dispose: (client) => client.close(),
    );

    // Hive缓存管理器
    final cacheManager = HiveCacheManager.instance;
    await cacheManager.initialize();
    _sl.registerSingleton<HiveCacheManager>(cacheManager);

    print('📦 基础设施层依赖注册完成');
  }

  /// 注册数据层依赖
  static Future<void> _registerDataLayer() async {
    // 缓存仓库
    _sl.registerLazySingleton<CacheRepository>(
      () => HiveCacheRepository(
        cacheManager: _sl<HiveCacheManager>(),
      ),
    );

    // 本地数据源
    _sl.registerLazySingleton<FundLocalDataSource>(
      () => FundLocalDataSource(),
    );

    // 远程数据源
    _sl.registerLazySingleton<FundRemoteDataSource>(
      () => FundRemoteDataSource(
        httpClient: _sl<http.Client>(),
      ),
    );

    // 基金仓库实现
    _sl.registerLazySingleton<FundRepository>(
      () => FundRepositoryImpl(
        remoteDataSource: _sl<FundRemoteDataSource>(),
        localDataSource: _sl<FundLocalDataSource>(),
        cacheRepository: _sl<CacheRepository>(),
      ),
    );

    // 基金服务
    _sl.registerLazySingleton<FundService>(
      () => FundService(),
    );

    print('📊 数据层依赖注册完成');
  }

  /// 注册领域层依赖
  static Future<void> _registerDomainLayer() async {
    // 获取基金排行榜用例
    _sl.registerLazySingleton<GetFundRankings>(
      () => GetFundRankings(
        repository: _sl<FundRepository>(),
      ),
    );

    print('🏗️ 领域层依赖注册完成');
  }

  /// 注册表现层依赖
  static Future<void> _registerPresentationLayer() async {
    // 缓存管理BLoC
    _sl.registerFactory<CacheBloc>(
      () => CacheBloc(
        cacheManager: _sl<HiveCacheManager>(),
      ),
    );

    // 基金排行榜BLoC
    _sl.registerFactory<FundRankingBloc>(
      () => FundRankingBloc(
        getFundRankings: _sl<GetFundRankings>(),
        repository: _sl<FundRepository>(),
      ),
    );

    print('🎨 表现层依赖注册完成');
  }

  /// 注册自定义服务
  static void registerCustomService<T extends Object>(
    T service, {
    bool singleton = false,
    String? instanceName,
  }) {
    if (singleton) {
      _sl.registerSingleton<T>(service, instanceName: instanceName);
    } else {
      _sl.registerFactory<T>(() => service, instanceName: instanceName);
    }
  }

  /// 注册异步工厂
  static void registerAsyncFactory<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
  }) {
    _sl.registerAsyncLazySingleton<T>(factoryFunc, instanceName: instanceName);
  }

  /// 获取服务实例
  static T get<T extends Object>({
    String? instanceName,
  }) {
    if (!_isInitialized) {
      throw StateError('依赖注入容器未初始化，请先调用 init()');
    }
    return _sl<T>(instanceName: instanceName);
  }

  /// 检查服务是否已注册
  static bool isRegistered<T extends Object>({
    String? instanceName,
  }) {
    return _sl.isRegistered<T>(instanceName: instanceName);
  }

  /// 移除服务
  static Future<void> unregister<T extends Object>({
    String? instanceName,
  }) {
    return _sl.unregister<T>(instanceName: instanceName);
  }

  /// 重置容器
  static Future<void> reset() async {
    await _sl.reset();
    _isInitialized = false;
    print('🔄 依赖注入容器已重置');
  }

  /// 获取依赖注入统计信息
  static Map<String, dynamic> getStatistics() {
    final registeredServices = <String>[];

    // 获取所有已注册的服务类型
    final allServices = _sl.allReadySync();
    for (final service in allServices) {
      registeredServices.add(service.runtimeType.toString());
    }

    return {
      'isInitialized': _isInitialized,
      'registeredServicesCount': registeredServices.length,
      'registeredServices': registeredServices,
      'hasHttpClient': isRegistered<http.Client>(),
      'hasCacheManager': isRegistered<HiveCacheManager>(),
      'hasCacheBloc': isRegistered<CacheBloc>(),
      'hasFundRankingBloc': isRegistered<FundRankingBloc>(),
      'hasFundRepository': isRegistered<FundRepository>(),
    };
  }

  /// 验证依赖注入完整性
  static Map<String, dynamic> validateDependencies() {
    final validation = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // 检查核心依赖
    final coreDependencies = [
      () => isRegistered<http.Client>(),
      () => isRegistered<HiveCacheManager>(),
      () => isRegistered<CacheRepository>(),
      () => isRegistered<FundRepository>(),
      () => isRegistered<GetFundRankings>(),
      () => isRegistered<FundRankingBloc>(),
    ];

    for (int i = 0; i < coreDependencies.length; i++) {
      try {
        final isRegistered = coreDependencies[i]();
        if (!isRegistered) {
          final dependencyNames = [
            'HTTP客户端',
            'Hive缓存管理器',
            '缓存仓库',
            '基金仓库',
            '获取基金排行榜用例',
            '基金排行榜BLoC',
          ];

          validation['errors'].add('核心依赖缺失: ${dependencyNames[i]}');
          validation['isValid'] = false;
        }
      } catch (e) {
        validation['errors'].add('依赖验证失败: $e');
        validation['isValid'] = false;
      }
    }

    // 检查可选依赖
    if (!isRegistered<CacheBloc>()) {
      validation['warnings'].add('缓存管理BLoC未注册，缓存功能可能受限');
    }

    return validation;
  }

  /// 应用启动时初始化
  static Future<void> initializeForApp() async {
    try {
      await init();

      // 验证依赖注入完整性
      final validation = validateDependencies();
      if (!validation['isValid'] as bool) {
        print('⚠️ 依赖注入验证失败:');
        for (final error in validation['errors'] as List<String>) {
          print('  ❌ $error');
        }
      }

      // 显示警告信息
      if (validation['warnings'].isNotEmpty) {
        print('⚠️ 依赖注入警告:');
        for (final warning in validation['warnings'] as List<String>) {
          print('  ⚠️ $warning');
        }
      }

      // 显示统计信息
      final stats = getStatistics();
      print('📊 依赖注入统计: ${stats['registeredServicesCount']} 个服务已注册');

      print('🚀 应用依赖注入初始化完成');
    } catch (e) {
      print('❌ 应用依赖注入初始化失败: $e');
      rethrow;
    }
  }

  /// 应用退出时清理资源
  static Future<void> dispose() async {
    try {
      // 关闭HTTP客户端
      if (isRegistered<http.Client>()) {
        await _sl<http.Client>().close();
      }

      // 关闭缓存管理器
      if (isRegistered<HiveCacheManager>()) {
        await _sl<HiveCacheManager>().close();
      }

      // 重置容器
      await reset();

      print('🧹 统一依赖注入容器清理完成');
    } catch (e) {
      print('❌ 统一依赖注入容器清理失败: $e');
    }
  }

  /// 创建服务代理（用于测试）
  static T createProxy<T extends Object>(T Function() factory) {
    return _sl.registerSingleton<T>(factory());
  }

  /// 获取服务构建器（用于延迟创建）
  static T Function() getBuilder<T extends Object>() {
    return () => _sl<T>();
  }
}

/// 依赖注入容器扩展
extension UnifiedInjectionContainerExtension on UnifiedInjectionContainer {
  /// 快速获取缓存管理器
  HiveCacheManager get cacheManager => get<HiveCacheManager>();

  /// 快速获取缓存BLoC
  CacheBloc get cacheBloc => get<CacheBloc>();

  /// 快速获取基金排行榜BLoC
  FundRankingBloc get fundRankingBloc => get<FundRankingBloc>();

  /// 快速获取基金仓库
  FundRepository get fundRepository => get<FundRepository>();

  /// 快速获取HTTP客户端
  http.Client get httpClient => get<http.Client>();
}