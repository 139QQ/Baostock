import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/logger.dart';
import '../cubits/index_trend_cubit.dart';
import '../cubits/market_index_cubit.dart';
import '../widgets/index_trend_chart.dart';
import '../widgets/market_index_card.dart';
import '../widgets/polling_status_indicator.dart';

/// 市场指数页面
///
/// 展示主要市场指数的准实时数据，包括价格、变化和趋势分析
class MarketIndexPage extends StatefulWidget {
  /// 创建市场指数页面
  const MarketIndexPage({super.key});

  @override
  State<MarketIndexPage> createState() => _MarketIndexPageState();
}

class _MarketIndexPageState extends State<MarketIndexPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 启动指数数据轮询
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMarketData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 初始化市场数据
  Future<void> _initializeMarketData() async {
    try {
      final cubit = context.read<MarketIndexCubit>();
      await cubit.startPolling();
      AppLogger.info('市场指数数据轮询已启动');
    } catch (e) {
      AppLogger.error('启动市场指数数据轮询失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动指数数据失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 刷新指数数据
  Future<void> _refreshData() async {
    try {
      final cubit = context.read<MarketIndexCubit>();
      await cubit.refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('指数数据已刷新'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('刷新指数数据失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 切换轮询状态
  Future<void> _togglePolling() async {
    try {
      final cubit = context.read<MarketIndexCubit>();

      if (cubit.state.isPolling) {
        await cubit.stopPolling();
        setState(() {
          _autoRefresh = false;
        });
      } else {
        await cubit.startPolling();
        setState(() {
          _autoRefresh = true;
        });
      }
    } catch (e) {
      AppLogger.error('切换轮询状态失败', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('市场指数'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '主要指数', icon: Icon(Icons.trending_up)),
            Tab(text: '趋势分析', icon: Icon(Icons.analytics)),
            Tab(text: '设置', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          // 轮询状态指示器
          BlocBuilder<MarketIndexCubit, MarketIndexState>(
            builder: (context, state) {
              return PollingStatusIndicator(
                isActive: state.isPolling,
                isLoading: state.isLoading,
                error: state.errorMessage,
                lastUpdate: state.lastUpdateTime,
                updateCount: state.updateCount,
                onTogglePolling: _togglePolling,
              );
            },
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMainIndicesTab(),
          _buildTrendAnalysisTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  /// 构建主要指数标签页
  Widget _buildMainIndicesTab() {
    return BlocBuilder<MarketIndexCubit, MarketIndexState>(
      builder: (context, state) {
        if (state.isLoading && state.indices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载指数数据...'),
              ],
            ),
          );
        }

        if (state.errorMessage != null && state.indices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (state.indices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text('暂无指数数据'),
                SizedBox(height: 8),
                Text('请稍后重试'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              // 状态信息栏
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Row(
                  children: [
                    Icon(
                      state.isPolling ? Icons.sync : Icons.sync_disabled,
                      size: 20,
                      color: state.isPolling ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isPolling ? '自动更新中' : '已暂停',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '更新次数: ${state.updateCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    if (state.lastUpdateTime != null)
                      Text(
                        '最后更新: ${_formatTime(state.lastUpdateTime!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              // 指数卡片列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.indices.length,
                  itemBuilder: (context, index) {
                    final indexData = state.indices[index];
                    return MarketIndexCard(
                      indexData: indexData,
                      onTap: () => _showIndexDetail(indexData),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建趋势分析标签页
  Widget _buildTrendAnalysisTab() {
    return BlocBuilder<IndexTrendCubit, IndexTrendState>(
      builder: (context, trendState) {
        return BlocBuilder<MarketIndexCubit, MarketIndexState>(
          builder: (context, indexState) {
            if (indexState.indices.isEmpty) {
              return const Center(
                child: Text('暂无指数数据可供分析'),
              );
            }

            return Column(
              children: [
                // 指数选择器
                Container(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: trendState.selectedIndexCode ??
                        (indexState.indices.isNotEmpty
                            ? indexState.indices.first.code
                            : null),
                    decoration: const InputDecoration(
                      labelText: '选择指数',
                      border: OutlineInputBorder(),
                    ),
                    items: indexState.indices.map((index) {
                      return DropdownMenuItem<String>(
                        value: index.code,
                        child: Text('${index.name} (${index.code})'),
                      );
                    }).toList(),
                    onChanged: (code) {
                      if (code != null) {
                        context.read<IndexTrendCubit>().selectIndex(code);
                      }
                    },
                  ),
                ),
                // 趋势图表
                Expanded(
                  child: trendState.selectedIndexCode != null
                      ? IndexTrendChart(
                          historicalData: trendState.historicalData,
                          indexCode: trendState.selectedIndexCode!,
                          indexName: indexState.indices
                              .firstWhere(
                                (index) =>
                                    index.code == trendState.selectedIndexCode,
                                orElse: () => indexState.indices.first,
                              )
                              .name,
                        )
                      : const Center(
                          child: Text('请选择要分析的指数'),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 构建设置标签页
  Widget _buildSettingsTab() {
    return BlocBuilder<MarketIndexCubit, MarketIndexState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 自动刷新设置
            Card(
              child: ListTile(
                title: const Text('自动刷新'),
                subtitle: const Text('启用自动数据更新'),
                leading: const Icon(Icons.refresh),
                trailing: Switch(
                  value: _autoRefresh,
                  onChanged: (value) {
                    if (value != _autoRefresh) {
                      _togglePolling();
                    }
                  },
                ),
              ),
            ),

            // 刷新间隔设置
            Card(
              child: ListTile(
                title: const Text('刷新间隔'),
                subtitle: Text('${state.pollingInterval.inSeconds}秒'),
                leading: const Icon(Icons.schedule),
                trailing: PopupMenuButton<Duration>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (duration) {
                    context
                        .read<MarketIndexCubit>()
                        .setPollingInterval(duration);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: Duration(seconds: 15),
                      child: Text('15秒'),
                    ),
                    const PopupMenuItem(
                      value: Duration(seconds: 30),
                      child: Text('30秒'),
                    ),
                    const PopupMenuItem(
                      value: Duration(seconds: 60),
                      child: Text('1分钟'),
                    ),
                    const PopupMenuItem(
                      value: Duration(seconds: 120),
                      child: Text('2分钟'),
                    ),
                  ],
                ),
              ),
            ),

            // 跟踪的指数
            Card(
              child: ExpansionTile(
                title: const Text('跟踪的指数'),
                subtitle: Text('${state.indices.length}个指数'),
                leading: const Icon(Icons.list),
                children: state.indices.map((index) {
                  return ListTile(
                    title: Text(index.name),
                    subtitle: Text(index.code),
                    trailing: Text(
                      index.currentValue.toString(),
                      style: TextStyle(
                        color: index.isRising
                            ? Colors.red
                            : index.isFalling
                                ? Colors.green
                                : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 统计信息
            Card(
              child: ListTile(
                title: const Text('统计信息'),
                subtitle: Text('更新次数: ${state.updateCount}'),
                leading: const Icon(Icons.analytics),
                onTap: () => _showStatisticsDialog(state),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 显示指数详情
  void _showIndexDetail(dynamic indexData) {
    // 这里可以实现指数详情页面
    AppLogger.info('显示指数详情: ${indexData.code}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('指数详情功能开发中: ${indexData.name}')),
    );
  }

  /// 显示统计信息对话框
  void _showStatisticsDialog(MarketIndexState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('统计信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('跟踪指数数量: ${state.indices.length}'),
            const SizedBox(height: 8),
            Text('更新次数: ${state.updateCount}'),
            const SizedBox(height: 8),
            Text('轮询间隔: ${state.pollingInterval.inSeconds}秒'),
            const SizedBox(height: 8),
            Text('自动刷新: ${state.isPolling ? '开启' : '关闭'}'),
            if (state.lastUpdateTime != null) ...[
              const SizedBox(height: 8),
              Text('最后更新: ${_formatTime(state.lastUpdateTime!)}'),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                '最后错误: ${state.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
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
