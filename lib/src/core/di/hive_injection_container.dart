import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../features/fund/presentation/fund_exploration/domain/data/repositories/hive_cache_repository.dart';
import '../../features/fund/presentation/fund_exploration/domain/repositories/cache_repository.dart';
import '../../features/fund/presentation/fund_exploration/domain/data/services/fund_service.dart';
import '../cache/hive_cache_manager.dart';

/// Hive缓存依赖注入配置
///
/// 负责初始化和管理所有Hive缓存相关的依赖关系
class HiveInjectionContainer {
  static final GetIt _sl = GetIt.instance;
  static GetIt get sl => _sl;

  /// 初始化Hive缓存依赖（带错误恢复）
  static Future<void> init() async {
    try {
      // 初始化Hive缓存管理器
      await HiveCacheManager.instance.initialize();
    } catch (e) {
      // 记录错误但不重新抛出，允许应用在无缓存模式下运行
      print('⚠️ Hive缓存依赖初始化失败，应用将在无缓存模式下运行: $e');
      // 不重新抛出异常
    }

    // 注册Hive缓存管理器
    _sl.registerLazySingleton<HiveCacheManager>(
      () => HiveCacheManager.instance,
    );

    // 注册缓存仓库
    _sl.registerLazySingleton<CacheRepository>(
      () => HiveCacheRepository(
        cacheManager: _sl<HiveCacheManager>(),
      ),
    );

    // 注册HTTP客户端（用于基金服务）
    _sl.registerLazySingleton<http.Client>(
      () => http.Client(),
    );

    // 注册基金服务（使用Hive缓存）
    _sl.registerLazySingleton<FundService>(
      () => FundService(),
    );
  }

  /// 清理所有缓存
  static Future<void> clearCache() async {
    if (_sl.isRegistered<CacheRepository>()) {
      await _sl<CacheRepository>().clearAllCache();
    }
  }

  /// 清理过期缓存
  static Future<void> clearExpiredCache() async {
    if (_sl.isRegistered<HiveCacheManager>()) {
      await _sl<HiveCacheManager>().clearExpiredCache();
    }
  }

  /// 获取缓存统计信息
  static Map<String, dynamic> getCacheStats() {
    if (_sl.isRegistered<HiveCacheManager>()) {
      return _sl<HiveCacheManager>().getStats();
    }
    return {};
  }

  /// 重置依赖注入容器
  static Future<void> reset() async {
    await _sl.reset();
  }

  /// 应用退出时清理资源
  static Future<void> dispose() async {
    // 关闭Hive缓存
    if (_sl.isRegistered<HiveCacheManager>()) {
      await _sl<HiveCacheManager>().close();
    }

    // 关闭HTTP客户端
    if (_sl.isRegistered<http.Client>()) {
      _sl<http.Client>().close();
    }

    // 重置依赖注入容器
    await reset();
  }
}
