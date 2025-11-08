import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../interfaces/i_data_consistency_manager.dart';
import '../interfaces/i_data_router.dart' as router;

/// 数据一致性管理器实现
///
/// 负责维护多数据源之间的数据一致性，处理冲突检测和解决
/// 支持版本控制、增量同步和数据完整性验证
class DataConsistencyManager implements IDataConsistencyManager {
  // ========================================================================
  // 核心依赖和状态
  // ========================================================================

  final List<DataSource> _dataSources;
  final router.IDataRouter _dataRouter;

  // 版本控制存储
  final Map<String, List<DataVersion>> _versionHistory = {};
  final Map<String, DataVersion> _currentVersions = {};

  // 冲突管理
  final Map<String, DataConflict> _activeConflicts = {};
  final List<ConflictResolutionResult> _resolutionHistory = [];

  // 同步状态
  final Map<String, SyncStatus> _syncStatus = {};
  final Map<String, DateTime> _lastSyncTimes = {};

  // 一致性规则
  List<ConsistencyRule> _consistencyRules = [];

  // 离线缓存管理
  final Map<String, OfflineDataChange> _offlineChanges = {};
  final Map<String, List<OfflineDataChange>> _changesByDataKey = {};
  final Map<String, List<OfflineDataChange>> _changesByDataType = {};
  final Map<String, List<OfflineDataChange>> _changesByDataSource = {};

  // 离线同步状态
  bool _isOfflineSyncing = false;
  double _offlineSyncProgress = 0.0;
  String? _currentOfflineChangeId;
  DateTime? _offlineSyncStartTime;
  bool _autoOfflineSyncEnabled = true;
  DateTime? _nextAutoOfflineSyncTime;

  // 监控和指标
  final Map<String, List<ConsistencyTrendPoint>> _consistencyTrends = {};
  final Map<String, ConsistencyMetrics> _metricsCache = {};
  final Map<String, DateTime> _metricsCacheTimestamps = {};

  // 配置和状态
  final ConsistencyManagerConfig _config;
  bool _isInitialized = false;
  Timer? _consistencyCheckTimer;
  Timer? _metricsUpdateTimer;
  Timer? _syncTimer;

  // 事件流
  final StreamController<DataConflict> _conflictDetectedController =
      StreamController.broadcast();
  final StreamController<SyncCompletedEvent> _syncCompletedController =
      StreamController.broadcast();

  // 解决历史记录（公开属性）
  List<ConflictResolutionResult> get resolutionHistory =>
      List.unmodifiable(_resolutionHistory);

  // ========================================================================
  // 构造函数和初始化
  // ========================================================================

  DataConsistencyManager({
    required List<DataSource> dataSources,
    required router.IDataRouter dataRouter,
    ConsistencyManagerConfig? config,
  })  : _dataSources = dataSources,
        _dataRouter = dataRouter,
        _config = config ?? ConsistencyManagerConfig.defaultConfig();

  /// 初始化一致性管理器
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('🔄 初始化数据一致性管理器...', name: 'DataConsistencyManager');

      // 1. 初始化版本控制
      await _initializeVersionControl();

      // 2. 加载一致性规则
      await _loadConsistencyRules();

      // 3. 初始化同步状态
      await _initializeSyncStatus();

      // 4. 启动定期检查
      _startPeriodicChecks();

      // 5. 执行初始一致性验证
      await _performInitialConsistencyCheck();

      _isInitialized = true;
      developer.log('✅ 数据一致性管理器初始化完成', name: 'DataConsistencyManager');
    } catch (e) {
      developer.log('❌ 数据一致性管理器初始化失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  /// 初始化版本控制
  Future<void> _initializeVersionControl() async {
    for (final source in _dataSources) {
      // 初始化每个数据源的版本历史
      _versionHistory[source.id] = [];
      _syncStatus[source.id] = const SyncStatus(
        state: SyncState.stopped,
        pendingChangesCount: 0,
        progress: 0.0,
      );
    }
  }

  /// 加载一致性规则
  Future<void> _loadConsistencyRules() async {
    // 默认一致性规则
    _consistencyRules = [
      const ConsistencyRule(
        ruleId: 'timestamp_validation',
        name: '时间戳验证',
        description: '验证数据时间戳的一致性',
        type: RuleType.validation,
        condition: RuleCondition(
          expression: 'timestamp_diff < max_allowed_diff',
          parameters: {'max_allowed_diff': 300}, // 5分钟
        ),
        action: RuleAction(
          type: ActionType.refreshCache,
          parameters: {'force': true},
        ),
        priority: 1,
        isEnabled: true,
      ),
      const ConsistencyRule(
        ruleId: 'value_consistency',
        name: '数值一致性',
        description: '确保关键数值字段的一致性',
        type: RuleType.validation,
        condition: RuleCondition(
          expression: 'value_matches_across_sources',
          parameters: {
            'critical_fields': ['price', 'nav', 'return']
          },
        ),
        action: RuleAction(
          type: ActionType.resync,
          parameters: {'scope': 'critical_fields'},
        ),
        priority: 2,
        isEnabled: true,
      ),
    ];
  }

  /// 初始化同步状态
  Future<void> _initializeSyncStatus() async {
    for (final source in _dataSources) {
      _lastSyncTimes[source.id] =
          DateTime.now().subtract(const Duration(hours: 1));
    }
  }

  /// 启动定期检查
  void _startPeriodicChecks() {
    // 一致性检查定时器
    _consistencyCheckTimer = Timer.periodic(
      _config.consistencyCheckInterval,
      (_) => _performScheduledConsistencyCheck(),
    );

    // 指标更新定时器
    _metricsUpdateTimer = Timer.periodic(
      _config.metricsUpdateInterval,
      (_) => _updateMetrics(),
    );

    // 同步定时器
    _syncTimer = Timer.periodic(
      _config.syncInterval,
      (_) => _performScheduledSync(),
    );
  }

  /// 执行初始一致性检查
  Future<void> _performInitialConsistencyCheck() async {
    try {
      developer.log('🔍 执行初始一致性检查', name: 'DataConsistencyManager');

      final result = await validateDataConsistency(
        validationScope: ValidationScope.selective,
      );

      if (!result.isValid) {
        developer.log('⚠️ 初始检查发现 ${result.inconsistentItemsCount} 个不一致项',
            name: 'DataConsistencyManager');
      }
    } catch (e) {
      developer.log('❌ 初始一致性检查失败: $e',
          name: 'DataConsistencyManager', level: 1000);
    }
  }

  // ========================================================================
  // 一致性验证接口实现
  // ========================================================================

  @override
  Future<ConsistencyValidationResult> validateDataConsistency({
    ValidationScope validationScope = ValidationScope.full,
    List<String>? dataSourceIds,
  }) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();
    final validationTime = DateTime.now();

    try {
      developer.log('🔍 开始数据一致性验证 [范围: $validationScope]',
          name: 'DataConsistencyManager');

      final targetSources = dataSourceIds != null
          ? _dataSources.where((s) => dataSourceIds.contains(s.id)).toList()
          : _dataSources;

      if (targetSources.length < 2) {
        return ConsistencyValidationResult(
          isValid: true,
          totalItemsChecked: 0,
          consistentItemsCount: 0,
          inconsistentItemsCount: 0,
          inconsistencies: [],
          validationDuration: stopwatch.elapsed,
          validationTime: validationTime,
        );
      }

      final inconsistencies = <InconsistencyDetail>[];
      int totalItemsChecked = 0;
      int consistentItemsCount = 0;

      // 根据验证范围执行不同的验证策略
      switch (validationScope) {
        case ValidationScope.full:
          await _performFullValidation(targetSources, inconsistencies,
              totalItemsChecked, consistentItemsCount);
          break;
        case ValidationScope.incremental:
          await _performIncrementalValidation(targetSources, inconsistencies,
              totalItemsChecked, consistentItemsCount);
          break;
        case ValidationScope.selective:
          await _performSelectiveValidation(targetSources, inconsistencies,
              totalItemsChecked, consistentItemsCount);
          break;
      }

      stopwatch.stop();

      final result = ConsistencyValidationResult(
        isValid: inconsistencies.isEmpty,
        totalItemsChecked: totalItemsChecked,
        consistentItemsCount: consistentItemsCount,
        inconsistentItemsCount: inconsistencies.length,
        inconsistencies: inconsistencies,
        validationDuration: stopwatch.elapsed,
        validationTime: validationTime,
      );

      // 更新一致性趋势
      _updateConsistencyTrend(result);

      developer.log(
          '✅ 一致性验证完成: ${result.consistencyRate.toStringAsFixed(2)}% 一致',
          name: 'DataConsistencyManager');

      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 一致性验证失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<IncrementalConsistencyResult> performIncrementalConsistencyCheck({
    DateTime? lastCheckTime,
    List<ChangeType>? changeTypes,
  }) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();
    final effectiveCheckTime = lastCheckTime ??
        DateTime.now().subtract(_config.incrementalCheckWindow);

    try {
      developer.log('🔄 执行增量一致性检查 [起始时间: $effectiveCheckTime]',
          name: 'DataConsistencyManager');

      final newChanges = <DataChange>[];
      final detectedConflicts = <DataConflict>[];

      // 1. 检查各数据源的增量变更
      for (final source in _dataSources) {
        final changes = await _getIncrementalChanges(
            source, effectiveCheckTime, changeTypes);
        newChanges.addAll(changes);
      }

      // 2. 检测变更中的冲突
      if (newChanges.isNotEmpty) {
        detectedConflicts.addAll(await _detectConflictsFromChanges(newChanges));
      }

      // 3. 发布冲突事件
      for (final conflict in detectedConflicts) {
        _activeConflicts[conflict.conflictId] = conflict;
        _conflictDetectedController.add(conflict);
      }

      stopwatch.stop();

      return IncrementalConsistencyResult(
        success: true,
        newChanges: newChanges,
        detectedConflicts: detectedConflicts,
        dataSourceCount: _dataSources.length,
        checkDuration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 增量一致性检查失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<ItemConsistencyResult> validateItemConsistency(
    String itemType,
    String itemId,
  ) async {
    _ensureInitialized();

    try {
      developer.log('🔍 验证数据项一致性: $itemType:$itemId',
          name: 'DataConsistencyManager');

      final itemReference = ItemReference(itemType: itemType, itemId: itemId);
      final dataSourceStatus = <String, DataStatus>{};
      final differences = <DataDifference>[];

      // 获取各数据源中的数据状态
      for (final source in _dataSources) {
        final status = await _getItemDataStatus(source, itemType, itemId);
        dataSourceStatus[source.id] = status;
      }

      // 比较数据差异
      final statusList = dataSourceStatus.values.toList();
      if (statusList.length > 1) {
        for (int i = 0; i < statusList.length - 1; i++) {
          for (int j = i + 1; j < statusList.length; j++) {
            differences
                .addAll(_compareDataStatus(statusList[i], statusList[j]));
          }
        }
      }

      final isConsistent = differences.isEmpty;

      return ItemConsistencyResult(
        itemReference: itemReference,
        isConsistent: isConsistent,
        dataSourceStatus: dataSourceStatus,
        differences: differences,
      );
    } catch (e) {
      developer.log('❌ 数据项一致性验证失败: $itemType:$itemId - $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<List<ItemConsistencyResult>> validateItemsConsistencyBatch(
    List<ItemReference> items,
  ) async {
    _ensureInitialized();

    final results = <ItemConsistencyResult>[];

    try {
      developer.log('📦 批量验证数据项一致性: ${items.length} 项',
          name: 'DataConsistencyManager');

      // 并行验证以提高效率
      final futures = items
          .map((item) => validateItemConsistency(item.itemType, item.itemId))
          .toList();

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);

      developer.log('✅ 批量一致性验证完成', name: 'DataConsistencyManager');
    } catch (e) {
      developer.log('❌ 批量一致性验证失败: $e',
          name: 'DataConsistencyManager', level: 1000);
    }

    return results;
  }

  // ========================================================================
  // 冲突检测和解决接口实现
  // ========================================================================

  @override
  Future<List<DataConflict>> detectConflicts(
    List<DataSource> dataSources, {
    ConflictDetectionStrategy conflictDetectionStrategy =
        ConflictDetectionStrategy.timestampBased,
  }) async {
    _ensureInitialized();

    try {
      developer.log('🔍 检测数据冲突 [策略: $conflictDetectionStrategy]',
          name: 'DataConsistencyManager');

      final conflicts = <DataConflict>[];

      // 根据检测策略执行不同的冲突检测
      switch (conflictDetectionStrategy) {
        case ConflictDetectionStrategy.timestampBased:
          conflicts.addAll(await _detectTimestampBasedConflicts(dataSources));
          break;
        case ConflictDetectionStrategy.versionBased:
          conflicts.addAll(await _detectVersionBasedConflicts(dataSources));
          break;
        case ConflictDetectionStrategy.contentHashBased:
          conflicts.addAll(await _detectContentHashBasedConflicts(dataSources));
          break;
        case ConflictDetectionStrategy.businessRuleBased:
          conflicts
              .addAll(await _detectBusinessRuleBasedConflicts(dataSources));
          break;
      }

      developer.log('✅ 冲突检测完成: 发现 ${conflicts.length} 个冲突',
          name: 'DataConsistencyManager');

      return conflicts;
    } catch (e) {
      developer.log('❌ 冲突检测失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<ConflictResolutionResult> resolveConflict(
    DataConflict conflict, {
    ConflictResolutionStrategy resolutionStrategy =
        ConflictResolutionStrategy.auto,
  }) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();
    final resolutionTime = DateTime.now();

    try {
      developer.log(
          '🔧 解决数据冲突: ${conflict.conflictId} [策略: $resolutionStrategy]',
          name: 'DataConsistencyManager');

      final resolutionActions = <ResolutionAction>[];
      dynamic resolvedValue;

      // 根据解决策略执行冲突解决
      switch (resolutionStrategy) {
        case ConflictResolutionStrategy.auto:
          resolvedValue =
              await _autoResolveConflict(conflict, resolutionActions);
          break;
        case ConflictResolutionStrategy.latestWins:
          resolvedValue =
              await _resolveWithLatestWins(conflict, resolutionActions);
          break;
        case ConflictResolutionStrategy.earliestWins:
          resolvedValue =
              await _resolveWithEarliestWins(conflict, resolutionActions);
          break;
        case ConflictResolutionStrategy.merge:
          resolvedValue = await _mergeConflictData(conflict, resolutionActions);
          break;
        case ConflictResolutionStrategy.manual:
        case ConflictResolutionStrategy.userChoice:
          // 手动解决需要用户介入，这里返回待处理状态
          return ConflictResolutionResult(
            conflictId: conflict.conflictId,
            success: false,
            usedStrategy: resolutionStrategy,
            resolutionTime: resolutionTime,
            resolutionDuration: stopwatch.elapsed,
            resolutionActions: [],
          );
      }

      // 应用解决方案
      if (resolvedValue != null) {
        await _applyConflictResolution(
            conflict, resolvedValue, resolutionActions);
      }

      stopwatch.stop();

      final result = ConflictResolutionResult(
        conflictId: conflict.conflictId,
        success: true,
        usedStrategy: resolutionStrategy,
        resolvedValue: resolvedValue,
        resolutionTime: resolutionTime,
        resolutionDuration: stopwatch.elapsed,
        resolutionActions: [],
      );

      // 更新冲突状态
      _activeConflicts.remove(conflict.conflictId);
      _resolutionHistory.add(result);

      developer.log('✅ 冲突解决完成: ${conflict.conflictId}',
          name: 'DataConsistencyManager');

      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 冲突解决失败: ${conflict.conflictId} - $e',
          name: 'DataConsistencyManager', level: 1000);

      return ConflictResolutionResult(
        conflictId: conflict.conflictId,
        success: false,
        usedStrategy: resolutionStrategy,
        resolutionTime: resolutionTime,
        resolutionDuration: stopwatch.elapsed,
        resolutionActions: [],
      );
    }
  }

  @override
  Future<List<ConflictResolutionResult>> resolveConflictsBatch(
    List<DataConflict> conflicts, {
    ConflictResolutionStrategy resolutionStrategy =
        ConflictResolutionStrategy.auto,
  }) async {
    _ensureInitialized();

    final results = <ConflictResolutionResult>[];

    try {
      developer.log('📦 批量解决冲突: ${conflicts.length} 个冲突',
          name: 'DataConsistencyManager');

      // 并行解决冲突以提高效率
      final futures = conflicts
          .map((conflict) =>
              resolveConflict(conflict, resolutionStrategy: resolutionStrategy))
          .toList();

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);

      developer.log(
          '✅ 批量冲突解决完成: ${results.where((r) => r.success).length}/${results.length} 成功',
          name: 'DataConsistencyManager');
    } catch (e) {
      developer.log('❌ 批量冲突解决失败: $e',
          name: 'DataConsistencyManager', level: 1000);
    }

    return results;
  }

  @override
  Future<ConflictResolutionPreview> previewConflictResolution(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    _ensureInitialized();

    try {
      developer.log('🔮 预览冲突解决方案: ${conflict.conflictId} [策略: $strategy]',
          name: 'DataConsistencyManager');

      // 预测解决方案的结果
      final expectedOutcome =
          await _predictResolutionOutcome(conflict, strategy);

      // 分析影响
      final impactAnalysis = await _analyzeResolutionImpact(conflict, strategy);

      return ConflictResolutionPreview(
        conflict: conflict,
        strategy: strategy,
        expectedOutcome: expectedOutcome,
        impactAnalysis: impactAnalysis,
      );
    } catch (e) {
      developer.log('❌ 冲突解决预览失败: ${conflict.conflictId} - $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  // ========================================================================
  // 版本控制接口实现
  // ========================================================================

  @override
  Future<DataVersion> createVersion(
    List<DataItem> dataItems, {
    VersionMetadata? metadata,
  }) async {
    _ensureInitialized();

    try {
      developer.log('📝 创建数据版本: ${dataItems.length} 个数据项',
          name: 'DataConsistencyManager');

      final versionId = _generateVersionId();
      final createdAt = DateTime.now();
      const createdBy = 'DataConsistencyManager';

      final changeLog = <VersionChangeLog>[];

      // 为每个数据项创建版本
      for (final item in dataItems) {
        final versionNumber = _getNextVersionNumber(item.itemType, item.itemId);

        final version = DataVersion(
          versionId: versionId,
          itemType: item.itemType,
          itemId: item.itemId,
          versionNumber: versionNumber,
          versionData: item.data,
          createdAt: createdAt,
          createdBy: createdBy,
          metadata: metadata ??
              const VersionMetadata(
                tags: ['auto'],
                description: '自动创建的版本',
                versionType: VersionType.automatic,
                isMajor: false,
                customAttributes: {},
              ),
          parentVersionId:
              _currentVersions['${item.itemType}:${item.itemId}']?.versionId,
          changeLog: changeLog,
        );

        // 保存版本
        _saveVersion(version);

        // 更新当前版本
        _currentVersions['${item.itemType}:${item.itemId}'] = version;
      }

      // 返回第一个创建的版本作为代表
      return _currentVersions[
          '${dataItems.first.itemType}:${dataItems.first.itemId}']!;
    } catch (e) {
      developer.log('❌ 创建数据版本失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<List<DataVersion>> getVersionHistory(
    String itemType,
    String itemId, {
    int? limit,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    _ensureInitialized();

    try {
      final key = '$itemType:$itemId';
      final history = _versionHistory[key] ?? [];

      // 时间过滤
      var filteredVersions = history;
      if (startTime != null) {
        filteredVersions = filteredVersions
            .where((v) => v.createdAt.isAfter(startTime))
            .toList();
      }
      if (endTime != null) {
        filteredVersions = filteredVersions
            .where((v) => v.createdAt.isBefore(endTime))
            .toList();
      }

      // 排序（最新的在前）
      filteredVersions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 限制数量
      if (limit != null && filteredVersions.length > limit) {
        filteredVersions = filteredVersions.take(limit).toList();
      }

      return filteredVersions;
    } catch (e) {
      developer.log('❌ 获取版本历史失败: $itemType:$itemId - $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<VersionRollbackResult> rollbackToVersion(
    String itemType,
    String itemId,
    String versionId,
  ) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();
    final rollbackTime = DateTime.now();

    try {
      developer.log('🔄 回滚到版本: $itemType:$itemId -> $versionId',
          name: 'DataConsistencyManager');

      final key = '$itemType:$itemId';
      final history = _versionHistory[key] ?? [];
      final targetVersion = history.firstWhere((v) => v.versionId == versionId);

      if (targetVersion == null) {
        throw ArgumentError('版本不存在: $versionId');
      }

      final currentVersion = _currentVersions[key];
      final affectedItems = <ItemReference>[];

      // 执行回滚
      await _rollbackDataToVersion(targetVersion);

      affectedItems.add(ItemReference(itemType: itemType, itemId: itemId));

      stopwatch.stop();

      return VersionRollbackResult(
        success: true,
        originalVersionId: currentVersion?.versionId ?? 'unknown',
        targetVersionId: versionId,
        rollbackTime: rollbackTime,
        rollbackDuration: stopwatch.elapsed,
        affectedItems: affectedItems,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 版本回滚失败: $itemType:$itemId -> $versionId - $e',
          name: 'DataConsistencyManager', level: 1000);

      return VersionRollbackResult(
        success: false,
        originalVersionId: 'unknown',
        targetVersionId: versionId,
        rollbackTime: rollbackTime,
        rollbackDuration: stopwatch.elapsed,
        affectedItems: [],
        error: e.toString(),
      );
    }
  }

  @override
  Future<VersionComparisonResult> compareVersions(
    String itemType,
    String itemId,
    String versionId1,
    String versionId2,
  ) async {
    _ensureInitialized();

    try {
      developer.log('🔍 比较数据版本: $itemType:$itemId [$versionId1 vs $versionId2]',
          name: 'DataConsistencyManager');

      final key = '$itemType:$itemId';
      final history = _versionHistory[key] ?? [];

      final version1 = history.firstWhere((v) => v.versionId == versionId1);
      final version2 = history.firstWhere((v) => v.versionId == versionId2);

      if (version2 == null) {
        throw ArgumentError('版本不存在');
      }

      final differences = _compareVersionData(version1, version2);
      final similarityScore = _calculateSimilarityScore(version1, version2);

      return VersionComparisonResult(
        version1: version1,
        version2: version2,
        differences: differences,
        similarityScore: similarityScore,
        comparisonTime: DateTime.now(),
      );
    } catch (e) {
      developer.log('❌ 版本比较失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<VersionMergeResult> mergeVersions(
    String itemType,
    String itemId,
    List<String> versionIds, {
    MergeStrategy mergeStrategy = MergeStrategy.latestWins,
  }) async {
    _ensureInitialized();

    try {
      developer.log('🔀 合并数据版本: $itemType:$itemId [${versionIds.length} 个版本]',
          name: 'DataConsistencyManager');

      final key = '$itemType:$itemId';
      final history = _versionHistory[key] ?? [];

      final versionsToMerge = versionIds
          .map((id) => history.firstWhere((v) => v.versionId == id))
          .toList();

      if (versionsToMerge.length != versionIds.length) {
        throw ArgumentError('部分版本不存在');
      }

      final mergeConflicts = <MergeConflict>[];
      final mergedData = <String, dynamic>{};

      // 根据合并策略执行合并
      switch (mergeStrategy) {
        case MergeStrategy.latestWins:
          _mergeWithLatestWins(versionsToMerge, mergedData, mergeConflicts);
          break;
        case MergeStrategy.earliestWins:
          _mergeWithEarliestWins(versionsToMerge, mergedData, mergeConflicts);
          break;
        case MergeStrategy.mergeAll:
          _mergeAllChanges(versionsToMerge, mergedData, mergeConflicts);
          break;
        case MergeStrategy.keepConflicts:
          _mergeKeepConflicts(versionsToMerge, mergedData, mergeConflicts);
          break;
        default:
          throw ArgumentError('不支持的合并策略: $mergeStrategy');
      }

      // 创建合并版本
      final mergedVersion = DataVersion(
        versionId: _generateVersionId(),
        itemType: itemType,
        itemId: itemId,
        versionNumber: _getNextVersionNumber(itemType, itemId),
        versionData: mergedData,
        createdAt: DateTime.now(),
        createdBy: 'DataConsistencyManager',
        metadata: VersionMetadata(
          tags: ['merge'],
          description: '合并版本: ${versionIds.join(', ')}',
          versionType: VersionType.merge,
          isMajor: false,
          customAttributes: {'mergeStrategy': mergeStrategy.name},
        ),
        changeLog: [],
      );

      _saveVersion(mergedVersion);
      _currentVersions[key] = mergedVersion;

      return VersionMergeResult(
        success: true,
        mergedVersions: versionsToMerge,
        mergedVersion: mergedVersion,
        mergeConflicts: mergeConflicts,
        mergeStrategy: mergeStrategy,
        mergeTime: DateTime.now(),
      );
    } catch (e) {
      developer.log('❌ 版本合并失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  // ========================================================================
  // 增量同步接口实现
  // ========================================================================

  @override
  Future<IncrementalSyncResult> performIncrementalSync({
    SyncScope syncScope = SyncScope.all,
    SyncDirection syncDirection = SyncDirection.bidirectional,
    DateTime? lastSyncTime,
  }) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();
    final effectiveSyncTime = lastSyncTime ?? _getLastSyncTime();

    try {
      developer.log('🔄 执行增量同步 [范围: $syncScope] [方向: $syncDirection]',
          name: 'DataConsistencyManager');

      final changes = <DataChange>[];

      // 根据同步范围执行不同的同步策略
      switch (syncScope) {
        case SyncScope.all:
          changes.addAll(
              await _syncAllDataSources(effectiveSyncTime, syncDirection));
          break;
        case SyncScope.selective:
          changes.addAll(await _syncSelectiveDataSources(
              effectiveSyncTime, syncDirection));
          break;
        case SyncScope.incremental:
          changes.addAll(
              await _syncIncrementalData(effectiveSyncTime, syncDirection));
          break;
      }

      // 更新同步时间
      _updateLastSyncTime();

      stopwatch.stop();

      final result = IncrementalSyncResult(
        success: true,
        changes: changes,
        duration: stopwatch.elapsed,
      );

      // 发布同步完成事件
      _syncCompletedController.add(SyncCompletedEvent(syncResult: result));

      developer.log('✅ 增量同步完成: ${changes.length} 个变更',
          name: 'DataConsistencyManager');

      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 增量同步失败: $e',
          name: 'DataConsistencyManager', level: 1000);

      return IncrementalSyncResult(
        success: false,
        changes: [],
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SyncStatus> getSyncStatus({
    String? dataSourceId,
  }) async {
    _ensureInitialized();

    if (dataSourceId != null) {
      return _syncStatus[dataSourceId] ??
          const SyncStatus(
            state: SyncState.stopped,
            pendingChangesCount: 0,
            progress: 0.0,
          );
    }

    // 返回整体同步状态
    int totalPending = 0;
    double totalProgress = 0.0;
    SyncState overallState = SyncState.completed;

    for (final status in _syncStatus.values) {
      totalPending += status.pendingChangesCount;
      totalProgress += status.progress;

      if (status.state == SyncState.error) {
        overallState = SyncState.error;
      } else if (status.state == SyncState.running &&
          overallState != SyncState.error) {
        overallState = SyncState.running;
      }
    }

    totalProgress /= _syncStatus.length;

    return SyncStatus(
      state: overallState,
      lastSyncTime: _getLastGlobalSyncTime(),
      pendingChangesCount: totalPending,
      progress: totalProgress,
    );
  }

  @override
  Future<void> pauseSync({
    String? dataSourceId,
  }) async {
    _ensureInitialized();

    if (dataSourceId != null) {
      _syncStatus[dataSourceId] = _syncStatus[dataSourceId]?.copyWith(
            state: SyncState.paused,
          ) ??
          const SyncStatus(
              state: SyncState.paused, pendingChangesCount: 0, progress: 0.0);
    } else {
      for (final sourceId in _syncStatus.keys) {
        _syncStatus[sourceId] = _syncStatus[sourceId]!.copyWith(
          state: SyncState.paused,
        );
      }
    }

    developer.log(
        '⏸️ 同步已暂停 ${dataSourceId != null ? '(数据源: $dataSourceId)' : '(所有数据源)'}',
        name: 'DataConsistencyManager');
  }

  @override
  Future<void> resumeSync({
    String? dataSourceId,
  }) async {
    _ensureInitialized();

    if (dataSourceId != null) {
      _syncStatus[dataSourceId] = _syncStatus[dataSourceId]?.copyWith(
            state: SyncState.running,
          ) ??
          const SyncStatus(
              state: SyncState.running, pendingChangesCount: 0, progress: 0.0);
    } else {
      for (final sourceId in _syncStatus.keys) {
        _syncStatus[sourceId] = _syncStatus[sourceId]!.copyWith(
          state: SyncState.running,
        );
      }
    }

    developer.log(
        '▶️ 同步已恢复 ${dataSourceId != null ? '(数据源: $dataSourceId)' : '(所有数据源)'}',
        name: 'DataConsistencyManager');
  }

  @override
  Future<ForceSyncResult> forceSync({
    List<String>? dataSourceIds,
    SyncScope syncScope = SyncScope.all,
  }) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();
    final syncTime = DateTime.now();

    try {
      developer.log('🔄 强制同步 [数据源: ${dataSourceIds?.join(',') ?? '全部'}]',
          name: 'DataConsistencyManager');

      final targetSources = dataSourceIds != null
          ? _dataSources.where((s) => dataSourceIds.contains(s.id)).toList()
          : _dataSources;

      int syncedItemsCount = 0;

      // 执行强制同步
      for (final source in targetSources) {
        final itemsCount = await _forceSyncDataSource(source);
        syncedItemsCount += itemsCount;
      }

      stopwatch.stop();

      return ForceSyncResult(
        success: true,
        syncedDataSourcesCount: targetSources.length,
        syncedItemsCount: syncedItemsCount,
        syncDuration: stopwatch.elapsed,
        syncTime: syncTime,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 强制同步失败: $e',
          name: 'DataConsistencyManager', level: 1000);

      return ForceSyncResult(
        success: false,
        syncedDataSourcesCount: 0,
        syncedItemsCount: 0,
        syncDuration: stopwatch.elapsed,
        syncTime: syncTime,
        error: e.toString(),
      );
    }
  }

  // ========================================================================
  // 数据完整性验证接口实现
  // ========================================================================

  @override
  Future<IntegrityValidationResult> validateDataIntegrity({
    IntegrityCheckType integrityCheckType = IntegrityCheckType.comprehensive,
    DataScope? dataScope,
  }) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 验证数据完整性 [类型: $integrityCheckType]',
          name: 'DataConsistencyManager');

      final issues = <IntegrityIssue>[];
      int totalItemsChecked = 0;
      int intactItemsCount = 0;

      // 根据检查类型执行不同的验证
      switch (integrityCheckType) {
        case IntegrityCheckType.comprehensive:
          await _performComprehensiveIntegrityCheck(
              dataScope, issues, totalItemsChecked, intactItemsCount);
          break;
        case IntegrityCheckType.quick:
          await _performQuickIntegrityCheck(
              dataScope, issues, totalItemsChecked, intactItemsCount);
          break;
        case IntegrityCheckType.deep:
          await _performDeepIntegrityCheck(
              dataScope, issues, totalItemsChecked, intactItemsCount);
          break;
        case IntegrityCheckType.selective:
          await _performSelectiveIntegrityCheck(
              dataScope, issues, totalItemsChecked, intactItemsCount);
          break;
      }

      stopwatch.stop();

      return IntegrityValidationResult(
        isValid: issues.isEmpty,
        totalItemsChecked: totalItemsChecked,
        intactItemsCount: intactItemsCount,
        corruptedItemsCount: issues.length,
        issues: issues,
        validationDuration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 数据完整性验证失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<IntegrityRepairResult> repairIntegrityIssues(
    List<IntegrityIssue> issues,
  ) async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();
    final repairResults = <IssueRepairResult>[];

    try {
      developer.log('🔧 修复数据完整性问题: ${issues.length} 个问题',
          name: 'DataConsistencyManager');

      int repairedCount = 0;
      int failedCount = 0;

      for (final issue in issues) {
        try {
          final repairMethod = _determineRepairMethod(issue);
          final success = await _repairIntegrityIssue(issue, repairMethod);

          repairResults.add(IssueRepairResult(
            issueId: issue.issueId,
            success: success,
            repairMethod: repairMethod,
            repairTime: DateTime.now(),
          ));

          if (success) {
            repairedCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          repairResults.add(IssueRepairResult(
            issueId: issue.issueId,
            success: false,
            repairMethod: RepairMethod.dataRecovery,
            repairTime: DateTime.now(),
            error: e.toString(),
          ));
        }
      }

      stopwatch.stop();

      return IntegrityRepairResult(
        success: failedCount == 0,
        repairedIssuesCount: repairedCount,
        failedRepairsCount: failedCount,
        repairDuration: stopwatch.elapsed,
        repairResults: repairResults,
      );
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 修复完整性问题失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<IntegrityReport> getIntegrityReport({
    ReportScope scope = ReportScope.full,
  }) async {
    _ensureInitialized();

    try {
      developer.log('📊 生成完整性报告 [范围: $scope]', name: 'DataConsistencyManager');

      final reportId = _generateReportId();
      final generatedAt = DateTime.now();

      // 收集完整性统计
      final sourceStats = <String, SourceIntegrityStats>{};
      double totalIntegrityScore = 0.0;
      int totalItems = 0;
      int totalIntactItems = 0;

      for (final source in _dataSources) {
        final stats = await _calculateSourceIntegrityStats(source);
        sourceStats[source.id] = stats;

        totalIntegrityScore += stats.integrityRate;
        totalItems += stats.totalItems;
        totalIntactItems += stats.intactItems;
      }

      final overallIntegrityScore = sourceStats.isNotEmpty
          ? totalIntegrityScore / sourceStats.length
          : 1.0;

      // 生成趋势数据
      final trendPoints = await _generateIntegrityTrendPoints();

      // 生成改进建议
      final recommendations =
          await _generateIntegrityRecommendations(sourceStats);

      return IntegrityReport(
        reportId: reportId,
        scope: scope,
        generatedAt: generatedAt,
        overallIntegrityScore: overallIntegrityScore,
        sourceStats: sourceStats,
        trendPoints: trendPoints,
        recommendations: recommendations,
      );
    } catch (e) {
      developer.log('❌ 生成完整性报告失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  // ========================================================================
  // 监控和报告接口实现
  // ========================================================================

  @override
  Future<ConsistencyMetrics> getConsistencyMetrics({
    MetricsPeriod period = MetricsPeriod.last24Hours,
  }) async {
    _ensureInitialized();

    final cacheKey = period.name;

    // 检查缓存
    if (_metricsCache.containsKey(cacheKey)) {
      final cached = _metricsCache[cacheKey]!;
      final cachedTime = _metricsCacheTimestamps[cacheKey]!;
      final now = DateTime.now();
      if (now.difference(cachedTime) < const Duration(hours: 1)) {
        return cached;
      }
    }

    try {
      developer.log('📊 获取一致性指标 [周期: $period]', name: 'DataConsistencyManager');

      final now = DateTime.now();
      final startTime = _getPeriodStartTime(now, period);

      // 计算指标
      double overallConsistencyRate = 0.0;
      final sourceConsistencyRates = <String, double>{};
      final typeConsistencyRates = <String, double>{};
      int conflictDetectionCount = 0;
      int conflictResolutionCount = 0;
      Duration totalResolutionTime = Duration.zero;

      // 从趋势数据计算指标
      final trendPoints = _getTrendPointsForPeriod(period);
      if (trendPoints.isNotEmpty) {
        overallConsistencyRate =
            trendPoints.map((p) => p.consistencyRate).reduce((a, b) => a + b) /
                trendPoints.length;

        for (final source in _dataSources) {
          sourceConsistencyRates[source.id] =
              _calculateSourceConsistencyRate(source.id, period);
        }

        conflictDetectionCount = _resolutionHistory.length;
        conflictResolutionCount =
            _resolutionHistory.where((r) => r.success).length;

        if (_resolutionHistory.isNotEmpty) {
          totalResolutionTime = _resolutionHistory
              .map((r) => r.resolutionDuration)
              .reduce((a, b) => a + b);
        }
      }

      final averageResolutionTime = conflictResolutionCount > 0
          ? Duration(
              milliseconds:
                  totalResolutionTime.inMilliseconds ~/ conflictResolutionCount)
          : Duration.zero;

      final metrics = ConsistencyMetrics(
        period: period,
        overallConsistencyRate: overallConsistencyRate,
        sourceConsistencyRates: sourceConsistencyRates,
        typeConsistencyRates: typeConsistencyRates,
        conflictDetectionCount: conflictDetectionCount,
        conflictResolutionCount: conflictResolutionCount,
        averageResolutionTime: averageResolutionTime,
      );

      // 缓存结果，添加时间戳
      final metricsWithTimestamp = ConsistencyMetrics(
        period: metrics.period,
        overallConsistencyRate: metrics.overallConsistencyRate,
        sourceConsistencyRates: metrics.sourceConsistencyRates,
        typeConsistencyRates: metrics.typeConsistencyRates,
        conflictDetectionCount: metrics.conflictDetectionCount,
        conflictResolutionCount: metrics.conflictResolutionCount,
        averageResolutionTime: metrics.averageResolutionTime,
      );
      _metricsCache[cacheKey] = metricsWithTimestamp;
      _metricsCacheTimestamps[cacheKey] = DateTime.now();

      return metrics;
    } catch (e) {
      developer.log('❌ 获取一致性指标失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<ConsistencyReport> generateConsistencyReport({
    ReportType reportType = ReportType.summary,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    _ensureInitialized();

    try {
      developer.log('📊 生成一致性报告 [类型: $reportType]',
          name: 'DataConsistencyManager');

      final reportId = _generateReportId();
      final now = DateTime.now();
      final timeRange = TimeRange(
        startTime: startTime ?? now.subtract(const Duration(days: 1)),
        endTime: endTime ?? now,
      );

      // 生成报告数据
      final summary = await _generateConsistencySummary(timeRange);
      final metrics = await getConsistencyMetrics();
      final conflictAnalysis = await _generateConflictAnalysis(timeRange);
      final trendAnalysis = await _generateTrendAnalysis(timeRange);

      return ConsistencyReport(
        reportId: reportId,
        reportType: reportType,
        timeRange: timeRange,
        generatedAt: now,
        summary: summary,
        metrics: metrics,
        conflictAnalysis: conflictAnalysis,
        trendAnalysis: trendAnalysis,
      );
    } catch (e) {
      developer.log('❌ 生成一致性报告失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<List<ConsistencyTrendPoint>> getConsistencyTrend({
    TrendPeriod period = TrendPeriod.last7Days,
    TrendMetric metric = TrendMetric.consistencyRate,
  }) async {
    _ensureInitialized();

    try {
      developer.log('📈 获取一致性趋势 [周期: $period] [指标: $metric]',
          name: 'DataConsistencyManager');

      final now = DateTime.now();
      final startTime = _getTrendPeriodStartTime(now, period);

      final trendPoints = <ConsistencyTrendPoint>[];

      // 生成趋势点（按小时或天）
      final interval = period == TrendPeriod.last7Days
          ? const Duration(days: 1)
          : const Duration(days: 7);

      var currentTime = startTime;
      while (currentTime.isBefore(now)) {
        final point = await _calculateTrendPoint(currentTime, metric);
        trendPoints.add(point);
        currentTime = currentTime.add(interval);
      }

      return trendPoints;
    } catch (e) {
      developer.log('❌ 获取一致性趋势失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> configureConsistencyRules(
    List<ConsistencyRule> rules,
  ) async {
    _ensureInitialized();

    try {
      developer.log('⚙️ 配置一致性规则: ${rules.length} 个规则',
          name: 'DataConsistencyManager');

      _consistencyRules = rules;

      // 验证规则配置
      await _validateConsistencyRules();

      developer.log('✅ 一致性规则配置完成', name: 'DataConsistencyManager');
    } catch (e) {
      developer.log('❌ 配置一致性规则失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<List<ConsistencyRule>> getConsistencyRules() async {
    _ensureInitialized();
    return List.from(_consistencyRules);
  }

  // ========================================================================
  // 事件流访问器
  // ========================================================================

  /// 冲突检测事件流
  Stream<DataConflict> get onConflictDetected =>
      _conflictDetectedController.stream;

  /// 同步完成事件流
  Stream<SyncCompletedEvent> get onSyncCompleted =>
      _syncCompletedController.stream;

  // ========================================================================
  // 私有辅助方法
  // ========================================================================

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'DataConsistencyManager not initialized. Call initialize() first.');
    }
  }

  String _generateVersionId() {
    return 'v${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  String _generateReportId() {
    return 'report_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  int _getNextVersionNumber(String itemType, String itemId) {
    final key = '$itemType:$itemId';
    final currentVersion = _currentVersions[key];
    return currentVersion != null ? currentVersion.versionNumber + 1 : 1;
  }

  void _saveVersion(DataVersion version) {
    final key = '${version.itemType}:${version.itemId}';
    _versionHistory.putIfAbsent(key, () => []).add(version);

    // 限制历史版本数量
    if (_versionHistory[key]!.length > _config.maxVersionHistory) {
      _versionHistory[key] =
          _versionHistory[key]!.skip(_config.maxVersionHistory ~/ 2).toList();
    }
  }

  DateTime _getLastSyncTime() {
    if (_lastSyncTimes.isEmpty) {
      return DateTime.now().subtract(const Duration(hours: 24));
    }
    return _lastSyncTimes.values.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? _getLastGlobalSyncTime() {
    if (_lastSyncTimes.isEmpty) return null;
    return _lastSyncTimes.values.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  void _updateLastSyncTime() {
    final now = DateTime.now();
    for (final sourceId in _dataSources.map((s) => s.id)) {
      _lastSyncTimes[sourceId] = now;
    }
  }

  void _updateConsistencyTrend(ConsistencyValidationResult result) {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    final trendPoint = ConsistencyTrendPoint(
      timestamp: today,
      consistencyRate: result.consistencyRate,
      conflictCount: _activeConflicts.length,
      activeDataSources: _dataSources
          .where((s) => s.healthStatus == HealthStatus.healthy)
          .length,
    );

    _consistencyTrends.putIfAbsent(todayKey, () => []).add(trendPoint);
  }

  Future<void> _performScheduledConsistencyCheck() async {
    try {
      await validateDataConsistency(
          validationScope: ValidationScope.incremental);
    } catch (e) {
      developer.log('⚠️ 定期一致性检查失败: $e', name: 'DataConsistencyManager');
    }
  }

  Future<void> _performScheduledSync() async {
    try {
      await performIncrementalSync();
    } catch (e) {
      developer.log('⚠️ 定期同步失败: $e', name: 'DataConsistencyManager');
    }
  }

  void _updateMetrics() {
    try {
      // 清理过期的指标缓存
      final expiredKeys = _metricsCacheTimestamps.keys.where((key) {
        final cachedTime = _metricsCacheTimestamps[key]!;
        final now = DateTime.now();
        return now.difference(cachedTime) > const Duration(hours: 2);
      }).toList();

      for (final key in expiredKeys) {
        _metricsCache.remove(key);
        _metricsCacheTimestamps.remove(key);
      }
    } catch (e) {
      developer.log('⚠️ 更新指标失败: $e', name: 'DataConsistencyManager');
    }
  }

  // 占位符方法实现（在实际项目中需要根据具体数据源实现）

  Future<void> _performFullValidation(
    List<DataSource> sources,
    List<InconsistencyDetail> inconsistencies,
    int totalItemsChecked,
    int consistentItemsCount,
  ) async {
    // 实现完整验证逻辑
  }

  Future<void> _performIncrementalValidation(
    List<DataSource> sources,
    List<InconsistencyDetail> inconsistencies,
    int totalItemsChecked,
    int consistentItemsCount,
  ) async {
    // 实现增量验证逻辑
  }

  Future<void> _performSelectiveValidation(
    List<DataSource> sources,
    List<InconsistencyDetail> inconsistencies,
    int totalItemsChecked,
    int consistentItemsCount,
  ) async {
    // 实现选择性验证逻辑
  }

  Future<List<DataChange>> _getIncrementalChanges(
    DataSource source,
    DateTime since,
    List<ChangeType>? changeTypes,
  ) async {
    // 实现增量变更获取逻辑
    return [];
  }

  Future<List<DataConflict>> _detectConflictsFromChanges(
      List<DataChange> changes) async {
    // 实现变更冲突检测逻辑
    return [];
  }

  Future<DataStatus> _getItemDataStatus(
      DataSource source, String itemType, String itemId) async {
    // 实现数据状态获取逻辑
    return DataStatus(
      dataSourceId: source.id,
      hasData: false,
      isComplete: false,
    );
  }

  List<DataDifference> _compareDataStatus(
      DataStatus status1, DataStatus status2) {
    // 实现数据状态比较逻辑
    return [];
  }

  Future<List<DataConflict>> _detectTimestampBasedConflicts(
      List<DataSource> sources) async {
    // 实现基于时间戳的冲突检测
    return [];
  }

  Future<List<DataConflict>> _detectVersionBasedConflicts(
      List<DataSource> sources) async {
    // 实现基于版本的冲突检测
    return [];
  }

  Future<List<DataConflict>> _detectContentHashBasedConflicts(
      List<DataSource> sources) async {
    // 实现基于内容哈希的冲突检测
    return [];
  }

  Future<List<DataConflict>> _detectBusinessRuleBasedConflicts(
      List<DataSource> sources) async {
    // 实现基于业务规则的冲突检测
    return [];
  }

  Future<dynamic> _autoResolveConflict(
      DataConflict conflict, List<ResolutionAction> actions) async {
    // 实现自动冲突解决逻辑
    return null;
  }

  Future<dynamic> _resolveWithLatestWins(
      DataConflict conflict, List<ResolutionAction> actions) async {
    // 实现最新版本获胜解决逻辑
    return null;
  }

  Future<dynamic> _resolveWithEarliestWins(
      DataConflict conflict, List<ResolutionAction> actions) async {
    // 实现最旧版本获胜解决逻辑
    return null;
  }

  Future<dynamic> _mergeConflictData(
      DataConflict conflict, List<ResolutionAction> actions) async {
    // 实现数据合并解决逻辑
    return null;
  }

  Future<void> _applyConflictResolution(DataConflict conflict,
      dynamic resolvedValue, List<ResolutionAction> actions) async {
    // 实现冲突解决方案应用逻辑
  }

  Future<dynamic> _predictResolutionOutcome(
      DataConflict conflict, ConflictResolutionStrategy strategy) async {
    // 实现解决结果预测逻辑
    return null;
  }

  Future<ImpactAnalysis> _analyzeResolutionImpact(
      DataConflict conflict, ConflictResolutionStrategy strategy) async {
    // 实现影响分析逻辑
    return const ImpactAnalysis(
      affectedDataSources: 0,
      affectedUsers: 0,
      affectedModules: [],
      performanceImpact: PerformanceImpact(
        responseTimeImpact: 0.0,
        throughputImpact: 0.0,
        resourceUsageImpact: 0.0,
      ),
    );
  }

  Future<void> _rollbackDataToVersion(DataVersion version) async {
    // 实现版本回滚逻辑
  }

  List<VersionDifference> _compareVersionData(
      DataVersion version1, DataVersion version2) {
    // 实现版本数据比较逻辑
    return [];
  }

  double _calculateSimilarityScore(DataVersion version1, DataVersion version2) {
    // 实现相似度计算逻辑
    return 0.0;
  }

  void _mergeWithLatestWins(List<DataVersion> versions,
      Map<String, dynamic> mergedData, List<MergeConflict> conflicts) {
    // 实现最新版本获胜合并逻辑
  }

  void _mergeWithEarliestWins(List<DataVersion> versions,
      Map<String, dynamic> mergedData, List<MergeConflict> conflicts) {
    // 实现最旧版本获胜合并逻辑
  }

  void _mergeAllChanges(List<DataVersion> versions,
      Map<String, dynamic> mergedData, List<MergeConflict> conflicts) {
    // 实现所有变更合并逻辑
  }

  void _mergeKeepConflicts(List<DataVersion> versions,
      Map<String, dynamic> mergedData, List<MergeConflict> conflicts) {
    // 实现保留冲突合并逻辑
  }

  Future<List<DataChange>> _syncAllDataSources(
      DateTime since, SyncDirection direction) async {
    // 实现全部数据源同步逻辑
    return [];
  }

  Future<List<DataChange>> _syncSelectiveDataSources(
      DateTime since, SyncDirection direction) async {
    // 实现选择性数据源同步逻辑
    return [];
  }

  Future<List<DataChange>> _syncIncrementalData(
      DateTime since, SyncDirection direction) async {
    // 实现增量数据同步逻辑
    return [];
  }

  Future<int> _forceSyncDataSource(DataSource source) async {
    // 实现强制数据源同步逻辑
    return 0;
  }

  Future<void> _performComprehensiveIntegrityCheck(
    DataScope? scope,
    List<IntegrityIssue> issues,
    int totalItemsChecked,
    int intactItemsCount,
  ) async {
    // 实现完整性检查逻辑
  }

  Future<void> _performQuickIntegrityCheck(
    DataScope? scope,
    List<IntegrityIssue> issues,
    int totalItemsChecked,
    int intactItemsCount,
  ) async {
    // 实现快速完整性检查逻辑
  }

  Future<void> _performDeepIntegrityCheck(
    DataScope? scope,
    List<IntegrityIssue> issues,
    int totalItemsChecked,
    int intactItemsCount,
  ) async {
    // 实现深度完整性检查逻辑
  }

  Future<void> _performSelectiveIntegrityCheck(
    DataScope? scope,
    List<IntegrityIssue> issues,
    int totalItemsChecked,
    int intactItemsCount,
  ) async {
    // 实现选择性完整性检查逻辑
  }

  RepairMethod _determineRepairMethod(IntegrityIssue issue) {
    // 实现修复方法确定逻辑
    return RepairMethod.dataRecovery;
  }

  Future<bool> _repairIntegrityIssue(
      IntegrityIssue issue, RepairMethod method) async {
    // 实现完整性问题修复逻辑
    return false;
  }

  Future<SourceIntegrityStats> _calculateSourceIntegrityStats(
      DataSource source) async {
    // 实现数据源完整性统计计算逻辑
    return SourceIntegrityStats(
      dataSourceId: source.id,
      totalItems: 0,
      intactItems: 0,
      corruptedItems: 0,
      integrityRate: 1.0,
    );
  }

  Future<List<IntegrityTrendPoint>> _generateIntegrityTrendPoints() async {
    // 实现完整性趋势点生成逻辑
    return [];
  }

  Future<List<ImprovementRecommendation>> _generateIntegrityRecommendations(
      Map<String, SourceIntegrityStats> sourceStats) async {
    // 实现改进建议生成逻辑
    return [];
  }

  List<ConsistencyTrendPoint> _getTrendPointsForPeriod(MetricsPeriod period) {
    // 实现趋势点获取逻辑
    return [];
  }

  double _calculateSourceConsistencyRate(
      String sourceId, MetricsPeriod period) {
    // 实现数据源一致性率计算逻辑
    return 1.0;
  }

  DateTime _getPeriodStartTime(DateTime now, MetricsPeriod period) {
    switch (period) {
      case MetricsPeriod.lastHour:
        return now.subtract(const Duration(hours: 1));
      case MetricsPeriod.last24Hours:
        return now.subtract(const Duration(days: 1));
      case MetricsPeriod.last7Days:
        return now.subtract(const Duration(days: 7));
      case MetricsPeriod.last30Days:
        return now.subtract(const Duration(days: 30));
    }
  }

  Future<ConsistencySummary> _generateConsistencySummary(
      TimeRange timeRange) async {
    // 实现一致性摘要生成逻辑
    return const ConsistencySummary(
      overallStatus: OverallStatus.good,
      consistencyRate: 0.95,
      activeConflictsCount: 0,
      resolvedConflictsToday: 0,
      syncStatus: SyncStatus(
        state: SyncState.completed,
        pendingChangesCount: 0,
        progress: 1.0,
      ),
    );
  }

  Future<ConflictAnalysis> _generateConflictAnalysis(
      TimeRange timeRange) async {
    // 实现冲突分析生成逻辑
    return const ConflictAnalysis(
      conflictTypeDistribution: {},
      conflictSeverityDistribution: {},
      frequentConflictItems: [],
      resolutionTimeAnalysis: ResolutionTimeAnalysis(
        averageResolutionTime: Duration.zero,
        medianResolutionTime: Duration.zero,
        longestResolutionTime: Duration.zero,
        shortestResolutionTime: Duration.zero,
      ),
    );
  }

  Future<TrendAnalysis> _generateTrendAnalysis(TimeRange timeRange) async {
    // 实现趋势分析生成逻辑
    return const TrendAnalysis(
      consistencyRateTrend: [],
      conflictCountTrend: [],
      syncPerformanceTrend: [],
    );
  }

  Future<ConsistencyTrendPoint> _calculateTrendPoint(
      DateTime time, TrendMetric metric) async {
    // 实现趋势点计算逻辑
    return ConsistencyTrendPoint(
      timestamp: time,
      consistencyRate: 0.95,
      conflictCount: 0,
      activeDataSources: _dataSources.length,
    );
  }

  DateTime _getTrendPeriodStartTime(DateTime now, TrendPeriod period) {
    switch (period) {
      case TrendPeriod.last7Days:
        return now.subtract(const Duration(days: 7));
      case TrendPeriod.last30Days:
        return now.subtract(const Duration(days: 30));
      case TrendPeriod.last90Days:
        return now.subtract(const Duration(days: 90));
    }
  }

  Future<void> _validateConsistencyRules() async {
    // 实现一致性规则验证逻辑
  }

  // ===== 断线缓存和恢复接口实现 =====

  @override
  Future<void> recordDataChange({
    required String dataType,
    required String dataKey,
    required Map<String, dynamic> data,
    required String sourceId,
    String changeType = 'update',
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    try {
      final changeId = _generateChangeId();
      final timestamp = DateTime.now();
      final version = _getNextVersionNumber(dataType, dataKey);
      final checksum = _calculateChecksum(data);

      final change = OfflineDataChange(
        changeId: changeId,
        dataType: dataType,
        dataKey: dataKey,
        changeType: changeType,
        previousData: previousData,
        newData: data,
        timestamp: timestamp,
        sourceId: sourceId,
        version: version,
        checksum: checksum,
        metadata: metadata ?? {},
      );

      // 存储变更记录
      _offlineChanges[changeId] = change;

      // 按数据键索引
      _changesByDataKey.putIfAbsent(dataKey, () => []).add(change);

      // 按数据类型索引
      _changesByDataType.putIfAbsent(dataType, () => []).add(change);

      // 按数据源索引
      _changesByDataSource.putIfAbsent(sourceId, () => []).add(change);

      developer.log('📝 记录离线数据变更: $dataKey ($changeType)',
          name: 'DataConsistencyManager');

      // 触发自动同步检查
      _checkAutoOfflineSync();
    } catch (e) {
      developer.log('❌ 记录离线数据变更失败: $dataKey - $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<List<OfflineDataChange>> getCachedChanges({
    DateTime? since,
    String? dataType,
    String? sourceId,
  }) async {
    _ensureInitialized();

    try {
      var changes = _offlineChanges.values.toList();

      // 时间过滤
      if (since != null) {
        changes =
            changes.where((change) => change.timestamp.isAfter(since)).toList();
      }

      // 数据类型过滤
      if (dataType != null) {
        changes =
            changes.where((change) => change.dataType == dataType).toList();
      }

      // 数据源过滤
      if (sourceId != null) {
        changes =
            changes.where((change) => change.sourceId == sourceId).toList();
      }

      // 按时间排序（最新的在前）
      changes.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return changes;
    } catch (e) {
      developer.log('❌ 获取缓存变更失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> cleanupExpiredCache({Duration? olderThan}) async {
    _ensureInitialized();

    try {
      final cutoff = olderThan ?? const Duration(days: 7);
      final cutoffTime = DateTime.now().subtract(cutoff);

      final expiredChanges = <String>[];
      int removedCount = 0;

      for (final entry in _offlineChanges.entries) {
        if (entry.value.timestamp.isBefore(cutoffTime)) {
          expiredChanges.add(entry.key);
        }
      }

      // 移除过期变更
      for (final changeId in expiredChanges) {
        final change = _offlineChanges[changeId]!;

        _offlineChanges.remove(changeId);
        _changesByDataKey[change.dataKey]?.remove(change);
        _changesByDataType[change.dataType]?.remove(change);
        _changesByDataSource[change.sourceId]?.remove(change);

        removedCount++;
      }

      // 清理空列表
      _changesByDataKey.removeWhere((key, value) => value.isEmpty);
      _changesByDataType.removeWhere((key, value) => value.isEmpty);
      _changesByDataSource.removeWhere((key, value) => value.isEmpty);

      developer.log('🧹 清理过期缓存: 移除 $removedCount 个变更',
          name: 'DataConsistencyManager');
    } catch (e) {
      developer.log('❌ 清理过期缓存失败: $e',
          name: 'DataConsistencyManager', level: 1000);
    }
  }

  @override
  Future<OfflineSyncResult> syncCachedChanges({
    String? sourceId,
    List<String>? changeIds,
  }) async {
    _ensureInitialized();

    if (_isOfflineSyncing) {
      throw StateError('离线同步正在进行中');
    }

    final stopwatch = Stopwatch()..start();
    final syncTime = DateTime.now();

    try {
      _isOfflineSyncing = true;
      _offlineSyncStartTime = syncTime;
      _offlineSyncProgress = 0.0;

      developer.log(
          '🔄 开始离线同步: ${sourceId ?? '所有源'}, ${changeIds?.length ?? '全部'} 个变更',
          name: 'DataConsistencyManager');

      // 获取要同步的变更
      final changesToSync = _getChangesToSync(sourceId, changeIds);

      if (changesToSync.isEmpty) {
        return OfflineSyncResult(
          success: true,
          syncedChangesCount: 0,
          failedChangesCount: 0,
          skippedChangesCount: 0,
          syncDuration: stopwatch.elapsed,
          syncTime: syncTime,
          conflictCount: 0,
          resolvedConflictsCount: 0,
          itemResults: [],
        );
      }

      final itemResults = <OfflineSyncItemResult>[];
      int syncedCount = 0;
      int failedCount = 0;
      int skippedCount = 0;
      int conflictCount = 0;
      int resolvedConflictCount = 0;

      // 逐个同步变更
      for (int i = 0; i < changesToSync.length; i++) {
        final change = changesToSync[i];
        _currentOfflineChangeId = change.changeId;
        _offlineSyncProgress = (i + 1) / changesToSync.length;

        try {
          // 检查冲突
          final hasConflict = await _checkChangeConflict(change);
          bool conflictResolved = false;

          if (hasConflict) {
            conflictCount++;
            conflictResolved = await _resolveChangeConflict(change);
            if (conflictResolved) {
              resolvedConflictCount++;
            }
          }

          // 执行同步
          await _syncSingleChange(change);

          // 标记为已同步
          change.markAsSynced();
          syncedCount++;

          itemResults.add(OfflineSyncItemResult(
            changeId: change.changeId,
            dataKey: change.dataKey,
            success: true,
            syncDuration: stopwatch.elapsed,
            hasConflict: hasConflict,
            conflictResolved: conflictResolved,
          ));
        } catch (e) {
          failedCount++;
          change.markSyncFailed(e.toString());

          itemResults.add(OfflineSyncItemResult(
            changeId: change.changeId,
            dataKey: change.dataKey,
            success: false,
            syncDuration: stopwatch.elapsed,
            error: e.toString(),
          ));

          developer.log('⚠️ 变更同步失败: ${change.dataKey} - $e',
              name: 'DataConsistencyManager');
        }
      }

      stopwatch.stop();

      final result = OfflineSyncResult(
        success: failedCount == 0,
        syncedChangesCount: syncedCount,
        failedChangesCount: failedCount,
        skippedChangesCount: skippedCount,
        syncDuration: stopwatch.elapsed,
        syncTime: syncTime,
        conflictCount: conflictCount,
        resolvedConflictsCount: resolvedConflictCount,
        itemResults: itemResults,
      );

      developer.log(
          '✅ 离线同步完成: ${result.syncSuccessRate.toStringAsFixed(1)}% 成功率',
          name: 'DataConsistencyManager');

      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log('❌ 离线同步失败: $e',
          name: 'DataConsistencyManager', level: 1000);

      return OfflineSyncResult(
        success: false,
        syncedChangesCount: 0,
        failedChangesCount: 0,
        skippedChangesCount: 0,
        syncDuration: stopwatch.elapsed,
        syncTime: syncTime,
        conflictCount: 0,
        resolvedConflictsCount: 0,
        itemResults: [],
        error: e.toString(),
      );
    } finally {
      _isOfflineSyncing = false;
      _currentOfflineChangeId = null;
      _offlineSyncProgress = 1.0;
      _offlineSyncStartTime = null;
    }
  }

  @override
  bool detectDataConflict(
    String dataKey,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String remoteChecksum,
  ) {
    try {
      final localChecksum = _calculateChecksum(localData);
      return localChecksum != remoteChecksum;
    } catch (e) {
      developer.log('❌ 检测数据冲突失败: $dataKey - $e',
          name: 'DataConsistencyManager', level: 1000);
      return false;
    }
  }

  @override
  Future<void> resolveDataConflict({
    required String dataKey,
    required ConflictResolutionStrategy strategy,
    Map<String, dynamic>? resolvedData,
  }) async {
    try {
      final changes = _changesByDataKey[dataKey] ?? [];

      for (final change in changes) {
        if (!change.isSynced && change.newData != null) {
          switch (strategy) {
            case ConflictResolutionStrategy.auto:
            case ConflictResolutionStrategy.manual:
            case ConflictResolutionStrategy.userChoice:
              // 保持本地数据，标记为已解决
              change.markAsSynced();
              break;
            case ConflictResolutionStrategy.latestWins:
              // 使用远程数据
              if (resolvedData != null) {
                change.newData = resolvedData;
                change.checksum = _calculateChecksum(resolvedData);
                change.markAsSynced();
              }
              break;
            case ConflictResolutionStrategy.earliestWins:
              // 使用最旧版本数据
              if (resolvedData != null) {
                change.newData = resolvedData;
                change.checksum = _calculateChecksum(resolvedData);
                change.markAsSynced();
              }
              break;
            case ConflictResolutionStrategy.merge:
              // 合并数据（简化处理）
              if (resolvedData != null) {
                change.newData = resolvedData;
                change.checksum = _calculateChecksum(resolvedData);
                change.markAsSynced();
              }
              break;
          }
        }
      }

      developer.log('🔧 解决数据冲突: $dataKey (策略: ${strategy.name})',
          name: 'DataConsistencyManager');
    } catch (e) {
      developer.log('❌ 解决数据冲突失败: $dataKey - $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<OfflineCacheStats> getCacheStats() async {
    try {
      int totalCount = _offlineChanges.length;
      int syncedCount = _offlineChanges.values.where((c) => c.isSynced).length;
      int pendingCount = _offlineChanges.values
          .where((c) => !c.isSynced && c.syncFailureCount == 0)
          .length;
      int failedCount =
          _offlineChanges.values.where((c) => c.syncFailureCount > 0).length;

      // 计算缓存大小
      int cacheSize = 0;
      DateTime? earliestTime;
      DateTime? latestTime;

      for (final change in _offlineChanges.values) {
        cacheSize += change.toString().length; // 简化计算
        if (earliestTime == null || change.timestamp.isBefore(earliestTime)) {
          earliestTime = change.timestamp;
        }
        if (latestTime == null || change.timestamp.isAfter(latestTime)) {
          latestTime = change.timestamp;
        }
      }

      // 按数据类型统计
      final changesByType = <String, int>{};
      for (final entry in _changesByDataType.entries) {
        changesByType[entry.key] = entry.value.length;
      }

      // 按数据源统计
      final changesBySource = <String, int>{};
      for (final entry in _changesByDataSource.entries) {
        changesBySource[entry.key] = entry.value.length;
      }

      // 冲突统计
      int conflictCount = 0;
      for (final change in _offlineChanges.values) {
        if (change.metadata.containsKey('requiresManualResolution')) {
          conflictCount++;
        }
      }

      // 过期变更统计
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      int expiredCount = _offlineChanges.values
          .where((c) => c.timestamp.isBefore(cutoff))
          .length;

      return OfflineCacheStats(
        totalChangesCount: totalCount,
        syncedChangesCount: syncedCount,
        pendingChangesCount: pendingCount,
        failedChangesCount: failedCount,
        cacheSizeBytes: cacheSize,
        earliestChangeTime: earliestTime,
        latestChangeTime: latestTime,
        changesByDataType: changesByType,
        changesByDataSource: changesBySource,
        conflictCount: conflictCount,
        expiredChangesCount: expiredCount,
      );
    } catch (e) {
      developer.log('❌ 获取缓存统计失败: $e',
          name: 'DataConsistencyManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<OfflineSyncStatus> getOfflineSyncStatus() async {
    return OfflineSyncStatus(
      isSyncing: _isOfflineSyncing,
      progress: _offlineSyncProgress,
      currentChangeId: _currentOfflineChangeId,
      estimatedRemainingTime: _offlineSyncStartTime != null && _isOfflineSyncing
          ? Duration(
              milliseconds: ((DateTime.now()
                              .difference(_offlineSyncStartTime!)
                              .inMilliseconds /
                          _offlineSyncProgress.clamp(0.01, 1.0)) *
                      (1 - _offlineSyncProgress))
                  .round())
          : null,
      syncStartTime: _offlineSyncStartTime,
      lastSyncTime: _lastSyncTimes.values.isNotEmpty
          ? _lastSyncTimes.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
      autoSyncEnabled: _autoOfflineSyncEnabled,
      nextAutoSyncTime: _nextAutoOfflineSyncTime,
    );
  }

  // ===== 离线同步私有辅助方法 =====

  String _generateChangeId() {
    return 'change_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  String _calculateChecksum(Map<String, dynamic> data) {
    try {
      final jsonString = json.encode(data);
      final bytes = utf8.encode(jsonString);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      return 'checksum_error_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  List<OfflineDataChange> _getChangesToSync(
      String? sourceId, List<String>? changeIds) {
    var changes =
        _offlineChanges.values.where((change) => !change.isSynced).toList();

    if (sourceId != null) {
      changes = changes.where((change) => change.sourceId == sourceId).toList();
    }

    if (changeIds != null) {
      changes = changes
          .where((change) => changeIds.contains(change.changeId))
          .toList();
    }

    // 优先同步失败次数较少的变更
    changes.sort((a, b) => a.syncFailureCount.compareTo(b.syncFailureCount));

    return changes;
  }

  Future<bool> _checkChangeConflict(OfflineDataChange change) async {
    // 这里应该调用实际的远程数据检查
    // 简化实现：假设没有冲突
    return false;
  }

  Future<bool> _resolveChangeConflict(OfflineDataChange change) async {
    // 这里应该实现实际的冲突解决逻辑
    // 简化实现：自动使用本地数据
    return true;
  }

  Future<void> _syncSingleChange(OfflineDataChange change) async {
    // 这里应该调用实际的远程同步API
    // 模拟网络延迟
    await Future.delayed(
        Duration(milliseconds: 100 + math.Random().nextInt(400)));

    // 模拟偶尔的同步失败（5%概率）
    if (math.Random().nextDouble() < 0.05) {
      throw Exception('模拟网络错误');
    }
  }

  void _checkAutoOfflineSync() {
    if (!_autoOfflineSyncEnabled || _isOfflineSyncing) return;

    final pendingChanges =
        _offlineChanges.values.where((c) => !c.isSynced).length;
    if (pendingChanges >= 10) {
      // 累积10个变更时自动同步
      _nextAutoOfflineSyncTime =
          DateTime.now().add(const Duration(seconds: 30));
      // 这里可以启动定时器进行自动同步
    }
  }

  /// 释放资源
  @override
  Future<void> dispose() async {
    try {
      developer.log('🔒 开始释放数据一致性管理器资源...', name: 'DataConsistencyManager');

      _consistencyCheckTimer?.cancel();
      _metricsUpdateTimer?.cancel();
      _syncTimer?.cancel();

      await _conflictDetectedController.close();
      await _syncCompletedController.close();

      _versionHistory.clear();
      _currentVersions.clear();
      _activeConflicts.clear();
      _resolutionHistory.clear();
      _syncStatus.clear();
      _lastSyncTimes.clear();
      _consistencyRules.clear();
      _consistencyTrends.clear();
      _metricsCache.clear();

      // 清理离线缓存数据
      _offlineChanges.clear();
      _changesByDataKey.clear();
      _changesByDataType.clear();
      _changesByDataSource.clear();
      _isOfflineSyncing = false;
      _offlineSyncProgress = 0.0;
      _currentOfflineChangeId = null;
      _offlineSyncStartTime = null;
      _nextAutoOfflineSyncTime = null;

      _isInitialized = false;
      developer.log('✅ 数据一致性管理器资源释放完成', name: 'DataConsistencyManager');
    } catch (e) {
      developer.log('❌ 释放数据一致性管理器资源失败: $e',
          name: 'DataConsistencyManager', level: 1000);
    }
  }
}

// ========================================================================
// 辅助类定义
// ========================================================================

/// 一致性管理器配置
class ConsistencyManagerConfig {
  final Duration consistencyCheckInterval;
  final Duration metricsUpdateInterval;
  final Duration syncInterval;
  final Duration incrementalCheckWindow;
  final int maxVersionHistory;
  final int maxActiveConflicts;

  const ConsistencyManagerConfig({
    this.consistencyCheckInterval = const Duration(minutes: 15),
    this.metricsUpdateInterval = const Duration(minutes: 5),
    this.syncInterval = const Duration(minutes: 30),
    this.incrementalCheckWindow = const Duration(hours: 1),
    this.maxVersionHistory = 100,
    this.maxActiveConflicts = 1000,
  });

  factory ConsistencyManagerConfig.defaultConfig() =>
      const ConsistencyManagerConfig();

  factory ConsistencyManagerConfig.development() =>
      const ConsistencyManagerConfig(
        consistencyCheckInterval: Duration(minutes: 5),
        metricsUpdateInterval: Duration(minutes: 2),
        syncInterval: Duration(minutes: 10),
        incrementalCheckWindow: Duration(minutes: 30),
        maxVersionHistory: 50,
        maxActiveConflicts: 500,
      );

  factory ConsistencyManagerConfig.production() =>
      const ConsistencyManagerConfig(
        consistencyCheckInterval: Duration(minutes: 10),
        metricsUpdateInterval: Duration(minutes: 1),
        syncInterval: Duration(minutes: 15),
        incrementalCheckWindow: Duration(minutes: 15),
        maxVersionHistory: 200,
        maxActiveConflicts: 2000,
      );
}

/// 同步完成事件
class SyncCompletedEvent {
  final IncrementalSyncResult syncResult;

  const SyncCompletedEvent({required this.syncResult});
}

/// SyncStatus 扩展方法
extension SyncStatusExtension on SyncStatus {
  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncTime,
    int? pendingChangesCount,
    double? progress,
    String? error,
  }) {
    return SyncStatus(
      dataSourceId: dataSourceId,
      state: state ?? this.state,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingChangesCount: pendingChangesCount ?? this.pendingChangesCount,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}
