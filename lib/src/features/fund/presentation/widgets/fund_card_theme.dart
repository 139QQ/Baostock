import 'package:flutter/material.dart';

/// 基金卡片主题配置
///
/// 统一管理基金卡片的样式参数，便于全局调整
class FundCardTheme {
  // 卡片基础样式
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  // 徽章样式
  static const double badgeSize = 36.0;
  static const double badgeIconSize = 18.0;
  static const EdgeInsets badgePadding = EdgeInsets.all(0);
  static const double badgeShadowBlurRadius = 2.0;
  static const double badgeShadowSpreadRadius = 1.0;

  // 文本样式
  static const TextStyle fundNameStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle fundCodeStyle = TextStyle(
    fontSize: 11,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle fundTypeStyle = TextStyle(
    fontSize: 11,
    color: Colors.white,
  );

  static const TextStyle companyStyle = TextStyle(
    fontSize: 11,
    color: Colors.white70,
  );

  static const TextStyle returnLabelStyle = TextStyle(
    fontSize: 11,
    color: Colors.white70,
  );

  static const TextStyle returnValueStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  // 按钮样式
  static const double favoriteButtonSize = 36.0;
  static const double favoriteIconSize = 20.0;
  static const double favoriteSplashRadius = 18.0;

  // 收益率容器样式
  static const EdgeInsets returnContainerPadding = EdgeInsets.all(10);
  static const double returnContainerBorderRadius = 8.0;
  static const double returnItemSpacing = 8.0;
  static const double returnIconSize = 10.0;

  // 动画配置
  static const Duration fadeInDuration = Duration(milliseconds: 300);
  static const Duration scaleInDuration = Duration(milliseconds: 200);
  static const Curve fadeInCurve = Curves.easeInOut;
  static const Curve scaleInCurve = Curves.elasticOut;

  // 状态颜色
  static Map<int, Color> get rankingBadgeColors => {
        1: const Color(0xFFFFD700), // 金色
        2: const Color(0xFFC0C0C0), // 银色
        3: const Color(0xFFCD7F32), // 铜色
        4: Colors.blue, // 前10名蓝色
        5: Colors.blue,
        6: Colors.blue,
        7: Colors.blue,
        8: Colors.blue,
        9: Colors.blue,
        10: Colors.blue,
      };

  static const Color defaultBadgeColor = Colors.grey;
  static const Color positiveReturnColor = Color(0xFF4CAF50);
  static const Color negativeReturnColor = Color(0xFFF44336);
  static const Color neutralReturnColor = Colors.white;

  // 渐变色配置
  static Map<int, LinearGradient> get rankingGradients => {
        1: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        2: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
        ),
        3: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
        ),
      };

  static LinearGradient getDefaultRankingGradient(
      BuildContext context, int position) {
    if (position <= 10) {
      final theme = Theme.of(context);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF757575), Color(0xFF616161)],
      );
    }
  }

  // 容器装饰
  static BoxDecoration getBadgeDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(badgeSize / 2),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          spreadRadius: badgeShadowSpreadRadius,
          blurRadius: badgeShadowBlurRadius,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration getReturnContainerDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(returnContainerBorderRadius),
    );
  }

  static BoxDecoration getTagContainerDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
    );
  }

  // 卡片装饰
  static BoxDecoration getCardDecoration(BuildContext context, int position) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(cardBorderRadius),
      gradient: position <= 10 && rankingGradients.containsKey(position)
          ? rankingGradients[position]!
          : getDefaultRankingGradient(context, position),
    );
  }

  // 响应式尺寸调整
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return screenWidth - 32; // 移动端
    } else if (screenWidth < 1200) {
      return (screenWidth - 64) / 2; // 平板端
    } else {
      return 400; // 桌面端固定宽度
    }
  }

  // 暗色主题适配
  static Color getTextColor(bool isDarkTheme) {
    return isDarkTheme ? Colors.white : Colors.white;
  }

  static Color getSecondaryTextColor(bool isDarkTheme) {
    return isDarkTheme ? Colors.white70 : Colors.white70;
  }

  // 无障碍支持
  static double getMinimumTouchTarget() {
    return 44.0; // WCAG标准最小触摸目标
  }

  static EdgeInsets getButtonPadding() {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  }

  // 加载状态样式
  static const Widget loadingIndicator = SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    ),
  );

  // 错误状态样式
  static const Widget errorIcon = Icon(
    Icons.error_outline,
    color: Colors.red,
    size: 16,
  );

  // 空状态样式
  static const Widget emptyIcon = Icon(
    Icons.inbox_outlined,
    color: Colors.grey,
    size: 16,
  );
}

/// 基金卡片尺寸配置
class FundCardDimensions {
  static const double compactHeight = 120.0;
  static const double normalHeight = 160.0;
  static const double expandedHeight = 200.0;

  static double getHeight(FundCardSize size) {
    switch (size) {
      case FundCardSize.compact:
        return compactHeight;
      case FundCardSize.normal:
        return normalHeight;
      case FundCardSize.expanded:
        return expandedHeight;
    }
  }
}

/// 基金卡片尺寸枚举
enum FundCardSize {
  compact,
  normal,
  expanded,
}

/// 基金卡片动画配置
class FundCardAnimationConfig {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;

  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: defaultCurve),
    );
  }

  static Animation<double> createScaleAnimation(
      AnimationController controller) {
    return Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: bounceCurve),
    );
  }

  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: smoothCurve),
    );
  }
}
