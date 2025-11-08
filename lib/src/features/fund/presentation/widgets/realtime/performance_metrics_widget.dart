import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/state/realtime_connection_cubit.dart';

/// 连接性能指标展示组件
class PerformanceMetricsWidget extends StatefulWidget {
  /// 创建性能指标展示组件
  const PerformanceMetricsWidget({
    super.key,
    this.showDetailedCharts = true,
    this.chartHeight = 200,
    this.refreshInterval = const Duration(seconds: 1),
  });

  /// 是否显示详细图表
  final bool showDetailedCharts;

  /// 图表高度
  final double chartHeight;

  /// 刷新间隔
  final Duration refreshInterval;

  @override
  State<PerformanceMetricsWidget> createState() =>
      _PerformanceMetricsWidgetState();
}

class _PerformanceMetricsWidgetState extends State<PerformanceMetricsWidget> {
  Timer? _refreshTimer;
  late RealtimeConnectionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<RealtimeConnectionCubit>();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      if (mounted) {
        _cubit.refreshConnectionStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RealtimeConnectionCubit, RealtimeConnectionState>(
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '连接性能指标',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _cubit.refreshConnectionStatus(),
                      tooltip: '刷新指标',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 核心指标卡片
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard(
                      context,
                      '延迟',
                      '${state.latency.toStringAsFixed(0)}ms',
                      _getLatencyIcon(state.latency),
                      _getLatencyColor(state.latency),
                      subtitle: _getLatencyDescription(state.latency),
                    ),
                    _buildMetricCard(
                      context,
                      '稳定性',
                      '${state.stabilityScore.toStringAsFixed(1)}%',
                      _getStabilityIcon(state.stabilityScore),
                      _getStabilityColor(state.stabilityScore),
                      subtitle: state.qualityLevel,
                    ),
                    _buildMetricCard(
                      context,
                      '重连次数',
                      state.reconnectCount.toString(),
                      Icons.refresh,
                      state.reconnectCount > 0 ? Colors.orange : Colors.green,
                      subtitle: state.reconnectCount > 0 ? '有重连' : '稳定',
                    ),
                    _buildMetricCard(
                      context,
                      '连接时长',
                      _formatDuration(
                          state.connectionDuration ?? Duration.zero),
                      Icons.access_time,
                      Colors.blue,
                      subtitle: state.isConnected ? '已连接' : '未连接',
                    ),
                  ],
                ),

                if (widget.showDetailedCharts) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '性能趋势',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: widget.chartHeight,
                    child: _buildLatencyChart(context),
                  ),
                ],

                const SizedBox(height: 16),
                _buildDetailedMetrics(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建指标卡片
  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.8),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建延迟图表
  Widget _buildLatencyChart(BuildContext context) {
    // 这里应该从实际的监控数据获取延迟历史
    // 由于我们的实现中还没有完整集成ConnectionMonitor，这里使用模拟数据
    final data = _generateMockLatencyData();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 50,
          verticalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}s',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: 100,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}ms',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.primary,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: 60,
        minY: 0,
        maxY: 500,
      ),
    );
  }

  /// 生成模拟延迟数据
  List<FlSpot> _generateMockLatencyData() {
    final data = <FlSpot>[];
    const baseLatency = 150.0;

    for (int i = 0; i <= 60; i++) {
      // 添加一些随机波动
      final variation = (sin(i * 0.3) * 50) + (Random().nextDouble() * 40 - 20);
      final latency = (baseLatency + variation).clamp(50.0, 400.0);
      data.add(FlSpot(i.toDouble(), latency));
    }

    return data;
  }

  /// 构建详细指标
  Widget _buildDetailedMetrics(
      BuildContext context, RealtimeConnectionState state) {
    return ExpansionTile(
      title: Text(
        '详细指标',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMetricSection(
                context,
                '连接信息',
                [
                  _buildMetricRow('状态', state.connectionStateDescription),
                  _buildMetricRow('连接URL', state.connectionUrl ?? '未知'),
                  _buildMetricRow(
                      '自动重连', state.autoReconnectEnabled ? '启用' : '禁用'),
                  if (state.connectionStartTime != null)
                    _buildMetricRow(
                      '连接开始时间',
                      _formatDateTime(state.connectionStartTime!),
                    ),
                  if (state.lastMessageTime != null)
                    _buildMetricRow(
                      '最后消息时间',
                      _formatDateTime(state.lastMessageTime!),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricSection(
                context,
                '质量指标',
                [
                  _buildMetricRow('质量等级', state.qualityLevel),
                  _buildMetricRow(
                      '质量评分', '${state.stabilityScore.toStringAsFixed(1)}/100'),
                  _buildMetricRow('质量颜色', state.qualityColor),
                ],
              ),
              const SizedBox(height: 16),
              if (state.qualityMetrics.isNotEmpty)
                _buildMetricSection(
                  context,
                  '原始指标',
                  state.qualityMetrics.entries
                      .map(
                        (entry) => _buildMetricRow(_formatMetricName(entry.key),
                            _formatMetricValue(entry.value)),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建指标部分
  Widget _buildMetricSection(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  /// 构建指标行
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  /// 获取延迟图标
  IconData _getLatencyIcon(double latency) {
    if (latency <= 100) return Icons.signal_cellular_alt;
    if (latency <= 200) return Icons.signal_cellular_alt_2_bar;
    if (latency <= 500) return Icons.signal_cellular_alt_1_bar;
    return Icons.signal_cellular_connected_no_internet_4_bar;
  }

  /// 获取延迟颜色
  Color _getLatencyColor(double latency) {
    if (latency <= 100) return Colors.green;
    if (latency <= 200) return Colors.lime;
    if (latency <= 500) return Colors.orange;
    return Colors.red;
  }

  /// 获取延迟描述
  String _getLatencyDescription(double latency) {
    if (latency <= 100) return '优秀';
    if (latency <= 200) return '良好';
    if (latency <= 500) return '一般';
    return '较差';
  }

  /// 获取稳定性图标
  IconData _getStabilityIcon(double score) {
    if (score >= 90) return Icons.verified;
    if (score >= 75) return Icons.thumb_up;
    if (score >= 60) return Icons.remove_circle_outline;
    return Icons.warning;
  }

  /// 获取稳定性颜色
  Color _getStabilityColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
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

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
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
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    } else if (value is Duration) {
      return _formatDuration(value);
    } else {
      return value.toString();
    }
  }
}
