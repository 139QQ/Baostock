import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'models/permission_request_record.dart';
import 'models/permission_statistics.dart';

/// 权限历史记录管理器
///
/// 负责管理权限请求的历史记录，包括：
/// - 记录每次权限请求的详细信息
/// - 统计权限请求的成功率、失败率等
/// - 提供权限请求历史查询功能
/// - 优化权限请求策略的数据支持
class PermissionHistoryManager {
  // 私有构造函数，确保单例模式
  PermissionHistoryManager._();

  /// 单例实例
  static final PermissionHistoryManager _instance =
      PermissionHistoryManager._();

  /// 获取单例实例
  static PermissionHistoryManager get instance => _instance;

  /// SharedPreferences实例
  SharedPreferences? _prefs;

  /// 权限记录缓存
  final List<PermissionRequestRecord> _recordsCache = [];

  /// 统计信息缓存
  PermissionStatistics? _statisticsCache;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 缓存的最大记录数
  static const int _maxCacheSize = 1000;

  /// SharedPreferences键前缀
  static const String _keyPrefix = 'permission_history_';
  static const String _recordsKey = '${_keyPrefix}records';
  static const String _statisticsKey = '${_keyPrefix}statistics';
  static const String _lastCleanupKey = '${_keyPrefix}last_cleanup';

  /// 初始化历史记录管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🔍 初始化权限历史记录管理器');

      // 获取SharedPreferences实例
      _prefs = await SharedPreferences.getInstance();

      // 加载历史记录
      await _loadRecords();

      // 加载统计信息
      await _loadStatistics();

      // 执行清理（每天一次）
      await _performCleanupIfNeeded();

      _isInitialized = true;
      AppLogger.info('✅ 权限历史记录管理器初始化完成，共加载 ${_recordsCache.length} 条记录');
    } catch (e, stack) {
      AppLogger.error('❌ 权限历史记录管理器初始化失败', e, stack);
      // 初始化失败不影响应用运行，只影响统计功能
    }
  }

  /// 记录权限请求
  Future<void> recordPermissionRequest({
    required Permission permission,
    required PermissionStatus status,
    required String featureModule,
    required String context,
    bool isFirstRequest = true,
    int retryCount = 0,
    bool showedRationale = false,
    int durationMs = 0,
    Map<String, String>? deviceInfo,
    String? appVersion,
  }) async {
    if (!_isInitialized) {
      AppLogger.warn('⚠️ 权限历史记录管理器未初始化，跳过记录');
      return;
    }

    try {
      // 创建记录对象
      final record = PermissionRequestRecord(
        id: _generateRecordId(),
        permission: permission,
        permissionName: _getPermissionName(permission),
        requestTime: DateTime.now(),
        status: status,
        featureModule: featureModule,
        context: context,
        isFirstRequest: isFirstRequest,
        retryCount: retryCount,
        showedRationale: showedRationale,
        durationMs: durationMs,
        deviceInfo: deviceInfo ?? await _getDeviceInfo(),
        appVersion: appVersion ?? await _getAppVersion(),
      );

      // 添加到缓存
      _recordsCache.add(record);

      // 限制缓存大小
      if (_recordsCache.length > _maxCacheSize) {
        _recordsCache.removeAt(0);
      }

      // 保存到持久化存储
      await _saveRecords();

      // 更新统计信息
      await _updateStatistics(record);

      AppLogger.debug('📝 权限请求记录已保存: $record');
    } catch (e, stack) {
      AppLogger.error('❌ 保存权限请求记录失败', e, stack);
    }
  }

  /// 获取权限请求历史记录
  Future<List<PermissionRequestRecord>> getPermissionHistory({
    Permission? permission,
    String? featureModule,
    PermissionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    if (!_isInitialized) return [];

    try {
      List<PermissionRequestRecord> filteredRecords = List.from(_recordsCache);

      // 按权限类型过滤
      if (permission != null) {
        filteredRecords = filteredRecords
            .where((record) => record.permission == permission)
            .toList();
      }

      // 按功能模块过滤
      if (featureModule != null && featureModule.isNotEmpty) {
        filteredRecords = filteredRecords
            .where((record) => record.featureModule == featureModule)
            .toList();
      }

      // 按状态过滤
      if (status != null) {
        filteredRecords =
            filteredRecords.where((record) => record.status == status).toList();
      }

      // 按时间范围过滤
      if (startDate != null) {
        filteredRecords = filteredRecords
            .where((record) => record.requestTime.isAfter(startDate))
            .toList();
      }

      if (endDate != null) {
        filteredRecords = filteredRecords
            .where((record) => record.requestTime.isBefore(endDate))
            .toList();
      }

      // 按时间倒序排列
      filteredRecords.sort((a, b) => b.requestTime.compareTo(a.requestTime));

      // 分页
      final start = offset;
      final end = start + limit;
      if (start >= filteredRecords.length) return [];

      return filteredRecords.sublist(
        start,
        end > filteredRecords.length ? filteredRecords.length : end,
      );
    } catch (e, stack) {
      AppLogger.error('❌ 获取权限历史记录失败', e, stack);
      return [];
    }
  }

  /// 获取权限统计信息
  Future<PermissionStatistics?> getPermissionStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized) return null;

    try {
      // 如果没有指定时间范围，返回缓存的统计信息
      if (startDate == null && endDate == null) {
        return _statisticsCache;
      }

      // 计算指定时间范围的统计信息
      return await _calculateStatistics(startDate, endDate);
    } catch (e, stack) {
      AppLogger.error('❌ 获取权限统计信息失败', e, stack);
      return null;
    }
  }

  /// 获取特定权限的历史记录数量
  Future<int> getPermissionRequestCount({
    Permission? permission,
    String? featureModule,
    PermissionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final records = await getPermissionHistory(
      permission: permission,
      featureModule: featureModule,
      status: status,
      startDate: startDate,
      endDate: endDate,
      limit: _maxCacheSize, // 获取所有符合条件的记录
    );

    return records.length;
  }

  /// 获取特定权限的成功率
  Future<double> getPermissionSuccessRate(Permission permission) async {
    try {
      final records = await getPermissionHistory(
        permission: permission,
        limit: _maxCacheSize,
      );

      if (records.isEmpty) return 0.0;

      final grantedCount = records.where((r) => r.isGranted).length;
      return grantedCount / records.length;
    } catch (e) {
      AppLogger.error('计算权限成功率失败', e);
      return 0.0;
    }
  }

  /// 检查权限是否曾被永久拒绝
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    try {
      final records = await getPermissionHistory(
        permission: permission,
        status: PermissionStatus.permanentlyDenied,
        limit: 10, // 只需要检查最近的记录
      );

      return records.isNotEmpty;
    } catch (e) {
      AppLogger.error('检查权限永久拒绝状态失败', e);
      return false;
    }
  }

  /// 获取最近一次权限请求记录
  Future<PermissionRequestRecord?> getLastPermissionRequest(
      Permission permission) async {
    try {
      final records = await getPermissionHistory(
        permission: permission,
        limit: 1,
      );

      return records.isNotEmpty ? records.first : null;
    } catch (e) {
      AppLogger.error('获取最近权限请求记录失败', e);
      return null;
    }
  }

  /// 清除所有历史记录
  Future<void> clearAllHistory() async {
    if (!_isInitialized) return;

    try {
      _recordsCache.clear();
      _statisticsCache = null;

      await _prefs?.remove(_recordsKey);
      await _prefs?.remove(_statisticsKey);

      AppLogger.info('🗑️ 所有权限历史记录已清除');
    } catch (e, stack) {
      AppLogger.error('❌ 清除权限历史记录失败', e, stack);
    }
  }

  /// 清除指定时间范围的历史记录
  Future<void> clearHistoryInRange(DateTime startDate, DateTime endDate) async {
    if (!_isInitialized) return;

    try {
      _recordsCache.removeWhere((record) =>
          record.requestTime.isAfter(startDate) &&
          record.requestTime.isBefore(endDate));

      await _saveRecords();
      await _updateStatistics(null);

      AppLogger.info('🗑️ 指定时间范围的权限历史记录已清除');
    } catch (e, stack) {
      AppLogger.error('❌ 清除指定时间范围的权限历史记录失败', e, stack);
    }
  }

  /// 导出历史记录为JSON
  Future<String> exportHistoryAsJson() async {
    try {
      final exportData = {
        'exportTime': DateTime.now().toIso8601String(),
        'totalRecords': _recordsCache.length,
        'statistics': _statisticsCache?.toJson(),
        'records': _recordsCache.map((r) => r.toJson()).toList(),
      };

      return jsonEncode(exportData);
    } catch (e, stack) {
      AppLogger.error('❌ 导出权限历史记录失败', e, stack);
      rethrow;
    }
  }

  /// 生成记录ID
  String _generateRecordId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_recordsCache.length}';
  }

  /// 获取权限名称
  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return '通知权限';
      case Permission.camera:
        return '相机权限';
      case Permission.photos:
        return '照片权限';
      case Permission.storage:
        return '存储权限';
      case Permission.microphone:
        return '麦克风权限';
      case Permission.location:
        return '位置权限';
      case Permission.systemAlertWindow:
        return '悬浮窗权限';
      case Permission.ignoreBatteryOptimizations:
        return '忽略电池优化权限';
      default:
        return permission.toString();
    }
  }

  /// 获取设备信息
  Future<Map<String, String>> _getDeviceInfo() async {
    // 这里可以根据需要获取更详细的设备信息
    return {
      'platform': defaultTargetPlatform.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 获取应用版本
  Future<String> _getAppVersion() async {
    // 这里可以从package_info获取版本信息
    // 暂时返回默认值
    return '0.5.5';
  }

  /// 加载历史记录
  Future<void> _loadRecords() async {
    try {
      final recordsJson = _prefs?.getString(_recordsKey);
      if (recordsJson != null && recordsJson.isNotEmpty) {
        final List<dynamic> recordsList = jsonDecode(recordsJson);
        _recordsCache.clear();

        for (final recordJson in recordsList) {
          try {
            final record = PermissionRequestRecord.fromJson(recordJson);
            _recordsCache.add(record);
          } catch (e) {
            AppLogger.warn('解析权限记录失败: $e');
          }
        }

        AppLogger.debug('📚 从存储加载了 ${_recordsCache.length} 条权限记录');
      }
    } catch (e) {
      AppLogger.error('加载权限历史记录失败', e);
    }
  }

  /// 保存历史记录
  Future<void> _saveRecords() async {
    try {
      final recordsJson = jsonEncode(
        _recordsCache.map((record) => record.toJson()).toList(),
      );
      await _prefs?.setString(_recordsKey, recordsJson);
    } catch (e) {
      AppLogger.error('保存权限历史记录失败', e);
    }
  }

  /// 加载统计信息
  Future<void> _loadStatistics() async {
    try {
      final statisticsJson = _prefs?.getString(_statisticsKey);
      if (statisticsJson != null && statisticsJson.isNotEmpty) {
        final statisticsMap = jsonDecode(statisticsJson);
        _statisticsCache = PermissionStatistics.fromJson(statisticsMap);
        AppLogger.debug('📊 权限统计信息已加载');
      }
    } catch (e) {
      AppLogger.error('加载权限统计信息失败', e);
    }
  }

  /// 保存统计信息
  Future<void> _saveStatistics() async {
    try {
      if (_statisticsCache != null) {
        final statisticsJson = jsonEncode(_statisticsCache!.toJson());
        await _prefs?.setString(_statisticsKey, statisticsJson);
      }
    } catch (e) {
      AppLogger.error('保存权限统计信息失败', e);
    }
  }

  /// 更新统计信息
  Future<void> _updateStatistics(PermissionRequestRecord? newRecord) async {
    try {
      // 如果没有新的记录，重新计算所有统计信息
      if (newRecord == null) {
        _statisticsCache = await _calculateStatistics();
        await _saveStatistics();
        return;
      }

      // 更新现有统计信息
      _statisticsCache = _updateExistingStatistics(_statisticsCache, newRecord);
      await _saveStatistics();
    } catch (e) {
      AppLogger.error('更新权限统计信息失败', e);
    }
  }

  /// 计算统计信息
  Future<PermissionStatistics> _calculateStatistics([
    DateTime? startDate,
    DateTime? endDate,
  ]) async {
    // 获取时间范围内的记录
    final records = await getPermissionHistory(
      startDate: startDate,
      endDate: endDate,
      limit: _maxCacheSize,
    );

    if (records.isEmpty) {
      return PermissionStatistics(
        startDate: startDate ?? DateTime.now(),
        endDate: endDate ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    }

    // 计算基础统计
    int totalRequests = records.length;
    int grantedCount = records.where((r) => r.isGranted).length;
    int deniedCount = records.where((r) => r.isDenied).length;
    int permanentlyDeniedCount =
        records.where((r) => r.isPermanentlyDenied).length;
    int retryCount = records.fold(0, (sum, r) => sum + r.retryCount);
    int firstRequestCount = records.where((r) => r.isFirstRequest).length;
    int rationaleShownCount = records.where((r) => r.showedRationale).length;

    // 计算耗时统计
    final durations =
        records.map((r) => r.durationMs).where((d) => d > 0).toList();
    double avgDurationMs = durations.isNotEmpty
        ? durations.reduce((a, b) => a + b) / durations.length
        : 0.0;
    int minDurationMs =
        durations.isNotEmpty ? durations.reduce((a, b) => a < b ? a : b) : 0;
    int maxDurationMs =
        durations.isNotEmpty ? durations.reduce((a, b) => a > b ? a : b) : 0;

    // 按权限类型分组统计
    final Map<String, PermissionTypeStats> permissionTypeStats = {};
    for (final record in records) {
      final type = record.permissionTypeDescription;
      if (!permissionTypeStats.containsKey(type)) {
        permissionTypeStats[type] = PermissionTypeStats(permissionType: type);
      }

      final stats = permissionTypeStats[type]!;
      permissionTypeStats[type] = PermissionTypeStats(
        permissionType: type,
        requestCount: stats.requestCount + 1,
        grantedCount: stats.grantedCount + (record.isGranted ? 1 : 0),
        deniedCount: stats.deniedCount + (record.isDenied ? 1 : 0),
        permanentlyDeniedCount:
            stats.permanentlyDeniedCount + (record.isPermanentlyDenied ? 1 : 0),
        firstRequestCount:
            stats.firstRequestCount + (record.isFirstRequest ? 1 : 0),
        rationaleShownCount:
            stats.rationaleShownCount + (record.showedRationale ? 1 : 0),
        avgDurationMs:
            (stats.avgDurationMs * stats.requestCount + record.durationMs) /
                (stats.requestCount + 1),
      );
    }

    // 按功能模块分组统计
    final Map<String, ModuleStats> moduleStats = {};
    for (final record in records) {
      final module = record.featureModule;
      if (!moduleStats.containsKey(module)) {
        moduleStats[module] = ModuleStats(moduleName: module);
      }

      final stats = moduleStats[module]!;
      moduleStats[module] = ModuleStats(
        moduleName: module,
        requestCount: stats.requestCount + 1,
        grantedCount: stats.grantedCount + (record.isGranted ? 1 : 0),
        permissionTypesInvolved: stats.permissionTypesInvolved, // 这个需要更复杂的计算
        avgDurationMs:
            (stats.avgDurationMs * stats.requestCount + record.durationMs) /
                (stats.requestCount + 1),
      );
    }

    // 按日期分组统计
    final Map<String, DailyStats> dailyStats = {};
    for (final record in records) {
      final date = record.requestTime.toIso8601String().substring(0, 10);
      if (!dailyStats.containsKey(date)) {
        dailyStats[date] = DailyStats(date: date);
      }

      final stats = dailyStats[date]!;
      dailyStats[date] = DailyStats(
        date: date,
        requestCount: stats.requestCount + 1,
        grantedCount: stats.grantedCount + (record.isGranted ? 1 : 0),
        deniedCount: stats.deniedCount + (record.isDenied ? 1 : 0),
        permanentlyDeniedCount:
            stats.permanentlyDeniedCount + (record.isPermanentlyDenied ? 1 : 0),
      );
    }

    // 更新模块统计中的权限类型数量
    for (final module in moduleStats.keys) {
      final uniquePermissionTypes = records
          .where((r) => r.featureModule == module)
          .map((r) => r.permissionTypeDescription)
          .toSet()
          .length;

      final stats = moduleStats[module]!;
      moduleStats[module] = ModuleStats(
        moduleName: module,
        requestCount: stats.requestCount,
        grantedCount: stats.grantedCount,
        permissionTypesInvolved: uniquePermissionTypes,
        avgDurationMs: stats.avgDurationMs,
      );
    }

    return PermissionStatistics(
      startDate: startDate ?? records.first.requestTime,
      endDate: endDate ?? records.last.requestTime,
      totalRequests: totalRequests,
      grantedCount: grantedCount,
      deniedCount: deniedCount,
      permanentlyDeniedCount: permanentlyDeniedCount,
      retryCount: retryCount,
      firstRequestCount: firstRequestCount,
      rationaleShownCount: rationaleShownCount,
      permissionTypeStats: permissionTypeStats,
      moduleStats: moduleStats,
      dailyStats: dailyStats,
      avgDurationMs: avgDurationMs,
      minDurationMs: minDurationMs,
      maxDurationMs: maxDurationMs,
      lastUpdated: DateTime.now(),
    );
  }

  /// 更新现有统计信息
  PermissionStatistics _updateExistingStatistics(
    PermissionStatistics? existingStats,
    PermissionRequestRecord newRecord,
  ) {
    if (existingStats == null) {
      // 如果没有现有统计，创建新的统计信息
      return PermissionStatistics(
        startDate: newRecord.requestTime,
        endDate: newRecord.requestTime,
        totalRequests: 1,
        grantedCount: newRecord.isGranted ? 1 : 0,
        deniedCount: newRecord.isDenied ? 1 : 0,
        permanentlyDeniedCount: newRecord.isPermanentlyDenied ? 1 : 0,
        retryCount: newRecord.retryCount,
        firstRequestCount: newRecord.isFirstRequest ? 1 : 0,
        rationaleShownCount: newRecord.showedRationale ? 1 : 0,
        avgDurationMs: newRecord.durationMs.toDouble(),
        minDurationMs: newRecord.durationMs,
        maxDurationMs: newRecord.durationMs,
        lastUpdated: DateTime.now(),
      );
    }

    // 更新现有统计
    final newTotalRequests = existingStats.totalRequests + 1;
    final newGrantedCount =
        existingStats.grantedCount + (newRecord.isGranted ? 1 : 0);
    final newDeniedCount =
        existingStats.deniedCount + (newRecord.isDenied ? 1 : 0);
    final newPermanentlyDeniedCount = existingStats.permanentlyDeniedCount +
        (newRecord.isPermanentlyDenied ? 1 : 0);
    final newRetryCount = existingStats.retryCount + newRecord.retryCount;
    final newFirstRequestCount =
        existingStats.firstRequestCount + (newRecord.isFirstRequest ? 1 : 0);
    final newRationaleShownCount =
        existingStats.rationaleShownCount + (newRecord.showedRationale ? 1 : 0);

    // 更新平均耗时
    final newAvgDurationMs =
        (existingStats.avgDurationMs * existingStats.totalRequests +
                newRecord.durationMs) /
            newTotalRequests;
    final newMinDurationMs = existingStats.minDurationMs == 0
        ? newRecord.durationMs
        : (newRecord.durationMs < existingStats.minDurationMs
            ? newRecord.durationMs
            : existingStats.minDurationMs);
    final newMaxDurationMs = newRecord.durationMs > existingStats.maxDurationMs
        ? newRecord.durationMs
        : existingStats.maxDurationMs;

    // 更新时间范围
    final newStartDate = newRecord.requestTime.isBefore(existingStats.startDate)
        ? newRecord.requestTime
        : existingStats.startDate;
    final newEndDate = newRecord.requestTime.isAfter(existingStats.endDate)
        ? newRecord.requestTime
        : existingStats.endDate;

    // 更新权限类型统计
    final permissionTypeStats = Map<String, PermissionTypeStats>.from(
        existingStats.permissionTypeStats);
    final permissionType = newRecord.permissionTypeDescription;
    final existingTypeStats = permissionTypeStats[permissionType];

    permissionTypeStats[permissionType] = PermissionTypeStats(
      permissionType: permissionType,
      requestCount: (existingTypeStats?.requestCount ?? 0) + 1,
      grantedCount: (existingTypeStats?.grantedCount ?? 0) +
          (newRecord.isGranted ? 1 : 0),
      deniedCount:
          (existingTypeStats?.deniedCount ?? 0) + (newRecord.isDenied ? 1 : 0),
      permanentlyDeniedCount: (existingTypeStats?.permanentlyDeniedCount ?? 0) +
          (newRecord.isPermanentlyDenied ? 1 : 0),
      firstRequestCount: (existingTypeStats?.firstRequestCount ?? 0) +
          (newRecord.isFirstRequest ? 1 : 0),
      rationaleShownCount: (existingTypeStats?.rationaleShownCount ?? 0) +
          (newRecord.showedRationale ? 1 : 0),
      avgDurationMs: existingTypeStats == null
          ? newRecord.durationMs.toDouble()
          : (existingTypeStats.avgDurationMs * existingTypeStats.requestCount +
                  newRecord.durationMs) /
              (existingTypeStats.requestCount + 1),
    );

    // 更新模块统计
    final moduleStats =
        Map<String, ModuleStats>.from(existingStats.moduleStats);
    final moduleName = newRecord.featureModule;
    final existingModuleStats = moduleStats[moduleName];

    moduleStats[moduleName] = ModuleStats(
      moduleName: moduleName,
      requestCount: (existingModuleStats?.requestCount ?? 0) + 1,
      grantedCount: (existingModuleStats?.grantedCount ?? 0) +
          (newRecord.isGranted ? 1 : 0),
      permissionTypesInvolved:
          existingModuleStats?.permissionTypesInvolved ?? 1, // 简化处理
      avgDurationMs: existingModuleStats == null
          ? newRecord.durationMs.toDouble()
          : (existingModuleStats.avgDurationMs *
                      existingModuleStats.requestCount +
                  newRecord.durationMs) /
              (existingModuleStats.requestCount + 1),
    );

    // 更新日期统计
    final dailyStats = Map<String, DailyStats>.from(existingStats.dailyStats);
    final date = newRecord.requestTime.toIso8601String().substring(0, 10);
    final existingDailyStats = dailyStats[date];

    dailyStats[date] = DailyStats(
      date: date,
      requestCount: (existingDailyStats?.requestCount ?? 0) + 1,
      grantedCount: (existingDailyStats?.grantedCount ?? 0) +
          (newRecord.isGranted ? 1 : 0),
      deniedCount:
          (existingDailyStats?.deniedCount ?? 0) + (newRecord.isDenied ? 1 : 0),
      permanentlyDeniedCount:
          (existingDailyStats?.permanentlyDeniedCount ?? 0) +
              (newRecord.isPermanentlyDenied ? 1 : 0),
    );

    return PermissionStatistics(
      startDate: newStartDate,
      endDate: newEndDate,
      totalRequests: newTotalRequests,
      grantedCount: newGrantedCount,
      deniedCount: newDeniedCount,
      permanentlyDeniedCount: newPermanentlyDeniedCount,
      retryCount: newRetryCount,
      firstRequestCount: newFirstRequestCount,
      rationaleShownCount: newRationaleShownCount,
      permissionTypeStats: permissionTypeStats,
      moduleStats: moduleStats,
      dailyStats: dailyStats,
      avgDurationMs: newAvgDurationMs,
      minDurationMs: newMinDurationMs,
      maxDurationMs: newMaxDurationMs,
      lastUpdated: DateTime.now(),
    );
  }

  /// 执行清理操作
  Future<void> _performCleanupIfNeeded() async {
    try {
      final lastCleanup = _prefs?.getInt(_lastCleanupKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneDayInMs = 24 * 60 * 60 * 1000;

      // 如果距离上次清理超过一天，执行清理
      if (now - lastCleanup > oneDayInMs) {
        await _performCleanup();
        await _prefs?.setInt(_lastCleanupKey, now);
        AppLogger.info('🧹 权限历史记录清理完成');
      }
    } catch (e) {
      AppLogger.error('执行权限历史记录清理失败', e);
    }
  }

  /// 执行清理操作
  Future<void> _performCleanup() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // 删除30天前的记录
      final originalSize = _recordsCache.length;
      _recordsCache
          .removeWhere((record) => record.requestTime.isBefore(thirtyDaysAgo));
      final removedCount = originalSize - _recordsCache.length;

      if (removedCount > 0) {
        await _saveRecords();
        await _updateStatistics(null); // 重新计算统计信息
        AppLogger.info('🗑️ 清理了 $removedCount 条过期权限记录');
      }
    } catch (e) {
      AppLogger.error('清理权限历史记录失败', e);
    }
  }

  /// 获取初始化状态
  bool get isInitialized => _isInitialized;

  /// 获取缓存记录数量
  int get cacheSize => _recordsCache.length;

  /// 获取统计信息缓存
  PermissionStatistics? get statisticsCache => _statisticsCache;
}
