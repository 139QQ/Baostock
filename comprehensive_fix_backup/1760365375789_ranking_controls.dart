import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';

/// 排行榜控制组件
///
/// 提供排行榜的筛选、排序、时间段选择等控制功能
class RankingControls extends StatefulWidget {
  /// 排行榜类型
  final RankingType rankingType;

  /// 条件变化回调
  final Function(RankingCriteria) onCriteriaChanged;

  /// 当前查询条件
  final RankingCriteria? initialCriteria;

  const RankingControls({
    super.key,
    required this.rankingType,
    required this.onCriteriaChanged,
    this.initialCriteria,
  });

  @override
  State<RankingControls> createState() => _RankingControlsState();
}

class _RankingControlsState extends State<RankingControls> {
  late RankingType _currentRankingType;
  late RankingPeriod _currentPeriod;
  late RankingSortBy _currentSortBy;
  String? _currentFundType;
  String? _currentCompany;

  @override
  void initState() {
    super.initState();
    _initializeFromCriteria();
  }

  /// 从初始条件初始化状态
  void _initializeFromCriteria() {
    _currentRankingType =
        widget.initialCriteria?.rankingType ?? widget.rankingType;
    _currentPeriod =
        widget.initialCriteria?.rankingPeriod ?? RankingPeriod.oneYear;
    _currentSortBy = widget.initialCriteria?.sortBy ?? RankingSortBy.returnRate;
    _currentFundType = widget.initialCriteria?.fundType;
    _currentCompany = widget.initialCriteria?.company;
  }

  /// 构建控制组件
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 排行榜类型和时间段选择
          _buildTopControls(),

          const SizedBox(height: 16),

          // 筛选控制
          _buildFilterControls(),

          const SizedBox(height: 16),

          // 排序控制
          _buildSortControls(),

          // 快速筛选标签
          _buildQuickFilterTags(),
        ],
      ),
    );
  }

  /// 构建顶部控制（排行榜类型和时间段）
  Widget _buildTopControls() {
    return Row(
      children: [
        // 排行榜类型选择
        Expanded(
          flex: 2,
          child: _buildRankingTypeSelector(),
        ),

        const SizedBox(width: 12),

        // 时间段选择
        Expanded(
          flex: 3,
          child: _buildPeriodSelector(),
        ),
      ],
    );
  }

  /// 构建排行榜类型选择器
  Widget _buildRankingTypeSelector() {
    if (widget.rankingType != RankingType.overall) {
      // 如果不是总榜，不显示排行榜类型选择
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RankingType>(
          value: _currentRankingType,
          isDense: true,
          style: const TextStyle(fontSize: 14),
          items: RankingType.values.map((type) {
            return DropdownMenuItem<RankingType>(
              value: type,
              child: Text(_getRankingTypeDisplayName(type)),
            );
          }).toList(),
          onChanged: (RankingType? value) {
            if (value != null) {
              setState(() {
                _currentRankingType = value;
              });
              _notifyCriteriaChanged();
            }
          },
        ),
      ),
    );
  }

  /// 构建时间段选择器
  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RankingPeriod.values.map((period) {
          final isSelected = period == _currentPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _getPeriodDisplayName(period),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentPeriod = period;
                  });
                  _notifyCriteriaChanged();
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey[100],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建筛选控制
  Widget _buildFilterControls() {
    return Row(
      children: [
        // 基金类型筛选
        Expanded(
          child: _buildFundTypeFilter(),
        ),

        const SizedBox(width: 12),

        // 基金公司筛选
        Expanded(
          child: _buildCompanyFilter(),
        ),
      ],
    );
  }

  /// 构建基金类型筛选
  Widget _buildFundTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _currentFundType,
          isDense: true,
          style: const TextStyle(fontSize: 14),
          hint: const Text('基金类型'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('全部类型'),
            ),
            ..._getFundTypes().map((type) {
              return DropdownMenuItem<String?>(
                value: type,
                child: Text(type),
              );
            }),
          ],
          onChanged: (String? value) {
            setState(() {
              _currentFundType = value;
            });
            _notifyCriteriaChanged();
          },
        ),
      ),
    );
  }

  /// 构建基金公司筛选
  Widget _buildCompanyFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _currentCompany,
          isDense: true,
          style: const TextStyle(fontSize: 14),
          hint: const Text('基金公司'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('全部公司'),
            ),
            ..._getFundCompanies().map((company) {
              return DropdownMenuItem<String?>(
                value: company,
                child: Text(company),
              );
            }),
          ],
          onChanged: (String? value) {
            setState(() {
              _currentCompany = value;
            });
            _notifyCriteriaChanged();
          },
        ),
      ),
    );
  }

  /// 构建排序控制
  Widget _buildSortControls() {
    return Row(
      children: [
        const Text(
          '排序方式：',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RankingSortBy.values.map((sortBy) {
                final isSelected = sortBy == _currentSortBy;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _getSortByDisplayName(sortBy),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentSortBy = sortBy;
                        });
                        _notifyCriteriaChanged();
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Colors.grey[100],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建快速筛选标签
  Widget _buildQuickFilterTags() {
    return const SizedBox(height: 16); // 预留空间，后续可扩展
  }

  /// 获取排行榜类型显示名称
  String _getRankingTypeDisplayName(RankingType type) {
    switch (type) {
      case RankingType.overall:
        return '总排行榜';
      case RankingType.byType:
        return '分类排行';
      case RankingType.byCompany:
        return '公司排行';
      case RankingType.byPeriod:
        return '时段排行';
    }
  }

  /// 获取时间段显示名称
  String _getPeriodDisplayName(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.daily:
        return '日排行';
      case RankingPeriod.oneWeek:
        return '近1周';
      case RankingPeriod.oneMonth:
        return '近1月';
      case RankingPeriod.threeMonths:
        return '近3月';
      case RankingPeriod.sixMonths:
        return '近6月';
      case RankingPeriod.oneYear:
        return '近1年';
      case RankingPeriod.twoYears:
        return '近2年';
      case RankingPeriod.threeYears:
        return '近3年';
      case RankingPeriod.ytd:
        return '今年来';
      case RankingPeriod.sinceInception:
        return '成立来';
    }
  }

  /// 获取排序方式显示名称
  String _getSortByDisplayName(RankingSortBy sortBy) {
    switch (sortBy) {
      case RankingSortBy.returnRate:
        return '收益率';
      case RankingSortBy.unitNav:
        return '单位净值';
      case RankingSortBy.accumulatedNav:
        return '累计净值';
      case RankingSortBy.dailyReturn:
        return '日增长';
      case RankingSortBy.rankingPosition:
        return '排名';
    }
  }

  /// 获取基金类型列表
  List<String> _getFundTypes() {
    return [
      '股票型',
      '债券型',
      '混合型',
      '货币型',
      '指数型',
      'QDII',
      'FOF',
      'REITs',
    ];
  }

  /// 获取基金公司列表
  List<String> _getFundCompanies() {
    // 这里可以从API或本地缓存获取真实的基金公司列表
    return [
      '易方达基金',
      '华夏基金',
      '嘉实基金',
      '南方基金',
      '博时基金',
      '广发基金',
      '汇添富基金',
      '富国基金',
      '招商基金',
      '中欧基金',
    ];
  }

  /// 通知查询条件变化
  void _notifyCriteriaChanged() {
    final criteria = RankingCriteria(
      rankingType: _currentRankingType,
      rankingPeriod: _currentPeriod,
      fundType: _currentFundType,
      company: _currentCompany,
      sortBy: _currentSortBy,
      page: 1, // 重置页码
      pageSize: 20,
    );

    widget.onCriteriaChanged(criteria);
  }
}
