import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../cache/hive_cache_manager.dart';
import '../../di/hive_injection_container.dart';

part 'cache_event.dart';
part 'cache_state.dart';

/// 统一缓存管理BLoC
///
/// 负责管理应用中所有缓存相关的状态和操作
/// 包括缓存数据的存储、获取、清理和统计
class CacheBloc extends Bloc<CacheEvent, CacheState> {
  final HiveCacheManager _cacheManager;

  CacheBloc({HiveCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? HiveCacheManager.instance,
        super(CacheState.initial()) {
    on<InitializeCache>(_onInitializeCache);
    on<StoreCacheData>(_onStoreCacheData);
    on<GetCacheData>(_onGetCacheData);
    on<RemoveCacheData>(_onRemoveCacheData);
    on<ClearAllCache>(_onClearAllCache);
    on<ClearExpiredCache>(_onClearExpiredCache);
    on<GetCacheStatistics>(_onGetCacheStatistics);
    on<MonitorCacheUsage>(_onMonitorCacheUsage);
    on<SetCachePolicy>(_onSetCachePolicy);
  }

  /// 初始化缓存
  Future<void> _onInitializeCache(
    InitializeCache event,
    Emitter<CacheState> emit,
  ) async {
    emit(CacheState.loading());

    try {
      await _cacheManager.initialize();

      emit(state.copyWith(
        status: CacheStatus.initialized,
        statistics: _cacheManager.getStats(),
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ 缓存管理器初始化成功');
    } catch (e) {
      emit(state.copyWith(
        status: CacheStatus.error,
        errorMessage: '缓存初始化失败: ${e.toString()}',
      ));

      debugPrint('❌ 缓存管理器初始化失败: $e');
    }
  }

  /// 存储缓存数据
  Future<void> _onStoreCacheData(
    StoreCacheData event,
    Emitter<CacheState> emit,
  ) async {
    try {
      await _cacheManager.put(
        event.key,
        event.value,
        expiration: event.expiration,
      );

      emit(state.copyWith(
        status: CacheStatus.dataStored,
        lastOperation: CacheOperation.store,
        lastOperationKey: event.key,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ 缓存数据已存储: ${event.key}');
    } catch (e) {
      emit(state.copyWith(
        status: CacheStatus.error,
        errorMessage: '存储缓存数据失败: ${e.toString()}',
      ));

      debugPrint('❌ 存储缓存数据失败: $e');
    }
  }

  /// 获取缓存数据
  Future<void> _onGetCacheData(
    GetCacheData event,
    Emitter<CacheState> emit,
  ) async {
    try {
      final value = _cacheManager.get(event.key);

      final isHit = value != null;

      emit(state.copyWith(
        status: CacheStatus.dataRetrieved,
        lastOperation: CacheOperation.retrieve,
        lastOperationKey: event.key,
        lastOperationResult: value,
        cacheHits: isHit ? state.cacheHits + 1 : state.cacheHits,
        cacheMisses: isHit ? state.cacheMisses : state.cacheMisses + 1,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('${isHit ? "✅" : "❌"} 缓存${isHit ? "命中" : "未命中"}: ${event.key}');
    } catch (e) {
      emit(state.copyWith(
        status: CacheStatus.error,
        errorMessage: '获取缓存数据失败: ${e.toString()}',
      ));

      debugPrint('❌ 获取缓存数据失败: $e');
    }
  }

  /// 移除缓存数据
  Future<void> _onRemoveCacheData(
    RemoveCacheData event,
    Emitter<CacheState> emit,
  ) async {
    try {
      await _cacheManager.remove(event.key);

      emit(state.copyWith(
        status: CacheStatus.dataRemoved,
        lastOperation: CacheOperation.remove,
        lastOperationKey: event.key,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ 缓存数据已移除: ${event.key}');
    } catch (e) {
      emit(state.copyWith(
        status: CacheStatus.error,
        errorMessage: '移除缓存数据失败: ${e.toString()}',
      ));

      debugPrint('❌ 移除缓存数据失败: $e');
    }
  }

  /// 清空所有缓存
  Future<void> _onClearAllCache(
    ClearAllCache event,
    Emitter<CacheState> emit,
  ) async {
    emit(state.copyWith(status: CacheStatus.clearing));

    try {
      await _cacheManager.clear();

      emit(state.copyWith(
        status: CacheStatus.cleared,
        lastOperation: CacheOperation.clearAll,
        cacheHits: 0,
        cacheMisses: 0,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ 所有缓存已清空');
    } catch (e) {
      emit(state.copyWith(
        status: CacheStatus.error,
        errorMessage: '清空缓存失败: ${e.toString()}',
      ));

      debugPrint('❌ 清空缓存失败: $e');
    }
  }

  /// 清理过期缓存
  Future<void> _onClearExpiredCache(
    ClearExpiredCache event,
    Emitter<CacheState> emit,
  ) async {
    try {
      await _cacheManager.clearExpiredCache();

      emit(state.copyWith(
        status: CacheStatus.expiredCleared,
        lastOperation: CacheOperation.clearExpired,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('✅ 过期缓存清理完成');
    } catch (e) {
      emit(state.copyWith(
        status: CacheStatus.error,
        errorMessage: '清理过期缓存失败: ${e.toString()}',
      ));

      debugPrint('❌ 清理过期缓存失败: $e');
    }
  }

  /// 获取缓存统计信息
  Future<void> _onGetCacheStatistics(
    GetCacheStatistics event,
    Emitter<CacheState> emit,
  ) async {
    try {
      final statistics = _cacheManager.getStats();
      final hitRate = _calculateHitRate();

      emit(state.copyWith(
        status: CacheStatus.statisticsReady,
        statistics: statistics,
        hitRate: hitRate,
        lastUpdated: DateTime.now(),
      ));

      debugPrint('📊 缓存统计信息: 命中率 ${(hitRate * 100).toStringAsFixed(1)}%');
    } catch (e) {
      emit(state.copyWith(
        status: CacheStatus.error,
        errorMessage: '获取缓存统计失败: ${e.toString()}',
      ));

      debugPrint('❌ 获取缓存统计失败: $e');
    }
  }

  /// 监控缓存使用情况
  Future<void> _onMonitorCacheUsage(
    MonitorCacheUsage event,
    Emitter<CacheState> emit,
  ) async {
    // 获取实时统计信息
    final statistics = _cacheManager.getStats();
    final hitRate = _calculateHitRate();

    emit(state.copyWith(
      status: CacheStatus.monitoring,
      statistics: statistics,
      hitRate: hitRate,
      isMonitoring: true,
      lastUpdated: DateTime.now(),
    ));

    debugPrint('🔍 开始缓存监控: 命中率 ${(hitRate * 100).toStringAsFixed(1)}%');
  }

  /// 设置缓存策略
  Future<void> _onSetCachePolicy(
    SetCachePolicy event,
    Emitter<CacheState> emit,
  ) async {
    emit(state.copyWith(
      status: CacheStatus.policyUpdated,
      cachePolicy: event.policy,
      lastUpdated: DateTime.now(),
    ));

    debugPrint('⚙️ 缓存策略已更新: ${event.policy.toString()}');
  }

  /// 计算缓存命中率
  double _calculateHitRate() {
    final total = state.cacheHits + state.cacheMisses;
    if (total == 0) return 0.0;
    return state.cacheHits / total;
  }

  /// 获取缓存命中率
  double get hitRate => _calculateHitRate();

  /// 检查缓存是否健康
  bool get isHealthy {
    return state.status != CacheStatus.error &&
           hitRate > 0.5 && // 命中率大于50%
           (state.statistics['size'] ?? 0) < 1000; // 缓存项数量合理
  }

  /// 获取缓存健康报告
  Map<String, dynamic> getHealthReport() {
    return {
      'isHealthy': isHealthy,
      'status': state.status.name,
      'hitRate': hitRate,
      'cacheSize': state.statistics['size'] ?? 0,
      'lastUpdated': state.lastUpdated?.toIso8601String(),
      'errorCount': state.errorMessage != null ? 1 : 0,
      'recommendations': _getHealthRecommendations(),
    };
  }

  /// 获取健康建议
  List<String> _getHealthRecommendations() {
    final recommendations = <String>[];

    if (hitRate < 0.5) {
      recommendations.add('缓存命中率过低，建议检查缓存策略');
    }

    if ((state.statistics['size'] ?? 0) > 1000) {
      recommendations.add('缓存项数量过多，建议定期清理');
    }

    if (state.status == CacheStatus.error) {
      recommendations.add('缓存系统存在错误，建议检查日志');
    }

    return recommendations;
  }

  @override
  Future<void> close() async {
    debugPrint('🔄 CacheBloc 正在关闭...');
    await super.close();
  }
}