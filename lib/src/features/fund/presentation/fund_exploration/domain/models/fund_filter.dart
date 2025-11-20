/// 基金筛选条件模型
class FundFilter {
  final List<String> fundTypes;
  final List<String> themes;
  final List<String> riskLevels;
  final double? minScale;
  final double? maxScale;
  final DateTime? establishStart;
  final DateTime? establishEnd;
  final List<String>? companies;
  final List<String>? managers;
  final double? minReturn1Y;
  final double? maxReturn1Y;
  final double? minReturn3Y;
  final double? maxReturn3Y;
  final double? minSharpeRatio;
  final double? maxMaxDrawdown;
  final String? sortBy;
  final bool sortAscending;
  final int? page;
  final int? pageSize;

  FundFilter({
    this.fundTypes = const [],
    this.themes = const [],
    this.riskLevels = const [],
    this.minScale,
    this.maxScale,
    this.establishStart,
    this.establishEnd,
    this.companies,
    this.managers,
    this.minReturn1Y,
    this.maxReturn1Y,
    this.minReturn3Y,
    this.maxReturn3Y,
    this.minSharpeRatio,
    this.maxMaxDrawdown,
    this.sortBy,
    this.sortAscending = false,
    this.page,
    this.pageSize,
  });

  /// 复制构造函数
  FundFilter copyWith({
    List<String>? fundTypes,
    List<String>? themes,
    List<String>? riskLevels,
    double? minScale,
    double? maxScale,
    DateTime? establishStart,
    DateTime? establishEnd,
    List<String>? companies,
    List<String>? managers,
    double? minReturn1Y,
    double? maxReturn1Y,
    double? minReturn3Y,
    double? maxReturn3Y,
    double? minSharpeRatio,
    double? maxMaxDrawdown,
    String? sortBy,
    bool? sortAscending,
    int? page,
    int? pageSize,
  }) {
    return FundFilter(
      fundTypes: fundTypes ?? this.fundTypes,
      themes: themes ?? this.themes,
      riskLevels: riskLevels ?? this.riskLevels,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      establishStart: establishStart ?? this.establishStart,
      establishEnd: establishEnd ?? this.establishEnd,
      companies: companies ?? this.companies,
      managers: managers ?? this.managers,
      minReturn1Y: minReturn1Y ?? this.minReturn1Y,
      maxReturn1Y: maxReturn1Y ?? this.maxReturn1Y,
      minReturn3Y: minReturn3Y ?? this.minReturn3Y,
      maxReturn3Y: maxReturn3Y ?? this.maxReturn3Y,
      minSharpeRatio: minSharpeRatio ?? this.minSharpeRatio,
      maxMaxDrawdown: maxMaxDrawdown ?? this.maxMaxDrawdown,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// 检查是否有筛选条件
  bool get hasActiveFilters {
    return fundTypes.isNotEmpty ||
        themes.isNotEmpty ||
        riskLevels.isNotEmpty ||
        minScale != null ||
        maxScale != null ||
        establishStart != null ||
        establishEnd != null ||
        companies != null && companies!.isNotEmpty ||
        managers != null && managers!.isNotEmpty ||
        minReturn1Y != null ||
        maxReturn1Y != null ||
        minReturn3Y != null ||
        maxReturn3Y != null ||
        minSharpeRatio != null ||
        maxMaxDrawdown != null;
  }

  /// 重置所有筛选条件
  FundFilter reset() {
    return FundFilter();
  }

  /// 转换为API参数字符串
  Map<String, dynamic> toApiParams() {
    final params = <String, dynamic>{};

    if (fundTypes.isNotEmpty) {
      params['fund_types'] = fundTypes.join(',');
    }
    if (themes.isNotEmpty) {
      params['themes'] = themes.join(',');
    }
    if (riskLevels.isNotEmpty) {
      params['risk_levels'] = riskLevels.join(',');
    }
    if (minScale != null) {
      params['min_scale'] = minScale;
    }
    if (maxScale != null) {
      params['max_scale'] = maxScale;
    }
    if (establishStart != null) {
      params['establish_start'] = establishStart!.toIso8601String();
    }
    if (establishEnd != null) {
      params['establish_end'] = establishEnd!.toIso8601String();
    }
    if (companies != null && companies!.isNotEmpty) {
      params['companies'] = companies!.join(',');
    }
    if (managers != null && managers!.isNotEmpty) {
      params['managers'] = managers!.join(',');
    }
    if (minReturn1Y != null) {
      params['min_return_1y'] = minReturn1Y;
    }
    if (maxReturn1Y != null) {
      params['max_return_1y'] = maxReturn1Y;
    }
    if (minReturn3Y != null) {
      params['min_return_3y'] = minReturn3Y;
    }
    if (maxReturn3Y != null) {
      params['max_return_3y'] = maxReturn3Y;
    }
    if (minSharpeRatio != null) {
      params['min_sharpe_ratio'] = minSharpeRatio;
    }
    if (maxMaxDrawdown != null) {
      params['max_max_drawdown'] = maxMaxDrawdown;
    }
    if (sortBy != null) {
      params['sort_by'] = sortBy;
    }
    params['sort_ascending'] = sortAscending;
    if (page != null) {
      params['page'] = page;
    }
    if (pageSize != null) {
      params['page_size'] = pageSize;
    }

    return params;
  }

  @override
  String toString() {
    return 'FundFilter('
        'fundTypes: $fundTypes, '
        'themes: $themes, '
        'riskLevels: $riskLevels, '
        'minScale: $minScale, '
        'maxScale: $maxScale, '
        'establishStart: $establishStart, '
        'establishEnd: $establishEnd, '
        'companies: $companies, '
        'managers: $managers, '
        'minReturn1Y: $minReturn1Y, '
        'maxReturn1Y: $maxReturn1Y, '
        'sortBy: $sortBy, '
        'sortAscending: $sortAscending'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FundFilter &&
        other.fundTypes == fundTypes &&
        other.themes == themes &&
        other.riskLevels == riskLevels &&
        other.minScale == minScale &&
        other.maxScale == maxScale &&
        other.establishStart == establishStart &&
        other.establishEnd == establishEnd &&
        other.companies == companies &&
        other.managers == managers &&
        other.minReturn1Y == minReturn1Y &&
        other.maxReturn1Y == maxReturn1Y &&
        other.minReturn3Y == minReturn3Y &&
        other.maxReturn3Y == maxReturn3Y &&
        other.minSharpeRatio == minSharpeRatio &&
        other.maxMaxDrawdown == maxMaxDrawdown &&
        other.sortBy == sortBy &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode {
    return fundTypes.hashCode ^
        themes.hashCode ^
        riskLevels.hashCode ^
        minScale.hashCode ^
        maxScale.hashCode ^
        establishStart.hashCode ^
        establishEnd.hashCode ^
        companies.hashCode ^
        managers.hashCode ^
        minReturn1Y.hashCode ^
        maxReturn1Y.hashCode ^
        minReturn3Y.hashCode ^
        maxReturn3Y.hashCode ^
        minSharpeRatio.hashCode ^
        maxMaxDrawdown.hashCode ^
        sortBy.hashCode ^
        sortAscending.hashCode ^
        page.hashCode ^
        pageSize.hashCode;
  }
}
