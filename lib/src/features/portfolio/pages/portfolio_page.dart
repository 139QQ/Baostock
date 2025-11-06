import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/portfolio_bloc.dart';
import '../../../services/portfolio_analysis_service.dart';
import '../../../services/high_performance_fund_service.dart';
import '../../../services/fund_analysis_service.dart';
import '../widgets/portfolio_list_widget.dart';
import '../widgets/portfolio_create_dialog.dart';

/// 投资组合页面
class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortfolioBloc(
        portfolioService: PortfolioAnalysisService(),
        analysisService: FundAnalysisService(),
        fundService: HighPerformanceFundService(),
      )
        ..add(LoadPortfolios())
        ..add(const LoadRecommendedFunds()),
      child: const PortfolioView(),
    );
  }
}

/// 投资组合视图
class PortfolioView extends StatefulWidget {
  const PortfolioView({super.key});

  @override
  State<PortfolioView> createState() => _PortfolioViewState();
}

class _PortfolioViewState extends State<PortfolioView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投资组合'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我的组合', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: '创建组合', icon: Icon(Icons.add_circle)),
            Tab(text: '市场分析', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showPortfolioHelp(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is PortfolioError) {
            return _buildErrorState(context, state);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMyPortfoliosTab(context),
              _buildCreatePortfolioTab(context),
              _buildMarketAnalysisTab(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMyPortfoliosTab(BuildContext context) {
    return const PortfolioListWidget();
  }

  Widget _buildCreatePortfolioTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快速创建卡片
          _buildQuickCreateCard(context),

          const SizedBox(height: 24),

          // 推荐基金
          _buildRecommendedFunds(context),

          const SizedBox(height: 24),

          // 创建指南
          _buildCreationGuide(context),
        ],
      ),
    );
  }

  Widget _buildMarketAnalysisTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 市场概览
          _buildMarketOverview(context),

          const SizedBox(height: 24),

          // 策略推荐
          _buildStrategyRecommendations(context),

          const SizedBox(height: 24),

          // 风险提示
          _buildRiskWarning(context),
        ],
      ),
    );
  }

  Widget _buildQuickCreateCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '快速创建投资组合',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '根据您的风险偏好和投资目标，智能推荐适合的基金组合',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showCreatePortfolioDialog(
                      context, PortfolioStrategy.balanced);
                },
                icon: const Icon(Icons.rocket_launch),
                label: const Text('智能创建'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedFunds(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '推荐基金',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<PortfolioBloc, PortfolioState>(
          builder: (context, state) {
            if (state is PortfolioLoading) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is PortfolioLoaded) {
              if (state.recommendedFunds.isEmpty) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无推荐基金',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context
                                .read<PortfolioBloc>()
                                .add(const LoadRecommendedFunds());
                          },
                          child: const Text('点击加载'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.recommendedFunds.length,
                  itemBuilder: (context, index) {
                    final fund = state.recommendedFunds[index];
                    return _buildRecommendedFundCard(context, fund);
                  },
                ),
              );
            }

            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '推荐基金加载中...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        context
                            .read<PortfolioBloc>()
                            .add(const LoadRecommendedFunds());
                      },
                      child: const Text('手动加载'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedFundCard(
      BuildContext context, FundRecommendation fund) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(fund.score).withOpacity(0.1),
          child: Text(
            fund.score.toString(),
            style: TextStyle(
              color: _getScoreColor(fund.score),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          fund.fundName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fund.fundCode} • ${fund.fundType}'),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRiskChip(fund.riskLevel),
                const SizedBox(width: 8),
                Text(
                  '夏普: ${fund.sharpeScore}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '收益: ${fund.returnScore}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () {
            _addFundToPortfolio(context, fund);
          },
          icon: const Icon(Icons.add_circle, color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildRiskChip(String riskLevel) {
    Color color;
    switch (riskLevel.toLowerCase()) {
      case '低':
        color = Colors.green;
        break;
      case '中':
        color = Colors.orange;
        break;
      case '高':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        riskLevel,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  void _addFundToPortfolio(BuildContext context, FundRecommendation fund) {
    // 切换到我的组合标签页并提示用户
    DefaultTabController.of(context).animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已选择 ${fund.fundName}，请在创建组合时添加'),
        action: SnackBarAction(
          label: '创建组合',
          onPressed: () {
            DefaultTabController.of(context).animateTo(1);
          },
        ),
      ),
    );
  }

  Widget _buildCreationGuide(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '创建投资组合指南',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideStep(context, '1', '选择投资策略', '根据您的风险承受能力选择合适的投资策略'),
            _buildGuideStep(context, '2', '添加基金产品', '从推荐列表中添加基金到您的组合'),
            _buildGuideStep(context, '3', '调整配置权重', '合理分配资金到不同的基金产品'),
            _buildGuideStep(context, '4', '分析风险收益', '查看组合的风险指标和预期收益'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(
      BuildContext context, String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketOverview(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 28,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 12),
                Text(
                  '市场概览',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMarketMetric(
                context, '沪深300指数', '3,856.23', '+1.23%', Colors.green),
            _buildMarketMetric(
                context, '创业板指数', '2,234.56', '-0.45%', Colors.red),
            _buildMarketMetric(
                context, '基金平均收益率', '8.56%', '+0.23%', Colors.green),
            _buildMarketMetric(context, '市场波动率', '15.2%', '正常', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketMetric(BuildContext context, String label, String value,
      String change, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyRecommendations(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.purple[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '策略推荐',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStrategyCard(context, '保守型', '低风险，稳健收益', Colors.blue),
            _buildStrategyCard(context, '平衡型', '中等风险，均衡配置', Colors.green),
            _buildStrategyCard(context, '进取型', '高风险，高收益', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard(
      BuildContext context, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskWarning(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '风险提示',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• 投资有风险，入市需谨慎\n• 过往业绩不代表未来表现\n• 请根据自身风险承受能力选择合适的投资产品\n• 建议分散投资，降低单一产品风险',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
            ),
          ],
        ),
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

  void _showCreatePortfolioDialog(
      BuildContext context, PortfolioStrategy strategy) {
    showDialog(
      context: context,
      builder: (context) => PortfolioCreateDialog(strategy: strategy),
    );
  }

  void _showPortfolioHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投资组合帮助'),
        content: const Text(
          '投资组合是您持有的多个基金的集合。\n\n'
          '通过合理的资产配置，可以：\n'
          '• 分散投资风险\n'
          '• 提高收益稳定性\n'
          '• 实现投资目标\n\n'
          '建议您根据自己的风险承受能力和投资期限，选择合适的投资策略。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
