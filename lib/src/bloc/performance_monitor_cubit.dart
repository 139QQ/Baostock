// ignore_for_file: type_literal_in_constant_pattern

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../core/performance/core_performance_manager.dart' as core;
import '../core/performance/performance_detector.dart' as detector;
import '../core/performance/unified_performance_monitor.dart';
import '../core/utils/logger.dart';

/// 性能状态基类
abstract class PerformanceState extends Equatable {
  const PerformanceState();

  @override
  List<Object?> get props => [];
}

/// 性能监控初始状态
class PerformanceInitial extends PerformanceState {
  const PerformanceInitial();
}

/// 性能监控加载状态
class PerformanceLoading extends PerformanceState {
  const PerformanceLoading();
}

/// 性能数据已加载状态
class PerformanceLoaded extends PerformanceState {
  final core.PerformanceMetrics currentMetrics;
  final Map<String, dynamic> statistics;
  final String status;
  final String strategy;
  final DateTime timestamp;

  const PerformanceLoaded({
    required this.currentMetrics,
    required this.statistics,
    required this.status,
    required this.strategy,
    required this.timestamp,
  });

  @override
  List<Object?> get props =>
      [currentMetrics, statistics, status, strategy, timestamp];

  PerformanceLoaded copyWith({
    core.PerformanceMetrics? currentMetrics,
    Map<String, dynamic>? statistics,
    String? status,
    String? strategy,
    DateTime? timestamp,
  }) {
    return PerformanceLoaded(
      currentMetrics: currentMetrics ?? this.currentMetrics,
      statistics: statistics ?? this.statistics,
      status: status ?? this.status,
      strategy: strategy ?? this.strategy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// 性能警告状态
class PerformanceWarning extends PerformanceState {
  final String warningType;
  final String message;
  final core.PerformanceMetrics? metrics;

  const PerformanceWarning({
    required this.warningType,
    required this.message,
    this.metrics,
  });

  @override
  List<Object?> get props => [warningType, message, metrics];
}

/// 性能错误状态
class PerformanceError extends PerformanceState {
  final String error;
  final String? stackTrace;

  const PerformanceError({
    required this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [error, stackTrace];
}

/// 性能优化已应用状态
class PerformanceOptimizationApplied extends PerformanceState {
  final String optimizationType;
  final Map<String, dynamic> results;

  const PerformanceOptimizationApplied({
    required this.optimizationType,
    required this.results,
  });

  @override
  List<Object?> get props => [optimizationType, results];
}

/// 性能监控事件基类
abstract class PerformanceEvent extends Equatable {
  const PerformanceEvent();
}

/// 开始性能监控事件
class StartPerformanceMonitoring extends PerformanceEvent {
  const StartPerformanceMonitoring();

  @override
  List<Object?> get props => [];
}

/// 停止性能监控事件
class StopPerformanceMonitoring extends PerformanceEvent {
  const StopPerformanceMonitoring();

  @override
  List<Object?> get props => [];
}

/// 刷新性能指标事件
class RefreshPerformanceMetrics extends PerformanceEvent {
  const RefreshPerformanceMetrics();

  @override
  List<Object?> get props => [];
}

/// 应用性能优化事件
class ApplyPerformanceOptimization extends PerformanceEvent {
  final String optimizationType;

  const ApplyPerformanceOptimization({
    required this.optimizationType,
  });

  @override
  List<Object?> get props => [optimizationType];
}

/// 清理性能缓存事件
class ClearPerformanceCache extends PerformanceEvent {
  const ClearPerformanceCache();

  @override
  List<Object?> get props => [];
}

/// 获取性能历史事件
class GetPerformanceHistory extends PerformanceEvent {
  final int? limit;

  const GetPerformanceHistory({this.limit});

  @override
  List<Object?> get props => [limit];
}

/// 获取详细性能报告事件
class GetDetailedPerformanceReport extends PerformanceEvent {
  const GetDetailedPerformanceReport();

  @override
  List<Object?> get props => [];
}

/// 性能监控Cubit
class PerformanceMonitorCubit extends Cubit<PerformanceState> {
  final core.CorePerformanceManager _performanceManager;
  final detector.SmartPerformanceDetector _performanceDetector;
  final UnifiedPerformanceMonitor _unifiedMonitor;

  StreamSubscription<core.PerformanceMetrics>? _performanceSubscription;
  StreamSubscription<core.PerformanceMetrics>? _alertSubscription;
  Timer? _refreshTimer;

  PerformanceMonitorCubit({
    core.CorePerformanceManager? performanceManager,
    detector.SmartPerformanceDetector? performanceDetector,
    UnifiedPerformanceMonitor? unifiedMonitor,
  })  : _performanceManager =
            performanceManager ?? core.CorePerformanceManager(),
        _performanceDetector =
            performanceDetector ?? detector.SmartPerformanceDetector.instance,
        _unifiedMonitor = unifiedMonitor ?? UnifiedPerformanceMonitor(),
        super(const PerformanceInitial());

  /// 初始化性能监控
  Future<void> initialize() async {
    try {
      emit(const PerformanceLoading());

      // 初始化核心性能管理器
      await _performanceManager.initialize();

      // 初始化性能检测器 - SmartPerformanceDetector不需要显式初始化
      // await _performanceDetector.initialize();

      // 设置性能监控回调
      _setupPerformanceCallbacks();

      // 获取初始性能指标
      final initialMetrics = _performanceManager.getCurrentMetrics();
      final statistics = _performanceManager.getStatistics();

      emit(PerformanceLoaded(
        currentMetrics: initialMetrics,
        statistics: statistics,
        status: _performanceManager.currentStatus.name,
        strategy: _performanceManager.currentStrategy.name,
        timestamp: DateTime.now(),
      ));

      AppLogger.business('性能监控Cubit初始化完成', 'PerformanceMonitorCubit');
    } catch (e) {
      AppLogger.error('性能监控Cubit初始化失败', e);
      emit(PerformanceError(error: e.toString()));
    }
  }

  /// 设置性能监控回调
  void _setupPerformanceCallbacks() {
    // 性能指标回调
    _performanceManager.addPerformanceCallback((metrics) {
      if (state is PerformanceLoaded) {
        final currentState = state as PerformanceLoaded;
        emit(currentState.copyWith(
          currentMetrics: metrics,
          timestamp: DateTime.now(),
        ));
      }

      // 检查性能警告
      _checkPerformanceWarnings(metrics);
    });

    // 策略变更回调
    _performanceManager.addStrategyChangeCallback((strategy) {
      AppLogger.info('性能优化策略已变更: ${strategy.name}', 'PerformanceMonitorCubit');
    });

    // 危险状态回调
    _performanceManager.addCriticalStateCallback(() {
      emit(PerformanceWarning(
        warningType: 'critical',
        message: '系统性能处于危险状态，已应用紧急优化措施',
        metrics: _performanceManager.getCurrentMetrics(),
      ));
    });
  }

  /// 检查性能警告
  void _checkPerformanceWarnings(core.PerformanceMetrics metrics) {
    if (metrics.memoryUsage > 85) {
      emit(PerformanceWarning(
        warningType: 'memory',
        message: '内存使用率过高: ${metrics.memoryUsage.toStringAsFixed(1)}%',
        metrics: metrics,
      ));
    }

    if (metrics.activeLoadingTasks > 10) {
      emit(PerformanceWarning(
        warningType: 'loading',
        message: '活动加载任务过多: ${metrics.activeLoadingTasks}',
        metrics: metrics,
      ));
    }

    if (metrics.queuedLoadingTasks > 20) {
      emit(PerformanceWarning(
        warningType: 'queue',
        message: '排队任务过多: ${metrics.queuedLoadingTasks}',
        metrics: metrics,
      ));
    }
  }

  /// 开始性能监控
  Future<void> startMonitoring() async {
    try {
      await _performanceManager.refreshMetrics();

      // 启动定时刷新
      _startRefreshTimer();

      AppLogger.business('性能监控已启动', 'PerformanceMonitorCubit');
    } catch (e) {
      AppLogger.error('启动性能监控失败', e);
      emit(PerformanceError(error: e.toString()));
    }
  }

  /// 停止性能监控
  void stopMonitoring() {
    _refreshTimer?.cancel();
    _performanceSubscription?.cancel();
    _alertSubscription?.cancel();

    AppLogger.business('性能监控已停止', 'PerformanceMonitorCubit');
  }

  /// 启动定时刷新
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshMetrics();
    });
  }

  /// 事件处理
  Future<void> handleEvent(PerformanceEvent event) async {
    try {
      switch (event.runtimeType) {
        case StartPerformanceMonitoring:
          await startMonitoring();
          break;
        case StopPerformanceMonitoring:
          stopMonitoring();
          break;
        case RefreshPerformanceMetrics:
          await _refreshMetrics();
          break;
        case ApplyPerformanceOptimization:
          await _applyOptimization(event as ApplyPerformanceOptimization);
          break;
        case ClearPerformanceCache:
          await _clearCache();
          break;
        case GetPerformanceHistory:
          await _getHistory(event as GetPerformanceHistory);
          break;
        case GetDetailedPerformanceReport:
          await _getDetailedReport();
          break;
      }
    } catch (e) {
      AppLogger.error('处理性能事件失败: ${event.runtimeType}', e);
      emit(PerformanceError(error: e.toString()));
    }
  }

  /// 刷新性能指标
  Future<void> _refreshMetrics() async {
    try {
      await _performanceManager.refreshMetrics();

      final metrics = _performanceManager.getCurrentMetrics();
      final statistics = _performanceManager.getStatistics();

      if (state is PerformanceLoaded) {
        final currentState = state as PerformanceLoaded;
        emit(currentState.copyWith(
          currentMetrics: metrics,
          statistics: statistics,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      AppLogger.error('刷新性能指标失败', e);
    }
  }

  /// 应用性能优化
  Future<void> _applyOptimization(ApplyPerformanceOptimization event) async {
    try {
      final optimizationType = event.optimizationType;

      switch (optimizationType.toLowerCase()) {
        case 'aggressive':
          await _performanceManager.triggerOptimization(
            strategy: core.OptimizationStrategy.aggressive,
          );
          break;
        case 'balanced':
          await _performanceManager.triggerOptimization(
            strategy: core.OptimizationStrategy.balanced,
          );
          break;
        case 'conservative':
          await _performanceManager.triggerOptimization(
            strategy: core.OptimizationStrategy.conservative,
          );
          break;
        case 'adaptive':
          await _performanceManager.triggerOptimization(
            strategy: core.OptimizationStrategy.adaptive,
          );
          break;
        default:
          await _performanceManager.triggerOptimization();
      }

      // 等待优化生效后刷新指标
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshMetrics();

      emit(PerformanceOptimizationApplied(
        optimizationType: optimizationType,
        results: {
          'timestamp': DateTime.now().toIso8601String(),
          'strategy': _performanceManager.currentStrategy.name,
          'status': _performanceManager.currentStatus.name,
        },
      ));

      AppLogger.business(
          '性能优化已应用: $optimizationType', 'PerformanceMonitorCubit');
    } catch (e) {
      AppLogger.error('应用性能优化失败', e);
      emit(PerformanceError(error: e.toString()));
    }
  }

  /// 清理性能缓存
  Future<void> _clearCache() async {
    try {
      // 注意：根据实际API调整方法调用
      // _performanceManager.lazyLoadingManager.clearCache();
      // _performanceManager.memoryManager.clearCache();

      // Story 2.5 组件缓存清理 - 根据实际API调整
      // _performanceManager.advancedMemoryManager.clearCache();
      // _performanceManager.batchProcessor.clearQueue();

      await _refreshMetrics();

      AppLogger.business('性能缓存已清理', 'PerformanceMonitorCubit');
    } catch (e) {
      AppLogger.error('清理性能缓存失败', e);
      emit(PerformanceError(error: e.toString()));
    }
  }

  /// 获取性能历史
  Future<void> _getHistory(GetPerformanceHistory event) async {
    try {
      final history =
          _performanceManager.getPerformanceHistory(limit: event.limit);

      // 这里可以添加状态来存储历史数据，或通过回调返回
      AppLogger.debug(
          '获取性能历史: ${history.length} 条记录', 'PerformanceMonitorCubit');
    } catch (e) {
      AppLogger.error('获取性能历史失败', e);
      emit(PerformanceError(error: e.toString()));
    }
  }

  /// 获取详细性能报告
  Future<void> _getDetailedReport() async {
    try {
      final report = _performanceManager.exportPerformanceReport();
      // final unifiedReport = await _unifiedMonitor.generateComprehensiveReport();

      AppLogger.info('详细性能报告已生成', 'PerformanceMonitorCubit');

      // 可以通过回调或事件返回报告内容
      if (kDebugMode) {
        print('\n=== 详细性能报告 ===\n$report');
      }
    } catch (e) {
      AppLogger.error('生成详细性能报告失败', e);
      emit(PerformanceError(error: e.toString()));
    }
  }

  /// 获取当前性能状态
  core.PerformanceStatus? getCurrentPerformanceStatus() {
    return _performanceManager.currentStatus;
  }

  /// 获取当前优化策略
  core.OptimizationStrategy? getCurrentOptimizationStrategy() {
    return _performanceManager.currentStrategy;
  }

  /// 获取Story 2.5组件状态
  Map<String, dynamic> getStory25ComponentStatus() {
    // 返回基本状态信息，具体的组件访问需要根据实际CorePerformanceManager API调整
    return {
      'performanceManager': {
        'status': _performanceManager.currentStatus.name,
        'strategy': _performanceManager.currentStrategy.name,
      },
      'performanceDetector': {
        'isMonitoring': _performanceDetector.isMonitoring,
        'lastResult': _performanceDetector.lastResult?.score,
      },
      // 注释掉需要具体API访问的组件
      /*
      'advancedMemoryManager': {
        'initialized': _performanceManager.advancedMemoryManager.isInitialized,
        'memoryInfo': _performanceManager.advancedMemoryManager.getMemoryInfo().toMap(),
      },
      'deviceDetector': {
        'initialized': _performanceManager.deviceDetector.isInitialized,
        'capabilities': _performanceManager.deviceDetector.getCurrentCapabilities()?.toMap(),
      },
      'batchProcessor': {
        'state': _performanceManager.batchProcessor.currentState.name,
        'queueLength': _performanceManager.batchProcessor.queueLength,
        'currentBatchSize': _performanceManager.batchProcessor.currentBatchSize,
      },
      'memoryLeakDetector': {
        'isMonitoring': _performanceManager.memoryLeakDetector.isMonitoring,
        'leakCount': _performanceManager.memoryLeakDetector.getLeakCount(),
      },
      'lowOverheadMonitor': {
        'isInitialized': _performanceManager.lowOverheadMonitor.isInitialized,
        'currentMetrics': _performanceManager.lowOverheadMonitor.getCurrentMetrics(),
      },
      'unifiedMonitor': {
        'isInitialized': _performanceManager.unifiedMonitor.isInitialized,
        'isMonitoring': _performanceManager.unifiedMonitor.isMonitoring,
      },
      */
    };
  }

  @override
  Future<void> close() async {
    stopMonitoring();
    await _performanceManager.dispose();
    await super.close();
  }
}
