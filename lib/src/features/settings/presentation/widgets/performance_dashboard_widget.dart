import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/performance/unified_performance_monitor.dart';
import '../../../../core/performance/performance_thresholds.dart';

/// 性能监控仪表板组件
///
/// 显示实时性能指标、历史趋势和性能警报
/// 支持不同时间范围的数据查看和性能状态监控
class PerformanceDashboardWidget extends StatefulWidget {
  const PerformanceDashboardWidget({super.key});

  @override
  State<PerformanceDashboardWidget> createState() =>
      _PerformanceDashboardWidgetState();
}

class _PerformanceDashboardWidgetState extends State<PerformanceDashboardWidget>
    with TickerProviderStateMixin {
  final UnifiedPerformanceMonitor _monitor = UnifiedPerformanceMonitor();
  late TabController _tabController;
  Timer? _refreshTimer;

  PerformanceSummary? _summary;
  List<PerformanceAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _summary = _monitor.getPerformanceSummary();
      _alerts = _monitor.getRecentAlerts(limit: 10);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性能监控仪表板'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '实时监控', icon: Icon(Icons.speed)),
            Tab(text: '性能指标', icon: Icon(Icons.analytics)),
            Tab(text: '警报日志', icon: Icon(Icons.warning)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRealTimeTab(),
                _buildMetricsTab(),
                _buildAlertsTab(),
              ],
            ),
    );
  }

  /// 构建实时监控标签页
  Widget _buildRealTimeTab() {
    if (_summary == null) {
      return const Center(child: Text('暂无数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 整体性能状态
          _buildOverallStatusCard(),
          const SizedBox(height: 16),

          // 关键性能指标
          _buildKeyMetricsGrid(),
          const SizedBox(height: 16),

          // 实时图表
          _buildRealTimeCharts(),
        ],
      ),
    );
  }

  /// 构建性能指标标签页
  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 指标类别选择
          _buildMetricCategorySelector(),
          const SizedBox(height: 16),

          // 详细指标列表
          _buildDetailedMetricsList(),
        ],
      ),
    );
  }

  /// 构建警报日志标签页
  Widget _buildAlertsTab() {
    return Column(
      children: [
        // 警报统计
        _buildAlertStatistics(),
        const Divider(),
        // 警报列表
        Expanded(
          child: _alerts.isEmpty
              ? const Center(child: Text('暂无性能警报'))
              : ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return _buildAlertCard(alert);
                  },
                ),
        ),
      ],
    );
  }

  /// 构建整体状态卡片
  Widget _buildOverallStatusCard() {
    final status = _summary!.overallStatus;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusText(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '整体性能状态',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建关键性能指标网格
  Widget _buildKeyMetricsGrid() {
    final keyMetrics = [
      {'name': 'search_response_time', 'label': '搜索响应时间', 'unit': 'ms'},
      {'name': 'cache_hit_rate', 'label': '缓存命中率', 'unit': '%'},
      {'name': 'memory_usage', 'label': '内存使用', 'unit': 'MB'},
      {'name': 'cpu_usage', 'label': 'CPU使用率', 'unit': '%'},
      {'name': 'frame_rate', 'label': '帧率', 'unit': 'FPS'},
      {'name': 'api_success_rate', 'label': 'API成功率', 'unit': '%'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: keyMetrics.length,
      itemBuilder: (context, index) {
        final metric = keyMetrics[index];
        return _buildMetricCard(
          metric['name'] as String,
          metric['label'] as String,
          metric['unit'] as String,
        );
      },
    );
  }

  /// 构建性能指标卡片
  Widget _buildMetricCard(String metricName, String label, String unit) {
    final currentMetric = _monitor.getCurrentMetric(metricName);
    final predefinedMetric = PredefinedMetrics.metrics
        .where((m) => m.name == metricName)
        .firstOrNull;

    if (currentMetric == null || predefinedMetric == null) {
      return _buildEmptyMetricCard(label);
    }

    final status = predefinedMetric.getStatus(currentMetric.value);
    final statusColor = _getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  currentMetric.formattedValue,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空指标卡片
  Widget _buildEmptyMetricCard(String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              '--',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建实时图表
  Widget _buildRealTimeCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '性能趋势',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildPerformanceChart(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建性能图表
  Widget _buildPerformanceChart() {
    // 这里应该使用真实的图表库（如fl_chart）
    // 目前使用占位符
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('性能趋势图表', style: TextStyle(color: Colors.grey)),
            Text('(待实现)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// 构建指标类别选择器
  Widget _buildMetricCategorySelector() {
    final categories = [
      {'id': 'all', 'label': '全部', 'icon': Icons.dashboard},
      {'id': 'response_time', 'label': '响应时间', 'icon': Icons.speed},
      {'id': 'cache', 'label': '缓存性能', 'icon': Icons.cached},
      {'id': 'memory', 'label': '内存使用', 'icon': Icons.memory},
      {'id': 'network', 'label': '网络性能', 'icon': Icons.network_check},
      {'id': 'ui', 'label': 'UI性能', 'icon': Icons.phone_android},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category['icon'] as IconData, size: 16),
                  const SizedBox(width: 4),
                  Text(category['label'] as String),
                ],
              ),
              onSelected: (selected) {
                // TODO: 实现类别筛选
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建详细指标列表
  Widget _buildDetailedMetricsList() {
    final allMetrics = _monitor.getAllCurrentMetrics();

    return Card(
      child: ListView(
        shrinkWrap: true,
        children: allMetrics.entries.map((entry) {
          return _buildDetailedMetricTile(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  /// 构建详细指标列表项
  Widget _buildDetailedMetricTile(String name, PerformanceDataPoint dataPoint) {
    final predefinedMetric =
        PredefinedMetrics.metrics.where((m) => m.name == name).firstOrNull;

    return ListTile(
      leading: Icon(
        _getMetricIcon(predefinedMetric?.category),
        color: _getMetricColor(predefinedMetric?.category),
      ),
      title: Text(predefinedMetric?.description ?? name),
      subtitle: Text('最后更新: ${_formatTime(dataPoint.timestamp)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dataPoint.formattedValue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (predefinedMetric != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    _getStatusColor(predefinedMetric.getStatus(dataPoint.value))
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(predefinedMetric.getStatus(dataPoint.value)),
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(
                      predefinedMetric.getStatus(dataPoint.value)),
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // TODO: 显示指标详情
      },
    );
  }

  /// 构建警报统计
  Widget _buildAlertStatistics() {
    final criticalAlerts =
        _alerts.where((a) => a.status == PerformanceStatus.critical).length;
    final warningAlerts =
        _alerts.where((a) => a.status == PerformanceStatus.warning).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildAlertStatCard('严重警报', criticalAlerts, Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildAlertStatCard('警告警报', warningAlerts, Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildAlertStatCard('总警报数', _alerts.length, Colors.blue),
          ),
        ],
      ),
    );
  }

  /// 构建警报统计卡片
  Widget _buildAlertStatCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建警报卡片
  Widget _buildAlertCard(PerformanceAlert alert) {
    final metric = PredefinedMetrics.metrics
        .where((m) => m.name == alert.metricName)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(alert.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(alert.status),
            color: _getStatusColor(alert.status),
          ),
        ),
        title: Text(metric?.description ?? alert.metricName),
        subtitle: Text(
            '当前值: ${alert.value.toStringAsFixed(2)}, 阈值: ${alert.threshold.toStringAsFixed(2)}'),
        trailing: Text(
          _formatTime(alert.timestamp),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  // ========== 辅助方法 ==========

  Color _getStatusColor(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.optimal:
        return Colors.green;
      case PerformanceStatus.good:
        return Colors.blue;
      case PerformanceStatus.warning:
        return Colors.orange;
      case PerformanceStatus.critical:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.optimal:
        return Icons.check_circle;
      case PerformanceStatus.good:
        return Icons.thumb_up;
      case PerformanceStatus.warning:
        return Icons.warning;
      case PerformanceStatus.critical:
        return Icons.error;
    }
  }

  String _getStatusText(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.optimal:
        return '最优';
      case PerformanceStatus.good:
        return '良好';
      case PerformanceStatus.warning:
        return '警告';
      case PerformanceStatus.critical:
        return '危险';
    }
  }

  IconData _getMetricIcon(PerformanceCategory? category) {
    switch (category) {
      case PerformanceCategory.responseTime:
        return Icons.speed;
      case PerformanceCategory.cache:
        return Icons.cached;
      case PerformanceCategory.memory:
        return Icons.memory;
      case PerformanceCategory.cpu:
        return Icons.memory;
      case PerformanceCategory.network:
        return Icons.network_check;
      case PerformanceCategory.ui:
        return Icons.phone_android;
      case PerformanceCategory.business:
        return Icons.business_center;
      default:
        return Icons.analytics;
    }
  }

  Color _getMetricColor(PerformanceCategory? category) {
    switch (category) {
      case PerformanceCategory.responseTime:
        return Colors.blue;
      case PerformanceCategory.cache:
        return Colors.green;
      case PerformanceCategory.memory:
        return Colors.orange;
      case PerformanceCategory.cpu:
        return Colors.red;
      case PerformanceCategory.network:
        return Colors.purple;
      case PerformanceCategory.ui:
        return Colors.cyan;
      case PerformanceCategory.business:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
