part of 'unified_fund_cubit.dart';

/// 基金NAV数据
class FundNavData extends Equatable {
  /// NAV值
  final String nav;

  /// NAV日期
  final DateTime navDate;

  /// 日收益率
  final double dailyReturn;

  /// 收益率
  final double returnRate;

  /// 构造函数
  const FundNavData({
    required this.nav,
    required this.navDate,
    required this.dailyReturn,
    required this.returnRate,
  });

  @override
  List<Object> get props => [nav, navDate, dailyReturn, returnRate];
}

/// 基金实体（简化版）
class Fund extends Equatable {
  /// 基金代码
  final String code;

  /// 基金名称
  final String name;

  /// 基金类型
  final String type;

  /// NAV值
  final double? nav;

  /// NAV日期
  final DateTime? navDate;

  /// 构造函数
  const Fund({
    required this.code,
    required this.name,
    required this.type,
    this.nav,
    this.navDate,
  });

  @override
  List<Object?> get props => [code, name, type, nav, navDate];
}

/// 统一基金状态的基类
abstract class UnifiedFundState extends Equatable {
  /// 构造函数
  const UnifiedFundState();

  @override
  List<Object?> get props => [];

  /// 获取状态描述
  String get description => runtimeType.toString();

  /// 获取状态类型
  UnifiedStatus get status => UnifiedStatus.idle;

  /// 获取创建时间
  DateTime get timestamp => DateTime.now();

  /// 获取错误信息
  String? get error => null;

  /// 是否为加载状态
  bool get isLoading => status == UnifiedStatus.loading;

  /// 是否为成功状态
  bool get isSuccess => status == UnifiedStatus.success;

  /// 是否为错误状态
  bool get isError => status == UnifiedStatus.error;

  /// 是否为监控状态
  bool get isMonitoring => status == UnifiedStatus.monitoring;

  /// 是否为空闲状态
  bool get isIdle => status == UnifiedStatus.idle;
}

/// 初始状态
class UnifiedFundInitial extends UnifiedFundState {
  /// 构造函数
  const UnifiedFundInitial();

  @override
  List<Object?> get props => [];

  @override
  String get description => '统一基金状态 - 初始';

  @override
  String toString() => 'UnifiedFundInitial';
}

/// 加载中状态
class UnifiedFundLoading extends UnifiedFundState {
  /// 构造函数
  const UnifiedFundLoading({
    /// 加载消息
    this.message = '加载中...',
  });

  /// 加载消息
  final String? message;

  @override
  List<Object?> get props => [message];

  @override
  String get description => message ?? '统一基金状态 - 加载中';

  @override
  String toString() => 'UnifiedFundLoading(message: $message)';
}

/// 数据加载成功状态
class UnifiedFundLoaded extends UnifiedFundState {
  /// 基金列表
  final List<Fund> funds;

  /// 基金排名列表
  final List<FundRanking> rankings;

  /// NAV数据映射
  final Map<String, FundNavData> navData;

  /// 用户偏好设置
  final Map<String, dynamic> userPreferences;

  /// 状态
  @override
  final UnifiedStatus status;

  /// 最后更新时间
  final DateTime lastUpdate;

  /// 错误信息
  @override
  final String? error;

  /// 构造函数
  const UnifiedFundLoaded({
    required this.funds,
    required this.rankings,
    required this.navData,
    required this.userPreferences,
    this.status = UnifiedStatus.success,
    required this.lastUpdate,
    this.error,
  });

  @override
  List<Object?> get props => [
        funds,
        rankings,
        navData,
        userPreferences,
        status,
        lastUpdate,
        error,
      ];

  @override
  String get description => '统一基金状态 - 加载成功';

  @override
  String toString() =>
      'UnifiedFundLoaded(funds: ${funds.length}, rankings: ${rankings.length})';

  /// 更新状态
  UnifiedFundLoaded copyWith({
    List<Fund>? funds,
    List<FundRanking>? rankings,
    Map<String, FundNavData>? navData,
    Map<String, dynamic>? userPreferences,
    UnifiedStatus? status,
    DateTime? lastUpdate,
    String? error,
    bool clearError = false,
  }) {
    return UnifiedFundLoaded(
      funds: funds ?? this.funds,
      rankings: rankings ?? this.rankings,
      navData: navData ?? this.navData,
      userPreferences: userPreferences ?? this.userPreferences,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 错误状态
class UnifiedFundError extends UnifiedFundState {
  @override
  final String error;

  @override
  final DateTime timestamp;

  /// 前一个状态
  final UnifiedStatus previousStatus;

  /// 构造函数
  const UnifiedFundError({
    required this.error,
    required this.timestamp,
    this.previousStatus = UnifiedStatus.idle,
  });

  @override
  List<Object?> get props => [error, timestamp, previousStatus];

  @override
  String get description => '统一基金状态 - 错误';

  @override
  String toString() => 'UnifiedFundError(error: $error, timestamp: $timestamp)';
}

/// 状态枚举
enum UnifiedStatus {
  /// 空闲状态
  idle,

  /// 加载中状态
  loading,

  /// 成功状态
  success,

  /// 错误状态
  error,

  /// 监控中状态
  monitoring,

  /// 完成状态
  completed,
}

/// 状态扩展方法
extension UnifiedStatusExtension on UnifiedStatus {
  /// 获取状态描述
  String get description {
    switch (this) {
      case UnifiedStatus.idle:
        return '空闲';
      case UnifiedStatus.loading:
        return '加载中';
      case UnifiedStatus.success:
        return '成功';
      case UnifiedStatus.error:
        return '错误';
      case UnifiedStatus.monitoring:
        return '监控中';
      case UnifiedStatus.completed:
        return '完成';
    }
  }

  /// 获取状态图标
  String get icon {
    switch (this) {
      case UnifiedStatus.idle:
        return '⚪';
      case UnifiedStatus.loading:
        return '⏳';
      case UnifiedStatus.success:
        return '✅';
      case UnifiedStatus.error:
        return '❌';
      case UnifiedStatus.monitoring:
        return '👁';
      case UnifiedStatus.completed:
        return '🎉';
    }
  }
}
