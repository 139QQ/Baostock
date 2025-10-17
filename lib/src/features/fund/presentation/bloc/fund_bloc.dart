import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/fund.dart';
import '../../domain/entities/fund_ranking.dart';
import '../../domain/usecases/get_fund_list.dart';
// ignore: unused_import
import '../../domain/usecases/get_fund_rankings.dart';
import '../fund_exploration/domain/repositories/cache_repository.dart';
import '../fund_exploration/domain/data/repositories/hive_cache_repository.dart';

part 'fund_event.dart';
part 'fund_state.dart';

/// 基金业务逻辑组件
///
/// 负责处理基金相关的业务逻辑，包括：
/// - 获取基金列表
/// - 获取基金排名
/// - 处理基金数据状态管理
class FundBloc extends Bloc<FundEvent, FundState> {
  /// 获取基金列表用例
  final GetFundList getFundList;

  /// 获取基金排名用例
  final GetFundRankings getFundRankings;

  /// 缓存仓储
  final CacheRepository cacheRepository;

  /// 当前正在处理的排名请求symbol
  String? _currentRankingSymbol;

  /// 构造函数
  ///
  /// [getFundList] 获取基金列表的用例实例
  /// [getFundRankings] 获取基金排名的用例实例
  /// [cacheRepository] 缓存仓储实例（可选）
  FundBloc({
    required this.getFundList,
    required this.getFundRankings,
    CacheRepository? cacheRepository,
  })  : cacheRepository = cacheRepository ?? _createDefaultCacheRepository(),
        super(FundInitial()) {
    on<LoadFundList>(_onLoadFundList);
    on<LoadFundRankings>(_onLoadFundRankings);
    on<LoadFundRankingsSmart>(_onLoadFundRankingsSmart);
    on<RefreshFundRankingsCache>(_onRefreshFundRankingsCache);
  }

  /// 处理加载基金列表事件
  ///
  /// [event] 加载基金列表事件
  /// [emit] 状态发射器，用于发射新的状态
  Future<void> _onLoadFundList(
    LoadFundList event,
    Emitter<FundState> emit,
  ) async {
    // 发射加载状态，区分是否是刷新操作
    emit(FundListLoading(isRefresh: event.forceRefresh));

    try {
      // 调用用例获取数据
      final funds = await getFundList.call();

      if (funds.isEmpty) {
        // 数据为空时发射空状态
        emit(FundListEmpty());
      } else {
        // 数据加载成功
        emit(FundListLoaded(
          fundList: funds,
          totalCount: funds.length,
        ));
      }
    } catch (e) {
      // 错误处理
      final errorInfo = _handleError(e);
      emit(FundListError(
        message: errorInfo.message,
        errorType: errorInfo.type,
      ));
    }
  }

  /// 处理加载基金排名事件
  ///
  /// [event] 加载基金排名事件，包含symbol参数
  /// [emit] 状态发射器，用于发射新的状态
  Future<void> _onLoadFundRankings(
    LoadFundRankings event,
    Emitter<FundState> emit,
  ) async {
    // 转发到智能加载方法，使用默认参数
    await _handleLoadFundRankingsSmart(
      LoadFundRankingsSmart(
        symbol: event.symbol,
        cacheFirst: false, // 传统加载不使用缓存优先
        backgroundRefresh: false, // 传统加载不后台刷新
      ),
      emit,
    );
  }

  /// 处理智能按需加载基金排名事件
  ///
  /// [event] 智能加载基金排名事件，包含缓存策略参数
  /// [emit] 状态发射器，用于发射新的状态
  Future<void> _onLoadFundRankingsSmart(
    LoadFundRankingsSmart event,
    Emitter<FundState> emit,
  ) async {
    await _handleLoadFundRankingsSmart(event, emit);
  }

  /// 处理刷新基金排名缓存事件
  ///
  /// [event] 刷新缓存事件，支持静默刷新
  /// [emit] 状态发射器，用于发射新的状态
  Future<void> _onRefreshFundRankingsCache(
    RefreshFundRankingsCache event,
    Emitter<FundState> emit,
  ) async {
    try {
      // 如果是静默刷新，不显示加载状态
      if (!event.silentRefresh) {
        emit(FundRankingsLoading(event.symbol));
      }

      // 直接调用API获取最新数据
      final rankingResult = await getFundRankings.call(
        const RankingCriteria(
          rankingType: RankingType.overall,
          rankingPeriod: RankingPeriod.oneYear,
          page: 1,
          pageSize: 100,
        ),
      );
      final funds = rankingResult.rankings
          .map((ranking) => Fund(
                code: ranking.fundCode,
                name: ranking.fundName,
                type: ranking.fundType,
                company: ranking.company,
                manager: '',
                unitNav: ranking.unitNav,
                accumulatedNav: ranking.accumulatedNav,
                dailyReturn: ranking.dailyReturn,
                return1W: ranking.return1W,
                return1M: ranking.return1M,
                return3M: ranking.return3M,
                return6M: ranking.return6M,
                return1Y: ranking.return1Y,
                return2Y: ranking.return2Y,
                return3Y: ranking.return3Y,
                returnYTD: ranking.returnYTD,
                returnSinceInception: ranking.returnSinceInception,
                scale: 0.0,
                riskLevel: '',
                status: 'active',
                date: ranking.rankingDate.toIso8601String(),
                fee: 0.0,
                rankingPosition: ranking.rankingPosition,
                totalCount: ranking.totalCount,
                currentPrice: ranking.unitNav,
                dailyChange: ranking.dailyReturn,
                dailyChangePercent: ranking.dailyReturn * 100,
                lastUpdate: ranking.rankingDate,
              ))
          .toList();

      // 更新缓存（这里需要集成缓存系统）
      // await _updateFundRankingsCache(event.symbol, funds);

      if (!event.silentRefresh) {
        if (funds.isEmpty) {
          emit(FundRankingsEmpty(event.symbol));
        } else {
          emit(FundRankingsLoaded(
            rankings: funds,
            symbol: event.symbol,
            totalCount: funds.length,
          ));
        }
      }

      dev.log('✅ 基金排名缓存刷新完成: ${event.symbol}');
    } catch (e) {
      if (!event.silentRefresh) {
        final errorInfo = _handleError(e);
        emit(FundRankingsError(
          message: errorInfo.message,
          symbol: event.symbol,
          errorType: errorInfo.type,
        ));
      }
      dev.log('❌ 基金排名缓存刷新失败: $e');
    }
  }

  /// 核心智能加载逻辑处理
  Future<void> _handleLoadFundRankingsSmart(
    LoadFundRankingsSmart event,
    Emitter<FundState> emit,
  ) async {
    // 记录当前正在处理的请求，用于处理并发请求
    _currentRankingSymbol = event.symbol;

    try {
      if (event.cacheFirst) {
        // 缓存优先策略：先尝试从缓存获取
        dev.log('🔄 尝试从缓存获取基金排名: ${event.symbol}');

        // 缓存优先策略：先尝试从缓存获取
        final cachedData = await _getCachedFundRankings(event.symbol);
        if (cachedData != null && cachedData.isNotEmpty) {
          dev.log('✅ 从缓存获取基金排名成功: ${event.symbol}, 共 ${cachedData.length} 条');

          emit(FundRankingsLoaded(
            rankings: cachedData,
            symbol: event.symbol,
            totalCount: cachedData.length,
          ));

          // 后台静默刷新
          if (event.backgroundRefresh) {
            _refreshFundRankingsInBackground(event.symbol);
          }

          return;
        }

        dev.log('⚠️ 缓存未命中，从API获取: ${event.symbol}');
      }

      // 发射加载状态，携带symbol参数
      emit(FundRankingsLoading(event.symbol));

      // 调用用例获取数据
      final funds = await _getFundsFromRanking();

      // 检查是否是当前请求（防止并发请求导致的状态混乱）
      if (_currentRankingSymbol != event.symbol) {
        dev.log('忽略已过时的排名请求: ${event.symbol}');
        return;
      }

      if (funds.isEmpty) {
        // 数据为空时发射空状态
        emit(FundRankingsEmpty(event.symbol));
      } else {
        // 数据加载成功
        emit(FundRankingsLoaded(
          rankings: funds,
          symbol: event.symbol,
          totalCount: funds.length,
        ));

        // 更新缓存
        await _cacheFundRankings(event.symbol, funds);
      }
    } catch (e) {
      // 检查是否是当前请求
      if (_currentRankingSymbol != event.symbol) {
        dev.log('忽略已过时的排名请求错误: ${event.symbol}');
        return;
      }

      // 错误处理
      final errorInfo = _handleError(e);
      emit(FundRankingsError(
        message: errorInfo.message,
        symbol: event.symbol,
        errorType: errorInfo.type,
      ));
    } finally {
      // 清除当前请求标识（如果是最后一个请求）
      if (_currentRankingSymbol == event.symbol) {
        _currentRankingSymbol = null;
      }
    }
  }

  /// 从缓存获取基金排名数据
  Future<List<Fund>?> _getCachedFundRankings(String symbol) async {
    try {
      final cachedData = await cacheRepository.getCachedFundRankings(symbol);

      if (cachedData != null && cachedData.isNotEmpty) {
        // 转换缓存数据为Fund对象列表（使用与API一致的中文字段名）
        final funds = cachedData
            .map((data) => Fund(
                  code: data['基金代码'] ?? '',
                  name: data['基金简称'] ?? '',
                  type: _determineFundType(data['基金简称']?.toString() ?? ''),
                  company: data['公司名称'] ?? '',
                  manager: '', // 缓存中可能没有基金经理信息
                  unitNav: (data['单位净值'] ?? 0).toDouble(),
                  accumulatedNav: (data['累计净值'] ?? 0).toDouble(),
                  dailyReturn: (data['日增长率'] ?? 0).toDouble(),
                  return1W: (data['近1周'] ?? 0).toDouble(),
                  return1M: (data['近1月'] ?? 0).toDouble(),
                  return3M: (data['近3月'] ?? 0).toDouble(),
                  return6M: (data['近6月'] ?? 0).toDouble(),
                  return1Y: (data['近1年'] ?? 0).toDouble(),
                  return2Y: (data['近2年'] ?? 0).toDouble(),
                  return3Y: (data['近3年'] ?? 0).toDouble(),
                  returnYTD: (data['今年来'] ?? 0).toDouble(),
                  returnSinceInception: (data['成立来'] ?? 0).toDouble(),
                  scale: 0, // 缓存中可能没有规模信息
                  riskLevel: '', // 缓存中可能没有风险等级
                  status: 'active', // 默认状态
                  date: data['日期'] ?? DateTime.now().toIso8601String(),
                  fee: (data['手续费'] ?? 0).toDouble(),
                  rankingPosition: data['序号'] ?? 0,
                  totalCount: data['总数'] ?? 0,
                  lastUpdate: DateTime.now(), // 必需参数
                ))
            .toList();

        dev.log('✅ 从缓存获取基金排名成功: $symbol, 共 ${funds.length} 条');
        return funds;
      }

      return null;
    } catch (e) {
      dev.log('⚠️ 获取缓存失败: $e');
      return null;
    }
  }

  /// 缓存基金排名数据
  Future<void> _cacheFundRankings(String symbol, List<Fund> funds) async {
    try {
      final rankingsData = funds
          .map((fund) => {
                '基金代码': fund.code,
                '基金简称': fund.name,
                '基金类型': fund.type,
                '公司名称': fund.company,
                '单位净值': fund.unitNav,
                '累计净值': fund.accumulatedNav,
                '日增长率': fund.dailyReturn,
                '近1周': fund.return1W,
                '近1月': fund.return1M,
                '近3月': fund.return3M,
                '近6月': fund.return6M,
                '近1年': fund.return1Y,
                '近2年': fund.return2Y,
                '近3年': fund.return3Y,
                '今年来': fund.returnYTD,
                '成立来': fund.returnSinceInception,
                '日期': fund.date,
                '手续费': fund.fee,
                '序号': fund.rankingPosition,
                '总数': fund.totalCount,
              })
          .toList();

      await cacheRepository.cacheFundRankings(symbol, rankingsData,
          ttl: const Duration(minutes: 30));
      dev.log('✅ 基金排名缓存成功: $symbol, 共 ${funds.length} 条');
    } catch (e) {
      dev.log('⚠️ 缓存基金排名失败: $e');
    }
  }

  /// 后台静默刷新基金排名
  Future<void> _refreshFundRankingsInBackground(String symbol) async {
    try {
      dev.log('🔄 后台静默刷新基金排名: $symbol');
      final funds = await _getFundsFromRanking();
      await _cacheFundRankings(symbol, funds);
      dev.log('✅ 后台静默刷新完成: $symbol');
    } catch (e) {
      dev.log('⚠️ 后台静默刷新失败: $e');
    }
  }

  /// 从排行榜数据获取Fund列表
  Future<List<Fund>> _getFundsFromRanking() async {
    final rankingResult = await getFundRankings.call(
      const RankingCriteria(
        rankingType: RankingType.overall,
        rankingPeriod: RankingPeriod.oneYear,
        page: 1,
        pageSize: 100,
      ),
    );

    return rankingResult.rankings
        .map((ranking) => Fund(
              code: ranking.fundCode,
              name: ranking.fundName,
              type: ranking.fundType,
              company: ranking.company,
              manager: '',
              unitNav: ranking.unitNav,
              accumulatedNav: ranking.accumulatedNav,
              dailyReturn: ranking.dailyReturn,
              return1W: ranking.return1W,
              return1M: ranking.return1M,
              return3M: ranking.return3M,
              return6M: ranking.return6M,
              return1Y: ranking.return1Y,
              return2Y: ranking.return2Y,
              return3Y: ranking.return3Y,
              returnYTD: ranking.returnYTD,
              returnSinceInception: ranking.returnSinceInception,
              scale: 0.0,
              riskLevel: '',
              status: 'active',
              date: ranking.rankingDate.toIso8601String(),
              fee: 0.0,
              rankingPosition: ranking.rankingPosition,
              totalCount: ranking.totalCount,
              currentPrice: ranking.unitNav,
              dailyChange: ranking.dailyReturn,
              dailyChangePercent: ranking.dailyReturn * 100,
              lastUpdate: ranking.rankingDate,
            ))
        .toList();
  }

  /// 根据基金简称判断基金类型
  static String _determineFundType(String fundName) {
    if (fundName.contains('混合')) return '混合型';
    if (fundName.contains('股票')) return '股票型';
    if (fundName.contains('债券')) return '债券型';
    if (fundName.contains('指数')) return '指数型';
    if (fundName.contains('QDII')) return 'QDII';
    if (fundName.contains('货币')) return '货币型';
    return '混合型'; // 默认类型
  }

  /// 创建默认的缓存仓储实例
  static CacheRepository _createDefaultCacheRepository() {
    return HiveCacheRepository();
  }

  /// 错误处理工具方法
  _ErrorInfo _handleError(dynamic error) {
    if (error is DioException) {
      dev.log('网络请求错误: ${error.message}, 类型: ${error.type}');

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return _ErrorInfo(
            message: '请求超时，请稍后重试',
            type: FundErrorType.timeout,
          );
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return _ErrorInfo(
            message: '网络连接错误，请检查网络设置',
            type: FundErrorType.network,
          );
        case DioExceptionType.badResponse:
          return _ErrorInfo(
            message: '服务器错误 (${error.response?.statusCode})',
            type: FundErrorType.server,
          );
        default:
          return _ErrorInfo(
            message: '请求失败: ${error.message}',
            type: FundErrorType.unknown,
          );
      }
    } else if (error is FormatException) {
      dev.log('数据解析错误: ${error.message}');
      return _ErrorInfo(
        message: '数据格式错误',
        type: FundErrorType.parsing,
      );
    } else if (error is ArgumentError) {
      dev.log('参数错误: ${error.message}');
      return _ErrorInfo(
        message: '无效的请求参数',
        type: FundErrorType.invalidData,
      );
    } else {
      dev.log('未知错误: ${error.toString()}');
      return _ErrorInfo(
        message: '加载失败: ${error.toString()}',
        type: FundErrorType.unknown,
      );
    }
  }
}

/// 错误信息封装类
class _ErrorInfo {
  final String message;
  final FundErrorType type;

  _ErrorInfo({required this.message, required this.type});
}

/// 用例返回结果封装类
class FundResult {
  final List<Fund> funds;
  final int totalCount;

  FundResult({required this.funds, required this.totalCount});
}
