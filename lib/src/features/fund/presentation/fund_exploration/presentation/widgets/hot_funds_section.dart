import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fund_exploration_cubit.dart';
import '../../domain/models/fund.dart';
import 'modern_fund_card.dart';

/// 热门基金推荐组件
///
/// 展示基于算法推荐的优质基金，包括：
/// - 近期表现优异的基金
/// - 高关注度的热门基金
/// - 专业机构推荐的基金
/// - 新兴主题投资机会
class HotFundsSection extends StatefulWidget {
  const HotFundsSection({super.key});

  @override
  State<HotFundsSection> createState() => _HotFundsSectionState();
}

class _HotFundsSectionState extends State<HotFundsSection> {
  String _selectedCategory = '综合推荐';
  bool _hasLoaded = false;

  // 推荐分类
  final List<String> _categories = [
    '综合推荐',
    '近期表现',
    '机构青睐',
    '新兴主题',
    '稳健收益',
    '高成长',
  ];

  @override
  void initState() {
    super.initState();
    // 不在initState中自动加载，等待用户交互
  }

  /// 按需加载热门基金（用户触发）
  void _loadHotFunds() {
    if (!_hasLoaded) {
      final cubit = context.read<FundExplorationCubit>();
      debugPrint('🔄 HotFundsSection 用户触发加载...');
      cubit.loadHotFunds();
      setState(() {
        _hasLoaded = true;
      });
    }
  }

  /// 处理分类切换
  void _handleCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });

      // 通知状态管理器加载对应分类的热门基金
      // context.read<FundExplorationCubit>().switchView(FundExplorationView.hot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        final hotFunds = state.hotFunds;
        final isLoading = state.isLoading;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 320, // 最大高度限制
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题和分类选择
                    _buildHeader(),

                    const SizedBox(height: 12),

                    // 内容区域 - 给定合适的高度
                    SizedBox(
                      height: 220,
                      child: _buildContent(
                          context, isLoading, hotFunds, _hasLoaded),
                    ),
                    const SizedBox(height: 12),

                    // 查看更多按钮
                    _buildFooterButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题区域
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.whatshot,
          color: Color(0xFFF59E0B),
          size: 20,
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            '热门基金推荐',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 简化的分类选择器
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: _selectedCategory,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 14),
            isDense: true,
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _handleCategoryChanged,
          ),
        ),
      ],
    );
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context, bool isLoading,
      List<Fund> hotFunds, bool hasLoaded) {
    // 加载状态
    if (isLoading && hotFunds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              '正在加载热门基金...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // 空状态 - 已加载但无数据
    if (!isLoading && hotFunds.isEmpty && hasLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              '暂无热门基金数据',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '请稍后重试',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // 初始状态 - 等待用户交互
    if (!isLoading && hotFunds.isEmpty && !hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              '点击加载热门基金',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadHotFunds,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('加载热门基金'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
      );
    }

    // 基金卡片列表 - 使用LayoutBuilder动态调整卡片尺寸
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用高度计算卡片宽度
        final availableHeight = constraints.maxHeight;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: hotFunds.length,
          itemBuilder: (context, index) {
            final fund = hotFunds[index];

            return Container(
              width: availableHeight.clamp(200.0, 280.0),
              margin: const EdgeInsets.only(right: 8),
              child: ModernFundCard(
                fund: FundRanking(
                  fundCode: fund.code,
                  fundName: fund.name,
                  fundType: fund.type,
                  company: fund.company,
                  rankingPosition: index + 1,
                  totalCount: hotFunds.length,
                  unitNav: fund.unitNav ?? 0.0,
                  accumulatedNav: fund.accumulatedNav ?? 0.0,
                  dailyReturn: fund.dailyReturn ?? 0.0,
                  return1W: fund.return1W,
                  return1M: fund.return1M,
                  return3M: fund.return3M,
                  return6M: fund.return6M,
                  return1Y: fund.return1Y,
                  return2Y: 0.0, // Fund实体没有return2Y字段
                  return3Y: fund.return3Y,
                  returnYTD: fund.returnYTD ?? 0.0,
                  returnSinceInception: fund.returnSinceInception ?? 0.0,
                  date: '', // Fund实体没有date字段
                  fee: fund.managementFee ?? 0.0,
                ),
                ranking: index + 1,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/fund-detail',
                    arguments: fund.code,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// 构建底部按钮
  Widget _buildFooterButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          // 导航到完整的热门基金页面
          Navigator.pushNamed(context, '/hot-funds');
        },
        child: const Text(
          '查看更多',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF1E40AF),
          ),
        ),
      ),
    );
  }
}
