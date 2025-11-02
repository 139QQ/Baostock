import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/portfolio_analysis_service.dart';
import '../services/fund_analysis_service.dart';
import '../services/high_performance_fund_service.dart';

// 使用 portfolio_analysis_service 中定义的模型类
// Portfolio, PortfolioHolding, PortfolioStrategy, PortfolioMetrics
// PortfolioSimulation, OptimizationGoal

// ========================================
// Events
// ========================================

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

class LoadPortfolios extends PortfolioEvent {}

class CreatePortfolio extends PortfolioEvent {
  final String name;
  final String? description;
  final List<PortfolioHolding> holdings;
  final PortfolioStrategy strategy;

  const CreatePortfolio({
    required this.name,
    this.description,
    required this.holdings,
    this.strategy = PortfolioStrategy.balanced,
  });

  @override
  List<Object?> get props => [name, description, holdings, strategy];
}

class UpdatePortfolio extends PortfolioEvent {
  final String portfolioId;
  final String? name;
  final String? description;
  final List<PortfolioHolding>? holdings;
  final PortfolioStrategy? strategy;

  const UpdatePortfolio({
    required this.portfolioId,
    this.name,
    this.description,
    this.holdings,
    this.strategy,
  });

  @override
  List<Object?> get props =>
      [portfolioId, name, description, holdings, strategy];
}

class DeletePortfolio extends PortfolioEvent {
  final String portfolioId;

  const DeletePortfolio(this.portfolioId);

  @override
  List<Object?> get props => [portfolioId];
}

class OptimizePortfolio extends PortfolioEvent {
  final String portfolioId;
  final OptimizationGoal goal;
  final List<String>? constraints;

  const OptimizePortfolio(
    this.portfolioId, {
    this.goal = OptimizationGoal.maximizeSharpe,
    this.constraints,
  });

  @override
  List<Object?> get props => [portfolioId, goal, constraints];
}

class SimulatePortfolio extends PortfolioEvent {
  final String portfolioId;
  final int months;
  final double initialInvestment;
  final int simulations;

  const SimulatePortfolio(
    this.portfolioId, {
    this.months = 12,
    this.initialInvestment = 10000,
    this.simulations = 1000,
  });

  @override
  List<Object?> get props =>
      [portfolioId, months, initialInvestment, simulations];
}

class AddHolding extends PortfolioEvent {
  final String portfolioId;
  final String fundCode;
  final String fundName;
  final double weight;

  const AddHolding({
    required this.portfolioId,
    required this.fundCode,
    required this.fundName,
    required this.weight,
  });

  @override
  List<Object?> get props => [portfolioId, fundCode, fundName, weight];
}

class RemoveHolding extends PortfolioEvent {
  final String portfolioId;
  final String fundCode;

  const RemoveHolding(this.portfolioId, this.fundCode);

  @override
  List<Object?> get props => [portfolioId, fundCode];
}

class UpdateHoldingWeight extends PortfolioEvent {
  final String portfolioId;
  final String fundCode;
  final double newWeight;

  const UpdateHoldingWeight({
    required this.portfolioId,
    required this.fundCode,
    required this.newWeight,
  });

  @override
  List<Object?> get props => [portfolioId, fundCode, newWeight];
}

class LoadRecommendedFunds extends PortfolioEvent {
  final String fundType;
  final int limit;

  const LoadRecommendedFunds({
    this.fundType = '全部',
    this.limit = 20,
  });

  @override
  List<Object?> get props => [fundType, limit];
}

// ========================================
// States
// ========================================

abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<Portfolio> portfolios;
  final List<FundRecommendation> recommendedFunds;
  final Portfolio? selectedPortfolio;
  final PortfolioSimulation? currentSimulation;

  const PortfolioLoaded({
    required this.portfolios,
    this.recommendedFunds = const [],
    this.selectedPortfolio,
    this.currentSimulation,
  });

  @override
  List<Object?> get props => [
        portfolios,
        recommendedFunds,
        selectedPortfolio,
        currentSimulation,
      ];

  PortfolioLoaded copyWith({
    List<Portfolio>? portfolios,
    List<FundRecommendation>? recommendedFunds,
    Portfolio? selectedPortfolio,
    PortfolioSimulation? currentSimulation,
  }) {
    return PortfolioLoaded(
      portfolios: portfolios ?? this.portfolios,
      recommendedFunds: recommendedFunds ?? this.recommendedFunds,
      selectedPortfolio: selectedPortfolio ?? this.selectedPortfolio,
      currentSimulation: currentSimulation ?? this.currentSimulation,
    );
  }
}

class PortfolioOperationInProgress extends PortfolioState {
  final String operation;
  final PortfolioState previousState;

  const PortfolioOperationInProgress(this.operation, this.previousState);

  @override
  List<Object?> get props => [operation, previousState];
}

class PortfolioError extends PortfolioState {
  final String message;
  final PortfolioEvent? triggeringEvent;

  const PortfolioError(this.message, {this.triggeringEvent});

  @override
  List<Object?> get props => [message, triggeringEvent];
}

// ========================================
// BLoC
// ========================================

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final PortfolioAnalysisService _portfolioService;
  final FundAnalysisService _analysisService;
  final HighPerformanceFundService _fundService;

  List<Portfolio> _portfolios = [];
  List<FundRecommendation> _recommendedFunds = [];

  PortfolioBloc({
    required PortfolioAnalysisService portfolioService,
    required FundAnalysisService analysisService,
    required HighPerformanceFundService fundService,
  })  : _portfolioService = portfolioService,
        _analysisService = analysisService,
        _fundService = fundService,
        super(PortfolioInitial()) {
    on<LoadPortfolios>(_onLoadPortfolios);
    on<CreatePortfolio>(_onCreatePortfolio);
    on<UpdatePortfolio>(_onUpdatePortfolio);
    on<DeletePortfolio>(_onDeletePortfolio);
    on<OptimizePortfolio>(_onOptimizePortfolio);
    on<SimulatePortfolio>(_onSimulatePortfolio);
    on<AddHolding>(_onAddHolding);
    on<RemoveHolding>(_onRemoveHolding);
    on<UpdateHoldingWeight>(_onUpdateHoldingWeight);
    on<LoadRecommendedFunds>(_onLoadRecommendedFunds);
  }

  Future<void> _onLoadPortfolios(
    LoadPortfolios event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(PortfolioLoading());

    try {
      // 这里应该从持久化存储加载投资组合
      // 暂时返回空列表
      _portfolios = [];

      emit(PortfolioLoaded(
        portfolios: _portfolios,
        recommendedFunds: _recommendedFunds,
      ));
    } catch (e) {
      emit(PortfolioError('加载投资组合失败：${e.toString()}'));
    }
  }

  Future<void> _onCreatePortfolio(
    CreatePortfolio event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      final currentState = state as PortfolioLoaded;
      emit(PortfolioOperationInProgress('创建投资组合', currentState));

      // 验证持仓权重
      final totalWeight =
          event.holdings.fold<double>(0, (sum, h) => sum + h.weight);
      if ((totalWeight - 1.0).abs() > 0.01) {
        emit(const PortfolioError('持仓权重总和必须等于100%'));
        emit(currentState);
        return;
      }

      final portfolio = await _portfolioService.createPortfolio(
        name: event.name,
        description: event.description,
        holdings: event.holdings,
        strategy: event.strategy,
      );

      _portfolios.add(portfolio);

      emit(PortfolioLoaded(
        portfolios: List.from(_portfolios),
        recommendedFunds: _recommendedFunds,
        selectedPortfolio: portfolio,
      ));
    } catch (e) {
      if (state is PortfolioOperationInProgress) {
        emit((state as PortfolioOperationInProgress).previousState);
      }
      emit(PortfolioError('创建投资组合失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onUpdatePortfolio(
    UpdatePortfolio event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      final currentState = state as PortfolioLoaded;
      emit(PortfolioOperationInProgress('更新投资组合', currentState));

      final portfolioIndex =
          _portfolios.indexWhere((p) => p.id == event.portfolioId);
      if (portfolioIndex == -1) {
        emit(const PortfolioError('未找到指定投资组合'));
        emit(currentState);
        return;
      }

      final oldPortfolio = _portfolios[portfolioIndex];

      // 构建更新后的投资组合
      final updatedHoldings = event.holdings ?? oldPortfolio.holdings;
      final updatedName = event.name ?? oldPortfolio.name;
      final updatedDescription = event.description ?? oldPortfolio.description;
      final updatedStrategy = event.strategy ?? oldPortfolio.strategy;

      final updatedPortfolio = await _portfolioService.createPortfolio(
        name: updatedName,
        description: updatedDescription,
        holdings: updatedHoldings,
        strategy: updatedStrategy,
      );

      // 保持原有的ID和创建时间
      final finalPortfolio = Portfolio(
        id: oldPortfolio.id,
        name: updatedPortfolio.name,
        description: updatedPortfolio.description,
        holdings: updatedPortfolio.holdings,
        strategy: updatedPortfolio.strategy,
        metrics: updatedPortfolio.metrics,
        createdAt: oldPortfolio.createdAt,
        updatedAt: DateTime.now(),
      );

      _portfolios[portfolioIndex] = finalPortfolio;

      emit(PortfolioLoaded(
        portfolios: List.from(_portfolios),
        recommendedFunds: _recommendedFunds,
        selectedPortfolio: finalPortfolio,
      ));
    } catch (e) {
      if (state is PortfolioOperationInProgress) {
        emit((state as PortfolioOperationInProgress).previousState);
      }
      emit(PortfolioError('更新投资组合失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onDeletePortfolio(
    DeletePortfolio event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      _portfolios.removeWhere((p) => p.id == event.portfolioId);

      final currentState = state as PortfolioLoaded;
      emit(PortfolioLoaded(
        portfolios: List.from(_portfolios),
        recommendedFunds: _recommendedFunds,
        selectedPortfolio:
            currentState.selectedPortfolio?.id == event.portfolioId
                ? null
                : currentState.selectedPortfolio,
      ));
    } catch (e) {
      emit(PortfolioError('删除投资组合失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onOptimizePortfolio(
    OptimizePortfolio event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      final currentState = state as PortfolioLoaded;
      emit(PortfolioOperationInProgress('优化投资组合', currentState));

      final portfolioIndex =
          _portfolios.indexWhere((p) => p.id == event.portfolioId);
      if (portfolioIndex == -1) {
        emit(const PortfolioError('未找到指定投资组合'));
        emit(currentState);
        return;
      }

      final originalPortfolio = _portfolios[portfolioIndex];
      final optimizedPortfolio =
          await _portfolioService.optimizePortfolioWeights(
        portfolio: originalPortfolio,
        goal: event.goal,
        constraints: event.constraints,
      );

      _portfolios[portfolioIndex] = optimizedPortfolio;

      emit(PortfolioLoaded(
        portfolios: List.from(_portfolios),
        recommendedFunds: _recommendedFunds,
        selectedPortfolio: optimizedPortfolio,
      ));
    } catch (e) {
      if (state is PortfolioOperationInProgress) {
        emit((state as PortfolioOperationInProgress).previousState);
      }
      emit(PortfolioError('优化投资组合失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onSimulatePortfolio(
    SimulatePortfolio event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      final currentState = state as PortfolioLoaded;
      final portfolio = _portfolios.firstWhere(
        (p) => p.id == event.portfolioId,
        orElse: () => throw Exception('未找到指定投资组合'),
      );

      final simulation = await _portfolioService.simulatePortfolio(
        portfolio,
        months: event.months,
        initialInvestment: event.initialInvestment,
        simulations: event.simulations,
      );

      emit(currentState.copyWith(currentSimulation: simulation));
    } catch (e) {
      emit(PortfolioError('投资组合模拟失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onAddHolding(
    AddHolding event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      final portfolioIndex =
          _portfolios.indexWhere((p) => p.id == event.portfolioId);
      if (portfolioIndex == -1) {
        emit(const PortfolioError('未找到指定投资组合'));
        return;
      }

      final portfolio = _portfolios[portfolioIndex];
      final newHolding = PortfolioHolding(
        fundCode: event.fundCode,
        fundName: event.fundName,
        weight: event.weight,
      );

      // 调整其他持仓的权重
      final updatedHoldings = <PortfolioHolding>[];
      double remainingWeight = 1.0 - event.weight;

      for (final holding in portfolio.holdings) {
        if (holding.fundCode != event.fundCode) {
          final adjustedWeight = holding.weight * remainingWeight;
          if (adjustedWeight > 0.001) {
            // 忽略太小的持仓
            updatedHoldings.add(PortfolioHolding(
              fundCode: holding.fundCode,
              fundName: holding.fundName,
              weight: adjustedWeight,
            ));
          }
        }
      }

      updatedHoldings.add(newHolding);

      // 更新投资组合
      add(UpdatePortfolio(
        portfolioId: event.portfolioId,
        holdings: updatedHoldings,
      ));
    } catch (e) {
      emit(PortfolioError('添加持仓失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onRemoveHolding(
    RemoveHolding event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      final portfolioIndex =
          _portfolios.indexWhere((p) => p.id == event.portfolioId);
      if (portfolioIndex == -1) {
        emit(const PortfolioError('未找到指定投资组合'));
        return;
      }

      final portfolio = _portfolios[portfolioIndex];
      final updatedHoldings = portfolio.holdings
          .where((h) => h.fundCode != event.fundCode)
          .toList();

      if (updatedHoldings.isEmpty) {
        emit(const PortfolioError('不能删除最后一个持仓'));
        return;
      }

      // 重新分配权重
      final totalWeight =
          updatedHoldings.fold<double>(0, (sum, h) => sum + h.weight);
      if (totalWeight < 1.0) {
        final scaleFactor = 1.0 / totalWeight;
        for (int i = 0; i < updatedHoldings.length; i++) {
          updatedHoldings[i] = PortfolioHolding(
            fundCode: updatedHoldings[i].fundCode,
            fundName: updatedHoldings[i].fundName,
            weight: updatedHoldings[i].weight * scaleFactor,
          );
        }
      }

      // 更新投资组合
      add(UpdatePortfolio(
        portfolioId: event.portfolioId,
        holdings: updatedHoldings,
      ));
    } catch (e) {
      emit(PortfolioError('删除持仓失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onUpdateHoldingWeight(
    UpdateHoldingWeight event,
    Emitter<PortfolioState> emit,
  ) async {
    if (state is! PortfolioLoaded) return;

    try {
      final portfolioIndex =
          _portfolios.indexWhere((p) => p.id == event.portfolioId);
      if (portfolioIndex == -1) {
        emit(const PortfolioError('未找到指定投资组合'));
        return;
      }

      final portfolio = _portfolios[portfolioIndex];
      final updatedHoldings = <PortfolioHolding>[];

      // 更新指定持仓的权重
      for (final holding in portfolio.holdings) {
        if (holding.fundCode == event.fundCode) {
          updatedHoldings.add(PortfolioHolding(
            fundCode: holding.fundCode,
            fundName: holding.fundName,
            weight: event.newWeight,
          ));
        } else {
          // 按比例调整其他持仓
          final remainingWeight = 1.0 - event.newWeight;
          final otherHoldingsTotal = portfolio.holdings
              .where((h) => h.fundCode != event.fundCode)
              .fold<double>(0, (sum, h) => sum + h.weight);

          if (otherHoldingsTotal > 0) {
            final scaleFactor = remainingWeight / otherHoldingsTotal;
            updatedHoldings.add(PortfolioHolding(
              fundCode: holding.fundCode,
              fundName: holding.fundName,
              weight: holding.weight * scaleFactor,
            ));
          }
        }
      }

      // 更新投资组合
      add(UpdatePortfolio(
        portfolioId: event.portfolioId,
        holdings: updatedHoldings,
      ));
    } catch (e) {
      emit(PortfolioError('更新持仓权重失败：${e.toString()}', triggeringEvent: event));
    }
  }

  Future<void> _onLoadRecommendedFunds(
    LoadRecommendedFunds event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      final fundScores = await _analysisService.getRecommendedFunds(
        fundType: event.fundType,
        limit: event.limit,
      );

      _recommendedFunds = fundScores
          .map((score) => FundRecommendation(
                fundCode: score.fundCode,
                fundName: score.fundName,
                fundType: score.fundType,
                score: score.totalScore,
                riskLevel: score.riskLevel,
                sharpeScore: score.sharpeScore,
                volatilityScore: score.volatilityScore,
                returnScore: score.returnScore,
              ))
          .toList();

      if (state is PortfolioLoaded) {
        final currentState = state as PortfolioLoaded;
        emit(currentState.copyWith(
          recommendedFunds: _recommendedFunds,
        ));
      }
    } catch (e) {
      emit(PortfolioError('加载推荐基金失败：${e.toString()}', triggeringEvent: event));
    }
  }

  // 公共访问方法

  List<Portfolio> get portfolios => List.from(_portfolios);

  Portfolio? get selectedPortfolio {
    if (state is PortfolioLoaded) {
      return (state as PortfolioLoaded).selectedPortfolio;
    }
    return null;
  }

  PortfolioSimulation? get currentSimulation {
    if (state is PortfolioLoaded) {
      return (state as PortfolioLoaded).currentSimulation;
    }
    return null;
  }

  List<FundRecommendation> get recommendedFunds => List.from(_recommendedFunds);

  bool get isLoading => state is PortfolioLoading;

  bool get isOperationInProgress => state is PortfolioOperationInProgress;

  bool get hasError => state is PortfolioError;

  String? get errorMessage {
    if (state is PortfolioError) {
      return (state as PortfolioError).message;
    }
    return null;
  }

  /// 提供对投资组合分析服务的访问
  PortfolioAnalysisService get portfolioService => _portfolioService;
}

// 辅助数据模型

class FundRecommendation {
  final String fundCode;
  final String fundName;
  final String fundType;
  final int score;
  final String riskLevel;
  final int sharpeScore;
  final int volatilityScore;
  final int returnScore;

  FundRecommendation({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.score,
    required this.riskLevel,
    required this.sharpeScore,
    required this.volatilityScore,
    required this.returnScore,
  });
}
