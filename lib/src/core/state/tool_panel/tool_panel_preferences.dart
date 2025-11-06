import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 工具面板用户偏好管理器
class ToolPanelPreferences {
  static const String _prefPrefix = 'tool_panel_';
  static const String _statesKey = '${_prefPrefix}states';
  static const String _layoutKey = '${_prefPrefix}layout';
  static const String _visibilityKey = '${_prefPrefix}visibility';
  static const String _customizationKey = '${_prefPrefix}customization';

  /// 保存面板状态
  static Future<void> savePanelStates(PanelStates states) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statesKey, jsonEncode(states.toJson()));
    } catch (e) {
      // 静默处理保存失败，不影响用户体验
    }
  }

  /// 加载面板状态
  static Future<PanelStates> loadPanelStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statesJson = prefs.getString(_statesKey);

      if (statesJson != null) {
        final Map<String, dynamic> json = jsonDecode(statesJson);
        return PanelStates.fromJson(json);
      }
    } catch (e) {
      // 静默处理加载失败
    }

    return const PanelStates();
  }

  /// 保存面板可见性
  static Future<void> savePanelVisibility(PanelVisibility visibility) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_visibilityKey, jsonEncode(visibility.toJson()));
    } catch (e) {
      // 静默处理保存失败
    }
  }

  /// 加载面板可见性
  static Future<PanelVisibility> loadPanelVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visibilityJson = prefs.getString(_visibilityKey);

      if (visibilityJson != null) {
        final Map<String, dynamic> json = jsonDecode(visibilityJson);
        return PanelVisibility.fromJson(json);
      }
    } catch (e) {
      // 静默处理加载失败
    }

    return const PanelVisibility();
  }

  /// 保存布局偏好
  static Future<void> saveLayoutPreferences(LayoutPreferences layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_layoutKey, jsonEncode(layout.toJson()));
    } catch (e) {
      // 静默处理保存失败
    }
  }

  /// 加载布局偏好
  static Future<LayoutPreferences> loadLayoutPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutJson = prefs.getString(_layoutKey);

      if (layoutJson != null) {
        final Map<String, dynamic> json = jsonDecode(layoutJson);
        return LayoutPreferences.fromJson(json);
      }
    } catch (e) {
      // 静默处理加载失败
    }

    return const LayoutPreferences();
  }

  /// 保存自定义偏好
  static Future<void> saveCustomizationPreferences(
      CustomizationPreferences customization) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _customizationKey, jsonEncode(customization.toJson()));
    } catch (e) {
      // 静默处理保存失败
    }
  }

  /// 加载自定义偏好
  static Future<CustomizationPreferences> loadCustomizationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customizationJson = prefs.getString(_customizationKey);

      if (customizationJson != null) {
        final Map<String, dynamic> json = jsonDecode(customizationJson);
        return CustomizationPreferences.fromJson(json);
      }
    } catch (e) {
      // 静默处理加载失败
    }

    return const CustomizationPreferences();
  }

  /// 重置所有偏好设置
  static Future<void> resetAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_statesKey);
      await prefs.remove(_visibilityKey);
      await prefs.remove(_layoutKey);
      await prefs.remove(_customizationKey);
    } catch (e) {
      // 静默处理重置失败
    }
  }

  /// 导出偏好设置
  static Future<Map<String, dynamic>> exportAllPreferences() async {
    try {
      final panelStates = await loadPanelStates();
      final visibility = await loadPanelVisibility();
      final layout = await loadLayoutPreferences();
      final customization = await loadCustomizationPreferences();

      return {
        'panelStates': panelStates.toJson(),
        'visibility': visibility.toJson(),
        'layout': layout.toJson(),
        'customization': customization.toJson(),
        'exportTime': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // 静默处理导出失败
      return {};
    }
  }

  /// 导入偏好设置
  static Future<bool> importPreferences(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('panelStates')) {
        final panelStates = PanelStates.fromJson(data['panelStates']);
        await savePanelStates(panelStates);
      }

      if (data.containsKey('visibility')) {
        final visibility = PanelVisibility.fromJson(data['visibility']);
        await savePanelVisibility(visibility);
      }

      if (data.containsKey('layout')) {
        final layout = LayoutPreferences.fromJson(data['layout']);
        await saveLayoutPreferences(layout);
      }

      if (data.containsKey('customization')) {
        final customization =
            CustomizationPreferences.fromJson(data['customization']);
        await saveCustomizationPreferences(customization);
      }

      return true;
    } catch (e) {
      // 静默处理导入失败
      return false;
    }
  }

  /// 检查偏好设置是否存在
  static Future<bool> hasPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_statesKey) ||
          prefs.containsKey(_visibilityKey) ||
          prefs.containsKey(_layoutKey) ||
          prefs.containsKey(_customizationKey);
    } catch (e) {
      // 静默处理检查失败
      return false;
    }
  }
}

/// 面板状态偏好设置
class PanelStates {
  final bool filterExpanded;
  final bool comparisonExpanded;
  final bool calculatorExpanded;
  final String lastUpdatedPanel;

  const PanelStates({
    this.filterExpanded = true,
    this.comparisonExpanded = false,
    this.calculatorExpanded = false,
    this.lastUpdatedPanel = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'filterExpanded': filterExpanded,
      'comparisonExpanded': comparisonExpanded,
      'calculatorExpanded': calculatorExpanded,
      'lastUpdatedPanel': lastUpdatedPanel,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory PanelStates.fromJson(Map<String, dynamic> json) {
    return PanelStates(
      filterExpanded: json['filterExpanded'] ?? true,
      comparisonExpanded: json['comparisonExpanded'] ?? false,
      calculatorExpanded: json['calculatorExpanded'] ?? false,
      lastUpdatedPanel: json['lastUpdatedPanel'] ?? '',
    );
  }

  PanelStates copyWith({
    bool? filterExpanded,
    bool? comparisonExpanded,
    bool? calculatorExpanded,
    String? lastUpdatedPanel,
  }) {
    return PanelStates(
      filterExpanded: filterExpanded ?? this.filterExpanded,
      comparisonExpanded: comparisonExpanded ?? this.comparisonExpanded,
      calculatorExpanded: calculatorExpanded ?? this.calculatorExpanded,
      lastUpdatedPanel: lastUpdatedPanel ?? this.lastUpdatedPanel,
    );
  }
}

/// 面板可见性偏好设置
class PanelVisibility {
  final bool showFilterPanel;
  final bool showComparisonPanel;
  final bool showCalculatorPanel;
  final bool showHeader;
  final bool showSettingsButton;
  final bool showPanelActions;

  const PanelVisibility({
    this.showFilterPanel = true,
    this.showComparisonPanel = true,
    this.showCalculatorPanel = true,
    this.showHeader = true,
    this.showSettingsButton = true,
    this.showPanelActions = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'showFilterPanel': showFilterPanel,
      'showComparisonPanel': showComparisonPanel,
      'showCalculatorPanel': showCalculatorPanel,
      'showHeader': showHeader,
      'showSettingsButton': showSettingsButton,
      'showPanelActions': showPanelActions,
    };
  }

  factory PanelVisibility.fromJson(Map<String, dynamic> json) {
    return PanelVisibility(
      showFilterPanel: json['showFilterPanel'] ?? true,
      showComparisonPanel: json['showComparisonPanel'] ?? true,
      showCalculatorPanel: json['showCalculatorPanel'] ?? true,
      showHeader: json['showHeader'] ?? true,
      showSettingsButton: json['showSettingsButton'] ?? true,
      showPanelActions: json['showPanelActions'] ?? true,
    );
  }

  PanelVisibility copyWith({
    bool? showFilterPanel,
    bool? showComparisonPanel,
    bool? showCalculatorPanel,
    bool? showHeader,
    bool? showSettingsButton,
    bool? showPanelActions,
  }) {
    return PanelVisibility(
      showFilterPanel: showFilterPanel ?? this.showFilterPanel,
      showComparisonPanel: showComparisonPanel ?? this.showComparisonPanel,
      showCalculatorPanel: showCalculatorPanel ?? this.showCalculatorPanel,
      showHeader: showHeader ?? this.showHeader,
      showSettingsButton: showSettingsButton ?? this.showSettingsButton,
      showPanelActions: showPanelActions ?? this.showPanelActions,
    );
  }
}

/// 布局偏好设置
class LayoutPreferences {
  final String layoutMode; // 'expanded', 'compact', 'minimal'
  final double panelWidth;
  final bool enableAnimations;
  final int animationDuration;
  final String theme; // 'light', 'dark', 'auto'

  const LayoutPreferences({
    this.layoutMode = 'expanded',
    this.panelWidth = 320.0,
    this.enableAnimations = true,
    this.animationDuration = 300,
    this.theme = 'auto',
  });

  Map<String, dynamic> toJson() {
    return {
      'layoutMode': layoutMode,
      'panelWidth': panelWidth,
      'enableAnimations': enableAnimations,
      'animationDuration': animationDuration,
      'theme': theme,
    };
  }

  factory LayoutPreferences.fromJson(Map<String, dynamic> json) {
    return LayoutPreferences(
      layoutMode: json['layoutMode'] ?? 'expanded',
      panelWidth: (json['panelWidth'] as num?)?.toDouble() ?? 320.0,
      enableAnimations: json['enableAnimations'] ?? true,
      animationDuration: json['animationDuration'] ?? 300,
      theme: json['theme'] ?? 'auto',
    );
  }

  LayoutPreferences copyWith({
    String? layoutMode,
    double? panelWidth,
    bool? enableAnimations,
    int? animationDuration,
    String? theme,
  }) {
    return LayoutPreferences(
      layoutMode: layoutMode ?? this.layoutMode,
      panelWidth: panelWidth ?? this.panelWidth,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      animationDuration: animationDuration ?? this.animationDuration,
      theme: theme ?? this.theme,
    );
  }
}

/// 自定义偏好设置
class CustomizationPreferences {
  final Map<String, dynamic> toolSettings;
  final List<String> favoriteTools;
  final Map<String, String> panelTitles;
  final Map<String, int> panelOrder;

  const CustomizationPreferences({
    this.toolSettings = const {},
    this.favoriteTools = const [],
    this.panelTitles = const {},
    this.panelOrder = const {
      'filter': 0,
      'comparison': 1,
      'calculator': 2,
    },
  });

  Map<String, dynamic> toJson() {
    return {
      'toolSettings': toolSettings,
      'favoriteTools': favoriteTools,
      'panelTitles': panelTitles,
      'panelOrder': panelOrder,
    };
  }

  factory CustomizationPreferences.fromJson(Map<String, dynamic> json) {
    return CustomizationPreferences(
      toolSettings: Map<String, dynamic>.from(json['toolSettings'] ?? {}),
      favoriteTools: List<String>.from(json['favoriteTools'] ?? []),
      panelTitles: Map<String, String>.from(json['panelTitles'] ?? {}),
      panelOrder: Map<String, int>.from(json['panelOrder'] ??
          {
            'filter': 0,
            'comparison': 1,
            'calculator': 2,
          }),
    );
  }

  CustomizationPreferences copyWith({
    Map<String, dynamic>? toolSettings,
    List<String>? favoriteTools,
    Map<String, String>? panelTitles,
    Map<String, int>? panelOrder,
  }) {
    return CustomizationPreferences(
      toolSettings: toolSettings ?? this.toolSettings,
      favoriteTools: favoriteTools ?? this.favoriteTools,
      panelTitles: panelTitles ?? this.panelTitles,
      panelOrder: panelOrder ?? this.panelOrder,
    );
  }
}
