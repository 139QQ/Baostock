import 'package:flutter/material.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/entities/fund_ranking.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';

/// 基金对比表格组件
///
/// 展示多只基金在不同时间段的对比数据
class ComparisonTable extends StatefulWidget {
  /// 对比结果数据
  final ComparisonResult comparisonResult;

  /// 点击回调
  final Function(FundComparisonData)? onTap;

  /// 基金详情回调
  final Function(String)? onFundDetail;

  /// 是否显示统计信息
  final bool showStatistics;

  /// 是否可编辑
  final bool isEditable;

  const ComparisonTable({
    super.key,
    required this.comparisonResult,
    this.onTap,
    this.onFundDetail,
    this.showStatistics = true,
    this.isEditable = false,
  });

  @override
  State<ComparisonTable> createState() => _ComparisonTableState();
}

class _ComparisonTableState extends State<ComparisonTable> {
  bool _sortAscending = true;
  ComparisonSortBy _currentSortBy = ComparisonSortBy.fundCode;
  int _sortColumnIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.comparisonResult.hasError) {
      return _buildErrorWidget();
    }

    if (widget.comparisonResult.fundData.isEmpty) {
      return _buildEmptyWidget();
    }

    return Card(
      child: Column(
        children: [
          // 表格头部
          _buildTableHeader(),
          // 数据表格
          Expanded(
            child: _buildDataTable(),
          ),
          // 统计信息
          if (widget.showStatistics) _buildStatisticsSection(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '加载对比数据失败',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.comparisonResult.errorMessage ?? '未知错误',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade400,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _retryLoad(),
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无对比数据',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择基金进行对比分析',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.table_chart,
            color: Color(0xFF1E40AF),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '基金对比结果',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (widget.isEditable) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editCriteria,
              tooltip: '编辑对比条件',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveConfiguration,
              tooltip: '保存配置',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final sortedData = _getSortedData();
    final periods = widget.comparisonResult.criteria.periods;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 16,
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected)
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent;
        }),
        columns: _buildTableColumns(periods),
        rows: sortedData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return _buildDataRow(index, data, periods);
        }).toList(),
      ),
    );
  }

  List<DataColumn> _buildTableColumns(List<RankingPeriod> periods) {
    final columns = <DataColumn>[];

    // 基金信息列
    columns.add(DataColumn(
      label: GestureDetector(
        onTap: () => _sortByColumn(0, ComparisonSortBy.fundCode),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('基金信息'),
            if (_currentSortBy == ComparisonSortBy.fundCode)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
          ],
        ),
      ),
      numeric: false,
    ));

    // 每个时间段的收益率列
    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];
      columns.add(DataColumn(
        label: GestureDetector(
          onTap: () => _sortByColumn(i + 1, ComparisonSortBy.totalReturn),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getPeriodDisplayName(period)),
              if (_currentSortBy == ComparisonSortBy.totalReturn &&
                  _sortColumnIndex == i + 1)
                Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
            ],
          ),
        ),
        numeric: true,
      ));
    }

    // 统计列
    columns.add(const DataColumn(
      label: Text('排名'),
      numeric: true,
    ));

    columns.add(const DataColumn(
      label: Text('超越同类'),
      numeric: true,
    ));

    return columns;
  }

  DataRow _buildDataRow(
      int index, FundComparisonData data, List<RankingPeriod> periods) {
    final cells = <DataCell>[];

    // 基金信息
    cells.add(DataCell(
      GestureDetector(
        onTap: () => _onFundTap(data),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.fundName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '${data.fundCode} • ${data.fundType}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ));

    // 每个时间段的收益率
    for (final period in periods) {
      final periodData = widget.comparisonResult
          .getPeriodData(period)
          .firstWhere((d) => d.fundCode == data.fundCode, orElse: () => data);

      cells.add(DataCell(
        _buildReturnCell(periodData.totalReturn),
        onTap: () => _onReturnTap(periodData),
      ));
    }

    // 排名
    cells.add(DataCell(
      _buildRankingCell(data.ranking),
    ));

    // 超越同类
    cells.add(DataCell(
      _buildPercentCell(data.beatCategoryPercent),
    ));

    return DataRow(
      selected: index % 2 == 0,
      cells: cells,
    );
  }

  Widget _buildReturnCell(double returnValue) {
    final isPositive = returnValue >= 0;
    final returnText = '${(returnValue * 100).toStringAsFixed(2)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        returnText,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildRankingCell(int ranking) {
    Color color;
    IconData icon;

    if (ranking <= 3) {
      color = Colors.amber;
      icon = Icons.emoji_events;
    } else if (ranking <= 10) {
      color = Colors.blue;
      icon = Icons.star;
    } else {
      color = Colors.grey;
      icon = Icons.info;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '#$ranking',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentCell(double percent) {
    final isPositive = percent >= 0;
    final percentText = '${percent.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        percentText,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isPositive ? Colors.blue.shade700 : Colors.orange.shade700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final stats = widget.comparisonResult.statistics;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '统计信息',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatItem('平均收益率', stats.averageReturn, Colors.blue),
              _buildStatItem('最高收益率', stats.maxReturn, Colors.green),
              _buildStatItem('最低收益率', stats.minReturn, Colors.red),
              _buildStatItem('平均波动率', stats.averageVolatility, Colors.orange),
              _buildStatItem('平均夏普比率', stats.averageSharpeRatio, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(value * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(1.0),
            ),
          ),
        ],
      ),
    );
  }

  List<FundComparisonData> _getSortedData() {
    final data =
        List<FundComparisonData>.from(widget.comparisonResult.fundData);

    // 按基金代码分组，取最新时间段的每个基金数据
    final fundDataMap = <String, FundComparisonData>{};

    for (final item in data) {
      if (!fundDataMap.containsKey(item.fundCode) ||
          item.period.index >= fundDataMap[item.fundCode]!.period.index) {
        fundDataMap[item.fundCode] = item;
      }
    }

    final uniqueData = fundDataMap.values.toList();

    switch (_currentSortBy) {
      case ComparisonSortBy.fundCode:
        uniqueData.sort((a, b) => a.fundCode.compareTo(b.fundCode));
        break;
      case ComparisonSortBy.totalReturn:
        uniqueData.sort((a, b) => _sortAscending
            ? a.totalReturn.compareTo(b.totalReturn)
            : b.totalReturn.compareTo(a.totalReturn));
        break;
      case ComparisonSortBy.recentPerformance:
        uniqueData.sort((a, b) => _sortAscending
            ? a.annualizedReturn.compareTo(b.annualizedReturn)
            : b.annualizedReturn.compareTo(a.annualizedReturn));
        break;
      case ComparisonSortBy.volatility:
        uniqueData.sort((a, b) => _sortAscending
            ? a.volatility.compareTo(b.volatility)
            : b.volatility.compareTo(a.volatility));
        break;
      default:
        break;
    }

    return uniqueData;
  }

  void _sortByColumn(int columnIndex, ComparisonSortBy sortBy) {
    setState(() {
      if (_currentSortBy == sortBy && _sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _currentSortBy = sortBy;
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
  }

  String _getPeriodDisplayName(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.oneMonth:
        return '1月';
      case RankingPeriod.threeMonths:
        return '3月';
      case RankingPeriod.sixMonths:
        return '6月';
      case RankingPeriod.oneYear:
        return '1年';
      case RankingPeriod.threeYears:
        return '3年';
      default:
        return period.name;
    }
  }

  void _onFundTap(FundComparisonData data) {
    widget.onTap?.call(data);
    widget.onFundDetail?.call(data.fundCode);
  }

  void _onReturnTap(FundComparisonData data) {
    // 可以显示详细信息对话框
    showDialog(
      context: context,
      builder: (context) => _buildReturnDetailDialog(data),
    );
  }

  Widget _buildReturnDetailDialog(FundComparisonData data) {
    return AlertDialog(
      title: Text('${data.fundName} (${data.fundCode})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
              '累计收益率', '${(data.totalReturn * 100).toStringAsFixed(2)}%'),
          _buildDetailRow(
              '年化收益率', '${(data.annualizedReturn * 100).toStringAsFixed(2)}%'),
          _buildDetailRow(
              '波动率', '${(data.volatility * 100).toStringAsFixed(2)}%'),
          _buildDetailRow('夏普比率', data.sharpeRatio.toStringAsFixed(2)),
          _buildDetailRow(
              '最大回撤', '${(data.maxDrawdown * 100).toStringAsFixed(2)}%'),
          _buildDetailRow('排名', '#${data.ranking}'),
          _buildDetailRow(
              '超越同类', '${data.beatCategoryPercent.toStringAsFixed(1)}%'),
          _buildDetailRow(
              '超越基准', '${data.beatBenchmarkPercent.toStringAsFixed(1)}%'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _editCriteria() {
    // 编辑对比条件的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中')),
    );
  }

  void _saveConfiguration() {
    // 保存配置的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存功能开发中')),
    );
  }

  void _retryLoad() {
    // 重新加载数据的逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('重新加载功能开发中')),
    );
  }
}
