/// 图表依赖注入容器
///
/// 负责注册和管理图表相关的依赖注入
library chart_di_container;

import 'package:get_it/get_it.dart';

import 'chart_config_manager.dart';

/// 图表依赖注入容器
class ChartDIContainer {
  static final GetIt _getIt = GetIt.instance;

  /// 初始化图表依赖注入
  static Future<void> initialize() async {
    await _registerServices();
  }

  /// 注册服务
  static Future<void> _registerServices() async {
    // 注册图表配置管理器
    if (!_getIt.isRegistered<IChartConfigManager>()) {
      _getIt.registerSingleton<IChartConfigManager>(
        ChartConfigManager(),
      );
    }
  }

  /// 获取服务实例
  static T get<T extends Object>() {
    return _getIt.get<T>();
  }

  /// 注册单例服务
  static void registerSingleton<T extends Object>(T instance) {
    _getIt.registerSingleton<T>(instance);
  }

  /// 注册工厂服务
  static void registerFactory<T extends Object>(T Function() factory) {
    _getIt.registerFactory<T>(factory);
  }

  /// 注册异步单例服务
  static Future<void> registerSingletonAsync<T extends Object>(
    Future<T> Function() factory,
  ) async {
    _getIt.registerSingletonAsync<T>(factory);
  }

  /// 重置容器
  static Future<void> reset() async {
    await _getIt.reset();
  }

  /// 检查服务是否已注册
  static bool isRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }
}
