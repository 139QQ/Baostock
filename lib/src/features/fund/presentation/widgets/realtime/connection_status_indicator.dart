import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/network/realtime/websocket_models.dart';
import '../../../../../core/state/realtime_connection_cubit.dart';

/// 实时连接状态指示器组件
class ConnectionStatusIndicator extends StatelessWidget {
  // ignore: public_member_api_docs
  const ConnectionStatusIndicator({
    super.key,
    this.size = 24.0,
    this.showLabel = true,
    this.textStyle,
    this.onTap,
  });

  /// 指示器大小
  final double size;

  /// 是否显示文字标签
  final bool showLabel;

  /// 自定义文字样式
  final TextStyle? textStyle;

  /// 点击回调
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RealtimeConnectionCubit, RealtimeConnectionState>(
      builder: (context, state) {
        final color = _getStatusColor(state);
        final icon = _getStatusIcon(state);
        final text = state.connectionStateDescription;

        Widget indicator = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.6,
          ),
        );

        // 如果正在连接或重连，添加动画效果
        if (state.isConnecting || state.isReconnecting) {
          indicator = _buildAnimatingIndicator(indicator);
        }

        if (showLabel) {
          final effectiveTextStyle = textStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  );

          indicator = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: effectiveTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }

        if (onTap != null) {
          indicator = GestureDetector(
            onTap: onTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: indicator,
            ),
          );
        }

        return Tooltip(
          message: _buildTooltipText(state),
          child: indicator,
        );
      },
    );
  }

  /// 构建动画指示器
  Widget _buildAnimatingIndicator(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(RealtimeConnectionState state) {
    switch (state.connectionState) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
        return Colors.orange;
      case WebSocketConnectionState.reconnecting:
        return Colors.deepOrange;
      case WebSocketConnectionState.disconnected:
        return Colors.grey;
      case WebSocketConnectionState.error:
        return Colors.red;
      case WebSocketConnectionState.closed:
        return Colors.grey[600]!;
    }
  }

  /// 获取状态图标
  IconData _getStatusIcon(RealtimeConnectionState state) {
    switch (state.connectionState) {
      case WebSocketConnectionState.connected:
        return Icons.wifi;
      case WebSocketConnectionState.connecting:
        return Icons.wifi_off;
      case WebSocketConnectionState.reconnecting:
        return Icons.refresh;
      case WebSocketConnectionState.disconnected:
        return Icons.wifi_off;
      case WebSocketConnectionState.error:
        return Icons.error_outline;
      case WebSocketConnectionState.closed:
        return Icons.close;
    }
  }

  /// 构建工具提示文本
  String _buildTooltipText(RealtimeConnectionState state) {
    final buffer = StringBuffer();
    buffer.writeln('状态: ${state.connectionStateDescription}');

    if (state.isConnected) {
      buffer.writeln('延迟: ${state.latency.toStringAsFixed(0)}ms');
      buffer.writeln('质量: ${state.qualityLevel}');

      if (state.connectionDuration != null) {
        final duration = state.connectionDuration!;
        buffer.writeln('连接时长: ${_formatDuration(duration)}');
      }
    }

    if (state.reconnectCount > 0) {
      buffer.writeln('重连次数: ${state.reconnectCount}');
    }

    if (state.hasError) {
      buffer.writeln('错误: ${state.errorMessage}');
    }

    if (state.connectionUrl != null) {
      buffer.writeln('服务器: ${state.connectionUrl}');
    }

    return buffer.toString().trim();
  }

  /// 格式化持续时间
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
}

/// 扩展的连接状态面板
class ConnectionStatusPanel extends StatelessWidget {
  /// 是否显示详细信息
  final bool showDetails;

  /// 面板宽度
  final double? width;

  const ConnectionStatusPanel({
    super.key,
    this.showDetails = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RealtimeConnectionCubit, RealtimeConnectionState>(
      builder: (context, state) {
        return Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ConnectionStatusIndicator(
                    size: 32,
                    showLabel: true,
                    onTap: () => _showConnectionDetails(context, state),
                  ),
                  const Spacer(),
                  if (state.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getQualityColor(state.stabilityScore),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.qualityLevel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
              if (showDetails) ...[
                const SizedBox(height: 16),
                _buildDetailedInfo(context, state),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 构建详细信息
  Widget _buildDetailedInfo(
      BuildContext context, RealtimeConnectionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isConnected) ...[
          _buildInfoRow(
            context,
            '延迟',
            '${state.latency.toStringAsFixed(0)}ms',
            _getLatencyColor(state.latency),
          ),
          _buildInfoRow(
            context,
            '稳定性评分',
            '${state.stabilityScore.toStringAsFixed(1)}/100',
            _getQualityColor(state.stabilityScore),
          ),
          if (state.connectionDuration != null)
            _buildInfoRow(
              context,
              '连接时长',
              _formatDuration(state.connectionDuration!),
              null,
            ),
        ],
        if (state.reconnectCount > 0)
          _buildInfoRow(
            context,
            '重连次数',
            state.reconnectCount.toString(),
            Colors.orange,
          ),
        if (state.qualityMetrics.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '质量指标',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ...state.qualityMetrics.entries.map(
            (entry) => _buildInfoRow(
              context,
              _formatMetricName(entry.key),
              _formatMetricValue(entry.value),
              null,
            ),
          ),
        ],
        if (state.hasError) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  /// 获取质量颜色
  Color _getQualityColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  /// 获取延迟颜色
  Color _getLatencyColor(double latency) {
    if (latency <= 200) return Colors.green;
    if (latency <= 500) return Colors.orange;
    return Colors.red;
  }

  /// 格式化度量名称
  String _formatMetricName(String name) {
    switch (name) {
      case 'totalMessages':
        return '总消息数';
      case 'errorCount':
        return '错误次数';
      case 'reconnectCount':
        return '重连次数';
      case 'lastLatency':
        return '最近延迟';
      case 'averageLatency':
        return '平均延迟';
      case 'connectionUptime':
        return '连接时间';
      default:
        return name;
    }
  }

  /// 格式化度量值
  String _formatMetricValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(1);
    } else if (value is int) {
      return value.toString();
    } else if (value is Duration) {
      return _formatDuration(value);
    } else {
      return value.toString();
    }
  }

  /// 格式化持续时间
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// 显示连接详情对话框
  void _showConnectionDetails(
      BuildContext context, RealtimeConnectionState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接详情'),
        content: SingleChildScrollView(
          child: ConnectionStatusPanel(
            showDetails: true,
            width: 400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          if (!state.isConnected)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<RealtimeConnectionCubit>().connect();
              },
              child: const Text('重新连接'),
            ),
        ],
      ),
    );
  }
}
