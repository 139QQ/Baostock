import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限请求统计信息模型
///
/// 用于统计权限请求的各类数据，包括：
/// - 总请求次数和成功率
/// - 按权限类型分组的统计
/// - 按功能模块分组的统计
/// - 时间维度的统计
/// - 用户行为分析
class PermissionStatistics extends Equatable {
  // ignore: public_member_api_docs
  const PermissionStatistics({
    required this.startDate,
    required this.endDate,
    this.totalRequests = 0,
    this.grantedCount = 0,
    this.deniedCount = 0,
    this.permanentlyDeniedCount = 0,
    this.retryCount = 0,
    this.firstRequestCount = 0,
    this.rationaleShownCount = 0,
    this.permissionTypeStats = const {},
    this.moduleStats = const {},
    this.dailyStats = const {},
    this.avgDurationMs = 0.0,
    this.minDurationMs = 0,
    this.maxDurationMs = 0,
    required this.lastUpdated,
  });

  /// 统计时间范围开始
  final DateTime startDate;

  /// 统计时间范围结束
  final DateTime endDate;

  /// 总请求次数
  final int totalRequests;

  /// 成功授权次数
  final int grantedCount;

  /// 被拒绝次数
  final int deniedCount;

  /// 永久拒绝次数
  final int permanentlyDeniedCount;

  /// 重试次数
  final int retryCount;

  /// 首次请求次数
  final int firstRequestCount;

  /// 显示权限说明次数
  final int rationaleShownCount;

  /// 按权限类型分组的统计
  final Map<String, PermissionTypeStats> permissionTypeStats;

  /// 按功能模块分组的统计
  final Map<String, ModuleStats> moduleStats;

  /// 按日期分组的统计
  final Map<String, DailyStats> dailyStats;

  /// 平均请求耗时（毫秒）
  final double avgDurationMs;

  /// 最快请求耗时（毫秒）
  final int minDurationMs;

  /// 最慢请求耗时（毫秒）
  final int maxDurationMs;

  /// 最后更新时间
  final DateTime lastUpdated;

  /// 从JSON创建实例
  factory PermissionStatistics.fromJson(Map<String, dynamic> json) {
    return PermissionStatistics(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalRequests: json['totalRequests'] as int? ?? 0,
      grantedCount: json['grantedCount'] as int? ?? 0,
      deniedCount: json['deniedCount'] as int? ?? 0,
      permanentlyDeniedCount: json['permanentlyDeniedCount'] as int? ?? 0,
      retryCount: json['retryCount'] as int? ?? 0,
      firstRequestCount: json['firstRequestCount'] as int? ?? 0,
      rationaleShownCount: json['rationaleShownCount'] as int? ?? 0,
      permissionTypeStats:
          (json['permissionTypeStats'] as Map<String, dynamic>?)?.map(
                  (key, value) => MapEntry(
                      key,
                      PermissionTypeStats.fromJson(
                          value as Map<String, dynamic>))) ??
              {},
      moduleStats: (json['moduleStats'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                  key, ModuleStats.fromJson(value as Map<String, dynamic>))) ??
          {},
      dailyStats: (json['dailyStats'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                  key, DailyStats.fromJson(value as Map<String, dynamic>))) ??
          {},
      avgDurationMs: (json['avgDurationMs'] as num?)?.toDouble() ?? 0.0,
      minDurationMs: json['minDurationMs'] as int? ?? 0,
      maxDurationMs: json['maxDurationMs'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalRequests': totalRequests,
      'grantedCount': grantedCount,
      'deniedCount': deniedCount,
      'permanentlyDeniedCount': permanentlyDeniedCount,
      'retryCount': retryCount,
      'firstRequestCount': firstRequestCount,
      'rationaleShownCount': rationaleShownCount,
      'permissionTypeStats': permissionTypeStats
          .map((key, value) => MapEntry(key, value.toJson())),
      'moduleStats':
          moduleStats.map((key, value) => MapEntry(key, value.toJson())),
      'dailyStats':
          dailyStats.map((key, value) => MapEntry(key, value.toJson())),
      'avgDurationMs': avgDurationMs,
      'minDurationMs': minDurationMs,
      'maxDurationMs': maxDurationMs,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 创建副本
  PermissionStatistics copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? totalRequests,
    int? grantedCount,
    int? deniedCount,
    int? permanentlyDeniedCount,
    int? retryCount,
    int? firstRequestCount,
    int? rationaleShownCount,
    Map<String, PermissionTypeStats>? permissionTypeStats,
    Map<String, ModuleStats>? moduleStats,
    Map<String, DailyStats>? dailyStats,
    double? avgDurationMs,
    int? minDurationMs,
    int? maxDurationMs,
    DateTime? lastUpdated,
  }) {
    return PermissionStatistics(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalRequests: totalRequests ?? this.totalRequests,
      grantedCount: grantedCount ?? this.grantedCount,
      deniedCount: deniedCount ?? this.deniedCount,
      permanentlyDeniedCount:
          permanentlyDeniedCount ?? this.permanentlyDeniedCount,
      retryCount: retryCount ?? this.retryCount,
      firstRequestCount: firstRequestCount ?? this.firstRequestCount,
      rationaleShownCount: rationaleShownCount ?? this.rationaleShownCount,
      permissionTypeStats: permissionTypeStats ?? this.permissionTypeStats,
      moduleStats: moduleStats ?? this.moduleStats,
      dailyStats: dailyStats ?? this.dailyStats,
      avgDurationMs: avgDurationMs ?? this.avgDurationMs,
      minDurationMs: minDurationMs ?? this.minDurationMs,
      maxDurationMs: maxDurationMs ?? this.maxDurationMs,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 计算成功率
  double get successRate =>
      totalRequests > 0 ? grantedCount / totalRequests : 0.0;

  /// 计算拒绝率
  double get denialRate => totalRequests > 0
      ? (deniedCount + permanentlyDeniedCount) / totalRequests
      : 0.0;

  /// 计算永久拒绝率
  double get permanentDenialRate =>
      totalRequests > 0 ? permanentlyDeniedCount / totalRequests : 0.0;

  /// 计算重试率
  double get retryRate => totalRequests > 0 ? retryCount / totalRequests : 0.0;

  /// 获取最常请求的权限类型
  String? get mostRequestedPermissionType {
    if (permissionTypeStats.isEmpty) return null;
    return permissionTypeStats.entries
        .reduce((a, b) => a.value.requestCount > b.value.requestCount ? a : b)
        .key;
  }

  /// 获取成功率最高的权限类型
  String? get highestSuccessRatePermissionType {
    if (permissionTypeStats.isEmpty) return null;
    return permissionTypeStats.entries
        .where((e) => e.value.requestCount > 0)
        .reduce((a, b) => (a.value.grantedCount / a.value.requestCount) >
                (b.value.grantedCount / b.value.requestCount)
            ? a
            : b)
        .key;
  }

  /// 获取最活跃的功能模块
  String? get mostActiveModule {
    if (moduleStats.isEmpty) return null;
    return moduleStats.entries
        .reduce((a, b) => a.value.requestCount > b.value.requestCount ? a : b)
        .key;
  }

  /// 获取今日统计
  DailyStats? get todayStats {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return dailyStats[today];
  }

  /// 获取本周统计
  Map<String, DailyStats> get thisWeekStats {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartKey = weekStart.toIso8601String().substring(0, 10);

    return Map.fromEntries(
        dailyStats.entries.where((e) => e.key.compareTo(weekStartKey) >= 0));
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        totalRequests,
        grantedCount,
        deniedCount,
        permanentlyDeniedCount,
        retryCount,
        firstRequestCount,
        rationaleShownCount,
        permissionTypeStats,
        moduleStats,
        dailyStats,
        avgDurationMs,
        minDurationMs,
        maxDurationMs,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'PermissionStatistics('
        'period: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}, '
        'total: $totalRequests, '
        'successRate: ${(successRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// 权限类型统计
class PermissionTypeStats extends Equatable {
  /// 权限类型名称
  final String permissionType;

  /// 请求次数
  final int requestCount;

  /// 成功授权次数
  final int grantedCount;

  /// 被拒绝次数
  final int deniedCount;

  /// 永久拒绝次数
  final int permanentlyDeniedCount;

  /// 首次请求次数
  final int firstRequestCount;

  /// 显示权限说明次数
  final int rationaleShownCount;

  /// 平均耗时
  final double avgDurationMs;

  const PermissionTypeStats({
    required this.permissionType,
    this.requestCount = 0,
    this.grantedCount = 0,
    this.deniedCount = 0,
    this.permanentlyDeniedCount = 0,
    this.firstRequestCount = 0,
    this.rationaleShownCount = 0,
    this.avgDurationMs = 0.0,
  });

  factory PermissionTypeStats.fromJson(Map<String, dynamic> json) {
    return PermissionTypeStats(
      permissionType: json['permissionType'] as String,
      requestCount: json['requestCount'] as int? ?? 0,
      grantedCount: json['grantedCount'] as int? ?? 0,
      deniedCount: json['deniedCount'] as int? ?? 0,
      permanentlyDeniedCount: json['permanentlyDeniedCount'] as int? ?? 0,
      firstRequestCount: json['firstRequestCount'] as int? ?? 0,
      rationaleShownCount: json['rationaleShownCount'] as int? ?? 0,
      avgDurationMs: (json['avgDurationMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'permissionType': permissionType,
      'requestCount': requestCount,
      'grantedCount': grantedCount,
      'deniedCount': deniedCount,
      'permanentlyDeniedCount': permanentlyDeniedCount,
      'firstRequestCount': firstRequestCount,
      'rationaleShownCount': rationaleShownCount,
      'avgDurationMs': avgDurationMs,
    };
  }

  /// 计算成功率
  double get successRate =>
      requestCount > 0 ? grantedCount / requestCount : 0.0;

  @override
  List<Object?> get props => [
        permissionType,
        requestCount,
        grantedCount,
        deniedCount,
        permanentlyDeniedCount,
        firstRequestCount,
        rationaleShownCount,
        avgDurationMs,
      ];
}

/// 功能模块统计
class ModuleStats extends Equatable {
  /// 模块名称
  final String moduleName;

  /// 请求次数
  final int requestCount;

  /// 成功授权次数
  final int grantedCount;

  /// 涉及的权限类型数量
  final int permissionTypesInvolved;

  /// 平均耗时
  final double avgDurationMs;

  const ModuleStats({
    required this.moduleName,
    this.requestCount = 0,
    this.grantedCount = 0,
    this.permissionTypesInvolved = 0,
    this.avgDurationMs = 0.0,
  });

  factory ModuleStats.fromJson(Map<String, dynamic> json) {
    return ModuleStats(
      moduleName: json['moduleName'] as String,
      requestCount: json['requestCount'] as int? ?? 0,
      grantedCount: json['grantedCount'] as int? ?? 0,
      permissionTypesInvolved: json['permissionTypesInvolved'] as int? ?? 0,
      avgDurationMs: (json['avgDurationMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleName': moduleName,
      'requestCount': requestCount,
      'grantedCount': grantedCount,
      'permissionTypesInvolved': permissionTypesInvolved,
      'avgDurationMs': avgDurationMs,
    };
  }

  /// 计算成功率
  double get successRate =>
      requestCount > 0 ? grantedCount / requestCount : 0.0;

  @override
  List<Object?> get props => [
        moduleName,
        requestCount,
        grantedCount,
        permissionTypesInvolved,
        avgDurationMs,
      ];
}

/// 日期统计
class DailyStats extends Equatable {
  /// 日期
  final String date;

  /// 请求次数
  final int requestCount;

  /// 成功授权次数
  final int grantedCount;

  /// 被拒绝次数
  final int deniedCount;

  /// 永久拒绝次数
  final int permanentlyDeniedCount;

  const DailyStats({
    required this.date,
    this.requestCount = 0,
    this.grantedCount = 0,
    this.deniedCount = 0,
    this.permanentlyDeniedCount = 0,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] as String,
      requestCount: json['requestCount'] as int? ?? 0,
      grantedCount: json['grantedCount'] as int? ?? 0,
      deniedCount: json['deniedCount'] as int? ?? 0,
      permanentlyDeniedCount: json['permanentlyDeniedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'requestCount': requestCount,
      'grantedCount': grantedCount,
      'deniedCount': deniedCount,
      'permanentlyDeniedCount': permanentlyDeniedCount,
    };
  }

  /// 计算成功率
  double get successRate =>
      requestCount > 0 ? grantedCount / requestCount : 0.0;

  @override
  List<Object?> get props => [
        date,
        requestCount,
        grantedCount,
        deniedCount,
        permanentlyDeniedCount,
      ];
}
