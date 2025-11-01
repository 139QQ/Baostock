import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import '../interfaces/i_data_consistency_manager.dart';
import '../interfaces/i_data_router.dart';
import '../interfaces/i_unified_data_source.dart';

/// 数据一致性管理器实现
///
/// 负责维护多数据源之间的数据一致性，处理冲突检测和解决
/// 支持版本控制、增量同步和数据完整性验证
class DataConsistencyManager implements IDataConsistencyManager {
  // ========================================================================
  // 核心依赖和状态
  // ========================================================================

  final List<DataSource> _dataSources;
  final IDataRouter _dataRouter;

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
    required IDataRouter dataRouter,
    ConsistencyManagerConfig? config,
  })  : _dataSources = dataSources,
        _dataRouter = dataRouter,
        _config = config ?? ConsistencyManagerConfig.defaultConfig();

  /// 初始化一致性管理器
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
      _syncStatus[source.id] = SyncStatus(
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
      ConsistencyRule(
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
      ConsistencyRule(
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
      _lastSyncTimes[source.id] = DateTime.now().subtract(Duration(hours: 1));
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
      final createdBy = 'DataConsistencyManager';

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
              VersionMetadata(
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
          dataItems.first.itemType + ':' + dataItems.first.itemId]!;
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
      final key = '${itemType}:${itemId}';
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

      final key = '${itemType}:${itemId}';
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

      final key = '${itemType}:${itemId}';
      final history = _versionHistory[key] ?? [];

      final version1 = history.firstWhere((v) => v.versionId == versionId1);
      final version2 = history.firstWhere((v) => v.versionId == versionId2);

      if (version1 == null || version2 == null) {
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

      final key = '${itemType}:${itemId}';
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
          SyncStatus(
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
          SyncStatus(
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
          SyncStatus(
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
      if (now.difference(cachedTime) < Duration(hours: 1)) {
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
        startTime: startTime ?? now.subtract(Duration(days: 1)),
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
          ? Duration(days: 1)
          : Duration(days: 7);

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
    final key = '${itemType}:${itemId}';
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
      return DateTime.now().subtract(Duration(hours: 24));
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
        return now.difference(cachedTime) > Duration(hours: 2);
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
    return ImpactAnalysis(
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
        return now.subtract(Duration(hours: 1));
      case MetricsPeriod.last24Hours:
        return now.subtract(Duration(days: 1));
      case MetricsPeriod.last7Days:
        return now.subtract(Duration(days: 7));
      case MetricsPeriod.last30Days:
        return now.subtract(Duration(days: 30));
    }
  }

  Future<ConsistencySummary> _generateConsistencySummary(
      TimeRange timeRange) async {
    // 实现一致性摘要生成逻辑
    return ConsistencySummary(
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
    return ConflictAnalysis(
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
    return TrendAnalysis(
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
        return now.subtract(Duration(days: 7));
      case TrendPeriod.last30Days:
        return now.subtract(Duration(days: 30));
      case TrendPeriod.last90Days:
        return now.subtract(Duration(days: 90));
    }
  }

  Future<void> _validateConsistencyRules() async {
    // 实现一致性规则验证逻辑
  }

  /// 释放资源
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

  factory ConsistencyManagerConfig.development() => ConsistencyManagerConfig(
        consistencyCheckInterval: Duration(minutes: 5),
        metricsUpdateInterval: Duration(minutes: 2),
        syncInterval: Duration(minutes: 10),
        incrementalCheckWindow: Duration(minutes: 30),
        maxVersionHistory: 50,
        maxActiveConflicts: 500,
      );

  factory ConsistencyManagerConfig.production() => ConsistencyManagerConfig(
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
