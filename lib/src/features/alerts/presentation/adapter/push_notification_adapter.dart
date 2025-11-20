import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/state/feature_toggle_service.dart';
import '../../data/managers/push_history_manager.dart';
import '../../data/services/android_permission_service.dart';
import '../../data/services/push_analytics_service.dart';
import '../bloc/push_notification_bloc.dart';
import '../cubits/push_notification_cubit.dart' as cubit;

/// 推送通知状态管理适配器
///
/// 根据Feature Toggle配置，自动选择使用Cubit或BLoC模式
/// 提供统一的接口供UI层使用，屏蔽底层实现差异
class PushNotificationAdapter {
  const PushNotificationAdapter._();

  /// 创建推送通知状态管理器（Cubit或BLoC）
  static Widget create({
    required Widget Function(BuildContext context) builder,
    cubit.PushNotificationCubit? cubit,
    PushNotificationBloc? bloc,
  }) {
    return Builder(
      builder: (context) {
        final featureToggle = FeatureToggleService.instance;
        final useBloc = featureToggle.useBlocMode('alerts');

        if (useBloc) {
          debugPrint('🔄 PushNotificationAdapter: 使用BLoC模式');
          return BlocProvider(
            create: (context) => bloc ?? _createDefaultBloc(context),
            child: Builder(builder: builder),
          );
        } else {
          debugPrint('🔄 PushNotificationAdapter: 使用Cubit模式');
          return BlocProvider(
            create: (context) => cubit ?? _createDefaultCubit(context),
            child: Builder(builder: builder),
          );
        }
      },
    );
  }

  /// 获取推送通知状态
  static dynamic getState(BuildContext context) {
    final featureToggle = FeatureToggleService.instance;
    final useBloc = featureToggle.useBlocMode('alerts');

    if (useBloc) {
      return context.watch<PushNotificationBloc>().state;
    } else {
      return context.watch<cubit.PushNotificationCubit>().state;
    }
  }

  /// 添加事件（仅对BLoC有效）
  static void addEvent(BuildContext context, dynamic event) {
    final featureToggle = FeatureToggleService.instance;
    final useBloc = featureToggle.useBlocMode('alerts');

    if (useBloc) {
      context.read<PushNotificationBloc>().add(event);
    } else {
      debugPrint('⚠️ PushNotificationAdapter: Cubit模式不支持事件，请直接调用方法');
    }
  }

  /// 调用方法（统一接口）
  static Future<void> callMethod(
    BuildContext context,
    String methodName, {
    dynamic arg1,
    dynamic arg2,
  }) async {
    final featureToggle = FeatureToggleService.instance;
    final useBloc = featureToggle.useBlocMode('alerts');

    if (useBloc) {
      final bloc = context.read<PushNotificationBloc>();
      switch (methodName) {
        case 'requestNotificationPermission':
          await bloc.requestNotificationPermission();
          break;
        case 'clearAllHistory':
          await bloc.clearAllHistory();
          break;
        default:
          debugPrint('⚠️ PushNotificationAdapter: BLoC不支持方法 $methodName');
      }
    } else {
      final cubitNotifier = context.read<cubit.PushNotificationCubit>();
      switch (methodName) {
        case 'requestNotificationPermission':
          await cubitNotifier.requestNotificationPermission();
          break;
        default:
          debugPrint('⚠️ PushNotificationAdapter: Cubit不支持方法 $methodName');
      }
    }
  }

  /// 创建默认的Cubit实例
  static cubit.PushNotificationCubit _createDefaultCubit(BuildContext context) {
    // 这里需要从依赖注入容器获取必要的服务
    // 暂时使用简化的构造方式
    return cubit.PushNotificationCubit(
      historyManager: PushHistoryManager.instance,
      analyticsService: PushAnalyticsService.instance,
      permissionService: AndroidPermissionService.instance,
    );
  }

  /// 创建默认的BLoC实例
  static PushNotificationBloc _createDefaultBloc(BuildContext context) {
    // 这里需要从依赖注入容器获取必要的服务
    // 暂时使用简化的构造方式
    return PushNotificationBloc(
      pushHistoryManager: PushHistoryManager.instance,
      analyticsService: PushAnalyticsService.instance,
      permissionService: AndroidPermissionService.instance,
    );
  }
}

/// 推送通知状态适配器
///
/// 提供统一的状态访问接口，兼容Cubit和BLoC
class PushNotificationStateAdapter {
  const PushNotificationStateAdapter._();

  /// 获取状态值
  static T getStateValue<T>(BuildContext context, String propertyName) {
    final featureToggle = FeatureToggleService.instance;
    final useBloc = featureToggle.useBlocMode('alerts');
    dynamic state;

    if (useBloc) {
      state = context.watch<PushNotificationBloc>().state;
    } else {
      state = context.watch<cubit.PushNotificationCubit>().state;
    }

    switch (propertyName) {
      case 'status':
        return state.status as T;
      case 'pushHistory':
        return state.pushHistory as T;
      case 'unreadCount':
        return state.unreadCount as T;
      case 'statistics':
        return state.statistics as T;
      case 'engagementAnalysis':
        return state.engagementAnalysis as T;
      case 'errorMessage':
        return state.errorMessage as T;
      case 'isLoadingMore':
        return state.isLoadingMore as T;
      case 'hasReachedMax':
        return state.hasReachedMax as T;
      case 'currentPage':
        return state.currentPage as T;
      case 'searchKeyword':
        return state.searchKeyword as T;
      case 'filterType':
        return state.filterType as T;
      case 'filterPriority':
        return state.filterPriority as T;
      case 'hasNotificationPermission':
        return state.hasNotificationPermission as T;
      case 'canRequestNotifications':
        return state.canRequestNotifications as T;
      default:
        throw ArgumentError('未知属性: $propertyName');
    }
  }

  /// 检查是否正在加载
  static bool isLoading(BuildContext context) {
    final featureToggle = FeatureToggleService.instance;
    final useBloc = featureToggle.useBlocMode('alerts');
    dynamic state;

    if (useBloc) {
      state = context.watch<PushNotificationBloc>().state;
    } else {
      state = context.watch<cubit.PushNotificationCubit>().state;
    }

    return state.status == PushNotificationStatus.loading;
  }

  /// 检查是否有错误
  static bool hasError(BuildContext context) {
    final featureToggle = FeatureToggleService.instance;
    final useBloc = featureToggle.useBlocMode('alerts');
    dynamic state;

    if (useBloc) {
      state = context.watch<PushNotificationBloc>().state;
    } else {
      state = context.watch<cubit.PushNotificationCubit>().state;
    }

    return state.status == PushNotificationStatus.error;
  }

  /// 获取错误消息
  static String? getErrorMessage(BuildContext context) {
    return getStateValue<String?>(context, 'errorMessage');
  }

  /// 获取未读数量
  static int getUnreadCount(BuildContext context) {
    return getStateValue<int>(context, 'unreadCount');
  }

  /// 获取推送历史
  static List getPushHistory(BuildContext context) {
    return getStateValue<List>(context, 'pushHistory');
  }
}
