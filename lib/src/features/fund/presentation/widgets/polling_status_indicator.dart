import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../cubits/fund_nav_cubit.dart';

/// 轮询状态指示器
///
/// 显示基金净值轮询状态的视觉指示器
/// 支持多种样式和动画效果
class PollingStatusIndicator extends StatelessWidget {
  /// 状态
  final FundNavStatus? status;

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 指示器样式
  final PollingIndicatorStyle style;

  /// 是否显示详细信息
  final bool showDetails;

  /// 是否启用动画
  final bool enableAnimation;

  /// 自定义颜色
  final Color? activeColor;

  /// 自定义大小
  final double size;

  /// 点击回调
  final VoidCallback? onTap;

  const PollingStatusIndicator({
    Key? key,
    this.status,
    this.lastUpdateTime,
    this.style = PollingIndicatorStyle.compact,
    this.showDetails = false,
    this.enableAnimation = true,
    this.activeColor,
    this.size = 24,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentStatus = status ?? FundNavStatus.idle;
    final color = activeColor ?? _getStatusColor(currentStatus);

    Widget indicator;

    switch (style) {
      case PollingIndicatorStyle.compact:
        indicator = _buildCompactIndicator(color, currentStatus);
        break;
      case PollingIndicatorStyle.detailed:
        indicator = _buildDetailedIndicator(color, currentStatus);
        break;
      case PollingIndicatorStyle.icon:
        indicator = _buildIconIndicator(color, currentStatus);
        break;
      case PollingIndicatorStyle.badge:
        indicator = _buildBadgeIndicator(color, currentStatus);
        break;
    }

    final widgetWithAnimation = enableAnimation
        ? indicator
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 300))
        : indicator;

    return GestureDetector(
      onTap: onTap,
      child: widgetWithAnimation,
    );
  }

  /// 构建紧凑样式指示器
  Widget _buildCompactIndicator(Color color, FundNavStatus status) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: _buildStatusIcon(status, size * 0.6, color),
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(FundNavStatus status, double iconSize, Color color) {
    return Icon(
      _getStatusIcon(status),
      size: iconSize,
      color: color,
    );
  }

  /// 构建详细样式指示器
  Widget _buildDetailedIndicator(Color color, FundNavStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status.description,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (showDetails && lastUpdateTime != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatLastUpdate(lastUpdateTime!),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建图标样式指示器
  Widget _buildIconIndicator(Color color, FundNavStatus status) {
    return Icon(
      _getStatusIcon(status),
      size: size,
      color: color,
    );
  }

  /// 构建徽章样式指示器
  Widget _buildBadgeIndicator(Color color, FundNavStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: size * 0.6,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            status.description,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取状态图标
  IconData _getStatusIcon(FundNavStatus status) {
    switch (status) {
      case FundNavStatus.idle:
        return Icons.circle_outlined;
      case FundNavStatus.polling:
        return Icons.autorenew;
      case FundNavStatus.paused:
        return Icons.pause_circle_outline;
      case FundNavStatus.error:
        return Icons.error_outline;
      case FundNavStatus.updating:
        return Icons.sync;
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(FundNavStatus status) {
    switch (status) {
      case FundNavStatus.idle:
        return Colors.grey;
      case FundNavStatus.polling:
        return Colors.green;
      case FundNavStatus.paused:
        return Colors.orange;
      case FundNavStatus.error:
        return Colors.red;
      case FundNavStatus.updating:
        return Colors.blue;
    }
  }

  /// 格式化最后更新时间
  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return '刚刚更新';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}

/// 轮询状态指示器样式
enum PollingIndicatorStyle {
  /// 紧凑样式
  compact,

  /// 详细样式
  detailed,

  /// 图标样式
  icon,

  /// 徽章样式
  badge,
}

/// 轮询按钮样式
enum PollingButtonStyle {
  /// 浮动按钮
  floating,

  /// 轮廓按钮
  outlined,

  /// 文本按钮
  text,
}

/// 轮询控制按钮
class PollingControlButton extends StatefulWidget {
  /// 当前状态
  final FundNavStatus status;

  /// 点击回调
  final VoidCallback? onTap;

  /// 按钮样式
  final PollingButtonStyle style;

  /// 是否启用动画
  final bool enableAnimation;

  /// 自定义大小
  final double? size;

  const PollingControlButton({
    Key? key,
    required this.status,
    this.onTap,
    this.style = PollingButtonStyle.floating,
    this.enableAnimation = true,
    this.size,
  }) : super(key: key);

  @override
  State<PollingControlButton> createState() => _PollingControlButtonState();
}

class _PollingControlButtonState extends State<PollingControlButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);

    if (widget.status == FundNavStatus.polling) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(PollingControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.status != oldWidget.status) {
      if (widget.status == FundNavStatus.polling &&
          !_animationController.isAnimating) {
        _animationController.repeat();
      } else if (widget.status != FundNavStatus.polling &&
          _animationController.isAnimating) {
        _animationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.size ?? _getDefaultSize();
    final color = _getButtonColor();
    final icon = _getButtonIcon();

    Widget button;

    switch (widget.style) {
      case PollingButtonStyle.floating:
        button = _buildFloatingButton(color, icon, buttonSize);
        break;
      case PollingButtonStyle.outlined:
        button = _buildOutlinedButton(color, icon, buttonSize);
        break;
      case PollingButtonStyle.text:
        button = _buildTextButton(color, icon);
        break;
    }

    final animatedButton = widget.enableAnimation
        ? button.animate().scale(duration: const Duration(milliseconds: 200))
        : button;

    return GestureDetector(
      onTap: widget.onTap,
      child: animatedButton,
    );
  }

  /// 构建浮动按钮
  Widget _buildFloatingButton(Color color, IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.status == FundNavStatus.polling
                ? _rotationAnimation.value * 360
                : 0,
            child: Icon(
              icon,
              size: size * 0.5,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  /// 构建轮廓按钮
  Widget _buildOutlinedButton(Color color, IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: color,
      ),
    );
  }

  /// 构建文本按钮
  Widget _buildTextButton(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            _getButtonText(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取按钮颜色
  Color _getButtonColor() {
    switch (widget.status) {
      case FundNavStatus.idle:
        return Colors.grey;
      case FundNavStatus.polling:
        return Colors.green;
      case FundNavStatus.paused:
        return Colors.orange;
      case FundNavStatus.error:
        return Colors.red;
      case FundNavStatus.updating:
        return Colors.blue;
    }
  }

  /// 获取按钮图标
  IconData _getButtonIcon() {
    switch (widget.status) {
      case FundNavStatus.idle:
        return Icons.play_arrow;
      case FundNavStatus.polling:
        return Icons.pause;
      case FundNavStatus.paused:
        return Icons.play_arrow;
      case FundNavStatus.error:
        return Icons.refresh;
      case FundNavStatus.updating:
        return Icons.sync;
    }
  }

  /// 获取按钮文本
  String _getButtonText() {
    switch (widget.status) {
      case FundNavStatus.idle:
        return '开始';
      case FundNavStatus.polling:
        return '暂停';
      case FundNavStatus.paused:
        return '恢复';
      case FundNavStatus.error:
        return '重试';
      case FundNavStatus.updating:
        return '更新中';
    }
  }

  /// 获取默认大小
  double _getDefaultSize() {
    switch (widget.style) {
      case PollingButtonStyle.floating:
        return 56;
      case PollingButtonStyle.outlined:
        return 48;
      case PollingButtonStyle.text:
        return 40;
    }
  }
}

/// 轮询状态面板
class PollingStatusPanel extends StatelessWidget {
  /// 状态
  final FundNavStatus? status;

  /// 跟踪的基金数量
  final int trackedFundCount;

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 轮询间隔
  final Duration? pollingInterval;

  /// 错误信息
  final String? errorMessage;

  /// 面板样式
  final PollingPanelStyle style;

  /// 控制回调
  final PollingControlCallbacks? callbacks;

  const PollingStatusPanel({
    Key? key,
    this.status,
    this.trackedFundCount = 0,
    this.lastUpdateTime,
    this.pollingInterval,
    this.errorMessage,
    this.style = PollingPanelStyle.compact,
    this.callbacks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentStatus = status ?? FundNavStatus.idle;

    switch (style) {
      case PollingPanelStyle.compact:
        return _buildCompactPanel(currentStatus);
      case PollingPanelStyle.detailed:
        return _buildDetailedPanel(currentStatus);
      case PollingPanelStyle.minimal:
        return _buildMinimalPanel(currentStatus);
    }
  }

  /// 构建紧凑面板
  Widget _buildCompactPanel(FundNavStatus status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          PollingStatusIndicator(
            status: status,
            lastUpdateTime: lastUpdateTime,
            style: PollingIndicatorStyle.compact,
            enableAnimation: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
                if (trackedFundCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '跟踪基金: $trackedFundCount',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (callbacks != null) ...[
            PollingControlButton(
              status: status,
              onTap: callbacks?.onToggle,
              style: PollingButtonStyle.outlined,
              size: 32,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// 构建详细面板
  Widget _buildDetailedPanel(FundNavStatus status) {
    final children = <Widget>[];

    // 头部行
    children.add(Row(
      children: [
        PollingStatusIndicator(
          status: status,
          lastUpdateTime: lastUpdateTime,
          style: PollingIndicatorStyle.badge,
          showDetails: true,
        ),
        const Spacer(),
        if (callbacks != null) ...[
          if (status == FundNavStatus.polling) ...[
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: callbacks?.onPause,
              tooltip: '暂停轮询',
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: callbacks?.onStop,
              tooltip: '停止轮询',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: callbacks?.onStart,
              tooltip: '开始轮询',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: callbacks?.onRefresh,
              tooltip: '刷新数据',
            ),
          ],
        ],
      ],
    ));

    // 间距
    children.add(const SizedBox(height: 16));

    // 信息网格
    children.add(_buildInfoGrid(status));

    // 错误信息
    if (errorMessage != null) {
      children.add(const SizedBox(height: 12));
      children.add(Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// 构建最简化面板
  Widget _buildMinimalPanel(FundNavStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          PollingStatusIndicator(
            status: status,
            style: PollingIndicatorStyle.icon,
            enableAnimation: false,
          ),
          const SizedBox(width: 8),
          Text(
            status.description,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息网格
  Widget _buildInfoGrid(FundNavStatus status) {
    return Column(
      children: [
        Row(
          children: [
            _buildInfoItem('状态', status.description),
            if (pollingInterval != null)
              _buildInfoItem('轮询间隔', '${pollingInterval!.inSeconds}秒'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoItem('跟踪基金', '$trackedFundCount个'),
            if (lastUpdateTime != null)
              _buildInfoItem('最后更新', _formatLastUpdate(lastUpdateTime!)),
          ],
        ),
      ],
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(FundNavStatus status) {
    switch (status) {
      case FundNavStatus.idle:
        return Colors.grey;
      case FundNavStatus.polling:
        return Colors.green;
      case FundNavStatus.paused:
        return Colors.orange;
      case FundNavStatus.error:
        return Colors.red;
      case FundNavStatus.updating:
        return Colors.blue;
    }
  }

  /// 格式化最后更新时间
  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}

/// 轮询面板样式
enum PollingPanelStyle {
  /// 紧凑样式
  compact,

  /// 详细样式
  detailed,

  /// 最简样式
  minimal,
}

/// 轮询控制回调
class PollingControlCallbacks {
  /// 开始/恢复轮询
  final VoidCallback? onStart;

  /// 暂停轮询
  final VoidCallback? onPause;

  /// 停止轮询
  final VoidCallback? onStop;

  /// 刷新数据
  final VoidCallback? onRefresh;

  /// 切换状态
  final VoidCallback? onToggle;

  const PollingControlCallbacks({
    this.onStart,
    this.onPause,
    this.onStop,
    this.onRefresh,
    this.onToggle,
  });
}
