import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../fund_exploration/domain/models/fund.dart';
import '../../models/fund_nav_data.dart';
import '../../data/processors/nav_change_detector.dart';
import '../../data/processors/fund_nav_data_manager.dart';
import '../fund_exploration/presentation/widgets/adaptive_fund_card.dart';
import 'package:decimal/decimal.dart';

/// 净值感知的基金卡片
///
/// 扩展AdaptiveFundCard，支持实时净值变化显示、动画效果和交互
/// 根据净值变化自动调整视觉提示和动画
class NavAwareFundCard extends StatefulWidget {
  /// 基金数据
  final Fund fund;

  /// 当前净值数据
  final FundNavData? currentNavData;

  /// 前一个净值数据（用于变化检测）
  final FundNavData? previousNavData;

  /// 净值变化信息
  final NavChangeInfo? changeInfo;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否显示详细信息
  final bool showDetailedInfo;

  /// 是否启用动画
  final bool enableAnimations;

  /// 自定义动画配置
  final NavCardAnimationConfig? animationConfig;

  /// 卡片样式
  final NavCardStyle style;

  const NavAwareFundCard({
    Key? key,
    required this.fund,
    this.currentNavData,
    this.previousNavData,
    this.changeInfo,
    this.onTap,
    this.onLongPress,
    this.showDetailedInfo = false,
    this.enableAnimations = true,
    this.animationConfig,
    this.style = NavCardStyle.modern,
  }) : super(key: key);

  @override
  State<NavAwareFundCard> createState() => _NavAwareFundCardState();
}

class _NavAwareFundCardState extends State<NavAwareFundCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _colorChangeController;
  late AnimationController _slideController;

  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isHovered = false;
  int _animationLevel = 2; // 默认完整动画

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserPreferences();
  }

  @override
  void didUpdateWidget(NavAwareFundCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检测净值变化
    if (_shouldTriggerAnimation(oldWidget)) {
      _triggerChangeAnimation();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorChangeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// 初始化动画控制器
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _colorChangeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: _getChangeColor(),
    ).animate(CurvedAnimation(
      parent: _colorChangeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  /// 加载用户偏好
  Future<void> _loadUserPreferences() async {
    if (!widget.enableAnimations) return;

    try {
      _animationLevel = await UserPreferences.getAnimationLevel();
    } catch (e) {
      debugPrint('Failed to load user preferences: $e');
    }
  }

  /// 检查是否应该触发动画
  bool _shouldTriggerAnimation(NavAwareFundCard oldWidget) {
    if (!widget.enableAnimations || widget.changeInfo == null) return false;

    // 检查是否有新的变化信息
    return widget.changeInfo != oldWidget.changeInfo &&
        widget.changeInfo!.hasChange;
  }

  /// 触发变化动画
  void _triggerChangeAnimation() {
    if (_animationLevel == 0) return; // 禁用动画

    switch (_animationLevel) {
      case 1: // 基础动画
        _triggerBasicAnimation();
        break;
      case 2: // 完整动画
        _triggerFullAnimation();
        break;
    }
  }

  /// 触发基础动画
  void _triggerBasicAnimation() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    HapticFeedback.lightImpact();
  }

  /// 触发完整动画
  void _triggerFullAnimation() {
    // 脉冲动画
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    // 颜色变化动画
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: _getChangeColor(),
    ).animate(CurvedAnimation(
      parent: _colorChangeController,
      curve: Curves.easeInOut,
    ));

    _colorChangeController.forward().then((_) {
      _colorChangeController.reverse();
    });

    // 滑动动画
    if (widget.changeInfo!.changeType == NavChangeType.surge ||
        widget.changeInfo!.changeType == NavChangeType.plunge) {
      _slideController.forward().then((_) {
        _slideController.reverse();
      });
    }

    // 触觉反馈
    _triggerHapticFeedback();
  }

  /// 触发触觉反馈
  void _triggerHapticFeedback() {
    switch (widget.changeInfo!.changeType) {
      case NavChangeType.surge:
        HapticFeedback.mediumImpact();
        break;
      case NavChangeType.plunge:
        HapticFeedback.heavyImpact();
        break;
      case NavChangeType.rise:
      case NavChangeType.fall:
        HapticFeedback.lightImpact();
        break;
      default:
        break;
    }
  }

  /// 获取变化颜色
  Color _getChangeColor() {
    if (widget.changeInfo == null) return Colors.transparent;

    switch (widget.changeInfo!.changeType) {
      case NavChangeType.surge:
      case NavChangeType.rise:
      case NavChangeType.slightRise:
        return Colors.green.withOpacity(0.3);
      case NavChangeType.plunge:
      case NavChangeType.fall:
      case NavChangeType.slightFall:
        return Colors.red.withOpacity(0.3);
      case NavChangeType.flat:
        return Colors.grey.withOpacity(0.2);
      case NavChangeType.none:
        return Colors.transparent;
      case NavChangeType.dataError:
        return Colors.orange.withOpacity(0.3);
      case NavChangeType.unknown:
        return Colors.transparent;
    }
  }

  /// 构建基础卡片
  Widget _buildBaseCard() {
    return AdaptiveFundCard(
      fund: widget.fund,
      onTap: widget.onTap,
      showQuickActions: true,
      compactMode: false,
    );
  }

  /// 构建净值变化指示器
  Widget _buildChangeIndicator() {
    if (widget.changeInfo == null || !widget.changeInfo!.hasChange) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getChangeColor().withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getChangeColor(),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getChangeIcon(),
              size: 16,
              color: _getChangeIconColor(),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.changeInfo!.changePercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getChangeIconColor(),
              ),
            ),
          ],
        ),
      ).animate(controller: _colorChangeController).fadeIn(),
    );
  }

  /// 获取变化图标
  IconData _getChangeIcon() {
    if (widget.changeInfo == null) return Icons.remove;

    switch (widget.changeInfo!.changeType) {
      case NavChangeType.surge:
        return Icons.trending_up;
      case NavChangeType.rise:
        return Icons.arrow_upward;
      case NavChangeType.slightRise:
        return Icons.arrow_upward;
      case NavChangeType.flat:
        return Icons.remove;
      case NavChangeType.slightFall:
        return Icons.arrow_downward;
      case NavChangeType.fall:
        return Icons.arrow_downward;
      case NavChangeType.plunge:
        return Icons.trending_down;
      case NavChangeType.none:
        return Icons.remove;
      case NavChangeType.dataError:
        return Icons.error;
      case NavChangeType.unknown:
        return Icons.help;
    }
  }

  /// 获取变化图标颜色
  Color _getChangeIconColor() {
    if (widget.changeInfo == null) return Colors.grey;

    switch (widget.changeInfo!.changeType) {
      case NavChangeType.surge:
      case NavChangeType.rise:
      case NavChangeType.slightRise:
        return Colors.green.shade700;
      case NavChangeType.flat:
        return Colors.grey.shade600;
      case NavChangeType.none:
        return Colors.grey.shade500;
      case NavChangeType.dataError:
        return Colors.orange.shade700;
      case NavChangeType.slightFall:
      case NavChangeType.fall:
      case NavChangeType.plunge:
        return Colors.red.shade700;
      case NavChangeType.unknown:
        return Colors.grey.shade500;
    }
  }

  /// 构建详细信息面板
  Widget _buildDetailedInfo() {
    if (!widget.showDetailedInfo || widget.currentNavData == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavInfoRow(),
            if (widget.changeInfo != null) ...[
              const SizedBox(height: 8),
              _buildChangeInfoRow(),
            ],
          ],
        ),
      ).animate().slideY(begin: 0.1, end: 0).fadeIn(),
    );
  }

  /// 构建净值信息行
  Widget _buildNavInfoRow() {
    final navData = widget.currentNavData!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '单位净值',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
            Text(
              navData.navFormatted,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '累计净值',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
            Text(
              navData.accumulatedNavFormatted,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建变化信息行
  Widget _buildChangeInfoRow() {
    if (widget.changeInfo == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          _getChangeIcon(),
          size: 16,
          color: _getChangeIconColor(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.changeInfo!.description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimations || _animationLevel == 0) {
      // 禁用动画版本
      return Stack(
        children: [
          _buildBaseCard(),
          _buildChangeIndicator(),
          _buildDetailedInfo(),
        ],
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _colorAnimation,
        _slideAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Stack(
            children: [
              _buildBaseCard(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _colorAnimation.value ?? Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              _buildChangeIndicator(),
              _buildDetailedInfo(),
            ],
          ),
        );
      },
    );
  }
}

/// 净值卡片动画配置
class NavCardAnimationConfig {
  /// 脉冲动画持续时间
  final Duration pulseDuration;

  /// 颜色变化动画持续时间
  final Duration colorChangeDuration;

  /// 滑动动画持续时间
  final Duration slideDuration;

  /// 脉冲动画幅度
  final double pulseScale;

  /// 是否启用触觉反馈
  final bool enableHapticFeedback;

  const NavCardAnimationConfig({
    this.pulseDuration = const Duration(milliseconds: 600),
    this.colorChangeDuration = const Duration(milliseconds: 800),
    this.slideDuration = const Duration(milliseconds: 500),
    this.pulseScale = 1.05,
    this.enableHapticFeedback = true,
  });
}

/// 净值卡片样式
enum NavCardStyle {
  /// 现代风格
  modern,

  /// 简约风格
  minimal,

  /// 详细风格
  detailed,

  /// 卡片风格
  card,
}

/// 净值变化监听器
typedef NavChangeCallback = void Function(NavChangeInfo changeInfo);

/// 带净值监听的基金卡片
class NavListeningFundCard extends StatefulWidget {
  /// 基金代码
  final String fundCode;

  /// 基金数据
  final Fund? fund;

  /// 净值变化回调
  final NavChangeCallback? onNavChange;

  /// 点击回调
  final VoidCallback? onTap;

  /// 其他参数
  final bool showDetailedInfo;
  final bool enableAnimations;
  final NavCardStyle style;

  const NavListeningFundCard({
    Key? key,
    required this.fundCode,
    this.fund,
    this.onNavChange,
    this.onTap,
    this.showDetailedInfo = false,
    this.enableAnimations = true,
    this.style = NavCardStyle.modern,
  }) : super(key: key);

  @override
  State<NavListeningFundCard> createState() => _NavListeningFundCardState();
}

class _NavListeningFundCardState extends State<NavListeningFundCard> {
  final FundNavDataManager _navManager = FundNavDataManager();

  FundNavData? _currentNavData;
  FundNavData? _previousNavData;
  NavChangeInfo? _changeInfo;
  StreamSubscription<FundNavUpdateEvent>? _navUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNavListening();
  }

  @override
  void dispose() {
    _navUpdateSubscription?.cancel();
    super.dispose();
  }

  /// 初始化净值监听
  void _initializeNavListening() {
    // 添加基金到跟踪列表
    _navManager.addFundCode(widget.fundCode);

    // 监听净值更新
    _navUpdateSubscription = _navManager.updateStream.listen(
      (updateEvent) {
        if (updateEvent.fundCode == widget.fundCode) {
          setState(() {
            _previousNavData = _currentNavData;
            _currentNavData = updateEvent.currentNav;
            _changeInfo = updateEvent.changeInfo;
          });

          // 触发回调
          if (widget.onNavChange != null && _changeInfo != null) {
            widget.onNavChange!(_changeInfo!);
          }
        }
      },
    );

    // 获取当前净值数据
    _loadCurrentNavData();
  }

  /// 加载当前净值数据
  Future<void> _loadCurrentNavData() async {
    try {
      final navData = await _navManager.getCachedNavData(widget.fundCode);
      if (navData != null) {
        setState(() {
          _currentNavData = navData;
        });
      }
    } catch (e) {
      debugPrint('Failed to load current NAV data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有基金数据，创建一个默认的
    final fund = widget.fund ??
        Fund(
          code: widget.fundCode,
          name: '基金 ${widget.fundCode}',
          type: '混合型',
          company: '未知公司',
          manager: '未知经理',
          return1W: 0.0,
          return1M: 0.0,
          return3M: 0.0,
          return6M: 0.0,
          return1Y: 0.0,
          return3Y: 0.0,
          scale: 0.0,
          riskLevel: '未知',
          status: '正常',
          unitNav: _currentNavData?.nav.toDouble(),
          accumulatedNav: _currentNavData?.accumulatedNav.toDouble(),
          establishDate: DateTime.now(),
          isFavorite: false,
        );

    return NavAwareFundCard(
      fund: fund,
      currentNavData: _currentNavData,
      previousNavData: _previousNavData,
      changeInfo: _changeInfo,
      onTap: widget.onTap,
      showDetailedInfo: widget.showDetailedInfo,
      enableAnimations: widget.enableAnimations,
      style: widget.style,
    );
  }
}
