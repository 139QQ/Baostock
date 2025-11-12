import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 轮询状态指示器
///
/// 显示当前轮询状态的可视化组件
class PollingStatusIndicator extends StatefulWidget {
  final bool isActive;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;
  final int? updateCount;
  final PollingStatusStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePolling;

  const PollingStatusIndicator({
    Key? key,
    required this.isActive,
    required this.isLoading,
    this.error,
    this.lastUpdate,
    this.updateCount,
    this.style = PollingStatusStyle.compact,
    this.onTap,
    this.onTogglePolling,
  }) : super(key: key);

  @override
  State<PollingStatusIndicator> createState() => _PollingStatusIndicatorState();
}

class _PollingStatusIndicatorState extends State<PollingStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(PollingStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _rotationController.stop();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case PollingStatusStyle.compact:
        return _buildCompactIndicator();
      case PollingStatusStyle.detailed:
        return _buildDetailedIndicator();
      case PollingStatusStyle.minimal:
        return _buildMinimalIndicator();
      case PollingStatusStyle.card:
        return _buildCardIndicator();
    }
  }

  /// 构建紧凑风格指示器
  Widget _buildCompactIndicator() {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getBorderColor(),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.error != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.warning,
                      size: 14,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建详细风格指示器
  Widget _buildDetailedIndicator() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: _getGradient(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: widget.isLoading
                            ? _rotationAnimation.value * 2 * math.pi
                            : 0,
                        child: child,
                      );
                    },
                    child: _buildStatusIcon(size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '数据轮询状态',
                          style: TextStyle(
                            color: _getTextColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusDescription(),
                          style: TextStyle(
                            color: _getTextColor().withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onTogglePolling != null)
                    IconButton(
                      onPressed: widget.onTogglePolling,
                      icon: Icon(
                        widget.isActive ? Icons.pause : Icons.play_arrow,
                        color: _getTextColor(),
                        size: 20,
                      ),
                      tooltip: widget.isActive ? '暂停轮询' : '开始轮询',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem('状态', _getStatusText()),
                  _buildInfoItem('更新次数', '${widget.updateCount ?? 0}'),
                  _buildInfoItem('最后更新', _formatTime(widget.lastUpdate)),
                ],
              ),
              if (widget.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建极简风格指示器
  Widget _buildMinimalIndicator() {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive ? _pulseAnimation.value : 1.0,
            child: Icon(
              _getIcon(),
              size: 16,
              color: _getIconColor(),
            ),
          );
        },
      ),
    );
  }

  /// 构建卡片风格指示器
  Widget _buildCardIndicator() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 3,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getCardGradientColors(),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: widget.isLoading
                            ? _rotationAnimation.value * 2 * math.pi
                            : 0,
                        child: child,
                      );
                    },
                    child: Icon(
                      _getIcon(),
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getStatusText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusDescription(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCardInfoItem('更新', '${widget.updateCount ?? 0}'),
                  _buildCardInfoItem('时间', _formatTime(widget.lastUpdate)),
                ],
              ),
              if (widget.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '错误: ${widget.error}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon({double size = 16}) {
    return Icon(
      _getIcon(),
      size: size,
      color: _getIconColor(),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _getTextColor().withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: _getTextColor(),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 构建卡片信息项
  Widget _buildCardInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 获取图标
  IconData _getIcon() {
    if (widget.error != null) {
      return Icons.error_outline;
    } else if (widget.isLoading) {
      return Icons.sync;
    } else if (widget.isActive) {
      return Icons.sync_problem;
    } else {
      return Icons.sync_disabled;
    }
  }

  /// 获取图标颜色
  Color _getIconColor() {
    if (widget.error != null) {
      return Colors.red;
    } else if (widget.isActive) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    if (widget.error != null) {
      return Colors.red.withOpacity(0.1);
    } else if (widget.isActive) {
      return Colors.green.withOpacity(0.1);
    } else {
      return Colors.grey.withOpacity(0.1);
    }
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    if (widget.error != null) {
      return Colors.red.withOpacity(0.3);
    } else if (widget.isActive) {
      return Colors.green.withOpacity(0.3);
    } else {
      return Colors.grey.withOpacity(0.3);
    }
  }

  /// 获取文字颜色
  Color _getTextColor() {
    if (widget.error != null) {
      return Colors.red[700]!;
    } else if (widget.isActive) {
      return Colors.green[700]!;
    } else {
      return Colors.grey[700]!;
    }
  }

  /// 获取渐变
  LinearGradient _getGradient() {
    if (widget.error != null) {
      return LinearGradient(
        colors: [
          Colors.red[400]!,
          Colors.red[600]!,
        ],
      );
    } else if (widget.isActive) {
      return LinearGradient(
        colors: [
          Colors.green[400]!,
          Colors.green[600]!,
        ],
      );
    } else {
      return LinearGradient(
        colors: [
          Colors.grey[400]!,
          Colors.grey[600]!,
        ],
      );
    }
  }

  /// 获取卡片渐变颜色
  List<Color> _getCardGradientColors() {
    if (widget.error != null) {
      return [Colors.red[400]!, Colors.red[700]!];
    } else if (widget.isActive) {
      return [Colors.green[400]!, Colors.green[700]!];
    } else {
      return [Colors.grey[400]!, Colors.grey[700]!];
    }
  }

  /// 获取状态文本
  String _getStatusText() {
    if (widget.error != null) {
      return '错误';
    } else if (widget.isLoading) {
      return '更新中';
    } else if (widget.isActive) {
      return '活动中';
    } else {
      return '已停止';
    }
  }

  /// 获取状态描述
  String _getStatusDescription() {
    if (widget.error != null) {
      return '数据获取出现错误';
    } else if (widget.isLoading) {
      return '正在获取最新数据';
    } else if (widget.isActive) {
      return '实时轮询已启用';
    } else {
      return '实时轮询已暂停';
    }
  }

  /// 格式化时间
  String _formatTime(DateTime? time) {
    if (time == null) return '未知';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
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
enum PollingStatusStyle {
  /// 紧凑风格
  compact,

  /// 详细风格
  detailed,

  /// 极简风格
  minimal,

  /// 卡片风格
  card,
}

/// 轮询状态指示器扩展功能
class PollingStatusIndicatorExtensions {
  /// 创建带动画的状态指示器
  static Widget withAnimation({
    required Widget child,
    required bool isActive,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimatedContainer(
      duration: duration,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  /// 创建带工具提示的指示器
  static Widget withTooltip({
    required Widget child,
    required String message,
  }) {
    return Tooltip(
      message: message,
      child: child,
    );
  }

  /// 创建可点击的指示器
  static Widget withClickEffect({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.blue.withOpacity(0.1),
      highlightColor: Colors.blue.withOpacity(0.05),
      child: child,
    );
  }
}
