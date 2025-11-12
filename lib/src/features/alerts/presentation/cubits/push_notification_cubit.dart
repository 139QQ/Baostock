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
    bool clearError = false,
  }) {
    return PushNotificationState(
      status: status ?? this.status,
      pushHistory: pushHistory ?? this.pushHistory,
      unreadCount: unreadCount ?? this.unreadCount,
      statistics: statistics ?? this.statistics,
      engagementAnalysis: engagementAnalysis ?? this.engagementAnalysis,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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

/// 推送通知Bloc
class PushNotificationCubit
    extends Bloc<PushNotificationEvent, PushNotificationState> {
  PushNotificationCubit({
    PushHistoryManager? historyManager,
    PushAnalyticsService? analyticsService,
    AndroidPermissionService? permissionService,
  })  : _historyManager = historyManager ?? PushHistoryManager.instance,
        _analyticsService = analyticsService ?? PushAnalyticsService.instance,
        _permissionService =
            permissionService ?? AndroidPermissionService.instance,
        super(const PushNotificationState()) {
    on<PushNotificationEvent>(_onEvent);
  }

  final PushHistoryManager _historyManager;
  final PushAnalyticsService _analyticsService;
  final AndroidPermissionService _permissionService;

  static const int _pageSize = 20;

  /// 初始化
  Future<void> initialize() async {
    try {
      emit(state.copyWith(status: PushNotificationStatus.loading));

      // 初始化服务
      await _historyManager.initialize();
      await _analyticsService.initialize();

      // 检查通知权限
      await _checkNotificationPermission();

      // 加载初始数据
      await _loadInitialData();

      emit(state.copyWith(status: PushNotificationStatus.loaded));
    } catch (e) {
      AppLogger.error('❌ PushNotificationCubit: Failed to initialize', e);
      emit(state.copyWith(
        status: PushNotificationStatus.error,
        errorMessage: '初始化失败: ${e.toString()}',
      ));
    }
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    try {
      // 加载推送历史
      final recentPushes =
          await _historyManager.getRecentPushes(limit: _pageSize);
      final unreadCount = await _historyManager.getUnreadCount();

      emit(state.copyWith(
        pushHistory: recentPushes,
        unreadCount: unreadCount,
        currentPage: 1,
        hasReachedMax: recentPushes.length < _pageSize,
      ));
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to load initial data', e);
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _historyManager.dispose();
    _analyticsService.dispose();
    return super.close();
  }

  /// 处理事件
  Future<void> _onEvent(
      PushNotificationEvent event, Emitter<PushNotificationState> emit) async {
    try {
      if (event is LoadPushHistory) {
        await _onLoadPushHistory(event);
      } else if (event is LoadMorePushHistory) {
        await _onLoadMorePushHistory();
      } else if (event is MarkPushAsRead) {
        await _onMarkPushAsRead(event);
      } else if (event is MarkPushAsClicked) {
        await _onMarkPushAsClicked(event);
      } else if (event is SetUserFeedback) {
        await _onSetUserFeedback(event);
      } else if (event is LoadStatistics) {
        await _onLoadStatistics(event);
      } else if (event is LoadEngagementAnalysis) {
        await _onLoadEngagementAnalysis(event);
      } else if (event is RefreshPushStatus) {
        await _onRefreshPushStatus();
      } else if (event is ClearError) {
        emit(state.copyWith(clearError: true));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Error handling event: ${event.runtimeType}',
          e);
      emit(state.copyWith(
        status: PushNotificationStatus.error,
        errorMessage: '操作失败: ${e.toString()}',
      ));
    }
  }

  /// 处理加载推送历史事件
  Future<void> _onLoadPushHistory(LoadPushHistory event) async {
    try {
      emit(state.copyWith(status: PushNotificationStatus.loading));

      List<PushHistoryRecord> pushes;

      if (event.refresh) {
        // 刷新：重新加载第一页
        if (event.searchKeyword != null ||
            event.filterType != null ||
            event.filterPriority != null) {
          // 搜索模式
          pushes = await _historyManager.searchPushHistory(
            keyword: event.searchKeyword,
            pushType: event.filterType,
            priority: event.filterPriority,
            limit: _pageSize,
          );
        } else {
          // 普通模式
          pushes = await _historyManager.getRecentPushes(limit: _pageSize);
        }

        final unreadCount = await _historyManager.getUnreadCount();

        emit(state.copyWith(
          status: PushNotificationStatus.loaded,
          pushHistory: pushes,
          unreadCount: unreadCount,
          currentPage: 1,
          hasReachedMax: pushes.length < _pageSize,
          searchKeyword: event.searchKeyword,
          filterType: event.filterType,
          filterPriority: event.filterPriority,
          clearError: true,
        ));
      } else {
        // 保持当前状态，只更新过滤条件
        emit(state.copyWith(
          searchKeyword: event.searchKeyword,
          filterType: event.filterType,
          filterPriority: event.filterPriority,
        ));

        // 触发新的加载
        add(LoadPushHistory(refresh: true));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to load push history', e);
      emit(state.copyWith(
        status: PushNotificationStatus.error,
        errorMessage: '加载推送历史失败: ${e.toString()}',
      ));
    }
  }

  /// 处理加载更多推送历史事件
  Future<void> _onLoadMorePushHistory() async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    try {
      emit(state.copyWith(isLoadingMore: true));

      List<PushHistoryRecord> morePushes;

      if (state.searchKeyword != null ||
          state.filterType != null ||
          state.filterPriority != null) {
        // 搜索模式
        morePushes = await _historyManager.searchPushHistory(
          keyword: state.searchKeyword,
          pushType: state.filterType,
          priority: state.filterPriority,
          limit: _pageSize,
        );
      } else {
        // 普通模式
        morePushes = await _historyManager.getRecentPushes(
          limit: _pageSize,
          onlyUnread: false,
        );
      }

      final updatedHistory = List<PushHistoryRecord>.from(state.pushHistory)
        ..addAll(morePushes);

      emit(state.copyWith(
        isLoadingMore: false,
        pushHistory: updatedHistory,
        currentPage: state.currentPage + 1,
        hasReachedMax: morePushes.length < _pageSize,
      ));
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to load more push history', e);
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: '加载更多推送失败: ${e.toString()}',
      ));
    }
  }

  /// 处理标记推送为已读事件
  Future<void> _onMarkPushAsRead(MarkPushAsRead event) async {
    try {
      final success = await _historyManager.markAsRead(event.pushId);
      if (success) {
        // 更新本地状态
        final updatedHistory = state.pushHistory.map((push) {
          if (push.id == event.pushId) {
            return push.markAsRead();
          }
          return push;
        }).toList();

        final newUnreadCount =
            state.unreadCount > 0 ? state.unreadCount - 1 : 0;

        emit(state.copyWith(
          pushHistory: updatedHistory,
          unreadCount: newUnreadCount,
        ));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to mark push as read: ${event.pushId}',
          e);
    }
  }

  /// 处理标记推送为已点击事件
  Future<void> _onMarkPushAsClicked(MarkPushAsClicked event) async {
    try {
      final success = await _historyManager.markAsClicked(event.pushId);
      if (success) {
        // 更新本地状态
        final updatedHistory = state.pushHistory.map((push) {
          if (push.id == event.pushId) {
            return push.markAsClicked();
          }
          return push;
        }).toList();

        emit(state.copyWith(pushHistory: updatedHistory));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to mark push as clicked: ${event.pushId}',
          e);
    }
  }

  /// 处理设置用户反馈事件
  Future<void> _onSetUserFeedback(SetUserFeedback event) async {
    try {
      final success =
          await _historyManager.setUserFeedback(event.pushId, event.feedback);
      if (success) {
        // 更新本地状态
        final updatedHistory = state.pushHistory.map((push) {
          if (push.id == event.pushId) {
            return push.withUserFeedback(event.feedback);
          }
          return push;
        }).toList();

        emit(state.copyWith(pushHistory: updatedHistory));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to set user feedback: ${event.pushId}',
          e);
    }
  }

  /// 处理加载统计数据事件
  Future<void> _onLoadStatistics(LoadStatistics event) async {
    try {
      final statistics =
          await _historyManager.getPushStatistics(days: event.days);
      emit(state.copyWith(statistics: statistics));
    } catch (e) {
      AppLogger.error('❌ PushNotificationCubit: Failed to load statistics', e);
    }
  }

  /// 处理加载用户参与度分析事件
  Future<void> _onLoadEngagementAnalysis(LoadEngagementAnalysis event) async {
    try {
      final engagementAnalysis =
          await _analyticsService.getUserEngagementAnalysis(days: event.days);
      emit(state.copyWith(engagementAnalysis: engagementAnalysis));
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to load engagement analysis', e);
    }
  }

  /// 处理刷新推送状态事件
  Future<void> _onRefreshPushStatus() async {
    try {
      // 重新加载未读数量
      final unreadCount = await _historyManager.getUnreadCount();

      // 如果有搜索或过滤条件，重新搜索
      if (state.searchKeyword != null ||
          state.filterType != null ||
          state.filterPriority != null) {
        add(LoadPushHistory(
          refresh: true,
          searchKeyword: state.searchKeyword,
          filterType: state.filterType,
          filterPriority: state.filterPriority,
        ));
      } else {
        // 否则只刷新未读数量
        emit(state.copyWith(unreadCount: unreadCount));
      }
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to refresh push status', e);
    }
  }

  /// 获取推送详情
  Future<PushHistoryRecord?> getPushDetails(String pushId) async {
    try {
      return await _historyManager.getPushHistory(pushId);
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to get push details: $pushId', e);
      return null;
    }
  }

  /// 搜索推送
  Future<void> searchPushes({
    String? keyword,
    String? type,
    String? priority,
  }) async {
    add(LoadPushHistory(
      refresh: true,
      searchKeyword: keyword,
      filterType: type,
      filterPriority: priority,
    ));
  }

  /// 清除过滤条件
  void clearFilters() {
    add(LoadPushHistory(refresh: true));
  }

  /// 批量标记为已读
  Future<void> markAllAsRead() async {
    try {
      final unreadPushes = state.pushHistory.where((push) => !push.isRead);
      for (final push in unreadPushes) {
        await _historyManager.markAsRead(push.id);
      }

      // 更新本地状态
      final updatedHistory = state.pushHistory
          .map((push) => push.isRead ? push : push.markAsRead())
          .toList();

      emit(state.copyWith(
        pushHistory: updatedHistory,
        unreadCount: 0,
      ));
    } catch (e) {
      AppLogger.error('❌ PushNotificationCubit: Failed to mark all as read', e);
    }
  }

  /// 获取推送效果预测
  Future<PushEffectivenessPrediction> predictEffectiveness({
    required String pushType,
    required String priority,
    required String title,
    required String content,
    String? templateId,
    DateTime? scheduledTime,
  }) async {
    try {
      return await _analyticsService.predictPushEffectiveness(
        pushType: pushType,
        priority: priority,
        title: title,
        content: content,
        templateId: templateId,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to predict effectiveness', e);
      return PushEffectivenessPrediction.empty();
    }
  }

  /// 获取最佳推送时间建议
  Future<OptimalTimingRecommendations> getOptimalTiming() async {
    try {
      return await _analyticsService.getOptimalTimingRecommendations();
    } catch (e) {
      AppLogger.error(
          '❌ PushNotificationCubit: Failed to get optimal timing', e);
      return OptimalTimingRecommendations.empty();
    }
  }

  /// 检查通知权限状态
  Future<void> _checkNotificationPermission() async {
    try {
      final hasPermission =
          await _permissionService.hasNotificationPermission();
      final permissionResult =
          await _permissionService.checkPermissionCompleteness();

      emit(state.copyWith(
        hasNotificationPermission: hasPermission,
        canRequestNotifications: permissionResult.canRequestAll,
      ));

      AppLogger.info(
          '通知权限状态: $hasPermission, 可请求: ${permissionResult.canRequestAll}');
    } catch (e) {
      AppLogger.error('检查通知权限失败', e);
    }
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      emit(state.copyWith(status: PushNotificationStatus.loading));

      final status = await _permissionService.requestNotificationPermission();
      final hasPermission = status == PermissionStatus.granted;

      await _checkNotificationPermission(); // 重新检查权限状态

      emit(state.copyWith(status: PushNotificationStatus.loaded));

      return hasPermission;
    } catch (e) {
      AppLogger.error('请求通知权限失败', e);
      emit(state.copyWith(
        status: PushNotificationStatus.error,
        errorMessage: '请求通知权限失败: ${e.toString()}',
      ));
      return false;
    }
  }

  /// 打开应用设置
  Future<bool> openAppSettings() async {
    try {
      return await _permissionService.openAppSettings();
    } catch (e) {
      AppLogger.error('打开应用设置失败', e);
      return false;
    }
  }

  /// 获取权限完整性检查结果
  Future<PermissionCheckResult> getPermissionStatus() async {
    try {
      return await _permissionService.checkPermissionCompleteness();
    } catch (e) {
      AppLogger.error('获取权限状态失败', e);
      return PermissionCheckResult(
        isComplete: false,
        missingPermissions: [],
        canRequestAll: false,
        recommendations: ['检查权限状态时发生错误'],
      );
    }
  }
}
