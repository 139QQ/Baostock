import 'package:equatable/equatable.dart';
import '../../domain/entities/fund_filter_criteria.dart';

/// 筛选事件基类
abstract class FilterEvent extends Equatable {
  const FilterEvent();

  @override
  List<Object> get props => [];
}

/// 加载筛选选项事件
class LoadFilterOptions extends FilterEvent {
  const LoadFilterOptions();
}

/// 更新筛选条件事件
class UpdateFilterCriteria extends FilterEvent {
  final List<String>? fundTypes;
  final List<String>? companies;
  final RangeValue? scaleRange;
  final DateRange? establishmentDateRange;
  final List<String>? riskLevels;
  final RangeValue? returnRange;
  final List<String>? statuses;

  const UpdateFilterCriteria({
    this.fundTypes,
    this.companies,
    this.scaleRange,
    this.establishmentDateRange,
    this.riskLevels,
    this.returnRange,
    this.statuses,
  });

  @override
  List<Object> get props => [
        fundTypes ?? [],
        companies ?? [],
        scaleRange ?? '',
        establishmentDateRange ?? '',
        riskLevels ?? [],
        returnRange ?? '',
        statuses ?? [],
      ];
}

/// 应用筛选事件
class ApplyFilter extends FilterEvent {
  final FundFilterCriteria criteria;

  const ApplyFilter({required this.criteria});

  @override
  List<Object> get props => [criteria];
}

/// 重置筛选条件事件
class ResetFilter extends FilterEvent {
  const ResetFilter();
}

/// 重置特定类型筛选条件事件
class ResetFilterType extends FilterEvent {
  final FilterType type;

  const ResetFilterType({required this.type});

  @override
  List<Object> get props => [type];
}

/// 加载更多结果事件
class LoadMoreResults extends FilterEvent {
  const LoadMoreResults();
}

/// 更改排序选项事件
class ChangeSortOption extends FilterEvent {
  final String sortBy;
  final SortDirection sortDirection;

  const ChangeSortOption({
    required this.sortBy,
    required this.sortDirection,
  });

  @override
  List<Object> get props => [sortBy, sortDirection];
}

/// 应用预设筛选条件事件
class ApplyPresetFilter extends FilterEvent {
  final String presetName;

  const ApplyPresetFilter({required this.presetName});

  @override
  List<Object> get props => [presetName];
}

/// 保存筛选预设事件
class SaveFilterPreset extends FilterEvent {
  final String presetName;

  const SaveFilterPreset({required this.presetName});

  @override
  List<Object> get props => [presetName];
}

/// 加载筛选统计信息事件
class LoadFilterStatistics extends FilterEvent {
  const LoadFilterStatistics();
}

/// 快速筛选事件（单条件筛选）
class QuickFilter extends FilterEvent {
  final FilterType type;
  final String value;

  const QuickFilter({
    required this.type,
    required this.value,
  });

  @override
  List<Object> get props => [type, value];
}

/// 清除所有筛选事件
class ClearAllFilters extends FilterEvent {
  const ClearAllFilters();
}

/// 切换筛选条件事件（用于开关式筛选）
class ToggleFilterOption extends FilterEvent {
  final FilterType type;
  final String value;

  const ToggleFilterOption({
    required this.type,
    required this.value,
  });

  @override
  List<Object> get props => [type, value];
}
