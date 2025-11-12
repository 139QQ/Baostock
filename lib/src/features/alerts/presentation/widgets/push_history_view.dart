import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/push_history_record.dart';
import '../cubits/push_history_cubit.dart';

/// 推送历史查看界面
///
/// 提供推送历史记录的查看和管理功能，包括：
/// - 历史记录列表展示
/// - 搜索和过滤功能
/// - 详情查看和操作
/// - 统计数据展示
/// - 数据导出功能
class PushHistoryView extends StatefulWidget {
  /// 创建推送历史查看界面
  const PushHistoryView({super.key});

  @override
  State<PushHistoryView> createState() => _PushHistoryViewState();
}

class _PushHistoryViewState extends State<PushHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    // 初始化加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PushHistoryCubit>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PushHistoryCubit>().add(LoadMorePushHistory());
    }
  }

  void _onSearchChanged(String value) {
    // 延迟搜索，避免频繁请求
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        _performSearch(value);
      }
    });
  }

  void _performSearch(String keyword) {
    if (keyword.trim().isEmpty) {
      context.read<PushHistoryCubit>().add(ClearFilter());
    } else {
      context.read<PushHistoryCubit>().search(keyword: keyword.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推送历史'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '历史记录', icon: Icon(Icons.history)),
            Tab(text: '统计分析', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PushHistoryCubit>().refresh();
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('导出数据'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('全部标记已读'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('高级筛选'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // 搜索栏
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索推送内容...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<PushHistoryCubit>().add(ClearFilter());
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // 过滤器提示
        BlocBuilder<PushHistoryCubit, PushHistoryState>(
          builder: (context, state) {
            if (state.filter.hasActiveFilter) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16),
                    const SizedBox(width: 8),
                    const Text('已应用过滤器'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        context.read<PushHistoryCubit>().add(ClearFilter());
                      },
                      child: const Text('清除'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // 历史记录列表
        Expanded(
          child: BlocBuilder<PushHistoryCubit, PushHistoryState>(
            builder: (context, state) {
              if (state.status == PushHistoryStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == PushHistoryStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? '未知错误',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PushHistoryCubit>().refresh();
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }

              if (state.records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        '暂无推送记录',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '您还没有收到任何推送通知',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PushHistoryCubit>().refresh();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      state.records.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.records.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final record = state.records[index];
                    return _buildPushRecordCard(record);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPushRecordCard(PushHistoryRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showPushDetails(record),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：标题和时间
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: record.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildPriorityChip(record.priority),
                            const SizedBox(width: 8),
                            _buildTypeChip(record.pushType),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDateTime(record.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (record.isRead)
                            const Icon(Icons.mark_email_read,
                                size: 16, color: Colors.green)
                          else
                            const Icon(Icons.mark_email_unread,
                                size: 16, color: Colors.orange),
                          if (record.isClicked) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.touch_app,
                                size: 16, color: Colors.blue),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 内容预览
              Text(
                record.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // 底部操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!record.isRead)
                        TextButton.icon(
                          onPressed: () {
                            context
                                .read<PushHistoryCubit>()
                                .add(MarkAsRead(record.id));
                          },
                          icon: const Icon(Icons.mark_email_read, size: 16),
                          label: const Text('标记已读'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (record.userFeedback == null) ...[
                        const SizedBox(width: 8),
                        _buildFeedbackButtons(record),
                      ],
                    ],
                  ),
                  Text(
                    record.ageDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    String label;

    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        color = Colors.red;
        label = '高';
        break;
      case 'medium':
        color = Colors.orange;
        label = '中';
        break;
      default:
        color = Colors.grey;
        label = '低';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    String label;

    switch (type.toLowerCase()) {
      case 'market_change':
        label = '市场';
        break;
      case 'fund_update':
        label = '基金';
        break;
      case 'investment_advice':
        label = '建议';
        break;
      case 'system':
        label = '系统';
        break;
      default:
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeedbackButtons(PushHistoryRecord record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            context
                .read<PushHistoryCubit>()
                .add(SetUserFeedback(record.id, 'like'));
          },
          icon: const Icon(Icons.thumb_up, size: 16),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        IconButton(
          onPressed: () {
            context
                .read<PushHistoryCubit>()
                .add(SetUserFeedback(record.id, 'dislike'));
          },
          icon: const Icon(Icons.thumb_down, size: 16),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计概览
          BlocBuilder<PushHistoryCubit, PushHistoryState>(
            builder: (context, state) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '统计概览',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              '总推送',
                              state.records.length.toString(),
                              Icons.notifications,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              '已读',
                              context
                                  .read<PushHistoryCubit>()
                                  .readCount
                                  .toString(),
                              Icons.mark_email_read,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              '点击',
                              context
                                  .read<PushHistoryCubit>()
                                  .clickedCount
                                  .toString(),
                              Icons.touch_app,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              '未读',
                              context
                                  .read<PushHistoryCubit>()
                                  .unreadCount
                                  .toString(),
                              Icons.mark_email_unread,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 推送类型分布
          BlocBuilder<PushHistoryCubit, PushHistoryState>(
            builder: (context, state) {
              final typeStats = context.read<PushHistoryCubit>().recordsByType;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '推送类型分布',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      for (final entry in typeStats.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(_getTypeDisplayName(entry.key)),
                              const Spacer(),
                              Text(
                                  '${entry.value} ${state.records.isNotEmpty ? (entry.value / state.records.length * 100).toStringAsFixed(1) : '0.0'}%'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 优先级分布
          BlocBuilder<PushHistoryCubit, PushHistoryState>(
            builder: (context, state) {
              final priorityStats =
                  context.read<PushHistoryCubit>().recordsByPriority;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '优先级分布',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      for (final entry in priorityStats.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              _buildPriorityChip(entry.key),
                              const SizedBox(width: 8),
                              Text(
                                  '${entry.value} ${state.records.isNotEmpty ? (entry.value / state.records.length * 100).toStringAsFixed(1) : '0.0'}%'),
                              const Spacer(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'market_change':
        return '市场变化';
      case 'fund_update':
        return '基金更新';
      case 'investment_advice':
        return '投资建议';
      case 'system':
        return '系统通知';
      default:
        return type;
    }
  }

  void _showPushDetails(PushHistoryRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '时间: ${_formatDateTime(record.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip(record.priority),
                  const SizedBox(width: 8),
                  _buildTypeChip(record.pushType),
                ],
              ),
              const SizedBox(height: 16),
              Text(record.content),
              const SizedBox(height: 16),
              if (record.relatedFundCodes.isNotEmpty) ...[
                const Text(
                  '相关基金:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(record.relatedFundCodes.join(', ')),
                const SizedBox(height: 8),
              ],
              if (record.relatedEventIds.isNotEmpty) ...[
                const Text(
                  '相关事件:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(record.relatedEventIds.join(', ')),
                const SizedBox(height: 8),
              ],
              const Text(
                '状态:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(record.statusDescription),
            ],
          ),
        ),
        actions: [
          if (!record.isRead)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<PushHistoryCubit>().add(MarkAsRead(record.id));
              },
              child: const Text('标记已读'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'filter':
        _showFilterDialog();
        break;
    }
  }

  Future<void> _exportData() async {
    try {
      final cubit = context.read<PushHistoryCubit>();
      await cubit.exportHistory();

      // 这里应该保存文件到设备
      AppLogger.info('✅ PushHistoryView: Data exported');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据导出成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('❌ PushHistoryView: Failed to export data', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markAllAsRead() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全部标记已读'),
        content: const Text('确定要将所有推送标记为已读吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PushHistoryCubit>().add(MarkAllAsRead());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已全部标记为已读'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('高级筛选'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 这里可以添加更多的筛选选项
            Text('高级筛选功能开发中...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
