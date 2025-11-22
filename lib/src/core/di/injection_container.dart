import 'package:get_it/get_it.dart';
import 'di_initializer.dart';

/// 全局服务定位器
///
/// 提供简单的服务访问接口，作为 DIInitializer 的便捷包装器
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  /// 获取服务实例
  T get<T extends Object>() {
    return DIInitializer.getService<T>();
  }

  /// 检查服务是否已注册
  bool isRegistered<T extends Object>() {
    return DIInitializer.isServiceRegistered<T>();
  }

  /// 检查服务名称是否已注册
  bool isServiceNameRegistered(String serviceName) {
    return DIInitializer.isServiceNameRegistered(serviceName);
  }
}

/// 全局服务定位器实例
///
/// 使用示例：
/// ```dart
/// final service = sl<MyService>();
/// ```
final ServiceLocator sl = ServiceLocator();
