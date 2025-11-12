import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/processors/fund_nav_data_manager.dart';
import '../../data/processors/nav_change_detector.dart';
import '../../models/fund_nav_data.dart';
import '../../../../core/state/global_cubit_manager.dart';

/// 基金净值状态
abstract class FundNavState extends Equatable {
  const FundNavState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class FundNavInitial extends FundNavState {
  const FundNavInitial();

  @override
  List<Object?> get props => [];
}

/// 加载中状态
class FundNavLoading extends FundNavState {
  const FundNavLoading();

  @override
  List<Object?> get props => [];
}

/// 加载成功状态
class FundNavLoaded extends FundNavState {
  final Map<String, FundNavData> navData;
  final Map<String, NavChangeInfo?> changeInfo;
  final FundNavStatus status;
  final DateTime lastUpdate;
  final String? errorMessage;

  const FundNavLoaded({
    required this.navData,
    required this.changeInfo,
    required this.status,
    required this.lastUpdate,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        navData,
        changeInfo,
        status,
        lastUpdate,
        errorMessage,
      ];

  FundNavLoaded copyWith({
    Map<String, FundNavData>? navData,
    Map<String, NavChangeInfo?>? changeInfo,
    FundNavStatus? status,
    DateTime? lastUpdate,
    String? errorMessage,
  }) {
    return FundNavLoaded(
      navData: navData ?? this.navData,
      changeInfo: changeInfo ?? this.changeInfo,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      errorMessage: errorMessage,
    );
  }
}

/// 加载失败状态
class FundNavError extends FundNavState {
  final String errorMessage;
  final DateTime timestamp;

  const FundNavError({
    required this.errorMessage,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [errorMessage, timestamp];
}

/// 轮询状态
enum FundNavStatus {
  /// 空闲
  idle('空闲'),

  /// 轮询中
  polling('轮询中'),

  /// 已暂停
  paused('已暂停'),

  /// 错误
  error('错误'),

  /// 正在更新
  updating('更新中');

  const FundNavStatus(this.description);
  final String description;

  /// 是否为活跃状态
  bool get isActive =>
      this == FundNavStatus.polling || this == FundNavStatus.updating;
}

/// 基金净值事件
abstract class FundNavEvent extends Equatable {
  const FundNavEvent();

  @override
  List<Object?> get props => [];
}

/// 添加基金代码
class AddFundCode extends FundNavEvent {
  final String fundCode;

  const AddFundCode(this.fundCode);

  @override
  List<Object?> get props => [fundCode];
}

/// 移除基金代码
class RemoveFundCode extends FundNavEvent {
  final String fundCode;

  const RemoveFundCode(this.fundCode);

  @override
  List<Object?> get props => [fundCode];
}

/// 批量添加基金代码
class AddFundCodes extends FundNavEvent {
  final List<String> fundCodes;

  const AddFundCodes(this.fundCodes);

  @override
  List<Object?> get props => [fundCodes];
}

/// 开始轮询
class StartPolling extends FundNavEvent {
  const StartPolling();

  @override
  List<Object?> get props => [];
}

/// 停止轮询
class StopPolling extends FundNavEvent {
  const StopPolling();

  @override
  List<Object?> get props => [];
}

/// 暂停轮询
class PausePolling extends FundNavEvent {
  const PausePolling();

  @override
  List<Object?> get props => [];
}

/// 恢复轮询
class ResumePolling extends FundNavEvent {
  const ResumePolling();

  @override
  List<Object?> get props => [];
}

/// 设置轮询间隔
class SetPollingInterval extends FundNavEvent {
  final Duration interval;

  const SetPollingInterval(this.interval);

  @override
  List<Object?> get props => [interval];
}

/// 刷新数据
class RefreshData extends FundNavEvent {
  final List<String>? fundCodes;

  const RefreshData({this.fundCodes});

  @override
  List<Object?> get props => [fundCodes];
}

/// 清除错误
class ClearError extends FundNavEvent {
  const ClearError();

  @override
  List<Object?> get props => [];
}

/// 重置状态
class ResetState extends FundNavEvent {
  const ResetState();

  @override
  List<Object?> get props => [];
}

/// 基金净值Cubit
///
/// 管理基金净值数据的准实时状态
/// 集成FundNavDataManager和GlobalCubitManager
class FundNavCubit extends Bloc<FundNavEvent, FundNavState> {
  final FundNavDataManager _navManager;
  final GlobalCubitManager _globalCubitManager;

  StreamSubscription<FundNavUpdateEvent>? _navUpdateSubscription;
  Set<String> _trackedFundCodes = {};

  Duration _pollingInterval = const Duration(seconds: 30);
  DateTime? _lastUpdateTime;
  String? _lastErrorMessage;

  FundNavCubit({
    FundNavDataManager? navManager,
    GlobalCubitManager? globalCubitManager,
  })  : _navManager = navManager ?? FundNavDataManager(),
        _globalCubitManager = globalCubitManager ?? GlobalCubitManager.instance,
        super(const FundNavInitial()) {
    _initialize();

    // 注册事件处理器
    on<AddFundCode>(_onAddFundCode);
    on<RemoveFundCode>(_onRemoveFundCode);
    on<AddFundCodes>(_onAddFundCodes);
    on<StartPolling>(_onStartPolling);
    on<StopPolling>(_onStopPolling);
    on<PausePolling>(_onPausePolling);
    on<ResumePolling>(_onResumePolling);
    on<SetPollingInterval>(_onSetPollingInterval);
    on<RefreshData>(_onRefreshData);
    on<ClearError>(_onClearError);
    on<ResetState>(_onResetState);
  }

  /// 初始化Cubit
  void _initialize() {
    // 监听净值更新事件
    _navUpdateSubscription = _navManager.updateStream.listen(
      _handleNavUpdate,
      onError: _handleError,
    );
  }

  /// 处理净值更新
  void _handleNavUpdate(FundNavUpdateEvent updateEvent) {
    final fundCode = updateEvent.fundCode;

    if (!_trackedFundCodes.contains(fundCode)) {
      return;
    }

    final currentState = state;
    if (currentState is FundNavLoaded) {
      final updatedNavData =
          Map<String, FundNavData>.from(currentState.navData);
      final updatedChangeInfo =
          Map<String, NavChangeInfo?>.from(currentState.changeInfo);

      // 更新数据
      updatedNavData[fundCode] = updateEvent.currentNav;
      updatedChangeInfo[fundCode] = updateEvent.changeInfo;

      // 更新状态
      emit(FundNavLoaded(
        navData: updatedNavData,
        changeInfo: updatedChangeInfo,
        status: FundNavStatus.polling,
        lastUpdate: DateTime.now(),
        errorMessage: _lastErrorMessage,
      ));

      // 清除错误信息
      _lastErrorMessage = null;

      // 记录更新时间
      _lastUpdateTime = DateTime.now();
    }
  }

  /// 处理错误
  void _handleError(dynamic error) {
    _lastErrorMessage = error.toString();

    final currentState = state;
    if (currentState is FundNavLoaded) {
      emit(currentState.copyWith(
        status: FundNavStatus.error,
        errorMessage: _lastErrorMessage,
      ));
    } else {
      emit(FundNavError(
        errorMessage: _lastErrorMessage!,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 处理添加基金代码
  Future<void> _onAddFundCode(
      AddFundCode event, Emitter<FundNavState> emit) async {
    try {
      emit(const FundNavLoading());

      await _navManager.addFundCode(event.fundCode);
      _trackedFundCodes.add(event.fundCode);

      // 获取初始数据
      final initialData = await _navManager.getCachedNavData(event.fundCode);
      final navData = <String, FundNavData>{};
      final changeInfo = <String, NavChangeInfo?>{};

      if (initialData != null) {
        navData[event.fundCode] = initialData;
      }

      for (final fundCode in _trackedFundCodes) {
        if (fundCode != event.fundCode) {
          final currentState = state;
          if (currentState is FundNavLoaded) {
            final existingData = currentState.navData[fundCode];
            if (existingData != null) {
              navData[fundCode] = existingData;
              final existingChangeInfo = currentState.changeInfo[fundCode];
              changeInfo[fundCode] = existingChangeInfo;
            }
          }
        }
      }

      emit(FundNavLoaded(
        navData: navData,
        changeInfo: changeInfo,
        status: FundNavStatus.polling,
        lastUpdate: DateTime.now(),
      ));
    } catch (e) {
      _lastErrorMessage = e.toString();
      emit(FundNavError(
        errorMessage: _lastErrorMessage!,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 处理移除基金代码
  Future<void> _onRemoveFundCode(
      RemoveFundCode event, Emitter<FundNavState> emit) async {
    try {
      await _navManager.removeFundCode(event.fundCode);
      _trackedFundCodes.remove(event.fundCode);

      final currentState = state;
      if (currentState is FundNavLoaded) {
        final updatedNavData =
            Map<String, FundNavData>.from(currentState.navData);
        final updatedChangeInfo =
            Map<String, NavChangeInfo?>.from(currentState.changeInfo);

        updatedNavData.remove(event.fundCode);
        updatedChangeInfo.remove(event.fundCode);

        if (updatedNavData.isEmpty) {
          emit(FundNavInitial());
        } else {
          emit(currentState.copyWith(
            navData: updatedNavData,
            changeInfo: updatedChangeInfo,
          ));
        }
      }
    } catch (e) {
      _lastErrorMessage = e.toString();
      if (state is FundNavLoaded) {
        emit((state as FundNavLoaded).copyWith(
          status: FundNavStatus.error,
          errorMessage: _lastErrorMessage,
        ));
      } else {
        emit(FundNavError(
          errorMessage: _lastErrorMessage!,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// 处理批量添加基金代码
  Future<void> _onAddFundCodes(
      AddFundCodes event, Emitter<FundNavState> emit) async {
    try {
      emit(FundNavLoading());

      for (final fundCode in event.fundCodes) {
        await _navManager.addFundCode(fundCode);
        _trackedFundCodes.add(fundCode);
      }

      // 获取初始数据
      final navData = <String, FundNavData>{};
      final changeInfo = <String, NavChangeInfo?>{};

      for (final fundCode in _trackedFundCodes) {
        final data = await _navManager.getCachedNavData(fundCode);
        if (data != null) {
          navData[fundCode] = data;
        }
      }

      emit(FundNavLoaded(
        navData: navData,
        changeInfo: changeInfo,
        status: FundNavStatus.polling,
        lastUpdate: DateTime.now(),
      ));
    } catch (e) {
      _lastErrorMessage = e.toString();
      emit(FundNavError(
        errorMessage: _lastErrorMessage!,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 处理开始轮询
  Future<void> _onStartPolling(
      StartPolling event, Emitter<FundNavState> emit) async {
    try {
      await _navManager.startPolling();

      final currentState = state;
      if (currentState is FundNavLoaded) {
        emit(currentState.copyWith(
          status: FundNavStatus.polling,
        ));
      }
    } catch (e) {
      _lastErrorMessage = e.toString();
      if (state is FundNavLoaded) {
        emit((state as FundNavLoaded).copyWith(
          status: FundNavStatus.error,
          errorMessage: _lastErrorMessage,
        ));
      } else {
        emit(FundNavError(
          errorMessage: _lastErrorMessage!,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// 处理停止轮询
  Future<void> _onStopPolling(
      StopPolling event, Emitter<FundNavState> emit) async {
    try {
      await _navManager.stopPolling();

      final currentState = state;
      if (currentState is FundNavLoaded) {
        emit(currentState.copyWith(
          status: FundNavStatus.idle,
        ));
      }
    } catch (e) {
      _lastErrorMessage = e.toString();
      if (state is FundNavLoaded) {
        emit((state as FundNavLoaded).copyWith(
          status: FundNavStatus.error,
          errorMessage: _lastErrorMessage,
        ));
      } else {
        emit(FundNavError(
          errorMessage: _lastErrorMessage!,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// 处理暂停轮询
  Future<void> _onPausePolling(
      PausePolling event, Emitter<FundNavState> emit) async {
    try {
      await _navManager.stopPolling();

      final currentState = state;
      if (currentState is FundNavLoaded) {
        emit(currentState.copyWith(
          status: FundNavStatus.paused,
        ));
      }
    } catch (e) {
      _lastErrorMessage = e.toString();
      if (state is FundNavLoaded) {
        emit((state as FundNavLoaded).copyWith(
          status: FundNavStatus.error,
          errorMessage: _lastErrorMessage,
        ));
      } else {
        emit(FundNavError(
          errorMessage: _lastErrorMessage!,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// 处理恢复轮询
  Future<void> _onResumePolling(
      ResumePolling event, Emitter<FundNavState> emit) async {
    try {
      await _navManager.startPolling();

      final currentState = state;
      if (currentState is FundNavLoaded) {
        emit(currentState.copyWith(
          status: FundNavStatus.polling,
        ));
      }
    } catch (e) {
      _lastErrorMessage = e.toString();
      if (state is FundNavLoaded) {
        emit((state as FundNavLoaded).copyWith(
          status: FundNavStatus.error,
          errorMessage: _lastErrorMessage,
        ));
      } else {
        emit(FundNavError(
          errorMessage: _lastErrorMessage!,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// 处理设置轮询间隔
  Future<void> _onSetPollingInterval(
      SetPollingInterval event, Emitter<FundNavState> emit) async {
    try {
      _pollingInterval = event.interval;
      await _navManager.setPollingInterval(event.interval);

      // 状态保持不变，只更新间隔
      final currentState = state;
      if (currentState is FundNavLoaded) {
        emit(currentState);
      }
    } catch (e) {
      _lastErrorMessage = e.toString();
      if (state is FundNavLoaded) {
        emit((state as FundNavLoaded).copyWith(
          status: FundNavStatus.error,
          errorMessage: _lastErrorMessage,
        ));
      } else {
        emit(FundNavError(
          errorMessage: _lastErrorMessage!,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  /// 处理刷新数据
  Future<void> _onRefreshData(
      RefreshData event, Emitter<FundNavState> emit) async {
    try {
      emit(FundNavLoading());

      final fundsToRefresh = event.fundCodes ?? _trackedFundCodes.toList();

      final navData = <String, FundNavData>{};
      final changeInfo = <String, NavChangeInfo?>{};

      for (final fundCode in fundsToRefresh) {
        final data = await _navManager.getCachedNavData(fundCode);
        if (data != null) {
          navData[fundCode] = data;
        }
      }

      // 保持现有状态，只更新数据
      final currentState = state;
      if (currentState is FundNavLoaded) {
        emit(currentState.copyWith(
          navData: navData,
          changeInfo: changeInfo,
          status: FundNavStatus.updating,
          lastUpdate: DateTime.now(),
        ));

        // 恢复轮询状态
        emit(currentState.copyWith(
          status: currentState.status,
        ));
      } else {
        emit(FundNavLoaded(
          navData: navData,
          changeInfo: changeInfo,
          status: FundNavStatus.polling,
          lastUpdate: DateTime.now(),
        ));
      }
    } catch (e) {
      _lastErrorMessage = e.toString();
      emit(FundNavError(
        errorMessage: _lastErrorMessage!,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 处理清除错误
  Future<void> _onClearError(
      ClearError event, Emitter<FundNavState> emit) async {
    _lastErrorMessage = null;

    final currentState = state;
    if (currentState is FundNavLoaded) {
      emit(currentState.copyWith(
        errorMessage: null,
      ));
    }
  }

  /// 处理重置状态
  Future<void> _onResetState(
      ResetState event, Emitter<FundNavState> emit) async {
    try {
      // 停止所有轮询
      await _navManager.stopPolling();

      // 清理跟踪的基金代码
      for (final fundCode in _trackedFundCodes.toList()) {
        await _navManager.removeFundCode(fundCode);
      }
      _trackedFundCodes.clear();

      emit(FundNavInitial());
    } catch (e) {
      _lastErrorMessage = e.toString();
      emit(FundNavError(
        errorMessage: _lastErrorMessage!,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 获取指定基金的净值数据
  FundNavData? getNavData(String fundCode) {
    final currentState = state;
    if (currentState is FundNavLoaded) {
      return currentState.navData[fundCode];
    }
    return null;
  }

  /// 获取指定基金的变化信息
  NavChangeInfo? getChangeInfo(String fundCode) {
    final currentState = state;
    if (currentState is FundNavLoaded) {
      return currentState.changeInfo[fundCode];
    }
    return null;
  }

  /// 获取所有跟踪的基金代码
  Set<String> get trackedFundCodes => Set.unmodifiable(_trackedFundCodes);

  /// 获取当前状态
  FundNavStatus? get currentStatus {
    final currentState = state;
    if (currentState is FundNavLoaded) {
      return currentState.status;
    }
    return null;
  }

  /// 获取最后更新时间
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// 获取轮询间隔
  Duration get pollingInterval => _pollingInterval;

  /// 获取错误信息
  String? get errorMessage => _lastErrorMessage;

  /// 检查是否正在轮询
  bool get isPolling {
    final status = currentStatus;
    return status == FundNavStatus.polling || status == FundNavStatus.updating;
  }

  /// 检查是否已暂停
  bool get isPaused {
    return currentStatus == FundNavStatus.paused;
  }

  /// 检查是否有错误
  bool get hasError => _lastErrorMessage != null;

  /// 检查是否有数据
  bool get hasData {
    final currentState = state;
    return currentState is FundNavLoaded && currentState.navData.isNotEmpty;
  }

  @override
  Future<void> close() {
    _navUpdateSubscription?.cancel();
    _navManager.dispose();
    return super.close();
  }
}

/// 基金净值状态提供者
class FundNavProvider extends BlocProvider<FundNavCubit> {
  FundNavProvider({
    super.key,
    required super.child,
    FundNavDataManager? navManager,
    GlobalCubitManager? globalCubitManager,
  }) : super(
          create: (_) => FundNavCubit(
            navManager: navManager,
            globalCubitManager: globalCubitManager,
          ),
        );
}
