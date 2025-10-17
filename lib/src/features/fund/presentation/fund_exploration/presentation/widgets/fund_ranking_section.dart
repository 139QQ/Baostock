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

  FundRanking({
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

  /// 获取排名徽章颜色�?-3名特殊颜色）
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

/// 基金排行榜组�?///
/// 展示不同时间维度的基金业绩排名，支持�?/// - 多时间段切换（近1周、近1月、近3月、近1年、今年来、成立来�?/// - 不同基金类型筛�?/// - 排序方式选择
/// - 排行榜导出功�?/// - 基金详情快速查�?class FundRankingSection extends StatefulWidget {
  final List<FundRanking>? fundRankings;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final String? errorMessage;

  const FundRankingSection({
    super.key,
    this.fundRankings,
    this.isLoading = false,
    this.onLoadMore,
    this.errorMessage,
  });

  @override
  State<FundRankingSection> createState() => _FundRankingSectionState();
}

class _FundRankingSectionState extends State<FundRankingSection> {
  String _selectedPeriod = '�?�?;
  String _selectedFundType = '全部';
  String _sortBy = '收益�?;
  bool _isLoading = false;
  List<FundRanking> _rankings = [];
  List<FundRanking> _filteredRankings = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  final List<String> _periods = ['�?�?, '�?�?, '�?�?, '�?�?, '今年�?, '成立�?];

  final List<String> _fundTypes = [
    '全部',
    '股票�?,
    '债券�?,
    '混合�?,
    '货币�?,
    '指数�?,
    'QDII'
  ];

  final List<String> _sortOptions = ['收益�?, '夏普比率', '基金规模', '风险调整'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.errorMessage != null) {
      debugPrint('�?外部数据加载错误: ${widget.errorMessage}');
      return;
    }

    if (widget.fundRankings != null && widget.fundRankings!.isNotEmpty) {
      debugPrint('�?使用外部传入的真实数据，�?${widget.fundRankings!.length} 条记�?);
      setState(() {
        _rankings = widget.fundRankings!;
        _filteredRankings = widget.fundRankings!;
        _hasMoreData = widget.fundRankings!.length >= _pageSize;
        _currentPage = 1;
      });
      _applyFiltersAndPagination();
    } else if (widget.isLoading) {
      debugPrint('�?外部数据正在加载中，显示加载界面...');
    } else {
      debugPrint('🔄 未提供外部数据，显示空状�?);
      setState(() {
        _rankings = [];
        _filteredRankings = [];
        _hasMoreData = false;
      });
    }
  }

  @override
  void didUpdateWidget(FundRankingSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.fundRankings != oldWidget.fundRankings ||
        widget.errorMessage != oldWidget.errorMessage ||
        widget.isLoading != oldWidget.isLoading) {
      debugPrint('📊 检测到外部数据状态变化，重新初始�?);
      _initializeData();
    }
  }

  void _applyFiltersAndPagination() {
    if (!mounted) return;

    List<FundRanking> filteredList = _rankings;
    if (_selectedFundType != '全部') {
      filteredList = _rankings
          .where((fund) => fund.fundType == _selectedFundType)
          .toList();
    }

    _sortRankingsForList(filteredList);

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

    debugPrint('📄 分页信息 - 当前�? $_currentPage, 每页: $_pageSize, '
        '过滤后总数: ${filteredList.length}, 当前显示: ${_filteredRankings.length}, '
        '是否还有更多: $_hasMoreData');
  }

  void _sortRankingsForList(List<FundRanking> list) {
    switch (_sortBy) {
      case '收益�?:
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
    if (widget.fundRankings != null) {
      debugPrint('�?已有外部真实数据，跳过模拟数据加�?);
      return;
    }

    debugPrint('⚠️ 没有外部数据可用，显示空状�?);
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
        _currentPage = 1;
      });
    }
    _applyFiltersAndPagination();
  }

  void _handleSortChanged(String sortBy) {
    if (mounted) {
      setState(() {
        _sortBy = sortBy;
        _currentPage = 1;
      });
    }
    _applyFiltersAndPagination();
  }

  void _sortRankings() {
    if (mounted) {
      setState(() {
        switch (_sortBy) {
          case '收益�?:
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
            _buildHeaderSection(),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContentWidget(),
            ),
            const SizedBox(height: 16),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '基金排行�?,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (!isCompact) ...[
                  const Spacer(),
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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                _buildPeriodSelector(),
                _buildFundTypeSelector(),
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
              color: isSelected ? const Color(0xFF1E40AF) : Colors.grey.shade600,
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

  String _getRankingDescription() {
    String description = '�?_selectedPeriod收益率排�?;
    if (_selectedFundType != '全部') {
      description += ' · $_selectedFundType';
    }
    if (_sortBy != '收益�?) {
      description += ' · �?_sortBy排序';
    }
    return description;
  }

  Widget _buildRankingTable() {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius only(
                topLeft: const Radius.circular(8),
                topRight: const Radius.circular(8),
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
          const SizedBox(height: 16),
          Text(
            '暂无基金排行数据',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请稍后重试或检查网络连�?,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadRankings();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingRow(FundRanking ranking, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      child: Row(
        children: [
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
                        style: const TextStyle(
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
                const SizedBox(width: 8),
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
          SizedBox(
            width: 80,
            child: Text(
              ranking.fundCode,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
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
          SizedBox(
            width: 60,
            child: Container(
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
                textAlign: TextAlign.center,
              ),
            ),
          ),
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
          SizedBox(
            width: 80,
            child: Text(
              ranking.sharpeRatio.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 16),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已收�?${ranking.fundName}')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
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
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        Container(
          height: 48,
          margin: EdgeInsets only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildSkeletonCell(40),
              _buildSkeletonCell(60),
              _buildSkeletonCell(120),
              _buildSkeletonCell(60),
              _buildSkeletonCell(80),
              _buildSkeletonCell(100),
              _buildSkeletonCell(60),
            ],
          ),
        ),
        ...List.generate(8, (index) {
          return Container(
            height: 56,
            margin: EdgeInsets only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              children: [
                _buildSkeletonCell(40),
                _buildSkeletonCell(60),
                _buildSkeletonCell(120),
                _buildSkeletonCell(60),
                _buildSkeletonCell(80),
                _buildSkeletonCell(100),
                _buildSkeletonCell(60),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
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

  Widget _buildSkeletonCell(double width) {
    return Container(
      width: width,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '正在加载基金排行�?,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E40AF),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '数据源：东方财富�?· 预计时间�?5-20�?,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                const SizedBox(width: 8),
                const Text(
                  '数据量较大，请耐心等待',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.3 + (index * 0.3)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget() {
    if (widget.errorMessage != null) {
      return _buildErrorWidget();
    } else if (widget.isLoading || _isLoading) {
      return _buildLoadingWidget();
    } else {
      return _buildRankingTable();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 24),
          Text(
            '数据加载失败',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ?? '未知错误',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Text(
                  '建议解决方案�?,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '1. 检查网络连接\n2. 稍后重试（API响应较慢）\n3. 联系技术支�?,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onLoadMore != null) {
                widget.onLoadMore!();
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

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

                  if (widget.fundRankings != null) {
                    _applyFiltersAndPagination();
                  } else {
                    _loadRankings();
                  }
                }
              : null,
        ),
        Text(
          '�?$_currentPage �?,
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

                  if (widget.fundRankings != null) {
                    _applyFiltersAndPagination();
                  } else {
                    _loadRankings();
                  }

                  if (widget.onLoadMore != null) {
                    widget.onLoadMore!();
                  }
                }
              : null,
        ),
      ],
    );
  }

  Color _getReturnColor(double returnValue) {
    return returnValue > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981);
  }

  Color _getFundTypeColor(String type) {
    switch (type) {
      case '股票�?:
        return const Color(0xFFEF4444);
      case '债券�?:
        return const Color(0xFF10B981);
      case '混合�?:
        return const Color(0xFFF59E0B);
      case '货币�?:
        return const Color(0xFF3B82F6);
      case '指数�?:
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  double _getReturnForPeriod(FundRanking ranking) {
    switch (_selectedPeriod) {
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
      case '今年�?:
        return ranking.returnYTD;
      case '成立�?:
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
