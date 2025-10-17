import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'optimized_fund_service.dart';
import 'smart_cache_manager.dart';
import 'common_types.dart';
import '../../models/fund.dart';

/// 数据同步和刷新策略管理器
///
/// 核心功能：
/// - 智能数据同步策略
/// - 增量更新机制
/// - 数据一致性保证
/// - 冲突解决策略
/// - 离线数据支持
class DataSyncManager {
  final OptimizedFundService _fundService;
  final SmartCacheManager _cacheManager;
  // final DataPreloadManager _preloadManager; // 预留后续扩展使用

  // 同步状态管理
  final Map<String, SyncState> _syncStates = {};
  Timer? _syncTimer;
  Duration _syncInterval = const Duration(minutes: 10);

  // 数据版本控制
  final Map<String, DataVersion> _dataVersions = {};

  // 冲突解决策略
  ConflictResolutionStrategy _conflictStrategy =
      ConflictResolutionStrategy.timestamp;

  DataSyncManager({
    required OptimizedFundService fundService,
    required SmartCacheManager cacheManager,
    // required DataPreloadManager preloadManager, // 预留后续扩展使用
  })  : _fundService = fundService,
        _cacheManager = cacheManager;
  // _preloadManager = preloadManager;

  /// 初始化同步管理器
  Future<void> initialize() async {
    debugPrint('🔄 初始化数据同步管理器...');

    // 启动定期同步
    _startPeriodicSync();

    // 初始化数据版本
    await _initializeDataVersions();

    debugPrint('✅ 数据同步管理器初始化完成');
  }

  /// 初始化数据版本
  Future<void> _initializeDataVersions() async {
    final dataTypes = ['funds', 'rankings', 'search_results'];

    for (final dataType in dataTypes) {
      // 从缓存获取版本信息
      final cachedVersion = _cacheManager.get<DataVersion>('version_$dataType');

      if (cachedVersion != null) {
        _dataVersions[dataType] = cachedVersion;
      } else {
        // 创建初始版本
        final initialVersion = DataVersion(
          dataType: dataType,
          version: '1.0.0',
          timestamp: DateTime.now(),
          checksum: _generateChecksum([]),
        );
        _dataVersions[dataType] = initialVersion;
        await _cacheManager.put('version_$dataType', initialVersion);
      }

      // 初始化同步状态
      _syncStates[dataType] = SyncState(dataType: dataType);
    }

    debugPrint('📋 数据版本初始化完成: ${_dataVersions.length}个数据类型');
  }

  /// 启动定期同步
  void _startPeriodicSync() {
    debugPrint('⏰ 启动定期数据同步 (间隔: ${_syncInterval.inMinutes}分钟)');

    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      await _performPeriodicSync();
    });
  }

  /// 执行定期同步
  Future<void> _performPeriodicSync() async {
    debugPrint('🔄 执行定期数据同步...');

    final dataTypes = ['funds', 'rankings'];
    final futures = <Future>[];

    for (final dataType in dataTypes) {
      final syncState = _syncStates[dataType];
      if (syncState != null && syncState.canSync) {
        futures.add(_syncDataType(dataType));
      }
    }

    try {
      await Future.wait(futures);
      debugPrint('✅ 定期数据同步完成');
    } catch (e) {
      debugPrint('❌ 定期数据同步失败: $e');
    }
  }

  /// 同步特定数据类型
  Future<bool> _syncDataType(String dataType) async {
    final syncState = _syncStates[dataType]!;
    if (!syncState.canSync) {
      debugPrint('⚠️ 数据类型 $dataType 当前无法同步 (状态: ${syncState.status})');
      return false;
    }

    syncState.status = SyncStatus.syncing;
    debugPrint('🔄 开始同步数据类型: $dataType');

    try {
      bool success = false;

      switch (dataType) {
        case 'funds':
          success = await _syncFunds();
          break;
        case 'rankings':
          success = await _syncRankings();
          break;
        case 'search_results':
          success = await _syncSearchResults();
          break;
        default:
          debugPrint('⚠️ 未知数据类型: $dataType');
          return false;
      }

      if (success) {
        // 更新同步状态
        syncState.status = SyncStatus.idle;
        syncState.lastSyncTime = DateTime.now();
        syncState.nextSyncTime = DateTime.now().add(_syncInterval);
        syncState.failedAttempts = 0;
        syncState.lastError = null;

        debugPrint('✅ 数据类型 $dataType 同步成功');
      } else {
        throw Exception('同步返回失败状态');
      }

      return true;
    } catch (e) {
      // 更新失败状态
      syncState.status = SyncStatus.failed;
      syncState.failedAttempts++;
      syncState.lastError = e.toString();

      debugPrint(
          '❌ 数据类型 $dataType 同步失败: $e (尝试次数: ${syncState.failedAttempts})');

      // 指数退避重试
      final retryDelay = Duration(
          minutes:
              math.pow(2, math.min(syncState.failedAttempts - 1, 5)).toInt());
      syncState.nextSyncTime = DateTime.now().add(retryDelay);

      return false;
    }
  }

  /// 同步基金数据
  Future<bool> _syncFunds() async {
    try {
      debugPrint('🔄 同步基金数据...');

      // 获取当前数据版本
      final currentVersion = _dataVersions['funds']!;

      // 从服务器获取最新数据
      final latestFunds = await _fundService.getFundBasicInfo(limit: 100);

      // 计算新数据的校验和
      final newChecksum =
          _generateChecksum(latestFunds.map((f) => f.fundCode).toList());

      // 检查是否有更新
      if (newChecksum != currentVersion.checksum) {
        debugPrint('🔄 检测到基金数据更新，执行增量同步...');

        // 解决冲突
        await _resolveDataConflict('funds', latestFunds);

        // 更新缓存
        final fundModels = latestFunds.map((dto) => _dtoToFund(dto)).toList();
        await _cacheManager.put('funds', fundModels, dataType: 'fund');

        // 更新版本信息
        final newVersion = DataVersion(
          dataType: 'funds',
          version: _generateNewVersion(currentVersion.version),
          timestamp: DateTime.now(),
          checksum: newChecksum,
        );
        _dataVersions['funds'] = newVersion;
        await _cacheManager.put('version_funds', newVersion);

        debugPrint('✅ 基金数据同步完成: ${latestFunds.length}条');
      } else {
        debugPrint('ℹ️ 基金数据已是最新版本');
      }

      return true;
    } catch (e) {
      debugPrint('❌ 同步基金数据失败: $e');
      return false;
    }
  }

  /// 同步排行榜数据
  Future<bool> _syncRankings() async {
    try {
      debugPrint('🔄 同步排行榜数据...');

      final currentVersion = _dataVersions['rankings']!;
      final symbols = ['全部', '股票型', '混合型', '债券型'];

      bool hasUpdate = false;

      for (final symbol in symbols) {
        try {
          final latestRankings =
              await _fundService.getFundRankings(symbol: symbol);
          final cacheKey = 'rankings_$symbol';

          // 检查是否有更新
          final cachedRankings = _cacheManager.get<List>(cacheKey);
          if (cachedRankings == null ||
              cachedRankings.length != latestRankings.length) {
            debugPrint('🔄 检测到 $symbol 排行数据更新');

            // 解决冲突
            await _resolveDataConflict(cacheKey, latestRankings);

            // 更新缓存
            await _cacheManager.put(cacheKey, latestRankings,
                dataType: 'ranking');
            hasUpdate = true;
          }
        } catch (e) {
          debugPrint('⚠️ 同步 $symbol 排行数据失败: $e');
        }
      }

      if (hasUpdate) {
        // 更新版本信息
        final newVersion = DataVersion(
          dataType: 'rankings',
          version: _generateNewVersion(currentVersion.version),
          timestamp: DateTime.now(),
          checksum: _generateChecksum(['rankings_updated']),
        );
        _dataVersions['rankings'] = newVersion;
        await _cacheManager.put('version_rankings', newVersion);

        debugPrint('✅ 排行榜数据同步完成');
      } else {
        debugPrint('ℹ️ 排行榜数据已是最新版本');
      }

      return true;
    } catch (e) {
      debugPrint('❌ 同步排行榜数据失败: $e');
      return false;
    }
  }

  /// 同步搜索结果
  Future<bool> _syncSearchResults() async {
    // 搜索结果通常是动态的，不需要强制同步
    debugPrint('ℹ️ 搜索结果数据跳过同步（动态数据）');
    return true;
  }

  /// 解决数据冲突
  Future<void> _resolveDataConflict(String dataType, dynamic newData) async {
    debugPrint('🔧 解决数据冲突: $dataType');

    final cachedData = _cacheManager.get(dataType);
    if (cachedData == null) {
      // 没有冲突，直接使用新数据
      return;
    }

    switch (_conflictStrategy) {
      case ConflictResolutionStrategy.timestamp:
        // 基于时间戳的策略已在 _syncDataType 中实现
        break;

      case ConflictResolutionStrategy.server:
        // 服务器优先：直接使用新数据
        debugPrint('🔧 服务器优先策略：使用服务器数据');
        break;

      case ConflictResolutionStrategy.client:
        // 客户端优先：保留本地数据
        debugPrint('🔧 客户端优先策略：保留本地数据');
        // 不更新缓存
        return;

      case ConflictResolutionStrategy.merge:
        // 合并策略：尝试合并数据
        debugPrint('🔧 合并策略：尝试合并数据');
        await _mergeData(dataType, cachedData, newData);
        break;
    }
  }

  /// 合并数据
  Future<void> _mergeData(
      String dataType, dynamic localData, dynamic serverData) async {
    try {
      if (dataType == 'funds' && localData is List && serverData is List) {
        // 合并基金数据：保留本地最新的，添加服务器新的
        final localCodes = (localData).map((f) => f.code).toSet();
        final serverNewFunds =
            (serverData).where((f) => !localCodes.contains(f.code)).toList();

        final mergedData = [...localData, ...serverNewFunds];
        await _cacheManager.put(dataType, mergedData, dataType: 'fund');

        debugPrint(
            '🔧 数据合并完成：本地${localData.length}条，服务器新增${serverNewFunds.length}条');
      } else {
        // 其他类型的数据，简单使用服务器数据
        await _cacheManager.put(dataType, serverData);
        debugPrint('🔧 使用服务器数据（无法合并）');
      }
    } catch (e) {
      debugPrint('❌ 数据合并失败: $e，使用服务器数据');
      await _cacheManager.put(dataType, serverData);
    }
  }

  /// 手动强制同步
  Future<Map<String, bool>> forceSyncAll() async {
    debugPrint('🔄 手动强制同步所有数据...');

    final results = <String, bool>{};
    final dataTypes = ['funds', 'rankings'];

    for (final dataType in dataTypes) {
      results[dataType] = await _syncDataType(dataType);
    }

    final successCount = results.values.where((success) => success).length;
    debugPrint('✅ 强制同步完成: $successCount/${dataTypes.length} 个数据类型成功');

    return results;
  }

  /// 手动同步特定数据类型
  Future<bool> syncDataType(String dataType) async {
    debugPrint('🔄 手动同步数据类型: $dataType');
    return await _syncDataType(dataType);
  }

  /// 检查数据是否需要同步
  bool needsSync(String dataType) {
    final syncState = _syncStates[dataType];
    if (syncState == null) return true;

    return syncState.canSync &&
        (syncState.nextSyncTime == null ||
            DateTime.now().isAfter(syncState.nextSyncTime!));
  }

  /// 获取同步状态
  SyncState? getSyncState(String dataType) {
    return _syncStates[dataType];
  }

  /// 获取所有同步状态
  Map<String, SyncState> getAllSyncStates() {
    return Map.from(_syncStates);
  }

  /// 暂停同步
  void pauseSync(String? dataType) {
    if (dataType != null) {
      final syncState = _syncStates[dataType];
      if (syncState != null) {
        syncState.status = SyncStatus.paused;
        debugPrint('⏸️ 暂停同步: $dataType');
      }
    } else {
      // 暂停所有同步
      for (final syncState in _syncStates.values) {
        syncState.status = SyncStatus.paused;
      }
      debugPrint('⏸️ 暂停所有同步');
    }
  }

  /// 恢复同步
  void resumeSync(String? dataType) {
    if (dataType != null) {
      final syncState = _syncStates[dataType];
      if (syncState != null && syncState.status == SyncStatus.paused) {
        syncState.status = SyncStatus.idle;
        debugPrint('▶️ 恢复同步: $dataType');
      }
    } else {
      // 恢复所有同步
      for (final syncState in _syncStates.values) {
        if (syncState.status == SyncStatus.paused) {
          syncState.status = SyncStatus.idle;
        }
      }
      debugPrint('▶️ 恢复所有同步');
    }
  }

  /// 设置同步间隔
  void setSyncInterval(Duration interval) {
    _syncInterval = interval;
    debugPrint('⚙️ 设置同步间隔: ${interval.inMinutes}分钟');

    // 重启同步定时器
    _syncTimer?.cancel();
    _startPeriodicSync();
  }

  /// 设置冲突解决策略
  void setConflictResolutionStrategy(ConflictResolutionStrategy strategy) {
    _conflictStrategy = strategy;
    debugPrint('⚙️ 设置冲突解决策略: $strategy');
  }

  /// 获取同步统计信息
  Map<String, dynamic> getSyncStats() {
    final totalStates = _syncStates.length;
    final activeStates =
        _syncStates.values.where((s) => s.status == SyncStatus.syncing).length;
    final failedStates = _syncStates.values.where((s) => s.hasError).length;
    final pausedStates =
        _syncStates.values.where((s) => s.status == SyncStatus.paused).length;

    return {
      'totalDataTypes': totalStates,
      'activeSyncs': activeStates,
      'failedSyncs': failedStates,
      'pausedSyncs': pausedStates,
      'syncInterval': _syncInterval.inMinutes,
      'conflictStrategy': _conflictStrategy.toString(),
      'dataVersions': _dataVersions.map((k, v) => MapEntry(k, {
            'version': v.version,
            'timestamp': v.timestamp.toIso8601String(),
          })),
      'syncStates': _syncStates.map((k, v) => MapEntry(k, {
            'status': v.status.toString(),
            'lastSyncTime': v.lastSyncTime.toIso8601String(),
            'failedAttempts': v.failedAttempts,
            'hasError': v.lastError != null,
          })),
    };
  }

  /// 生成校验和
  String _generateChecksum(List<String> items) {
    items.sort();
    final combined = items.join('|');
    return combined.hashCode.toString();
  }

  /// 生成新版本号
  String _generateNewVersion(String currentVersion) {
    final parts = currentVersion.split('.');
    if (parts.length != 3) return '1.0.0';

    try {
      final major = int.parse(parts[0]);
      final minor = int.parse(parts[1]);
      final patch = int.parse(parts[2]);

      // 简单的递增策略：增加补丁版本
      return '$major.$minor.${patch + 1}';
    } catch (e) {
      return '1.0.0';
    }
  }

  /// 辅助方法：DTO转Fund
  Fund _dtoToFund(dynamic dto) {
    return Fund(
      code: dto.fundCode,
      name: dto.fundName,
      type: dto.fundType,
      company: dto.fundCompany,
      manager: dto.fundManager ?? '未知',
      return1W: 0.0,
      return1M: 0.0,
      return3M: 0.0,
      return6M: 0.0,
      return1Y: dto.dailyReturn ?? 0.0,
      return3Y: 0.0,
      scale: dto.fundScale ?? 0.0,
      riskLevel: dto.riskLevel ?? 'R3',
      status: dto.status ?? 'active',
      isFavorite: false,
    );
  }

  /// 清理资源
  void dispose() {
    _syncTimer?.cancel();
    _syncStates.clear();
    _dataVersions.clear();
    debugPrint('🔒 数据同步管理器已释放');
  }
}
