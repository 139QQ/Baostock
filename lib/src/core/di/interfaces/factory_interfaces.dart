import 'package:meta/meta.dart';
import 'service_interfaces.dart';

/// ==================== 服务工厂接口 ====================

/// 通用服务工厂接口
abstract class IServiceFactory {
  /// 创建服务实例
  T createService<T extends Object>([Map<String, dynamic>? parameters]);

  /// 异步创建服务实例
  Future<T> createServiceAsync<T extends Object>(
      [Map<String, dynamic>? parameters]);

  /// 检查是否可以创建指定类型的服务
  bool canCreate<T extends Object>();

  /// 获取支持的服务类型
  List<Type> get supportedServiceTypes;
}

/// 缓存服务工厂接口
abstract class ICacheServiceFactory extends IServiceFactory {
  /// 创建基础缓存服务
  ICacheService createCacheService({String? name});

  /// 创建带TTL的缓存服务
  ICacheService createTtlCacheService(Duration defaultTtl);

  /// 创建LRU缓存服务
  ICacheService createLruCacheService(int maxSize);

  /// 创建分布式缓存服务
  Future<ICacheService> createDistributedCacheService();
}

/// API服务工厂接口
abstract class IApiServiceFactory extends IServiceFactory {
  /// 创建基础API服务
  IApiService createApiService(String baseUrl);

  /// 创建带认证的API服务
  IApiService createAuthenticatedApiService(
    String baseUrl,
    String authToken,
  );

  /// 创建带重试机制的API服务
  IApiService createRetryableApiService(
    String baseUrl, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  });
}

/// 监控服务工厂接口
abstract class IMonitorServiceFactory extends IServiceFactory {
  /// 创建性能监控器
  IPerformanceMonitor createPerformanceMonitor();

  /// 创建内存监控器
  IMemoryMonitor createMemoryMonitor();

  /// 创建网络监控器
  INetworkMonitor createNetworkMonitor();
}

/// ==================== 适配器工厂接口 ====================

/// 适配器工厂接口
abstract class IAdapterFactory {
  /// 创建适配器
  T createAdapter<T extends Object>(Object target,
      [Map<String, dynamic>? config]);

  /// 检查是否可以创建指定类型的适配器
  bool canCreateAdapter<T extends Object>(Object target);

  /// 获取支持的适配器类型
  List<Type> get supportedAdapterTypes;
}

/// 缓存适配器工厂接口
abstract class ICacheAdapterFactory extends IAdapterFactory {
  /// 创建统一缓存适配器
  ICacheService createUnifiedCacheAdapter(Object targetCache);

  /// 创建缓存键适配器
  ICacheKeyManager createCacheKeyAdapter();
}

/// ==================== 组件工厂接口 ====================

/// 组件工厂接口
abstract class IComponentFactory {
  /// 创建组件
  T createComponent<T extends Object>([Map<String, dynamic>? parameters]);

  /// 创建带依赖的组件
  T createComponentWithDependencies<T extends Object>(
    Map<Type, Object> dependencies,
  );

  /// 检查是否可以创建指定类型的组件
  bool canCreate<T extends Object>();

  /// 获取支持的组件类型
  List<Type> get supportedComponentTypes;
}

/// UI组件工厂接口
abstract class IUIComponentFactory extends IComponentFactory {
  /// 创建基础UI组件
  T createUIComponent<T>([Map<String, dynamic>? properties]);

  /// 创建带状态的UI组件
  T createStatefulUIComponent<T>(
    dynamic initialState, [
    Map<String, dynamic>? properties,
  ]);
}

/// BLoC工厂接口
abstract class IBlocFactory {
  /// 创建BLoC实例
  T createBloc<T extends Object>([Map<String, dynamic>? parameters]);

  /// 创建Cubit实例
  T createCubit<T extends Object>([dynamic initialState]);

  /// 获取已创建的BLoC实例
  T? getBloc<T extends Object>();

  /// 释放BLoC实例
  void disposeBloc<T extends Object>();

  /// 释放所有BLoC实例
  Future<void> disposeAllBlocs();
}

/// ==================== 数据工厂接口 ====================

/// 仓库工厂接口
abstract class IRepositoryFactory {
  /// 创建仓库实例
  T createRepository<T extends Object>([Map<String, dynamic>? config]);

  /// 创建带数据源的仓库
  T createRepositoryWithDataSource<T extends Object>(
    Object dataSource, [
    Map<String, dynamic>? config,
  ]);
}

/// 数据源工厂接口
abstract class IDataSourceFactory {
  /// 创建远程数据源
  Object createRemoteDataSource(String baseUrl);

  /// 创建本地数据源
  Future<Object> createLocalDataSource(String databasePath);

  /// 创建混合数据源
  Object createHybridDataSource(
    Object remoteDataSource,
    Object localDataSource,
  );
}

/// ==================== 配置工厂接口 ====================

/// 配置工厂接口
abstract class IConfigurationFactory {
  /// 从环境变量创建配置
  Map<String, dynamic> createFromEnvironment();

  /// 从文件创建配置
  Future<Map<String, dynamic>> createFromFile(String filePath);

  /// 从URL创建配置
  Future<Map<String, dynamic>> createFromUrl(String url);

  /// 合并多个配置
  Map<String, dynamic> mergeConfigs(List<Map<String, dynamic>> configs);

  /// 验证配置
  bool validateConfiguration(Map<String, dynamic> config);
}

/// 服务配置工厂接口
abstract class IServiceConfigurationFactory {
  /// 创建默认服务配置
  Map<String, dynamic> createDefaultConfiguration();

  /// 创建开发环境配置
  Map<String, dynamic> createDevelopmentConfiguration();

  /// 创建测试环境配置
  Map<String, dynamic> createTestingConfiguration();

  /// 创建生产环境配置
  Map<String, dynamic> createProductionConfiguration();
}

/// ==================== 生命周期工厂接口 ====================

/// 生命周期管理器工厂接口
abstract class ILifecycleManagerFactory {
  /// 创建单例生命周期管理器
  Object createSingletonLifecycle<T extends Object>(
    T Function() factory,
  );

  /// 创建作用域生命周期管理器
  Object createScopedLifecycle<T extends Object>(
    T Function() factory,
  );

  /// 创建瞬态生命周期管理器
  Object createTransientLifecycle<T extends Object>(
    T Function() factory,
  );
}

/// ==================== 监控工厂接口 ====================

/// 监控工厂接口
abstract class IMonitoringFactory {
  /// 创建指标收集器
  Object createMetricsCollector();

  /// 创建日志记录器
  Object createLogger([String? name]);

  /// 创建追踪器
  Object createTracer([String? operationName]);

  /// 创建健康检查器
  IHealthCheckService createHealthChecker();
}

/// ==================== 网络工厂接口 ====================

/// 网络工厂接口
abstract class INetworkFactory {
  /// 创建HTTP客户端
  Object createHttpClient();

  /// 创建带拦截器的HTTP客户端
  Object createHttpClientWithInterceptors(List<Object> interceptors);

  /// 创建WebSocket客户端
  Object createWebSocketClient(String url);

  /// 创建网络监控器
  INetworkMonitor createNetworkMonitor();
}

/// ==================== 序列化工厂接口 ====================

/// 序列化工厂接口
abstract class ISerializationFactory {
  /// 创建JSON序列化器
  Object createJsonSerializer();

  /// 创建XML序列化器
  Object createXmlSerializer();

  /// 创建二进制序列化器
  Object createBinarySerializer();

  /// 创建自定义格式序列化器
  Object createCustomSerializer(String format);
}
