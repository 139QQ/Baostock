import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/models/fund.dart';
import 'modern_fund_card.dart';

/// 视图模式枚举
enum ViewMode {
  table, // 表格视图
  card, // 卡片视图
}

/// 基金排行榜组件
///
/// 展示不同时间维度的基金业绩排名，支持：
/// - 多时间段切换（近1周、近1月、近3月、近1年、今年来、成立来）
/// - 不同基金类型筛选
/// - 排序方式选择
/// - 排行榜导出功能
/// - 基金详情快速查看
/// - 分页加载真实数据
/// - 现代化卡片视图和传统表格视图切换
class FundRankingSectionFixed extends StatefulWidget {
  final List<FundRanking>? fundRankings; // 外部传入的真实数据
  final bool isLoading; // 加载状态
  final VoidCallback? onLoadMore; // 加载更多回调
  final String? errorMessage; // 错误信息

  const FundRankingSectionFixed({
    super.key,
    this.fundRankings,
    this.isLoading = false,
    this.onLoadMore,
    this.errorMessage,
  });

  @override
  State<FundRankingSectionFixed> createState() =>
      _FundRankingSectionFixedState();
}

class _FundRankingSectionFixedState extends State<FundRankingSectionFixed> {
  String _selectedPeriod = '近1月';
  String _selectedFundType = '全部';
  String _sortBy = '收益率';
  int _currentPage = 1;
  final int _pageSize = 20;
  ViewMode _viewMode = ViewMode.card; // 默认使用卡片视图
  final Set<String> _favoriteFunds = {}; // 收藏的基金
  // 内部状态管理
  List<FundRanking> _localRankings = [];
  bool _hasMoreData = true;

  // 表格列宽变量 - 动态计算
  double rankWidth = 40.0;
  double codeWidth = 80.0;
  double nameWidth = 180.0;
  double typeWidth = 60.0;
  double navWidth = 70.0;
  double returnWidth = 80.0;
  double actionWidth = 60.0;

  // 静态文本样式 - 性能优化
  static TextStyle headerTextStyle = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
  );

  static TextStyle fundCodeStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
  );

  static TextStyle fundNameStyle = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
  );

  static TextStyle companyStyle = const TextStyle(
    fontSize: 11,
    color: Color(0xFF9CA3AF),
  );

  static TextStyle navStyle = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
  );

  static TextStyle returnStyle = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // 时间周期选项 - 基于AKShare API字段
  final List<String> _periods = [
    '日增长率',
    '近1周',
    '近1月',
    '近3月',
    '近6月',
    '近1年',
    '近2年',
    '近3年',
    '今年来',
    '成立来'
  ];

  // 基金类型选项
  final List<String> _fundTypes = [
    '全部',
    '股票型',
    '债券型',
    '混合型',
    '货币型',
    '指数型',
    'QDII'
  ];

  // 排序选项 - 基于AKShare API实际字段
  final List<String> _sortOptions = ['收益率', '单位净值', '累计净值', '日增长率'];

  @override
  void initState() {
    super.initState();
    _initializeWithExternalData();
  }

  @override
  void didUpdateWidget(FundRankingSectionFixed oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部数据更新时，重新初始化
    if (widget.fundRankings != oldWidget.fundRankings) {
      _initializeWithExternalData();
    }
  }

  /// 初始化外部数据
  void _initializeWithExternalData() {
    if (widget.fundRankings != null) {
      // 使用外部真实数据
      setState(() {
        _localRankings = widget.fundRankings!;
        _hasMoreData = widget.fundRankings!.length >= _pageSize;
        _currentPage = 1; // 重置页码
      });
      _sortRankings();
    } else {
      // 没有外部数据时使用模拟数据（降级处理）
      _loadRankings();
    }
  }

  /// 加载排行榜数据（增强版 - 支持真实数据）
  Future<void> _loadRankings() async {
    // 使用外部加载状态，不设置内部状态
    if (widget.isLoading) return;

    // 如果有外部数据源，不应该使用模拟数据
    if (widget.fundRankings != null) {
      debugPrint('⚠️ 已有外部真实数据，跳过模拟数据加载');
      return;
    }

    // 没有外部数据时，显示空状态而非模拟数据
    debugPrint('⚠️ 没有外部数据可用，显示空状态');
    if (mounted) {
      setState(() {
        _localRankings = [];
        _hasMoreData = false;
      });
    }
  }

  void _handlePeriodChanged(String period) {
    if (mounted && _selectedPeriod != period) {
      setState(() {
        _selectedPeriod = period;
      });
      _sortRankings();
    }
  }

  void _handleFundTypeChanged(String fundType) {
    if (mounted && _selectedFundType != fundType) {
      setState(() {
        _selectedFundType = fundType;
      });
      _loadRankings();
    }
  }

  void _handleSortChanged(String sortBy) {
    if (mounted && _sortBy != sortBy) {
      setState(() {
        _sortBy = sortBy;
      });
      _sortRankings();
    }
  }

  /// 检查数据质量问题
  bool _checkDataQualityIssues() {
    if (_localRankings.isEmpty) return false;

    // 检查是否有大量数据使用默认值
    int unknownTypeCount = 0;
    int unknownCompanyCount = 0;

    for (final ranking in _localRankings) {
      if (ranking.fundType == '未知类型') unknownTypeCount++;
      if (ranking.company == '未知公司') unknownCompanyCount++;
    }

    // 如果超过30%的数据使用默认值，认为存在数据质量问题
    final threshold = (_localRankings.length * 0.3).ceil();
    return unknownTypeCount > threshold || unknownCompanyCount > threshold;
  }

  /// 处理未知值的显示文本
  String _getDisplayText(String value, String fallback) {
    if (value == '未知类型' || value == '未知公司' || value.isEmpty) {
      return fallback;
    }
    return value;
  }

  /// 获取基金类型的显示文本
  String _getFundTypeDisplay(String fundType) {
    return _getDisplayText(fundType, '--');
  }

  /// 获取基金公司的显示文本
  String _getCompanyDisplay(String company) {
    return _getDisplayText(company, '--');
  }

  /// 排序排行榜 - 基于AKShare API实际字段
  void _sortRankings() {
    if (!mounted || _localRankings.isEmpty) return;

    // 缓存排序键值，避免在排序过程中重复计算
    switch (_sortBy) {
      case '收益率':
        _localRankings.sort((a, b) {
          final returnA = _getReturnForPeriod(a);
          final returnB = _getReturnForPeriod(b);
          return returnB.compareTo(returnA);
        });
        break;
      case '单位净值':
        _localRankings.sort((a, b) => b.unitNav.compareTo(a.unitNav));
        break;
      case '累计净值':
        _localRankings
            .sort((a, b) => b.accumulatedNav.compareTo(a.accumulatedNav));
        break;
      case '日增长率':
        _localRankings.sort((a, b) => b.dailyReturn.compareTo(a.dailyReturn));
        break;
    }

    // 排序后重新计算排名位置（支持同分并列排名）
    _updateRankingsWithTies(_localRankings);

    // 直接调用setState，简化逻辑
    if (mounted) {
      setState(() {
        // 数据已排序且排名已重新计算，触发UI更新
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和控制区域 - 响应式布局
            _buildHeaderSection(),

            const SizedBox(height: 20),

            // 排行榜内容 - 根据视图模式显示
            if (widget.isLoading)
              _buildLoadingWidget()
            else if (widget.errorMessage != null)
              _buildErrorWidget()
            else if (_localRankings.isEmpty)
              _buildEmptyWidget()
            else
              _viewMode == ViewMode.card
                  ? _buildCardView()
                  : _buildRankingTable(),

            const SizedBox(height: 16),

            // 分页控件
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  /// 构建头部区域
  Widget _buildHeaderSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主标题区域
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '基金排行榜',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (!isCompact) ...[
                  const Spacer(),
                  // 视图切换按钮组
                  _buildViewModeToggle(),
                  const SizedBox(width: 12),
                  // 导出按钮
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('导出功能开发中')),
                      );
                    },
                    tooltip: '导出数据',
                  ),
                ] else ...[
                  const Spacer(),
                  // 紧凑模式下的视图切换
                  _buildCompactViewModeToggle(),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // 控制按钮区域 - 增强响应式处理
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 时间周期选择器
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 120 : 200,
                    ),
                    child: _buildPeriodSelector(),
                  ),
                  const SizedBox(width: 12),
                  // 基金类型选择器
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 100 : 150,
                    ),
                    child: _buildFundTypeSelector(),
                  ),
                  const SizedBox(width: 12),
                  // 排序选择器
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 100 : 150,
                    ),
                    child: _buildSortSelector(),
                  ),
                  if (isCompact) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('导出功能开发中')),
                        );
                      },
                      tooltip: '导出数据',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 排行榜说明
            Text(
              _getRankingDescription(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建时间周期选择器
  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _periods.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod;

          return ChoiceChip(
            label: Text(
              period,
              style: const TextStyle(fontSize: 12),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                _handlePeriodChanged(period);
              }
            },
            selectedColor: const Color(0xFF1E40AF).withOpacity(0.1),
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color:
                  isSelected ? const Color(0xFF1E40AF) : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  /// 构建基金类型选择器
  Widget _buildFundTypeSelector() {
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
          value: _selectedFundType,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _handleFundTypeChanged(newValue);
            }
          },
          items: _fundTypes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建排序选择器
  Widget _buildSortSelector() {
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
          value: _sortBy,
          isDense: true,
          icon: const Icon(Icons.sort, size: 16),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _handleSortChanged(newValue);
            }
          },
          items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建排行榜说明
  String _getRankingDescription() {
    String description = '$_selectedPeriod收益率排名';
    if (_selectedFundType != '全部') {
      description += ' · $_selectedFundType';
    }
    if (_sortBy != '收益率') {
      description += ' · $_sortBy排序';
    }
    return description;
  }

  /// 构建排行榜表格 - 优化横向滚动和文本自适应
  Widget _buildRankingTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        // 优化列宽分配 - 基于内容重要性的合理分配
        final totalWidth = constraints.maxWidth;
        const padding = 32.0; // 左右内边距总和
        final availableWidth = totalWidth - padding;

        // 重新设计：基于内容重要性的列宽分配
        if (isCompact) {
          // 移动端紧凑布局 - 优先保证核心信息
          rankWidth = 32.0; // 排名 - 最小必要宽度
          codeWidth = 55.0; // 代码 - 紧凑显示
          nameWidth = 85.0; // 名称 - 核心信息，但减少宽度
          typeWidth = 35.0; // 类型 - 最小宽度
          navWidth = 50.0; // 净值 - 紧凑显示
          returnWidth = 55.0; // 收益率 - 紧凑显示
          actionWidth = 40.0; // 操作 - 最小按钮宽度
        } else {
          // 桌面端标准布局 - 平衡各列重要性
          rankWidth = 40.0; // 排名
          codeWidth = 70.0; // 代码
          nameWidth = 120.0; // 名称 - 关键信息，但不过度占用空间
          typeWidth = 50.0; // 类型
          navWidth = 65.0; // 净值
          returnWidth = 70.0; // 收益率
          actionWidth = 55.0; // 操作
        }

        // 只在桌面端且空间充足时进行比例放大
        if (!isCompact && availableWidth > 600) {
          final calculatedTotalWidth = rankWidth +
              codeWidth +
              nameWidth +
              typeWidth +
              navWidth +
              returnWidth +
              actionWidth;
          if (calculatedTotalWidth < availableWidth) {
            final scaleFactor =
                math.min(availableWidth / calculatedTotalWidth, 1.3); // 最大放大30%
            rankWidth *= scaleFactor;
            codeWidth *= scaleFactor;
            nameWidth *= scaleFactor;
            typeWidth *= scaleFactor;
            navWidth *= scaleFactor;
            returnWidth *= scaleFactor;
            actionWidth *= scaleFactor;
          }
        }

        debugPrint(
            '📊 列宽分配 - isCompact: $isCompact, totalWidth: $totalWidth, availableWidth: $availableWidth');
        debugPrint(
            '📊 rank: $rankWidth, code: $codeWidth, name: $nameWidth, type: $typeWidth, nav: $navWidth, return: $returnWidth, action: $actionWidth');

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 表头 - 使用横向滚动，修复边框样式
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    // 移除部分圆角，避免与父容器圆角冲突
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: rankWidth,
                        child: Text('排名',
                            style:
                                _FundRankingSectionFixedState.headerTextStyle,
                            textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: codeWidth,
                        child: Text('基金代码',
                            style:
                                _FundRankingSectionFixedState.headerTextStyle,
                            textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: nameWidth,
                        child: Text('基金名称',
                            style:
                                _FundRankingSectionFixedState.headerTextStyle,
                            textAlign: TextAlign.left),
                      ),
                      SizedBox(
                        width: typeWidth,
                        child: Text('类型',
                            style:
                                _FundRankingSectionFixedState.headerTextStyle,
                            textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: navWidth,
                        child: Text('单位净值',
                            style:
                                _FundRankingSectionFixedState.headerTextStyle,
                            textAlign: TextAlign.right),
                      ),
                      SizedBox(
                        width: returnWidth,
                        child: Text(_selectedPeriod,
                            style:
                                _FundRankingSectionFixedState.headerTextStyle,
                            textAlign: TextAlign.right),
                      ),
                      SizedBox(
                        width: actionWidth,
                        child: Text('操作',
                            style:
                                _FundRankingSectionFixedState.headerTextStyle,
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),

              // 表格内容 - 修复：使用固定高度避免约束冲突
              SizedBox(
                height: math.min(_localRankings.length * 72.0 + 50,
                    400), // 限制最大高度400px，每行约72px
                child: ListView.builder(
                  physics: const ClampingScrollPhysics(), // 防止过度滚动
                  itemCount: _localRankings.length,
                  itemBuilder: (context, index) {
                    return _buildRankingRow(_localRankings[index], index,
                        isCompact: isCompact);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建排行榜行 - 支持响应式布局 - 使用类级动态列宽变量
  Widget _buildRankingRow(FundRanking ranking, int index,
      {bool isCompact = false}) {
    // 使用类级别的动态列宽变量，不再重新定义
    debugPrint(
        '📝 构建第$index行 - 排名: ${ranking.rankingPosition}, 基金: ${ranking.fundName}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      child: Row(
        children: [
          // 排名 - 修复溢出约束
          SizedBox(
            width: rankWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min, // 避免Row扩展超出约束
              children: [
                if (ranking.rankingPosition <= 3)
                  Container(
                    width: 18, // 减少尺寸避免溢出
                    height: 18,
                    decoration: BoxDecoration(
                      color: FundRanking.getRankingBadgeColor(
                          ranking.rankingPosition),
                      borderRadius: BorderRadius.circular(3), // 减少圆角
                    ),
                    child: Center(
                      child: Text(
                        ranking.rankingPosition.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10, // 减少字体大小
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    ranking.rankingPosition.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          FundRanking.getRankingColor(ranking.rankingPosition),
                      fontSize: 12, // 明确字体大小
                    ),
                  ),
                // 移除排名百分比的冗余显示，只保留排名数字
              ],
            ),
          ),

          // 基金代码
          SizedBox(
            width: codeWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.fundCode,
                  style: _FundRankingSectionFixedState.fundCodeStyle,
                ),
                Text(
                  _getCompanyDisplay(ranking.company),
                  style: _FundRankingSectionFixedState.companyStyle,
                ),
              ],
            ),
          ),

          // 基金名称 - 使用固定宽度避免约束冲突
          SizedBox(
            width: nameWidth, // 使用固定宽度避免Flexible在横向滚动中的约束冲突
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.fundName,
                  style: isCompact
                      ? _FundRankingSectionFixedState.fundNameStyle
                          .copyWith(fontSize: 12)
                      : _FundRankingSectionFixedState.fundNameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact)
                  Text(
                    _getCompanyDisplay(ranking.company),
                    style: _FundRankingSectionFixedState.companyStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // 基金类型 - 修复：确保文本不会换行或拆分
          SizedBox(
            width: typeWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2), // 减少内边距避免换行
              decoration: BoxDecoration(
                color: _getFundTypeColor(ranking.fundType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(3), // 减少圆角节省空间
              ),
              child: Text(
                _getFundTypeDisplay(ranking.fundType),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11, // 紧凑模式下使用更小字体
                  color: _getFundTypeColor(ranking.fundType),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // 防止文本溢出
              ),
            ),
          ),

          // 单位净值 - 修复：只显示当前单位净值，避免重复
          SizedBox(
            width: navWidth,
            child: Text(
              ranking.unitNav.toStringAsFixed(4),
              style: _FundRankingSectionFixedState.navStyle,
              textAlign: TextAlign.right,
            ),
          ),

          // 收益率
          SizedBox(
            width: returnWidth,
            child: Text(
              '${_getReturnForPeriod(ranking).toStringAsFixed(2)}%',
              style: _FundRankingSectionFixedState.returnStyle.copyWith(
                color: _getReturnColor(_getReturnForPeriod(ranking)),
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // 操作
          SizedBox(
            width: actionWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, size: 14),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已收藏${ranking.fundName}')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    splashRadius: 14,
                  ),
                  const SizedBox(width: 1),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 14),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/fund-detail',
                        arguments: ranking.fundCode,
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    splashRadius: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空数据状态 - 优化提示信息
  Widget _buildEmptyWidget() {
    final isFiltered = _selectedFundType != '全部';
    final hasDataQualityIssues = _checkDataQualityIssues();

    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered
                ? Icons.filter_list_off
                : hasDataQualityIssues
                    ? Icons.data_thresholding_outlined
                    : Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? '当前筛选条件下无数据'
                : hasDataQualityIssues
                    ? '数据加载不完整'
                    : '暂无基金排行数据',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? '请尝试更换基金类型筛选条件'
                : hasDataQualityIssues
                    ? '部分基金信息暂缺，正在努力完善数据'
                    : '请检查网络连接或稍后再试',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isFiltered
                ? () {
                    // 如果是筛选导致的空数据，重置筛选条件
                    if (mounted) {
                      setState(() {
                        _selectedFundType = '全部';
                      });
                      _loadRankings();
                    }
                  }
                : _loadRankings,
            icon:
                Icon(isFiltered ? Icons.filter_list : Icons.refresh, size: 16),
            label: Text(isFiltered ? '重置筛选' : '重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态组件
  Widget _buildErrorWidget() {
    final isDataQualityIssue = widget.errorMessage?.contains('数据不完整') == true ||
        widget.errorMessage?.contains('字段缺失') == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDataQualityIssue
                  ? Icons.data_thresholding_outlined
                  : Icons.error_outline,
              color: isDataQualityIssue ? Colors.orange : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isDataQualityIssue ? '数据加载不完整' : '加载失败: ${widget.errorMessage}',
              style: TextStyle(
                color: isDataQualityIssue ? Colors.orange : Colors.red,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isDataQualityIssue) ...[
              const SizedBox(height: 8),
              const Text(
                '部分基金信息暂缺，仍可查看基本排行数据',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (widget.onLoadMore != null) {
                  widget.onLoadMore!();
                } else {
                  _loadRankings();
                }
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载排行榜数据...'),
        ],
      ),
    );
  }

  /// 构建分页控件
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    if (mounted) {
                      setState(() {
                        _currentPage--;
                        // 应用分页过滤和排序
                        _applyPaginationAndSorting();
                      });
                    }
                  }
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '第$_currentPage 页（共${(_localRankings.length / _pageSize).ceil()} 页）',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < (_localRankings.length / _pageSize).ceil()
                ? () {
                    if (mounted) {
                      setState(() {
                        _currentPage++;
                        // 应用分页过滤和排序
                        _applyPaginationAndSorting();
                      });
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// 应用分页过滤和排序
  void _applyPaginationAndSorting() {
    if (!mounted || widget.fundRankings == null) return;

    // 计算当前页的起始和结束索引
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;

    // 获取过滤后的数据（基于基金类型）
    List<FundRanking> filteredData = widget.fundRankings!;
    if (_selectedFundType != '全部') {
      filteredData = filteredData
          .where((fund) => fund.fundType == _selectedFundType)
          .toList();
    }

    // 应用排序
    switch (_sortBy) {
      case '收益率':
        filteredData.sort((a, b) {
          final returnA = _getReturnForPeriod(a);
          final returnB = _getReturnForPeriod(b);
          return returnB.compareTo(returnA);
        });
        break;
      case '单位净值':
        filteredData.sort((a, b) => b.unitNav.compareTo(a.unitNav));
        break;
      case '累计净值':
        filteredData
            .sort((a, b) => b.accumulatedNav.compareTo(a.accumulatedNav));
        break;
      case '日增长率':
        filteredData.sort((a, b) => b.dailyReturn.compareTo(a.dailyReturn));
        break;
    }

    // 重新计算排名
    _updateRankingsWithTies(filteredData);

    // 应用分页
    final paginatedData = startIndex < filteredData.length
        ? filteredData.sublist(startIndex,
            endIndex > filteredData.length ? filteredData.length : endIndex)
        : <FundRanking>[];

    if (mounted) {
      setState(() {
        _localRankings = paginatedData;
        _hasMoreData = endIndex < filteredData.length;
      });
    }

    debugPrint(
        '📄 分页应用 - 页码: $_currentPage, 开始索引: $startIndex, 结束索引: $endIndex');
    debugPrint(
        '📄 分页结果 - 当前页数量: ${paginatedData.length} 项， 是否有更多: $_hasMoreData');
  }

  /// 更新排名，支持同分并列（如多只基金收益率相同则排名相同）
  void _updateRankingsWithTies(List<FundRanking> dataToSort) {
    if (dataToSort.isEmpty) return;

    // 获取当前排序键值（基于选中的时间段）
    double getSortValue(FundRanking ranking) {
      return _getReturnForPeriod(ranking);
    }

    // 重新计算排名，支持并列
    int currentRank = 1;
    int itemsInRank = 0;
    double? previousValue;

    for (int i = 0; i < dataToSort.length; i++) {
      final currentValue = getSortValue(dataToSort[i]);

      // 如果是第一个元素，或者值与上一个不同，则更新排名
      if (i == 0 || currentValue != previousValue) {
        currentRank = currentRank + itemsInRank;
        itemsInRank = 1;
      } else {
        // 值相同，增加当前排名的项目数
        itemsInRank++;
      }

      // 更新排名位置
      dataToSort[i] = dataToSort[i].copyWith(
        rankingPosition: currentRank,
      );

      previousValue = currentValue;
    }
  }

  /// 获取收益率颜色
  Color _getReturnColor(double returnValue) {
    return returnValue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981);
  }

  /// 获取基金类型颜色
  Color _getFundTypeColor(String type) {
    switch (type) {
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
        return Colors.grey;
    }
  }

  /// 获取指定期间的收益率 - 基于AKShare API数据
  double _getReturnForPeriod(FundRanking ranking) {
    switch (_selectedPeriod) {
      case '日增长率':
        return ranking.dailyReturn;
      case '近1周':
        return ranking.return1W;
      case '近1月':
        return ranking.return1M;
      case '近3月':
        return ranking.return3M;
      case '近6月':
        return ranking.return6M;
      case '近1年':
        return ranking.return1Y;
      case '近2年':
        return ranking.return2Y;
      case '近3年':
        return ranking.return3Y;
      case '今年来':
        return ranking.returnYTD;
      case '成立来':
        return ranking.returnSinceInception;
      default:
        return ranking.return1Y;
    }
  }

  /// 构建视图模式切换按钮
  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(
            icon: Icons.view_list,
            label: '表格',
            isSelected: _viewMode == ViewMode.table,
            onTap: () => _switchViewMode(ViewMode.table),
          ),
          _buildViewModeButton(
            icon: Icons.view_module,
            label: '卡片',
            isSelected: _viewMode == ViewMode.card,
            onTap: () => _switchViewMode(ViewMode.card),
          ),
        ],
      ),
    );
  }

  /// 构建紧凑模式视图切换按钮
  Widget _buildCompactViewModeToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _viewMode == ViewMode.table ? Icons.view_list : Icons.view_module,
            color: _viewMode == ViewMode.table
                ? const Color(0xFF1E40AF)
                : Colors.grey.shade600,
          ),
          onPressed: () {
            _switchViewMode(
                _viewMode == ViewMode.table ? ViewMode.card : ViewMode.table);
          },
          tooltip: _viewMode == ViewMode.table ? '切换到卡片视图' : '切换到表格视图',
        ),
      ],
    );
  }

  /// 构建单个视图模式按钮
  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E40AF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 切换视图模式
  void _switchViewMode(ViewMode mode) {
    if (mounted && _viewMode != mode) {
      setState(() {
        _viewMode = mode;
      });
    }
  }

  /// 处理基金收藏
  void _handleFundFavorite(FundRanking fund, int ranking) {
    setState(() {
      if (_favoriteFunds.contains(fund.fundCode)) {
        _favoriteFunds.remove(fund.fundCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已取消收藏${fund.fundName}')),
        );
      } else {
        _favoriteFunds.add(fund.fundCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已收藏${fund.fundName}')),
        );
      }
    });
  }

  /// 处理基金详情查看
  void _handleFundDetails(FundRanking fund, int ranking) {
    Navigator.pushNamed(
      context,
      '/fund-detail',
      arguments: fund.fundCode,
    );
  }

  /// 处理基金点击
  void _handleFundTap(FundRanking fund, int ranking) {
    // 可以添加点击后的详细展示逻辑
    debugPrint('点击基金: ${fund.fundName} (排名: $ranking)');
  }

  /// 构建卡片视图
  Widget _buildCardView() {
    return ModernFundCardList(
      funds: _localRankings,
      selectedPeriod: _selectedPeriod,
      onFundTap: _handleFundTap,
      onFundFavorite: _handleFundFavorite,
      onFundDetails: _handleFundDetails,
      favoriteFunds: _favoriteFunds,
      displayMode: CardDisplayMode.compact,
    );
  }
}
