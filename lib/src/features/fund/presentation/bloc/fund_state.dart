part of 'fund_bloc.dart';

abstract class FundState {
  FundState();

  List<Object?> get props => [];
}

/// 初始状态
class FundInitial extends FundState {}

// 基金列表相关状态
/// 基金列表加载中状态
class FundListLoading extends FundState {
  final bool isRefresh;

  FundListLoading({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// 基金列表加载成功状态
class FundListLoaded extends FundState {
  final List<Fund> fundList;
  final int totalCount;

  FundListLoaded({
    required this.fundList,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [fundList, totalCount];
}

/// 基金列表为空状态
class FundListEmpty extends FundState {}

/// 基金列表加载错误状态
class FundListError extends FundState {
  final String message;
  final FundErrorType errorType;

  FundListError({
    required this.message,
    required this.errorType,
  });

  @override
  List<Object?> get props => [message, errorType];
}

// 基金排名相关状态
/// 基金排名加载中状态
class FundRankingsLoading extends FundState {
  final String symbol;

  FundRankingsLoading(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// 基金排名加载成功状态
class FundRankingsLoaded extends FundState {
  final List<Fund> rankings;
  final String symbol;
  final int totalCount;

  FundRankingsLoaded({
    required this.rankings,
    required this.symbol,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [rankings, symbol, totalCount];
}

/// 基金排名为空状态
class FundRankingsEmpty extends FundState {
  final String symbol;

  FundRankingsEmpty(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// 基金排名加载错误状态
class FundRankingsError extends FundState {
  final String message;
  final String symbol;
  final FundErrorType errorType;

  FundRankingsError({
    required this.message,
    required this.symbol,
    required this.errorType,
  });

  @override
  List<Object?> get props => [message, symbol, errorType];
}

/// 错误类型枚举
enum FundErrorType {
  network, // 网络错误
  parsing, // 数据解析错误
  server, // 服务器错误
  timeout, // 超时错误
  invalidData, // 无效数据
  unknown, // 未知错误
}
