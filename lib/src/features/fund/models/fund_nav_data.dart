import 'package:decimal/decimal.dart';

/// 基金净值数据模型
///
/// 包含基金净值、累计净值、变化率等核心信息
/// 支持准实时更新和历史数据对比
class FundNavData {
  /// 基金代码
  final String fundCode;

  /// 单位净值
  final Decimal nav;

  /// 净值日期
  final DateTime navDate;

  /// 累计净值
  final Decimal accumulatedNav;

  /// 日变化率 (百分比，如：0.0234 表示 2.34%)
  final Decimal changeRate;

  /// 数据时间戳
  final DateTime timestamp;

  /// 数据源
  final String? dataSource;

  /// 数据质量评分 (0-100)
  final double? qualityScore;

  /// 前一日净值 (用于计算变化)
  final Decimal? previousNav;

  /// 净值类型 (单位净值/累计净值)
  final NavType navType;

  /// 是否为交易日数据
  final bool isTradingDay;

  /// 交易状态
  final TradingStatus tradingStatus;

  /// 基金状态 (正常/暂停申购等)
  final FundStatus fundStatus;

  /// 扩展属性
  final Map<String, dynamic> extensions;

  const FundNavData({
    required this.fundCode,
    required this.nav,
    required this.navDate,
    required this.accumulatedNav,
    required this.changeRate,
    required this.timestamp,
    this.dataSource,
    this.qualityScore,
    this.previousNav,
    this.navType = NavType.unit,
    this.isTradingDay = true,
    this.tradingStatus = TradingStatus.open,
    this.fundStatus = FundStatus.normal,
    this.extensions = const {},
  });

  /// 从JSON创建实例
  factory FundNavData.fromJson(Map<String, dynamic> json) {
    return FundNavData(
      fundCode: json['fundCode'] as String,
      nav: Decimal.tryParse(json['nav'].toString()) ?? Decimal.zero,
      navDate: DateTime.parse(json['navDate'] as String),
      accumulatedNav:
          Decimal.tryParse(json['accumulatedNav'].toString()) ?? Decimal.zero,
      changeRate:
          Decimal.tryParse(json['changeRate'].toString()) ?? Decimal.zero,
      timestamp: DateTime.parse(json['timestamp'] as String),
      dataSource: json['dataSource'] as String?,
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
      previousNav: json['previousNav'] != null
          ? Decimal.tryParse(json['previousNav'].toString())
          : null,
      navType: NavType.values.firstWhere(
        (type) => type.name == json['navType'],
        orElse: () => NavType.unit,
      ),
      isTradingDay: json['isTradingDay'] as bool? ?? true,
      tradingStatus: TradingStatus.values.firstWhere(
        (status) => status.name == json['tradingStatus'],
        orElse: () => TradingStatus.open,
      ),
      fundStatus: FundStatus.values.firstWhere(
        (status) => status.name == json['fundStatus'],
        orElse: () => FundStatus.normal,
      ),
      extensions: Map<String, dynamic>.from(json['extensions'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'nav': nav.toString(),
      'navDate': navDate.toIso8601String(),
      'accumulatedNav': accumulatedNav.toString(),
      'changeRate': changeRate.toString(),
      'timestamp': timestamp.toIso8601String(),
      'dataSource': dataSource,
      'qualityScore': qualityScore,
      'previousNav': previousNav?.toString(),
      'navType': navType.name,
      'isTradingDay': isTradingDay,
      'tradingStatus': tradingStatus.name,
      'fundStatus': fundStatus.name,
      'extensions': extensions,
    };
  }

  /// 创建副本
  FundNavData copyWith({
    String? fundCode,
    Decimal? nav,
    DateTime? navDate,
    Decimal? accumulatedNav,
    Decimal? changeRate,
    DateTime? timestamp,
    String? dataSource,
    double? qualityScore,
    Decimal? previousNav,
    NavType? navType,
    bool? isTradingDay,
    TradingStatus? tradingStatus,
    FundStatus? fundStatus,
    Map<String, dynamic>? extensions,
  }) {
    return FundNavData(
      fundCode: fundCode ?? this.fundCode,
      nav: nav ?? this.nav,
      navDate: navDate ?? this.navDate,
      accumulatedNav: accumulatedNav ?? this.accumulatedNav,
      changeRate: changeRate ?? this.changeRate,
      timestamp: timestamp ?? this.timestamp,
      dataSource: dataSource ?? this.dataSource,
      qualityScore: qualityScore ?? this.qualityScore,
      previousNav: previousNav ?? this.previousNav,
      navType: navType ?? this.navType,
      isTradingDay: isTradingDay ?? this.isTradingDay,
      tradingStatus: tradingStatus ?? this.tradingStatus,
      fundStatus: fundStatus ?? this.fundStatus,
      extensions: extensions ?? this.extensions,
    );
  }

  /// 获取变化金额
  Decimal get changeAmount {
    if (previousNav == null) return Decimal.zero;
    return nav - previousNav!;
  }

  /// 获取变化百分比 (格式化为字符串)
  String get changePercentageFormatted {
    if (changeRate == Decimal.zero) return '0.00%';
    final prefix = changeRate > Decimal.zero ? '+' : '';
    return '$prefix${(changeRate * Decimal.fromInt(100)).toStringAsFixed(2)}%';
  }

  /// 是否上涨
  bool get isUp => changeRate > Decimal.zero;

  /// 是否下跌
  bool get isDown => changeRate < Decimal.zero;

  /// 是否持平
  bool get isFlat => changeRate == Decimal.zero;

  /// 是否为今日数据
  bool get isToday {
    final now = DateTime.now();
    return navDate.year == now.year &&
        navDate.month == now.month &&
        navDate.day == now.day;
  }

  /// 获取数据年龄
  Duration get age => DateTime.now().difference(timestamp);

  /// 是否数据过期 (超过1小时)
  bool get isExpired => age.inHours > 1;

  /// 是否为高质量数据
  bool get isHighQuality => (qualityScore ?? 0) >= 80.0;

  /// 获取净值格式化字符串
  String get navFormatted {
    return nav.toStringAsFixed(4);
  }

  /// 获取累计净值格式化字符串
  String get accumulatedNavFormatted {
    return accumulatedNav.toStringAsFixed(4);
  }

  /// 验证数据完整性
  bool get isValid {
    return fundCode.isNotEmpty &&
        nav > Decimal.zero &&
        accumulatedNav > Decimal.zero &&
        changeRate.abs() <= Decimal.fromInt(1); // 变化率不超过100%
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundNavData &&
        other.fundCode == fundCode &&
        other.nav == nav &&
        other.navDate == navDate &&
        other.accumulatedNav == accumulatedNav &&
        other.changeRate == changeRate &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      fundCode,
      nav,
      navDate,
      accumulatedNav,
      changeRate,
      timestamp,
    );
  }

  @override
  String toString() {
    return 'FundNavData(fundCode: $fundCode, nav: $navFormatted, change: $changePercentageFormatted, date: ${navDate.toIso8601String().split('T')[0]})';
  }
}

/// 净值类型
enum NavType {
  /// 单位净值
  unit,

  /// 累计净值
  accumulated,

  /// 万份收益 (货币基金)
  tenThousandIncome,

  /// 七日年化收益率
  sevenDayYield;
}

/// 交易状态
enum TradingStatus {
  /// 开放交易
  open,

  /// 暂停交易
  suspended,

  /// 停牌
  halted,

  /// 休市
  closed;

  String get description {
    switch (this) {
      case TradingStatus.open:
        return '开放交易';
      case TradingStatus.suspended:
        return '暂停交易';
      case TradingStatus.halted:
        return '停牌';
      case TradingStatus.closed:
        return '休市';
    }
  }
}

/// 基金状态
enum FundStatus {
  /// 正常
  normal,

  /// 暂停申购
  subscriptionSuspended,

  /// 暂停赎回
  redemptionSuspended,

  /// 暂停申购和赎回
  bothSuspended,

  /// 清盘
  liquidation,

  /// 终止
  terminated;

  String get description {
    switch (this) {
      case FundStatus.normal:
        return '正常';
      case FundStatus.subscriptionSuspended:
        return '暂停申购';
      case FundStatus.redemptionSuspended:
        return '暂停赎回';
      case FundStatus.bothSuspended:
        return '暂停申赎';
      case FundStatus.liquidation:
        return '清盘';
      case FundStatus.terminated:
        return '终止';
    }
  }
}

/// 净值数据查询参数
class FundNavQueryParams {
  /// 基金代码列表
  final List<String> fundCodes;

  /// 查询日期范围
  final DateTimeRange? dateRange;

  /// 是否包含历史数据
  final bool includeHistory;

  /// 数据页大小
  final int pageSize;

  /// 页码
  final int page;

  /// 排序方式
  final NavSortOrder sortOrder;

  /// 过滤条件
  final NavFilter? filter;

  const FundNavQueryParams({
    required this.fundCodes,
    this.dateRange,
    this.includeHistory = false,
    this.pageSize = 50,
    this.page = 1,
    this.sortOrder = NavSortOrder.dateDesc,
    this.filter,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'codes': fundCodes.join(','),
      'include_history': includeHistory,
      'page_size': pageSize,
      'page': page,
      'sort_order': sortOrder.name,
    };

    if (dateRange != null) {
      params['start_date'] = dateRange!.start.toIso8601String().split('T')[0];
      params['end_date'] = dateRange!.end.toIso8601String().split('T')[0];
    }

    if (filter != null) {
      params.addAll(filter!.toQueryParameters());
    }

    return params;
  }
}

/// 日期范围
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }
}

/// 净值排序方式
enum NavSortOrder {
  /// 日期降序
  dateDesc,

  /// 日期升序
  dateAsc,

  /// 净值降序
  navDesc,

  /// 净值升序
  navAsc,

  /// 变化率降序
  changeRateDesc,

  /// 变化率升序
  changeRateAsc;
}

/// 净值数据过滤器
class NavFilter {
  /// 最小净值
  final Decimal? minNav;

  /// 最大净值
  final Decimal? maxNav;

  /// 最小变化率
  final Decimal? minChangeRate;

  /// 最大变化率
  final Decimal? maxChangeRate;

  /// 交易状态
  final TradingStatus? tradingStatus;

  /// 基金状态
  final FundStatus? fundStatus;

  /// 数据质量最低分数
  final double? minQualityScore;

  const NavFilter({
    this.minNav,
    this.maxNav,
    this.minChangeRate,
    this.maxChangeRate,
    this.tradingStatus,
    this.fundStatus,
    this.minQualityScore,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (minNav != null) params['min_nav'] = minNav!.toString();
    if (maxNav != null) params['max_nav'] = maxNav!.toString();
    if (minChangeRate != null)
      params['min_change_rate'] = minChangeRate!.toString();
    if (maxChangeRate != null)
      params['max_change_rate'] = maxChangeRate!.toString();
    if (tradingStatus != null) params['trading_status'] = tradingStatus!.name;
    if (fundStatus != null) params['fund_status'] = fundStatus!.name;
    if (minQualityScore != null) params['min_quality_score'] = minQualityScore;

    return params;
  }
}
