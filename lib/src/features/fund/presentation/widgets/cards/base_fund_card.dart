import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/utils/logger.dart';
import '../../../domain/entities/fund.dart';

/// 统一的基金卡片组件基类
///
/// 提供所有基金卡片的通用功能和接口，支持：
/// - 自适应性能优化
/// - 多种显示模式
/// - 统一的交互处理
/// - 可配置的动画效果
abstract class BaseFundCard extends StatefulWidget {
  /// 基金数据实体
  final Fund fund;

  /// 是否显示比较复选框
  final bool showComparisonCheckbox;

  /// 是否显示快速操作按钮
  final bool showQuickActions;

  /// 是否处于选中状态
  final bool isSelected;

  /// 是否启用紧凑模式
  final bool compactMode;

  /// 点击回调函数
  final VoidCallback? onTap;

  /// 选择状态变化回调函数
  final Function(bool)? onSelectionChanged;

  /// 添加到关注列表回调函数
  final VoidCallback? onAddToWatchlist;

  /// 添加到比较回调函数
  final VoidCallback? onCompare;

  /// 分享回调函数
  final VoidCallback? onShare;

  /// 左滑手势回调函数
  final Function()? onSwipeLeft;

  /// 右滑手势回调函数
  final Function()? onSwipeRight;

  /// 创建基金卡片基类实例
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
///
/// 提供基金卡片的各种配置选项，包括动画效果、交互反馈等
class FundCardConfig {
  /// 动画级别 (0: 禁用, 1: 基础, 2: 完整)
  final int animationLevel;

  /// 是否启用动画效果
  final bool enableAnimations;

  /// 是否启用悬停效果
  final bool enableHoverEffects;

  /// 是否启用手势反馈
  final bool enableGestureFeedback;

  /// 是否启用性能监控
  final bool enablePerformanceMonitoring;

  /// 是否启用无障碍功能
  final bool enableAccessibility;

  /// 动画持续时间
  final Duration animationDuration;

  /// 动画曲线
  final Curve animationCurve;

  /// 创建基金卡片配置实例
  const FundCardConfig({
    this.animationLevel = 1,
    this.enableAnimations = true,
    this.enableHoverEffects = true,
    this.enableGestureFeedback = true,
    this.enablePerformanceMonitoring = true,
    this.enableAccessibility = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
  });

  /// 默认配置
  static const FundCardConfig defaultConfig = FundCardConfig();

  /// 高性能配置
  static const FundCardConfig highPerformance = FundCardConfig(
    animationLevel: 0,
    enableAnimations: false,
    enableHoverEffects: false,
    enableGestureFeedback: false,
    enablePerformanceMonitoring: false,
  );

  /// 增强体验配置
  static const FundCardConfig enhanced = FundCardConfig(
    animationLevel: 2,
    enableAnimations: true,
    enableHoverEffects: true,
    enableGestureFeedback: true,
    enablePerformanceMonitoring: true,
    animationDuration: Duration(milliseconds: 400),
  );
}

/// 基金卡片样式枚举
///
/// 定义基金卡片的不同视觉风格
enum CardStyle {
  /// 极简风格 - 最小化视觉元素，突出核心信息
  minimal,

  /// 现代风格 - 平衡的视觉效果和功能展示
  modern,

  /// 增强风格 - 丰富的视觉效果和交互细节
  enhanced,
}

/// 基金卡片状态枚举
///
/// 定义基金卡片的不同状态，影响外观和交互行为
enum CardState {
  /// 正常状态 - 标准显示和交互
  normal,

  /// 加载状态 - 显示加载指示器，禁用交互
  loading,

  /// 错误状态 - 显示错误信息，提供重试选项
  error,

  /// 选中状态 - 高亮显示，用于多选场景
  selected,

  /// 禁用状态 - 灰显，禁用所有交互
  disabled,
}

/// 基金卡片通用工具类
class FundCardUtils {
  /// 格式化净值显示
  static String formatNav(double nav) {
    return nav.toStringAsFixed(4);
  }

  /// 格式化收益率显示
  static String formatYieldRate(double yieldRate) {
    final sign = yieldRate >= 0 ? '+' : '';
    return '$sign${yieldRate.toStringAsFixed(2)}%';
  }

  /// 获取收益率颜色
  static Color getYieldRateColor(BuildContext context, double yieldRate) {
    if (yieldRate >= 0) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  /// 获取基金类型显示名称
  static String getFundTypeDisplayName(String fundType) {
    switch (fundType.toLowerCase()) {
      case 'stock':
        return '股票型';
      case 'bond':
        return '债券型';
      case 'mixed':
        return '混合型';
      case 'index':
        return '指数型';
      case 'money_market':
        return '货币型';
      case 'qdii':
        return 'QDII';
      case 'fof':
        return 'FOF';
      default:
        return fundType;
    }
  }

  /// 获取风险等级显示
  static String getRiskLevelDisplay(int riskLevel) {
    switch (riskLevel) {
      case 1:
        return '低风险';
      case 2:
        return '中低风险';
      case 3:
        return '中风险';
      case 4:
        return '中高风险';
      case 5:
        return '高风险';
      default:
        return '未知风险';
    }
  }

  /// 获取风险等级颜色
  static Color getRiskLevelColor(BuildContext context, int riskLevel) {
    switch (riskLevel) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 触发触觉反馈
  static void triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// 记录用户交互
  static void logUserInteraction(String action, Map<String, dynamic> context) {
    AppLogger.info('User interaction', {'action': action, ...context});
  }

  /// 检查是否应该显示动画
  static bool shouldShowAnimation(FundCardConfig config, CardState state) {
    if (!config.enableAnimations) return false;

    switch (state) {
      case CardState.loading:
      case CardState.error:
        return false;
      case CardState.normal:
      case CardState.selected:
      case CardState.disabled:
        return config.animationLevel > 0;
    }
  }

  /// 获取卡片阴影
  static List<BoxShadow> getCardShadows(BuildContext context, {
    bool isHovered = false,
    bool isPressed = false,
    CardState state = CardState.normal,
  }) {
    final theme = Theme.of(context);

    if (state == CardState.disabled) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
    }

    double elevation = 4.0;
    Color shadowColor = Colors.black.withOpacity(0.15);

    if (isPressed) {
      elevation = 8.0;
      shadowColor = theme.primaryColor.withOpacity(0.3);
    } else if (isHovered) {
      elevation = 12.0;
      shadowColor = theme.primaryColor.withOpacity(0.2);
    }

    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: elevation,
        offset: Offset(0, elevation / 2),
      ),
    ];
  }

  /// 获取卡片边框
  static BoxBorder? getCardBorder(BuildContext context, {
    CardState state = CardState.normal,
    bool isSelected = false,
  }) {
    if (isSelected) {
      return Border.all(
        color: Theme.of(context).primaryColor,
        width: 2,
      );
    }

    switch (state) {
      case CardState.error:
        return Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 1,
        );
      case CardState.disabled:
        return Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        );
      case CardState.normal:
      case CardState.loading:
      case CardState.selected:
        return null;
    }
  }

  /// 获取卡片背景颜色
  static Color getCardBackgroundColor(BuildContext context, {
    CardState state = CardState.normal,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);

    if (isSelected) {
      return theme.primaryColor.withOpacity(0.05);
    }

    switch (state) {
      case CardState.loading:
        return theme.colorScheme.surface.withOpacity(0.5);
      case CardState.error:
        return theme.colorScheme.errorContainer;
      case CardState.disabled:
        return theme.colorScheme.surface.withOpacity(0.3);
      case CardState.normal:
      case CardState.selected:
        return theme.colorScheme.surface;
    }
  }

  /// 构建语义化标签
  static String buildSemanticLabel(Fund fund, {String? additionalInfo}) {
    final buffer = StringBuffer();
    buffer.write('基金: ${fund.name}');
    buffer.write(', 代码: ${fund.code}');
    buffer.write(', 净值: ${formatNav(fund.unitNav)}');
    buffer.write(', 收益率: ${formatYieldRate(fund.dailyReturn)}');

    if (additionalInfo != null) {
      buffer.write(', $additionalInfo');
    }

    return buffer.toString();
  }

  /// 验证基金数据完整性
  static bool validateFundData(Fund fund) {
    return fund.code.isNotEmpty &&
           fund.name.isNotEmpty &&
           fund.unitNav >= 0 &&
           fund.dailyReturn >= -100 &&
           fund.dailyReturn <= 1000;
  }

  /// 获取推荐的动画配置
  static FundCardConfig getRecommendedConfig(Fund fund, {
    int animationLevel = 1,
    bool isHighPerformanceDevice = false,
  }) {
    if (isHighPerformanceDevice) {
      return FundCardConfig.enhanced;
    }

    switch (animationLevel) {
      case 0:
        return FundCardConfig.highPerformance;
      case 1:
        return FundCardConfig.defaultConfig;
      case 2:
        return FundCardConfig.enhanced;
      default:
        return FundCardConfig.defaultConfig;
    }
  }
}