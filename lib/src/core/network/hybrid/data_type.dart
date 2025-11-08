/// 数据类型枚举和优先级系统
///
/// 定义混合数据获取系统支持的所有数据类型及其优先级、更新频率等特性
enum DataType {
  // 高优先级实时数据 (未来WebSocket)
  marketIndex('market_index', DataPriority.high, Duration(seconds: 30)),
  etfSpotPrice('etf_spot_price', DataPriority.high, Duration(seconds: 30)),
  macroeconomicIndicator(
      'macroeconomic_indicator', DataPriority.high, Duration(minutes: 1)),

  // 中等优先级准实时数据 (当前HTTP轮询)
  fundNetValue('fund_net_value', DataPriority.medium, Duration(minutes: 15)),
  fundBasicInfo('fund_basic_info', DataPriority.medium, Duration(hours: 6)),
  marketTradingData(
      'market_trading_data', DataPriority.medium, Duration(minutes: 5)),

  // 低优先级按需数据 (HTTP按需请求)
  historicalPerformance(
      'historical_performance', DataPriority.low, Duration(hours: 24)),
  fundHoldingDetails(
      'fund_holding_details', DataPriority.low, Duration(hours: 12)),
  analysisReport('analysis_report', DataPriority.low, Duration(hours: 24)),

  // 系统状态数据
  connectionStatus(
      'connection_status', DataPriority.critical, Duration(seconds: 10)),
  dataQualityMetrics(
      'data_quality_metrics', DataPriority.medium, Duration(minutes: 1)),

  // 缓存系统需要的额外数据类型
  fundRanking('fund_ranking', DataPriority.medium, Duration(minutes: 2)),
  etfSpotData('etf_spot_data', DataPriority.high, Duration(seconds: 30)),
  lofSpotData('lof_spot_data', DataPriority.high, Duration(seconds: 30)),
  fundProfile('fund_profile', DataPriority.low, Duration(hours: 24)),
  portfolioData('portfolio_data', DataPriority.medium, Duration(minutes: 10)),
  userPreferences('user_preferences', DataPriority.low, Duration(days: 30)),
  unknown('unknown', DataPriority.low, Duration(hours: 24));

  const DataType(this.code, this.priority, this.defaultUpdateInterval);

  /// 数据类型代码标识符
  final String code;

  /// 数据优先级
  final DataPriority priority;

  /// 默认更新间隔
  final Duration defaultUpdateInterval;

  /// 获取数据类型的描述
  String get description {
    switch (this) {
      case DataType.marketIndex:
        return '市场指数 (上证、深证、创业板等)';
      case DataType.etfSpotPrice:
        return 'ETF实时价格';
      case DataType.macroeconomicIndicator:
        return '重要宏观经济指标';
      case DataType.fundNetValue:
        return '基金净值';
      case DataType.fundBasicInfo:
        return '基金基础信息';
      case DataType.marketTradingData:
        return '市场交易数据';
      case DataType.historicalPerformance:
        return '历史业绩数据';
      case DataType.fundHoldingDetails:
        return '基金持仓详情';
      case DataType.analysisReport:
        return '分析报告数据';
      case DataType.connectionStatus:
        return '连接状态';
      case DataType.dataQualityMetrics:
        return '数据质量监控指标';
      case DataType.fundRanking:
        return '基金排行榜';
      case DataType.etfSpotData:
        return 'ETF现货数据';
      case DataType.lofSpotData:
        return 'LOF现货数据';
      case DataType.fundProfile:
        return '基金档案';
      case DataType.portfolioData:
        return '投资组合数据';
      case DataType.userPreferences:
        return '用户偏好设置';
      case DataType.unknown:
        return '未知数据类型';
    }
  }

  /// 获取数据类型的API端点
  String get apiEndpoint {
    switch (this) {
      case DataType.marketIndex:
        return '/api/stock/realtime';
      case DataType.etfSpotPrice:
        return '/api/etf/spot';
      case DataType.macroeconomicIndicator:
        return '/api/macro/indicator';
      case DataType.fundNetValue:
        return '/api/fund/nav';
      case DataType.fundBasicInfo:
        return '/api/fund/info';
      case DataType.marketTradingData:
        return '/api/market/trading';
      case DataType.historicalPerformance:
        return '/api/fund/performance';
      case DataType.fundHoldingDetails:
        return '/api/fund/holdings';
      case DataType.analysisReport:
        return '/api/fund/analysis';
      case DataType.connectionStatus:
        return '/api/system/status';
      case DataType.dataQualityMetrics:
        return '/api/system/metrics';
      case DataType.fundRanking:
        return '/api/fund/ranking';
      case DataType.etfSpotData:
        return '/api/etf/spot';
      case DataType.lofSpotData:
        return '/api/lof/spot';
      case DataType.fundProfile:
        return '/api/fund/profile';
      case DataType.portfolioData:
        return '/api/portfolio/data';
      case DataType.userPreferences:
        return '/api/user/preferences';
      case DataType.unknown:
        return '/api/unknown';
    }
  }

  /// 检查是否为实时数据类型
  bool get isRealtime =>
      priority == DataPriority.high || priority == DataPriority.critical;

  /// 检查是否为准实时数据类型
  bool get isQuasiRealtime => priority == DataPriority.medium;

  /// 检查是否为按需数据类型
  bool get isOnDemand => priority == DataPriority.low;

  /// 从字符串代码解析数据类型
  static DataType? fromCode(String code) {
    try {
      return DataType.values.firstWhere((type) => type.code == code);
    } catch (e) {
      return null;
    }
  }
}

/// 数据优先级枚举
enum DataPriority {
  /// 关键数据 - 系统状态、连接状态
  critical(100, '关键'),

  /// 高优先级 - 实时市场数据
  high(80, '高'),

  /// 中等优先级 - 准实时数据
  medium(50, '中等'),

  /// 低优先级 - 按需历史数据
  low(20, '低');

  const DataPriority(this.value, this.description);

  /// 优先级数值 (越高越重要)
  final int value;

  /// 优先级描述
  final String description;

  /// 比较优先级
  int compareTo(DataPriority other) {
    return value.compareTo(other.value);
  }

  /// 检查是否高于指定优先级
  bool isHigherThan(DataPriority other) {
    return value > other.value;
  }
}

/// 数据获取策略配置
class DataFetchConfig {
  /// 数据类型
  final DataType dataType;

  /// 是否启用自动获取
  final bool autoFetchEnabled;

  /// 自定义更新间隔 (如果为null，使用默认间隔)
  final Duration? customInterval;

  /// 获取策略类型偏好
  final FetchStrategyPreference strategyPreference;

  /// 最大重试次数
  final int maxRetries;

  /// 超时时间
  final Duration timeout;

  /// 是否启用缓存
  final bool cacheEnabled;

  /// 缓存过期时间
  final Duration cacheExpiration;

  const DataFetchConfig({
    required this.dataType,
    this.autoFetchEnabled = true,
    this.customInterval,
    this.strategyPreference = FetchStrategyPreference.auto,
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 30),
    this.cacheEnabled = true,
    this.cacheExpiration = const Duration(minutes: 15),
  });

  /// 获取有效更新间隔
  Duration get effectiveInterval =>
      customInterval ?? dataType.defaultUpdateInterval;

  /// 创建默认配置
  factory DataFetchConfig.defaultForType(DataType dataType) {
    return DataFetchConfig(dataType: dataType);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.code,
      'autoFetchEnabled': autoFetchEnabled,
      'customInterval': customInterval?.inMilliseconds,
      'strategyPreference': strategyPreference.name,
      'maxRetries': maxRetries,
      'timeout': timeout.inMilliseconds,
      'cacheEnabled': cacheEnabled,
      'cacheExpiration': cacheExpiration.inMilliseconds,
    };
  }

  /// 从JSON创建配置
  factory DataFetchConfig.fromJson(Map<String, dynamic> json) {
    final dataTypeCode = json['dataType'] as String;
    final dataType = DataType.fromCode(dataTypeCode);
    if (dataType == null) {
      throw ArgumentError('Unknown data type: $dataTypeCode');
    }

    return DataFetchConfig(
      dataType: dataType,
      autoFetchEnabled: json['autoFetchEnabled'] as bool? ?? true,
      customInterval: json['customInterval'] != null
          ? Duration(milliseconds: json['customInterval'] as int)
          : null,
      strategyPreference: FetchStrategyPreference.values
          .firstWhere((pref) => pref.name == json['strategyPreference']),
      maxRetries: json['maxRetries'] as int? ?? 3,
      timeout: Duration(milliseconds: json['timeout'] as int? ?? 30000),
      cacheEnabled: json['cacheEnabled'] as bool? ?? true,
      cacheExpiration:
          Duration(milliseconds: json['cacheExpiration'] as int? ?? 900000),
    );
  }
}

/// 数据获取策略偏好
enum FetchStrategyPreference {
  /// 自动选择最优策略
  auto,

  /// 优先使用WebSocket
  websocket,

  /// 优先使用HTTP轮询
  httpPolling,

  /// 仅使用HTTP按需请求
  httpOnDemand;
}

/// 数据质量级别
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
