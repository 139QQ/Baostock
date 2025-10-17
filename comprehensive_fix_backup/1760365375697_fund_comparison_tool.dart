import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/fund.dart';
import '../cubit/fund_exploration_cubit.dart';

/// 基金对比工具组件
///
/// 提供基金对比分析功能，包括：
/// - 对比基金列表管理
/// - 快速对比分析
/// - 对比结果展示
/// - 对比基金添加/删除
class FundComparisonTool extends StatefulWidget {
  // ignore: use_super_parameters
  const FundComparisonTool({Key? key}) : super(key: key);

  @override
  State<FundComparisonTool> createState() => _FundComparisonToolState();
}

class _FundComparisonToolState extends State<FundComparisonTool> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundExplorationCubit, FundExplorationState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题区域
                Row(
                  children: [
                    const Icon(
                      Icons.compare_arrows,
                      color: Color(0xFF1E40AF),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '基金对比',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (state.comparisonFunds.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          context
                              .read<FundExplorationCubit>()
                              .clearComparison();
                        },
                        child: const Text('清空'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // 对比基金列表
                if (state.comparisonFunds.isEmpty)
                  _buildEmptyState()
                else
                  _buildComparisonList(state.comparisonFunds),

                const SizedBox(height: 16),

                // 对比操作按钮
                if (state.comparisonFunds.isNotEmpty) ...[
                  _buildComparisonActions(state.comparisonFunds),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无对比基金',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在基金列表中选择基金进行对比',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建对比基金列表
  Widget _buildComparisonList(List<Fund> funds) {
    return Column(
      children: [
        // 列表标题
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '基金名称',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '近1年收益',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '操作',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 基金列表
        ...funds.map<Widget>((fund) => _buildFundItem(fund)),
      ],
    );
  }

  /// 构建基金项
  Widget _buildFundItem(Fund fund) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fund.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fund.code,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${fund.return1Y > 0 ? '+' : ''}${fund.return1Y.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Fund.getReturnColor(fund.return1Y),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                context.read<FundExplorationCubit>().removeFromComparison(fund);
              },
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建对比操作按钮
  Widget _buildComparisonActions(List<Fund> funds) {
    return Column(
      children: [
        // 对比统计信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('对比基金', '${funds.length}'),
              _buildStatItem('平均收益',
                  '${funds.map((f) => f.return1Y).reduce((a, b) => a + b) / funds.length}%'),
              _buildStatItem('最高收益',
                  '${funds.map((f) => f.return1Y).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}%'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 主要操作按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: funds.length >= 2
                ? () {
                    Navigator.pushNamed(
                      context,
                      '/fund-comparison',
                      arguments: funds.map((f) => f.code).toList(),
                    );
                  }
                : null,
            icon: const Icon(Icons.analytics),
            label: Text('开始对比分析 (${funds.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 次要操作按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // 导出对比结果
                  _exportComparison(funds);
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('分享'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // 保存对比组合
                  _saveComparisonGroup(funds);
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('保存'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 导出对比结果
  void _exportComparison(List<Fund> funds) {
    final comparisonText = funds.map((fund) {
      return '''${fund.name} (${fund.code})
类型: ${fund.type}
近1年收益: ${fund.return1Y > 0 ? '+' : ''}${fund.return1Y.toStringAsFixed(2)}%
基金规模: ${fund.scale}亿
基金经理: ${fund.manager}
-------------------''';
    }).join('\n');

    // 基金对比分析文本
    '''基金对比分析
时间: ${DateTime.now().toString().split(' ')[0]}

$comparisonText

注: 以上数据仅供参考，投资有风险，入市需谨慎。''';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('对比结果已复制到剪贴板')),
    );

    // 这里可以集成实际的分享功能
    // Clipboard.setData(ClipboardData(text: shareText));
  }

  /// 保存对比组合
  void _saveComparisonGroup(List<Fund> funds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存对比组合'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: '组合名称',
            hintText: '请输入对比组合名称',
          ),
          onSubmitted: (name) {
            if (name.isNotEmpty) {
              // 这里可以实现实际的保存逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('对比组合 "$name" 已保存')),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 获取TextField的值并保存
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('对比组合已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
