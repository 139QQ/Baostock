import 'package:get_it/get_it.dart';
import '../database/sql_server_manager.dart';
import '../database/sql_server_config.dart';
import '../database/repositories/fund_database_repository.dart';
import '../../features/fund/presentation/fund_exploration/domain/repositories/cache_repository.dart';
import '../utils/logger.dart';

/// SQL Server 数据库依赖注入配置
class SqlServerInjectionContainer {
  static final GetIt _sl = GetIt.instance;
  static GetIt get sl => _sl;

  /// 初始化 SQL Server 数据库依赖
  static Future<void> init() async {
    // 注册 SQL Server 配置
    _sl.registerLazySingleton<SqlServerConfig>(
      () => SqlServerConfig.development(),
    );

    // 注册 SQL Server 管理器
    _sl.registerLazySingleton<SqlServerManager>(
      () => SqlServerManager.instance,
    );

    // 注册数据库仓库
    _sl.registerLazySingleton<CacheRepository>(
      () => FundDatabaseRepository(
        dbManager: _sl<SqlServerManager>(),
      ),
    );
  }

  /// 初始化数据库连接
  static Future<bool> initializeDatabase() async {
    try {
      final config = _sl<SqlServerConfig>();
      final manager = _sl<SqlServerManager>();

      // 初始化数据库连接
      final connected = await manager.initialize(config);

      if (connected) {
        // 初始化数据库表结构
        final repository = _sl<FundDatabaseRepository>();
        await repository.initializeDatabase();
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('数据库初始化失败', e);
      return false;
    }
  }

  /// 测试数据库连接
  static Future<bool> testConnection() async {
    try {
      final manager = _sl<SqlServerManager>();

      if (!manager.isConnected) {
        return false;
      }

      // 执行简单查询测试连接
      final result = await manager.query('SELECT 1 as test');
      return result.isNotEmpty && result.first['test'] == 1;
    } catch (e) {
      AppLogger.error('数据库连接测试失败', e);
      return false;
    }
  }

  /// 获取数据库统计信息
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final manager = _sl<SqlServerManager>();
      final repository = _sl<FundDatabaseRepository>();

      final connectionStats = manager.getConnectionStats();
      final cacheInfo = await repository.getCacheInfo();

      return {
        'connection': connectionStats,
        'cache': cacheInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 关闭数据库连接
  static Future<void> dispose() async {
    try {
      final manager = _sl<SqlServerManager>();
      await manager.disconnect();

      // 重置依赖注入容器
      await _sl.reset();
    } catch (e) {
      AppLogger.error('数据库连接关闭失败', e);
    }
  }
}
