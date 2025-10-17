import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/fund_filter_criteria.dart';
import '../bloc/filter_bloc.dart';
import '../bloc/filter_event.dart';
import '../bloc/filter_state.dart';
import 'filter_chip.dart';
import 'range_slider_filter.dart';
import 'search_bar_filter.dart';
import 'filter_loading_indicator.dart';

/// 基金筛选面板组件
///
/// 集成所有筛选功能的主面板组件，使用BLoC状态管理。
/// 提供基金类型、公司、规模、时间等多维度筛选功能。
class FilterPanel extends StatefulWidget {
  /// 是否显示高级选项
  final bool showAdvancedOptions;

  /// 面板展开状态回调
  final ValueChanged<bool>? onPanelExpanded;

  /// 自定义筛选器配置
  final FilterPanelConfig? config;

  const FilterPanel({
    super.key,
    this.showAdvancedOptions = true,
    this.onPanelExpanded,
    this.config,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isExpanded = true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onPanelExpanded?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, state) {
        return FilterLoadingIndicator(
          isLoading: state.isLoading,
          isFromCache: state.fromCache,
          loadingText:
              state.status == FilterStatus.loadingMore ? '加载更多...' : '筛选中...',
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 面板头部
                _buildPanelHeader(state),

                // 展开时显示内容
                if (_isExpanded) ...[
                  const Divider(height: 1),
                  _buildPanelContent(state),
                ],

                // 错误指示器
                if (state.hasError) _buildErrorIndicator(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelHeader(FilterState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: colors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '基金筛选',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    if (state.hasActiveFilters) ...[
                      const SizedBox(height: 4),
                      Text(
                        state.filterDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 筛选结果统计
              if (state.hasResult)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${state.currentResultCount}/${state.totalResultCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // 展开/收起按钮
              IconButton(
                onPressed: _toggleExpanded,
                icon: AnimatedIcon(
                  icon: AnimatedIcons.close_menu,
                  progress: AlwaysStoppedAnimation(_isExpanded ? 1.0 : 0.0),
                  color: colors.onSurface,
                ),
                tooltip: _isExpanded ? '收起筛选' : '展开筛选',
              ),
            ],
          ),

          // 已选筛选条件标签
          if (state.hasActiveFilters) ...[
            const SizedBox(height: 12),
            _buildSelectedFilters(state),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorIndicator(FilterState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                '筛选出错',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.error ?? '未知错误',
            style: TextStyle(color: Colors.red[600]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _retryFilter(context),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilters(FilterState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 基金类型标签
        if (state.criteria.fundTypes?.isNotEmpty == true)
          ...state.criteria.fundTypes!.map(
            (type) => FundFilterChip.selectedTag(
              label: '类型: $type',
              onDelete: () => _resetFilterType(FilterType.fundType),
              color: FundFilterChipColors.stockType,
            ),
          ),

        // 管理公司标签
        if (state.criteria.companies?.isNotEmpty == true)
          ...state.criteria.companies!.map(
            (company) => FundFilterChip.selectedTag(
              label: '公司: $company',
              onDelete: () => _resetFilterType(FilterType.company),
              color: Colors.blue,
            ),
          ),

        // 基金规模标签
        if (state.criteria.scaleRange != null)
          FundFilterChip.selectedTag(
            label:
                '规模: ${state.criteria.scaleRange!.min.toInt()}-${state.criteria.scaleRange!.max.toInt()}亿',
            onDelete: () => _resetFilterType(FilterType.scale),
            color: Colors.green,
          ),

        // 成立时间标签
        if (state.criteria.establishmentDateRange != null)
          FundFilterChip.selectedTag(
            label:
                '成立: ${state.criteria.establishmentDateRange!.start.year}-${state.criteria.establishmentDateRange!.end.year}',
            onDelete: () => _resetFilterType(FilterType.establishmentDate),
            color: Colors.orange,
          ),

        // 风险等级标签
        if (state.criteria.riskLevels?.isNotEmpty == true)
          ...state.criteria.riskLevels!.map(
            (level) => FundFilterChip.selectedTag(
              label: '风险: $level',
              onDelete: () => _resetFilterType(FilterType.riskLevel),
              color: Colors.red,
            ),
          ),

        // 收益率标签
        if (state.criteria.returnRange != null)
          FundFilterChip.selectedTag(
            label:
                '收益: ${state.criteria.returnRange!.min.toStringAsFixed(1)}-${state.criteria.returnRange!.max.toStringAsFixed(1)}%',
            onDelete: () => _resetFilterType(FilterType.returnRate),
            color: Colors.purple,
          ),
      ],
    );
  }

  Widget _buildPanelContent(FilterState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索栏
          SearchBarFilter(
            searchText: '', // 从状态中获取搜索文本
            placeholder: '搜索基金代码、名称或公司',
            onSearch: (text) {
              // 触发搜索
              context.read<FilterBloc>().add(
                    const UpdateFilterCriteria(
                        // 这里需要根据实际的搜索字段来更新
                        ),
                  );
            },
            quickFilters: [
              QuickFilterOption(
                label: '热门基金',
                value: '热门',
                icon: Icons.local_fire_department,
              ),
              QuickFilterOption(
                label: '新发基金',
                value: '新发',
                icon: Icons.new_releases,
              ),
              QuickFilterOption(
                label: '高分红',
                value: '高分红',
                icon: Icons.trending_up,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 标签页
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '基础筛选'),
              Tab(text: '高级筛选'),
              Tab(text: '排序设置'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 16),

          // 标签页内容
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicFilters(state),
                _buildAdvancedFilters(state),
                _buildSortOptions(state),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 操作按钮
          _buildActionButtons(state),
        ],
      ),
    );
  }

  Widget _buildBasicFilters(FilterState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基金类型筛选
          _buildFilterSection(
            title: '基金类型',
            child: _buildFundTypeSelector(state),
          ),

          const SizedBox(height: 24),

          // 风险等级筛选
          _buildFilterSection(
            title: '风险等级',
            child: _buildRiskLevelSelector(state),
          ),

          const SizedBox(height: 24),

          // 基金规模筛选
          _buildFilterSection(
            title: '基金规模',
            child: RangeSliderFilter.fundScale(
              value: state.criteria.scaleRange,
              onChanged: (range) {
                context.read<FilterBloc>().add(
                      UpdateFilterCriteria(scaleRange: range),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(FilterState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 管理公司筛选
          _buildFilterSection(
            title: '管理公司',
            child: _buildCompanySelector(state),
          ),

          const SizedBox(height: 24),

          // 成立时间筛选
          _buildFilterSection(
            title: '成立时间',
            child: _buildDateRangeSelector(state),
          ),

          const SizedBox(height: 24),

          // 收益率筛选
          _buildFilterSection(
            title: '年化收益率',
            child: RangeSliderFilter.returnRate(
              value: state.criteria.returnRange,
              onChanged: (range) {
                context.read<FilterBloc>().add(
                      UpdateFilterCriteria(returnRange: range),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions(FilterState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection(
            title: '排序字段',
            child: _buildSortBySelector(state),
          ),
          const SizedBox(height: 24),
          _buildFilterSection(
            title: '排序方向',
            child: _buildSortDirectionSelector(state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFundTypeSelector(FilterState state) {
    final fundTypes = [
      '股票型',
      '债券型',
      '混合型',
      '货币型',
      '指数型',
      'QDII',
      'FOF',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fundTypes.map((type) {
        final isSelected = state.criteria.fundTypes?.contains(type) ?? false;
        return FundFilterChip.fundType(
          fundType: type,
          selected: isSelected,
          onSelected: (selected) {
            final currentTypes =
                List<String>.from(state.criteria.fundTypes ?? []);
            if (selected) {
              currentTypes.add(type);
            } else {
              currentTypes.remove(type);
            }
            context.read<FilterBloc>().add(
                  UpdateFilterCriteria(fundTypes: currentTypes),
                );
          },
          color: _getFundTypeColor(type),
        );
      }).toList(),
    );
  }

  Widget _buildRiskLevelSelector(FilterState state) {
    final riskLevels = [
      {'level': 'R1', 'name': '低风险', 'color': FundFilterChipColors.riskLevel1},
      {'level': 'R2', 'name': '中低风险', 'color': FundFilterChipColors.riskLevel2},
      {'level': 'R3', 'name': '中等风险', 'color': FundFilterChipColors.riskLevel3},
      {'level': 'R4', 'name': '中高风险', 'color': FundFilterChipColors.riskLevel4},
      {'level': 'R5', 'name': '高风险', 'color': FundFilterChipColors.riskLevel5},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: riskLevels.map((risk) {
        final level = risk['level'] as String;
        final name = risk['name'] as String;
        final color = risk['color'] as Color;
        final isSelected = state.criteria.riskLevels?.contains(level) ?? false;

        return FundFilterChip.riskLevel(
          level: level,
          name: name,
          selected: isSelected,
          onSelected: (selected) {
            final currentLevels =
                List<String>.from(state.criteria.riskLevels ?? []);
            if (selected) {
              currentLevels.add(level);
            } else {
              currentLevels.remove(level);
            }
            context.read<FilterBloc>().add(
                  UpdateFilterCriteria(riskLevels: currentLevels),
                );
          },
          color: color,
        );
      }).toList(),
    );
  }

  Widget _buildCompanySelector(FilterState state) {
    // 这里应该从API获取实际的基金公司列表
    final companies = [
      '易方达基金',
      '华夏基金',
      '嘉实基金',
      '南方基金',
      '博时基金',
      '广发基金',
      '汇添富基金',
      '富国基金',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: companies.map((company) {
        final isSelected = state.criteria.companies?.contains(company) ?? false;
        return FundFilterChip.company(
          companyName: company,
          selected: isSelected,
          onSelected: (selected) {
            final currentCompanies =
                List<String>.from(state.criteria.companies ?? []);
            if (selected) {
              currentCompanies.add(company);
            } else {
              currentCompanies.remove(company);
            }
            context.read<FilterBloc>().add(
                  UpdateFilterCriteria(companies: currentCompanies),
                );
          },
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector(FilterState state) {
    final dateRange = state.criteria.establishmentDateRange;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            label: '开始日期',
            date: dateRange?.start,
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: dateRange?.start ??
                    DateTime.now().subtract(const Duration(days: 365 * 5)),
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                final newRange = DateRange(
                  start: selectedDate,
                  end: dateRange?.end ?? DateTime.now(),
                );
                context.read<FilterBloc>().add(
                      UpdateFilterCriteria(establishmentDateRange: newRange),
                    );
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateField(
            label: '结束日期',
            date: dateRange?.end,
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: dateRange?.end ?? DateTime.now(),
                firstDate: DateTime(1990),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                final newRange = DateRange(
                  start: dateRange?.start ?? DateTime(1990),
                  end: selectedDate,
                );
                context.read<FilterBloc>().add(
                      UpdateFilterCriteria(establishmentDateRange: newRange),
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: colors.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  color: date != null
                      ? colors.onSurface
                      : colors.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBySelector(FilterState state) {
    final sortOptions = [
      {'value': 'name', 'label': '基金名称'},
      {'value': 'code', 'label': '基金代码'},
      {'value': 'nav', 'label': '最新净值'},
      {'value': 'return_1y', 'label': '近一年收益'},
      {'value': 'return_3y', 'label': '近三年收益'},
      {'value': 'scale', 'label': '基金规模'},
      {'value': 'establish_date', 'label': '成立时间'},
    ];

    return Column(
      children: sortOptions.map((option) {
        final value = option['value'] as String;
        final label = option['label'] as String;
        final isSelected = state.criteria.sortBy == value;

        return RadioListTile<String>(
          title: Text(label),
          value: value,
          groupValue: state.criteria.sortBy,
          onChanged: (value) {
            if (value != null) {
              context.read<FilterBloc>().add(
                    ChangeSortOption(
                      sortBy: value,
                      sortDirection:
                          state.criteria.sortDirection ?? SortDirection.desc,
                    ),
                  );
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortDirectionSelector(FilterState state) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<SortDirection>(
            title: const Text('降序'),
            value: SortDirection.desc,
            groupValue: state.criteria.sortDirection,
            onChanged: (value) {
              if (value != null) {
                context.read<FilterBloc>().add(
                      ChangeSortOption(
                        sortBy: state.criteria.sortBy ?? 'return_1y',
                        sortDirection: value,
                      ),
                    );
              }
            },
          ),
        ),
        Expanded(
          child: RadioListTile<SortDirection>(
            title: const Text('升序'),
            value: SortDirection.asc,
            groupValue: state.criteria.sortDirection,
            onChanged: (value) {
              if (value != null) {
                context.read<FilterBloc>().add(
                      ChangeSortOption(
                        sortBy: state.criteria.sortBy ?? 'return_1y',
                        sortDirection: value,
                      ),
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(FilterState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        // 重置按钮
        Expanded(
          child: OutlinedButton(
            onPressed: state.hasActiveFilters
                ? () {
                    context.read<FilterBloc>().add(const ResetFilter());
                  }
                : null,
            child: const Text('重置筛选'),
          ),
        ),
        const SizedBox(width: 16),
        // 应用筛选按钮
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () {
                    // 应用筛选逻辑已通过状态管理自动处理
                    Navigator.of(context).pop();
                  },
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 16),
            label: Text(state.isLoading ? '筛选中...' : '应用筛选'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getFundTypeColor(String fundType) {
    switch (fundType) {
      case '股票型':
        return FundFilterChipColors.stockType;
      case '债券型':
        return FundFilterChipColors.bondType;
      case '混合型':
        return FundFilterChipColors.hybridType;
      case '货币型':
        return FundFilterChipColors.moneyType;
      case '指数型':
        return FundFilterChipColors.indexType;
      case 'QDII':
        return FundFilterChipColors.qdiiType;
      case 'FOF':
        return FundFilterChipColors.fofType;
      default:
        return Colors.grey;
    }
  }

  void _resetFilterType(FilterType type) {
    context.read<FilterBloc>().add(ResetFilterType(type: type));
  }

  /// 重试筛选
  void _retryFilter(BuildContext context) {
    final currentCriteria = context.read<FilterBloc>().state.criteria;
    context.read<FilterBloc>().add(ApplyFilter(criteria: currentCriteria));
  }
}

/// 筛选面板配置
class FilterPanelConfig {
  /// 是否显示搜索栏
  final bool showSearch;

  /// 是否显示基础筛选
  final bool showBasicFilters;

  /// 是否显示高级筛选
  final bool showAdvancedFilters;

  /// 是否显示排序选项
  final bool showSortOptions;

  /// 可用的基金类型
  final List<String>? availableFundTypes;

  /// 可用的风险等级
  final List<String>? availableRiskLevels;

  /// 可用的管理公司
  final List<String>? availableCompanies;

  FilterPanelConfig({
    this.showSearch = true,
    this.showBasicFilters = true,
    this.showAdvancedFilters = true,
    this.showSortOptions = true,
    this.availableFundTypes,
    this.availableRiskLevels,
    this.availableCompanies,
  });
}
