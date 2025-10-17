/// SQL Server 数据库配置
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

  /// 默认配置（开发环境）
  factory SqlServerConfig.development() {
    return SqlServerConfig(
      host: '154.44.25.92',
      port: 1433,
      database: 'JiSuDB',
      username: 'SA',
      password: 'Miami@2024',
    );
  }

  /// 生产环境配置
  factory SqlServerConfig.production() {
    return SqlServerConfig(
      host: 'your-production-server.database.windows.net',
      database: 'FundAnalyzerDB',
      username: 'funduser',
      password: 'YourProduction@Password123',
      connectionTimeout: 60,
      commandTimeout: 60,
    );
  }

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
