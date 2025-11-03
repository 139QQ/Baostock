import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fund_search_bar.dart';
import 'unified_fund_search_bar.dart';

/// 基金搜索栏适配器
///
/// 提供向后兼容的接口，可以在原有FundSearchBar和新的UnifiedFundSearchBar之间切换。
/// 支持通过配置开关来选择使用哪个实现。
class FundSearchBarAdapter extends StatelessWidget {
  /// 是否启用统一搜索服务
  static bool _enableUnifiedSearch = true;

  /// 当前搜索文本
  final String? searchText;

  /// 占位符文本
  final String? placeholder;

  /// 搜索回调
  final ValueChanged<String>? onSearch;

  /// 清除回调
  final VoidCallback? onClear;

  /// 焦点变化回调
  final ValueChanged<bool>? onFocusChanged;

  /// 是否自动聚焦
  final bool autoFocus;

  /// 是否显示高级搜索选项
  final bool showAdvancedOptions;

  /// 是否启用语音搜索
  final bool enableVoiceSearch;

  /// 自定义样式
  final BoxDecoration? decoration;

  /// 自定义边框
  final BoxBorder? border;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 内边距
  final EdgeInsets? contentPadding;

  /// 文本样式
  final TextStyle? textStyle;

  /// 提示文本样式
  final TextStyle? hintStyle;

  /// 前缀图标
  final Widget? prefixIcon;

  /// 后缀图标
  final Widget? suffixIcon;

  /// 是否只读
  final bool readOnly;

  /// 最大长度
  final int? maxLength;

  /// 输入格式器
  final List<TextInputFormatter>? inputFormatters;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 文本输入动作
  final TextInputAction? textInputAction;

  /// 是否启用
  final bool enabled;

  /// 强制使用特定实现（用于测试）
  final bool? forceUseUnified;

  const FundSearchBarAdapter({
    super.key,
    this.searchText,
    this.placeholder,
    this.onSearch,
    this.onClear,
    this.onFocusChanged,
    this.autoFocus = false,
    this.showAdvancedOptions = true,
    this.enableVoiceSearch = false,
    this.decoration,
    this.border,
    this.borderRadius,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLength,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.forceUseUnified,
  });

  /// 设置全局配置：是否启用统一搜索
  static void setUnifiedSearchEnabled(bool enabled) {
    _enableUnifiedSearch = enabled;
  }

  /// 获取当前是否启用统一搜索
  static bool isUnifiedSearchEnabled() => _enableUnifiedSearch;

  @override
  Widget build(BuildContext context) {
    final shouldUseUnified = forceUseUnified ?? _enableUnifiedSearch;

    if (shouldUseUnified) {
      // 使用统一搜索栏
      return UnifiedFundSearchBar(
        searchText: searchText,
        placeholder: placeholder,
        onSearch: onSearch,
        onClear: onClear,
        onFocusChanged: onFocusChanged,
        autoFocus: autoFocus,
        showAdvancedOptions: showAdvancedOptions,
        enableVoiceSearch: enableVoiceSearch,
        decoration: decoration,
        border: border,
        borderRadius: borderRadius,
        contentPadding: contentPadding,
        textStyle: textStyle,
        hintStyle: hintStyle,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        readOnly: readOnly,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        enabled: enabled,
      );
    } else {
      // 使用原有搜索栏（需要与SearchBloc配合使用）
      return FundSearchBar(
        searchText: searchText,
        placeholder: placeholder,
        onSearch: onSearch,
        onClear: onClear,
        onFocusChanged: onFocusChanged,
        autoFocus: autoFocus,
        showAdvancedOptions: showAdvancedOptions,
        enableVoiceSearch: enableVoiceSearch,
        decoration: decoration,
        border: border,
        borderRadius: borderRadius,
        contentPadding: contentPadding,
        textStyle: textStyle,
        hintStyle: hintStyle,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        readOnly: readOnly,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        enabled: enabled,
      );
    }
  }
}

/// 搜索栏配置
///
/// 提供全局配置选项，用于控制搜索行为
class SearchBarConfig {
  /// 是否启用统一搜索
  static bool enableUnifiedSearch = true;

  /// 默认搜索模式
  static UnifiedSearchMode defaultSearchMode = UnifiedSearchMode.auto;

  /// 是否显示搜索模式选择器
  static bool showSearchModeSelector = true;

  /// 是否显示搜索建议
  static bool showSuggestions = true;

  /// 搜索防抖时间（毫秒）
  static int searchDebounceMs = 300;

  /// 最大建议数量
  static int maxSuggestions = 10;

  /// 是否启用性能监控
  static bool enablePerformanceMonitoring = true;

  /// 是否启用缓存
  static bool enableCache = true;

  /// 缓存过期时间（分钟）
  static int cacheExpiryMinutes = 10;

  /// 应用配置
  static void applyConfig({
    bool? enableUnifiedSearch,
    UnifiedSearchMode? defaultSearchMode,
    bool? showSearchModeSelector,
    bool? showSuggestions,
    int? searchDebounceMs,
    int? maxSuggestions,
    bool? enablePerformanceMonitoring,
    bool? enableCache,
    int? cacheExpiryMinutes,
  }) {
    if (enableUnifiedSearch != null) {
      SearchBarConfig.enableUnifiedSearch = enableUnifiedSearch;
      FundSearchBarAdapter.setUnifiedSearchEnabled(enableUnifiedSearch);
    }
    if (defaultSearchMode != null) {
      SearchBarConfig.defaultSearchMode = defaultSearchMode;
    }
    if (showSearchModeSelector != null) {
      SearchBarConfig.showSearchModeSelector = showSearchModeSelector;
    }
    if (showSuggestions != null) {
      SearchBarConfig.showSuggestions = showSuggestions;
    }
    if (searchDebounceMs != null) {
      SearchBarConfig.searchDebounceMs = searchDebounceMs;
    }
    if (maxSuggestions != null) {
      SearchBarConfig.maxSuggestions = maxSuggestions;
    }
    if (enablePerformanceMonitoring != null) {
      SearchBarConfig.enablePerformanceMonitoring = enablePerformanceMonitoring;
    }
    if (enableCache != null) {
      SearchBarConfig.enableCache = enableCache;
    }
    if (cacheExpiryMinutes != null) {
      SearchBarConfig.cacheExpiryMinutes = cacheExpiryMinutes;
    }
  }

  /// 重置为默认配置
  static void resetToDefaults() {
    applyConfig(
      enableUnifiedSearch: true,
      defaultSearchMode: UnifiedSearchMode.auto,
      showSearchModeSelector: true,
      showSuggestions: true,
      searchDebounceMs: 300,
      maxSuggestions: 10,
      enablePerformanceMonitoring: true,
      enableCache: true,
      cacheExpiryMinutes: 10,
    );
  }

  /// 获取当前配置摘要
  static Map<String, dynamic> getConfigSummary() {
    return {
      'enableUnifiedSearch': enableUnifiedSearch,
      'defaultSearchMode': defaultSearchMode.toString(),
      'showSearchModeSelector': showSearchModeSelector,
      'showSuggestions': showSuggestions,
      'searchDebounceMs': searchDebounceMs,
      'maxSuggestions': maxSuggestions,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableCache': enableCache,
      'cacheExpiryMinutes': cacheExpiryMinutes,
    };
  }
}
