import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../features/fund/domain/entities/fund_ranking.dart';
import '../../features/portfolio/domain/entities/portfolio_holding.dart';

/// 服务接口抽象层 - Story R.2 服务层重构
///
/// 定义清晰的服务契约，支持依赖倒置和测试替换

// ============================================================================
// 基础服务接口
// ============================================================================

/// 基础服务接口
abstract class BaseService {
  /// 获取服务统计信息
  Map<String, dynamic> getServiceStats();

  /// 检查服务健康状态
  Future<bool> checkHealth();

  /// 清理资源
  Future<void> dispose();
}

/// 响应结果基础接口
abstract class ServiceResult<T> {
  bool get isSuccess;
  bool get isFailure;
  T? get data;
  String? get errorMessage;

  T get dataOrThrow;

  ServiceResult<R> map<R>(R Function(T data) mapper);
}

/// 服务结果实现
class ServiceResultImpl<T> implements ServiceResult<T> {
  @override
  final bool isSuccess;
  @override
  final bool isFailure;
  @override
  final T? data;
  @override
  final String? errorMessage;

  const ServiceResultImpl._({
    required this.isSuccess,
    required this.isFailure,
    this.data,
    this.errorMessage,
  });

  factory ServiceResultImpl.success(T data) {
    return ServiceResultImpl._(
      isSuccess: true,
      isFailure: false,
      data: data,
    );
  }

  factory ServiceResultImpl.failure(String errorMessage) {
    return ServiceResultImpl._(
      isSuccess: false,
      isFailure: true,
      errorMessage: errorMessage,
    );
  }

  @override
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(errorMessage ?? '操作失败');
  }

  @override
  ServiceResult<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        if (data == null) {
          return ServiceResultImpl.failure('数据为空');
        }
        return ServiceResultImpl.success(mapper(data as T));
      } catch (e) {
        return ServiceResultImpl.failure('映射失败: $e');
      }
    }
    return ServiceResultImpl.failure(errorMessage ?? '操作失败');
  }
}

// ============================================================================
// 基金数据服务接口
// ============================================================================

/// 基金数据服务接口
abstract class IFundDataService extends BaseService {
  /// 获取基金排行数据
  Future<ServiceResult<List<FundRanking>>> getFundRankings({
    String symbol,
    bool forceRefresh,
    Function(double)? onProgress,
    bool useHighPerformance,
  });

  /// 搜索基金
  Future<ServiceResult<List<FundRanking>>> searchFunds(
    String query, {
    List<FundRanking>? searchIn,
    bool useHighPerformance,
  });

  /// 获取基金详细信息
  Future<ServiceResult<Map<String, dynamic>>> getFundDetail(String fundCode);

  /// 预热缓存
  Future<void> preheatCache();

  /// 清理缓存
  Future<void> clearCache({String? symbol});

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats();
}

/// 基金分析服务接口
abstract class IFundAnalysisService extends BaseService {
  /// 分析基金风险
  Future<ServiceResult<Map<String, dynamic>>> analyzeFundRisk(String fundCode);

  /// 分析基金表现
  Future<ServiceResult<Map<String, dynamic>>> analyzeFundPerformance(
      String fundCode);

  /// 获取基金推荐
  Future<ServiceResult<List<FundRanking>>> getFundRecommendations({
    String riskLevel,
    String investmentType,
    int minAge,
  });
}

// ============================================================================
// 投资组合服务接口
// ============================================================================

/// 投资组合服务接口
abstract class IPortfolioService extends BaseService {
  /// 获取用户持仓
  Future<Either<Failure, List<PortfolioHolding>>> getUserHoldings(
    String userId, {
    bool useCache,
  });

  /// 保存用户持仓
  Future<Either<Failure, Unit>> saveUserHoldings(
    String userId,
    List<PortfolioHolding> holdings,
  );

  /// 添加持仓
  Future<Either<Failure, Unit>> addHolding(
    String userId,
    PortfolioHolding holding,
  );

  /// 移除持仓
  Future<Either<Failure, Unit>> removeHolding(
    String userId,
    String fundCode,
  );

  /// 更新持仓
  Future<Either<Failure, Unit>> updateHolding(
    String userId,
    PortfolioHolding holding,
  );

  /// 计算投资组合收益
  Future<Either<Failure, IPortfolioProfitSummary>> calculatePortfolioProfit(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 获取投资组合分析报告
  Future<Either<Failure, IPortfolioAnalysisReport>> getPortfolioAnalysis(
    String userId,
  );

  /// 从收藏转换到持仓
  Future<Either<Failure, Unit>> convertFavoriteToHolding(
    String userId,
    String fundCode, {
    double? customAmount,
    int? customShares,
  });

  /// 清空用户持仓
  Future<Either<Failure, Unit>> clearUserHoldings(String userId);
}

/// 投资组合收益服务接口
abstract class IPortfolioProfitService extends BaseService {
  /// 获取实时收益
  Future<Either<Failure, Map<String, dynamic>>> getRealTimeProfit(
      String userId);

  /// 获取历史收益
  Future<Either<Failure, List<Map<String, dynamic>>>> getHistoricalProfit(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 计算收益统计
  Future<Either<Failure, Map<String, dynamic>>> calculateProfitStatistics(
    List<PortfolioHolding> holdings,
  );
}

// ============================================================================
// API服务接口
// ============================================================================

/// API服务接口
abstract class IApiService extends BaseService {
  /// GET请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    bool enableRetry,
  });

  /// POST请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    bool enableRetry,
  });

  /// PUT请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    bool enableRetry,
  });

  /// DELETE请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    bool enableRetry,
  });

  /// 测试连通性
  Future<bool> testConnectivity();

  /// 设置基础URL
  void setBaseUrl(String url);

  /// 添加备用URL
  void addFallbackUrl(String url);
}

/// API响应接口
abstract class IApiResponse<T> {
  bool get isSuccess;
  bool get isFailure;
  T? get data;
  String? get errorMessage;
  int? get statusCode;
  Map<String, String>? get headers;
  String? get requestId;

  T get dataOrThrow;

  IApiResponse<R> map<R>(R Function(T data) mapper);
}

/// API响应实现
class ApiResponse<T> implements IApiResponse<T> {
  @override
  final bool isSuccess;
  @override
  final bool isFailure;
  @override
  final T? data;
  @override
  final String? errorMessage;
  @override
  final int? statusCode;
  @override
  final Map<String, String>? headers;
  @override
  final String? requestId;

  const ApiResponse._({
    required this.isSuccess,
    required this.isFailure,
    this.data,
    this.errorMessage,
    this.statusCode,
    this.headers,
    this.requestId,
  });

  factory ApiResponse.success(
    T data, {
    int statusCode = 200,
    Map<String, String>? headers,
    String? requestId,
  }) {
    return ApiResponse._(
      isSuccess: true,
      isFailure: false,
      data: data,
      statusCode: statusCode,
      headers: headers,
      requestId: requestId,
    );
  }

  factory ApiResponse.failure(
    String errorMessage, {
    int statusCode = 400,
    String? requestId,
  }) {
    return ApiResponse._(
      isSuccess: false,
      isFailure: true,
      errorMessage: errorMessage,
      statusCode: statusCode,
      requestId: requestId,
    );
  }

  @override
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(errorMessage ?? '请求失败');
  }

  @override
  ApiResponse<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        if (data == null) {
          return ApiResponse.failure('数据为空', statusCode: statusCode ?? 400);
        }
        return ApiResponse.success(
          mapper(data as T),
          statusCode: statusCode ?? 200,
          headers: headers,
          requestId: requestId,
        );
      } catch (e) {
        return ApiResponse.failure(
          '映射失败: $e',
          statusCode: statusCode ?? 400,
          requestId: requestId,
        );
      }
    }
    return ApiResponse.failure(
      errorMessage ?? '请求失败',
      statusCode: statusCode ?? 400,
      requestId: requestId,
    );
  }
}

// ============================================================================
// 缓存服务接口
// ============================================================================

/// 缓存服务接口
abstract class ICacheService extends BaseService {
  /// 获取缓存数据
  Future<T?> get<T>(String key);

  /// 设置缓存数据
  Future<void> put<T>(
    String key,
    T value, {
    Duration? expiration,
  });

  /// 移除缓存数据
  Future<void> remove(String key);

  /// 清空所有缓存
  Future<void> clear();

  /// 检查缓存是否存在
  Future<bool> containsKey(String key);

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getStats();

  /// 预热缓存
  Future<void> preheat(List<String> keys);
}

// ============================================================================
// 搜索服务接口
// ============================================================================

/// 搜索服务接口
abstract class ISearchService extends BaseService {
  /// 搜索基金
  Future<ServiceResult<List<FundRanking>>> searchFunds(
    String query, {
    int limit,
    List<String>? filters,
  });

  /// 获取搜索建议
  Future<ServiceResult<List<String>>> getSearchSuggestions(String query);

  /// 获取热门搜索
  Future<ServiceResult<List<String>>> getPopularSearches();

  /// 记录搜索历史
  Future<void> recordSearch(String query, List<FundRanking> results);

  /// 获取搜索历史
  Future<ServiceResult<List<String>>> getSearchHistory({int limit});
}

// ============================================================================
// 用户服务接口
// ============================================================================

/// 用户服务接口
abstract class IUserService extends BaseService {
  /// 获取用户信息
  Future<ServiceResult<Map<String, dynamic>>> getUserInfo(String userId);

  /// 更新用户信息
  Future<ServiceResult<Unit>> updateUserInfo(
    String userId,
    Map<String, dynamic> userInfo,
  );

  /// 获取用户偏好设置
  Future<ServiceResult<Map<String, dynamic>>> getUserPreferences(String userId);

  /// 更新用户偏好设置
  Future<ServiceResult<Unit>> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
}

// ============================================================================
// 通知服务接口
// ============================================================================

/// 通知服务接口
abstract class INotificationService extends BaseService {
  /// 发送通知
  Future<ServiceResult<Unit>> sendNotification(
    String userId,
    String title,
    String message, {
    Map<String, dynamic>? data,
  });

  /// 获取通知列表
  Future<ServiceResult<List<Map<String, dynamic>>>> getNotifications(
    String userId, {
    int limit,
    int offset,
  });

  /// 标记通知为已读
  Future<ServiceResult<Unit>> markNotificationAsRead(
    String userId,
    String notificationId,
  );

  /// 订阅通知主题
  Future<ServiceResult<Unit>> subscribeToTopic(
    String userId,
    String topic,
  );

  /// 取消订阅通知主题
  Future<ServiceResult<Unit>> unsubscribeFromTopic(
    String userId,
    String topic,
  );
}

// ============================================================================
// 市场数据服务接口
// ============================================================================

/// 市场数据服务接口
abstract class IMarketDataService extends BaseService {
  /// 获取市场指数
  Future<ServiceResult<List<Map<String, dynamic>>>> getMarketIndices();

  /// 获取实时行情
  Future<ServiceResult<Map<String, dynamic>>> getRealtimeQuote(String symbol);

  /// 获取市场新闻
  Future<ServiceResult<List<Map<String, dynamic>>>> getMarketNews({
    int limit,
  });

  /// 获取经济日历
  Future<ServiceResult<List<Map<String, dynamic>>>> getEconomicCalendar({
    DateTime? startDate,
    DateTime? endDate,
  });
}

// ============================================================================
// 数据模型接口
// ============================================================================

/// 投资组合收益摘要接口
abstract class IPortfolioProfitSummary {
  double get totalInvestment;
  double get currentValue;
  double get totalProfit;
  double get totalProfitRate;
  double get dailyProfit;
  double get dailyProfitRate;
  List<IHoldingProfit> get holdings;
  DateTime? get calculatedAt;

  Map<String, dynamic> toJson();
}

/// 持仓收益接口
abstract class IHoldingProfit {
  String get fundCode;
  String get fundName;
  double get shares;
  double get costPrice;
  double get currentPrice;
  double get investment;
  double get currentValue;
  double get profit;
  double get profitRate;

  Map<String, dynamic> toJson();
}

/// 投资组合分析报告接口
abstract class IPortfolioAnalysisReport {
  double get totalValue;
  int get holdingsCount;
  Map<String, double> get typeDistribution;
  Map<String, double> get companyDistribution;
  IPortfolioProfitSummary? get profitSummary;
  IPortfolioRiskAnalysis get riskAnalysis;
  List<String> get recommendations;
  DateTime get generatedAt;

  Map<String, dynamic> toJson();
}

/// 投资组合风险分析接口
abstract class IPortfolioRiskAnalysis {
  double get totalInvestment;
  double get highRiskAmount;
  double get mediumRiskAmount;
  double get lowRiskAmount;
  double get highRiskPercentage;
  double get mediumRiskPercentage;
  double get lowRiskPercentage;
  double get riskScore;

  Map<String, dynamic> toJson();
}

/// 失败类型基类
abstract class Failure {
  String get message;

  const Failure();
}

/// 具体失败类型
class CacheFailure extends Failure {
  @override
  final String message;
  const CacheFailure(this.message);
}

class NetworkFailure extends Failure {
  @override
  final String message;
  const NetworkFailure(this.message);
}

class ValidationFailure extends Failure {
  @override
  final String message;
  const ValidationFailure(this.message);
}

class BusinessFailure extends Failure {
  @override
  final String message;
  const BusinessFailure(this.message);
}

// ============================================================================
// 推送通知相关类型定义
// ============================================================================

/// 推送统计数据
class PushStatistics {
  final int totalSent;
  final int totalDelivered;
  final int totalOpened;
  final int totalClicked;
  final double deliveryRate;
  final double openRate;
  final double clickRate;
  final DateTime startDate;
  final DateTime endDate;

  const PushStatistics({
    required this.totalSent,
    required this.totalDelivered,
    required this.totalOpened,
    required this.totalClicked,
    required this.deliveryRate,
    required this.openRate,
    required this.clickRate,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_sent': totalSent,
      'total_delivered': totalDelivered,
      'total_opened': totalOpened,
      'total_clicked': totalClicked,
      'delivery_rate': deliveryRate,
      'open_rate': openRate,
      'click_rate': clickRate,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}

/// 用户参与度分析
class UserEngagementAnalysis {
  final Map<String, int> deviceTypeDistribution;
  final Map<String, int> timeOfDayDistribution;
  final Map<String, int> dayOfWeekDistribution;
  final double avgSessionsPerDay;
  final double avgSessionDuration;
  final List<String> mostActiveTimes;
  final List<String> leastActiveTimes;

  const UserEngagementAnalysis({
    required this.deviceTypeDistribution,
    required this.timeOfDayDistribution,
    required this.dayOfWeekDistribution,
    required this.avgSessionsPerDay,
    required this.avgSessionDuration,
    required this.mostActiveTimes,
    required this.leastActiveTimes,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_type_distribution': deviceTypeDistribution,
      'time_of_day_distribution': timeOfDayDistribution,
      'day_of_week_distribution': dayOfWeekDistribution,
      'avg_sessions_per_day': avgSessionsPerDay,
      'avg_session_duration': avgSessionDuration,
      'most_active_times': mostActiveTimes,
      'least_active_times': leastActiveTimes,
    };
  }
}
