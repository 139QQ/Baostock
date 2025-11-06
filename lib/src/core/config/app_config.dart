import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 应用环境配置管理器
///
/// 提供统一的环境配置管理，支持多环境切换
/// 支持的开发环境: development, staging, production
class AppConfig {
  static AppConfig? _instance;
  static bool _initialized = false;

  // 私有构造函数
  AppConfig._();

  /// 获取单例实例
  static AppConfig get instance {
    _instance ??= AppConfig._();
    return _instance!;
  }

  /// 初始化环境配置
  static Future<void> initialize({String? envFileName}) async {
    if (_initialized) return;

    try {
      // 确定环境文件名
      final fileName = envFileName ?? _determineEnvFile();

      // 加载环境配置文件
      await dotenv.load(fileName: fileName);

      // 设置环境变量
      await _setEnvironmentVariables();

      _initialized = true;

      print('✅ 环境配置初始化成功: $fileName');
    } catch (e) {
      print('❌ 环境配置初始化失败: $e');
      // 加载默认配置
      await _loadDefaultConfig();
      _initialized = true;
    }
  }

  /// 自动确定环境文件
  static String _determineEnvFile() {
    // 检查FLUTTER_ENV环境变量（Web兼容）
    String flutterEnv;
    if (kIsWeb) {
      // Web环境使用默认值或从常量获取
      flutterEnv = const String.fromEnvironment('FLUTTER_ENV',
          defaultValue: 'development');
    } else {
      // Native环境可以访问系统环境变量
      flutterEnv = Platform.environment['FLUTTER_ENV'] ?? 'development';
    }

    // 在release模式下默认使用生产环境配置
    const bool isReleaseMode = bool.fromEnvironment('dart.vm.product');
    if (isReleaseMode) {
      return '.env.production';
    }

    return '.env.$flutterEnv';
  }

  /// 设置环境变量
  static Future<void> _setEnvironmentVariables() async {
    // 确保必要的环境变量存在
    final requiredVars = ['API_BASE_URL', 'DB_HOST'];

    for (final varName in requiredVars) {
      if (!dotenv.env.containsKey(varName)) {
        throw Exception('缺少必需的环境变量: $varName');
      }
    }
  }

  /// 加载默认配置（当配置文件不存在时）
  static Future<void> _loadDefaultConfig() async {
    // 设置开发环境的默认值
    dotenv.env.addAll({
      'API_BASE_URL': 'http://154.44.25.92:8080',
      'API_CONNECT_TIMEOUT': '30',
      'API_RECEIVE_TIMEOUT': '120',
      'API_SEND_TIMEOUT': '30',
      'API_MAX_RETRIES': '5',
      'API_RETRY_DELAY': '2',
      'DB_HOST': '154.44.25.92',
      'DB_PORT': '1433',
      'DB_DATABASE': 'JiSuDB',
      'DB_USERNAME': 'SA',
      'DB_PASSWORD': 'Miami@2024',
      'APP_ENV': 'development',
      'APP_DEBUG': 'true',
      'CACHE_ENABLED': 'true',
      'PERFORMANCE_MONITORING_ENABLED': 'true',
    });
  }

  // ========== API配置 ==========

  /// API基础URL
  String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://154.44.25.92:8080';

  /// API连接超时时间（秒）
  int get apiConnectTimeout =>
      int.tryParse(dotenv.env['API_CONNECT_TIMEOUT'] ?? '30') ?? 30;

  /// API接收超时时间（秒）
  int get apiReceiveTimeout =>
      int.tryParse(dotenv.env['API_RECEIVE_TIMEOUT'] ?? '120') ?? 120;

  /// API发送超时时间（秒）
  int get apiSendTimeout =>
      int.tryParse(dotenv.env['API_SEND_TIMEOUT'] ?? '30') ?? 30;

  /// API最大重试次数
  int get apiMaxRetries =>
      int.tryParse(dotenv.env['API_MAX_RETRIES'] ?? '5') ?? 5;

  /// API重试延迟时间（秒）
  int get apiRetryDelay =>
      int.tryParse(dotenv.env['API_RETRY_DELAY'] ?? '2') ?? 2;

  // ========== 数据库配置 ==========

  /// 数据库主机地址
  String get dbHost => dotenv.env['DB_HOST'] ?? '154.44.25.92';

  /// 数据库端口
  int get dbPort => int.tryParse(dotenv.env['DB_PORT'] ?? '1433') ?? 1433;

  /// 数据库名称
  String get dbDatabase => dotenv.env['DB_DATABASE'] ?? 'JiSuDB';

  /// 数据库用户名
  String get dbUsername => dotenv.env['DB_USERNAME'] ?? 'SA';

  /// 数据库密码
  String get dbPassword => dotenv.env['DB_PASSWORD'] ?? 'Miami@2024';

  /// 数据库连接超时时间（秒）
  int get dbConnectionTimeout =>
      int.tryParse(dotenv.env['DB_CONNECTION_TIMEOUT'] ?? '30') ?? 30;

  /// 数据库命令超时时间（秒）
  int get dbCommandTimeout =>
      int.tryParse(dotenv.env['DB_COMMAND_TIMEOUT'] ?? '30') ?? 30;

  /// 是否启用多活动结果集
  bool get dbEnableMultipleActiveResultSets =>
      dotenv.env['DB_ENABLE_MULTIPLE_ACTIVE_RESULT_SETS']?.toLowerCase() ==
      'true';

  // ========== 应用配置 ==========

  /// 当前环境
  String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  /// 是否为开发模式
  bool get isDevelopment => appEnv == 'development';

  /// 是否为测试模式
  bool get isStaging => appEnv == 'staging';

  /// 是否为生产模式
  bool get isProduction => appEnv == 'production';

  /// 是否启用调试模式
  bool get appDebug => dotenv.env['APP_DEBUG']?.toLowerCase() == 'true';

  /// 日志级别
  String get appLogLevel => dotenv.env['APP_LOG_LEVEL'] ?? 'debug';

  // ========== 缓存配置 ==========

  /// 是否启用缓存
  bool get cacheEnabled => dotenv.env['CACHE_ENABLED']?.toLowerCase() == 'true';

  /// 缓存过期时间（秒）
  int get cacheTtl => int.tryParse(dotenv.env['CACHE_TTL'] ?? '3600') ?? 3600;

  /// 缓存最大大小
  int get cacheMaxSize =>
      int.tryParse(dotenv.env['CACHE_MAX_SIZE'] ?? '100') ?? 100;

  // ========== 性能配置 ==========

  /// 是否启用性能监控
  bool get performanceMonitoringEnabled =>
      dotenv.env['PERFORMANCE_MONITORING_ENABLED']?.toLowerCase() == 'true';

  /// 性能响应时间阈值（毫秒）
  int get performanceResponseTimeThreshold =>
      int.tryParse(
          dotenv.env['PERFORMANCE_RESPONSE_TIME_THRESHOLD'] ?? '300') ??
      300;

  // ========== 安全配置 ==========

  /// 是否启用加密
  bool get securityEncryptionEnabled =>
      dotenv.env['SECURITY_ENCRYPTION_ENABLED']?.toLowerCase() == 'true';

  /// 令牌过期时间（小时）
  int get securityTokenExpiry =>
      int.tryParse(dotenv.env['SECURITY_TOKEN_EXPIRY'] ?? '24') ?? 24;

  // ========== 监控配置 ==========

  /// 是否启用监控
  bool get monitoringEnabled =>
      dotenv.env['MONITORING_ENABLED']?.toLowerCase() == 'true';

  /// 是否启用错误报告
  bool get monitoringErrorReporting =>
      dotenv.env['MONITORING_ERROR_REPORTING']?.toLowerCase() == 'true';

  /// 是否启用分析
  bool get monitoringAnalyticsEnabled =>
      dotenv.env['MONITORING_ANALYTICS_ENABLED']?.toLowerCase() == 'true';

  // ========== 性能阈值配置 ==========

  /// 搜索响应时间最优阈值
  int get performanceSearchResponseTimeOptimal =>
      int.tryParse(
          dotenv.env['PERFORMANCE_SEARCH_RESPONSE_TIME_OPTIMAL'] ?? '200') ??
      200;

  /// 搜索响应时间良好阈值
  int get performanceSearchResponseTimeGood =>
      int.tryParse(
          dotenv.env['PERFORMANCE_SEARCH_RESPONSE_TIME_GOOD'] ?? '300') ??
      300;

  /// 搜索响应时间警告阈值
  int get performanceSearchResponseTimeWarning =>
      int.tryParse(
          dotenv.env['PERFORMANCE_SEARCH_RESPONSE_TIME_WARNING'] ?? '500') ??
      500;

  /// 搜索响应时间危险阈值
  int get performanceSearchResponseTimeCritical =>
      int.tryParse(
          dotenv.env['PERFORMANCE_SEARCH_RESPONSE_TIME_CRITICAL'] ?? '1000') ??
      1000;

  /// 缓存命中率最优阈值
  double get performanceCacheHitRateOptimal =>
      double.tryParse(
          dotenv.env['PERFORMANCE_CACHE_HIT_RATE_OPTIMAL'] ?? '0.85') ??
      0.85;

  /// 缓存命中率良好阈值
  double get performanceCacheHitRateGood =>
      double.tryParse(
          dotenv.env['PERFORMANCE_CACHE_HIT_RATE_GOOD'] ?? '0.70') ??
      0.70;

  /// 缓存命中率警告阈值
  double get performanceCacheHitRateWarning =>
      double.tryParse(
          dotenv.env['PERFORMANCE_CACHE_HIT_RATE_WARNING'] ?? '0.50') ??
      0.50;

  /// 缓存命中率危险阈值
  double get performanceCacheHitRateCritical =>
      double.tryParse(
          dotenv.env['PERFORMANCE_CACHE_HIT_RATE_CRITICAL'] ?? '0.30') ??
      0.30;

  /// 内存使用最优阈值
  int get performanceMemoryUsageOptimal =>
      int.tryParse(dotenv.env['PERFORMANCE_MEMORY_USAGE_OPTIMAL'] ?? '150') ??
      150;

  /// 内存使用良好阈值
  int get performanceMemoryUsageGood =>
      int.tryParse(dotenv.env['PERFORMANCE_MEMORY_USAGE_GOOD'] ?? '250') ?? 250;

  /// 内存使用警告阈值
  int get performanceMemoryUsageWarning =>
      int.tryParse(dotenv.env['PERFORMANCE_MEMORY_USAGE_WARNING'] ?? '400') ??
      400;

  /// 内存使用危险阈值
  int get performanceMemoryUsageCritical =>
      int.tryParse(dotenv.env['PERFORMANCE_MEMORY_USAGE_CRITICAL'] ?? '600') ??
      600;

  /// CPU使用率最优阈值
  double get performanceCpuUsageOptimal =>
      double.tryParse(dotenv.env['PERFORMANCE_CPU_USAGE_OPTIMAL'] ?? '30.0') ??
      30.0;

  /// CPU使用率良好阈值
  double get performanceCpuUsageGood =>
      double.tryParse(dotenv.env['PERFORMANCE_CPU_USAGE_GOOD'] ?? '50.0') ??
      50.0;

  /// CPU使用率警告阈值
  double get performanceCpuUsageWarning =>
      double.tryParse(dotenv.env['PERFORMANCE_CPU_USAGE_WARNING'] ?? '70.0') ??
      70.0;

  /// CPU使用率危险阈值
  double get performanceCpuUsageCritical =>
      double.tryParse(dotenv.env['PERFORMANCE_CPU_USAGE_CRITICAL'] ?? '90.0') ??
      90.0;

  /// API成功率最优阈值
  double get performanceApiSuccessRateOptimal =>
      double.tryParse(
          dotenv.env['PERFORMANCE_API_SUCCESS_RATE_OPTIMAL'] ?? '0.99') ??
      0.99;

  /// API成功率良好阈值
  double get performanceApiSuccessRateGood =>
      double.tryParse(
          dotenv.env['PERFORMANCE_API_SUCCESS_RATE_GOOD'] ?? '0.95') ??
      0.95;

  /// API成功率警告阈值
  double get performanceApiSuccessRateWarning =>
      double.tryParse(
          dotenv.env['PERFORMANCE_API_SUCCESS_RATE_WARNING'] ?? '0.90') ??
      0.90;

  /// API成功率危险阈值
  double get performanceApiSuccessRateCritical =>
      double.tryParse(
          dotenv.env['PERFORMANCE_API_SUCCESS_RATE_CRITICAL'] ?? '0.80') ??
      0.80;

  // ========== 工具方法 ==========

  /// 获取完整的数据库连接字符串
  String get dbConnectionString {
    return 'Server=$dbHost,$dbPort;'
        'Database=$dbDatabase;'
        'User Id=$dbUsername;'
        'Password=$dbPassword;'
        'Connection Timeout=$dbConnectionTimeout;'
        'Command Timeout=$dbCommandTimeout;'
        'MultipleActiveResultSets=$dbEnableMultipleActiveResultSets;';
  }

  /// 验证配置完整性
  bool validateConfig() {
    try {
      // 验证API配置
      if (apiBaseUrl.isEmpty) return false;

      // 验证数据库配置
      if (dbHost.isEmpty ||
          dbDatabase.isEmpty ||
          dbUsername.isEmpty ||
          dbPassword.isEmpty) {
        return false;
      }

      // 验证端口范围
      if (dbPort <= 0 || dbPort > 65535) return false;

      // 验证超时配置
      if (apiConnectTimeout <= 0 ||
          apiReceiveTimeout <= 0 ||
          apiSendTimeout <= 0) {
        return false;
      }

      return true;
    } catch (e) {
      print('配置验证失败: $e');
      return false;
    }
  }

  /// 打印当前配置摘要（开发模式下）
  void printConfigSummary() {
    if (!appDebug) return;

    print('🔧 应用配置摘要:');
    print('   环境: $appEnv');
    print('   API地址: $apiBaseUrl');
    print('   数据库: $dbHost:$dbPort/$dbDatabase');
    print('   缓存: ${cacheEnabled ? "启用" : "禁用"}');
    print('   性能监控: ${performanceMonitoringEnabled ? "启用" : "禁用"}');
    print('   加密: ${securityEncryptionEnabled ? "启用" : "禁用"}');
  }

  /// 重新加载配置
  static Future<void> reload({String? envFileName}) async {
    dotenv.env.clear();
    _initialized = false;
    await initialize(envFileName: envFileName);
  }
}
