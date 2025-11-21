import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'fund_data_card.dart'; // 已删除，使用统一组件
import '../../../widgets/cards/adaptive_fund_card.dart';
import '../../../widgets/cards/fund_card_factory.dart';
import '../../../widgets/cards/base_fund_card.dart';
import '../../../../../../features/fund/domain/entities/fund.dart';

/// 响应式基金网格布局组件
/// 根据屏幕尺寸自动调整列数和卡片模式
/// 实现跨平台一致的响应式设计
class ResponsiveFundGrid extends StatelessWidget {
  final List<Fund> funds;
  final Function(Fund) onFundTap;
  final Function(Fund) onFavoriteToggle;
  final Function(Fund) onCompareToggle;
  final Set<String> favoriteFunds;
  final Set<String> comparingFunds;
  final EdgeInsets? padding;
  final bool showPerformanceMetrics;
  final double? childAspectRatio;

  const ResponsiveFundGrid({
    Key? key,
    required this.funds,
    required this.onFundTap,
    required this.onFavoriteToggle,
    required this.onCompareToggle,
    this.favoriteFunds = const {},
    this.comparingFunds = const {},
    this.padding,
    this.showPerformanceMetrics = true,
    this.childAspectRatio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = _getGridConfig(constraints.maxWidth);

        return Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridHeader(constraints.maxWidth),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: config.columnCount,
                  crossAxisSpacing: config.spacing,
                  mainAxisSpacing: config.spacing,
                  childAspectRatio: childAspectRatio ?? config.childAspectRatio,
                ),
                itemCount: funds.length,
                itemBuilder: (context, index) {
                  final fund = funds[index];
                  return AdaptiveFundCard(
                    fund: fund,
                    compactMode: true,
                    onTap: () => onFundTap(fund),
                    onAddToWatchlist: () => onFavoriteToggle(fund),
                    onCompare: () => onCompareToggle(fund),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridHeader(double screenWidth) {
    final viewMode = _getViewMode(screenWidth);

    return Row(
      children: [
        Expanded(
          child: Text(
            '基金列表 (${funds.length})',
            style: GoogleFonts.inter(
              fontSize: viewMode == ViewMode.mobile ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1a1a1a),
            ),
          ),
        ),
        if (screenWidth >= 768) ...[
          _buildViewModeToggle(),
        ],
      ],
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf5f5f5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton('网格', Icons.grid_view, true),
          _buildViewModeButton('列表', Icons.view_list, false),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String label, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007bff) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : const Color(0xFF666666),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  _GridConfig _getGridConfig(double screenWidth) {
    if (screenWidth < 768) {
      // Mobile: 单列布局，紧凑模式
      return _GridConfig(
        columnCount: 1,
        spacing: 12,
        cardMode: CardStyle.minimal,
        childAspectRatio: 2.8,
      );
    } else if (screenWidth < 1024) {
      // Tablet: 双列布局，标准模式
      return _GridConfig(
        columnCount: 2,
        spacing: 16,
        cardMode: CardStyle.modern,
        childAspectRatio: 2.2,
      );
    } else if (screenWidth < 1440) {
      // Desktop: 三列布局，标准模式
      return _GridConfig(
        columnCount: 3,
        spacing: 20,
        cardMode: CardStyle.modern,
        childAspectRatio: 2.0,
      );
    } else {
      // Large Desktop: 四列布局，详细模式
      return _GridConfig(
        columnCount: 4,
        spacing: 24,
        cardMode: CardStyle.enhanced,
        childAspectRatio: 1.8,
      );
    }
  }

  ViewMode _getViewMode(double screenWidth) {
    if (screenWidth < 768) return ViewMode.mobile;
    if (screenWidth < 1024) return ViewMode.tablet;
    return ViewMode.desktop;
  }
}

/// 视图模式枚举
enum ViewMode {
  mobile, // 移动端
  tablet, // 平板
  desktop, // 桌面
}

/// 网格配置类
class _GridConfig {
  final int columnCount;
  final double spacing;
  final CardStyle cardMode;
  final double childAspectRatio;

  _GridConfig({
    required this.columnCount,
    required this.spacing,
    required this.cardMode,
    required this.childAspectRatio,
  });
}

/// 响应式间距工具类
class ResponsiveSpacing {
  static double getHorizontalSpacing(double screenWidth) {
    if (screenWidth < 768) return 16;
    if (screenWidth < 1024) return 24;
    if (screenWidth < 1440) return 32;
    return 40;
  }

  static double getVerticalSpacing(double screenWidth) {
    if (screenWidth < 768) return 12;
    if (screenWidth < 1024) return 16;
    if (screenWidth < 1440) return 20;
    return 24;
  }

  static double getCardFontSize(double screenWidth) {
    if (screenWidth < 768) return 14;
    if (screenWidth < 1024) return 15;
    return 16;
  }

  static EdgeInsets getScreenPadding(double screenWidth) {
    final horizontal = getHorizontalSpacing(screenWidth);
    final vertical = getVerticalSpacing(screenWidth);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }
}

/// 响应式尺寸工具类
class ResponsiveSizes {
  static bool isMobile(double screenWidth) => screenWidth < 768;
  static bool isTablet(double screenWidth) =>
      screenWidth >= 768 && screenWidth < 1024;
  static bool isDesktop(double screenWidth) => screenWidth >= 1024;

  static int getMaxCharacters(double screenWidth) {
    if (screenWidth < 768) return 20; // Mobile
    if (screenWidth < 1024) return 30; // Tablet
    if (screenWidth < 1440) return 40; // Desktop
    return 50; // Large Desktop
  }

  static double getButtonHeight(double screenWidth) {
    if (screenWidth < 768) return 36;
    if (screenWidth < 1024) return 40;
    return 44;
  }

  static double getIconSize(double screenWidth) {
    if (screenWidth < 768) return 16;
    if (screenWidth < 1024) return 18;
    return 20;
  }
}
