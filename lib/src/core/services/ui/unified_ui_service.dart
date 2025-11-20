import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import '../base/i_unified_service.dart';
import '../../theme/glassmorphism_theme_manager.dart';
import '../../../shared/widgets/charts/chart_config_manager.dart';
import '../../../shared/widgets/charts/chart_theme_manager.dart';
import '../../cache/config/cache_config_manager.dart';
import '../../utils/logger.dart';

/// 统一UI服务
///
/// 整合所有UI相关管理器，提供统一的用户界面管理功能
/// 支持主题管理、图表配置、UI性能优化、响应式布局等
///
/// 整合的Manager:
/// - GlassmorphismThemeManager: 毛玻璃主题管理
/// - ChartConfigManager: 图表配置管理
/// - ChartThemeManager: 图表主题管理
/// - CacheConfigManager: 缓存配置管理
class UnifiedUIService implements IUnifiedService {
  // ========== 管理器实例 ==========
  GlassmorphismThemeManager? _glassmorphismThemeManager;
  ChartConfigManager? _chartConfigManager;
  ChartThemeManager? _chartThemeManager;
  CacheConfigManager? _cacheConfigManager; // TODO: 实现缓存配置管理功能

  // ========== 服务状态 ==========
  bool _isInitialized = false;
  bool _isDisposed = false;
  DateTime _startTime = DateTime.now();

  // ========== 事件流控制器 ==========
  final StreamController<UIEvent> _eventController =
      StreamController<UIEvent>.broadcast();
  final StreamController<UIThemeEvent> _themeController =
      StreamController<UIThemeEvent>.broadcast();
  final StreamController<UIPerformanceEvent> _performanceController =
      StreamController<UIPerformanceEvent>.broadcast();

  // ========== UI状态 ==========
  UIThemeMode _currentThemeMode = UIThemeMode.system;
  UIDensity _currentDensity = UIDensity.normal;
  UIAnimationLevel _currentAnimationLevel = UIAnimationLevel.normal;
  double _currentTextScale = 1.0;
  Brightness _currentBrightness = Brightness.light;

  // ========== 性能监控 ==========
  UIPerformanceMetrics _performanceMetrics = const UIPerformanceMetrics(
    averageFrameTime: 16.0,
    jankFraction: 0.0,
    memoryUsage: 0,
    gpuUsage: 0.0,
    renderTime: 0.0,
  );
  Timer? _performanceMonitorTimer;

  // ========== 配置缓存 ==========
  final Map<String, dynamic> _configCache = {};
  Timer? _configCleanupTimer;

  // ========== 响应式配置 ==========
  final Map<UIBreakpoint, UIConfiguration> _responsiveConfig = {};
  ui.FlutterView? _flutterView;

  // ========== 配置 ==========
  final UnifiedUIConfig _config;

  // ========== 构造函数 ==========
  UnifiedUIService({
    UnifiedUIConfig? config,
  }) : _config = config ?? const UnifiedUIConfig();

  // ========== IUnifiedService 接口实现 ==========
  @override
  String get serviceName => 'UnifiedUIService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [];

  @override
  Future<void> initialize(ServiceContainer container) async {
    if (_isInitialized) {
      AppLogger.warn('UnifiedUIService已经初始化');
      return;
    }

    AppLogger.info('正在初始化UnifiedUIService...');

    try {
      // 初始化毛玻璃主题管理器
      await _initializeGlassmorphismThemeManager();

      // 初始化图表配置管理器
      await _initializeChartConfigManager();

      // 初始化图表主题管理器
      await _initializeChartThemeManager();

      // 初始化缓存配置管理器
      await _initializeCacheConfigManager();

      // 初始化响应式配置
      await _initializeResponsiveConfig();

      // 启动性能监控
      _startPerformanceMonitoring();

      // 启动配置缓存清理
      _startConfigCleanup();

      // 监听系统主题变化
      _setupSystemThemeMonitoring();

      _isInitialized = true;
      _startTime = DateTime.now();
      setLifecycleState(ServiceLifecycleState.initialized);

      AppLogger.info('UnifiedUIService初始化完成');
      _emitEvent(UIEvent.serviceInitialized());
      _emitThemeEvent(UIThemeEvent.themeInitialized());
    } catch (e) {
      AppLogger.error('UnifiedUIService初始化失败', e);
      _emitEvent(UIEvent.error(e.toString()));
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    AppLogger.info('正在关闭UnifiedUIService...');
    setLifecycleState(ServiceLifecycleState.disposing);
    _isDisposed = true;
    _isInitialized = false;

    try {
      // 停止性能监控
      _performanceMonitorTimer?.cancel();

      // 停止配置清理
      _configCleanupTimer?.cancel();

      // 释放管理器
      _glassmorphismThemeManager?.dispose();
      _chartThemeManager?.dispose();

      // 关闭事件流
      await _eventController.close();
      await _themeController.close();
      await _performanceController.close();

      // 清理缓存
      _configCache.clear();
      _responsiveConfig.clear();

      setLifecycleState(ServiceLifecycleState.disposed);
      AppLogger.info('UnifiedUIService已关闭');
    } catch (e) {
      AppLogger.error('关闭UnifiedUIService时出错', e);
    }
  }

  bool get isInitialized => _isInitialized;

  bool get isDisposed => _isDisposed;

  @override
  ServiceLifecycleState get lifecycleState {
    if (_isDisposed) return ServiceLifecycleState.disposed;
    if (_isInitialized) return ServiceLifecycleState.initialized;
    return ServiceLifecycleState.uninitialized;
  }

  // 注意：这个方法在基类中已实现，这里仅为满足接口要求
  @protected
  void setLifecycleState(ServiceLifecycleState state) {
    // 基类会处理实际的状态设置
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    if (!_isInitialized || _isDisposed) {
      return ServiceHealthStatus(
        isHealthy: false,
        message: 'Service未初始化或已关闭',
        lastCheck: DateTime.now(),
      );
    }

    final healthIssues = <String>[];

    try {
      // 检查性能指标
      if (_performanceMetrics.averageFrameTime >
          _config.maxAcceptableFrameTime) {
        healthIssues.add(
            'UI性能较差: 平均帧时间${_performanceMetrics.averageFrameTime.toStringAsFixed(1)}ms');
      }

      if (_performanceMetrics.jankFraction >
          _config.maxAcceptableJankFraction) {
        healthIssues.add(
            'UI卡顿严重: 卡顿率${(_performanceMetrics.jankFraction * 100).toStringAsFixed(1)}%');
      }

      // 检查配置缓存大小
      if (_configCache.length > _config.maxConfigCacheSize) {
        healthIssues.add('配置缓存过大: ${_configCache.length}');
      }

      // 检查响应式配置
      if (_responsiveConfig.isEmpty) {
        healthIssues.add('响应式配置为空');
      }

      if (healthIssues.isNotEmpty) {
        return ServiceHealthStatus(
          isHealthy: false,
          message: 'UI服务健康检查失败: ${healthIssues.join('; ')}',
          lastCheck: DateTime.now(),
          details: {'issues': healthIssues},
        );
      }

      AppLogger.debug('UnifiedUIService健康检查通过');
      return ServiceHealthStatus(
        isHealthy: true,
        message: 'UI服务运行正常',
        lastCheck: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('UnifiedUIService健康检查失败', e);
      return ServiceHealthStatus(
        isHealthy: false,
        message: '健康检查异常: $e',
        lastCheck: DateTime.now(),
      );
    }
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: DateTime.now().difference(_startTime),
      memoryUsage: _configCache.length * 1024, // 估算内存使用
      customMetrics: {
        'config_cache_size': _configCache.length,
        'responsive_configs': _responsiveConfig.length,
        'current_theme': _currentThemeMode.toString(),
        'current_density': _currentDensity.toString(),
        'animation_level': _currentAnimationLevel.toString(),
        'performance_metrics': {
          'average_frame_time': _performanceMetrics.averageFrameTime,
          'jank_fraction': _performanceMetrics.jankFraction,
          'memory_usage': _performanceMetrics.memoryUsage,
          'gpu_usage': _performanceMetrics.gpuUsage,
          'render_time': _performanceMetrics.renderTime,
        },
      },
    );
  }

  // ========== 公共API方法 ==========

  /// 设置UI主题模式
  Future<void> setThemeMode(UIThemeMode mode) async {
    _ensureInitialized();

    if (_currentThemeMode == mode) return;

    _currentThemeMode = mode;
    await _applyThemeMode(mode);

    AppLogger.info('UI主题模式已更新', mode.toString());
    _emitThemeEvent(UIThemeEvent.themeModeChanged(mode));
    _emitEvent(UIEvent.themeChanged());
  }

  /// 设置UI密度
  Future<void> setUIDensity(UIDensity density) async {
    _ensureInitialized();

    if (_currentDensity == density) return;

    _currentDensity = density;
    await _applyUIDensity(density);

    AppLogger.info('UI密度已更新', density.toString());
    _emitEvent(UIEvent.densityChanged());
  }

  /// 设置动画级别
  Future<void> setAnimationLevel(UIAnimationLevel level) async {
    _ensureInitialized();

    if (_currentAnimationLevel == level) return;

    _currentAnimationLevel = level;
    await _applyAnimationLevel(level);

    AppLogger.info('UI动画级别已更新', level.toString());
    _emitEvent(UIEvent.animationLevelChanged());
  }

  /// 设置文本缩放
  Future<void> setTextScale(double scale) async {
    _ensureInitialized();

    if (_currentTextScale == scale) return;

    _currentTextScale = scale.clamp(_config.minTextScale, _config.maxTextScale);
    await _applyTextScale(_currentTextScale);

    AppLogger.info(
        '文本缩放已更新', '${(_currentTextScale * 100).toStringAsFixed(0)}%');
    _emitEvent(UIEvent.textScaleChanged());
  }

  /// 获取当前主题配置
  UIThemeConfiguration getCurrentThemeConfig() {
    _ensureInitialized();

    return UIThemeConfiguration(
      themeMode: _currentThemeMode,
      brightness: _currentBrightness,
      density: _currentDensity,
      animationLevel: _currentAnimationLevel,
      textScale: _currentTextScale,
      glassmorphismConfig: _glassmorphismThemeManager?.currentConfig,
    );
  }

  /// 获取图表配置
  ChartConfiguration getChartConfiguration(String chartType) {
    _ensureInitialized();

    final chartTheme = _chartThemeManager?.currentTheme;
    final chartConfig = _chartConfigManager;

    return ChartConfiguration(
      chartType: chartType,
      theme: chartTheme ?? ChartTheme.light(),
      config: chartConfig,
      responsive: _getResponsiveChartConfig(chartType),
    );
  }

  /// 应用响应式配置
  Future<void> applyResponsiveConfiguration(BuildContext context) async {
    _ensureInitialized();

    final screenSize = MediaQuery.of(context).size;
    final breakpoint = _calculateBreakpoint(screenSize);
    final config = _responsiveConfig[breakpoint];

    if (config != null) {
      await _applyResponsiveConfig(config);
      AppLogger.debug('应用响应式配置', '$breakpoint: ${config.toString()}');
    }
  }

  /// 优化UI性能
  Future<void> optimizeUIPerformance() async {
    _ensureInitialized();

    final optimizations = <String>[];

    // 根据性能指标自动调整
    if (_performanceMetrics.jankFraction > 0.1) {
      // 降低动画级别
      if (_currentAnimationLevel == UIAnimationLevel.full) {
        await setAnimationLevel(UIAnimationLevel.reduced);
        optimizations.add('降低动画级别');
      } else if (_currentAnimationLevel == UIAnimationLevel.reduced) {
        await setAnimationLevel(UIAnimationLevel.minimal);
        optimizations.add('最小化动画');
      }
    }

    if (_performanceMetrics.averageFrameTime > 16.67) {
      // 降低视觉效果密度
      if (_currentDensity == UIDensity.comfortable) {
        await setUIDensity(UIDensity.normal);
        optimizations.add('降低UI密度');
      }
    }

    if (optimizations.isNotEmpty) {
      AppLogger.info('UI性能优化完成', optimizations.join(', '));
      _emitPerformanceEvent(UIPerformanceEvent.optimized(optimizations));
    }
  }

  /// 获取性能指标
  UIPerformanceMetrics get performanceMetrics => _performanceMetrics;

  /// 获取UI配置缓存
  Map<String, dynamic> getConfigCache() => Map.unmodifiable(_configCache);

  // ========== 私有初始化方法 ==========

  Future<void> _initializeGlassmorphismThemeManager() async {
    try {
      _glassmorphismThemeManager = GlassmorphismThemeManager();

      // 监听主题变化
      _glassmorphismThemeManager!.addListener(_onGlassmorphismThemeChanged);

      AppLogger.debug('GlassmorphismThemeManager初始化完成');
    } catch (e) {
      AppLogger.error('GlassmorphismThemeManager初始化失败', e);
      rethrow;
    }
  }

  Future<void> _initializeChartConfigManager() async {
    try {
      // 这里假设ChartConfigManager有默认构造函数或依赖注入
      _chartConfigManager = ChartConfigManager();

      AppLogger.debug('ChartConfigManager初始化完成');
    } catch (e) {
      AppLogger.error('ChartConfigManager初始化失败', e);
      rethrow;
    }
  }

  Future<void> _initializeChartThemeManager() async {
    try {
      // 这里假设ChartThemeManager有默认构造函数
      _chartThemeManager = ChartThemeManager.instance;

      // 监听图表主题变化
      _chartThemeManager!.addListener(_onChartThemeChanged);

      AppLogger.debug('ChartThemeManager初始化完成');
    } catch (e) {
      AppLogger.error('ChartThemeManager初始化失败', e);
      rethrow;
    }
  }

  Future<void> _initializeCacheConfigManager() async {
    try {
      // 这里假设CacheConfigManager有默认构造函数
      _cacheConfigManager = CacheConfigManager();

      AppLogger.debug('CacheConfigManager初始化完成');
    } catch (e) {
      AppLogger.error('CacheConfigManager初始化失败', e);
      rethrow;
    }
  }

  Future<void> _initializeResponsiveConfig() async {
    // 设置默认响应式配置
    _responsiveConfig[UIBreakpoint.mobile] = UIConfiguration(
      density: UIDensity.compact,
      animationLevel: UIAnimationLevel.reduced,
      textScale: 0.9,
      chartSimplification: true,
    );

    _responsiveConfig[UIBreakpoint.tablet] = UIConfiguration(
      density: UIDensity.normal,
      animationLevel: UIAnimationLevel.normal,
      textScale: 1.0,
      chartSimplification: false,
    );

    _responsiveConfig[UIBreakpoint.desktop] = UIConfiguration(
      density: UIDensity.comfortable,
      animationLevel: UIAnimationLevel.full,
      textScale: 1.1,
      chartSimplification: false,
    );

    AppLogger.debug('响应式配置初始化完成');
  }

  // ========== 私有应用方法 ==========

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('UnifiedUIService未初始化');
    }
    if (_isDisposed) {
      throw StateError('UnifiedUIService已关闭');
    }
  }

  Future<void> _applyThemeMode(UIThemeMode mode) async {
    switch (mode) {
      case UIThemeMode.system:
        _currentBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        break;
      case UIThemeMode.light:
        _currentBrightness = Brightness.light;
        break;
      case UIThemeMode.dark:
        _currentBrightness = Brightness.dark;
        break;
    }

    // 更新毛玻璃主题
    if (_glassmorphismThemeManager != null) {
      _glassmorphismThemeManager!
          .updateThemeState(_currentBrightness == Brightness.dark);
    }

    // 更新图表主题
    if (_chartThemeManager != null) {
      final chartTheme = _currentBrightness == Brightness.dark
          ? ChartTheme.dark()
          : ChartTheme.light();
      _chartThemeManager!.setTheme(chartTheme);
    }
  }

  Future<void> _applyUIDensity(UIDensity density) async {
    // 根据密度调整间距、字体大小等
    final spacingFactor = density.spacingFactor;
    final fontFactor = density.fontFactor;

    // 缓存配置
    _configCache['ui_density'] = {
      'spacing_factor': spacingFactor,
      'font_factor': fontFactor,
      'applied_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _applyAnimationLevel(UIAnimationLevel level) async {
    // 根据动画级别调整动画时长和效果
    final durationMultiplier = level.durationMultiplier;

    // 缓存配置
    _configCache['animation_level'] = {
      'duration_multiplier': durationMultiplier,
      'curve': level.curve.toString(),
      'applied_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _applyTextScale(double scale) async {
    // 应用文本缩放
    // 注意：setTextScaleFactor 已被弃用，这里仅作记录
    // 实际的文本缩放需要通过 MediaQuery 或其他方式实现

    // 缓存配置
    _configCache['text_scale'] = {
      'scale': scale,
      'applied_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _applyResponsiveConfig(UIConfiguration config) async {
    await setUIDensity(config.density);
    await setAnimationLevel(config.animationLevel);
    await setTextScale(config.textScale);

    // 缓存响应式配置
    _configCache['responsive'] = {
      'config': config.toJson(),
      'applied_at': DateTime.now().toIso8601String(),
    };
  }

  UIBreakpoint _calculateBreakpoint(Size screenSize) {
    final width = screenSize.width;

    if (width < 600) return UIBreakpoint.mobile;
    if (width < 1024) return UIBreakpoint.tablet;
    return UIBreakpoint.desktop;
  }

  ChartResponsiveConfig _getResponsiveChartConfig(String chartType) {
    final screenSize = _flutterView?.physicalSize ?? ui.Size.zero;
    final breakpoint = _calculateBreakpoint(screenSize);

    switch (breakpoint) {
      case UIBreakpoint.mobile:
        return ChartResponsiveConfig(
          simplified: true,
          maxDataPoints: 20,
          showLegend: false,
          enableZoom: false,
        );
      case UIBreakpoint.tablet:
        return ChartResponsiveConfig(
          simplified: false,
          maxDataPoints: 50,
          showLegend: true,
          enableZoom: true,
        );
      case UIBreakpoint.desktop:
        return ChartResponsiveConfig(
          simplified: false,
          maxDataPoints: 100,
          showLegend: true,
          enableZoom: true,
        );
    }
  }

  // ========== 监听方法 ==========

  void _onGlassmorphismThemeChanged() {
    _emitThemeEvent(UIThemeEvent.glassmorphismThemeChanged());
  }

  void _onChartThemeChanged() {
    _emitThemeEvent(UIThemeEvent.chartThemeChanged());
  }

  void _setupSystemThemeMonitoring() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      if (_currentThemeMode == UIThemeMode.system) {
        final newBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        if (_currentBrightness != newBrightness) {
          _currentBrightness = newBrightness;
          _applyThemeMode(_currentThemeMode);
          _emitThemeEvent(UIThemeEvent.systemThemeChanged());
        }
      }
    };
  }

  // ========== 性能监控 ==========

  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _measureUIPerformance(),
    );
  }

  void _measureUIPerformance() {
    // 这里应该集成实际的性能测量逻辑
    // 使用 Flutter 的性能监控工具或自定义指标

    final currentMetrics = UIPerformanceMetrics(
      averageFrameTime: 16.0, // 模拟数据
      jankFraction: 0.05, // 模拟数据
      memoryUsage: 1024 * 1024 * 50, // 模拟数据
      gpuUsage: 0.3, // 模拟数据
      renderTime: 8.0, // 模拟数据
    );

    _performanceMetrics = currentMetrics;

    // 检查是否需要性能优化
    if (currentMetrics.jankFraction > _config.performanceThreshold) {
      _emitPerformanceEvent(
          UIPerformanceEvent.performanceDegraded(currentMetrics));
    }
  }

  void _startConfigCleanup() {
    _configCleanupTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _cleanExpiredConfig(),
    );
  }

  void _cleanExpiredConfig() {
    final expiredKeys = <String>[];
    final now = DateTime.now();

    for (final entry in _configCache.entries) {
      if (entry.value is Map<String, dynamic>) {
        final config = entry.value as Map<String, dynamic>;
        final appliedAt = config['applied_at'] as String?;
        if (appliedAt != null) {
          final appliedTime = DateTime.parse(appliedAt);
          if (now.difference(appliedTime) > _config.configCacheTtl) {
            expiredKeys.add(entry.key);
          }
        }
      }
    }

    for (final key in expiredKeys) {
      _configCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.debug('清理过期UI配置缓存', '删除${expiredKeys.length}条记录');
    }
  }

  // ========== 事件发送 ==========

  void _emitEvent(UIEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _emitThemeEvent(UIThemeEvent event) {
    if (!_themeController.isClosed) {
      _themeController.add(event);
    }
  }

  void _emitPerformanceEvent(UIPerformanceEvent event) {
    if (!_performanceController.isClosed) {
      _performanceController.add(event);
    }
  }

  // ========== 事件流 ==========

  /// UI事件流
  Stream<UIEvent> get eventStream => _eventController.stream;

  /// UI主题事件流
  Stream<UIThemeEvent> get themeStream => _themeController.stream;

  /// UI性能事件流
  Stream<UIPerformanceEvent> get performanceStream =>
      _performanceController.stream;
}

// ========== 支持类和枚举 ==========

/// UI主题模式
enum UIThemeMode {
  system, // 跟随系统
  light, // 浅色主题
  dark, // 深色主题
}

/// UI密度
enum UIDensity {
  compact, // 紧凑
  normal, // 正常
  comfortable, // 舒适
}

/// UI动画级别
enum UIAnimationLevel {
  minimal, // 最小动画
  reduced, // 减少动画
  normal, // 正常动画
  full, // 完整动画
}

extension UIDensityExtension on UIDensity {
  double get spacingFactor {
    switch (this) {
      case UIDensity.compact:
        return 0.8;
      case UIDensity.normal:
        return 1.0;
      case UIDensity.comfortable:
        return 1.2;
    }
  }

  double get fontFactor {
    switch (this) {
      case UIDensity.compact:
        return 0.9;
      case UIDensity.normal:
        return 1.0;
      case UIDensity.comfortable:
        return 1.1;
    }
  }
}

extension UIAnimationLevelExtension on UIAnimationLevel {
  double get durationMultiplier {
    switch (this) {
      case UIAnimationLevel.minimal:
        return 0.0;
      case UIAnimationLevel.reduced:
        return 0.5;
      case UIAnimationLevel.normal:
        return 1.0;
      case UIAnimationLevel.full:
        return 1.5;
    }
  }

  Curve get curve {
    switch (this) {
      case UIAnimationLevel.minimal:
        return Curves.linear;
      case UIAnimationLevel.reduced:
        return Curves.easeOut;
      case UIAnimationLevel.normal:
        return Curves.easeInOut;
      case UIAnimationLevel.full:
        return Curves.elasticOut;
    }
  }
}

/// UI断点
enum UIBreakpoint {
  mobile, // < 600px
  tablet, // 600px - 1024px
  desktop, // > 1024px
}

/// UI事件
class UIEvent {
  final String type;
  final String? message;
  final DateTime timestamp;

  UIEvent({
    required this.type,
    this.message,
  }) : timestamp = DateTime.now();

  const UIEvent.withTimestamp({
    required this.type,
    this.message,
    required this.timestamp,
  });

  UIEvent.serviceInitialized()
      : type = 'service_initialized',
        message = null,
        timestamp = DateTime.now();
  UIEvent.themeChanged()
      : type = 'theme_changed',
        message = null,
        timestamp = DateTime.now();
  UIEvent.densityChanged()
      : type = 'density_changed',
        message = null,
        timestamp = DateTime.now();
  UIEvent.animationLevelChanged()
      : type = 'animation_level_changed',
        message = null,
        timestamp = DateTime.now();
  UIEvent.textScaleChanged()
      : type = 'text_scale_changed',
        message = null,
        timestamp = DateTime.now();
  UIEvent.error(String message)
      : type = 'error',
        message = message,
        timestamp = DateTime.now();
}

/// UI主题事件
class UIThemeEvent {
  final String type;
  final dynamic data;
  final DateTime timestamp;

  UIThemeEvent({
    required this.type,
    this.data,
  }) : timestamp = DateTime.now();

  const UIThemeEvent.withTimestamp({
    required this.type,
    this.data,
    required this.timestamp,
  });

  UIThemeEvent.themeInitialized()
      : type = 'theme_initialized',
        data = null,
        timestamp = DateTime.now();
  UIThemeEvent.themeModeChanged(UIThemeMode mode)
      : type = 'theme_mode_changed',
        data = mode,
        timestamp = DateTime.now();
  UIThemeEvent.systemThemeChanged()
      : type = 'system_theme_changed',
        data = null,
        timestamp = DateTime.now();
  UIThemeEvent.glassmorphismThemeChanged()
      : type = 'glassmorphism_theme_changed',
        data = null,
        timestamp = DateTime.now();
  UIThemeEvent.chartThemeChanged()
      : type = 'chart_theme_changed',
        data = null,
        timestamp = DateTime.now();
}

/// UI性能事件
class UIPerformanceEvent {
  final String type;
  final dynamic data;
  final DateTime timestamp;

  UIPerformanceEvent({
    required this.type,
    this.data,
  }) : timestamp = DateTime.now();

  const UIPerformanceEvent.withTimestamp({
    required this.type,
    this.data,
    required this.timestamp,
  });

  UIPerformanceEvent.optimized(List<String> optimizations)
      : type = 'optimized',
        data = optimizations,
        timestamp = DateTime.now();
  UIPerformanceEvent.performanceDegraded(UIPerformanceMetrics metrics)
      : type = 'performance_degraded',
        data = metrics,
        timestamp = DateTime.now();
}

/// UI性能指标
class UIPerformanceMetrics {
  final double averageFrameTime; // 平均帧时间 (ms)
  final double jankFraction; // 卡顿比例 (0-1)
  final int memoryUsage; // 内存使用 (bytes)
  final double gpuUsage; // GPU使用率 (0-1)
  final double renderTime; // 渲染时间 (ms)

  const UIPerformanceMetrics({
    required this.averageFrameTime,
    required this.jankFraction,
    required this.memoryUsage,
    required this.gpuUsage,
    required this.renderTime,
  });
}

/// UI主题配置
class UIThemeConfiguration {
  final UIThemeMode themeMode;
  final Brightness brightness;
  final UIDensity density;
  final UIAnimationLevel animationLevel;
  final double textScale;
  final dynamic glassmorphismConfig;

  const UIThemeConfiguration({
    required this.themeMode,
    required this.brightness,
    required this.density,
    required this.animationLevel,
    required this.textScale,
    this.glassmorphismConfig,
  });
}

/// 图表配置
class ChartConfiguration {
  final String chartType;
  final ChartTheme theme;
  final ChartConfigManager? config;
  final ChartResponsiveConfig responsive;

  const ChartConfiguration({
    required this.chartType,
    required this.theme,
    this.config,
    required this.responsive,
  });
}

/// 图表响应式配置
class ChartResponsiveConfig {
  final bool simplified;
  final int maxDataPoints;
  final bool showLegend;
  final bool enableZoom;

  const ChartResponsiveConfig({
    required this.simplified,
    required this.maxDataPoints,
    required this.showLegend,
    required this.enableZoom,
  });
}

/// UI配置
class UIConfiguration {
  final UIDensity density;
  final UIAnimationLevel animationLevel;
  final double textScale;
  final bool chartSimplification;

  const UIConfiguration({
    required this.density,
    required this.animationLevel,
    required this.textScale,
    required this.chartSimplification,
  });

  Map<String, dynamic> toJson() => {
        'density': density.toString(),
        'animation_level': animationLevel.toString(),
        'text_scale': textScale,
        'chart_simplification': chartSimplification,
      };

  @override
  String toString() =>
      'UIConfiguration(density: $density, animation: $animationLevel, scale: $textScale)';
}

/// 统一UI配置
class UnifiedUIConfig {
  final Duration configCacheTtl;
  final int maxConfigCacheSize;
  final double performanceThreshold;
  final double maxAcceptableFrameTime;
  final double maxAcceptableJankFraction;
  final double minTextScale;
  final double maxTextScale;

  const UnifiedUIConfig({
    this.configCacheTtl = const Duration(hours: 1),
    this.maxConfigCacheSize = 100,
    this.performanceThreshold = 0.1,
    this.maxAcceptableFrameTime = 16.67,
    this.maxAcceptableJankFraction = 0.05,
    this.minTextScale = 0.8,
    this.maxTextScale = 1.5,
  });
}
