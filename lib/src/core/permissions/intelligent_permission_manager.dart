import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'permission_history_manager.dart';
import 'simple_permission_requester.dart';
import 'models/permission_request_record.dart';
import 'models/permission_statistics.dart';

/// 智能权限请求管理器
///
/// 提供智能的权限请求策略，包括：
/// - 基于用户行为的权限请求时机分析
/// - 权限请求成功率统计和优化建议
/// - 权限请求策略的自适应调整
/// - 批量权限请求优化
class IntelligentPermissionManager {
  // 私有构造函数，确保单例模式
  IntelligentPermissionManager._();

  /// 单例实例
  static final IntelligentPermissionManager _instance =
      IntelligentPermissionManager._();

  /// 获取单例实例
  static IntelligentPermissionManager get instance => _instance;

  /// 权限请求配置
  static final Map<Permission, PermissionConfig> _permissionConfigs = {
    Permission.notification: PermissionConfig(
      maxRetryCount: 2,
      showRationaleOnFirstRequest: false,
      cooldownPeriod: Duration(hours: 24),
      priority: PermissionPriority.high,
    ),
    Permission.camera: PermissionConfig(
      maxRetryCount: 1,
      showRationaleOnFirstRequest: true,
      cooldownPeriod: Duration(days: 7),
      priority: PermissionPriority.medium,
    ),
    Permission.photos: PermissionConfig(
      maxRetryCount: 1,
      showRationaleOnFirstRequest: true,
      cooldownPeriod: Duration(days: 3),
      priority: PermissionPriority.medium,
    ),
    Permission.storage: PermissionConfig(
      maxRetryCount: 1,
      showRationaleOnFirstRequest: false,
      cooldownPeriod: Duration(days: 7),
      priority: PermissionPriority.low,
    ),
    Permission.microphone: PermissionConfig(
      maxRetryCount: 1,
      showRationaleOnFirstRequest: true,
      cooldownPeriod: Duration(days: 7),
      priority: PermissionPriority.low,
    ),
    Permission.location: PermissionConfig(
      maxRetryCount: 1,
      showRationaleOnFirstRequest: true,
      cooldownPeriod: Duration(days: 30),
      priority: PermissionPriority.high,
    ),
  };

  /// 智能请求权限
  Future<PermissionRequestResult> requestPermissionIntelligently({
    required Permission permission,
    required String featureModule,
    required String context,
    bool forceRequest = false,
    String? customRationaleMessage,
  }) async {
    try {
      AppLogger.info('🤖 开始智能权限请求: ${permission.toString()}');

      // 1. 检查权限是否已授予
      if (await permission.isGranted) {
        AppLogger.debug('✅ 权限已授予: ${permission.toString()}');
        return PermissionRequestResult(
          success: true,
          reason: '权限已授予',
          strategy: PermissionRequestStrategy.direct,
        );
      }

      // 2. 获取权限配置和历史
      final config = _permissionConfigs[permission] ?? _defaultConfig;
      final history = await PermissionHistoryManager.instance
          .getLastPermissionRequest(permission);

      // 3. 检查是否在冷却期内
      if (!forceRequest && _isInCooldownPeriod(history, config)) {
        AppLogger.debug('⏰ 权限在冷却期内，跳过请求: ${permission.toString()}');
        return PermissionRequestResult(
          success: false,
          reason: '权限在冷却期内',
          strategy: PermissionRequestStrategy.skipped,
        );
      }

      // 4. 检查是否超过最大重试次数
      if (!forceRequest && await _hasExceededMaxRetries(permission, config)) {
        AppLogger.debug('🚫 权限请求超过最大重试次数: ${permission.toString()}');
        return PermissionRequestResult(
          success: false,
          reason: '超过最大重试次数',
          strategy: PermissionRequestStrategy.skipped,
        );
      }

      // 5. 确定请求策略
      final strategy =
          _determineRequestStrategy(permission, history, config, forceRequest);

      // 6. 执行权限请求
      final result = await _executePermissionRequest(
        permission: permission,
        featureModule: featureModule,
        context: context,
        strategy: strategy,
        config: config,
        customRationaleMessage: customRationaleMessage,
      );

      AppLogger.info(
          '🎯 智能权限请求完成: ${permission.toString()}, 成功: ${result.success}');
      return result;
    } catch (e, stack) {
      AppLogger.error('❌ 智能权限请求失败: ${permission.toString()}', e, stack);
      return PermissionRequestResult(
        success: false,
        reason: '请求失败: $e',
        strategy: PermissionRequestStrategy.error,
      );
    }
  }

  /// 批量智能请求权限
  Future<Map<Permission, PermissionRequestResult>>
      requestMultiplePermissionsIntelligently({
    required List<Permission> permissions,
    required String featureModule,
    required String context,
    bool forceRequest = false,
  }) async {
    AppLogger.info('🤖 开始批量智能权限请求: ${permissions.length}个权限');

    final results = <Permission, PermissionRequestResult>{};

    // 按优先级排序权限
    final sortedPermissions = _sortPermissionsByPriority(permissions);

    for (final permission in sortedPermissions) {
      // 检查是否应该继续请求
      if (!forceRequest && _shouldStopBatchRequest(results)) {
        AppLogger.debug('🛑 批量权限请求中断，已获得足够权限');
        break;
      }

      final result = await requestPermissionIntelligently(
        permission: permission,
        featureModule: featureModule,
        context: context,
        forceRequest: forceRequest,
      );

      results[permission] = result;

      // 在权限请求之间添加小延迟
      if (permission != sortedPermissions.last) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    AppLogger.info(
        '📊 批量权限请求完成: 成功${results.values.where((r) => r.success).length}/${permissions.length}');
    return results;
  }

  /// 获取权限建议
  Future<List<PermissionRecommendation>> getPermissionRecommendations() async {
    try {
      AppLogger.debug('💡 生成权限建议');

      final recommendations = <PermissionRecommendation>[];
      final statistics =
          await PermissionHistoryManager.instance.getPermissionStatistics();

      if (statistics == null) {
        // 如果没有历史数据，返回基本建议
        return _getBasicRecommendations();
      }

      // 分析成功率低的权限
      for (final entry in statistics.permissionTypeStats.entries) {
        final stats = entry.value;
        if (stats.requestCount > 0 && stats.successRate < 0.5) {
          final permission = _parsePermissionFromString(entry.key);
          if (permission != null) {
            recommendations.add(PermissionRecommendation(
              permission: permission,
              recommendation: _generateRecommendationForLowSuccessRate(stats),
              priority: _getRecommendationPriority(stats.successRate),
            ));
          }
        }
      }

      // 分析频繁拒绝的权限
      for (final entry in statistics.permissionTypeStats.entries) {
        final stats = entry.value;
        if (stats.deniedCount > stats.grantedCount * 2) {
          final permission = _parsePermissionFromString(entry.key);
          if (permission != null &&
              !recommendations.any((r) => r.permission == permission)) {
            recommendations.add(PermissionRecommendation(
              permission: permission,
              recommendation: '该权限被频繁拒绝，建议改善权限说明文案或调整请求时机',
              priority: RecommendationPriority.high,
            ));
          }
        }
      }

      // 按优先级排序建议
      recommendations
          .sort((a, b) => a.priority.index.compareTo(b.priority.index));

      return recommendations;
    } catch (e, stack) {
      AppLogger.error('生成权限建议失败', e, stack);
      return _getBasicRecommendations();
    }
  }

  /// 获取权限请求统计摘要
  Future<String> getPermissionRequestSummary() async {
    try {
      final statistics =
          await PermissionHistoryManager.instance.getPermissionStatistics();
      if (statistics == null) {
        return '暂无权限请求统计数据';
      }

      final buffer = StringBuffer();
      buffer.writeln('📊 权限请求统计摘要');
      buffer.writeln('==================');
      buffer.writeln('总请求次数: ${statistics.totalRequests}');
      buffer.writeln('成功授权次数: ${statistics.grantedCount}');
      buffer.writeln(
          '成功率: ${(statistics.successRate * 100).toStringAsFixed(1)}%');
      buffer.writeln('平均耗时: ${statistics.avgDurationMs.toStringAsFixed(0)}ms');
      buffer.writeln('');

      buffer.writeln('🔥 最常请求的权限:');
      if (statistics.mostRequestedPermissionType != null) {
        buffer.writeln('  - ${statistics.mostRequestedPermissionType}');
      }

      buffer.writeln('✅ 成功率最高的权限:');
      if (statistics.highestSuccessRatePermissionType != null) {
        buffer.writeln('  - ${statistics.highestSuccessRatePermissionType}');
      }

      buffer.writeln('🎯 最活跃的功能模块:');
      if (statistics.mostActiveModule != null) {
        buffer.writeln('  - ${statistics.mostActiveModule}');
      }

      return buffer.toString();
    } catch (e, stack) {
      AppLogger.error('获取权限请求摘要失败', e, stack);
      return '获取统计信息失败';
    }
  }

  /// 检查权限是否在冷却期内
  bool _isInCooldownPeriod(
      PermissionRequestRecord? history, PermissionConfig config) {
    if (history == null) return false;

    final now = DateTime.now();
    final lastRequestTime = history.requestTime;
    final cooldownEnd = lastRequestTime.add(config.cooldownPeriod);

    return now.isBefore(cooldownEnd);
  }

  /// 检查是否超过最大重试次数
  Future<bool> _hasExceededMaxRetries(
      Permission permission, PermissionConfig config) async {
    final history =
        await PermissionHistoryManager.instance.getPermissionHistory(
      permission: permission,
      limit: config.maxRetryCount + 1,
    );

    // 只计算拒绝的请求次数
    final deniedCount =
        history.where((r) => r.isDenied || r.isPermanentlyDenied).length;
    return deniedCount >= config.maxRetryCount;
  }

  /// 确定请求策略
  PermissionRequestStrategy _determineRequestStrategy(
    Permission permission,
    PermissionRequestRecord? history,
    PermissionConfig config,
    bool forceRequest,
  ) {
    if (forceRequest) return PermissionRequestStrategy.force;

    if (history == null) {
      // 首次请求
      return config.showRationaleOnFirstRequest
          ? PermissionRequestStrategy.firstWithRationale
          : PermissionRequestStrategy.firstDirect;
    }

    if (history.isDenied) {
      // 之前被拒绝，显示说明
      return PermissionRequestStrategy.withRationale;
    }

    if (history.isPermanentlyDenied) {
      // 永久拒绝，引导到设置
      return PermissionRequestStrategy.showSettings;
    }

    return PermissionRequestStrategy.direct;
  }

  /// 执行权限请求
  Future<PermissionRequestResult> _executePermissionRequest({
    required Permission permission,
    required String featureModule,
    required String context,
    required PermissionRequestStrategy strategy,
    required PermissionConfig config,
    String? customRationaleMessage,
  }) async {
    switch (strategy) {
      case PermissionRequestStrategy.firstDirect:
      case PermissionRequestStrategy.direct:
        return await _requestDirect(permission, featureModule, context, false);

      case PermissionRequestStrategy.firstWithRationale:
      case PermissionRequestStrategy.withRationale:
        return await _requestWithRationale(
            permission, featureModule, context, customRationaleMessage);

      case PermissionRequestStrategy.showSettings:
        return await _requestViaSettings(permission, featureModule);

      case PermissionRequestStrategy.force:
        return await _requestDirect(permission, featureModule, context, true);

      case PermissionRequestStrategy.skipped:
        return PermissionRequestResult(
          success: false,
          reason: '请求被跳过',
          strategy: strategy,
        );

      case PermissionRequestStrategy.error:
        return PermissionRequestResult(
          success: false,
          reason: '请求出错',
          strategy: strategy,
        );
    }
  }

  /// 直接请求权限
  Future<PermissionRequestResult> _requestDirect(
    Permission permission,
    String featureModule,
    String context,
    bool force,
  ) async {
    final success = await SimplePermissionRequester.requestPermissionOnDemand(
      permission: permission,
      featureModule: featureModule,
      context: context,
      showRationale: false,
    );

    return PermissionRequestResult(
      success: success,
      reason: success ? '直接请求成功' : '直接请求失败',
      strategy: PermissionRequestStrategy.direct,
    );
  }

  /// 带说明的权限请求
  Future<PermissionRequestResult> _requestWithRationale(
    Permission permission,
    String featureModule,
    String context,
    String? customMessage,
  ) async {
    final success = await SimplePermissionRequester.requestPermissionOnDemand(
      permission: permission,
      featureModule: featureModule,
      context: context,
      showRationale: true,
      customRationaleMessage: customMessage,
    );

    return PermissionRequestResult(
      success: success,
      reason: success ? '带说明的请求成功' : '带说明的请求失败',
      strategy: PermissionRequestStrategy.withRationale,
    );
  }

  /// 通过设置页面请求权限
  Future<PermissionRequestResult> _requestViaSettings(
    Permission permission,
    String featureModule,
  ) async {
    try {
      final opened = await openAppSettings();
      return PermissionRequestResult(
        success: opened,
        reason: opened ? '已打开设置页面' : '无法打开设置页面',
        strategy: PermissionRequestStrategy.showSettings,
      );
    } catch (e) {
      return PermissionRequestResult(
        success: false,
        reason: '打开设置页面失败: $e',
        strategy: PermissionRequestStrategy.showSettings,
      );
    }
  }

  /// 按优先级排序权限
  List<Permission> _sortPermissionsByPriority(List<Permission> permissions) {
    return permissions
      ..sort((a, b) {
        final priorityA =
            _permissionConfigs[a]?.priority ?? PermissionPriority.low;
        final priorityB =
            _permissionConfigs[b]?.priority ?? PermissionPriority.low;
        return priorityB.index.compareTo(priorityA.index);
      });
  }

  /// 检查是否应该停止批量请求
  bool _shouldStopBatchRequest(
      Map<Permission, PermissionRequestResult> results) {
    // 如果关键权限都已获得，可以停止
    final criticalPermissions = [Permission.notification, Permission.location];
    final grantedCritical =
        criticalPermissions.where((p) => results[p]?.success == true).length;

    return grantedCritical >= criticalPermissions.length / 2;
  }

  /// 获取基本建议
  List<PermissionRecommendation> _getBasicRecommendations() {
    return [
      PermissionRecommendation(
        permission: Permission.notification,
        recommendation: '建议在用户首次使用通知功能时请求权限，并提供清晰的功能说明',
        priority: RecommendationPriority.high,
      ),
      PermissionRecommendation(
        permission: Permission.camera,
        recommendation: '建议在使用相机功能时请求权限，并说明用途',
        priority: RecommendationPriority.medium,
      ),
      PermissionRecommendation(
        permission: Permission.location,
        recommendation: '位置权限敏感，建议提供明确的用途说明',
        priority: RecommendationPriority.high,
      ),
    ];
  }

  /// 为成功率低的权限生成建议
  String _generateRecommendationForLowSuccessRate(PermissionTypeStats stats) {
    if (stats.grantedCount == 0) {
      return '该权限从未成功获得，建议检查权限说明文案和请求时机';
    } else if (stats.permanentlyDeniedCount > 0) {
      return '该权限曾被永久拒绝，建议改善用户体验，让用户理解权限的价值';
    } else {
      return '该权限成功率较低(${(stats.successRate * 100).toStringAsFixed(1)}%)，建议优化请求策略';
    }
  }

  /// 获取建议优先级
  RecommendationPriority _getRecommendationPriority(double successRate) {
    if (successRate < 0.3) return RecommendationPriority.high;
    if (successRate < 0.7) return RecommendationPriority.medium;
    return RecommendationPriority.low;
  }

  /// 从字符串解析权限
  Permission? _parsePermissionFromString(String permissionStr) {
    switch (permissionStr) {
      case '通知权限':
        return Permission.notification;
      case '相机权限':
        return Permission.camera;
      case '照片权限':
        return Permission.photos;
      case '存储权限':
        return Permission.storage;
      case '麦克风权限':
        return Permission.microphone;
      case '位置权限':
        return Permission.location;
      case '悬浮窗权限':
        return Permission.systemAlertWindow;
      case '忽略电池优化权限':
        return Permission.ignoreBatteryOptimizations;
      default:
        return null;
    }
  }

  /// 默认权限配置
  static const PermissionConfig _defaultConfig = PermissionConfig(
    maxRetryCount: 1,
    showRationaleOnFirstRequest: true,
    cooldownPeriod: Duration(days: 7),
    priority: PermissionPriority.low,
  );
}

/// 权限配置
class PermissionConfig {
  final int maxRetryCount;
  final bool showRationaleOnFirstRequest;
  final Duration cooldownPeriod;
  final PermissionPriority priority;

  const PermissionConfig({
    required this.maxRetryCount,
    required this.showRationaleOnFirstRequest,
    required this.cooldownPeriod,
    required this.priority,
  });
}

/// 权限优先级
enum PermissionPriority {
  low,
  medium,
  high,
  critical,
}

/// 权限请求策略
enum PermissionRequestStrategy {
  direct,
  withRationale,
  firstDirect,
  firstWithRationale,
  showSettings,
  force,
  skipped,
  error,
}

/// 权限请求结果
class PermissionRequestResult {
  final bool success;
  final String reason;
  final PermissionRequestStrategy strategy;
  final DateTime timestamp;

  PermissionRequestResult({
    required this.success,
    required this.reason,
    required this.strategy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 权限建议
class PermissionRecommendation {
  final Permission permission;
  final String recommendation;
  final RecommendationPriority priority;

  const PermissionRecommendation({
    required this.permission,
    required this.recommendation,
    required this.priority,
  });
}

/// 建议优先级
enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}
