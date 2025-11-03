import '../config/app_config.dart';

/// SQL Server 数据库配置 - 使用环境配置
class SqlServerConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final int connectionTimeout;
  final int commandTimeout;
  final bool enableMultipleActiveResultSets;

  SqlServerConfig({
    required this.host,
    this.port = 1433,
    required this.database,
    required this.username,
    required this.password,
    this.connectionTimeout = 30,
    this.commandTimeout = 30,
    this.enableMultipleActiveResultSets = true,
  });

  /// 从环境配置创建配置实例
  factory SqlServerConfig.fromEnvironment() {
    final config = AppConfig.instance;
    return SqlServerConfig(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbDatabase,
      username: config.dbUsername,
      password: config.dbPassword,
      connectionTimeout: config.dbConnectionTimeout,
      commandTimeout: config.dbCommandTimeout,
      enableMultipleActiveResultSets: config.dbEnableMultipleActiveResultSets,
    );
  }

  /// 默认配置（开发环境）- 保持向后兼容
  factory SqlServerConfig.development() => SqlServerConfig.fromEnvironment();

  /// 生产环境配置 - 保持向后兼容
  factory SqlServerConfig.production() => SqlServerConfig.fromEnvironment();

  /// 转换为连接字符串
  String toConnectionString() {
    return 'Server=$host,$port;'
        'Database=$database;'
        'User Id=$username;'
        'Password=$password;'
        'Connection Timeout=$connectionTimeout;'
        'Command Timeout=$commandTimeout;'
        'MultipleActiveResultSets=$enableMultipleActiveResultSets;';
  }

  /// 验证配置
  bool validate() {
    return host.isNotEmpty &&
        database.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        port > 0 &&
        port <= 65535;
  }
}
