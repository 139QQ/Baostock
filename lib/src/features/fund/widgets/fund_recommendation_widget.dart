import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/fund_search_bloc.dart';
import '../../../models/fund_info.dart';
import 'fund_card_widget.dart';

/// 推荐基金组件
class FundRecommendationWidget extends StatefulWidget {
  const FundRecommendationWidget({super.key});

  @override
  State<FundRecommendationWidget> createState() =>
      _FundRecommendationWidgetState();
}

class _FundRecommendationWidgetState extends State<FundRecommendationWidget> {
  @override
  void initState() {
    super.initState();
    // 延迟加载推荐基金，避免阻塞UI
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<FundSearchBloc>().add(const LoadRecommendedFunds());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundSearchBloc, FundSearchState>(
      builder: (context, state) {
        if (state is FundSearchLoaded && state.recommendedFunds.isNotEmpty) {
          return _buildRecommendedFunds(context, state.recommendedFunds);
        } else if (state is FundSearchLoading) {
          return _buildLoadingState();
        } else {
          return _buildEmptyState();
        }
      },
    );
  }

  Widget _buildRecommendedFunds(BuildContext context, List<FundInfo> funds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '为您推荐',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // 查看更多推荐基金
                context.read<FundSearchBloc>().add(
                      const LoadRecommendedFunds(limit: 50),
                    );
              },
              child: const Text('查看更多'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: funds.length,
            itemBuilder: (context, index) {
              final fund = funds[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: FundCardWidget(
                  fund: fund,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/fund/detail',
                      arguments: fund.code,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '为您推荐',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // 显示3个加载占位符
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: _buildShimmerCard(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题占位符
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // 代码占位符
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // 类型标签占位符
            Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            // 信息项占位符
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '为您推荐',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 100,
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
                  Icons.hourglass_empty,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  '正在为您精选优质基金...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 精选基金推荐组件（更详细的展示）
class FeaturedFundsWidget extends StatelessWidget {
  const FeaturedFundsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '精选推荐',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 精选基金列表
          _buildFeaturedFundsList(context),
        ],
      ),
    );
  }

  Widget _buildFeaturedFundsList(BuildContext context) {
    // 这里可以根据业务逻辑展示精选基金
    // 暂时返回一个占位符
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '智能推荐系统',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '基于您的投资偏好，为您精选最优质的基金产品',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // 获取个性化推荐
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('正在为您生成个性化推荐...')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('获取推荐'),
          ),
        ],
      ),
    );
  }
}
