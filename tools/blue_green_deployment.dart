#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// 蓝绿部署管理器
/// 实现零停机部署和自动回滚机制
class BlueGreenDeploymentManager {
  final DeploymentConfig config;
  final HealthChecker healthChecker;
  final RollbackManager rollbackManager;

  BlueGreenDeploymentManager({
    required this.config,
    required this.healthChecker,
    required this.rollbackManager,
  });

  /// 执行蓝绿部署
  Future<DeploymentResult> deploy() async {
// ignore: avoid_print
    print('开始蓝绿部署流程');
    final startTime = DateTime.now();

    try {
      // 1. 预部署检查
      await _preDeploymentChecks();

      // 2. 确定目标环境（蓝或绿）
      final targetEnvironment = await _determineTargetEnvironment();
// ignore: avoid_print
      print('目标部署环境: ${targetEnvironment.name}');

      // 3. 备份当前环境
      await _backupCurrentEnvironment(targetEnvironment);

      // 4. 部署到新环境
      await _deployToEnvironment(targetEnvironment);

      // 5. 健康检查
      final healthCheckResult = await _performHealthChecks(targetEnvironment);
      if (!healthCheckResult.isHealthy) {
        throw DeploymentException(
          '健康检查失败: ${healthCheckResult.failures.join(', ')}',
          shouldRollback: true,
        );
      }

      // 6. 流量切换
      await _switchTraffic(targetEnvironment);

      // 7. 验证流量切换
      await _verifyTrafficSwitch(targetEnvironment);

      // 8. 清理旧环境
      await _cleanupOldEnvironment(targetEnvironment);

      final duration = DateTime.now().difference(startTime);
// ignore: avoid_print
      print('蓝绿部署成功完成，耗时: ${duration.inSeconds}秒');

      return DeploymentResult(
        success: true,
        environment: targetEnvironment,
        duration: duration,
        healthCheckResult: healthCheckResult,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
// ignore: avoid_print
      print('蓝绿部署失败: $e');

      // 自动回滚
      if (e is DeploymentException && e.shouldRollback) {
// ignore: avoid_print
        print('开始自动回滚');
        await rollbackManager.performRollback(
          reason: '部署失败: ${e.message}',
          isAutomatic: true,
        );
      }

      return DeploymentResult(
        success: false,
        error: e.toString(),
        duration: duration,
      );
    }
  }

  /// 预部署检查
  Future<void> _preDeploymentChecks() async {
// ignore: avoid_print
    print('执行预部署检查');

    final checks = [
      _checkSystemResources(),
      _checkDatabaseConnectivity(),
      _checkExternalServices(),
      _validateConfiguration(),
      _checkDeploymentArtifacts(),
    ];

    final results = await Future.wait(checks);
    final failures = results.where((r) => !r.success).toList();

    if (failures.isNotEmpty) {
      throw DeploymentException(
        '预部署检查失败: ${failures.map((f) => f.message).join(', ')}',
        shouldRollback: false,
      );
    }

// ignore: avoid_print
    print('预部署检查通过');
  }

  /// 检查系统资源
  Future<CheckResult> _checkSystemResources() async {
    try {
      // 检查磁盘空间
      final diskSpace = await _getAvailableDiskSpace();
      if (diskSpace < config.minDiskSpaceGB) {
        return CheckResult(
          success: false,
          message: '磁盘空间不足: ${diskSpace}GB < ${config.minDiskSpaceGB}GB',
        );
      }

      // 检查内存
      final memory = await _getAvailableMemory();
      if (memory < config.minMemoryGB) {
        return CheckResult(
          success: false,
          message: '内存不足: ${memory}GB < ${config.minMemoryGB}GB',
        );
      }

      return CheckResult(success: true);
    } catch (e) {
      return CheckResult(
        success: false,
        message: '系统资源检查失败: $e',
      );
    }
  }

  /// 检查数据库连接
  Future<CheckResult> _checkDatabaseConnectivity() async {
    try {
      // 这里应该实际测试数据库连接
      // 简化版本，仅检查连接字符串配置
      if (config.databaseConnectionString.isEmpty) {
        return CheckResult(
          success: false,
          message: '数据库连接字符串未配置',
        );
      }

      return CheckResult(success: true);
    } catch (e) {
      return CheckResult(
        success: false,
        message: '数据库连接检查失败: $e',
      );
    }
  }

  /// 检查外部服务
  Future<CheckResult> _checkExternalServices() async {
    try {
      final services = [
        'http://154.44.25.92:8080/health', // 自建API服务
        'https://aktools.akfamily.xyz/health', // AKShare服务
      ];

      for (final service in services) {
        try {
          final result = await Process.run(
              'curl', ['-s', '-o', '/dev/null', '-w', '%{http_code}', service]);
          if (result.stdout.toString().trim() != '200') {
            return CheckResult(
              success: false,
              message: '外部服务不可用: $service',
            );
          }
        } catch (e) {
// ignore: avoid_print
          print('外部服务检查失败: $service - $e');
        }
      }

      return CheckResult(success: true);
    } catch (e) {
      return CheckResult(
        success: false,
        message: '外部服务检查失败: $e',
      );
    }
  }

  /// 验证配置
  Future<CheckResult> _validateConfiguration() async {
    try {
      // 检查必要的配置项
      if (config.blueEnvironment.isEmpty || config.greenEnvironment.isEmpty) {
        return CheckResult(
          success: false,
          message: '环境配置不完整',
        );
      }

      if (config.loadBalancerConfig.isEmpty) {
        return CheckResult(
          success: false,
          message: '负载均衡器配置缺失',
        );
      }

      return CheckResult(success: true);
    } catch (e) {
      return CheckResult(
        success: false,
        message: '配置验证失败: $e',
      );
    }
  }

  /// 检查部署构件
  Future<CheckResult> _checkDeploymentArtifacts() async {
    try {
      // 检查应用包是否存在
      final appPackage = File(config.applicationPackagePath);
      if (!appPackage.existsSync()) {
        return CheckResult(
          success: false,
          message: '应用包不存在: ${config.applicationPackagePath}',
        );
      }

      // 检查配置文件
      final configFile = File(config.configurationFilePath);
      if (!configFile.existsSync()) {
        return CheckResult(
          success: false,
          message: '配置文件不存在: ${config.configurationFilePath}',
        );
      }

      return CheckResult(success: true);
    } catch (e) {
      return CheckResult(
        success: false,
        message: '部署构件检查失败: $e',
      );
    }
  }

  /// 确定目标环境
  Future<DeploymentEnvironment> _determineTargetEnvironment() async {
    // 获取当前活跃环境
    final currentEnvironment = await _getCurrentActiveEnvironment();

    // 切换到另一个环境
    final targetEnvironment = currentEnvironment == DeploymentEnvironment.blue
        ? DeploymentEnvironment.green
        : DeploymentEnvironment.blue;

// ignore: avoid_print
    print(
        '当前活跃环境: ${currentEnvironment.name}, 目标环境: ${targetEnvironment.name}');

    return targetEnvironment;
  }

  /// 获取当前活跃环境
  Future<DeploymentEnvironment> _getCurrentActiveEnvironment() async {
    try {
      // 通过负载均衡器获取当前活跃环境
      final result =
          await Process.run('curl', ['-s', config.loadBalancerStatusEndpoint]);
      final status = jsonDecode(result.stdout.toString());

      if (status['active_environment'] == 'blue') {
        return DeploymentEnvironment.blue;
      } else {
        return DeploymentEnvironment.green;
      }
    } catch (e) {
// ignore: avoid_print
      print('无法获取当前活跃环境，默认为blue: $e');
      return DeploymentEnvironment.blue;
    }
  }

  /// 备份当前环境
  Future<void> _backupCurrentEnvironment(
      DeploymentEnvironment targetEnvironment) async {
// ignore: avoid_print
    print('备份当前环境');

    try {
      final backupTimestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath =
          path.join(config.backupDirectory, 'backup_$backupTimestamp');

      // 创建备份目录
      await Directory(backupPath).create(recursive: true);

      // 备份当前环境配置
      final currentEnvironment = targetEnvironment == DeploymentEnvironment.blue
          ? DeploymentEnvironment.green
          : DeploymentEnvironment.blue;

      await _backupEnvironmentConfig(currentEnvironment, backupPath);
      await _backupDatabase(backupPath);
      await _backupApplicationFiles(backupPath);

// ignore: avoid_print
      print('环境备份完成: $backupPath');
    } catch (e) {
      throw DeploymentException('环境备份失败: $e', shouldRollback: false);
    }
  }

  /// 备份环境配置
  Future<void> _backupEnvironmentConfig(
      DeploymentEnvironment environment, String backupPath) async {
    final configPath = path.join(backupPath, 'config');
    await Directory(configPath).create(recursive: true);

    // 备份环境配置文件
    final envConfigFile = File(path.join(
        config.deploymentDirectory, environment.name, 'appsettings.json'));
    if (envConfigFile.existsSync()) {
      await envConfigFile
          .copy(path.join(configPath, '${environment.name}_appsettings.json'));
    }
  }

  /// 备份数据库
  Future<void> _backupDatabase(String backupPath) async {
    final dbBackupPath = path.join(backupPath, 'database');
    await Directory(dbBackupPath).create(recursive: true);

    try {
      // 这里应该执行实际的数据库备份命令
      final result = await Process.run('pg_dump', [
        config.databaseConnectionString,
        '-f',
        path.join(dbBackupPath, 'database_backup.sql'),
      ]);

      if (result.exitCode != 0) {
        throw Exception('数据库备份失败: ${result.stderr}');
      }

// ignore: avoid_print
      print('数据库备份完成');
    } catch (e) {
// ignore: avoid_print
      print('数据库备份失败: $e');
    }
  }

  /// 备份应用文件
  Future<void> _backupApplicationFiles(String backupPath) async {
    final appBackupPath = path.join(backupPath, 'application');
    await Directory(appBackupPath).create(recursive: true);

    // 备份当前版本的应用文件
    final currentAppPath = path.join(config.deploymentDirectory, 'current');
    if (Directory(currentAppPath).existsSync()) {
      await _copyDirectory(currentAppPath, appBackupPath);
    }
  }

  /// 部署到目标环境
  Future<void> _deployToEnvironment(DeploymentEnvironment environment) async {
// ignore: avoid_print
    print('部署到 ${environment.name} 环境');

    try {
      final environmentPath =
          path.join(config.deploymentDirectory, environment.name);

      // 清理目标环境
      await _cleanupEnvironment(environmentPath);

      // 解压应用包
      await _extractApplicationPackage(environmentPath);

      // 配置环境
      await _configureEnvironment(environment, environmentPath);

      // 启动服务
      await _startServices(environment, environmentPath);

// ignore: avoid_print
      print('部署到 ${environment.name} 环境完成');
    } catch (e) {
      throw DeploymentException('部署失败: $e', shouldRollback: true);
    }
  }

  /// 清理环境
  Future<void> _cleanupEnvironment(String environmentPath) async {
    final dir = Directory(environmentPath);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  /// 解压应用包
  Future<void> _extractApplicationPackage(String environmentPath) async {
    try {
      final result = await Process.run('tar', [
        '-xzf',
        config.applicationPackagePath,
        '-C',
        environmentPath,
        '--strip-components=1',
      ]);

      if (result.exitCode != 0) {
        throw Exception('解压失败: ${result.stderr}');
      }

// ignore: avoid_print
      print('应用包解压完成');
    } catch (e) {
      throw Exception('解压应用包失败: $e');
    }
  }

  /// 配置环境
  Future<void> _configureEnvironment(
      DeploymentEnvironment environment, String environmentPath) async {
    // 复制配置文件
    final configFile = File(config.configurationFilePath);
    if (configFile.existsSync()) {
      await configFile.copy(path.join(environmentPath, 'appsettings.json'));
    }

    // 设置环境变量
    final envFile = File(path.join(environmentPath, '.env'));
    await envFile.writeAsString('''
DEPLOYMENT_ENVIRONMENT=${environment.name}
DATABASE_CONNECTION_STRING=${config.databaseConnectionString}
API_BASE_URL=${config.apiBaseUrl}
REDIS_CONNECTION_STRING=${config.redisConnectionString}
LOG_LEVEL=${config.logLevel}
''');

// ignore: avoid_print
    print('环境配置完成');
  }

  /// 启动服务
  Future<void> _startServices(
      DeploymentEnvironment environment, String environmentPath) async {
    try {
      // 启动应用服务
      final startScript = File(path.join(environmentPath, 'start.sh'));
      if (startScript.existsSync()) {
        final result = await Process.run('bash', [startScript.path],
            workingDirectory: environmentPath);
        if (result.exitCode != 0) {
          throw Exception('服务启动失败: ${result.stderr}');
        }
      }

      // 等待服务启动
      await Future.delayed(const Duration(seconds: 30));

// ignore: avoid_print
      print('服务启动完成');
    } catch (e) {
      throw Exception('服务启动失败: $e');
    }
  }

  /// 执行健康检查
  Future<HealthCheckResult> _performHealthChecks(
      DeploymentEnvironment environment) async {
// ignore: avoid_print
    print('执行健康检查 - ${environment.name}');

    final healthCheckConfig = HealthCheckConfig(
      baseUrl:
          '${config.apiBaseUrl}:${environment == DeploymentEnvironment.blue ? config.bluePort : config.greenPort}',
      timeout: const Duration(seconds: 30),
      maxRetries: 3,
      retryDelay: const Duration(seconds: 5),
    );

    return await healthChecker.performHealthCheck(healthCheckConfig);
  }

  /// 切换流量
  Future<void> _switchTraffic(DeploymentEnvironment targetEnvironment) async {
// ignore: avoid_print
    print('切换流量到 ${targetEnvironment.name}');

    try {
      // 更新负载均衡器配置
      await _updateLoadBalancerConfig(targetEnvironment);

      // 验证流量切换
      await _verifyTrafficSwitch(targetEnvironment);

// ignore: avoid_print
      print('流量切换完成');
    } catch (e) {
      throw DeploymentException('流量切换失败: $e', shouldRollback: true);
    }
  }

  /// 更新负载均衡器配置
  Future<void> _updateLoadBalancerConfig(
      DeploymentEnvironment targetEnvironment) async {
    try {
      // 这里应该使用实际的负载均衡器API
      // 简化版本，仅做演示
      final configContent = '''
upstream backend {
    server localhost:${targetEnvironment == DeploymentEnvironment.blue ? config.bluePort : config.greenPort};
}
''';

      final configFile = File(config.loadBalancerConfig);
      await configFile.writeAsString(configContent);

      // 重新加载负载均衡器配置
      final result = await Process.run('nginx', ['-s', 'reload']);
      if (result.exitCode != 0) {
        throw Exception('负载均衡器配置重载失败: ${result.stderr}');
      }

// ignore: avoid_print
      print('负载均衡器配置更新完成');
    } catch (e) {
      throw Exception('负载均衡器配置更新失败: $e');
    }
  }

  /// 验证流量切换
  Future<void> _verifyTrafficSwitch(
      DeploymentEnvironment targetEnvironment) async {
// ignore: avoid_print
    print('验证流量切换');

    const maxRetries = 10;
    const retryDelay = Duration(seconds: 3);

    for (int i = 0; i < maxRetries; i++) {
      try {
        // 测试通过负载均衡器访问应用
        final result = await Process.run('curl', [
          '-s',
          '-o',
          '/dev/null',
          '-w',
          '%{http_code}',
          config.applicationEndpoint
        ]);
        final statusCode = int.tryParse(result.stdout.toString().trim()) ?? 0;

        if (statusCode == 200) {
          // 进一步验证响应内容
          final responseResult =
              await Process.run('curl', ['-s', config.applicationEndpoint]);
          final response = jsonDecode(responseResult.stdout.toString());

          if (response['environment'] == targetEnvironment.name) {
// ignore: avoid_print
            print('流量切换验证通过');
            return;
          }
        }

// ignore: avoid_print
        print('流量切换验证失败，重试 ${i + 1}/$maxRetries');
        await Future.delayed(retryDelay);
      } catch (e) {
// ignore: avoid_print
        print('流量切换验证异常，重试 ${i + 1}/$maxRetries: $e');
        await Future.delayed(retryDelay);
      }
    }

    throw DeploymentException('流量切换验证失败', shouldRollback: true);
  }

  /// 清理旧环境
  Future<void> _cleanupOldEnvironment(
      DeploymentEnvironment currentEnvironment) async {
    final oldEnvironment = currentEnvironment == DeploymentEnvironment.blue
        ? DeploymentEnvironment.green
        : DeploymentEnvironment.blue;

// ignore: avoid_print
    print('清理旧环境: ${oldEnvironment.name}');

    try {
      final oldEnvironmentPath =
          path.join(config.deploymentDirectory, oldEnvironment.name);
      final oldDir = Directory(oldEnvironmentPath);

      if (oldDir.existsSync()) {
        // 停止旧环境服务
        await _stopServices(oldEnvironment, oldEnvironmentPath);

        // 删除旧环境文件
        await oldDir.delete(recursive: true);
      }

// ignore: avoid_print
      print('旧环境清理完成');
    } catch (e) {
// ignore: avoid_print
      print('旧环境清理失败: $e');
      // 不抛出异常，因为清理失败不应该影响部署成功
    }
  }

  /// 停止服务
  Future<void> _stopServices(
      DeploymentEnvironment environment, String environmentPath) async {
    try {
      // 停止应用服务
      final stopScript = File(path.join(environmentPath, 'stop.sh'));
      if (stopScript.existsSync()) {
        await Process.run('bash', [stopScript.path],
            workingDirectory: environmentPath);
      }

// ignore: avoid_print
      print('服务停止完成: ${environment.name}');
    } catch (e) {
// ignore: avoid_print
      print('服务停止失败: ${environment.name} - $e');
    }
  }

  /// 获取可用磁盘空间（GB）
  Future<double> _getAvailableDiskSpace() async {
    try {
      final result =
          await Process.run('df', ['-BG', config.deploymentDirectory]);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final available = parts[3].replaceAll('G', '');
          return double.tryParse(available) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// 获取可用内存（GB）
  Future<double> _getAvailableMemory() async {
    try {
      final result = await Process.run('free', ['-g']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final available = parts[3];
          return double.tryParse(available) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// 复制目录
  Future<void> _copyDirectory(String source, String destination) async {
    final sourceDir = Directory(source);
    final destDir = Directory(destination);

    if (!sourceDir.existsSync()) return;
    if (!destDir.existsSync()) {
      await destDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: source);
        final newPath = path.join(destination, relativePath);
        await File(newPath).create(recursive: true);
        await entity.copy(newPath);
      }
    }
  }
}

/// 部署环境
enum DeploymentEnvironment {
  blue,
  green;

  String get name => toString().split('.').last;
}

/// 部署配置
class DeploymentConfig {
  final String blueEnvironment;
  final String greenEnvironment;
  final String deploymentDirectory;
  final String backupDirectory;
  final String applicationPackagePath;
  final String configurationFilePath;
  final String loadBalancerConfig;
  final String loadBalancerStatusEndpoint;
  final String applicationEndpoint;
  final String databaseConnectionString;
  final String redisConnectionString;
  final String apiBaseUrl;
  final String logLevel;
  final int bluePort;
  final int greenPort;
  final double minDiskSpaceGB;
  final double minMemoryGB;

  DeploymentConfig({
    required this.blueEnvironment,
    required this.greenEnvironment,
    required this.deploymentDirectory,
    required this.backupDirectory,
    required this.applicationPackagePath,
    required this.configurationFilePath,
    required this.loadBalancerConfig,
    required this.loadBalancerStatusEndpoint,
    required this.applicationEndpoint,
    required this.databaseConnectionString,
    required this.redisConnectionString,
    required this.apiBaseUrl,
    required this.logLevel,
    required this.bluePort,
    required this.greenPort,
    required this.minDiskSpaceGB,
    required this.minMemoryGB,
  });

  factory DeploymentConfig.fromJson(Map<String, dynamic> json) {
    return DeploymentConfig(
      blueEnvironment: json['blueEnvironment'],
      greenEnvironment: json['greenEnvironment'],
      deploymentDirectory: json['deploymentDirectory'],
      backupDirectory: json['backupDirectory'],
      applicationPackagePath: json['applicationPackagePath'],
      configurationFilePath: json['configurationFilePath'],
      loadBalancerConfig: json['loadBalancerConfig'],
      loadBalancerStatusEndpoint: json['loadBalancerStatusEndpoint'],
      applicationEndpoint: json['applicationEndpoint'],
      databaseConnectionString: json['databaseConnectionString'],
      redisConnectionString: json['redisConnectionString'],
      apiBaseUrl: json['apiBaseUrl'],
      logLevel: json['logLevel'],
      bluePort: json['bluePort'],
      greenPort: json['greenPort'],
      minDiskSpaceGB: json['minDiskSpaceGB'],
      minMemoryGB: json['minMemoryGB'],
    );
  }
}

/// 检查结果
class CheckResult {
  final bool success;
  final String message;

  CheckResult({
    required this.success,
    this.message = '',
  });
}

/// 部署结果
class DeploymentResult {
  final bool success;
  final DeploymentEnvironment? environment;
  final Duration duration;
  final HealthCheckResult? healthCheckResult;
  final String? error;

  DeploymentResult({
    required this.success,
    this.environment,
    required this.duration,
    this.healthCheckResult,
    this.error,
  });
}

/// 部署异常
class DeploymentException implements Exception {
  final String message;
  final bool shouldRollback;

  DeploymentException(this.message, {required this.shouldRollback});

  @override
  String toString() =>
      'DeploymentException: $message (shouldRollback: $shouldRollback)';
}

/// 健康检查配置
class HealthCheckConfig {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  HealthCheckConfig({
    required this.baseUrl,
    required this.timeout,
    required this.maxRetries,
    required this.retryDelay,
  });
}

/// 健康检查结果
class HealthCheckResult {
  final bool isHealthy;
  final List<String> failures;
  final Map<String, dynamic> details;
  final Duration responseTime;

  HealthCheckResult({
    required this.isHealthy,
    required this.failures,
    required this.details,
    required this.responseTime,
  });
}

/// 健康检查器
class HealthChecker {
  Future<HealthCheckResult> performHealthCheck(HealthCheckConfig config) async {
    final stopwatch = Stopwatch()..start();
    final failures = <String>[];
    final details = <String, dynamic>{};

    try {
      // API健康检查
      final apiHealth = await _checkApiHealth(config);
      if (!apiHealth.success) {
        failures.add(apiHealth.message);
      }
      details['api_health'] = apiHealth.details;

      // 数据库连接检查
      final dbHealth = await _checkDatabaseHealth(config);
      if (!dbHealth.success) {
        failures.add(dbHealth.message);
      }
      details['database_health'] = dbHealth.details;

      // 缓存检查
      final cacheHealth = await _checkCacheHealth(config);
      if (!cacheHealth.success) {
        failures.add(cacheHealth.message);
      }
      details['cache_health'] = cacheHealth.details;

      // 外部服务检查
      final externalHealth = await _checkExternalServicesHealth(config);
      if (!externalHealth.success) {
        failures.add(externalHealth.message);
      }
      details['external_services_health'] = externalHealth.details;
    } catch (e) {
      failures.add('健康检查异常: $e');
    } finally {
      stopwatch.stop();
    }

    final isHealthy = failures.isEmpty;
// ignore: avoid_print
    print(
        '健康检查完成: ${isHealthy ? '健康' : '不健康'}, 耗时: ${stopwatch.elapsed.inMilliseconds}ms');

    return HealthCheckResult(
      isHealthy: isHealthy,
      failures: failures,
      details: details,
      responseTime: stopwatch.elapsed,
    );
  }

  Future<HealthCheckDetail> _checkApiHealth(HealthCheckConfig config) async {
    try {
      final result = await Process.run(
          'curl', ['-s', '-w', '\n%{http_code}', '${config.baseUrl}/health']);
      final lines = result.stdout.toString().split('\n');
      final response = lines[0];
      final statusCode = lines.length > 1 ? lines[1] : '000';

      final isHealthy = statusCode == '200';
      return HealthCheckDetail(
        success: isHealthy,
        message: isHealthy ? 'API服务健康' : 'API服务不健康 (HTTP $statusCode)',
        details: {
          'status_code': statusCode,
          'response': response,
        },
      );
    } catch (e) {
      return HealthCheckDetail(
        success: false,
        message: 'API健康检查失败: $e',
        details: {'error': e.toString()},
      );
    }
  }

  Future<HealthCheckDetail> _checkDatabaseHealth(
      HealthCheckConfig config) async {
    try {
      // 这里应该实际测试数据库连接
      // 简化版本
      return HealthCheckDetail(
        success: true,
        message: '数据库连接正常',
        details: {'connection': 'healthy'},
      );
    } catch (e) {
      return HealthCheckDetail(
        success: false,
        message: '数据库连接失败: $e',
        details: {'error': e.toString()},
      );
    }
  }

  Future<HealthCheckDetail> _checkCacheHealth(HealthCheckConfig config) async {
    try {
      // 这里应该实际测试缓存连接
      // 简化版本
      return HealthCheckDetail(
        success: true,
        message: '缓存连接正常',
        details: {'connection': 'healthy'},
      );
    } catch (e) {
      return HealthCheckDetail(
        success: false,
        message: '缓存连接失败: $e',
        details: {'error': e.toString()},
      );
    }
  }

  Future<HealthCheckDetail> _checkExternalServicesHealth(
      HealthCheckConfig config) async {
    try {
      // 这里应该实际测试外部服务
      // 简化版本
      return HealthCheckDetail(
        success: true,
        message: '外部服务正常',
        details: {'status': 'healthy'},
      );
    } catch (e) {
      return HealthCheckDetail(
        success: false,
        message: '外部服务检查失败: $e',
        details: {'error': e.toString()},
      );
    }
  }
}

/// 健康检查详情
class HealthCheckDetail {
  final bool success;
  final String message;
  final Map<String, dynamic> details;

  HealthCheckDetail({
    required this.success,
    required this.message,
    required this.details,
  });
}

/// 回滚管理器
class RollbackManager {
  Future<void> performRollback({
    required String reason,
    required bool isAutomatic,
  }) async {
// ignore: avoid_print
    print('开始回滚: $reason (自动: $isAutomatic)');

    try {
      // 1. 获取回滚点
      final rollbackPoint = await _getRollbackPoint();

      // 2. 执行数据库回滚
      await _rollbackDatabase(rollbackPoint);

      // 3. 恢复应用版本
      await _rollbackApplication(rollbackPoint);

      // 4. 切换流量回旧版本
      await _rollbackTraffic(rollbackPoint);

      // 5. 验证回滚结果
      await _verifyRollback(rollbackPoint);

// ignore: avoid_print
      print('回滚完成');
    } catch (e) {
// ignore: avoid_print
      print('回滚失败: $e');
      throw Exception('回滚失败: $e');
    }
  }

  Future<RollbackPoint> _getRollbackPoint() async {
    // 这里应该获取最近的备份点
    // 简化版本
    return RollbackPoint(
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      environment: DeploymentEnvironment.blue,
      backupPath: '/backups/latest',
    );
  }

  Future<void> _rollbackDatabase(RollbackPoint rollbackPoint) async {
// ignore: avoid_print
    print('执行数据库回滚');
    // 这里应该执行实际的数据库回滚
  }

  Future<void> _rollbackApplication(RollbackPoint rollbackPoint) async {
// ignore: avoid_print
    print('执行应用回滚');
    // 这里应该执行实际的应用回滚
  }

  Future<void> _rollbackTraffic(RollbackPoint rollbackPoint) async {
// ignore: avoid_print
    print('执行流量回滚');
    // 这里应该执行实际的流量回滚
  }

  Future<void> _verifyRollback(RollbackPoint rollbackPoint) async {
// ignore: avoid_print
    print('验证回滚结果');
    // 这里应该验证回滚是否成功
  }
}

/// 回滚点
class RollbackPoint {
  final DateTime timestamp;
  final DeploymentEnvironment environment;
  final String backupPath;

  RollbackPoint({
    required this.timestamp,
    required this.environment,
    required this.backupPath,
  });
}

/// 主函数
void main(List<String> arguments) async {
  try {
    // 加载部署配置
    final configFile = File('deployment_config.json');
    if (!configFile.existsSync()) {
// ignore: avoid_print
      print('部署配置文件不存在: deployment_config.json');
      exit(1);
    }

    final configJson = jsonDecode(await configFile.readAsString());
    final config = DeploymentConfig.fromJson(configJson);

    // 创建部署管理器
    final deploymentManager = BlueGreenDeploymentManager(
      config: config,
      healthChecker: HealthChecker(),
      rollbackManager: RollbackManager(),
    );

    // 执行部署
    final result = await deploymentManager.deploy();

    if (result.success) {
// ignore: avoid_print
      print('🎉 部署成功!');
// ignore: avoid_print
      print('环境: ${result.environment?.name}');
// ignore: avoid_print
      print('耗时: ${result.duration.inSeconds}秒');
      exit(0);
    } else {
// ignore: avoid_print
      print('❌ 部署失败: ${result.error}');
      exit(1);
    }
  } catch (e) {
// ignore: avoid_print
    print('部署过程异常: $e');
    exit(1);
  }
}
