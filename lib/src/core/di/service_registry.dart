import 'package:meta/meta.dart';
import 'di_container_manager.dart';
import '../utils/logger.dart';
import 'interfaces/service_interfaces.dart';

/// 服务注册表接口
abstract class IServiceRegistry {
  Future<void> registerServices(DIContainerManager container);
  Map<String, ServiceRegistration> getServices();
}

/// 基础服务注册表
class BaseServiceRegistry implements IServiceRegistry {
  final Map<String, ServiceRegistration> _services = {};

  @override
  Map<String, ServiceRegistration> getServices() => Map.unmodifiable(_services);

  /// 注册服务
  @protected
  void register(ServiceRegistration registration) {
    if (_services.containsKey(registration.name)) {
      AppLogger.warning(
          'Service ${registration.name} already registered, overriding...');
    }
    _services[registration.name] = registration;
  }

  /// 批量注册服务
  @protected
  void registerAll(Map<String, ServiceRegistration> services) {
    services.forEach((key, registration) {
      register(registration);
    });
  }

  @override
  Future<void> registerServices(DIContainerManager container) async {
    AppLogger.info(
        'Registering ${_services.length} services from $runtimeType');

    var successCount = 0;
    var failureCount = 0;

    for (final entry in _services.entries) {
      try {
        await container.registerService(entry.value);
        successCount++;
      } catch (e, stackTrace) {
        failureCount++;
        AppLogger.warning('Failed to register service ${entry.key}: $e');
        AppLogger.debug('Stack trace for ${entry.key}: $stackTrace');
        // 继续注册其他服务，不让单个服务的失败影响整个过程
      }
    }

    AppLogger.info(
        'Successfully registered $successCount services, $failureCount failed');
  }
}

/// 缓存服务注册表
class CacheServiceRegistry extends BaseServiceRegistry {
  CacheServiceRegistry() {
    _registerCacheServices();
  }

  void _registerCacheServices() {
    // 缓存服务使用占位符类型，将在实际集成时替换
    register(ServiceRegistration.lazySingleton(
      name: 'unified_hive_cache_manager',
      implementationType: dynamic,
      asyncInitialization: true,
    ));

    // 缓存服务接口
    register(ServiceRegistration.lazySingleton(
      name: 'unified_cache_service',
      implementationType: dynamic,
      interfaceType: ICacheService,
      asyncInitialization: true,
    ));

    // 缓存键管理器
    register(ServiceRegistration.singleton(
      name: 'cache_key_manager',
      implementationType: dynamic,
    ));

    // 缓存失效管理器
    register(ServiceRegistration.lazySingleton(
      name: 'cache_invalidation_manager',
      implementationType: dynamic,
      asyncInitialization: true,
    ));

    // 缓存性能监控器
    register(ServiceRegistration.lazySingleton(
      name: 'cache_performance_monitor',
      implementationType: dynamic,
      asyncInitialization: true,
    ));

    // 缓存预热管理器
    register(ServiceRegistration.lazySingleton(
      name: 'cache_preheating_manager',
      implementationType: dynamic,
      asyncInitialization: true,
    ));
  }
}

/// 网络服务注册表
class NetworkServiceRegistry extends BaseServiceRegistry {
  NetworkServiceRegistry() {
    _registerNetworkServices();
  }

  void _registerNetworkServices() {
    // API客户端
    register(ServiceRegistration.lazySingleton(
      name: 'fund_api_client',
      implementationType: dynamic,
    ));

    // API服务
    register(ServiceRegistration.lazySingleton(
      name: 'api_service',
      implementationType: dynamic,
      interfaceType: IApiService,
    ));

    // 导航管理器
    register(ServiceRegistration.lazySingleton(
      name: 'navigation_manager',
      implementationType: dynamic,
    ));
  }
}

/// 安全服务注册表
class SecurityServiceRegistry extends BaseServiceRegistry {
  SecurityServiceRegistry() {
    _registerSecurityServices();
  }

  void _registerSecurityServices() {
    // 安全监控器
    register(ServiceRegistration.lazySingleton(
      name: 'security_monitor',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 安全中间件
    register(ServiceRegistration.lazySingleton(
      name: 'security_middleware',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 安全工具类
    register(ServiceRegistration.lazySingleton(
      name: 'security_utils',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 安全存储服务
    register(ServiceRegistration.lazySingleton(
      name: 'secure_storage_service',
      implementationType: dynamic, // 替换为实际类型
    ));
  }
}

/// 性能服务注册表
class PerformanceServiceRegistry extends BaseServiceRegistry {
  PerformanceServiceRegistry() {
    _registerPerformanceServices();
  }

  void _registerPerformanceServices() {
    // 内存泄漏检测器
    register(ServiceRegistration.lazySingleton(
      name: 'memory_leak_detector',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // 设备性能检测器
    register(ServiceRegistration.lazySingleton(
      name: 'device_performance_detector',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 内存压力监控器
    register(ServiceRegistration.lazySingleton(
      name: 'memory_pressure_monitor',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // 高级内存管理器
    register(ServiceRegistration.lazySingleton(
      name: 'advanced_memory_manager',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // 动态缓存调整器
    register(ServiceRegistration.lazySingleton(
      name: 'dynamic_cache_adjuster',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // 内存清理管理器
    register(ServiceRegistration.lazySingleton(
      name: 'memory_cleanup_manager',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // 低开销性能监控器
    register(ServiceRegistration.lazySingleton(
      name: 'low_overhead_monitor',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));
  }
}

/// 数据服务注册表
class DataServiceRegistry extends BaseServiceRegistry {
  DataServiceRegistry() {
    _registerDataServices();
  }

  void _registerDataServices() {
    // 基金远程数据源
    register(ServiceRegistration.lazySingleton(
      name: 'fund_remote_data_source',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 基金本地数据源
    register(ServiceRegistration.lazySingleton(
      name: 'fund_local_data_source',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // 基金仓库
    register(ServiceRegistration.lazySingleton(
      name: 'fund_repository',
      implementationType: dynamic, // 替换为实际类型
      interfaceType: dynamic, // 替换为接口类型
    ));

    // 投资组合仓库
    register(ServiceRegistration.lazySingleton(
      name: 'portfolio_profit_repository',
      implementationType: dynamic, // 替换为实际类型
      interfaceType: dynamic, // 替换为接口类型
    ));

    // 基金数据服务
    register(ServiceRegistration.lazySingleton(
      name: 'fund_data_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 数据验证服务
    register(ServiceRegistration.lazySingleton(
      name: 'data_validation_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 搜索服务
    register(ServiceRegistration.lazySingleton(
      name: 'search_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 统一搜索服务
    register(ServiceRegistration.lazySingleton(
      name: 'unified_search_service',
      implementationType: dynamic, // 替换为实际类型
      interfaceType: dynamic, // 替换为接口类型
      asyncInitialization: true,
    ));

    // 货币基金服务
    register(ServiceRegistration.lazySingleton(
      name: 'money_fund_service',
      implementationType: dynamic, // 替换为实际类型
    ));
  }
}

/// 业务服务注册表
class BusinessServiceRegistry extends BaseServiceRegistry {
  BusinessServiceRegistry() {
    _registerBusinessServices();
  }

  void _registerBusinessServices() {
    // 基金分析服务
    register(ServiceRegistration.lazySingleton(
      name: 'fund_analysis_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 投资组合分析服务
    register(ServiceRegistration.lazySingleton(
      name: 'portfolio_analysis_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 高性能基金服务
    register(ServiceRegistration.lazySingleton(
      name: 'high_performance_fund_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 智能推荐服务
    register(ServiceRegistration.lazySingleton(
      name: 'smart_recommendation_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 基金对比服务
    register(ServiceRegistration.lazySingleton(
      name: 'fund_comparison_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 基金收藏服务
    register(ServiceRegistration.lazySingleton(
      name: 'fund_favorite_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 推送分析服务
    register(ServiceRegistration.lazySingleton(
      name: 'push_analytics_service',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // Android权限服务
    register(ServiceRegistration.lazySingleton(
      name: 'android_permission_service',
      implementationType: dynamic, // 替换为实际类型
    ));
  }
}

/// 状态管理服务注册表
class StateServiceRegistry extends BaseServiceRegistry {
  StateServiceRegistry() {
    _registerStateServices();
  }

  void _registerStateServices() {
    // 特性开关服务
    register(ServiceRegistration.singleton(
      name: 'feature_toggle_service',
      implementationType: dynamic, // 替换为实际类型
    ));

    // BLoC工厂初始化器
    register(ServiceRegistration.lazySingleton(
      name: 'bloc_factory_initializer',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 统一BLoC工厂
    register(ServiceRegistration.lazySingleton(
      name: 'unified_bloc_factory',
      implementationType: dynamic, // 替换为实际类型
    ));

    // 全局状态管理器
    register(ServiceRegistration.lazySingleton(
      name: 'global_state_manager',
      implementationType: dynamic, // 替换为实际类型
      asyncInitialization: true,
    ));

    // 基金探索Cubit
    register(ServiceRegistration.lazySingleton(
      name: 'fund_exploration_cubit',
      implementationType: dynamic, // FundExplorationCubit - 将在集成时替换
    ));
  }
}

/// 复合服务注册表
class CompositeServiceRegistry implements IServiceRegistry {
  final List<IServiceRegistry> _registries;

  CompositeServiceRegistry(this._registries);

  @override
  Map<String, ServiceRegistration> getServices() {
    final allServices = <String, ServiceRegistration>{};

    for (final registry in _registries) {
      allServices.addAll(registry.getServices());
    }

    return Map.unmodifiable(allServices);
  }

  @override
  Future<void> registerServices(DIContainerManager container) async {
    AppLogger.info(
        'Registering services from ${_registries.length} registries');

    for (final registry in _registries) {
      await registry.registerServices(container);
    }

    AppLogger.info('Successfully registered all services');
  }

  /// 添加注册表
  void addRegistry(IServiceRegistry registry) {
    _registries.add(registry);
  }

  /// 移除注册表
  void removeRegistry(IServiceRegistry registry) {
    _registries.remove(registry);
  }

  /// 清空所有注册表
  void clearRegistries() {
    _registries.clear();
  }
}

/// 默认服务注册表构建器
class DefaultServiceRegistryBuilder {
  static IServiceRegistry build() {
    return CompositeServiceRegistry([
      // 基础服务优先注册
      CacheServiceRegistry(),
      NetworkServiceRegistry(),
      SecurityServiceRegistry(),

      // 性能服务
      PerformanceServiceRegistry(),

      // 数据服务
      DataServiceRegistry(),

      // 业务服务
      BusinessServiceRegistry(),

      // 状态管理服务
      StateServiceRegistry(),
    ]);
  }

  /// 构建最小化服务注册表（用于测试）
  static IServiceRegistry buildMinimal() {
    return CompositeServiceRegistry([
      CacheServiceRegistry(),
      NetworkServiceRegistry(),
      DataServiceRegistry(),
    ]);
  }

  /// 构建完整服务注册表
  static IServiceRegistry buildFull() {
    return build(); // 目前和默认一样
  }
}
