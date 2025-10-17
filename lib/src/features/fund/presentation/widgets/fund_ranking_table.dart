import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';

/// 基金排行榜表格组件
///
/// 以表格形式展示基金排行榜信息，适合查看大量数据
class FundRankingTable extends StatefulWidget {
  /// 排行榜数据
  final List<FundRanking> rankings;

  /// 点击回调
  final Function(FundRanking)? onTap;

  /// 收藏回调
  final Function(String, bool)? onFavorite;

  /// 是否显示排名变化
  final bool showPositionChange;

  /// 是否显示基金类型
  final bool showFundType;

  /// 是否显示基金公司
  final bool showCompany;

  const FundRankingTable({
    super.key,
    required this.rankings,
    this.onTap,
    this.onFavorite,
    this.showPositionChange = true,
    this.showFundType = true,
    this.showCompany = true,
  });

  @override
  State<FundRankingTable> createState() => _FundRankingTableState();
}

class _FundRankingTableState extends State<FundRankingTable> {
  final ScrollController _horizontalScrollController = ScrollController();
  final Set<String> _favoriteFunds = {};

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rankings.isEmpty) {
      return _buildEmptyTable();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 表格头部（固定）
          _buildTableHeader(),

          // 表格内容（可滚动）
          _buildTableContent(),
        ],
      ),
    );
  }

  /// 构建空表格
  Widget _buildEmptyTable() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.table_chart,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建表格头部
  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        child: DataTable(
          columnSpacing: 16,
          horizontalMargin: 16,
          headingRowColor: MaterialStateProperty.all(
            Colors.transparent,
          ),
          columns: _buildTableColumns(),
          rows: const [], // 头部不需要数据行
        ),
      ),
    );
  }

  /// 构建表格列
  List<DataColumn> _buildTableColumns() {
    final columns = <DataColumn>[
      DataColumn(
        label: const Text('排名'),
        numeric: true,
        onSort: (columnIndex, ascending) {
          _sortData(columnIndex, ascending);
        },
      ),
      DataColumn(
        label: const Text('基金代码'),
        onSort: (columnIndex, ascending) {
          _sortData(columnIndex, ascending);
        },
      ),
      DataColumn(
        label: const Text('基金名称'),
        onSort: (columnIndex, ascending) {
          _sortData(columnIndex, ascending);
        },
      ),
    ];

    if (widget.showFundType) {
      columns.add(
        DataColumn(
          label: const Text('类型'),
          onSort: (columnIndex, ascending) {
            _sortData(columnIndex, ascending);
          },
        ),
      );
    }

    if (widget.showCompany) {
      columns.add(
        DataColumn(
          label: const Text('基金公司'),
          onSort: (columnIndex, ascending) {
            _sortData(columnIndex, ascending);
          },
        ),
      );
    }

    columns.addAll([
      DataColumn(
        label: const Text('单位净值'),
        numeric: true,
        onSort: (columnIndex, ascending) {
          _sortData(columnIndex, ascending);
        },
      ),
      DataColumn(
        label: const Text('日增长'),
        numeric: true,
        onSort: (columnIndex, ascending) {
          _sortData(columnIndex, ascending);
        },
      ),
      DataColumn(
        label: const Text('近1月'),
        numeric: true,
        onSort: (columnIndex, ascending) {
          _sortData(columnIndex, ascending);
        },
      ),
      DataColumn(
        label: const Text('近1年'),
        numeric: true,
        onSort: (columnIndex, ascending) {
          _sortData(columnIndex, ascending);
        },
      ),
    ]);

    if (widget.showPositionChange) {
      columns.add(
        const DataColumn(
          label: Text('变化'),
          numeric: true,
        ),
      );
    }

    columns.add(
      const DataColumn(
        label: Text('操作'),
      ),
    );

    return columns;
  }

  /// 构建表格内容
  Widget _buildTableContent() {
    return SizedBox(
      height: 400, // 固定高度，超出部分可滚动
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 16,
            columns: _buildTableColumns(),
            rows: List<DataRow>.generate(
              widget.rankings.length,
              (index) => _buildTableRow(widget.rankings[index], index),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建表格行
  DataRow _buildTableRow(FundRanking ranking, int index) {
    final isSelected = _favoriteFunds.contains(ranking.fundCode);

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return Theme.of(context).colorScheme.primary.withOpacity(0.05);
          }
          return index % 2 == 0 ? Colors.grey[50] : Colors.white;
        },
      ),
      cells: [
        // 排名
        DataCell(
          _buildRankingCell(ranking.rankingPosition),
          onTap: () => widget.onTap?.call(ranking),
        ),

        // 基金代码
        DataCell(
          Text(
            ranking.fundCode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () => widget.onTap?.call(ranking),
        ),

        // 基金名称
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              ranking.fundName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          onTap: () => widget.onTap?.call(ranking),
        ),

        // 基金类型
        if (widget.showFundType)
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getFundTypeColor(ranking.fundType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ranking.fundType,
                style: TextStyle(
                  fontSize: 11,
                  color: _getFundTypeColor(ranking.fundType),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () => widget.onTap?.call(ranking),
          ),

        // 基金公司
        if (widget.showCompany)
          DataCell(
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                ranking.company,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            onTap: () => widget.onTap?.call(ranking),
          ),

        // 单位净值
        DataCell(
          Text(
            ranking.unitNav.toStringAsFixed(4),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () => widget.onTap?.call(ranking),
        ),

        // 日增长
        DataCell(
          _buildReturnCell(ranking.dailyReturn),
          onTap: () => widget.onTap?.call(ranking),
        ),

        // 近1月
        DataCell(
          _buildReturnCell(ranking.return1M),
          onTap: () => widget.onTap?.call(ranking),
        ),

        // 近1年
        DataCell(
          _buildReturnCell(ranking.return1Y),
          onTap: () => widget.onTap?.call(ranking),
        ),

        // 排名变化
        if (widget.showPositionChange)
          DataCell(
            _buildPositionChangeCell(ranking),
            onTap: () => widget.onTap?.call(ranking),
          ),

        // 操作
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 收藏按钮
              IconButton(
                onPressed: () => _toggleFavorite(ranking.fundCode),
                icon: Icon(
                  isSelected ? Icons.favorite : Icons.favorite_border,
                  color: isSelected ? Colors.red : Colors.grey,
                ),
                splashRadius: 16,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),

              // 详情按钮
              IconButton(
                onPressed: () => widget.onTap?.call(ranking),
                icon: const Icon(
                  Icons.info_outline,
                  size: 16,
                ),
                splashRadius: 16,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建排名单元格
  Widget _buildRankingCell(int position) {
    final isTopThree = position <= 3;
    final color = _getRankingColor(position);

    if (isTopThree) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getRankingBadgeColor(position),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            position.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Text(
      position.toString(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  /// 构建收益率单元格
  Widget _buildReturnCell(double returnValue) {
    final color = _getReturnColor(returnValue);
    final prefix = returnValue > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$prefix${returnValue.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// 构建排名变化单元格
  Widget _buildPositionChangeCell(FundRanking ranking) {
    if (ranking.positionChange == null) {
      return const Text(
        '-',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final change = ranking.positionChange!;
    final color = change > 0 ? Colors.red : Colors.green;
    final icon = change > 0 ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          change.abs().toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 获取排名颜色
  Color _getRankingColor(int position) {
    if (position == 1) {
      return const Color(0xFFFFD700); // 金色
    } else if (position == 2) {
      return const Color(0xFFC0C0C0); // 银色
    } else if (position == 3) {
      return const Color(0xFFCD7F32); // 铜色
    } else if (position <= 10) {
      return Colors.blue; // 前10名蓝色
    } else {
      return Colors.grey; // 其他灰色
    }
  }

  /// 获取排名徽章颜色
  Color _getRankingBadgeColor(int position) {
    if (position == 1) {
      return const Color(0xFFFFD700); // 金色
    } else if (position == 2) {
      return const Color(0xFFC0C0C0); // 银色
    } else if (position == 3) {
      return const Color(0xFFCD7F32); // 铜色
    } else if (position <= 10) {
      return Colors.blue; // 前10名蓝色
    } else {
      return Colors.grey; // 其他灰色
    }
  }

  /// 获取收益率颜色
  Color _getReturnColor(double value) {
    if (value > 0) {
      return const Color(0xFF4CAF50); // 绿色
    } else if (value < 0) {
      return const Color(0xFFF44336); // 红色
    } else {
      return Colors.grey[600]!; // 灰色
    }
  }

  /// 获取基金类型颜色
  Color _getFundTypeColor(String fundType) {
    switch (fundType) {
      case '股票型':
        return const Color(0xFFEF4444);
      case '债券型':
        return const Color(0xFF10B981);
      case '混合型':
        return const Color(0xFFF59E0B);
      case '货币型':
        return const Color(0xFF3B82F6);
      case '指数型':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey[600]!;
    }
  }

  /// 排序数据
  void _sortData(int columnIndex, bool ascending) {
    // 这里可以实现实际的排序逻辑
    // 由于原始数据可能已经排序，这里只是示例
    // 可以根据 columnIndex 和 ascending 参数对 widget.rankings 进行排序
  }

  /// 切换收藏状态
  void _toggleFavorite(String fundCode) {
    setState(() {
      if (_favoriteFunds.contains(fundCode)) {
        _favoriteFunds.remove(fundCode);
      } else {
        _favoriteFunds.add(fundCode);
      }
    });

    widget.onFavorite?.call(fundCode, _favoriteFunds.contains(fundCode));
  }
}
