import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 工具面板状态
class ToolPanelState extends Equatable {
  /// 面板展开状态映射
  final Map<String, bool> panelStates;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  const ToolPanelState({
    this.panelStates = const {},
    this.isLoading = false,
    this.error,
  });

  /// 创建初始状态
  factory ToolPanelState.initial() {
    return const ToolPanelState(
      panelStates: {
        'filter': true, // 默认展开筛选器
        'comparison': false,
        'calculator': false,
      },
    );
  }

  /// 复制状态并更新部分字段
  ToolPanelState copyWith({
    Map<String, bool>? panelStates,
    bool? isLoading,
    String? error,
  }) {
    return ToolPanelState(
      panelStates: panelStates ?? this.panelStates,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// 检查指定面板是否展开
  bool isPanelExpanded(String panelId) {
    return panelStates[panelId] ?? false;
  }

  @override
  List<Object?> get props => [panelStates, isLoading, error];

  @override
  String toString() {
    return 'ToolPanelState(panelStates: $panelStates, isLoading: $isLoading, error: $error)';
  }
}

/// 工具面板事件
abstract class ToolPanelEvent extends Equatable {
  const ToolPanelEvent();

  @override
  List<Object?> get props => [];
}

/// 加载面板状态
class LoadPanelStates extends ToolPanelEvent {}

/// 设置面板展开状态
class SetPanelExpanded extends ToolPanelEvent {
  final String panelId;
  final bool isExpanded;

  const SetPanelExpanded({
    required this.panelId,
    required this.isExpanded,
  });

  @override
  List<Object?> get props => [panelId, isExpanded];
}

/// 批量更新面板状态
class UpdateMultiplePanelStates extends ToolPanelEvent {
  final Map<String, bool> states;

  const UpdateMultiplePanelStates(this.states);

  @override
  List<Object?> get props => [states];
}

/// 展开所有面板
class ExpandAllPanels extends ToolPanelEvent {}

/// 折叠所有面板
class CollapseAllPanels extends ToolPanelEvent {}

/// 重置面板状态
class ResetPanelStates extends ToolPanelEvent {}

/// 工具面板状态管理器
class ToolPanelCubit extends Cubit<ToolPanelState> {
  static const String _prefKey = 'tool_panel_states';

  ToolPanelCubit() : super(ToolPanelState.initial());

  /// 加载面板状态
  Future<void> loadPanelStates() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final prefs = await SharedPreferences.getInstance();
      final statesJson = prefs.getString(_prefKey);

      if (statesJson != null) {
        // 解析保存的状态
        final Map<String, bool> savedStates = _parseStatesJson(statesJson);

        // 与默认状态合并，确保所有面板都有状态
        final defaultStates = ToolPanelState.initial().panelStates;
        final mergedStates = Map<String, bool>.from(defaultStates)
          ..addAll(savedStates);

        emit(state.copyWith(
          panelStates: mergedStates,
          isLoading: false,
        ));
      } else {
        // 使用默认状态
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '加载面板状态失败: $e',
      ));
    }
  }

  /// 设置面板展开状态
  Future<void> setPanelExpanded(String panelId, bool isExpanded) async {
    try {
      final newStates = Map<String, bool>.from(state.panelStates)
        ..[panelId] = isExpanded;

      emit(state.copyWith(panelStates: newStates));

      // 保存到持久化存储
      await _savePanelStates(newStates);
    } catch (e) {
      emit(state.copyWith(error: '保存面板状态失败: $e'));
    }
  }

  /// 批量更新面板状态
  Future<void> updateMultiplePanelStates(Map<String, bool> states) async {
    try {
      final newStates = Map<String, bool>.from(state.panelStates)
        ..addAll(states);

      emit(state.copyWith(panelStates: newStates));

      // 保存到持久化存储
      await _savePanelStates(newStates);
    } catch (e) {
      emit(state.copyWith(error: '批量更新面板状态失败: $e'));
    }
  }

  /// 展开所有面板
  Future<void> expandAllPanels() async {
    try {
      final allPanels = state.panelStates.keys.toList();
      final expandedStates = Map.fromEntries(
        allPanels.map((panelId) => MapEntry(panelId, true)),
      );

      emit(state.copyWith(panelStates: expandedStates));

      // 保存到持久化存储
      await _savePanelStates(expandedStates);
    } catch (e) {
      emit(state.copyWith(error: '展开所有面板失败: $e'));
    }
  }

  /// 折叠所有面板
  Future<void> collapseAllPanels() async {
    try {
      final allPanels = state.panelStates.keys.toList();
      final collapsedStates = Map.fromEntries(
        allPanels.map((panelId) => MapEntry(panelId, false)),
      );

      emit(state.copyWith(panelStates: collapsedStates));

      // 保存到持久化存储
      await _savePanelStates(collapsedStates);
    } catch (e) {
      emit(state.copyWith(error: '折叠所有面板失败: $e'));
    }
  }

  /// 重置面板状态
  Future<void> resetPanelStates() async {
    try {
      final defaultStates = ToolPanelState.initial().panelStates;

      emit(state.copyWith(panelStates: defaultStates));

      // 保存到持久化存储
      await _savePanelStates(defaultStates);
    } catch (e) {
      emit(state.copyWith(error: '重置面板状态失败: $e'));
    }
  }

  /// 切换面板展开状态
  Future<void> togglePanelExpanded(String panelId) async {
    final currentState = state.isPanelExpanded(panelId);
    await setPanelExpanded(panelId, !currentState);
  }

  /// 获取展开的面板数量
  int get expandedPanelCount {
    return state.panelStates.values.where((expanded) => expanded).length;
  }

  /// 获取总面板数量
  int get totalPanelCount {
    return state.panelStates.length;
  }

  /// 检查是否有面板展开
  bool get hasAnyPanelExpanded {
    return state.panelStates.values.any((expanded) => expanded);
  }

  /// 检查是否所有面板都展开
  bool get areAllPanelsExpanded {
    if (state.panelStates.isEmpty) return false;
    return state.panelStates.values.every((expanded) => expanded);
  }

  /// 保存面板状态到持久化存储
  Future<void> _savePanelStates(Map<String, bool> states) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statesJson = _statesToJson(states);
      await prefs.setString(_prefKey, statesJson);
    } catch (e) {
      // 静默处理保存失败，不影响用户体验
      print('保存面板状态失败: $e');
    }
  }

  /// 将状态Map转换为JSON字符串
  String _statesToJson(Map<String, bool> states) {
    final Map<String, String> stringMap = states.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return stringMap.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  /// 从JSON字符串解析状态Map
  Map<String, bool> _parseStatesJson(String json) {
    try {
      final Map<String, bool> states = {};
      final entries = json.split(',');

      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final key = parts[0];
          final value = parts[1] == 'true';
          states[key] = value;
        }
      }

      return states;
    } catch (e) {
      print('解析面板状态JSON失败: $e');
      return {};
    }
  }

  /// 清除错误状态
  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(error: null));
    }
  }

  @override
  void onChange(Change<ToolPanelState> change) {
    super.onChange(change);
    // 调试输出
    print('ToolPanelCubit state changed: ${change.nextState}');
  }
}
