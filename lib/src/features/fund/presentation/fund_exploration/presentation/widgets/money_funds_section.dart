import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/money_fund.dart';
import '../cubit/fund_exploration_cubit.dart';

/// 货币基金显示组件
///
/// 专门用于显示和操作货币基金数据的组件
class MoneyFundsSection extends StatefulWidget {
  const MoneyFundsSection({super.key});

  @override
  State<MoneyFundsSection> createState() => _MoneyFundsSectionState();
}

class _MoneyFundsSectionState extends State<MoneyFundsSection> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 初始化时加载货币基金数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FundExplorationCubit>().loadMoneyFunds();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听滚动事件
  void _onScroll() {
    // 可以在这里添加滚动到底部的逻辑
  }

  /// 切换搜索状态
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<FundExplorationCubit>().clearMoneyFundSearch();
      }
    });
  }

  /// 执行搜索
  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<FundExplorationCubit>().searchMoneyFunds(query.trim());
    } else {
      context.read<FundExplorationCubit>().clearMoneyFundSearch();
    }
  }

  /// 刷新数据
  void _refreshData() {
    context.read<FundExplorationCubit>().loadMoneyFunds(forceRefresh: true);
  }

  /// 获取高收益货币基金
  void _loadTopYieldFunds() {
    context.read<FundExplorationCubit>().loadTopYieldMoneyFunds(count: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildActionButtons(),
          Expanded(
            child: _buildMoneyFundsList(),
          ),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '货币基金',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '低风险理财，流动性好',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    if (!_isSearching) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索货币基金代码或名称...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<FundExplorationCubit>().clearMoneyFundSearch();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _performSearch,
        onSubmitted: _performSearch,
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _loadTopYieldFunds,
              icon: const Icon(Icons.trending_up, size: 16),
              label: const Text('高收益排行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('刷新数据'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建货币基金列表
  Widget _buildMoneyFundsList() {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        // 处理加载状态
        if (state.isMoneyFundsLoading && state.moneyFunds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载货币基金数据...'),
              ],
            ),
          );
        }

        // 处理错误状态
        if (state.moneyFundsError != null && state.moneyFunds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  '加载失败: ${state.moneyFundsError}',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('重新加载'),
                ),
              ],
            ),
          );
        }

        // 获取要显示的数据
        final moneyFunds = state.currentMoneyFunds;

        // 处理空数据状态
        if (moneyFunds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  '暂无货币基金数据',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('刷新数据'),
                ),
              ],
            ),
          );
        }

        // 显示货币基金列表
        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: moneyFunds.length,
            itemBuilder: (context, index) {
              final moneyFund = moneyFunds[index];
              return _buildMoneyFundCard(moneyFund, index);
            },
          ),
        );
      },
    );
  }

  /// 构建货币基金卡片
  Widget _buildMoneyFundCard(MoneyFund moneyFund, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基金基本信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moneyFund.fundName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moneyFund.fundCode,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '低风险',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 收益数据
            Row(
              children: [
                Expanded(
                  child: _buildYieldItem(
                    '万份收益',
                    moneyFund.formattedDailyIncome,
                    moneyFund.isIncomeIncreasing,
                    moneyFund.dailyIncomeChangeDescription,
                  ),
                ),
                Expanded(
                  child: _buildYieldItem(
                    '7日年化',
                    moneyFund.formattedSevenDayYield,
                    moneyFund.isYieldIncreasing,
                    moneyFund.sevenDayYieldChangeDescription,
                  ),
                ),
              ],
            ),

            // 数据日期
            if (moneyFund.dataDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '数据日期: ${moneyFund.dataDate}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建收益显示项
  Widget _buildYieldItem(
      String title, String value, bool isPositive, String change) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            if (change != '无数据' && change.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ],
          ],
        ),
        if (change != '无数据' && change.isNotEmpty)
          Text(
            change,
            style: TextStyle(
              fontSize: 10,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }
}
