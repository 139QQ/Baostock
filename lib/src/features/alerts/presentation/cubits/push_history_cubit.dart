import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/managers/push_history_manager.dart';
import '../../data/models/push_history_record.dart';
import '../../data/services/push_analytics_service.dart';
import '../../../../core/utils/logger.dart';

/// 推送历史状态
enum PushHistoryStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

/// 推送历史状态
class PushHistoryState extends Equatable {
  final PushHistoryStatus status;
  final List<PushHistoryRecord> records;
  final bool hasReachedMax;
  final int currentPage;
  final String? errorMessage;
  final PushHistoryFilter filter;
  final bool isLoadingMore;

  const PushHistoryState({
    this.status = PushHistoryStatus.initial,
    this.records = const [],
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.errorMessage,
    this.filter = const PushHistoryFilter(),
    this.isLoadingMore = false,
  });

  PushHistoryState copyWith({
    PushHistoryStatus? status,
    List<PushHistoryRecord>? records,
    bool? hasReachedMax,
    int? currentPage,
    String? errorMessage,
    PushHistoryFilter? filter,
    bool? isLoadingMore,
    bool clearError = false,
  }) {
    return PushHistoryState(
      status: status ?? this.status,
      records: records ?? this.records,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        records,
        hasReachedMax,
        currentPage,
        errorMessage,
        filter,
        isLoadingMore,
      ];
}

/// 推送历史过滤器
class PushHistoryFilter extends Equatable {
  final String? keyword;
  final String? pushType;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isRead;
  final bool? isClicked;
  final String? userFeedback;

  const PushHistoryFilter({
    this.keyword,
    this.pushType,
    this.priority,
    this.startDate,
    this.endDate,
    this.isRead,
    this.isClicked,
    this.userFeedback,
  });

  PushHistoryFilter copyWith({
    String? keyword,
    String? pushType,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRead,
    bool? isClicked,
    String? userFeedback,
    bool clearFilters = false,
  }) {
    return PushHistoryFilter(
      keyword: clearFilters ? null : (keyword ?? this.keyword),
      pushType: clearFilters ? null : (pushType ?? this.pushType),
      priority: clearFilters ? null : (priority ?? this.priority),
      startDate: clearFilters ? null : (startDate ?? this.startDate),
      endDate: clearFilters ? null : (endDate ?? this.endDate),
      isRead: clearFilters ? null : (isRead ?? this.isRead),
      isClicked: clearFilters ? null : (isClicked ?? this.isClicked),
      userFeedback: clearFilters ? null : (userFeedback ?? this.userFeedback),
    );
  }

  bool get hasActiveFilter =>
      keyword != null ||
      pushType != null ||
      priority != null ||
      startDate != null ||
      endDate != null ||
      isRead != null ||
      isClicked != null ||
      userFeedback != null;

  @override
  List<Object?> get props => [
        keyword,
        pushType,
        priority,
        startDate,
        endDate,
        isRead,
        isClicked,
        userFeedback,
      ];
}

/// 推送历史事件
abstract class PushHistoryEvent extends Equatable {
  const PushHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// 加载推送历史
class LoadPushHistory extends PushHistoryEvent {
  final bool refresh;
  final PushHistoryFilter? filter;

  const LoadPushHistory({
    this.refresh = false,
    this.filter,
  });

  @override
  List<Object?> get props => [refresh, filter];
}

/// 加载更多推送历史
class LoadMorePushHistory extends PushHistoryEvent {}

/// 更新过滤器
class UpdateFilter extends PushHistoryEvent {
  final PushHistoryFilter filter;

  const UpdateFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// 清除过滤器
class ClearFilter extends PushHistoryEvent {}

/// 标记为已读
class MarkAsRead extends PushHistoryEvent {
  final String recordId;

  const MarkAsRead(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// 批量标记为已读
class MarkAllAsRead extends PushHistoryEvent {}

/// 设置用户反馈
class SetUserFeedback extends PushHistoryEvent {
  final String recordId;
  final String feedback;

  const SetUserFeedback(this.recordId, this.feedback);

  @override
  List<Object?> get props => [recordId, feedback];
}

/// 删除记录
class DeleteRecord extends PushHistoryEvent {
  final String recordId;

  const DeleteRecord(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// 清除错误
class ClearError extends PushHistoryEvent {}

/// 推送历史Cubit
class PushHistoryCubit extends Bloc<PushHistoryEvent, PushHistoryState> {
  PushHistoryCubit({
    PushHistoryManager? historyManager,
    PushAnalyticsService? analyticsService,
  })  : _historyManager = historyManager ?? PushHistoryManager.instance,
        _analyticsService = analyticsService ?? PushAnalyticsService.instance,
        super(const PushHistoryState()) {
    // 注册事件处理器
    on<LoadPushHistory>(_onLoadPushHistory);
    on<LoadMorePushHistory>(_onLoadMorePushHistory);
    on<UpdateFilter>(_onUpdateFilter);
    on<ClearFilter>(_onClearFilter);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<SetUserFeedback>(_onSetUserFeedback);
    on<DeleteRecord>(_onDeleteRecord);
    on<ClearError>(_onClearError);
  }

  final PushHistoryManager _historyManager;
  final PushAnalyticsService _analyticsService;

  static const int _pageSize = 20;

  /// 初始化
  Future<void> initialize() async {
    try {
      emit(state.copyWith(status: PushHistoryStatus.loading));

      // 初始化服务
      await _historyManager.initialize();
      await _analyticsService.initialize();

      // 加载初始数据
      await _loadInitialHistory();

      emit(state.copyWith(status: PushHistoryStatus.loaded));
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to initialize', e);
      emit(state.copyWith(
        status: PushHistoryStatus.error,
        errorMessage: '初始化失败: ${e.toString()}',
      ));
    }
  }

  /// 加载初始历史记录
  Future<void> _loadInitialHistory() async {
    try {
      final records = await _fetchRecordsFromSource(page: 0);

      emit(state.copyWith(
        records: records,
        hasReachedMax: records.length < _pageSize,
        currentPage: 1,
      ));
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to load initial history', e);
      rethrow;
    }
  }

  /// 从数据源获取记录
  Future<List<PushHistoryRecord>> _fetchRecordsFromSource({
    required int page,
    PushHistoryFilter? filter,
  }) async {
    final effectiveFilter = filter ?? state.filter;
    final offset = page * _pageSize;

    if (effectiveFilter.hasActiveFilter) {
      // 使用搜索功能
      return await _historyManager.searchPushHistory(
        keyword: effectiveFilter.keyword,
        pushType: effectiveFilter.pushType,
        priority: effectiveFilter.priority,
        startTime: effectiveFilter.startDate,
        endTime: effectiveFilter.endDate,
        isRead: effectiveFilter.isRead,
        isClicked: effectiveFilter.isClicked,
        limit: _pageSize,
      );
    } else {
      // 使用常规分页
      return await _historyManager.getPushHistoryByTimeRange(
        startTime: effectiveFilter.startDate ??
            DateTime.now().subtract(const Duration(days: 90)),
        endTime: effectiveFilter.endDate,
        limit: _pageSize,
        offset: offset,
      );
    }
  }

  @override
  Future<void> close() {
    _historyManager.dispose();
    _analyticsService.dispose();
    return super.close();
  }

  /// 处理加载推送历史事件
  Future<void> _onLoadPushHistory(
      LoadPushHistory event, Emitter<PushHistoryState> emit) async {
    try {
      if (event.refresh) {
        emit(state.copyWith(status: PushHistoryStatus.loading));

        final records = await _fetchRecordsFromSource(
          page: 0,
          filter: event.filter,
        );

        emit(state.copyWith(
          status: PushHistoryStatus.loaded,
          records: records,
          hasReachedMax: records.length < _pageSize,
          currentPage: 1,
          filter: event.filter ?? state.filter,
          clearError: true,
        ));
      }
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to load push history', e);
      emit(state.copyWith(
        status: PushHistoryStatus.error,
        errorMessage: '加载推送历史失败: ${e.toString()}',
      ));
    }
  }

  /// 处理加载更多推送历史事件
  Future<void> _onLoadMorePushHistory(
      LoadMorePushHistory event, Emitter<PushHistoryState> emit) async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    try {
      emit(state.copyWith(isLoadingMore: true));

      final moreRecords =
          await _fetchRecordsFromSource(page: state.currentPage);

      final updatedRecords = List<PushHistoryRecord>.from(state.records)
        ..addAll(moreRecords);

      emit(state.copyWith(
        isLoadingMore: false,
        records: updatedRecords,
        currentPage: state.currentPage + 1,
        hasReachedMax: moreRecords.length < _pageSize,
      ));
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCubit: Failed to load more push history', e);
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: '加载更多推送失败: ${e.toString()}',
      ));
    }
  }

  /// 处理更新过滤器事件
  Future<void> _onUpdateFilter(
      UpdateFilter event, Emitter<PushHistoryState> emit) async {
    try {
      emit(state.copyWith(filter: event.filter));

      // 重新加载第一页
      add(LoadPushHistory(refresh: true, filter: event.filter));
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to update filter', e);
    }
  }

  /// 处理清除过滤器事件
  Future<void> _onClearFilter(
      ClearFilter event, Emitter<PushHistoryState> emit) async {
    try {
      const clearedFilter = PushHistoryFilter();
      emit(state.copyWith(filter: clearedFilter));

      // 重新加载第一页
      add(LoadPushHistory(refresh: true, filter: clearedFilter));
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to clear filter', e);
    }
  }

  /// 处理标记为已读事件
  Future<void> _onMarkAsRead(
      MarkAsRead event, Emitter<PushHistoryState> emit) async {
    try {
      final success = await _historyManager.markAsRead(event.recordId);
      if (success) {
        final updatedRecords = state.records.map((record) {
          if (record.id == event.recordId) {
            return record.markAsRead();
          }
          return record;
        }).toList();

        emit(state.copyWith(records: updatedRecords));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCubit: Failed to mark as read: ${event.recordId}', e);
    }
  }

  /// 处理批量标记为已读事件
  Future<void> _onMarkAllAsRead(
      MarkAllAsRead event, Emitter<PushHistoryState> emit) async {
    try {
      final unreadRecords = state.records.where((record) => !record.isRead);

      for (final record in unreadRecords) {
        await _historyManager.markAsRead(record.id);
      }

      final updatedRecords = state.records
          .map((record) => record.isRead ? record : record.markAsRead())
          .toList();

      emit(state.copyWith(records: updatedRecords));
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to mark all as read', e);
    }
  }

  /// 处理设置用户反馈事件
  Future<void> _onSetUserFeedback(
      SetUserFeedback event, Emitter<PushHistoryState> emit) async {
    try {
      final success =
          await _historyManager.setUserFeedback(event.recordId, event.feedback);
      if (success) {
        final updatedRecords = state.records.map((record) {
          if (record.id == event.recordId) {
            return record.withUserFeedback(event.feedback);
          }
          return record;
        }).toList();

        emit(state.copyWith(records: updatedRecords));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCubit: Failed to set user feedback: ${event.recordId}',
          e);
    }
  }

  /// 处理删除记录事件
  Future<void> _onDeleteRecord(
      DeleteRecord event, Emitter<PushHistoryState> emit) async {
    try {
      // 注意：当前的历史管理器不支持删除功能，这里只是更新UI状态
      // 实际实现需要扩展PushHistoryManager的删除功能
      final updatedRecords =
          state.records.where((record) => record.id != event.recordId).toList();

      emit(state.copyWith(records: updatedRecords));

      AppLogger.info(
          '✅ PushHistoryCubit: Record removed from UI: ${event.recordId}');
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCubit: Failed to delete record: ${event.recordId}', e);
    }
  }

  /// 处理清除错误事件
  Future<void> _onClearError(
      ClearError event, Emitter<PushHistoryState> emit) async {
    emit(state.copyWith(clearError: true));
  }

  /// 获取统计信息
  Future<PushStatistics> getStatistics({int days = 30}) async {
    try {
      return await _historyManager.getPushStatistics(days: days);
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to get statistics', e);
      return PushStatistics.empty();
    }
  }

  /// 获取效果分析
  Future<PushEffectivenessAnalysis> getEffectivenessAnalysis(
      {int days = 30}) async {
    try {
      return await _historyManager.getEffectivenessAnalysis(days: days);
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCubit: Failed to get effectiveness analysis', e);
      return PushEffectivenessAnalysis.empty();
    }
  }

  /// 获取每日统计
  Future<Map<String, DailyStats>> getDailyStatistics({int days = 30}) async {
    try {
      return await _historyManager.getDailyStatistics(days: days);
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to get daily statistics', e);
      return {};
    }
  }

  /// 导出历史数据
  Future<String> exportHistory() async {
    try {
      final records = state.records;
      final csvData = <String>[];

      // CSV 头部
      csvData.add('ID,推送类型,优先级,标题,内容,时间,已读,已点击,反馈,个性化评分,效果评分');

      // 数据行
      for (final record in records) {
        final row = [
          record.id,
          record.pushType,
          record.priority,
          record.title,
          record.content,
          record.timestamp.toIso8601String(),
          record.isRead.toString(),
          record.isClicked.toString(),
          record.userFeedback ?? '',
          record.personalizationScore.toString(),
          record.effectivenessScore.toString(),
        ];
        csvData.add(row.join(','));
      }

      return csvData.join('\n');
    } catch (e) {
      AppLogger.error('❌ PushHistoryCubit: Failed to export history', e);
      rethrow;
    }
  }

  /// 搜索记录
  Future<void> search({
    String? keyword,
    String? pushType,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRead,
    bool? isClicked,
  }) async {
    final filter = PushHistoryFilter(
      keyword: keyword,
      pushType: pushType,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      isRead: isRead,
      isClicked: isClicked,
    );

    add(UpdateFilter(filter));
  }

  /// 刷新数据
  Future<void> refresh() async {
    add(LoadPushHistory(refresh: true));
  }

  /// 获取记录详情
  PushHistoryRecord? getRecordById(String id) {
    try {
      return state.records.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取未读数量
  int get unreadCount {
    return state.records.where((record) => !record.isRead).length;
  }

  /// 获取已读数量
  int get readCount {
    return state.records.where((record) => record.isRead).length;
  }

  /// 获取点击数量
  int get clickedCount {
    return state.records.where((record) => record.isClicked).length;
  }

  /// 按类型分组统计
  Map<String, int> get recordsByType {
    final typeStats = <String, int>{};
    for (final record in state.records) {
      typeStats[record.pushType] = (typeStats[record.pushType] ?? 0) + 1;
    }
    return typeStats;
  }

  /// 按优先级分组统计
  Map<String, int> get recordsByPriority {
    final priorityStats = <String, int>{};
    for (final record in state.records) {
      priorityStats[record.priority] =
          (priorityStats[record.priority] ?? 0) + 1;
    }
    return priorityStats;
  }
}
