import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/fund_analysis_service.dart';
import '../services/fund_api_service.dart';
import '../models/fund_info.dart';

// ========================================
// Events
// ========================================

abstract class FundDetailEvent extends Equatable {
  const FundDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadFundDetail extends FundDetailEvent {
  final String fundCode;

  const LoadFundDetail(this.fundCode);

  @override
  List<Object> get props => [fundCode];
}

class LoadFundAnalysis extends FundDetailEvent {
  final String fundCode;

  const LoadFundAnalysis(this.fundCode);

  @override
  List<Object> get props => [fundCode];
}

class LoadFundRiskMetrics extends FundDetailEvent {
  final String fundCode;
  final int period;

  const LoadFundRiskMetrics(this.fundCode, {this.period = 252});

  @override
  List<Object> get props => [fundCode, period];
}

class LoadTechnicalIndicators extends FundDetailEvent {
  final String fundCode;
  final String indicatorType;
  final int period;

  const LoadTechnicalIndicators(
    this.fundCode, {
    this.indicatorType = 'ma',
    this.period = 20,
  });

  @override
  List<Object> get props => [fundCode, indicatorType, period];
}

class RefreshFundDetail extends FundDetailEvent {
  final String fundCode;

  const RefreshFundDetail(this.fundCode);

  @override
  List<Object> get props => [fundCode];
}

class ToggleFavorite extends FundDetailEvent {
  final String fundCode;

  const ToggleFavorite(this.fundCode);

  @override
  List<Object> get props => [fundCode];
}

// ========================================
// States
// ========================================

abstract class FundDetailState extends Equatable {
  const FundDetailState();

  @override
  List<Object> get props => [];
}

class FundDetailInitial extends FundDetailState {}

class FundDetailLoading extends FundDetailState {
  final String fundCode;

  const FundDetailLoading(this.fundCode);

  @override
  List<Object> get props => [fundCode];
}

class FundDetailLoaded extends FundDetailState {
  final FundInfo fundInfo;
  final FundRankingData? rankingData;
  final FundRiskMetrics? riskMetrics;
  final FundScore? fundScore;
  final Map<String, dynamic> technicalIndicators;
  final bool isFavorite;
  final DateTime lastUpdated;

  const FundDetailLoaded({
    required this.fundInfo,
    this.rankingData,
    this.riskMetrics,
    this.fundScore,
    this.technicalIndicators = const {},
    this.isFavorite = false,
    required this.lastUpdated,
  });

  @override
  List<Object> get props => [
        fundInfo,
        rankingData ?? '',
        riskMetrics ?? '',
        fundScore ?? '',
        technicalIndicators,
        isFavorite,
        lastUpdated,
      ];

  FundDetailLoaded copyWith({
    FundInfo? fundInfo,
    FundRankingData? rankingData,
    FundRiskMetrics? riskMetrics,
    FundScore? fundScore,
    Map<String, dynamic>? technicalIndicators,
    bool? isFavorite,
    DateTime? lastUpdated,
  }) {
    return FundDetailLoaded(
      fundInfo: fundInfo ?? this.fundInfo,
      rankingData: rankingData ?? this.rankingData,
      riskMetrics: riskMetrics ?? this.riskMetrics,
      fundScore: fundScore ?? this.fundScore,
      technicalIndicators: technicalIndicators ?? this.technicalIndicators,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class FundDetailError extends FundDetailState {
  final String message;
  final String fundCode;

  const FundDetailError(this.message, this.fundCode);

  @override
  List<Object> get props => [message, fundCode];
}

class FundDetailNotFound extends FundDetailState {
  final String fundCode;

  const FundDetailNotFound(this.fundCode);

  @override
  List<Object> get props => [fundCode];
}

// ========================================
// BLoC
// ========================================

class FundDetailBloc extends Bloc<FundDetailEvent, FundDetailState> {
  final FundAnalysisService _analysisService;

  Set<String> _favoriteFunds = <String>{};

  FundDetailBloc({
    required FundAnalysisService analysisService,
  })  : _analysisService = analysisService,
        super(FundDetailInitial()) {
    on<LoadFundDetail>(_onLoadFundDetail);
    on<LoadFundAnalysis>(_onLoadFundAnalysis);
    on<LoadFundRiskMetrics>(_onLoadFundRiskMetrics);
    on<LoadTechnicalIndicators>(_onLoadTechnicalIndicators);
    on<RefreshFundDetail>(_onRefreshFundDetail);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onLoadFundDetail(
    LoadFundDetail event,
    Emitter<FundDetailState> emit,
  ) async {
    try {
      emit(FundDetailLoading(event.fundCode));

      // 并行加载基金信息、排行榜数据和风险指标
      final futures = await Future.wait([
        _loadFundInfo(event.fundCode),
        _loadRankingData(event.fundCode),
        _analysisService.calculateRiskMetrics(event.fundCode),
        _analysisService.calculateFundScore(event.fundCode),
      ]);

      final fundInfo = futures[0] as FundInfo?;
      final rankingData = futures[1] as FundRankingData?;
      final riskMetrics = futures[2] as FundRiskMetrics?;
      final fundScore = futures[3] as FundScore?;

      if (fundInfo == null) {
        emit(FundDetailNotFound(event.fundCode));
        return;
      }

      emit(FundDetailLoaded(
        fundInfo: fundInfo,
        rankingData: rankingData,
        riskMetrics: riskMetrics,
        fundScore: fundScore,
        isFavorite: _favoriteFunds.contains(event.fundCode),
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(FundDetailError('加载基金详情失败：${e.toString()}', event.fundCode));
    }
  }

  Future<void> _onLoadFundAnalysis(
    LoadFundAnalysis event,
    Emitter<FundDetailState> emit,
  ) async {
    if (state is! FundDetailLoaded) return;

    try {
      final currentState = state as FundDetailLoaded;

      // 并行加载分析数据
      final futures = await Future.wait([
        _analysisService.calculateRiskMetrics(event.fundCode),
        _analysisService.calculateFundScore(event.fundCode),
        _loadRankingData(event.fundCode),
      ]);

      emit(currentState.copyWith(
        riskMetrics: futures[0] as FundRiskMetrics,
        fundScore: futures[1] as FundScore,
        rankingData: futures[2] as FundRankingData?,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      // 分析数据加载失败，不影响基础信息
      emit(FundDetailError('加载分析数据失败：${e.toString()}', event.fundCode));
    }
  }

  Future<void> _onLoadFundRiskMetrics(
    LoadFundRiskMetrics event,
    Emitter<FundDetailState> emit,
  ) async {
    if (state is! FundDetailLoaded) return;

    try {
      final riskMetrics = await _analysisService.calculateRiskMetrics(
        event.fundCode,
        period: event.period,
      );

      final currentState = state as FundDetailLoaded;
      emit(currentState.copyWith(
        riskMetrics: riskMetrics,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      // 风险指标加载失败，不影响基础信息
      if (state is FundDetailLoaded) {
        final currentState = state as FundDetailLoaded;
        emit(currentState.copyWith(
          lastUpdated: DateTime.now(),
        ));
      }
    }
  }

  Future<void> _onLoadTechnicalIndicators(
    LoadTechnicalIndicators event,
    Emitter<FundDetailState> emit,
  ) async {
    if (state is! FundDetailLoaded) return;

    try {
      final currentState = state as FundDetailLoaded;
      final indicators = <String, dynamic>{};

      switch (event.indicatorType) {
        case 'ma':
          final maData = await _analysisService.calculateMovingAverage(
            event.fundCode,
            period: event.period,
          );
          indicators['ma_${event.period}'] = maData;
          break;

        case 'rsi':
          final rsiData = await _analysisService.calculateRSI(
            event.fundCode,
            period: event.period,
          );
          indicators['rsi_${event.period}'] = rsiData;
          break;

        case 'bb':
          final bbData = await _analysisService.calculateBollingerBands(
            event.fundCode,
            period: event.period,
          );
          indicators['bb_${event.period}'] = bbData;
          break;

        default:
          // 加载所有常用指标
          final futures = await Future.wait([
            _analysisService.calculateMovingAverage(event.fundCode, period: 5),
            _analysisService.calculateMovingAverage(event.fundCode, period: 10),
            _analysisService.calculateMovingAverage(event.fundCode, period: 20),
            _analysisService.calculateRSI(event.fundCode, period: 14),
            _analysisService.calculateBollingerBands(event.fundCode,
                period: 20),
          ]);

          indicators['ma_5'] = futures[0];
          indicators['ma_10'] = futures[1];
          indicators['ma_20'] = futures[2];
          indicators['rsi_14'] = futures[3];
          indicators['bb_20'] = futures[4];
          break;
      }

      final updatedIndicators =
          Map<String, dynamic>.from(currentState.technicalIndicators);
      updatedIndicators.addAll(indicators);

      emit(currentState.copyWith(
        technicalIndicators: updatedIndicators,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      // 技术指标加载失败，不影响基础信息
      emit(FundDetailError('加载技术指标失败：${e.toString()}', event.fundCode));
    }
  }

  Future<void> _onRefreshFundDetail(
    RefreshFundDetail event,
    Emitter<FundDetailState> emit,
  ) async {
    // 重新加载所有数据
    add(LoadFundDetail(event.fundCode));
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FundDetailState> emit,
  ) async {
    if (state is! FundDetailLoaded) return;

    final currentState = state as FundDetailLoaded;

    if (_favoriteFunds.contains(event.fundCode)) {
      _favoriteFunds.remove(event.fundCode);
    } else {
      _favoriteFunds.add(event.fundCode);
    }

    emit(currentState.copyWith(
      isFavorite: _favoriteFunds.contains(event.fundCode),
    ));
  }

  // 私有辅助方法

  Future<FundInfo?> _loadFundInfo(String fundCode) async {
    try {
      // 这里应该调用实际的基金信息API
      // 暂时返回模拟数据
      return FundInfo(
        code: fundCode,
        name: '示例基金 $fundCode',
        type: '混合型',
        pinyinAbbr: 'sljj$fundCode',
        pinyinFull: 'shili jijin $fundCode',
      );
    } catch (e) {
      return null;
    }
  }

  Future<FundRankingData?> _loadRankingData(String fundCode) async {
    try {
      // 这里应该调用实际的排行榜API
      // 暂时返回模拟数据
      final rankings = await FundApiService.getFundRanking();
      for (final ranking in rankings) {
        if (ranking.fundCode == fundCode) {
          return ranking;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 公共访问方法

  FundInfo? get currentFund {
    if (state is FundDetailLoaded) {
      return (state as FundDetailLoaded).fundInfo;
    }
    return null;
  }

  FundRiskMetrics? get currentRiskMetrics {
    if (state is FundDetailLoaded) {
      return (state as FundDetailLoaded).riskMetrics;
    }
    return null;
  }

  FundScore? get currentFundScore {
    if (state is FundDetailLoaded) {
      return (state as FundDetailLoaded).fundScore;
    }
    return null;
  }

  Map<String, dynamic> get currentTechnicalIndicators {
    if (state is FundDetailLoaded) {
      return (state as FundDetailLoaded).technicalIndicators;
    }
    return {};
  }

  bool get isLoading => state is FundDetailLoading;

  bool get hasError => state is FundDetailError;

  bool get isNotFound => state is FundDetailNotFound;

  String? get errorMessage {
    if (state is FundDetailError) {
      return (state as FundDetailError).message;
    }
    return null;
  }

  bool get isFavorite {
    if (state is FundDetailLoaded) {
      return (state as FundDetailLoaded).isFavorite;
    }
    return false;
  }

  String? get currentFundCode {
    if (state is FundDetailLoaded) {
      return (state as FundDetailLoaded).fundInfo.code;
    } else if (state is FundDetailLoading) {
      return (state as FundDetailLoading).fundCode;
    } else if (state is FundDetailError) {
      return (state as FundDetailError).fundCode;
    } else if (state is FundDetailNotFound) {
      return (state as FundDetailNotFound).fundCode;
    }
    return null;
  }
}
