import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/fund.dart';

/// 用户偏好管理服务
class UserPreferences {
  /// 获取用户偏好的动画级别 (0: 禁用, 1: 基础, 2: 完整)
  static Future<int> getAnimationLevel() async {
    try {
      // 在实际项目中，这里应该使用 shared_preferences
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getInt(_animationsKey) ?? 2; // 默认完整动画

      // 模拟实现 - 返回默认值
      return 2;
    } catch (e) {
      debugPrint('UserPreferences: Failed to get animation level: $e');
      return 2; // 默认完整动画
    }
  }

  /// 保存用户偏好的动画级别
  static Future<void> setAnimationLevel(int level) async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setInt(_animationsKey, level);

      debugPrint('UserPreferences: Animation level set to $level');
    } catch (e) {
      debugPrint('UserPreferences: Failed to set animation level: $e');
    }
  }

  /// 获取用户偏好的悬停效果设置
  static Future<bool> getHoverEffectsEnabled() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getBool(_hoverEffectsKey) ?? true;

      return true; // 默认启用悬停效果
    } catch (e) {
      debugPrint('UserPreferences: Failed to get hover effects setting: $e');
      return true;
    }
  }

  /// 保存用户偏好的悬停效果设置
  static Future<void> setHoverEffectsEnabled(bool enabled) async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool(_hoverEffectsKey, enabled);

      debugPrint('UserPreferences: Hover effects set to $enabled');
    } catch (e) {
      debugPrint('UserPreferences: Failed to set hover effects: $e');
    }
  }

  /// 获取用户偏好的性能模式
  static Future<bool> getPerformanceMode() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getBool(_performanceModeKey) ?? false;

      return false; // 默认非性能模式
    } catch (e) {
      debugPrint('UserPreferences: Failed to get performance mode: $e');
      return false;
    }
  }

  /// 保存用户偏好的性能模式
  static Future<void> setPerformanceMode(bool enabled) async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool(_performanceModeKey, enabled);

      debugPrint('UserPreferences: Performance mode set to $enabled');
    } catch (e) {
      debugPrint('UserPreferences: Failed to set performance mode: $e');
    }
  }

  /// 获取用户偏好的手势反馈设置
  static Future<bool> getGestureFeedbackEnabled() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getBool(_gestureFeedbackKey) ?? true;

      return true; // 默认启用手势反馈
    } catch (e) {
      debugPrint('UserPreferences: Failed to get gesture feedback setting: $e');
      return true;
    }
  }

  /// 保存用户偏好的手势反馈设置
  static Future<void> setGestureFeedbackEnabled(bool enabled) async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool(_gestureFeedbackKey, enabled);

      debugPrint('UserPreferences: Gesture feedback set to $enabled');
    } catch (e) {
      debugPrint('UserPreferences: Failed to set gesture feedback: $e');
    }
  }

  /// 重置所有用户偏好到默认值
  static Future<void> resetToDefaults() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove(_animationsKey);
      // await prefs.remove(_hoverEffectsKey);
      // await prefs.remove(_performanceModeKey);
      // await prefs.remove(_gestureFeedbackKey);

      debugPrint('UserPreferences: All preferences reset to defaults');
    } catch (e) {
      debugPrint('UserPreferences: Failed to reset preferences: $e');
    }
  }
}

/// 性能监控混入
mixin PerformanceMonitorMixin on State {
  static const Duration _performanceThreshold =
      Duration(milliseconds: 16); // 60fps
  static const Map<String, Duration> _animationThresholds = {
    'hover': Duration(milliseconds: 200),
    'scale': Duration(milliseconds: 150),
    'return': Duration(milliseconds: 800),
    'favorite': Duration(milliseconds: 300),
  };

  Stopwatch? _stopwatch;

  void _startPerformanceTracking(String animationType) {
    _stopwatch = Stopwatch()..start();
  }

  void _endPerformanceTracking(String animationType) {
    if (_stopwatch != null && _stopwatch!.isRunning) {
      _stopwatch!.stop();
      final duration = _stopwatch!.elapsed;

      final threshold =
          _animationThresholds[animationType] ?? _performanceThreshold;
      if (duration > threshold) {
        _reportSlowAnimation(animationType, duration);
      }

      _stopwatch!.reset();
    }
  }

  void _reportSlowAnimation(String animationType, Duration duration) {
    debugPrint(
        '🔍 Performance Warning: $animationType animation took ${duration.inMilliseconds}ms');

    // 这里可以集成到分析服务
    // Analytics.track('slow_animation', {
    //   'animation_type': animationType,
    //   'duration_ms': duration.inMilliseconds,
    //   'threshold_ms': _animationThresholds[animationType]?.inMilliseconds,
    //   'widget_type': runtimeType.toString(),
    // });
  }

  void _trackFrameRate(String operation) {
    // 简单的帧率监控 - 在实际项目中可以使用更复杂的监控工具
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 这里可以添加帧率统计逻辑
    });
  }
}

/// 自适应基金卡片组件
///
/// 根据设备性能自动调整动画和效果的智能卡片组件：
/// - 低端设备自动禁用复杂动画
/// - 根据屏幕尺寸优化布局
/// - 内存使用优化
/// - 帧率监控和自适应调整
class AdaptiveFundCard extends StatefulWidget {
  final Fund fund;
  final bool showComparisonCheckbox;
  final bool showQuickActions;
  final bool isSelected;
  final bool compactMode;
  final VoidCallback? onTap;
  final Function(bool)? onSelectionChanged;
  final VoidCallback? onAddToWatchlist;
  final VoidCallback? onCompare;
  final VoidCallback? onShare;
  final Function()? onSwipeLeft;
  final Function()? onSwipeRight;

  const AdaptiveFundCard({
    super.key,
    required this.fund,
    this.showComparisonCheckbox = false,
    this.showQuickActions = true,
    this.isSelected = false,
    this.compactMode = false,
    this.onTap,
    this.onSelectionChanged,
    this.onAddToWatchlist,
    this.onCompare,
    this.onShare,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<AdaptiveFundCard> createState() => _AdaptiveFundCardState();
}

class _AdaptiveFundCardState extends State<AdaptiveFundCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Performance monitoring methods
  Stopwatch? _stopwatch;
  static const Duration _performanceThreshold = Duration(milliseconds: 16);
  static const Map<String, Duration> _animationThresholds = {
    'hover': Duration(milliseconds: 200),
    'scale': Duration(milliseconds: 150),
    'return': Duration(milliseconds: 800),
    'favorite': Duration(milliseconds: 300),
  };

  void _startPerformanceTracking(String animationType) {
    _stopwatch = Stopwatch()..start();
  }

  void _endPerformanceTracking(String animationType) {
    if (_stopwatch != null && _stopwatch!.isRunning) {
      _stopwatch!.stop();
      final duration = _stopwatch!.elapsed;

      final threshold =
          _animationThresholds[animationType] ?? _performanceThreshold;
      if (duration > threshold) {
        _reportSlowAnimation(animationType, duration);
      }

      _stopwatch!.reset();
    }
  }

  void _reportSlowAnimation(String animationType, Duration duration) {
    debugPrint(
        '🔍 Performance Warning: $animationType animation took ${duration.inMilliseconds}ms');
  }

  late AnimationController _hoverController;
  late AnimationController _returnController;
  late AnimationController _favoriteController;
  late AnimationController _scaleController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _returnAnimation;
  late Animation<double> _favoriteAnimation;
  late Animation<double> _scaleAnimation;

  bool _isHovered = false;
  bool _isFavorite = false;
  bool _isPressed = false;

  // 性能相关状态
  late bool _enableAnimations; // 异步初始化
  late bool _enableHoverEffects; // 异步初始化
  late int _animationLevel; // 异步初始化
  bool _animationInitializationFailed = false;
  bool _isInitialized = false; // 初始化状态标记

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 同步初始化默认值，避免延迟初始化错误
    _enableAnimations = true;
    _enableHoverEffects = true;
    _animationLevel = 2;
    _isInitialized = true;

    // 立即初始化所有控制器，避免LateInitializationError
    _initializeControllers();

    // 异步初始化用户偏好设置
    _initializeUserPreferences();
    _isFavorite = widget.fund.isFavorite;
  }

  /// 立即初始化所有动画控制器
  void _initializeControllers() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _returnController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  /// 初始化用户偏好设置
  Future<void> _initializeUserPreferences() async {
    try {
      // 获取用户偏好设置
      final userAnimationLevel = await UserPreferences.getAnimationLevel();
      final userHoverEffects = await UserPreferences.getHoverEffectsEnabled();
      final performanceMode = await UserPreferences.getPerformanceMode();

      // 先基于设备性能检测
      _initializePerformanceSettings();

      // 如果用户启用了性能模式，强制使用低性能设置
      if (performanceMode) {
        _animationLevel = 0;
        _enableAnimations = false;
        _enableHoverEffects = false;
      } else {
        // 应用用户偏好设置（但不超过设备性能上限）
        _animationLevel = _animationLevel < userAnimationLevel
            ? _animationLevel
            : userAnimationLevel;
        _enableHoverEffects = _enableHoverEffects && userHoverEffects;

        // 如果用户偏好完全禁用动画，则禁用所有动画
        if (userAnimationLevel == 0) {
          _enableAnimations = false;
          _enableHoverEffects = false;
        }
      }

      debugPrint(
          'AdaptiveFundCard: Final settings - Animation Level: $_animationLevel, '
          'Animations: $_enableAnimations, Hover: $_enableHoverEffects');

      // 初始化动画
      _initializeAnimations();
    } catch (e) {
      debugPrint('AdaptiveFundCard: Failed to initialize user preferences: $e');
      // 降级到默认行为
      _initializePerformanceSettings();
      _initializeAnimations();
    }
  }

  /// 根据设备性能初始化设置 - 增强版
  void _initializePerformanceSettings() {
    final performanceScore = _calculatePerformanceScore();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600 || screenHeight < 800;

    debugPrint('AdaptiveFundCard: Device performance score: $performanceScore');

    // 基于性能评分的智能决策
    if (performanceScore < 30) {
      // 低性能设备 (0-29分)
      _animationLevel = 0;
      _enableAnimations = false;
      _enableHoverEffects = false;
    } else if (performanceScore < 60) {
      // 中等性能设备 (30-59分)
      _animationLevel = 1;
      _enableAnimations = true;
      _enableHoverEffects = !isSmallScreen; // 小屏幕禁用悬停效果
    } else {
      // 高性能设备 (60-100分)
      _animationLevel = 2;
      _enableAnimations = true;
      _enableHoverEffects = true;
    }

    // 特殊情况调整
    if (isSmallScreen && performanceScore < 70) {
      // 小屏幕且性能不是顶级，进一步降级
      _animationLevel = 0;
      _enableAnimations = false;
      _enableHoverEffects = false;
    }
  }

  /// 检测低端设备 - 增强的性能检测算法
  bool _detectLowEndDevice() {
    try {
      final performanceScore = _calculatePerformanceScore();
      return performanceScore < 30; // 30分以下认为是低端设备
    } catch (e) {
      debugPrint('AdaptiveFundCard: Device performance detection failed: $e');
      // 如果检测失败，保守起见使用低性能模式
      return true;
    }
  }

  /// 计算设备性能评分 (0-100分)
  int _calculatePerformanceScore() {
    int score = 0;

    // 1. 屏幕性能评分 (40分满分)
    score += _calculateScreenPerformance();

    // 2. 内存估算评分 (30分满分) - 基于屏幕分辨率间接估算
    score += _estimateMemoryPerformance();

    // 3. 设备类型评分 (30分满分) - 基于平台和分辨率
    score += _calculateDeviceTypeScore();

    return score.clamp(0, 100);
  }

  /// 计算屏幕性能评分
  int _calculateScreenPerformance() {
    final pixelRatio = View.of(context).devicePixelRatio;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final totalPixels = screenWidth * screenHeight;

    int screenScore = 0;

    // 像素密度评分 (20分)
    if (pixelRatio >= 3.0) {
      screenScore += 20; // 高密度屏幕
    } else if (pixelRatio >= 2.0) {
      screenScore += 15; // 中密度屏幕
    } else if (pixelRatio >= 1.5) {
      screenScore += 10; // 普通密度屏幕
    } else {
      screenScore += 5; // 低密度屏幕
    }

    // 屏幕尺寸评分 (20分)
    if (totalPixels >= 2000000) {
      // 大于2百万像素
      screenScore += 20; // 大屏幕
    } else if (totalPixels >= 1000000) {
      // 大于1百万像素
      screenScore += 15; // 中等屏幕
    } else if (totalPixels >= 500000) {
      // 大于50万像素
      screenScore += 10; // 小屏幕
    } else {
      screenScore += 5; // 超小屏幕
    }

    return screenScore;
  }

  /// 估算内存性能评分
  int _estimateMemoryPerformance() {
    final pixelRatio = View.of(context).devicePixelRatio;
    final screenWidth = MediaQuery.of(context).size.width;

    // 基于分辨率和像素密度估算内存容量
    final estimatedMemoryGB = (pixelRatio * screenWidth / 500).clamp(1.0, 8.0);

    if (estimatedMemoryGB >= 6.0) {
      return 30; // 高内存设备
    } else if (estimatedMemoryGB >= 4.0) {
      return 25; // 中高内存设备
    } else if (estimatedMemoryGB >= 2.0) {
      return 20; // 中等内存设备
    } else if (estimatedMemoryGB >= 1.0) {
      return 15; // 低内存设备
    } else {
      return 10; // 超低内存设备
    }
  }

  /// 计算设备类型评分
  int _calculateDeviceTypeScore() {
    final pixelRatio = View.of(context).devicePixelRatio;
    final platform = Theme.of(context).platform;

    int deviceScore = 0;

    // 基于像素密度判断设备档次
    if (pixelRatio >= 3.5) {
      deviceScore += 20; // 高端设备
    } else if (pixelRatio >= 2.5) {
      deviceScore += 15; // 中高端设备
    } else if (pixelRatio >= 1.5) {
      deviceScore += 10; // 中端设备
    } else {
      deviceScore += 5; // 低端设备
    }

    // 平台加分 (桌面设备通常性能更好)
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      deviceScore += 10; // 桌面平台加分
    } else {
      deviceScore += 5; // 移动平台基础分
    }

    return deviceScore;
  }

  void _initializeAnimations() {
    if (!_enableAnimations) return;

    try {
      final duration = _animationLevel == 1 ? 100 : 200;

      // 更新悬停动画控制器持续时间
      _hoverController.duration = Duration(milliseconds: duration);
      _hoverAnimation = Tween<double>(
        begin: 0.0,
        end: _animationLevel == 2 ? -8.0 : -4.0,
      ).animate(CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutCubic,
      ));

      _shadowAnimation = Tween<double>(
        begin: 2.0,
        end: _animationLevel == 2 ? 12.0 : 6.0,
      ).animate(CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutCubic,
      ));

      // 更新收益率数字滚动动画控制器持续时间
      _returnController.duration =
          Duration(milliseconds: _animationLevel == 1 ? 400 : 800);
      _returnAnimation = Tween<double>(
        begin: 0.0,
        end: widget.fund.return1Y,
      ).animate(CurvedAnimation(
        parent: _returnController,
        curve: Curves.easeOutCubic,
      ));

      // 更新收藏动画控制器持续时间
      _favoriteController.duration =
          Duration(milliseconds: _animationLevel == 1 ? 150 : 300);
      _favoriteAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _favoriteController,
        curve: _animationLevel == 2 ? Curves.elasticOut : Curves.easeOut,
      ));

      // 更新点击缩放动画控制器持续时间
      _scaleController.duration =
          Duration(milliseconds: _animationLevel == 1 ? 75 : 150);
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: _animationLevel == 2 ? 0.98 : 0.99,
      ).animate(CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ));

      // 启动收益率动画
      _returnController.forward();
    } catch (e) {
      // 动画初始化失败，降级到静态模式
      debugPrint('AdaptiveFundCard: Animation initialization failed: $e');
      setState(() {
        _animationInitializationFailed = true;
        _enableAnimations = false;
        _enableHoverEffects = false;
        _animationLevel = 0;
      });

      // 安全释放可能已创建的控制器
      try {
        _hoverController.dispose();
      } catch (_) {}
      try {
        _returnController.dispose();
      } catch (_) {}
      try {
        _favoriteController.dispose();
      } catch (_) {}
      try {
        _scaleController.dispose();
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(AdaptiveFundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fund.return1Y != widget.fund.return1Y) {
      _updateReturnAnimation();
    }
    if (oldWidget.fund.isFavorite != widget.fund.isFavorite) {
      _updateFavoriteAnimation();
    }
  }

  void _updateReturnAnimation() {
    if (!_enableAnimations) return;

    _returnAnimation = Tween<double>(
      begin: _returnAnimation.value,
      end: widget.fund.return1Y,
    ).animate(CurvedAnimation(
      parent: _returnController,
      curve: Curves.easeOutCubic,
    ));
    _returnController.reset();
    _returnController.forward();
  }

  void _updateFavoriteAnimation() {
    if (!_enableAnimations) return;

    _isFavorite = widget.fund.isFavorite;
    if (_isFavorite) {
      _favoriteController.forward();
    } else {
      _favoriteController.reverse();
    }
  }

  void _onHoverChange(bool isHovered) {
    if (!_enableHoverEffects || widget.compactMode) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _startPerformanceTracking('hover');
      _hoverController.forward().whenComplete(() {
        _endPerformanceTracking('hover');
      });
    } else {
      _startPerformanceTracking('hover');
      _hoverController.reverse().whenComplete(() {
        _endPerformanceTracking('hover');
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!_enableAnimations) return;

    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();

    // 触觉反馈（低端设备禁用）
    if (_animationLevel > 0) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_enableAnimations) return;

    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();

    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!_enableAnimations) return;

    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_animationLevel > 0) {
      HapticFeedback.mediumImpact();
    }

    if (_isFavorite) {
      _startPerformanceTracking('favorite');
      _favoriteController.forward().whenComplete(() {
        _endPerformanceTracking('favorite');
      });
    } else {
      _startPerformanceTracking('favorite');
      _favoriteController.reverse().whenComplete(() {
        _endPerformanceTracking('favorite');
      });
    }

    widget.onAddToWatchlist?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_enableAnimations) {
      return _buildOptimizedCard(context);
    }

    if (widget.compactMode) {
      return _buildCompactAnimatedCard(context);
    }

    return _buildAdaptiveAnimatedCard(context);
  }

  Widget _buildOptimizedCard(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_animationLevel > 0 ? 12 : 8),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_animationLevel > 0 ? 12 : 8),
          child: Padding(
            padding: EdgeInsets.all(_animationLevel > 1 ? 14 : 12),
            child: _buildOptimizedContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveAnimatedCard(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _hoverController,
          _returnController,
          _favoriteController,
          _scaleController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _hoverAnimation.value),
            child: Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: Card(
                elevation: _shadowAnimation.value,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MouseRegion(
                  onEnter: (_) => _onHoverChange(true),
                  onExit: (_) => _onHoverChange(false),
                  child: GestureDetector(
                    onTapDown: _onTapDown,
                    onTapUp: _onTapUp,
                    onTapCancel: _onTapCancel,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _isHovered && _enableHoverEffects
                            ? Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // 主要内容
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: _buildOptimizedContent(context),
                            ),
                            // 涟漪效果（仅在高端设备显示）
                            if (_isPressed && _animationLevel == 2)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactAnimatedCard(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _returnController,
          _favoriteController,
          _scaleController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: ListTile(
                  leading: widget.showComparisonCheckbox
                      ? Checkbox(
                          value: widget.isSelected,
                          onChanged: (value) {
                            widget.onSelectionChanged?.call(value ?? false);
                          },
                        )
                      : null,
                  title: _buildCompactTitle(),
                  subtitle: _buildCompactSubtitle(),
                  trailing:
                      widget.showQuickActions ? _buildCompactActions() : null,
                  onTap: widget.onTap,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptimizedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头部信息
        _buildOptimizedHeader(),
        SizedBox(height: _animationLevel > 1 ? 10 : 8),
        // 基金经理和规模
        _buildOptimizedManagerInfo(),
        SizedBox(height: _animationLevel > 1 ? 10 : 8),
        // 快速操作按钮
        if (widget.showQuickActions) ...[
          _buildOptimizedQuickActions(),
        ],
      ],
    );
  }

  Widget _buildOptimizedHeader() {
    return Row(
      children: [
        // 左侧内容区域
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基金名称行
              Row(
                children: [
                  if (widget.showComparisonCheckbox) ...[
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) {
                        widget.onSelectionChanged?.call(value ?? false);
                      },
                      semanticLabel: widget.isSelected
                          ? '已选择${widget.fund.name}进行对比'
                          : '选择${widget.fund.name}进行对比',
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.fund.name,
                      style: TextStyle(
                        fontSize: _animationLevel > 1 ? 15 : 14,
                        fontWeight: FontWeight.bold,
                        color: _isHovered && _enableHoverEffects
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: '基金名称: ${widget.fund.name}',
                    ),
                  ),
                ],
              ),
              SizedBox(height: _animationLevel > 1 ? 4 : 2),
              // 基金类型和代码行
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _animationLevel > 1 ? 8 : 6,
                      vertical: _animationLevel > 1 ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: Fund.getFundTypeColor(widget.fund.type)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.fund.type,
                      style: TextStyle(
                        fontSize: _animationLevel > 1 ? 12 : 11,
                        color: Fund.getFundTypeColor(widget.fund.type),
                        fontWeight: FontWeight.w600,
                      ),
                      semanticsLabel: '基金类型: ${widget.fund.type}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.fund.code,
                    style: TextStyle(
                      fontSize: _animationLevel > 1 ? 12 : 11,
                      color: Colors.grey.shade600,
                    ),
                    semanticsLabel: '基金代码: ${widget.fund.code}',
                  ),
                ],
              ),
            ],
          ),
        ),
        // 右侧收益率显示区域
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptimizedReturn(),
              SizedBox(height: _animationLevel > 1 ? 2 : 1),
              Text(
                '近1年收益',
                style: TextStyle(
                  fontSize: _animationLevel > 1 ? 12 : 11,
                  color: Colors.grey.shade600,
                ),
                semanticsLabel: '收益统计周期: 近1年',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizedReturn() {
    if (!_enableAnimations) {
      return Text(
        '${widget.fund.return1Y > 0 ? '+' : ''}${widget.fund.return1Y.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: _animationLevel > 1 ? 18 : 16,
          fontWeight: FontWeight.bold,
          color: Fund.getReturnColor(widget.fund.return1Y),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _returnAnimation,
      builder: (context, child) {
        final currentValue = _returnAnimation.value;
        return Text(
          '${currentValue > 0 ? '+' : ''}${currentValue.toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: _animationLevel > 1 ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: Fund.getReturnColor(currentValue),
          ),
        );
      },
    );
  }

  Widget _buildOptimizedManagerInfo() {
    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: _animationLevel > 1 ? 14 : 12,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.fund.manager,
            style: TextStyle(
              fontSize: _animationLevel > 1 ? 13 : 12,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.fund.scale.toStringAsFixed(1)}亿',
          style: TextStyle(
            fontSize: _animationLevel > 1 ? 13 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizedQuickActions() {
    final buttonCount = _animationLevel > 1 ? 3 : 2;

    return Row(
      children: List.generate(buttonCount, (index) {
        final isLast = index == buttonCount - 1;

        return [
          Expanded(
            child: _buildAdaptiveActionButton(
              index: index,
              onTap: _getButtonAction(index),
            ),
          ),
          if (!isLast) const SizedBox(width: 8),
        ];
      }).expand((e) => e).toList(),
    );
  }

  VoidCallback? _getButtonAction(int index) {
    switch (index) {
      case 0:
        return _toggleFavorite;
      case 1:
        return widget.onCompare;
      case 2:
        return widget.onShare;
      default:
        return null;
    }
  }

  Widget _buildAdaptiveActionButton({
    required int index,
    required VoidCallback? onTap,
  }) {
    final icons = [
      _isFavorite ? Icons.favorite : Icons.favorite_border,
      Icons.compare_arrows,
      Icons.share,
    ];

    final labels = ['自选', '对比', '分享'];

    final semanticLabels = [
      _isFavorite
          ? '已添加${widget.fund.name}到自选，点击取消'
          : '添加${widget.fund.name}到自选',
      '将${widget.fund.name}加入对比列表',
      '分享${widget.fund.name}的信息',
    ];

    final colors = [
      _isFavorite ? Colors.red : null,
      null,
      null,
    ];

    if (!_enableAnimations) {
      return Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticLabels[index],
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icons[index], size: 16, color: colors[index]),
          label: Text(labels[index]),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: _animationLevel > 1 ? 6 : 4,
            ),
            minimumSize: const Size(0, 32),
            side: BorderSide(
              color: colors[index] ?? Colors.grey.shade300,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _favoriteController,
      builder: (context, child) {
        return Semantics(
          button: true,
          enabled: onTap != null,
          label: semanticLabels[index],
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Transform.scale(
              scale: colors[index] != null
                  ? 0.8 + (_favoriteAnimation.value * 0.4)
                  : 1.0,
              child: Icon(
                icons[index],
                size: 16,
                color: colors[index],
              ),
            ),
            label: Text(labels[index]),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: _animationLevel > 1 ? 6 : 4,
              ),
              minimumSize: const Size(0, 32),
              side: BorderSide(
                color: colors[index] ?? Colors.grey.shade300,
                width: colors[index] != null ? 1.5 : 1.0,
              ),
              backgroundColor: colors[index] != null
                  ? colors[index]!.withOpacity(0.1)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.fund.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Fund.getFundTypeColor(widget.fund.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            widget.fund.type,
            style: TextStyle(
              fontSize: 11,
              color: Fund.getFundTypeColor(widget.fund.type),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSubtitle() {
    return Row(
      children: [
        Text(
          widget.fund.code,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          widget.fund.manager,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        _buildOptimizedReturn(),
      ],
    );
  }

  Widget _buildCompactActions() {
    if (!_enableAnimations) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
              size: 18,
            ),
            onPressed: _toggleFavorite,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows, size: 18),
            onPressed: widget.onCompare,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 18),
            onPressed: widget.onShare,
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _favoriteController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Transform.scale(
                scale:
                    _isFavorite ? 0.8 + (_favoriteAnimation.value * 0.4) : 1.0,
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                  size: 18,
                ),
              ),
              onPressed: _toggleFavorite,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.compare_arrows, size: 18),
              onPressed: widget.onCompare,
              visualDensity: VisualDensity.compact,
            ),
            if (_animationLevel > 1)
              IconButton(
                icon: const Icon(Icons.share, size: 18),
                onPressed: widget.onShare,
                visualDensity: VisualDensity.compact,
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // 释放所有动画控制器
    _hoverController.dispose();
    _returnController.dispose();
    _favoriteController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
