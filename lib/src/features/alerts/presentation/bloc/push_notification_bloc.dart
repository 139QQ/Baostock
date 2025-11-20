import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/managers/push_history_manager.dart';
import '../../data/models/push_history_record.dart';
import '../../data/services/push_analytics_service.dart';
import '../../data/services/android_permission_service.dart';
import '../../../../core/utils/logger.dart';

/// 推送通知状态
enum PushNotificationStatus {
  initial,
  loading,
  loaded,
  error,
  sending,
  sent,
  failed,
}

/// 推送通知状态
class PushNotificationState extends Equatable {
  final PushNotificationStatus status;
  final List<PushHistoryRecord> pushHistory;
  final int unreadCount;
  final PushStatistics? statistics;
  final UserEngagementAnalysis? engagementAnalysis;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchKeyword;
  final String? filterType;
  final String? filterPriority;
  final bool hasNotificationPermission;
  final bool canRequestNotifications;

  const PushNotificationState({
    this.status = PushNotificationStatus.initial,
    this.pushHistory = const [],
    this.unreadCount = 0,
    this.statistics,
    this.engagementAnalysis,
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.searchKeyword,
    this.filterType,
    this.filterPriority,
    this.hasNotificationPermission = false,
    this.canRequestNotifications = true,
  });

  PushNotificationState copyWith({
    PushNotificationStatus? status,
    List<PushHistoryRecord>? pushHistory,
    int? unreadCount,
    PushStatistics? statistics,
    UserEngagementAnalysis? engagementAnalysis,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
    String? searchKeyword,
    String? filterType,
    String? filterPriority,
    bool? hasNotificationPermission,
    bool? canRequestNotifications,
  }) {
    return PushNotificationState(
      status: status ?? this.status,
      pushHistory: pushHistory ?? this.pushHistory,
      unreadCount: unreadCount ?? this.unreadCount,
      statistics: statistics ?? this.statistics,
      engagementAnalysis: engagementAnalysis ?? this.engagementAnalysis,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      filterType: filterType ?? this.filterType,
      filterPriority: filterPriority ?? this.filterPriority,
      hasNotificationPermission:
          hasNotificationPermission ?? this.hasNotificationPermission,
      canRequestNotifications:
          canRequestNotifications ?? this.canRequestNotifications,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pushHistory,
        unreadCount,
        statistics,
        engagementAnalysis,
        errorMessage,
        isLoadingMore,
        hasReachedMax,
        currentPage,
        searchKeyword,
        filterType,
        filterPriority,
        hasNotificationPermission,
        canRequestNotifications,
      ];
}

/// 推送通知事件
abstract class PushNotificationEvent extends Equatable {
  const PushNotificationEvent();

  @override
  List<Object?> get props => [];
}

/// 加载推送历史
class LoadPushHistory extends PushNotificationEvent {
  final bool refresh;
  final String? searchKeyword;
  final String? filterType;
  final String? filterPriority;

  const LoadPushHistory({
    this.refresh = false,
    this.searchKeyword,
    this.filterType,
    this.filterPriority,
  });

  @override
  List<Object?> get props =>
      [refresh, searchKeyword, filterType, filterPriority];
}

/// 加载更多推送历史
class LoadMorePushHistory extends PushNotificationEvent {}

/// 标记推送为已读
class MarkPushAsRead extends PushNotificationEvent {
  final String pushId;

  const MarkPushAsRead(this.pushId);

  @override
  List<Object?> get props => [pushId];
}

/// 标记推送为已点击
class MarkPushAsClicked extends PushNotificationEvent {
  final String pushId;

  const MarkPushAsClicked(this.pushId);

  @override
  List<Object?> get props => [pushId];
}

/// 设置用户反馈
class SetUserFeedback extends PushNotificationEvent {
  final String pushId;
  final String feedback;

  const SetUserFeedback(this.pushId, this.feedback);

  @override
  List<Object?> get props => [pushId, feedback];
}

/// 加载统计数据
class LoadStatistics extends PushNotificationEvent {
  final int days;

  const LoadStatistics({this.days = 30});

  @override
  List<Object?> get props => [days];
}

/// 加载用户参与度分析
class LoadEngagementAnalysis extends PushNotificationEvent {
  final int days;

  const LoadEngagementAnalysis({this.days = 30});

  @override
  List<Object?> get props => [days];
}

/// 刷新推送状态
class RefreshPushStatus extends PushNotificationEvent {}

/// 清除错误
class ClearError extends PushNotificationEvent {}

/// 推送通知BLoC
class PushNotificationBloc
    extends Bloc<PushNotificationEvent, PushNotificationState> {
  final PushHistoryManager _pushHistoryManager;
  final PushAnalyticsService _analyticsService;
  final AndroidPermissionService _permissionService;

  PushNotificationBloc({
    required PushHistoryManager pushHistoryManager,
    required PushAnalyticsService analyticsService,
    required AndroidPermissionService permissionService,
  })  : _pushHistoryManager = pushHistoryManager,
        _analyticsService = analyticsService,
        _permissionService = permissionService,
        super(const PushNotificationState()) {
    on<LoadPushHistory>(_onLoadPushHistory);
    on<LoadMorePushHistory>(_onLoadMorePushHistory);
    on<MarkPushAsRead>(_onMarkPushAsRead);
    on<MarkPushAsClicked>(_onMarkPushAsClicked);
    on<SetUserFeedback>(_onSetUserFeedback);
    on<LoadStatistics>(_onLoadStatistics);
    on<LoadEngagementAnalysis>(_onLoadEngagementAnalysis);
    on<RefreshPushStatus>(_onRefreshPushStatus);
    on<ClearError>(_onClearError);
  }

  /// 处理加载推送历史事件
  Future<void> _onLoadPushHistory(
    LoadPushHistory event,
    Emitter<PushNotificationState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: PushNotificationStatus.loading,
        errorMessage: null,
        searchKeyword: event.searchKeyword,
        filterType: event.filterType,
        filterPriority: event.filterPriority,
      ));

      final page = event.refresh ? 0 : state.currentPage;
      final result = await _pushHistoryManager.getPushHistoryByTimeRange(
        limit: 20,
        offset: page * 20,
      );

      final hasReachedMax = result.length < 20; // 假设每页20条

      emit(state.copyWith(
        status: PushNotificationStatus.loaded,
        pushHistory: event.refresh ? result : [...state.pushHistory, ...result],
        unreadCount: await _pushHistoryManager.getUnreadCount(),
        hasReachedMax: hasReachedMax,
        currentPage: page + 1,
        isLoadingMore: false,
      ));
    } catch (e) {
      AppLogger.error('加载推送历史失败', e);
      emit(state.copyWith(
        status: PushNotificationStatus.error,
        errorMessage: '加载推送历史失败: $e',
      ));
    }
  }

  /// 处理加载更多推送历史事件
  Future<void> _onLoadMorePushHistory(
    LoadMorePushHistory event,
    Emitter<PushNotificationState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    emit(state.copyWith(isLoadingMore: true));

    add(LoadPushHistory(
      refresh: false,
      searchKeyword: state.searchKeyword,
      filterType: state.filterType,
      filterPriority: state.filterPriority,
    ));
  }

  /// 处理标记推送为已读事件
  Future<void> _onMarkPushAsRead(
    MarkPushAsRead event,
    Emitter<PushNotificationState> emit,
  ) async {
    try {
      await _pushHistoryManager.markAsRead(event.pushId);

      final updatedHistory = state.pushHistory.map((record) {
        return record.id == event.pushId
            ? record.copyWith(isRead: true)
            : record;
      }).toList();

      final unreadCount = await _pushHistoryManager.getUnreadCount();

      emit(state.copyWith(
        pushHistory: updatedHistory,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      AppLogger.error('标记推送为已读失败', e);
    }
  }

  /// 处理标记推送为已点击事件
  Future<void> _onMarkPushAsClicked(
    MarkPushAsClicked event,
    Emitter<PushNotificationState> emit,
  ) async {
    try {
      await _pushHistoryManager.markAsClicked(event.pushId);

      final updatedHistory = state.pushHistory.map((record) {
        return record.id == event.pushId
            ? record.copyWith(isClicked: true)
            : record;
      }).toList();

      emit(state.copyWith(pushHistory: updatedHistory));
    } catch (e) {
      AppLogger.error('标记推送为已点击失败', e);
    }
  }

  /// 处理设置用户反馈事件
  Future<void> _onSetUserFeedback(
    SetUserFeedback event,
    Emitter<PushNotificationState> emit,
  ) async {
    try {
      await _pushHistoryManager.setUserFeedback(event.pushId, event.feedback);

      final updatedHistory = state.pushHistory.map((record) {
        return record.id == event.pushId
            ? record.copyWith(userFeedback: event.feedback)
            : record;
      }).toList();

      emit(state.copyWith(pushHistory: updatedHistory));
    } catch (e) {
      AppLogger.error('设置用户反馈失败', e);
    }
  }

  /// 处理加载统计数据事件
  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<PushNotificationState> emit,
  ) async {
    try {
      final statistics =
          await _pushHistoryManager.getPushStatistics(days: event.days);

      emit(state.copyWith(statistics: statistics));
    } catch (e) {
      AppLogger.error('加载统计数据失败', e);
    }
  }

  /// 处理加载用户参与度分析事件
  Future<void> _onLoadEngagementAnalysis(
    LoadEngagementAnalysis event,
    Emitter<PushNotificationState> emit,
  ) async {
    try {
      final analysis =
          await _analyticsService.getUserEngagementAnalysis(days: event.days);

      emit(state.copyWith(engagementAnalysis: analysis));
    } catch (e) {
      AppLogger.error('加载用户参与度分析失败', e);
    }
  }

  /// 处理刷新推送状态事件
  Future<void> _onRefreshPushStatus(
    RefreshPushStatus event,
    Emitter<PushNotificationState> emit,
  ) async {
    try {
      // 检查通知权限
      final notificationPermission = await Permission.notification.status;
      final hasPermission = notificationPermission.isGranted;

      emit(state.copyWith(
        hasNotificationPermission: hasPermission,
        canRequestNotifications: !notificationPermission.isPermanentlyDenied,
      ));

      // 重新加载推送历史
      add(LoadPushHistory(
        refresh: true,
        searchKeyword: state.searchKeyword,
        filterType: state.filterType,
        filterPriority: state.filterPriority,
      ));
    } catch (e) {
      AppLogger.error('刷新推送状态失败', e);
    }
  }

  /// 处理清除错误事件
  void _onClearError(
    ClearError event,
    Emitter<PushNotificationState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }

  /// 请求通知权限
  Future<void> requestNotificationPermission() async {
    try {
      final result = await _permissionService.requestNotificationPermission();

      // 这里可以通过事件或者状态更新来反映权限变化
      add(RefreshPushStatus());
    } catch (e) {
      AppLogger.error('请求通知权限失败', e);
    }
  }

  /// 清除所有推送历史
  Future<void> clearAllHistory() async {
    try {
      // 临时实现：通过缓存管理器清除
      // TODO: 等PushHistoryManager添加clearAllHistory方法后再更新
      AppLogger.info('清除推送历史（临时实现）');

      // 刷新状态
      add(LoadPushHistory(refresh: true));
    } catch (e) {
      AppLogger.error('清除推送历史失败', e);
    }
  }
}
