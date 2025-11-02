import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/fund_search_bloc.dart';
import '../../../models/fund_info.dart';
import 'fund_card_widget.dart';

/// 基金搜索结果组件
class FundSearchWidget extends StatelessWidget {
  final List<FundInfo> funds;

  const FundSearchWidget({super.key, required this.funds});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索结果标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '搜索结果',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        const SizedBox(height: 12),

        // 基金列表
        Expanded(
          child: _buildFundList(context, funds),
        ),
      ],
    );
  }

  Widget _buildFundList(BuildContext context, List<FundInfo> funds) {
    if (funds.isEmpty) {
      return const Center(
        child: Text('暂无基金数据'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FundSearchBloc>().add(
              SearchFunds(context.read<FundSearchBloc>().currentQuery),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: funds.length,
        itemBuilder: (context, index) {
          final fund = funds[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FundCardWidget(
              fund: fund,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/fund/detail',
                  arguments: fund.code,
                );
              },
              onFavorite: (isFavorite) {
                // TODO: 实现收藏功能
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavorite ? '已添加到收藏' : '已从收藏中移除'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
