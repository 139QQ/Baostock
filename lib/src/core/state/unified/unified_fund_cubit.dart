import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// 基础实体导入
import '../../../features/fund/domain/entities/fund_ranking.dart';

// 缓存相关导入
import '../../../features/fund/presentation/fund_exploration/domain/repositories/cache_repository.dart';
import '../../../features/fund/presentation/fund_exploration/domain/data/repositories/hive_cache_repository.dart';

part 'unified_fund_state.dart';
part 'unified_fund_event.dart';

// 临时的用例类定义
class GetFundList {
  Future<List<Fund>> execute() async {
    // 临时的实现
    return [];
  }
}

class GetFundRankings {
  Future<List<FundRanking>> execute({String? symbol}) async {
    // 临时的实现
    return [];
  }
}

// 临时的基金净值数据管理器
class FundNavDataManager {
  final Map<String, FundNavData> _navData = {};

  void updateNavData(String fundCode, FundNavData navData) {
    _navData[fundCode] = navData;
  }

  FundNavData? getNavData(String code) {
    return _navData[code];
  }

  Map<String, FundNavData> getAllNavData() {
    return Map.unmodifiable(_navData);
  }

  Future<void> loadNavData(List<String> fundCodes) async {
    // 临时的实现
  }

  void startRealtimeMonitoring() {
    // 临时的实现
  }

  void stopRealtimeMonitoring() {
    // 临时的实现
  }

  void startRealtimeMonitoringForFund(String code) {
    // 临时的实现
  }

  void stopRealtimeMonitoringForFund(String code) {
    // 临时的实现
  }

  bool isRealtimeMonitoring(String code) {
    return false;
  }
}

/// 统一基金状态管理Cubit
class UnifiedFundCubit extends Bloc<UnifiedFundEvent, UnifiedFundState> {
  /// 获取基金列表用例
  final GetFundList getFundList;

  /// 获取基金排名用例
  final GetFundRankings getFundRankings;

  /// 缓存仓储
  final CacheRepository cacheRepository;

  /// 基金净值数据管理器
  final FundNavDataManager _navDataManager;

  /// 当前正在处理的排名请求symbol
  String? _currentRankingSymbol;

  /// 创建默认缓存仓储
  static CacheRepository _createDefaultCacheRepository() {
    return HiveCacheRepository();
  }

  /// 构造函数
  UnifiedFundCubit({
    GetFundList? getFundList,
    GetFundRankings? getFundRankings,
    CacheRepository? cacheRepository,
  })  : getFundList = getFundList ?? GetFundList(),
        getFundRankings = getFundRankings ?? GetFundRankings(),
        cacheRepository = cacheRepository ?? _createDefaultCacheRepository(),
        _navDataManager = FundNavDataManager(),
        super(const UnifiedFundInitial()) {
    // 注册事件处理器
    on<LoadFundList>(_onLoadFundList);
    on<LoadFundRankings>(_onLoadFundRankings);
    on<LoadFundRankingsSmart>(_onLoadFundRankingsSmart);
    on<RefreshFundRankingsCache>(_onRefreshFundRankingsCache);
    on<UpdateFundNavData>(_onUpdateFundNavData);
    on<LoadFundNavData>(_onLoadFundNavData);
    on<StartRealtimeMonitoring>(_onStartRealtimeMonitoring);
    on<StopRealtimeMonitoring>(_onStopRealtimeMonitoring);
    on<UpdateUserPreferences>(_onUpdateUserPreferences);
  }

  // --- 事件处理器 ---

  void _onLoadFundList(
      LoadFundList event, Emitter<UnifiedFundState> emit) async {
    emit(const UnifiedFundLoading());

    try {
      final funds = await getFundList.execute();

      emit(UnifiedFundLoaded(
        funds: funds,
        rankings: const [],
        navData: const {},
        userPreferences: const {},
        status: UnifiedStatus.success,
        lastUpdate: DateTime.now(),
      ));

      // 如果需要，触发基金排名加载
      if (event.loadRankings) {
        add(const LoadFundRankings());
      }
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onLoadFundRankings(
      LoadFundRankings event, Emitter<UnifiedFundState> emit) async {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    try {
      _currentRankingSymbol = event.symbol ?? '';

      final rankings = await getFundRankings.execute(symbol: event.symbol);

      emit(UnifiedFundLoaded(
        funds: currentState.funds,
        rankings: rankings,
        navData: currentState.navData,
        userPreferences: currentState.userPreferences,
        status: UnifiedStatus.success,
        lastUpdate: DateTime.now(),
      ));
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onLoadFundRankingsSmart(
      LoadFundRankingsSmart event, Emitter<UnifiedFundState> emit) async {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    try {
      // 智能排名加载逻辑
      final rankings = await _smartLoadRankings();

      emit(currentState.copyWith(
        rankings: rankings,
        status: UnifiedStatus.success,
        lastUpdate: DateTime.now(),
      ));
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onRefreshFundRankingsCache(
      RefreshFundRankingsCache event, Emitter<UnifiedFundState> emit) async {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    try {
      // 刷新缓存中的排名数据
      await _refreshRankingCache();

      emit(currentState.copyWith(
        status: UnifiedStatus.success,
        lastUpdate: DateTime.now(),
      ));
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onUpdateFundNavData(
      UpdateFundNavData event, Emitter<UnifiedFundState> emit) {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    try {
      _navDataManager.updateNavData(event.fundCode, event.navData);

      emit(currentState.copyWith(
        navData: _navDataManager.getAllNavData(),
        status: UnifiedStatus.success,
        lastUpdate: DateTime.now(),
      ));
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onLoadFundNavData(
      LoadFundNavData event, Emitter<UnifiedFundState> emit) async {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    try {
      await _navDataManager.loadNavData(event.fundCodes);

      emit(currentState.copyWith(
        navData: _navDataManager.getAllNavData(),
        status: UnifiedStatus.success,
        lastUpdate: DateTime.now(),
      ));
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onStartRealtimeMonitoring(
      StartRealtimeMonitoring event, Emitter<UnifiedFundState> emit) {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    try {
      _navDataManager.startRealtimeMonitoring();

      emit(currentState.copyWith(
        status: UnifiedStatus.monitoring,
        lastUpdate: DateTime.now(),
      ));
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onStopRealtimeMonitoring(
      StopRealtimeMonitoring event, Emitter<UnifiedFundState> emit) {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    try {
      _navDataManager.stopRealtimeMonitoring();

      emit(currentState.copyWith(
        status: UnifiedStatus.idle,
        lastUpdate: DateTime.now(),
      ));
    } catch (error) {
      emit(UnifiedFundError(
        error: error.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onUpdateUserPreferences(
      UpdateUserPreferences event, Emitter<UnifiedFundState> emit) {
    final currentState = state;

    if (currentState is! UnifiedFundLoaded) return;

    emit(currentState.copyWith(
      userPreferences: event.preferences,
      status: UnifiedStatus.success,
      lastUpdate: DateTime.now(),
    ));
  }

  // --- 私有方法 ---

  Future<List<FundRanking>> _smartLoadRankings() async {
    // 智能排名加载逻辑
    // 基于当前状态和用户偏好决定加载策略

    if (_currentRankingSymbol != null && _currentRankingSymbol!.isNotEmpty) {
      return await getFundRankings.execute(symbol: _currentRankingSymbol!);
    }

    // 默认加载热门排名
    return await getFundRankings.execute();
  }

  Future<void> _refreshRankingCache() async {
    // 刷新缓存中的排名数据
    await cacheRepository.clearCache(CacheKeys.fundRankings);

    // 重新加载当前排名
    if (_currentRankingSymbol != null) {
      final rankings =
          await getFundRankings.execute(symbol: _currentRankingSymbol!);
      // 简化实现：转换为通用数据格式
      final rankingsData = rankings.map((r) => {'code': 'ranking'}).toList();
      await cacheRepository.cacheFundRankings(
        _currentRankingSymbol!,
        rankingsData,
      );
    }
  }

  // --- 公共方法 ---

  /// 更新用户偏好
  void updateUserPreferences(Map<String, dynamic> preferences) {
    add(UpdateUserPreferences(preferences));
  }
}
