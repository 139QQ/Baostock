import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jisu_fund_analyzer/src/bloc/portfolio_bloc.dart';
import 'package:jisu_fund_analyzer/src/services/portfolio_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/core/theme/app_theme.dart';

/// 增强版投资组合管理组件
class EnhancedPortfolioManagementWidget extends StatefulWidget {
  const EnhancedPortfolioManagementWidget({super.key});

  @override
  State<EnhancedPortfolioManagementWidget> createState() =>
      _EnhancedPortfolioManagementWidgetState();
}

class _EnhancedPortfolioManagementWidgetState
    extends State<EnhancedPortfolioManagementWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _portfolioNameController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<PortfolioHolding> _holdings = [];
  double _remainingWeight = 1.0;
  PortfolioStrategy _selectedStrategy = PortfolioStrategy.balanced;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDefaultHolding();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _portfolioNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeDefaultHolding() {
    _holdings = [
      PortfolioHolding(
        fundCode: '000001',
        fundName: '华夏成长混合',
        weight: 0.6,
      ),
    ];
    _updateRemainingWeight();
  }

  void _updateRemainingWeight() {
    _remainingWeight = 1.0 - _holdings.fold(0.0, (sum, h) => sum + h.weight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 顶部标题栏
          _buildSliverAppBar(),

          // 主体内容
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreatePortfolioTab(),
                _buildPortfolioListTab(),
                _buildOptimizationTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '投资组合管理',
              style: AppTheme.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '智能配置，优化收益',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(
            icon: Icon(Icons.add_circle_outline),
            text: '创建组合',
          ),
          Tab(
            icon: Icon(Icons.list_alt),
            text: '我的组合',
          ),
          Tab(
            icon: Icon(Icons.trending_up),
            text: '智能优化',
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePortfolioTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息
          _buildBasicInfoSection(),
          const SizedBox(height: 24),

          // 持仓配置
          _buildHoldingsSection(),
          const SizedBox(height: 24),

          // 策略选择
          _buildStrategySection(),
          const SizedBox(height: 24),

          // 预览卡片
          Expanded(child: _buildPreviewCard()),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '基本信息',
                  style: AppTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _portfolioNameController,
                decoration: InputDecoration(
                  labelText: '投资组合名称',
                  hintText: '请输入组合名称',
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入投资组合名称';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX().fadeIn();
  }

  Widget _buildHoldingsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '持仓配置',
                      style: AppTheme.headlineMedium,
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    '剩余权重: ${(_remainingWeight * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _remainingWeight > 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 搜索添加基金
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜索基金',
                hintText: '输入基金代码或名称',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addHolding,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 持仓列表
            Flexible(
              child: _holdings.isEmpty
                  ? _buildEmptyHoldings()
                  : _buildHoldingsList(),
            ),
          ],
        ),
      ),
    ).animate().slideY(delay: 200.ms).fadeIn();
  }

  Widget _buildEmptyHoldings() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '暂无持仓',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              '搜索并添加基金到投资组合',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _holdings.asMap().entries.map((entry) {
        final index = entry.key;
        final holding = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                holding.fundCode.substring(0, 2),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              holding.fundName,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(holding.fundCode),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(holding.weight * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: () => _removeHolding(index),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStrategySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '投资策略',
                  style: AppTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PortfolioStrategy.values.map((strategy) {
                final isSelected = _selectedStrategy == strategy;
                return ChoiceChip(
                  label: Text(_getStrategyDisplayName(strategy)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStrategy = strategy;
                      });
                    }
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              _getStrategyDescription(_selectedStrategy),
              style: AppTheme.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX(delay: 400.ms).fadeIn();
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 6,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.primaryColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '组合预览',
                  style: AppTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 组合统计
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '基金数量',
                    '${_holdings.length}',
                    Icons.account_balance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '配置权重',
                    '${((1.0 - _remainingWeight) * 100).toStringAsFixed(1)}%',
                    Icons.pie_chart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '策略类型',
                    _getStrategyDisplayName(_selectedStrategy),
                    Icons.lightbulb,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 持仓分布饼图（简化版）
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildSimplePieChart(),
            ),
          ],
        ),
      ),
    ).animate().slideY(delay: 600.ms).fadeIn();
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePieChart() {
    if (_holdings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '添加基金后查看分布',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 简化的饼图显示
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1.0 - _remainingWeight,
              strokeWidth: 20,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_holdings.length}',
                style: AppTheme.headlineLarge.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '只基金',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioListTab() {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is PortfolioLoaded && state.portfolios.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.portfolios.length,
            itemBuilder: (context, index) {
              final portfolio = state.portfolios[index];
              return _buildPortfolioCard(portfolio);
            },
          );
        }

        return _buildEmptyPortfolioList();
      },
    );
  }

  Widget _buildPortfolioCard(Portfolio portfolio) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portfolio.name,
                        style: AppTheme.headlineMedium,
                      ),
                      Text(
                        _getStrategyDisplayName(portfolio.strategy),
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        // 编辑投资组合
                        break;
                      case 'delete':
                        // 删除投资组合
                        break;
                      case 'optimize':
                        // 优化投资组合
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'optimize',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up),
                          SizedBox(width: 8),
                          Text('优化'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('删除'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 投资组合指标
            ...[
              Row(
                children: [
                  _buildMetricChip(
                      '预期收益',
                      '${(portfolio.metrics.totalExpectedReturn * 100).toStringAsFixed(2)}%',
                      AppTheme.successColor),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                      '波动率',
                      '${(portfolio.metrics.volatility * 100).toStringAsFixed(2)}%',
                      AppTheme.warningColor),
                  const SizedBox(width: 8),
                  _buildMetricChip(
                      '夏普比率',
                      portfolio.metrics.sharpeRatio.toStringAsFixed(2),
                      AppTheme.primaryColor),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 持仓列表
            Text(
              '持仓 (${portfolio.holdings.length}只)',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: portfolio.holdings.take(5).map((holding) {
                return Chip(
                  label: Text(
                    '${holding.fundCode} (${(holding.weight * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
            if (portfolio.holdings.length > 5) ...[
              const SizedBox(height: 4),
              Text(
                '...还有${portfolio.holdings.length - 5}只基金',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPortfolioList() {
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
            style: AppTheme.headlineMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建您的第一个投资组合，开启智能投资之旅',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(0);
            },
            icon: const Icon(Icons.add),
            label: const Text('创建投资组合'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '智能优化',
                        style: AppTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '基于现代投资组合理论，通过算法优化您的投资组合配置，在控制风险的同时追求最大收益。',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 优化目标选择
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '优化目标',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  ...OptimizationGoal.values.map((goal) {
                    return RadioListTile<OptimizationGoal>(
                      title: Text(_getOptimizationGoalDisplayName(goal)),
                      subtitle: Text(_getOptimizationGoalDescription(goal)),
                      value: goal,
                      groupValue: OptimizationGoal.maximizeSharpe,
                      onChanged: (value) {
                        setState(() {
                          // 更新选择的优化目标
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 开始优化按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startOptimization,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('开始智能优化'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _createPortfolio,
      icon: const Icon(Icons.save),
      label: const Text('创建组合'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
    );
  }

  void _addHolding() {
    if (_searchController.text.trim().isEmpty) return;
    if (_remainingWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('权重已满，请先调整现有持仓'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final newHolding = PortfolioHolding(
      fundCode: _searchController.text.trim(),
      fundName: '搜索的基金',
      weight: _remainingWeight > 0.1 ? 0.1 : _remainingWeight,
    );

    setState(() {
      _holdings.add(newHolding);
      _updateRemainingWeight();
      _searchController.clear();
    });
  }

  void _removeHolding(int index) {
    setState(() {
      _holdings.removeAt(index);
      _updateRemainingWeight();
    });
  }

  void _createPortfolio() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_holdings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请至少添加一只基金'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if ((_remainingWeight.abs() > 0.01)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('持仓权重总和必须等于100%'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // 创建投资组合
    context.read<PortfolioBloc>().add(CreatePortfolio(
          name: _portfolioNameController.text.trim(),
          holdings: _holdings,
          strategy: _selectedStrategy,
        ));

    // 清空表单
    _portfolioNameController.clear();
    _initializeDefaultHolding();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('投资组合创建成功！'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // 切换到我的组合页面
    _tabController.animateTo(1);
  }

  void _startOptimization() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('智能优化功能开发中，敬请期待！'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  String _getStrategyDisplayName(PortfolioStrategy strategy) {
    switch (strategy) {
      case PortfolioStrategy.conservative:
        return '保守型';
      case PortfolioStrategy.balanced:
        return '平衡型';
      case PortfolioStrategy.aggressive:
        return '进取型';
      case PortfolioStrategy.custom:
        return '自定义';
    }
  }

  String _getStrategyDescription(PortfolioStrategy strategy) {
    switch (strategy) {
      case PortfolioStrategy.conservative:
        return '以稳健收益为主，风险较低，适合风险厌恶型投资者';
      case PortfolioStrategy.balanced:
        return '风险与收益平衡，适合大多数投资者的长期配置';
      case PortfolioStrategy.aggressive:
        return '进取型策略，追求高收益，能承受较高风险';
      case PortfolioStrategy.custom:
        return '自定义投资策略，根据个人需求定制配置';
    }
  }

  String _getOptimizationGoalDisplayName(OptimizationGoal goal) {
    switch (goal) {
      case OptimizationGoal.maximizeSharpe:
        return '最大化夏普比率';
      case OptimizationGoal.minimizeVolatility:
        return '最小化波动率';
      case OptimizationGoal.riskParity:
        return '风险平价';
      case OptimizationGoal.equalWeight:
        return '等权重';
    }
  }

  String _getOptimizationGoalDescription(OptimizationGoal goal) {
    switch (goal) {
      case OptimizationGoal.maximizeSharpe:
        return '在承担单位风险的情况下获得最高超额收益';
      case OptimizationGoal.minimizeVolatility:
        return '最小化投资组合波动率，提高投资稳定性';
      case OptimizationGoal.riskParity:
        return '风险平价配置，各资产贡献相同风险';
      case OptimizationGoal.equalWeight:
        return '等权重配置，简单有效的分散投资';
    }
  }
}
