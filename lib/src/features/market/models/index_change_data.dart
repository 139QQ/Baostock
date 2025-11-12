import 'package:decimal/decimal.dart';
import 'market_index_data.dart';

/// 指数变化数据模型
///
/// 用于分析和展示指数的变化趋势和重要变化点
class IndexChangeData {
  /// 指数代码
  final String indexCode;

  /// 指数名称
  final String indexName;

  /// 变化前数据
  final MarketIndexData? previousData;

  /// 变化后数据
  final MarketIndexData currentData;

  /// 价格变化类型
  final PriceChangeType changeType;

  /// 变化幅度等级
  final ChangeMagnitude magnitude;

  /// 变化时间
  final DateTime changeTime;

  /// 是否为显著变化 (超过1%或特殊价格点)
  final bool isSignificant;

  /// 变化描述
  final String changeDescription;

  /// 技术分析信号
  final List<TechnicalSignal> technicalSignals;

  /// 创建指数变化数据实例
  const IndexChangeData({
    required this.indexCode,
    required this.indexName,
    this.previousData,
    required this.currentData,
    required this.changeType,
    required this.magnitude,
    required this.changeTime,
    required this.isSignificant,
    required this.changeDescription,
    this.technicalSignals = const [],
  });

  /// 计算变化检测
  factory IndexChangeData.calculateChange({
    required MarketIndexData currentData,
    MarketIndexData? previousData,
  }) {
    final indexCode = currentData.code;
    final indexName = currentData.name;
    final changeTime = currentData.updateTime;

    // 如果没有历史数据，创建首次变化记录
    if (previousData == null) {
      return IndexChangeData(
        indexCode: indexCode,
        indexName: indexName,
        currentData: currentData,
        changeType: PriceChangeType.initial,
        magnitude: ChangeMagnitude.minor,
        changeTime: changeTime,
        isSignificant: false,
        changeDescription: '首次获取${currentData.name}数据',
      );
    }

    // 计算价格变化
    final priceChange = currentData.currentValue - previousData.currentValue;
    final priceChangePercentage = Decimal.parse(
        (priceChange * Decimal.fromInt(100) / previousData.currentValue)
            .toString());

    // 确定变化类型
    final changeType = _determineChangeType(priceChange);

    // 确定变化幅度
    final magnitude =
        _determineMagnitude(Decimal.parse(priceChangePercentage.toString()));

    // 检查是否为显著变化
    final isSignificant = _isSignificantChange(
        Decimal.parse(priceChangePercentage.toString()), currentData);

    // 生成变化描述
    final changeDescription = _generateChangeDescription(
      currentData.name,
      priceChange,
      Decimal.parse(priceChangePercentage.toString()),
      changeType,
    );

    // 检测技术信号
    final technicalSignals = _detectTechnicalSignals(
      currentData,
      previousData,
      Decimal.parse(priceChangePercentage.toString()),
    );

    return IndexChangeData(
      indexCode: indexCode,
      indexName: indexName,
      previousData: previousData,
      currentData: currentData,
      changeType: changeType,
      magnitude: magnitude,
      changeTime: changeTime,
      isSignificant: isSignificant,
      changeDescription: changeDescription,
      technicalSignals: technicalSignals,
    );
  }

  /// 确定价格变化类型
  static PriceChangeType _determineChangeType(Decimal priceChange) {
    if (priceChange > Decimal.zero) {
      return PriceChangeType.rise;
    } else if (priceChange < Decimal.zero) {
      return PriceChangeType.fall;
    } else {
      return PriceChangeType.unchanged;
    }
  }

  /// 确定变化幅度等级
  static ChangeMagnitude _determineMagnitude(Decimal changePercentage) {
    final absPercentage = changePercentage.abs();

    if (absPercentage >= Decimal.fromInt(3)) {
      return ChangeMagnitude.major;
    } else if (absPercentage >= Decimal.fromInt(1)) {
      return ChangeMagnitude.moderate;
    } else if (absPercentage >= Decimal.parse('0.5')) {
      return ChangeMagnitude.minor;
    } else {
      return ChangeMagnitude.minimal;
    }
  }

  /// 检查是否为显著变化
  static bool _isSignificantChange(
    Decimal changePercentage,
    MarketIndexData currentData,
  ) {
    // 变化幅度超过1%认为是显著的
    if (changePercentage.abs() >= Decimal.fromInt(1)) {
      return true;
    }

    // 检查是否突破了重要的技术点位
    // 这里可以添加更多技术分析逻辑
    return false;
  }

  /// 生成变化描述
  static String _generateChangeDescription(
    String indexName,
    Decimal priceChange,
    Decimal changePercentage,
    PriceChangeType changeType,
  ) {
    final changeText = changePercentage.toStringAsFixed(2);
    final direction = changeType == PriceChangeType.rise
        ? '上涨'
        : changeType == PriceChangeType.fall
            ? '下跌'
            : '平盘';

    return '$indexName$direction$changeText%';
  }

  /// 检测技术信号
  static List<TechnicalSignal> _detectTechnicalSignals(
    MarketIndexData currentData,
    MarketIndexData previousData,
    Decimal changePercentage,
  ) {
    final signals = <TechnicalSignal>[];

    // 大幅变化信号
    if (changePercentage.abs() >= Decimal.fromInt(3)) {
      signals.add(TechnicalSignal(
        type: SignalType.largeMove,
        strength: SignalStrength.strong,
        description: '大幅波动',
      ));
    }

    // 成交量异常信号
    final volumeChange = currentData.volume - previousData.volume;
    if (volumeChange.abs() > previousData.volume ~/ 2) {
      signals.add(TechnicalSignal(
        type: SignalType.volumeAnomaly,
        strength: SignalStrength.moderate,
        description: '成交量异常',
      ));
    }

    // 价格突破信号
    if (currentData.currentValue > currentData.highPrice) {
      signals.add(TechnicalSignal(
        type: SignalType.breakout,
        strength: SignalStrength.strong,
        description: '突破新高',
      ));
    } else if (currentData.currentValue < currentData.lowPrice) {
      signals.add(TechnicalSignal(
        type: SignalType.breakdown,
        strength: SignalStrength.strong,
        description: '跌破新低',
      ));
    }

    return signals;
  }

  /// 创建JSON
  Map<String, dynamic> toJson() {
    return {
      'indexCode': indexCode,
      'indexName': indexName,
      'previousData': previousData?.toJson(),
      'currentData': currentData.toJson(),
      'changeType': changeType.name,
      'magnitude': magnitude.name,
      'changeTime': changeTime.toIso8601String(),
      'isSignificant': isSignificant,
      'changeDescription': changeDescription,
      'technicalSignals': technicalSignals.map((s) => s.toJson()).toList(),
    };
  }

  /// 从JSON创建
  factory IndexChangeData.fromJson(Map<String, dynamic> json) {
    return IndexChangeData(
      indexCode: json['indexCode'] as String,
      indexName: json['indexName'] as String,
      previousData: json['previousData'] != null
          ? MarketIndexData.fromJson(
              json['previousData'] as Map<String, dynamic>)
          : null,
      currentData:
          MarketIndexData.fromJson(json['currentData'] as Map<String, dynamic>),
      changeType: PriceChangeType.values.firstWhere(
        (type) => type.name == json['changeType'],
        orElse: () => PriceChangeType.unchanged,
      ),
      magnitude: ChangeMagnitude.values.firstWhere(
        (mag) => mag.name == json['magnitude'],
        orElse: () => ChangeMagnitude.minimal,
      ),
      changeTime: DateTime.parse(json['changeTime'] as String),
      isSignificant: json['isSignificant'] as bool,
      changeDescription: json['changeDescription'] as String,
      technicalSignals: (json['technicalSignals'] as List<dynamic>)
          .map((s) => TechnicalSignal.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'IndexChangeData(index: $indexName, change: $changeDescription, '
        'magnitude: $magnitude, significant: $isSignificant)';
  }
}

/// 价格变化类型
enum PriceChangeType {
  /// 上涨
  rise,

  /// 下跌
  fall,

  /// 平盘
  unchanged,

  /// 首次数据
  initial,

  /// 数据更新 (价格无变化)
  updated;

  /// 获取价格变化类型描述
  String get description {
    switch (this) {
      case PriceChangeType.rise:
        return '上涨';
      case PriceChangeType.fall:
        return '下跌';
      case PriceChangeType.unchanged:
        return '平盘';
      case PriceChangeType.initial:
        return '首次数据';
      case PriceChangeType.updated:
        return '数据更新';
    }
  }
}

/// 变化幅度等级
enum ChangeMagnitude {
  /// 大幅变化 (>3%)
  major,

  /// 中等变化 (1%-3%)
  moderate,

  /// 小幅变化 (0.5%-1%)
  minor,

  /// 微小变化 (<0.5%)
  minimal;

  /// 获取变化幅度等级描述
  String get description {
    switch (this) {
      case ChangeMagnitude.major:
        return '大幅';
      case ChangeMagnitude.moderate:
        return '中等';
      case ChangeMagnitude.minor:
        return '小幅';
      case ChangeMagnitude.minimal:
        return '微小';
    }
  }
}

/// 技术信号类型
enum SignalType {
  /// 大幅波动
  largeMove,

  /// 成交量异常
  volumeAnomaly,

  /// 突破新高
  breakout,

  /// 跌破新低
  breakdown,

  /// 趋势反转
  trendReversal,

  /// 支撑位测试
  supportTest,

  /// 阻力位测试
  resistanceTest;

  /// 获取技术信号类型描述
  String get description {
    switch (this) {
      case SignalType.largeMove:
        return '大幅波动';
      case SignalType.volumeAnomaly:
        return '成交量异常';
      case SignalType.breakout:
        return '突破新高';
      case SignalType.breakdown:
        return '跌破新低';
      case SignalType.trendReversal:
        return '趋势反转';
      case SignalType.supportTest:
        return '支撑位测试';
      case SignalType.resistanceTest:
        return '阻力位测试';
    }
  }
}

/// 信号强度
enum SignalStrength {
  /// 强信号
  strong,

  /// 中等信号
  moderate,

  /// 弱信号
  weak;

  /// 获取信号强度描述
  String get description {
    switch (this) {
      case SignalStrength.strong:
        return '强';
      case SignalStrength.moderate:
        return '中等';
      case SignalStrength.weak:
        return '弱';
    }
  }
}

/// 技术信号
class TechnicalSignal {
  /// 信号类型
  final SignalType type;

  /// 信号强度
  final SignalStrength strength;

  /// 信号描述
  final String description;

  /// 信号时间
  final DateTime timestamp;

  /// 额外数据
  final Map<String, dynamic>? additionalData;

  /// 创建技术信号实例
  TechnicalSignal({
    required this.type,
    required this.strength,
    required this.description,
    DateTime? timestamp,
    this.additionalData,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 创建JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'strength': strength.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  /// 从JSON创建
  factory TechnicalSignal.fromJson(Map<String, dynamic> json) {
    return TechnicalSignal(
      type: SignalType.values.firstWhere(
        (type) => type.name == json['type'],
      ),
      strength: SignalStrength.values.firstWhere(
        (strength) => strength.name == json['strength'],
      ),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'TechnicalSignal(type: $type, strength: $strength, description: $description)';
  }
}
