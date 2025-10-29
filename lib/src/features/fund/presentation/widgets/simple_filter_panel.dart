import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../fund_exploration/presentation/cubit/fund_exploration_cubit.dart';

/// 简化的筛选面板组件
///
/// 使用统一的FundExplorationCubit状态管理
/// 提供基本的筛选功能
class SimpleFilterPanel extends StatefulWidget {
  const SimpleFilterPanel({super.key});

  @override
  State<SimpleFilterPanel> createState() => _SimpleFilterPanelState();
}

class _SimpleFilterPanelState extends State<SimpleFilterPanel> {
  String _selectedType = '全部';
  String _selectedSort = '收益率';
  bool _showAdvanced = false;

  final List<String> _fundTypes = [
    '全部',
    '股票型',
    '债券型',
    '混合型',
    '货币型',
    'QDII',
    'FOF',
  ];

  final List<String> _sortOptions = [
    '收益率',
    '基金规模',
    '名称',
    '代码',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              const Text(
                '筛选条件',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAdvanced = !_showAdvanced;
                  });
                },
                child: Text(_showAdvanced ? '收起' : '高级'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 基金类型筛选
          _buildFilterSection(
            title: '基金类型',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fundTypes.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = selected ? type : '全部';
                    });
                    _applyFilter();
                  },
                );
              }).toList(),
            ),
          ),

          if (_showAdvanced) ...[
            const SizedBox(height: 16),

            // 排序方式
            _buildFilterSection(
              title: '排序方式',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sortOptions.map((sort) {
                  return FilterChip(
                    label: Text(sort),
                    selected: _selectedSort == sort,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSort = selected ? sort : '收益率';
                      });
                      _applyFilter();
                    },
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilter,
                  child: const Text('重置'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  child: const Text('应用筛选'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建筛选区域
  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// 应用筛选
  void _applyFilter() {
    // 这里可以根据选中的条件调用相应的筛选方法
    // 目前简单调用重新加载数据
    context.read<FundExplorationCubit>().refreshData();
  }

  /// 重置筛选条件
  void _resetFilter() {
    setState(() {
      _selectedType = '全部';
      _selectedSort = '收益率';
    });

    // 重新加载初始数据
    context.read<FundExplorationCubit>().refreshData();
  }
}
