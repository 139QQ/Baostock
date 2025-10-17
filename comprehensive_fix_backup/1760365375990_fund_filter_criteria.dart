import 'package:equatable/equatable.dart';

/// 基金筛选条件实体类
///
/// 用于存储和管理基金筛选的各种条件，支持多维度筛选和组合逻辑。
/// 所有筛选条件都是可选的，未设置的筛选条件将不会被应用。
///
/// 时间复杂度: O(1) 对于条件设置
/// 空间复杂度: O(n) 其中n是筛选条件数量
class FundFilterCriteria extends Equatable {
  /// 基金类型筛选条件
  final List<String>? fundTypes;

  /// 管理公司筛选条件
  final List<String>? companies;

  /// 基金规模范围筛选条件（单位：亿元）
  final RangeValue? scaleRange;

  /// 成立时间范围筛选条件
  final DateRange? establishmentDateRange;

  /// 风险等级筛选条件
  final List<String>? riskLevels;

  /// 收益率范围筛选条件（年化收益率）
  final RangeValue? returnRange;

  /// 基金状态筛选条件
  final List<String>? statuses;

  /// 排序字段
  final String? sortBy;

  /// 排序方向
  final SortDirection? sortDirection;

  /// 页码
  final int page;

  /// 每页数量
  final int pageSize;

  /// 基金筛选条件构造函数
  ///
  /// 所有参数都是可选的，默认值不会限制筛选结果
  const FundFilterCriteria({
    this.fundTypes,
    this.companies,
    this.scaleRange,
    this.establishmentDateRange,
    this.riskLevels,
    this.returnRange,
    this.statuses,
    this.sortBy,
    this.sortDirection,
    this.page = 1,
    this.pageSize = 20,
  });

  /// 创建空的筛选条件（返回所有基金）
  factory FundFilterCriteria.empty() {
    return const FundFilterCriteria();
  }

  /// 复制当前筛选条件并更新指定字段
  FundFilterCriteria copyWith({
    List<String>? fundTypes,
    List<String>? companies,
    RangeValue? scaleRange,
    DateRange? establishmentDateRange,
    List<String>? riskLevels,
    RangeValue? returnRange,
    List<String>? statuses,
    String? sortBy,
    SortDirection? sortDirection,
    int? page,
    int? pageSize,
    bool clearFundTypes = false,
    bool clearCompanies = false,
    bool clearScaleRange = false,
    bool clearEstablishmentDateRange = false,
    bool clearRiskLevels = false,
    bool clearReturnRange = false,
    bool clearStatuses = false,
    bool clearSortBy = false,
    bool clearSortDirection = false,
  }) {
    return FundFilterCriteria(
      fundTypes: clearFundTypes ? null : (fundTypes ?? this.fundTypes),
      companies: clearCompanies ? null : (companies ?? this.companies),
      scaleRange: clearScaleRange ? null : (scaleRange ?? this.scaleRange),
      establishmentDateRange: clearEstablishmentDateRange
          ? null
          : (establishmentDateRange ?? this.establishmentDateRange),
      riskLevels: clearRiskLevels ? null : (riskLevels ?? this.riskLevels),
      returnRange: clearReturnRange ? null : (returnRange ?? this.returnRange),
      statuses: clearStatuses ? null : (statuses ?? this.statuses),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortDirection:
          clearSortDirection ? null : (sortDirection ?? this.sortDirection),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// 检查是否有任何筛选条件被设置
  bool get hasAnyFilter {
    return fundTypes?.isNotEmpty == true ||
        companies?.isNotEmpty == true ||
        scaleRange != null ||
        establishmentDateRange != null ||
        riskLevels?.isNotEmpty == true ||
        returnRange != null ||
        statuses?.isNotEmpty == true;
  }

  /// 检查特定筛选类型是否被设置
  bool hasFilterType(FilterType type) {
    switch (type) {
      case FilterType.fundType:
        return fundTypes?.isNotEmpty == true;
      case FilterType.company:
        return companies?.isNotEmpty == true;
      case FilterType.scale:
        return scaleRange != null;
      case FilterType.establishmentDate:
        return establishmentDateRange != null;
      case FilterType.riskLevel:
        return riskLevels?.isNotEmpty == true;
      case FilterType.returnRate:
        return returnRange != null;
      case FilterType.status:
        return statuses?.isNotEmpty == true;
    }
  }

  /// 重置所有筛选条件
  FundFilterCriteria reset() {
    return FundFilterCriteria.empty();
  }

  /// 重置特定类型的筛选条件
  FundFilterCriteria resetFilterType(FilterType type) {
    switch (type) {
      case FilterType.fundType:
        return copyWith(clearFundTypes: true);
      case FilterType.company:
        return copyWith(clearCompanies: true);
      case FilterType.scale:
        return copyWith(clearScaleRange: true);
      case FilterType.establishmentDate:
        return copyWith(clearEstablishmentDateRange: true);
      case FilterType.riskLevel:
        return copyWith(clearRiskLevels: true);
      case FilterType.returnRate:
        return copyWith(clearReturnRange: true);
      case FilterType.status:
        return copyWith(clearStatuses: true);
    }
  }

  /// 序列化为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'fundTypes': fundTypes,
      'companies': companies,
      'scaleRange': scaleRange?.toJson(),
      'establishmentDateRange': establishmentDateRange?.toJson(),
      'riskLevels': riskLevels,
      'returnRange': returnRange?.toJson(),
      'statuses': statuses,
      'sortBy': sortBy,
      'sortDirection': sortDirection?.name,
      'page': page,
      'pageSize': pageSize,
    };
  }

  /// 从JSON格式创建筛选条件
  factory FundFilterCriteria.fromJson(Map<String, dynamic> json) {
    return FundFilterCriteria(
      fundTypes: (json['fundTypes'] as List<dynamic>?)?.cast<String>(),
      companies: (json['companies'] as List<dynamic>?)?.cast<String>(),
      scaleRange: json['scaleRange'] != null
          ? RangeValue.fromJson(json['scaleRange'])
          : null,
      establishmentDateRange: json['establishmentDateRange'] != null
          ? DateRange.fromJson(json['establishmentDateRange'])
          : null,
      riskLevels: (json['riskLevels'] as List<dynamic>?)?.cast<String>(),
      returnRange: json['returnRange'] != null
          ? RangeValue.fromJson(json['returnRange'])
          : null,
      statuses: (json['statuses'] as List<dynamic>?)?.cast<String>(),
      sortBy: json['sortBy'] as String?,
      sortDirection: json['sortDirection'] != null
          ? SortDirection.values.firstWhere(
              (e) => e.name == json['sortDirection'],
              orElse: () => SortDirection.asc,
            )
          : null,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  @override
  List<Object?> get props => [
        fundTypes,
        companies,
        scaleRange,
        establishmentDateRange,
        riskLevels,
        returnRange,
        statuses,
        sortBy,
        sortDirection,
        page,
        pageSize,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundFilterCriteria &&
          runtimeType == other.runtimeType &&
          _listEquals(fundTypes, other.fundTypes) &&
          _listEquals(companies, other.companies) &&
          scaleRange == other.scaleRange &&
          establishmentDateRange == other.establishmentDateRange &&
          _listEquals(riskLevels, other.riskLevels) &&
          returnRange == other.returnRange &&
          _listEquals(statuses, other.statuses) &&
          sortBy == other.sortBy &&
          sortDirection == other.sortDirection &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hashAll([
        _listHash(fundTypes),
        _listHash(companies),
        scaleRange,
        establishmentDateRange,
        _listHash(riskLevels),
        returnRange,
        _listHash(statuses),
        sortBy,
        sortDirection,
        page,
        pageSize,
      ]);

  /// 辅助方法：比较两个列表是否相等
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 辅助方法：计算列表的哈希值
  int _listHash<T>(List<T>? list) {
    if (list == null) return 0;
    int hash = 0;
    for (final item in list) {
      hash = hash * 31 + item.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    final filters = <String>[];

    if (fundTypes?.isNotEmpty == true) {
      filters.add('类型: ${fundTypes!.join(', ')}');
    }
    if (companies?.isNotEmpty == true) {
      filters.add('公司: ${companies!.join(', ')}');
    }
    if (scaleRange != null) {
      filters.add('规模: ${scaleRange!.min}-${scaleRange!.max}亿');
    }
    if (establishmentDateRange != null) {
      filters.add(
          '成立时间: ${establishmentDateRange!.start}-${establishmentDateRange!.end}');
    }
    if (riskLevels?.isNotEmpty == true) {
      filters.add('风险: ${riskLevels!.join(', ')}');
    }
    if (returnRange != null) {
      filters.add('收益: ${returnRange!.min}-${returnRange!.max}%');
    }
    if (statuses?.isNotEmpty == true) {
      filters.add('状态: ${statuses!.join(', ')}');
    }

    return filters.isEmpty ? '无筛选条件' : filters.join(' | ');
  }
}

/// 范围值（用于数值范围筛选）
class RangeValue extends Equatable {
  final double min;
  final double max;

  const RangeValue({
    required this.min,
    required this.max,
  }) : assert(min <= max, '最小值不能大于最大值');

  @override
  List<Object?> get props => [min, max];

  /// 检查数值是否在范围内
  bool contains(double value) {
    return value >= min && value <= max;
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }

  /// 从JSON创建范围值
  factory RangeValue.fromJson(Map<String, dynamic> json) {
    return RangeValue(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeValue &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => '$min-$max';
}

/// 日期范围（用于日期范围筛选）
class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  DateRange({
    required this.start,
    required this.end,
  }) : assert(
            start.isBefore(end) || start.isAtSameMomentAs(end), '开始日期不能晚于结束日期');

  @override
  List<Object?> get props => [start, end];

  /// 检查日期是否在范围内
  bool contains(DateTime date) {
    return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
        (date.isAtSameMomentAs(end) || date.isBefore(end));
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  /// 从JSON创建日期范围
  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() =>
      '${start.toLocal().toString().split(' ')[0]} - ${end.toLocal().toString().split(' ')[0]}';
}

/// 筛选类型枚举
enum FilterType {
  /// 基金类型筛选
  fundType('基金类型'),

  /// 管理公司筛选
  company('管理公司'),

  /// 基金规模筛选
  scale('基金规模'),

  /// 成立时间筛选
  establishmentDate('成立时间'),

  /// 风险等级筛选
  riskLevel('风险等级'),

  /// 收益率筛选
  returnRate('收益率'),

  /// 基金状态筛选
  status('基金状态');

  const FilterType(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

/// 排序方向枚举
enum SortDirection {
  /// 升序
  asc('升序'),

  /// 降序
  desc('降序');

  const SortDirection(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}
