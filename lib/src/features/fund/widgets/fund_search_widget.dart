import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/fund_search_bloc.dart';
import '../../../models/fund_info.dart';
import '../domain/entities/fund.dart';
import '../presentation/widgets/unified_fund_card.dart';

/// 基金搜索结果组件
class FundSearchWidget extends StatelessWidget {
  /// 创建基金搜索结果组件
  const FundSearchWidget({super.key, required this.funds});

  /// 搜索结果基金列表
  final List<FundInfo> funds;

  /// 将FundInfo转换为Fund实体的辅助函数
  Fund _fundInfoToFund(FundInfo fundInfo) {
    return Fund(
      code: fundInfo.code,
      name: fundInfo.name,
      type: fundInfo.type,
      company: '', // FundInfo中没有此字段，使用空字符串
      lastUpdate: DateTime.now(), // FundInfo中没有此字段，使用当前时间
    );
  }

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
          final fundInfo = funds[index];
          final fund = _fundInfoToFund(fundInfo);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: UnifiedFundCard(
              fund: fund,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/fund/detail',
                  arguments: fund.code,
                );
              },
              onAddToWatchlist: () {
                // TODO: 实现收藏功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已添加到收藏'),
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
