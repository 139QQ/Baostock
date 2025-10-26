import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fund_favorite.g.dart';

/// 自选基金实体
///
/// 表示用户添加到自选列表的单个基金，包含：
/// - 基金基本信息（代码、名称、类型）
/// - 实时行情数据（当前净值、涨跌幅等）
/// - 用户配置（提醒价格、备注等）
/// - 系统管理信息（添加时间、排序权重等）
@JsonSerializable()
class FundFavorite extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型（股票型、债券型、混合型等）
  final String fundType;

  /// 基金管理人
  final String fundManager;

  /// 添加到自选的时间
  final DateTime addedAt;

  /// 排序权重（用于自定义排序）
  final double sortWeight;

  /// 备注信息
  final String? notes;

  /// 价格提醒设置
  final PriceAlertSettings? priceAlerts;

  /// 最后更新时间
  final DateTime updatedAt;

  /// 当前净值（从实时数据获取）
  final double? currentNav;

  /// 日涨跌幅（%）
  final double? dailyChange;

  /// 前一日净值
  final double? previousNav;

  /// 基金成立日期
  final DateTime? establishDate;

  /// 基金规模（亿元）
  final double? fundScale;

  /// 是否同步到云端
  final bool isSynced;

  /// 云端同步ID
  final String? cloudId;

  const FundFavorite({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.fundManager,
    required this.addedAt,
    this.sortWeight = 0.0,
    this.notes,
    this.priceAlerts,
    required this.updatedAt,
    this.currentNav,
    this.dailyChange,
    this.previousNav,
    this.establishDate,
    this.fundScale,
    this.isSynced = false,
    this.cloudId,
  });

  /// 从JSON创建实例
  factory FundFavorite.fromJson(Map<String, dynamic> json) =>
      _$FundFavoriteFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundFavoriteToJson(this);

  /// 创建副本
  FundFavorite copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    String? fundManager,
    DateTime? addedAt,
    double? sortWeight,
    String? notes,
    PriceAlertSettings? priceAlerts,
    DateTime? updatedAt,
    double? currentNav,
    double? dailyChange,
    double? previousNav,
    DateTime? establishDate,
    double? fundScale,
    bool? isSynced,
    String? cloudId,
  }) {
    return FundFavorite(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      fundManager: fundManager ?? this.fundManager,
      addedAt: addedAt ?? this.addedAt,
      sortWeight: sortWeight ?? this.sortWeight,
      notes: notes ?? this.notes,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      updatedAt: updatedAt ?? this.updatedAt,
      currentNav: currentNav ?? this.currentNav,
      dailyChange: dailyChange ?? this.dailyChange,
      previousNav: previousNav ?? this.previousNav,
      establishDate: establishDate ?? this.establishDate,
      fundScale: fundScale ?? this.fundScale,
      isSynced: isSynced ?? this.isSynced,
      cloudId: cloudId ?? this.cloudId,
    );
  }

  /// 更新实时行情数据
  FundFavorite updateMarketData({
    double? currentNav,
    double? dailyChange,
    double? previousNav,
  }) {
    return copyWith(
      currentNav: currentNav,
      dailyChange: dailyChange,
      previousNav: previousNav,
      updatedAt: DateTime.now(),
    );
  }

  /// 更新排序权重
  FundFavorite updateSortWeight(double weight) {
    return copyWith(
      sortWeight: weight,
      updatedAt: DateTime.now(),
    );
  }

  /// 设置价格提醒
  FundFavorite setPriceAlerts(PriceAlertSettings alerts) {
    return copyWith(
      priceAlerts: alerts,
      updatedAt: DateTime.now(),
    );
  }

  /// 标记为已同步
  FundFavorite markAsSynced(String cloudId) {
    return copyWith(
      isSynced: true,
      cloudId: cloudId,
      updatedAt: DateTime.now(),
    );
  }

  /// 标记为需要同步
  FundFavorite markAsNeedSync() {
    return copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        fundType,
        fundManager,
        addedAt,
        sortWeight,
        notes,
        priceAlerts,
        updatedAt,
        currentNav,
        dailyChange,
        previousNav,
        establishDate,
        fundScale,
        isSynced,
        cloudId,
      ];

  @override
  String toString() {
    return 'FundFavorite(fundCode: $fundCode, fundName: $fundName, fundType: $fundType)';
  }
}

/// 价格提醒设置
@JsonSerializable()
class PriceAlertSettings extends Equatable {
  /// 是否启用价格提醒
  final bool enabled;

  /// 价格上涨提醒阈值（%）
  final double? riseThreshold;

  /// 价格下跌提醒阈值（%）
  final double? fallThreshold;

  /// 目标价格提醒
  final List<TargetPriceAlert> targetPrices;

  /// 最后提醒时间（避免重复提醒）
  final DateTime? lastAlertTime;

  /// 提醒方式（推送、邮件、短信等）
  final List<AlertMethod> alertMethods;

  const PriceAlertSettings({
    this.enabled = false,
    this.riseThreshold,
    this.fallThreshold,
    this.targetPrices = const [],
    this.lastAlertTime,
    this.alertMethods = const [AlertMethod.push],
  });

  factory PriceAlertSettings.fromJson(Map<String, dynamic> json) =>
      _$PriceAlertSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PriceAlertSettingsToJson(this);

  PriceAlertSettings copyWith({
    bool? enabled,
    double? riseThreshold,
    double? fallThreshold,
    List<TargetPriceAlert>? targetPrices,
    DateTime? lastAlertTime,
    List<AlertMethod>? alertMethods,
  }) {
    return PriceAlertSettings(
      enabled: enabled ?? this.enabled,
      riseThreshold: riseThreshold ?? this.riseThreshold,
      fallThreshold: fallThreshold ?? this.fallThreshold,
      targetPrices: targetPrices ?? this.targetPrices,
      lastAlertTime: lastAlertTime ?? this.lastAlertTime,
      alertMethods: alertMethods ?? this.alertMethods,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        riseThreshold,
        fallThreshold,
        targetPrices,
        lastAlertTime,
        alertMethods,
      ];
}

/// 目标价格提醒
@JsonSerializable()
class TargetPriceAlert extends Equatable {
  /// 目标价格
  final double targetPrice;

  /// 提醒类型（达到目标价格时）
  final TargetPriceType type;

  /// 是否已激活
  final bool isActive;

  /// 创建时间
  final DateTime createdAt;

  const TargetPriceAlert({
    required this.targetPrice,
    required this.type,
    this.isActive = true,
    required this.createdAt,
  });

  factory TargetPriceAlert.fromJson(Map<String, dynamic> json) =>
      _$TargetPriceAlertFromJson(json);

  Map<String, dynamic> toJson() => _$TargetPriceAlertToJson(this);

  @override
  List<Object?> get props => [targetPrice, type, isActive, createdAt];
}

/// 目标价格类型
enum TargetPriceType {
  /// 达到目标价格时提醒
  reach,

  /// 超过目标价格时提醒
  exceed,

  /// 低于目标价格时提醒
  below,
}

/// 提醒方式
enum AlertMethod {
  /// 推送通知
  push,

  /// 邮件提醒
  email,

  /// 短信提醒
  sms,
}

/// 自选基金排序类型
enum FundFavoriteSortType {
  /// 添加时间（默认）
  addTime,

  /// 基金代码
  fundCode,

  /// 基金名称
  fundName,

  /// 当前净值
  currentNav,

  /// 日涨跌幅
  dailyChange,

  /// 基金规模
  fundScale,

  /// 自定义排序
  custom,
}

/// 自选基金排序方向
enum FundFavoriteSortDirection {
  /// 升序
  ascending,

  /// 降序
  descending,
}
