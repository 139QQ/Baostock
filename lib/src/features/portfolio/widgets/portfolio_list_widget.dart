import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/portfolio_bloc.dart';
import '../../../services/portfolio_analysis_service.dart';

/// 投资组合列表组件
class PortfolioListWidget extends StatelessWidget {
  const PortfolioListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is PortfolioError) {
          return _buildErrorState(context, state);
        }

        if (state is PortfolioLoaded) {
          if (state.portfolios.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildPortfolioList(context, state.portfolios);
        }

        return const Center(
          child: Text('未知状态'),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无投资组合',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建您的第一个投资组合，开始智能投资',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // 切换到创建组合标签页
              DefaultTabController.of(context).animateTo(1);
            },
            icon: const Icon(Icons.add),
            label: const Text('创建投资组合'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioList(BuildContext context, List<Portfolio> portfolios) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PortfolioBloc>().add(LoadPortfolios());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: portfolios.length,
        itemBuilder: (context, index) {
          final portfolio = portfolios[index];
          return _PortfolioCard(
            portfolio: portfolio,
            onTap: () => _showPortfolioDetails(context, portfolio),
            onEdit: () => _editPortfolio(context, portfolio),
            onDelete: () => _deletePortfolio(context, portfolio),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PortfolioError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<PortfolioBloc>().add(LoadPortfolios());
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _showPortfolioDetails(BuildContext context, Portfolio portfolio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PortfolioDetailsSheet(portfolio: portfolio),
    );
  }

  void _editPortfolio(BuildContext context, Portfolio portfolio) {
    // TODO: 实现编辑投资组合功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中')),
    );
  }

  void _deletePortfolio(BuildContext context, Portfolio portfolio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除投资组合"${portfolio.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PortfolioBloc>().add(DeletePortfolio(portfolio.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 投资组合卡片
class _PortfolioCard extends StatelessWidget {
  final Portfolio portfolio;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PortfolioCard({
    required this.portfolio,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (portfolio.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            portfolio.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMetricChip(
                    context,
                    '策略',
                    portfolio.strategy.displayName,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    context,
                    '持仓',
                    '${portfolio.holdings.length}只',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                    context,
                    '创建时间',
                    _formatDate(portfolio.createdAt),
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      '预期收益率',
                      '${(portfolio.metrics.totalExpectedReturn * 100).toStringAsFixed(2)}%',
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      '波动率',
                      '${(portfolio.metrics.volatility * 100).toStringAsFixed(2)}%',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      '夏普比率',
                      portfolio.metrics.sharpeRatio.toStringAsFixed(2),
                      portfolio.metrics.sharpeRatio > 1
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}';
  }
}

/// 投资组合详情底部弹窗
class _PortfolioDetailsSheet extends StatelessWidget {
  final Portfolio portfolio;

  const _PortfolioDetailsSheet({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            portfolio.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (portfolio.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        portfolio.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildDetailSection(
                      context,
                      '组合指标',
                      [
                        _DetailItem('预期收益率',
                            '${(portfolio.metrics.totalExpectedReturn * 100).toStringAsFixed(2)}%'),
                        _DetailItem('年化波动率',
                            '${(portfolio.metrics.volatility * 100).toStringAsFixed(2)}%'),
                        _DetailItem('夏普比率',
                            portfolio.metrics.sharpeRatio.toStringAsFixed(2)),
                        _DetailItem('最大回撤',
                            '${(portfolio.metrics.maxDrawdown * 100).toStringAsFixed(2)}%'),
                        _DetailItem('Beta系数',
                            portfolio.metrics.beta.toStringAsFixed(2)),
                        _DetailItem('分散度评分',
                            '${portfolio.metrics.diversificationScore.toStringAsFixed(0)}分'),
                        _DetailItem('集中度风险',
                            '${(portfolio.metrics.concentrationRisk * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailSection(
                      context,
                      '持仓明细',
                      portfolio.holdings
                          .map((holding) => _DetailItem(
                                holding.fundName,
                                '${(holding.weight * 100).toStringAsFixed(1)}%',
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(
      BuildContext context, String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem(this.label, this.value);
}
