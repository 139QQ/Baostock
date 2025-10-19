import 'package:flutter/material.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/fund_ranking.dart';

/// 基金对比选择器组件
///
/// 提供基金选择、时间段选择、对比配置等功能
class ComparisonSelector extends StatefulWidget {
  /// 对比条件变化回调
  final Function(MultiDimensionalComparisonCriteria) onCriteriaChanged;

  /// 初始对比条件
  final MultiDimensionalComparisonCriteria? initialCriteria;

  /// 可选基金列表
  final List<FundRanking> availableFunds;

  const ComparisonSelector({
    super.key,
    required this.onCriteriaChanged,
    required this.availableFunds,
    this.initialCriteria,
  });

  @override
  State<ComparisonSelector> createState() => _ComparisonSelectorState();
}

class _ComparisonSelectorState extends State<ComparisonSelector>
    with TickerProviderStateMixin {
  late MultiDimensionalComparisonCriteria _criteria;
  final Set<String> _selectedFunds = {};
  final Set<RankingPeriod> _selectedPeriods = {};
  final TextEditingController _nameController = TextEditingController();
  ComparisonMetric _selectedMetric = ComparisonMetric.totalReturn;
  ComparisonSortBy _selectedSortBy = ComparisonSortBy.fundCode;
  bool _includeStatistics = true;

  @override
  void initState() {
    super.initState();
    _initializeCriteria();
  }

  void _initializeCriteria() {
    if (widget.initialCriteria != null) {
      _criteria = widget.initialCriteria!;
      _selectedFunds.addAll(_criteria.fundCodes);
      _selectedPeriods.addAll(_criteria.periods);
      _selectedMetric = _criteria.metric;
      _selectedSortBy = _criteria.sortBy;
      _includeStatistics = _criteria.includeStatistics;
      _nameController.text = _criteria.name ?? '';
    } else {
      _criteria = MultiDimensionalComparisonCriteria(
        fundCodes: const [],
        periods: const [RankingPeriod.oneMonth, RankingPeriod.threeMonths],
        metric: ComparisonMetric.totalReturn,
        includeStatistics: true,
        sortBy: ComparisonSortBy.fundCode,
      );
      _selectedPeriods.addAll(_criteria.periods);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  '基金对比设置',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_criteria.isValid())
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '配置有效',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 配置名称
            _buildNameSection(),
            const SizedBox(height: 16),

            // 基金选择
            _buildFundSelectionSection(),
            const SizedBox(height: 16),

            // 时间段选择
            _buildPeriodSelectionSection(),
            const SizedBox(height: 16),

            // 对比选项
            _buildComparisonOptionsSection(),
            const SizedBox(height: 16),

            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '对比名称（可选）',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: '为这个对比配置起个名字...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
          onChanged: (value) => _updateCriteria(),
        ),
      ],
    );
  }

  Widget _buildFundSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '选择基金 (${_selectedFunds.length}/5)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            Text(
              '请选择2-5只基金',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableFunds.map((fund) {
            final isSelected = _selectedFunds.contains(fund.fundCode);
            final canSelect = _selectedFunds.length < 5 || isSelected;

            return FilterChip(
              label: Text('${fund.fundName} (${fund.fundCode})'),
              selected: isSelected,
              onSelected: canSelect
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFunds.add(fund.fundCode);
                        } else {
                          _selectedFunds.remove(fund.fundCode);
                        }
                        _updateCriteria();
                      });
                    }
                  : null,
              backgroundColor: canSelect ? null : Colors.grey.shade300,
              disabledColor: Colors.grey.shade300,
              checkmarkColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
        if (_selectedFunds.length > 5 || _selectedFunds.length < 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _getFundSelectionError(),
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodSelectionSection() {
    final availablePeriods = [
      RankingPeriod.oneMonth,
      RankingPeriod.threeMonths,
      RankingPeriod.sixMonths,
      RankingPeriod.oneYear,
      RankingPeriod.threeYears,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '选择时间段 (${_selectedPeriods.length}/5)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedPeriods.length == availablePeriods.length) {
                    _selectedPeriods.clear();
                  } else {
                    _selectedPeriods.addAll(availablePeriods);
                  }
                  _updateCriteria();
                });
              },
              child: Text(_selectedPeriods.length == availablePeriods.length
                  ? '全不选'
                  : '全选'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availablePeriods.map((period) {
            final isSelected = _selectedPeriods.contains(period);
            final periodName = _getPeriodDisplayName(period);

            return FilterChip(
              label: Text(periodName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPeriods.add(period);
                  } else {
                    _selectedPeriods.remove(period);
                  }
                  _updateCriteria();
                });
              },
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildComparisonOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '对比选项',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 12),

        // 对比指标选择
        Row(
          children: [
            Text(
              '对比指标：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<ComparisonMetric>(
                value: _selectedMetric,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ComparisonMetric.values.map((metric) {
                  return DropdownMenuItem(
                    value: metric,
                    child: Text(_getMetricDisplayName(metric)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMetric = value;
                      _updateCriteria();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 排序方式选择
        Row(
          children: [
            Text(
              '排序方式：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<ComparisonSortBy>(
                value: _selectedSortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ComparisonSortBy.values.map((sortBy) {
                  return DropdownMenuItem(
                    value: sortBy,
                    child: Text(_getSortByDisplayName(sortBy)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSortBy = value;
                      _updateCriteria();
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 包含统计信息
        Row(
          children: [
            const Icon(Icons.analytics),
            const SizedBox(width: 8),
            Text(
              '包含统计信息',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Switch(
              value: _includeStatistics,
              onChanged: (value) {
                setState(() {
                  _includeStatistics = value;
                  _updateCriteria();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetConfiguration,
            icon: const Icon(Icons.refresh),
            label: const Text('重置'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _criteria.isValid() ? _applyConfiguration : null,
            icon: const Icon(Icons.check),
            label: const Text('应用配置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _criteria.isValid()
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _getFundSelectionError() {
    if (_selectedFunds.length < 2) {
      return '⚠️ 至少需要选择2只基金';
    }
    if (_selectedFunds.length > 5) {
      return '⚠️ 最多只能选择5只基金';
    }
    return '';
  }

  String _getPeriodDisplayName(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.oneMonth:
        return '近1月';
      case RankingPeriod.threeMonths:
        return '近3月';
      case RankingPeriod.sixMonths:
        return '近6月';
      case RankingPeriod.oneYear:
        return '近1年';
      case RankingPeriod.threeYears:
        return '近3年';
      default:
        return period.name;
    }
  }

  String _getMetricDisplayName(ComparisonMetric metric) {
    switch (metric) {
      case ComparisonMetric.totalReturn:
        return '累计收益率';
      case ComparisonMetric.annualizedReturn:
        return '年化收益率';
      case ComparisonMetric.volatility:
        return '波动率';
      case ComparisonMetric.sharpeRatio:
        return '夏普比率';
      case ComparisonMetric.maxDrawdown:
        return '最大回撤';
      default:
        return metric.name;
    }
  }

  String _getSortByDisplayName(ComparisonSortBy sortBy) {
    switch (sortBy) {
      case ComparisonSortBy.fundCode:
        return '基金代码';
      case ComparisonSortBy.totalReturn:
        return '累计收益率';
      case ComparisonSortBy.recentPerformance:
        return '近期表现';
      case ComparisonSortBy.volatility:
        return '波动率';
      case ComparisonSortBy.custom:
        return '自定义';
      default:
        return sortBy.name;
    }
  }

  void _updateCriteria() {
    final newCriteria = MultiDimensionalComparisonCriteria(
      fundCodes: _selectedFunds.toList(),
      periods: _selectedPeriods.toList(),
      metric: _selectedMetric,
      includeStatistics: _includeStatistics,
      sortBy: _selectedSortBy,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
    );

    setState(() {
      _criteria = newCriteria;
    });

    widget.onCriteriaChanged(_criteria);
  }

  void _resetConfiguration() {
    setState(() {
      _selectedFunds.clear();
      _selectedPeriods.clear();
      _selectedPeriods.addAll([
        RankingPeriod.oneMonth,
        RankingPeriod.threeMonths,
      ]);
      _selectedMetric = ComparisonMetric.totalReturn;
      _selectedSortBy = ComparisonSortBy.fundCode;
      _includeStatistics = true;
      _nameController.clear();
      _updateCriteria();
    });
  }

  void _applyConfiguration() {
    if (_criteria.isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('对比配置已应用'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
