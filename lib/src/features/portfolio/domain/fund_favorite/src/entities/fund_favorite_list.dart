import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'fund_favorite.dart';

part 'fund_favorite_list.g.dart';

/// 自选基金列表实体
///
/// 管理用户的自选基金集合，支持：
/// - 多列表管理（如：关注列表、观察列表等）
/// - 列表配置（排序、筛选等）
/// - 同步策略和统计信息
@JsonSerializable()
class FundFavoriteList extends Equatable {
  /// 列表ID
  final String id;

  /// 列表名称
  final String name;

  /// 列表描述
  final String? description;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  /// 基金数量
  final int fundCount;

  /// 排序配置
  final SortConfiguration sortConfig;

  /// 筛选配置
  final FilterConfiguration filterConfig;

  /// 同步配置
  final SyncConfiguration syncConfig;

  /// 统计信息
  final ListStatistics statistics;

  /// 是否为默认列表
  final bool isDefault;

  /// 是否启用
  final bool isEnabled;

  /// 列表图标
  final String? iconCode;

  /// 列表颜色主题
  final String? colorTheme;

  /// 是否公开（分享功能）
  final bool isPublic;

  /// 公开访问码
  final String? shareCode;

  /// 标签
  final List<String> tags;

  const FundFavoriteList({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.fundCount = 0,
    this.sortConfig = const SortConfiguration(),
    this.filterConfig = const FilterConfiguration(),
    this.syncConfig = const SyncConfiguration(),
    ListStatistics? statistics,
    this.isDefault = false,
    this.isEnabled = true,
    this.iconCode,
    this.colorTheme,
    this.isPublic = false,
    this.shareCode,
    this.tags = const [],
  }) : statistics = statistics ?? const ListStatistics(statisticsAt: null);

  /// 从JSON创建实例
  factory FundFavoriteList.fromJson(Map<String, dynamic> json) =>
      _$FundFavoriteListFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundFavoriteListToJson(this);

  /// 创建副本
  FundFavoriteList copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? fundCount,
    SortConfiguration? sortConfig,
    FilterConfiguration? filterConfig,
    SyncConfiguration? syncConfig,
    ListStatistics? statistics,
    bool? isDefault,
    bool? isEnabled,
    String? iconCode,
    String? colorTheme,
    bool? isPublic,
    String? shareCode,
    List<String>? tags,
  }) {
    return FundFavoriteList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fundCount: fundCount ?? this.fundCount,
      sortConfig: sortConfig ?? this.sortConfig,
      filterConfig: filterConfig ?? this.filterConfig,
      syncConfig: syncConfig ?? this.syncConfig,
      statistics: statistics ?? this.statistics,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      iconCode: iconCode ?? this.iconCode,
      colorTheme: colorTheme ?? this.colorTheme,
      isPublic: isPublic ?? this.isPublic,
      shareCode: shareCode ?? this.shareCode,
      tags: tags ?? this.tags,
    );
  }

  /// 更新基本信息
  FundFavoriteList updateInfo({
    String? name,
    String? description,
    String? iconCode,
    String? colorTheme,
    List<String>? tags,
  }) {
    return copyWith(
      name: name,
      description: description,
      iconCode: iconCode,
      colorTheme: colorTheme,
      tags: tags,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新基金数量
  FundFavoriteList updateFundCount(int count) {
    return copyWith(
      fundCount: count,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新排序配置
  FundFavoriteList updateSortConfig(SortConfiguration config) {
    return copyWith(
      sortConfig: config,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新筛选配置
  FundFavoriteList updateFilterConfig(FilterConfiguration config) {
    return copyWith(
      filterConfig: config,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新同步配置
  FundFavoriteList updateSyncConfig(SyncConfiguration config) {
    return copyWith(
      syncConfig: config,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新统计信息
  FundFavoriteList updateStatistics(ListStatistics stats) {
    return copyWith(
      statistics: stats,
      updatedAt: DateTime.now(),
    );
  }

  /// 启用/禁用列表
  FundFavoriteList setEnabled(bool enabled) {
    return copyWith(
      isEnabled: enabled,
      updatedAt: DateTime.now(),
    );
  }

  /// 设置为默认列表
  FundFavoriteList setAsDefault() {
    return copyWith(
      isDefault: true,
      updatedAt: DateTime.now(),
    );
  }

  /// 设置公开状态
  FundFavoriteList setPublic(bool isPublic, {String? shareCode}) {
    return copyWith(
      isPublic: isPublic,
      shareCode: shareCode,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdAt,
        updatedAt,
        fundCount,
        sortConfig,
        filterConfig,
        syncConfig,
        statistics,
        isDefault,
        isEnabled,
        iconCode,
        colorTheme,
        isPublic,
        shareCode,
        tags,
      ];

  @override
  String toString() {
    return 'FundFavoriteList(id: $id, name: $name, fundCount: $fundCount)';
  }
}

/// 排序配置
@JsonSerializable()
class SortConfiguration extends Equatable {
  /// 排序类型
  final FundFavoriteSortType sortType;

  /// 排序方向
  final FundFavoriteSortDirection direction;

  /// 是否启用自定义排序
  final bool enableCustomSort;

  const SortConfiguration({
    this.sortType = FundFavoriteSortType.addTime,
    this.direction = FundFavoriteSortDirection.descending,
    this.enableCustomSort = false,
  });

  factory SortConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SortConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$SortConfigurationToJson(this);

  SortConfiguration copyWith({
    FundFavoriteSortType? sortType,
    FundFavoriteSortDirection? direction,
    bool? enableCustomSort,
  }) {
    return SortConfiguration(
      sortType: sortType ?? this.sortType,
      direction: direction ?? this.direction,
      enableCustomSort: enableCustomSort ?? this.enableCustomSort,
    );
  }

  @override
  List<Object?> get props => [sortType, direction, enableCustomSort];
}

/// 筛选配置
@JsonSerializable()
class FilterConfiguration extends Equatable {
  /// 启用的基金类型
  final List<String> allowedFundTypes;

  /// 最小基金规模
  final double? minFundScale;

  /// 最大基金规模
  final double? maxFundScale;

  /// 最小成立年限（年）
  final int? minEstablishYears;

  /// 只显示有价格提醒的基金
  final bool onlyWithAlerts;

  /// 只显示同步到云端的基金
  final bool onlySynced;

  /// 自定义筛选条件
  final Map<String, dynamic> customFilters;

  const FilterConfiguration({
    this.allowedFundTypes = const [],
    this.minFundScale,
    this.maxFundScale,
    this.minEstablishYears,
    this.onlyWithAlerts = false,
    this.onlySynced = false,
    this.customFilters = const {},
  });

  factory FilterConfiguration.fromJson(Map<String, dynamic> json) =>
      _$FilterConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$FilterConfigurationToJson(this);

  FilterConfiguration copyWith({
    List<String>? allowedFundTypes,
    double? minFundScale,
    double? maxFundScale,
    int? minEstablishYears,
    bool? onlyWithAlerts,
    bool? onlySynced,
    Map<String, dynamic>? customFilters,
  }) {
    return FilterConfiguration(
      allowedFundTypes: allowedFundTypes ?? this.allowedFundTypes,
      minFundScale: minFundScale ?? this.minFundScale,
      maxFundScale: maxFundScale ?? this.maxFundScale,
      minEstablishYears: minEstablishYears ?? this.minEstablishYears,
      onlyWithAlerts: onlyWithAlerts ?? this.onlyWithAlerts,
      onlySynced: onlySynced ?? this.onlySynced,
      customFilters: customFilters ?? this.customFilters,
    );
  }

  @override
  List<Object?> get props => [
        allowedFundTypes,
        minFundScale,
        maxFundScale,
        minEstablishYears,
        onlyWithAlerts,
        onlySynced,
        customFilters,
      ];
}

/// 同步配置
@JsonSerializable()
class SyncConfiguration extends Equatable {
  /// 是否启用自动同步
  final bool autoSync;

  /// 同步间隔（分钟）
  final int syncInterval;

  /// 仅WiFi同步
  final bool wifiOnly;

  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 同步错误重试次数
  final int retryCount;

  /// 最大重试次数
  final int maxRetries;

  const SyncConfiguration({
    this.autoSync = true,
    this.syncInterval = 30,
    this.wifiOnly = true,
    this.lastSyncTime,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  factory SyncConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SyncConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$SyncConfigurationToJson(this);

  SyncConfiguration copyWith({
    bool? autoSync,
    int? syncInterval,
    bool? wifiOnly,
    DateTime? lastSyncTime,
    int? retryCount,
    int? maxRetries,
  }) {
    return SyncConfiguration(
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  @override
  List<Object?> get props => [
        autoSync,
        syncInterval,
        wifiOnly,
        lastSyncTime,
        retryCount,
        maxRetries,
      ];
}

/// 列表统计信息
@JsonSerializable()
class ListStatistics extends Equatable {
  /// 总收益
  final double totalProfit;

  /// 总收益率
  final double totalProfitRate;

  /// 日收益
  final double dailyProfit;

  /// 日收益率
  final double dailyProfitRate;

  /// 最好表现的基金
  final String? bestPerformingFund;

  /// 最差表现的基金
  final String? worstPerformingFund;

  /// 平均涨跌幅
  final double averageDailyChange;

  /// 统计时间
  final DateTime? statisticsAt;

  const ListStatistics({
    this.totalProfit = 0.0,
    this.totalProfitRate = 0.0,
    this.dailyProfit = 0.0,
    this.dailyProfitRate = 0.0,
    this.bestPerformingFund,
    this.worstPerformingFund,
    this.averageDailyChange = 0.0,
    this.statisticsAt,
  });

  /// 创建带有当前时间的统计实例
  factory ListStatistics.now({
    double totalProfit = 0.0,
    double totalProfitRate = 0.0,
    double dailyProfit = 0.0,
    double dailyProfitRate = 0.0,
    String? bestPerformingFund,
    String? worstPerformingFund,
    double averageDailyChange = 0.0,
  }) {
    return ListStatistics(
      totalProfit: totalProfit,
      totalProfitRate: totalProfitRate,
      dailyProfit: dailyProfit,
      dailyProfitRate: dailyProfitRate,
      bestPerformingFund: bestPerformingFund,
      worstPerformingFund: worstPerformingFund,
      averageDailyChange: averageDailyChange,
      statisticsAt: DateTime.now(),
    );
  }

  factory ListStatistics.fromJson(Map<String, dynamic> json) =>
      _$ListStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$ListStatisticsToJson(this);

  ListStatistics copyWith({
    double? totalProfit,
    double? totalProfitRate,
    double? dailyProfit,
    double? dailyProfitRate,
    String? bestPerformingFund,
    String? worstPerformingFund,
    double? averageDailyChange,
    DateTime? statisticsAt,
  }) {
    return ListStatistics(
      totalProfit: totalProfit ?? this.totalProfit,
      totalProfitRate: totalProfitRate ?? this.totalProfitRate,
      dailyProfit: dailyProfit ?? this.dailyProfit,
      dailyProfitRate: dailyProfitRate ?? this.dailyProfitRate,
      bestPerformingFund: bestPerformingFund ?? this.bestPerformingFund,
      worstPerformingFund: worstPerformingFund ?? this.worstPerformingFund,
      averageDailyChange: averageDailyChange ?? this.averageDailyChange,
      statisticsAt: statisticsAt ?? this.statisticsAt,
    );
  }

  @override
  List<Object?> get props => [
        totalProfit,
        totalProfitRate,
        dailyProfit,
        dailyProfitRate,
        bestPerformingFund,
        worstPerformingFund,
        averageDailyChange,
        statisticsAt,
      ];
}
