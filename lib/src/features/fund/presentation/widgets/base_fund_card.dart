import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/fund.dart';
import '../../../../core/utils/logger.dart';

/// 统一的基金卡片组件基类
///
/// 提供所有基金卡片的通用功能和接口，支持：
/// - 自适应性能优化
/// - 多种显示模式
/// - 统一的交互处理
/// - 可配置的动画效果
abstract class BaseFundCard extends StatefulWidget {
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

  const BaseFundCard({
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
}

/// 基金卡片配置类
class FundCardConfig {
  final int animationLevel; // 0: 禁用, 1: 基础, 2: 完整
  final bool enableAnimations;
  final bool enableHoverEffects;
  final bool enableGestureFeedback;
  final bool enablePerformanceMonitoring;
  final CardStyle cardStyle;

  const FundCardConfig({
    this.animationLevel = 2,
    this.enableAnimations = true,
    this.enableHoverEffects = true,
    this.enableGestureFeedback = true,
    this.enablePerformanceMonitoring = false,
    this.cardStyle = CardStyle.modern,
  });

  /// 创建低性能配置
  factory FundCardConfig.lowPerformance() {
    return const FundCardConfig(
      animationLevel: 0,
      enableAnimations: false,
      enableHoverEffects: false,
      enableGestureFeedback: false,
      enablePerformanceMonitoring: false,
      cardStyle: CardStyle.minimal,
    );
  }

  /// 创建高性能配置
  factory FundCardConfig.highPerformance() {
    return const FundCardConfig(
      animationLevel: 2,
      enableAnimations: true,
      enableHoverEffects: true,
      enableGestureFeedback: true,
      enablePerformanceMonitoring: true,
      cardStyle: CardStyle.enhanced,
    );
  }
}

/// 卡片样式枚举
enum CardStyle {
  minimal, // 简约样式
  modern, // 现代样式
  enhanced, // 增强样式
}

/// 用户偏好管理服务 - 统一版本
class UserPreferencesService {
  static const String _animationsKey = 'fund_card_animations';
  static const String _hoverEffectsKey = 'fund_card_hover_effects';
  static const String _gestureFeedbackKey = 'fund_card_gesture_feedback';
  static const String _performanceModeKey = 'fund_card_performance_mode';

  /// 获取用户偏好的动画级别
  static Future<int> getAnimationLevel() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getInt(_animationsKey) ?? 2;
      return 2; // 默认完整动画
    } catch (e) {
      AppLogger.warn('获取动画级别失败: $e');
      return 2;
    }
  }

  /// 获取用户偏好的悬停效果设置
  static Future<bool> getHoverEffectsEnabled() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getBool(_hoverEffectsKey) ?? true;
      return true;
    } catch (e) {
      AppLogger.warn('获取悬停效果设置失败: $e');
      return true;
    }
  }

  /// 获取用户偏好的手势反馈设置
  static Future<bool> getGestureFeedbackEnabled() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getBool(_gestureFeedbackKey) ?? true;
      return true;
    } catch (e) {
      AppLogger.warn('获取手势反馈设置失败: $e');
      return true;
    }
  }

  /// 获取用户偏好的性能模式
  static Future<bool> getPerformanceMode() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getBool(_performanceModeKey) ?? false;
      return false;
    } catch (e) {
      AppLogger.warn('获取性能模式失败: $e');
      return false;
    }
  }
}

/// 性能监控服务 - 统一版本
class PerformanceMonitorService {
  static const Duration _performanceThreshold = Duration(milliseconds: 16);
  static const Map<String, Duration> _animationThresholds = {
    'hover': Duration(milliseconds: 200),
    'scale': Duration(milliseconds: 150),
    'return': Duration(milliseconds: 800),
    'favorite': Duration(milliseconds: 300),
    'swipe': Duration(milliseconds: 200),
  };

  static Stopwatch? _stopwatch;

  static void startTracking(String animationType) {
    _stopwatch = Stopwatch()..start();
  }

  static void endTracking(String animationType) {
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

  static void _reportSlowAnimation(String animationType, Duration duration) {
    AppLogger.warn('性能警告: $animationType 动画耗时 ${duration.inMilliseconds}ms');
  }
}

/// 设备性能检测服务 - 统一版本
class DevicePerformanceService {
  /// 计算设备性能评分 (0-100分)
  static int calculatePerformanceScore(BuildContext context) {
    int score = 0;
    score += _calculateScreenPerformance(context);
    score += _estimateMemoryPerformance(context);
    score += _calculateDeviceTypeScore(context);
    return score.clamp(0, 100);
  }

  /// 计算屏幕性能评分
  static int _calculateScreenPerformance(BuildContext context) {
    final pixelRatio = View.of(context).devicePixelRatio;
    final size = MediaQuery.of(context).size;
    final totalPixels = size.width * size.height;

    int screenScore = 0;

    if (pixelRatio >= 3.0) {
      screenScore += 20;
    } else if (pixelRatio >= 2.0) {
      screenScore += 15;
    } else if (pixelRatio >= 1.5) {
      screenScore += 10;
    } else {
      screenScore += 5;
    }

    if (totalPixels >= 2000000) {
      screenScore += 20;
    } else if (totalPixels >= 1000000) {
      screenScore += 15;
    } else if (totalPixels >= 500000) {
      screenScore += 10;
    } else {
      screenScore += 5;
    }

    return screenScore;
  }

  /// 估算内存性能评分
  static int _estimateMemoryPerformance(BuildContext context) {
    final pixelRatio = View.of(context).devicePixelRatio;
    final screenWidth = MediaQuery.of(context).size.width;
    final estimatedMemoryGB = (pixelRatio * screenWidth / 500).clamp(1.0, 8.0);

    if (estimatedMemoryGB >= 6.0) {
      return 30;
    } else if (estimatedMemoryGB >= 4.0) {
      return 25;
    } else if (estimatedMemoryGB >= 2.0) {
      return 20;
    } else if (estimatedMemoryGB >= 1.0) {
      return 15;
    } else {
      return 10;
    }
  }

  /// 计算设备类型评分
  static int _calculateDeviceTypeScore(BuildContext context) {
    final pixelRatio = View.of(context).devicePixelRatio;
    final platform = Theme.of(context).platform;

    int deviceScore = 0;

    if (pixelRatio >= 3.5) {
      deviceScore += 20;
    } else if (pixelRatio >= 2.5) {
      deviceScore += 15;
    } else if (pixelRatio >= 1.5) {
      deviceScore += 10;
    } else {
      deviceScore += 5;
    }

    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      deviceScore += 10;
    } else {
      deviceScore += 5;
    }

    return deviceScore;
  }

  /// 检测低端设备
  static bool isLowEndDevice(BuildContext context) {
    return calculatePerformanceScore(context) < 30;
  }

  /// 获取推荐的配置
  static FundCardConfig getRecommendedConfig(BuildContext context) {
    final performanceScore = calculatePerformanceScore(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isLowEnd = isLowEndDevice(context);

    if (isLowEnd || (isMobile && performanceScore < 50)) {
      return FundCardConfig.lowPerformance();
    } else if (performanceScore >= 80) {
      return FundCardConfig.highPerformance();
    } else {
      return FundCardConfig(
        animationLevel: performanceScore < 60 ? 1 : 2,
        enableAnimations: performanceScore >= 50,
        enableHoverEffects: performanceScore >= 60 && !isMobile,
        enableGestureFeedback: !isLowEnd,
        cardStyle:
            performanceScore >= 70 ? CardStyle.enhanced : CardStyle.modern,
      );
    }
  }
}

/// 触觉反馈服务 - 统一版本
class HapticFeedbackService {
  static Future<void> provideFeedback(String type) async {
    try {
      final feedbackEnabled =
          await UserPreferencesService.getGestureFeedbackEnabled();
      if (!feedbackEnabled) return;

      switch (type) {
        case 'light':
          HapticFeedback.lightImpact();
          break;
        case 'medium':
          HapticFeedback.mediumImpact();
          break;
        case 'heavy':
          HapticFeedback.heavyImpact();
          break;
        case 'selection':
          HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      AppLogger.warn('触觉反馈失败: $e');
    }
  }
}
