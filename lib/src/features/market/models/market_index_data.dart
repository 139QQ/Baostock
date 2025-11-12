import 'dart:convert';
import 'package:decimal/decimal.dart';

/// 市场指数数据模型
///
/// 包含指数的基本信息、当前价格、变化情况和市场状态
class MarketIndexData {
  // ignore: public_member_api_docs
  const MarketIndexData({
    required this.code,
    required this.name,
    required this.currentValue,
    required this.previousClose,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.changeAmount,
    required this.changePercentage,
    required this.volume,
    required this.turnover,
    required this.updateTime,
    required this.marketStatus,
    this.qualityLevel = DataQualityLevel.good,
    this.dataSource = 'akshare',
  });

  /// 指数代码 (如: 'SH000001' 表示上证指数)
  final String code;

  /// 指数名称 (如: '上证指数')
  final String name;

  /// 当前值
  final Decimal currentValue;

  /// 前收盘价
  final Decimal previousClose;

  /// 开盘价
  final Decimal openPrice;

  /// 最高价
  final Decimal highPrice;

  /// 最低价
  final Decimal lowPrice;

  /// 涨跌点数
  final Decimal changeAmount;

  /// 涨跌幅百分比
  final Decimal changePercentage;

  /// 成交量 (手)
  final int volume;

  /// 成交额 (元)
  final Decimal turnover;

  /// 更新时间
  final DateTime updateTime;

  /// 市场状态
  final MarketStatus marketStatus;

  /// 数据质量级别
  final DataQualityLevel qualityLevel;

  /// 数据来源
  final String dataSource;

  /// 是否上涨
  bool get isRising => changeAmount > Decimal.zero;

  /// 是否下跌
  bool get isFalling => changeAmount < Decimal.zero;

  /// 是否平盘
  bool get isUnchanged => changeAmount == Decimal.zero;

  /// 涂跌幅绝对值
  Decimal get absoluteChangePercentage => changePercentage.abs();

  /// 获取变化颜色代码
  String get changeColorCode {
    if (isRising) return 'red'; // 中国股市红涨
    if (isFalling) return 'green'; // 中国股市绿跌
    return 'gray'; // 平盘灰色
  }

  /// 是否为交易时间数据
  bool get isTradingTime => marketStatus == MarketStatus.trading;

  /// 检查数据是否过期 (超过5分钟视为过期)
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(updateTime);
    return difference.inMinutes > 5;
  }

  /// 创建JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'currentValue': currentValue.toString(),
      'previousClose': previousClose.toString(),
      'openPrice': openPrice.toString(),
      'highPrice': highPrice.toString(),
      'lowPrice': lowPrice.toString(),
      'changeAmount': changeAmount.toString(),
      'changePercentage': changePercentage.toString(),
      'volume': volume,
      'turnover': turnover.toString(),
      'updateTime': updateTime.toIso8601String(),
      'marketStatus': marketStatus.name,
      'qualityLevel': qualityLevel.name,
      'dataSource': dataSource,
    };
  }

  /// 创建优化的JSON (使用缓存和批处理)
  Map<String, dynamic> toJsonOptimized() {
    return {
      'c': code, // 简化键名以减少JSON大小
      'n': name,
      'cv': currentValue.toString(),
      'pc': previousClose.toString(),
      'op': openPrice.toString(),
      'hp': highPrice.toString(),
      'lp': lowPrice.toString(),
      'ca': changeAmount.toString(),
      'cp': changePercentage.toString(),
      'v': volume,
      't': turnover.toString(),
      'ut': updateTime.millisecondsSinceEpoch, // 使用时间戳而不是ISO字符串
      'ms': marketStatus.index,
      'ql': qualityLevel.index,
      'ds': dataSource,
    };
  }

  /// 序列化为JSON字符串 (高性能版本)
  String toJsonString() {
    return jsonEncode(toJsonOptimized());
  }

  /// 序列化为紧凑JSON字符串
  String toCompactJsonString() {
    return jsonEncode(toJsonOptimized());
  }

  /// 从JSON创建
  factory MarketIndexData.fromJson(Map<String, dynamic> json) {
    return MarketIndexData(
      code: json['code'] as String,
      name: json['name'] as String,
      currentValue: Decimal.parse(json['currentValue'] as String),
      previousClose: Decimal.parse(json['previousClose'] as String),
      openPrice: Decimal.parse(json['openPrice'] as String),
      highPrice: Decimal.parse(json['highPrice'] as String),
      lowPrice: Decimal.parse(json['lowPrice'] as String),
      changeAmount: Decimal.parse(json['changeAmount'] as String),
      changePercentage: Decimal.parse(json['changePercentage'] as String),
      volume: json['volume'] as int,
      turnover: Decimal.parse(json['turnover'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      marketStatus: MarketStatus.values.firstWhere(
        (status) => status.name == json['marketStatus'],
        orElse: () => MarketStatus.unknown,
      ),
      qualityLevel: DataQualityLevel.values.firstWhere(
        (level) => level.name == json['qualityLevel'],
        orElse: () => DataQualityLevel.unknown,
      ),
      dataSource: json['dataSource'] as String? ?? 'unknown',
    );
  }

  /// 从优化JSON创建 (高性能版本)
  factory MarketIndexData.fromJsonOptimized(Map<String, dynamic> json) {
    // 预解析所有Decimal值，减少重复调用
    final decimalCache = <String, Decimal>{};

    return MarketIndexData(
      code: json['c'] as String? ?? json['code'] as String,
      name: json['n'] as String? ?? json['name'] as String,
      currentValue:
          _parseDecimalCached(json, 'cv', 'currentValue', decimalCache),
      previousClose:
          _parseDecimalCached(json, 'pc', 'previousClose', decimalCache),
      openPrice: _parseDecimalCached(json, 'op', 'openPrice', decimalCache),
      highPrice: _parseDecimalCached(json, 'hp', 'highPrice', decimalCache),
      lowPrice: _parseDecimalCached(json, 'lp', 'lowPrice', decimalCache),
      changeAmount:
          _parseDecimalCached(json, 'ca', 'changeAmount', decimalCache),
      changePercentage:
          _parseDecimalCached(json, 'cp', 'changePercentage', decimalCache),
      volume: json['v'] as int? ?? json['volume'] as int,
      turnover: _parseDecimalCached(json, 't', 'turnover', decimalCache),
      updateTime: _parseDateTime(json),
      marketStatus: _parseMarketStatus(json),
      qualityLevel: _parseQualityLevel(json),
      dataSource:
          json['ds'] as String? ?? json['dataSource'] as String? ?? 'unknown',
    );
  }

  /// 从JSON字符串创建 (高性能版本)
  factory MarketIndexData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return MarketIndexData.fromJson(json);
  }

  /// 缓存式Decimal解析
  static Decimal _parseDecimalCached(
    Map<String, dynamic> json,
    String optimizedKey,
    String originalKey,
    Map<String, Decimal> cache,
  ) {
    final value = json[optimizedKey] ?? json[originalKey] as String;
    return cache.putIfAbsent(value, () => Decimal.parse(value));
  }

  /// 解析时间戳
  static DateTime _parseDateTime(Map<String, dynamic> json) {
    if (json.containsKey('ut')) {
      return DateTime.fromMillisecondsSinceEpoch(json['ut'] as int);
    } else if (json.containsKey('updateTime')) {
      return DateTime.parse(json['updateTime'] as String);
    }
    return DateTime.now();
  }

  /// 解析市场状态
  static MarketStatus _parseMarketStatus(Map<String, dynamic> json) {
    if (json.containsKey('ms')) {
      final index = json['ms'] as int;
      if (index >= 0 && index < MarketStatus.values.length) {
        return MarketStatus.values[index];
      }
    } else if (json.containsKey('marketStatus')) {
      return MarketStatus.values.firstWhere(
        (status) => status.name == json['marketStatus'],
        orElse: () => MarketStatus.unknown,
      );
    }
    return MarketStatus.unknown;
  }

  /// 解析数据质量等级
  static DataQualityLevel _parseQualityLevel(Map<String, dynamic> json) {
    if (json.containsKey('ql')) {
      final index = json['ql'] as int;
      if (index >= 0 && index < DataQualityLevel.values.length) {
        return DataQualityLevel.values[index];
      }
    } else if (json.containsKey('qualityLevel')) {
      return DataQualityLevel.values.firstWhere(
        (level) => level.name == json['qualityLevel'],
        orElse: () => DataQualityLevel.unknown,
      );
    }
    return DataQualityLevel.unknown;
  }

  /// 复制并修改部分属性
  MarketIndexData copyWith({
    String? code,
    String? name,
    Decimal? currentValue,
    Decimal? previousClose,
    Decimal? openPrice,
    Decimal? highPrice,
    Decimal? lowPrice,
    Decimal? changeAmount,
    Decimal? changePercentage,
    int? volume,
    Decimal? turnover,
    DateTime? updateTime,
    MarketStatus? marketStatus,
    DataQualityLevel? qualityLevel,
    String? dataSource,
  }) {
    return MarketIndexData(
      code: code ?? this.code,
      name: name ?? this.name,
      currentValue: currentValue ?? this.currentValue,
      previousClose: previousClose ?? this.previousClose,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      changeAmount: changeAmount ?? this.changeAmount,
      changePercentage: changePercentage ?? this.changePercentage,
      volume: volume ?? this.volume,
      turnover: turnover ?? this.turnover,
      updateTime: updateTime ?? this.updateTime,
      marketStatus: marketStatus ?? this.marketStatus,
      qualityLevel: qualityLevel ?? this.qualityLevel,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketIndexData &&
        other.code == code &&
        other.updateTime == updateTime &&
        other.currentValue == currentValue;
  }

  @override
  int get hashCode =>
      code.hashCode ^ updateTime.hashCode ^ currentValue.hashCode;

  @override
  String toString() {
    return 'MarketIndexData(code: $code, name: $name, currentValue: $currentValue, '
        'change: $changeAmount ($changePercentage%), status: $marketStatus)';
  }
}

/// 市场状态枚举
enum MarketStatus {
  /// 交易中
  trading,

  /// 盘前
  preMarket,

  /// 盘后
  postMarket,

  /// 休市
  closed,

  /// 节假日
  holiday,

  /// 未知状态
  unknown;

  String get description {
    switch (this) {
      case MarketStatus.trading:
        return '交易中';
      case MarketStatus.preMarket:
        return '盘前';
      case MarketStatus.postMarket:
        return '盘后';
      case MarketStatus.closed:
        return '休市';
      case MarketStatus.holiday:
        return '节假日';
      case MarketStatus.unknown:
        return '未知';
    }
  }
}

/// 数据质量级别枚举 (复用DataType中的定义，但在这里重新声明以避免循环依赖)
enum DataQualityLevel {
  excellent(5, '优秀'),
  good(4, '良好'),
  fair(3, '一般'),
  poor(2, '较差'),
  unknown(1, '未知');

  const DataQualityLevel(this.value, this.description);

  final int value;
  final String description;

  /// 从数值创建质量级别
  static DataQualityLevel fromValue(int value) {
    return DataQualityLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DataQualityLevel.unknown,
    );
  }
}

/// 主要市场指数常量定义
class MarketIndexConstants {
  /// 上证指数
  static const String shanghaiComposite = 'SH000001';

  /// 深证成指
  static const String shenzhenComponent = 'SZ399001';

  /// 创业板指
  static const String chiNext = 'SZ399006';

  /// 科创50
  static const String star50 = 'SH000688';

  /// 上证50
  static const String shanghai50 = 'SH000016';

  /// 沪深300
  static const String csi300 = 'SH000300';

  /// 中证500
  static const String csi500 = 'SH000905';

  /// 中证1000
  static const String csi1000 = 'SH000852';

  /// 恒生指数
  static const String hangSeng = 'HSI';

  /// 道琼斯指数
  static const String dowJones = 'DJIA';

  /// 纳斯达克指数
  static const String nasdaq = 'IXIC';

  /// 获取所有主要指数代码列表
  static List<String> get allMajorIndices => [
        shanghaiComposite,
        shenzhenComponent,
        chiNext,
        star50,
        shanghai50,
        csi300,
        csi500,
        csi1000,
        hangSeng,
        dowJones,
        nasdaq,
      ];

  /// 获取指数显示名称
  static String getIndexName(String code) {
    final nameMap = {
      shanghaiComposite: '上证指数',
      shenzhenComponent: '深证成指',
      chiNext: '创业板指',
      star50: '科创50',
      shanghai50: '上证50',
      csi300: '沪深300',
      csi500: '中证500',
      csi1000: '中证1000',
      hangSeng: '恒生指数',
      dowJones: '道琼斯',
      nasdaq: '纳斯达克',
    };
    return nameMap[code] ?? '未知指数';
  }

  /// 批量序列化为JSON字符串 (高性能版本)
  static String serializeList(List<MarketIndexData> indices) {
    if (indices.isEmpty) return '[]';

    final buffer = StringBuffer();
    buffer.write('[');

    for (int i = 0; i < indices.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(indices[i].toJsonString());
    }

    buffer.write(']');
    return buffer.toString();
  }

  /// 批量反序列化JSON字符串 (高性能版本)
  static List<MarketIndexData> deserializeList(String jsonString) {
    if (jsonString.isEmpty || jsonString == '[]') return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final result = <MarketIndexData>[];

      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          result.add(MarketIndexData.fromJsonOptimized(item));
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  /// 批量序列化为Map列表 (缓存友好版本)
  static List<Map<String, dynamic>> serializeListToMaps(
      List<MarketIndexData> indices) {
    final result = <Map<String, dynamic>>[];

    for (final index in indices) {
      result.add(index.toJsonOptimized());
    }

    return result;
  }

  /// 批量从Map列表反序列化 (高性能版本)
  static List<MarketIndexData> deserializeListFromMaps(
      List<Map<String, dynamic>> maps) {
    final result = <MarketIndexData>[];

    for (final map in maps) {
      result.add(MarketIndexData.fromJsonOptimized(map));
    }

    return result;
  }
}
