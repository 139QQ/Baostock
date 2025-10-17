# Epic 3: 核心功能模块

## 史诗概述
开发基金分析应用的核心业务功能模块，包括基金排行榜、基金筛选搜索、基金详情展示和数据可视化功能。这些功能是应用的核心价值所在，为用户提供专业的基金分析工具。

## 史诗目标
- 构建功能完整的基金排行榜系统，支持多维度排序和筛选
- 实现智能基金搜索功能，支持模糊搜索和高级筛选
- 开发详细的基金信息展示页面，提供全面的基金数据分析
- 构建丰富的数据可视化组件，直观展示基金业绩和趋势
- 确保所有功能在不同平台的一致性和良好的用户体验

## 功能范围

### 1. 基金排行榜功能
**功能需求:**
- 支持多种基金类型排行（股票型、混合型、债券型、货币型等）
- 提供多时间段收益排行（近1周、1月、3月、6月、1年、3年等）
- 实现分页加载和虚拟滚动，支持大数据量展示
- 支持自定义排序和筛选条件

**技术实现:**
```dart
// 基金排行页面
class FundRankingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FundRankingBloc(
        getFundRankings: context.read<GetFundRankings>(),
        cacheService: context.read<CacheService>(),
      ),
      child: FundRankingView(),
    );
  }
}

// 排行数据展示组件
class FundRankingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('基金排行'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          // 排序按钮
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类选择器
          CategorySelector(),
          // 时间段选择器
          PeriodSelector(),
          // 排行列表
          Expanded(child: FundRankingList()),
        ],
      ),
    );
  }
}

// 排行列表组件
class FundRankingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundRankingBloc, FundRankingState>(
      builder: (context, state) {
        switch (state.status) {
          case LoadStatus.loading:
            return Center(child: CircularProgressIndicator());

          case LoadStatus.success:
            return RefreshIndicator(
              onRefresh: () => _refreshData(context),
              child: ListView.builder(
                itemCount: state.rankings.length,
                itemBuilder: (context, index) {
                  final ranking = state.rankings[index];
                  return FundRankingCard(
                    ranking: ranking,
                    index: index + 1,
                  );
                },
              ),
            );

          case LoadStatus.error:
            return ErrorWidget(
              message: state.error ?? '加载失败',
              onRetry: () => _loadData(context),
            );

          default:
            return SizedBox.shrink();
        }
      },
    );
  }
}
```

**排行卡片组件:**
```dart
class FundRankingCard extends StatelessWidget {
  final FundRanking ranking;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDetail(context, ranking.fundCode),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 排行和基金信息
              Row(
                children: [
                  // 排行位置
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankingColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),

                  // 基金信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranking.fundName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${ranking.fundCode} · ${ranking.companyName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // 收益信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 收益金额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ranking.returnRate.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getReturnColor(ranking.returnRate),
                        ),
                      ),
                      Text(
                        '${state.currentPeriod}收益',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),

                  // 排行变化
                  if (ranking.previousPosition != null) ...[
                    Icon(
                      _getRankingChangeIcon(ranking.positionChange),
                      color: _getReturnColor(ranking.positionChange),
                      size: 16,
                    ),
                    Text(
                      '${ranking.positionChange.abs()}',
                      style: TextStyle(
                        color: _getReturnColor(ranking.positionChange),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. 基金筛选搜索
**搜索功能设计:**
```dart
// 搜索页面
class FundSearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FundSearchBloc(
        searchFunds: context.read<SearchFunds>(),
      ),
      child: FundSearchView(),
    );
  }
}

// 搜索视图
class FundSearchView extends StatefulWidget {
  @override
  _FundSearchViewState createState() => _FundSearchViewState();
}

class _FundSearchViewState extends State<FundSearchView> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '搜索基金名称、代码、公司',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              prefixIcon: Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        context.read<FundSearchBloc>().add(ClearSearch());
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              context.read<FundSearchBloc>().add(SearchQueryChanged(value));
            },
            onSubmitted: (value) {
              context.read<FundSearchBloc>().add(ExecuteSearch(value));
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showAdvancedFilter(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 热门搜索标签
          _buildHotSearchTags(context),

          // 搜索历史
          _buildSearchHistory(context),

          // 搜索结果
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }
}
```

**高级筛选功能:**
```dart
// 高级筛选对话框
class AdvancedFilterDialog extends StatefulWidget {
  @override
  _AdvancedFilterDialogState createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<AdvancedFilterDialog> {
  String? _selectedFundType;
  String? _selectedCompany;
  double? _minScale;
  double? _maxScale;
  double? _minReturn;
  double? _maxReturn;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('高级筛选'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基金类型
            Text('基金类型', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['股票型', '混合型', '债券型', '货币型', 'QDII']
                  .map((type) => FilterChip(
                        label: Text(type),
                        selected: _selectedFundType == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFundType = selected ? type : null;
                          });
                        },
                      ))
                  .toList(),
            ),

            SizedBox(height: 16),

            // 基金规模
            Text('基金规模', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '最小规模(亿)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _minScale = double.tryParse(value),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '最大规模(亿)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _maxScale = double.tryParse(value),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // 收益率
            Text('收益率', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '最小收益率(%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _minReturn = double.tryParse(value),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '最大收益率(%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _maxReturn = double.tryParse(value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final filters = FundFilters(
              fundType: _selectedFundType,
              company: _selectedCompany,
              minScale: _minScale,
              maxScale: _maxScale,
              minReturn: _minReturn,
              maxReturn: _maxReturn,
            );
            Navigator.pop(context, filters);
          },
          child: Text('确定'),
        ),
      ],
    );
  }
}
```

### 3. 基金详情展示
**详情页面架构:**
```dart
// 基金详情页面
class FundDetailsPage extends StatelessWidget {
  final String fundCode;

  const FundDetailsPage({required this.fundCode});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FundDetailsBloc(
        getFundDetail: context.read<GetFundDetail>(),
        getFundNavHistory: context.read<GetFundNavHistory>(),
      )..add(LoadFundDetails(fundCode)),
      child: FundDetailsView(),
    );
  }
}

// 详情页面视图
class FundDetailsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FundDetailsBloc, FundDetailsState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.loading:
              return Center(child: CircularProgressIndicator());

            case LoadStatus.success:
              return CustomScrollView(
                slivers: [
                  // 顶部信息卡片
                  SliverToBoxAdapter(
                    child: FundInfoCard(fund: state.fund!),
                  ),

                  // 收益表现
                  SliverToBoxAdapter(
                    child: PerformanceSection(performance: state.performance!),
                  ),

                  // 净值走势图表
                  SliverToBoxAdapter(
                    child: NavChart(navHistory: state.navHistory!),
                  ),

                  // 持仓信息
                  SliverToBoxAdapter(
                    child: HoldingsSection(holdings: state.holdings!),
                  ),

                  // 基金经理信息
                  SliverToBoxAdapter(
                    child: ManagerSection(manager: state.manager!),
                  ),

                  // 相关公告
                  SliverToBoxAdapter(
                    child: AnnouncementsSection(announcements: state.announcements!),
                  ),
                ],
              );

            case LoadStatus.error:
              return ErrorWidget(
                message: state.error ?? '加载失败',
                onRetry: () => context.read<FundDetailsBloc>().add(LoadFundDetails(state.fundCode)),
              );

            default:
              return SizedBox.shrink();
          }
        },
      ),
    );
  }
}
```

**基金信息卡片:**
```dart
class FundInfoCard extends StatelessWidget {
  final FundDetail fund;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基金名称和代码
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fund.fundName,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        fund.fundCode,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // 关注按钮
                IconButton(
                  icon: Icon(
                    fund.isWatched ? Icons.star : Icons.star_border,
                    color: fund.isWatched ? Colors.amber : null,
                  ),
                  onPressed: () => _toggleWatchStatus(context, fund.fundCode),
                ),
              ],
            ),

            SizedBox(height: 16),

            // 基本信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('类型', fund.fundType),
                _buildInfoItem('规模', '${fund.scale?.toStringAsFixed(1) ?? '--'}亿'),
                _buildInfoItem('成立日期', fund.establishmentDate?.format('yyyy-MM-dd') ?? '--'),
              ],
            ),

            SizedBox(height: 16),

            // 最新净值
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('单位净值', style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: 4),
                      Text(
                        fund.currentNav?.toStringAsFixed(4) ?? '--',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('日涨跌', style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: 4),
                      Text(
                        '${fund.dailyReturn?.toStringAsFixed(2) ?? '--'}%',
                        style: TextStyle(
                          color: _getReturnColor(fund.dailyReturn),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. 数据可视化
**图表组件设计:**
```dart
// 净值走势图表
class NavChart extends StatelessWidget {
  final List<FundNav> navHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('净值走势', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),

            // 时间段选择器
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['1月', '3月', '6月', '1年', '3年', '成立来']
                    .map((period) => Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(period),
                            selected: _selectedPeriod == period,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedPeriod = period);
                                _loadNavData(period);
                              }
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),

            SizedBox(height: 16),

            // 图表
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _convertToSpots(navHistory),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 收益对比图表
class PerformanceChart extends StatelessWidget {
  final Map<String, double> performance;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收益表现', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['近1月', '近3月', '近6月', '近1年', '近3年'];
                          return Text(titles[value.toInt()]);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: performance.entries.map((entry) {
                    return BarChartGroupData(
                      x: performance.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: _getReturnColor(entry.value),
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 验收标准

### 功能验收
- [ ] 基金排行榜支持所有基金类型和时间段
- [ ] 搜索功能支持模糊搜索、代码搜索、公司搜索
- [ ] 高级筛选支持多条件组合筛选
- [ ] 基金详情页展示完整的基金信息
- [ ] 数据可视化图表支持缩放、滑动等交互
- [ ] 所有功能支持分页加载和虚拟滚动

### 性能验收
- [ ] 排行数据加载时间 < 1秒
- [ ] 搜索结果响应时间 < 500ms
- [ ] 详情页面加载时间 < 2秒
- [ ] 图表渲染时间 < 300ms
- [ ] 支持1000+基金数据的流畅展示

### 用户体验验收
- [ ] 界面响应流畅，无卡顿现象
- [ ] 支持上拉加载更多数据
- [ ] 支持下拉刷新功能
- [ ] 错误处理友好，提供重试机制
- [ ] 空状态展示友好

## 开发时间估算

### 工作量评估
- **基金排行榜功能**: 40小时
- **基金筛选搜索**: 32小时
- **基金详情展示**: 48小时
- **数据可视化**: 40小时
- **交互优化**: 24小时
- **测试和调试**: 24小时

**总计: 208小时（约26个工作日）**

## 依赖关系

### 前置依赖
- Epic 1: 基础架构搭建完成
- Epic 2: 数据层架构完成
- UI设计稿确认

### 后续影响
- 为用户提供核心功能体验
- 决定应用的主要价值输出
- 影响用户留存和活跃度

## 风险评估

### 技术风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 大数据量性能问题 | 高 | 高 | 实现虚拟滚动和分页加载 |
| 图表库兼容性问题 | 中 | 中 | 充分测试，准备备选方案 |
| 搜索算法优化 | 中 | 中 | 使用成熟的搜索算法 |

### 用户体验风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 界面复杂度过高 | 中 | 中 | 简化界面，分步骤展示 |
| 数据加载等待时间长 | 中 | 高 | 实现骨架屏和渐进式加载 |

## 资源需求

### 人员配置
- **Flutter开发工程师**: 3人
- **UI/UX设计师**: 1人（兼职）
- **数据可视化专家**: 1人（兼职）
- **测试工程师**: 1人（兼职）

### 技术资源
- 图表库和设计工具
- 性能测试工具
- 多平台测试设备
- 设计素材和图标库

## 交付物

### 代码交付
- 完整的基金排行榜功能代码
- 搜索和筛选功能实现
- 基金详情页面代码
- 数据可视化组件库

### 文档交付
- 功能使用说明文档
- API接口文档
- 组件库使用指南
- 性能优化最佳实践

### 测试交付
- 功能测试用例和报告
- 性能测试报告
- 兼容性测试报告
- 用户体验测试报告

---

**史诗负责人:** 产品经理
**预计开始时间:** 2025-11-06
**预计完成时间:** 2025-12-15
**优先级:** P0（最高）
**状态:** 待开始
**依赖史诗:** Epic 1, Epic 2