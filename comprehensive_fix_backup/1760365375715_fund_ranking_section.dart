import 'dart:ui';

import 'package:flutter/material.dart';

/// 基金排行数据模型
class FundRanking {
  final String fundCode;
  final String fundName;
  final String fundType;
  final String company;
  final int rankingPosition;
  final int totalCount;
  final double return1W;
  final double return1M;
  final double return3M;
  final double return6M;
  final double return1Y;
  final double return2Y;
  final double return3Y;
  final double returnYTD;
  final double returnSinceInception;
  final double sharpeRatio;
  final double maxDrawdown;
  final double volatility;
  final double scale;
  final double rankingPercentile;
  final String timePeriod;
  final DateTime rankingDate;

  const FundRanking({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.company,
    required this.rankingPosition,
    required this.totalCount,
    required this.return1W,
    required this.return1M,
    required this.return3M,
    required this.return6M,
    required this.return1Y,
    required this.return2Y,
    required this.return3Y,
    required this.returnYTD,
    required this.returnSinceInception,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.volatility,
    required this.scale,
    required this.rankingPercentile,
    required this.timePeriod,
    required this.rankingDate,
  });

  /// 获取排名徽章颜色（1-3名特殊颜色）
  static Color getRankingBadgeColor(int position) {
    if (position == 1) return const Color(0xFFFFD700); // 金色
    if (position == 2) return const Color(0xFFC0C0C0); // 银色
    if (position == 3) return const Color(0xFFCD7F32); // 铜色
    return Colors.transparent;
  }

  /// 获取排名文字颜色（非1-3名）
  static Color getRankingColor(int position) {
    return position > 3 ? Colors.grey.shade700 : Colors.transparent;
  }
}

/// 基金排行榜组件 - 修复版本
///
/// 展示不同时间维度的基金业绩排名，支持：
/// - 多时间段切换（近1周、近1月、近3月、近1年、今年来、成立来）
/// - 不同基金类型筛选
/// - 排序方式选择
/// - 排行榜导出功能
/// - 基金详情快速查看
/// - 支持外部真实数据传入
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
  String _selectedPeriod = '近1年';
  String _selectedFundType = '全部';
  String _sortBy = '收益率';
  bool _isLoading = false;
  List<FundRanking> _rankings = [];
  List<FundRanking> _filteredRankings = []; // 过滤后的数据
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true; // 是否有更多数据

  // 时间周期选项
  final List<String> _periods = ['近1周', '近1月', '近3月', '近1年', '今年来', '成立来'];

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

  // 排序选项
  final List<String> _sortOptions = ['收益率', '夏普比率', '基金规模', '风险调整'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 初始化数据 - 支持外部真实数据和错误处理（优化版）
  void _initializeData() {
    if (widget.errorMessage != null) {
      debugPrint('❌ 外部数据加载错误: ${widget.errorMessage}');
      return;
    }

    if (widget.fundRankings != null && widget.fundRankings!.isNotEmpty) {
      debugPrint('✅ 使用外部传入的真实数据，共 ${widget.fundRankings!.length} 条记录');
      setState(() {
        _rankings = widget.fundRankings!;
        _filteredRankings = widget.fundRankings!;
        _hasMoreData = widget.fundRankings!.length >= _pageSize;
        _currentPage = 1; // 重置页码
      });
      _applyFiltersAndPagination();
    } else if (widget.isLoading) {
      debugPrint('⏳ 外部数据正在加载中，显示增强加载界面...');
    } else {
      debugPrint('🔄 未提供外部数据，显示空状态');
      setState(() {
        _rankings = [];
        _filteredRankings = [];
        _hasMoreData = false;
      });
    }
  }

  @override
  void didUpdateWidget(FundRankingSectionFixed oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 监听外部数据变化（包括错误状态）
    if (widget.fundRankings != oldWidget.fundRankings ||
        widget.errorMessage != oldWidget.errorMessage ||
        widget.isLoading != oldWidget.isLoading) {
      debugPrint('📊 检测到外部数据状态变化，重新初始化');
      _initializeData();
    }
  }

  /// 应用过滤和分页逻辑
  void _applyFiltersAndPagination() {
    if (!mounted) return;

    // Step 1: 基金类型过滤
    List<FundRanking> filteredList = _rankings;
    if (_selectedFundType != '全部') {
      filteredList = _rankings
          .where((fund) => fund.fundType == _selectedFundType)
          .toList();
    }

    // Step 2: 应用排序
    _sortRankingsForList(filteredList);

    // Step 3: 分页处理
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;

    setState(() {
      if (startIndex < filteredList.length) {
        final actualEndIndex =
            endIndex > filteredList.length ? filteredList.length : endIndex;
        _filteredRankings = filteredList.sublist(startIndex, actualEndIndex);
        _hasMoreData = actualEndIndex < filteredList.length;
      } else {
        _filteredRankings = [];
        _hasMoreData = false;
      }
    });

    debugPrint('📄 分页信息 - 当前页: $_currentPage, 每页: $_pageSize, '
        '过滤后总数: ${filteredList.length}, 当前显示: ${_filteredRankings.length}, '
        '是否还有更多: $_hasMoreData');
  }

  /// 为指定列表应用排序
  void _sortRankingsForList(List<FundRanking> list) {
    switch (_sortBy) {
      case '收益率':
        list.sort(
            (a, b) => _getReturnForPeriod(b).compareTo(_getReturnForPeriod(a)));
        break;
      case '夏普比率':
        list.sort((a, b) => b.sharpeRatio.compareTo(a.sharpeRatio));
        break;
      case '基金规模':
        list.sort((a, b) => b.scale.compareTo(a.scale));
        break;
      case '风险调整':
        list.sort((a, b) => b.sharpeRatio.compareTo(a.sharpeRatio));
        break;
    }
  }

  Future<void> _loadRankings() async {
    // 如果有外部数据源，不应该使用模拟数据
    if (widget.fundRankings != null) {
      debugPrint('✅ 已有外部真实数据，跳过模拟数据加载');
      return;
    }

    // 没有外部数据时，显示空状态而非模拟数据
    debugPrint('⚠️ 没有外部数据可用，显示空状态');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _rankings = [];
        _filteredRankings = [];
      });
    }
  }

  void _handlePeriodChanged(String period) {
    if (mounted) {
      setState(() {
        _selectedPeriod = period;
      });
    }
    _sortRankings();
  }

  void _handleFundTypeChanged(String fundType) {
    if (mounted) {
      setState(() {
        _selectedFundType = fundType;
        _currentPage = 1; // 重置页码
      });
    }
    _applyFiltersAndPagination(); // 使用新的过滤和分页逻辑
  }

  void _handleSortChanged(String sortBy) {
    if (mounted) {
      setState(() {
        _sortBy = sortBy;
        _currentPage = 1; // 重置页码
      });
    }
    _applyFiltersAndPagination(); // 使用新的过滤和分页逻辑
  }

  void _sortRankings() {
    if (mounted) {
      setState(() {
        switch (_sortBy) {
          case '收益率':
            _rankings.sort((a, b) => b.return1Y.compareTo(a.return1Y));
            break;
          case '夏普比率':
            _rankings.sort((a, b) => b.sharpeRatio.compareTo(a.sharpeRatio));
            break;
          case '基金规模':
            _rankings.sort((a, b) => b.scale.compareTo(a.scale));
            break;
          case '风险调整':
            _rankings.sort((a, b) => b.sharpeRatio.compareTo(a.sharpeRatio));
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和控制区域 - 响应式布局
            _buildHeaderSection(),

            const SizedBox(height: 20),

            // 排行榜表格 - 智能加载状态切换
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContentWidget(),
            ),

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
                ],
              ],
            ),

            const SizedBox(height: 12),

            // 控制按钮区域
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                // 时间周期选择器
                _buildPeriodSelector(),
                // 基金类型选择器
                _buildFundTypeSelector(),
                // 排序选择器
                _buildSortSelector(),
                if (isCompact)
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
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFundType,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down, size: 16),
          style: TextStyle(fontSize: 12, color: Colors.black87),
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
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isDense: true,
          icon: Icon(Icons.sort, size: 16),
          style: TextStyle(fontSize: 12, color: Colors.black87),
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
    String description = '按$_selectedPeriod收益率排序';
    if (_selectedFundType != '全部') {
      description += ' · $_selectedFundType';
    }
    if (_sortBy != '收益率') {
      description += ' · 按$_sortBy排序';
    }
    return description;
  }

  /// 构建排行榜表格（支持空状态显示）
  Widget _buildRankingTable() {
    // 如果没有数据，显示空状态
    if (_filteredRankings.isEmpty) {
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('排名', style: _headerTextStyle)),
                SizedBox(
                    width: 80, child: Text('基金代码', style: _headerTextStyle)),
                Expanded(child: Text('基金名称', style: _headerTextStyle)),
                SizedBox(width: 60, child: Text('类型', style: _headerTextStyle)),
                SizedBox(
                    width: 80,
                    child: Text(_selectedPeriod,
                        style: _headerTextStyle, textAlign: TextAlign.right)),
                SizedBox(
                    width: 80,
                    child: Text('夏普比率',
                        style: _headerTextStyle, textAlign: TextAlign.right)),
                SizedBox(
                    width: 60,
                    child: Text('操作',
                        style: _headerTextStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),

          // 表格内容
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: List.generate(
                _filteredRankings.length,
                (index) => _buildRankingRow(_filteredRankings[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态界面
  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '暂无基金排行数据',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请稍后重试或检查网络连接',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadRankings();
            },
            icon: Icon(Icons.refresh, size: 18),
            label: Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建排行行
  Widget _buildRankingRow(FundRanking ranking, int index) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      child: Row(
        children: [
          // 排名
          SizedBox(
            width: 40,
            child: Row(
              children: [
                if (ranking.rankingPosition <= 3)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: FundRanking.getRankingBadgeColor(
                          ranking.rankingPosition),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        ranking.rankingPosition.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
                    ),
                  ),
                SizedBox(width: 8),
                Text(
                  '(${ranking.rankingPercentile.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 基金代码
          SizedBox(
            width: 80,
            child: Text(
              ranking.fundCode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),

          // 基金名称
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.fundName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  ranking.company,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 基金类型
          SizedBox(
            width: 60,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 收益率
          SizedBox(
            width: 80,
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

          // 夏普比率
          SizedBox(
            width: 80,
            child: Text(
              ranking.sharpeRatio.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // 操作
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border, size: 16),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已收藏 ${ranking.fundName}')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 16),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/fund-detail',
                      arguments: ranking.fundCode,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建骨架屏加载效果 - 模拟真实表格结构
  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        // 骨架屏表格头部
        Container(
          height: 48,
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildSkeletonCell(40), // 排名
              _buildSkeletonCell(60), // 基金代码
              _buildSkeletonCell(120), // 基金名称
              _buildSkeletonCell(60), // 基金类型
              _buildSkeletonCell(80), // 单位净值
              _buildSkeletonCell(100), // 收益率
              _buildSkeletonCell(60), // 操作
            ],
          ),
        ),

        // 骨架屏数据行
        ...List.generate(8, (index) {
          return Container(
            height: 56,
            margin: EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                _buildSkeletonCell(40), // 排名
                _buildSkeletonCell(60), // 基金代码
                _buildSkeletonCell(120), // 基金名称
                _buildSkeletonCell(60), // 基金类型
                _buildSkeletonCell(80), // 单位净值
                _buildSkeletonCell(100), // 收益率
                _buildSkeletonCell(60), // 操作
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // 骨架屏分页控件
        Container(
          height: 40,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  /// 构建骨架屏单元格（简化版动画）
  Widget _buildSkeletonCell(double width) {
    return Container(
      width: width,
      height: 16,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// 构建增强版加载状态组件 - 支持进度显示和详细信息
  Widget _buildLoadingWidget() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主要进度指示器
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
            ),
          ),
          SizedBox(height: 24),

          // 标题
          Text(
            '正在加载基金排行榜',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
          ),

          SizedBox(height: 8),

          // 详细说明
          Text(
            '数据源：东方财富网 · 预计时间：15-20秒',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),

          SizedBox(height: 16),

          // 加载提示
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 8),
                Text(
                  '数据量较大，请耐心等待',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // 动画点
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF1E40AF).withOpacity(0.3 + (index * 0.3)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 构建内容组件 - 智能状态管理
  Widget _buildContentWidget() {
    if (widget.errorMessage != null) {
      return _buildErrorWidget();
    } else if (widget.isLoading || _isLoading) {
      return _buildLoadingWidget(); // 统一使用增强版加载组件
    } else {
      return _buildRankingTable();
    }
  }

  /// 构建增强版错误组件 - 友好的错误提示
  Widget _buildErrorWidget() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 错误图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red.shade400,
            ),
          ),

          SizedBox(height: 24),

          // 错误标题
          Text(
            '数据加载失败',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
          ),

          SizedBox(height: 8),

          // 错误描述
          Text(
            widget.errorMessage ?? '未知错误',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          // 解决方案提示
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  '建议解决方案：',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '1. 检查网络连接\n2. 稍后重试（API响应较慢）\n3. 联系技术支持',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // 重试按钮
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onLoadMore != null) {
                widget.onLoadMore!();
              }
            },
            icon: Icon(Icons.refresh, size: 18),
            label: Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分页控件（支持外部数据分页）
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1
              ? () {
                  if (mounted) {
                    setState(() {
                      _currentPage--;
                    });
                  }

                  // 如果有外部数据，使用分页逻辑；否则重新加载
                  if (widget.fundRankings != null) {
                    _applyFiltersAndPagination();
                  } else {
                    _loadRankings();
                  }
                }
              : null,
        ),
        Text(
          '第 $_currentPage 页',
          style: const TextStyle(fontSize: 14),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _hasMoreData
              ? () {
                  if (mounted) {
                    setState(() {
                      _currentPage++;
                    });
                  }

                  // 如果有外部数据，使用分页逻辑；否则重新加载
                  if (widget.fundRankings != null) {
                    _applyFiltersAndPagination();
                  } else {
                    _loadRankings();
                  }

                  // 如果有外部加载更多回调，调用它
                  if (widget.onLoadMore != null) {
                    widget.onLoadMore!();
                  }
                }
              : null,
        ),
      ],
    );
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

  /// 获取指定期间的收益率
  double _getReturnForPeriod(FundRanking ranking) {
    switch (_selectedPeriod) {
      case '近1周':
        return ranking.return1W;
      case '近1月':
        return ranking.return1M;
      case '近3月':
        return ranking.return3M;
      case '近6月':
        return ranking.return6M; // 优先使用真实数据，降级使用估算
      case '近1年':
        return ranking.return1Y;
      case '今年来':
        return ranking.returnYTD;
      case '成立来':
        return ranking.returnSinceInception;
      default:
        return ranking.return1Y;
    }
  }

  TextStyle get _headerTextStyle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      );
}
