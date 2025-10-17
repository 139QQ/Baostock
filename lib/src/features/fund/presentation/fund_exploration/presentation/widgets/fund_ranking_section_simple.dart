import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/models/fund.dart';

/// 简化版基金排行展示组件
///
/// 专注于数据展示，不包含复杂的状态管�?
/// 优化布局约束，避免滚动冲�?
class FundRankingSectionSimple extends StatefulWidget {
  final List<FundRanking> rankings;
  final bool isLoading;
  final String selectedPeriod;
  final String sortBy;
  final Function(String)? onPeriodChanged;
  final Function(String)? onSortChanged;

  const FundRankingSectionSimple({
    super.key,
    required this.rankings,
    this.isLoading = false,
    this.selectedPeriod = '�?�?,
    this.sortBy = '收益�?,
    this.onPeriodChanged,
    this.onSortChanged,
  });

  @override
  State<FundRankingSectionSimple> createState() =>
      _FundRankingSectionSimpleState();
}

class _FundRankingSectionSimpleState extends State<FundRankingSectionSimple> {
  // 时间周期选项
  static List String> final _periods = [
    '日增长率',
    '�?�?,
    '�?�?,
    '�?�?,
    '�?�?,
    '�?�?,
    '�?�?,
    '�?�?,
    '今年�?,
    '成立�?
  ];

  // 排序选项
  static List String> final _sortOptions = ['收益�?, '单位净�?, '累计净�?, '日增长率'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 控制区域
        _buildControlSection(),

        const SizedBox(height: 16),

        // 数据展示区域
        _buildDataTable(),
      ],
    );
  }

  /// 构建控制区域
  Widget _buildControlSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明文字
            Text(
              _getDescription(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),

            // 控制按钮
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 时间段选择�?
                  _buildPeriodSelector(isCompact),

                  const SizedBox(width: 12),

                  // 排序选择�?
                  _buildSortSelector(isCompact),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建时间段选择�?
  Widget _buildPeriodSelector(bool isCompact) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _periods.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == widget.selectedPeriod;

          return ChoiceChip(
            label: Text(
              period,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected && widget.onPeriodChanged != null) {
                widget.onPeriodChanged!(period);
              }
            },
            selectedColor: const Color(0xFF1E40AF).withOpacity(0.1),
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color:
                  isSelected ? const Color(0xFF1E40AF) : Colors.grey.shade600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  /// 构建排序选择�?
  Widget _buildSortSelector(bool isCompact) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.sortBy,
          isDense: true,
          icon: const Icon(Icons.sort, size: 16),
          style: TextStyle(
            fontSize: isCompact ? 11 : 12,
            color: Colors.black87,
          ),
          onChanged: (String? newValue) {
            if (newValue != null && widget.onSortChanged != null) {
              widget.onSortChanged!(newValue);
            }
          },
          items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(fontSize: isCompact ? 11 : 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建数据表格
  Widget _buildDataTable() {
    if (widget.rankings.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 表头
          _buildTableHeader(),

          // 表格内容 - 使用固定高度避免约束冲突
          _buildTableContent(),
        ],
      ),
    );
  }

  /// 构建表头
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius only(
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          return Row(
            children: [
              SizedBox(
                width: isCompact ? 35 : 40,
                child: const Text(
                  '排名',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                flex: 3,
                child: Text(
                  '基金信息',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Text(
                  widget.selectedPeriod,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: isCompact ? 50 : 60,
                child: const Text(
                  '操作',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建表格内容
  Widget _buildTableContent() {
    // 限制显示数量，避免性能问题
    final displayCount = math.min(widget.rankings.length, 20);

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400, // 限制最大高�?
      ),
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        itemCount: displayCount,
        itemBuilder: (context, index) {
          return _buildTableRow(widget.rankings[index], index);
        },
      ),
    );
  }

  /// 构建表格�?
  Widget _buildTableRow(FundRanking ranking, int index) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          return Row(
            children: [
              // 排名
              SizedBox(
                width: isCompact ? 35 : 40,
                child: _buildRankingBadge(ranking.rankingPosition),
              ),
              const SizedBox(width: 8),

              // 基金信息
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ranking.fundName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ranking.fundCode} · ${ranking.company}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 收益�?
              Expanded(
                flex: 1,
                child: Text(
                  '${_getReturnForPeriod(ranking).toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getReturnColor(_getReturnForPeriod(ranking)),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),

              // 操作按钮
              SizedBox(
                width: isCompact ? 50 : 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 16),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/fund-detail',
                          arguments: ranking.fundCode,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建排名徽章
  Widget _buildRankingBadge(int rank) {
    if (rank <= 3) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _getRankingBadgeColor(rank),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            rank.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      return Text(
        rank.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getRankingColor(rank),
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  /// 构建空状�?
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无排行数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取描述文字
  String _getDescription() {
    return '�?{widget.selectedPeriod}${widget.sortBy}排序';
  }

  /// 获取指定时间段的收益�?
  double _getReturnForPeriod(FundRanking ranking) {
    switch (widget.selectedPeriod) {
      case '日增长率':
        return ranking.dailyReturn;
      case '�?�?:
        return ranking.return1W;
      case '�?�?:
        return ranking.return1M;
      case '�?�?:
        return ranking.return3M;
      case '�?�?:
        return ranking.return6M;
      case '�?�?:
        return ranking.return1Y;
      case '�?�?:
        return ranking.return2Y;
      case '�?�?:
        return ranking.return3Y;
      case '今年�?:
        return ranking.returnYTD;
      case '成立�?:
        return ranking.returnSinceInception;
      default:
        return ranking.return1Y;
    }
  }

  /// 获取收益率颜�?
  Color _getReturnColor(double returnValue) {
    return returnValue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981);
  }

  /// 获取排名徽章颜色
  Color _getRankingBadgeColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // 金色
      case 2:
        return const Color(0xFFC0C0C0); // 银色
      case 3:
        return const Color(0xFFCD7F32); // 铜色
      default:
        return Colors.grey;
    }
  }

  /// 获取排名颜色
  Color _getRankingColor(int rank) {
    if (rank <= 3) {
      return _getRankingBadgeColor(rank);
    }
    return Colors.grey.shade600;
  }
}
