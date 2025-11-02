import 'dart:async';
import 'dart:math' as math;
import 'package:decimal/decimal.dart';
import '../models/fund_info.dart';
import 'fund_analysis_service.dart';
import 'high_performance_fund_service.dart';
import '../core/cache/unified_hive_cache_manager.dart';

/// 投资组合分析服务
///
/// 职责：
/// - 投资组合构建和优化
/// - 资产配置分析
/// - 风险分散度计算
/// - 组合收益模拟
class PortfolioAnalysisService {
  static final PortfolioAnalysisService _instance =
      PortfolioAnalysisService._internal();
  factory PortfolioAnalysisService() => _instance;
  PortfolioAnalysisService._internal();

  final FundAnalysisService _analysisService = FundAnalysisService();
  final HighPerformanceFundService _fundService = HighPerformanceFundService();
  final UnifiedHiveCacheManager _cacheManager =
      UnifiedHiveCacheManager.instance;

  // 缓存配置
  static const String _portfolioCachePrefix = 'portfolio_analysis_';
  static const Duration _analysisCacheExpiry = Duration(hours: 1);

  /// 初始化投资组合分析服务
  Future<void> initialize() async {
    await _analysisService.initialize();
    await _fundService.initialize();
  }

  // ========================================
  // 投资组合构建
  // ========================================

  /// 创建投资组合
  Future<Portfolio> createPortfolio({
    required String name,
    required List<PortfolioHolding> holdings,
    String? description,
    PortfolioStrategy strategy = PortfolioStrategy.balanced,
  }) async {
    try {
      // 验证持有比例总和
      final totalWeight = holdings.fold<double>(0, (sum, h) => sum + h.weight);
      if ((totalWeight - 1.0).abs() > 0.01) {
        throw Exception(
            '持有比例总和必须等于100%，当前为${(totalWeight * 100).toStringAsFixed(2)}%');
      }

      // 计算组合指标
      final metrics = await _calculatePortfolioMetrics(holdings);

      final portfolio = Portfolio(
        id: _generatePortfolioId(),
        name: name,
        description: description,
        holdings: holdings,
        strategy: strategy,
        metrics: metrics,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return portfolio;
    } catch (e) {
      throw Exception('创建投资组合失败: $e');
    }
  }

  /// 优化投资组合权重
  Future<Portfolio> optimizePortfolioWeights({
    required Portfolio portfolio,
    OptimizationGoal goal = OptimizationGoal.maximizeSharpe,
    List<String>? constraints,
  }) async {
    try {
      final optimizedHoldings = await _optimizeWeights(
        portfolio.holdings,
        goal,
        constraints ?? [],
      );

      return await createPortfolio(
        name: '${portfolio.name} (优化版)',
        holdings: optimizedHoldings,
        description: '基于${goal.name}目标优化',
        strategy: portfolio.strategy,
      );
    } catch (e) {
      throw Exception('优化投资组合失败: $e');
    }
  }

  // ========================================
  // 投资组合分析
  // ========================================

  /// 计算投资组合指标
  Future<PortfolioMetrics> _calculatePortfolioMetrics(
      List<PortfolioHolding> holdings) async {
    if (holdings.isEmpty) {
      throw Exception('投资组合不能为空');
    }

    try {
      double totalExpectedReturn = 0;
      double totalVolatility = 0;
      double maxDrawdown = 0;
      double beta = 0;
      double sharpeRatio = 0;

      // 获取各基金的风险指标
      final riskMetricsList = <FundRiskMetrics>[];
      for (final holding in holdings) {
        final riskMetrics =
            await _analysisService.calculateRiskMetrics(holding.fundCode);
        riskMetricsList.add(riskMetrics);

        totalExpectedReturn += riskMetrics.averageReturn * holding.weight;
        beta += riskMetrics.beta * holding.weight;
        maxDrawdown += riskMetrics.maxDrawdown * holding.weight;
      }

      // 计算组合波动率 (考虑相关性)
      totalVolatility =
          await _calculatePortfolioVolatility(holdings, riskMetricsList);

      // 计算夏普比率
      final riskFreeRate = 0.03;
      sharpeRatio = (totalExpectedReturn - riskFreeRate) / totalVolatility;

      // 计算风险分散度
      final diversificationScore = _calculateDiversificationScore(holdings);

      // 计算集中度风险
      final concentrationRisk = _calculateConcentrationRisk(holdings);

      return PortfolioMetrics(
        totalExpectedReturn: totalExpectedReturn,
        volatility: totalVolatility,
        sharpeRatio: sharpeRatio,
        maxDrawdown: maxDrawdown,
        beta: beta,
        diversificationScore: diversificationScore,
        concentrationRisk: concentrationRisk,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('计算投资组合指标失败: $e');
    }
  }

  /// 计算投资组合波动率 (考虑相关性)
  Future<double> _calculatePortfolioVolatility(
    List<PortfolioHolding> holdings,
    List<FundRiskMetrics> riskMetricsList,
  ) async {
    final n = holdings.length;
    final variance = List.generate(n, (i) => List<double>.filled(n, 0.0));

    // 构建协方差矩阵
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i == j) {
          variance[i][j] =
              math.pow(riskMetricsList[i].volatility, 2).toDouble();
        } else {
          // 假设相关性为0.3 (简化计算)
          final correlation = 0.3;
          variance[i][j] = correlation *
              riskMetricsList[i].volatility *
              riskMetricsList[j].volatility;
        }
      }
    }

    // 计算组合方差: w^T * Σ * w
    double portfolioVariance = 0;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        portfolioVariance +=
            holdings[i].weight * holdings[j].weight * variance[i][j];
      }
    }

    return math.sqrt(portfolioVariance);
  }

  /// 计算风险分散度评分
  double _calculateDiversificationScore(List<PortfolioHolding> holdings) {
    // 基于持有数量和权重分布计算分散度
    final n = holdings.length;
    if (n <= 1) return 0;

    // 计算权重分布的熵
    double entropy = 0;
    for (final holding in holdings) {
      if (holding.weight > 0) {
        entropy -= holding.weight * math.log(holding.weight) / math.ln2;
      }
    }

    // 标准化到0-100分
    final maxEntropy = math.log(n) / math.ln2;
    return (entropy / maxEntropy) * 100;
  }

  /// 计算集中度风险
  double _calculateConcentrationRisk(List<PortfolioHolding> holdings) {
    // 计算赫芬达尔指数 (HHI)
    double hhi = 0;
    for (final holding in holdings) {
      hhi += math.pow(holding.weight * 100, 2);
    }

    // 标准化到0-1，值越大表示集中度越高
    return (hhi - 10000) / 9000; // 假设最大HHI为10000，最小为1000
  }

  // ========================================
  // 权重优化算法
  // ========================================

  /// 优化投资组合权重
  Future<List<PortfolioHolding>> _optimizeWeights(
    List<PortfolioHolding> holdings,
    OptimizationGoal goal,
    List<String> constraints,
  ) async {
    try {
      // 简化的优化算法：等权重或风险平价
      switch (goal) {
        case OptimizationGoal.equalWeight:
          return _createEqualWeightPortfolio(holdings);

        case OptimizationGoal.riskParity:
          return await _createRiskParityPortfolio(holdings);

        case OptimizationGoal.maximizeSharpe:
          return await _createMaxSharpePortfolio(holdings);

        case OptimizationGoal.minimizeVolatility:
          return await _createMinVolatilityPortfolio(holdings);
      }
    } catch (e) {
      throw Exception('权重优化失败: $e');
    }
  }

  /// 创建等权重投资组合
  List<PortfolioHolding> _createEqualWeightPortfolio(
      List<PortfolioHolding> holdings) {
    final equalWeight = 1.0 / holdings.length;

    return holdings
        .map((h) => PortfolioHolding(
              fundCode: h.fundCode,
              fundName: h.fundName,
              weight: equalWeight,
            ))
        .toList();
  }

  /// 创建风险平价投资组合
  Future<List<PortfolioHolding>> _createRiskParityPortfolio(
      List<PortfolioHolding> holdings) async {
    final riskMetricsList = <FundRiskMetrics>[];

    for (final holding in holdings) {
      final riskMetrics =
          await _analysisService.calculateRiskMetrics(holding.fundCode);
      riskMetricsList.add(riskMetrics);
    }

    // 计算风险平价权重
    final totalInvVolatility = riskMetricsList
        .map((rm) => 1.0 / rm.volatility)
        .reduce((a, b) => a + b);

    return holdings.asMap().entries.map((entry) {
      final index = entry.key;
      final holding = entry.value;
      final weight =
          (1.0 / riskMetricsList[index].volatility) / totalInvVolatility;

      return PortfolioHolding(
        fundCode: holding.fundCode,
        fundName: holding.fundName,
        weight: weight,
      );
    }).toList();
  }

  /// 创建最大夏普比率投资组合
  Future<List<PortfolioHolding>> _createMaxSharpePortfolio(
      List<PortfolioHolding> holdings) async {
    // 简化实现：基于夏普比率分配权重
    final scoreList = <double>[];

    for (final holding in holdings) {
      final riskMetrics =
          await _analysisService.calculateRiskMetrics(holding.fundCode);
      scoreList.add(riskMetrics.sharpeRatio);
    }

    final totalScore =
        scoreList.map((s) => math.max(s, 0)).reduce((a, b) => a + b);

    if (totalScore == 0) {
      // 如果所有夏普比率都为负，使用等权重
      return _createEqualWeightPortfolio(holdings);
    }

    return holdings.asMap().entries.map((entry) {
      final index = entry.key;
      final holding = entry.value;
      final weight = math.max(scoreList[index], 0) / totalScore;

      return PortfolioHolding(
        fundCode: holding.fundCode,
        fundName: holding.fundName,
        weight: weight,
      );
    }).toList();
  }

  /// 创建最小波动率投资组合
  Future<List<PortfolioHolding>> _createMinVolatilityPortfolio(
      List<PortfolioHolding> holdings) async {
    // 基于波动率的反比例分配权重
    final volatilities = <double>[];

    for (final holding in holdings) {
      final riskMetrics =
          await _analysisService.calculateRiskMetrics(holding.fundCode);
      volatilities.add(riskMetrics.volatility);
    }

    final totalInvVolatility =
        volatilities.map((v) => 1.0 / v).reduce((a, b) => a + b);

    return holdings.asMap().entries.map((entry) {
      final index = entry.key;
      final holding = entry.value;
      final weight = (1.0 / volatilities[index]) / totalInvVolatility;

      return PortfolioHolding(
        fundCode: holding.fundCode,
        fundName: holding.fundName,
        weight: weight,
      );
    }).toList();
  }

  // ========================================
  // 投资组合模拟
  // ========================================

  /// 模拟投资组合表现
  Future<PortfolioSimulation> simulatePortfolio(
    Portfolio portfolio, {
    int months = 12,
    double initialInvestment = 10000,
    int simulations = 1000,
  }) async {
    try {
      final cacheKey =
          '${_portfolioCachePrefix}simulation_${portfolio.id}_${months}_$simulations';

      // 检查缓存
      final cached = await _cacheManager.get<PortfolioSimulation>(cacheKey);
      if (cached != null) {
        return cached;
      }

      final random = math.Random();
      final simulationResults = <double>[];
      final monthlyReturns = <List<double>>[];

      // 获取各基金的收益率分布
      final fundReturns = <double, double>{}; // mean, std
      for (final holding in portfolio.holdings) {
        final riskMetrics =
            await _analysisService.calculateRiskMetrics(holding.fundCode);
        fundReturns[holding.weight] = riskMetrics.averageReturn;
      }

      // 蒙特卡洛模拟
      for (int sim = 0; sim < simulations; sim++) {
        double currentValue = initialInvestment;
        final returns = <double>[];

        for (int month = 0; month < months; month++) {
          // 生成随机收益率 (简化模型)
          double portfolioReturn = 0;
          for (final holding in portfolio.holdings) {
            final meanReturn = fundReturns[holding.weight] ?? 0;
            final monthlyStd = 0.05; // 假设月度标准差为5%
            final randomReturn =
                meanReturn + (_nextGaussian(random) * monthlyStd);
            portfolioReturn += holding.weight * randomReturn;
          }

          currentValue *= (1 + portfolioReturn / 12); // 年化转月化
          returns.add(portfolioReturn / 12);
        }

        simulationResults.add(currentValue);
        monthlyReturns.add(returns);
      }

      // 计算统计指标
      simulationResults.sort();
      final median = simulationResults[simulations ~/ 2];
      final percentile5 = simulationResults[(simulations * 0.05).floor()];
      final percentile95 = simulationResults[(simulations * 0.95).floor()];
      final mean = simulationResults.reduce((a, b) => a + b) / simulations;

      // 计算VaR (95%置信度)
      final var95 = initialInvestment - percentile5;

      // 计算最大回撤分布
      final maxDrawdowns = <double>[];
      for (final returns in monthlyReturns) {
        double peak = initialInvestment;
        double maxDrawdown = 0;
        double currentValue = initialInvestment;

        for (final monthlyReturn in returns) {
          currentValue *= (1 + monthlyReturn);
          if (currentValue > peak) {
            peak = currentValue;
          } else {
            final drawdown = (peak - currentValue) / peak;
            maxDrawdown = math.max(maxDrawdown, drawdown);
          }
        }
        maxDrawdowns.add(maxDrawdown);
      }
      maxDrawdowns.sort();
      final avgMaxDrawdown =
          maxDrawdowns.reduce((a, b) => a + b) / maxDrawdowns.length;

      final simulation = PortfolioSimulation(
        portfolioId: portfolio.id,
        initialInvestment: initialInvestment,
        months: months,
        simulations: simulations,
        finalValue: median,
        meanValue: mean,
        percentile5: percentile5,
        percentile95: percentile95,
        var95: var95,
        averageMaxDrawdown: avgMaxDrawdown,
        simulatedAt: DateTime.now(),
      );

      // 缓存结果
      await _cacheManager.put(cacheKey, simulation);

      return simulation;
    } catch (e) {
      throw Exception('投资组合模拟失败: $e');
    }
  }

  // ========================================
  // 辅助方法
  // ========================================

  String _generatePortfolioId() {
    return 'portfolio_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  /// 清理分析缓存
  Future<void> clearPortfolioCache() async {
    try {
      // TODO: 实现缓存清理功能
      // await _cacheManager.removeByPattern('$_portfolioCachePrefix*');
    } catch (e) {
      // 忽略清理错误
    }
  }

  /// 关闭服务
  Future<void> dispose() async {
    // 清理资源
  }
}

// ========================================
// 数据模型定义
// ========================================

/// 投资组合
class Portfolio {
  final String id;
  final String name;
  final String? description;
  final List<PortfolioHolding> holdings;
  final PortfolioStrategy strategy;
  final PortfolioMetrics metrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  Portfolio({
    required this.id,
    required this.name,
    this.description,
    required this.holdings,
    required this.strategy,
    required this.metrics,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'holdings': holdings.map((h) => h.toJson()).toList(),
      'strategy': strategy.name,
      'metrics': metrics.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      holdings: (json['holdings'] as List)
          .map((h) => PortfolioHolding.fromJson(h))
          .toList(),
      strategy: PortfolioStrategy.values.firstWhere(
        (s) => s.name == json['strategy'],
        orElse: () => PortfolioStrategy.balanced,
      ),
      metrics: PortfolioMetrics.fromJson(json['metrics']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// 投资组合持仓
class PortfolioHolding {
  final String fundCode;
  final String fundName;
  final double weight; // 权重 (0-1)

  PortfolioHolding({
    required this.fundCode,
    required this.fundName,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'weight': weight,
    };
  }

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      fundCode: json['fundCode'],
      fundName: json['fundName'],
      weight: (json['weight'] ?? 0).toDouble(),
    );
  }
}

/// 投资组合指标
class PortfolioMetrics {
  final double totalExpectedReturn; // 预期收益率
  final double volatility; // 波动率
  final double sharpeRatio; // 夏普比率
  final double maxDrawdown; // 最大回撤
  final double beta; // Beta系数
  final double diversificationScore; // 分散度评分
  final double concentrationRisk; // 集中度风险
  final DateTime calculatedAt; // 计算时间

  PortfolioMetrics({
    required this.totalExpectedReturn,
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.beta,
    required this.diversificationScore,
    required this.concentrationRisk,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalExpectedReturn': totalExpectedReturn,
      'volatility': volatility,
      'sharpeRatio': sharpeRatio,
      'maxDrawdown': maxDrawdown,
      'beta': beta,
      'diversificationScore': diversificationScore,
      'concentrationRisk': concentrationRisk,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory PortfolioMetrics.fromJson(Map<String, dynamic> json) {
    return PortfolioMetrics(
      totalExpectedReturn: (json['totalExpectedReturn'] ?? 0).toDouble(),
      volatility: (json['volatility'] ?? 0).toDouble(),
      sharpeRatio: (json['sharpeRatio'] ?? 0).toDouble(),
      maxDrawdown: (json['maxDrawdown'] ?? 0).toDouble(),
      beta: (json['beta'] ?? 0).toDouble(),
      diversificationScore: (json['diversificationScore'] ?? 0).toDouble(),
      concentrationRisk: (json['concentrationRisk'] ?? 0).toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }
}

/// 投资组合策略
enum PortfolioStrategy {
  conservative('保守型'),
  balanced('平衡型'),
  aggressive('进取型'),
  custom('自定义');

  const PortfolioStrategy(this.displayName);
  final String displayName;
}

/// 优化目标
enum OptimizationGoal {
  equalWeight('等权重'),
  riskParity('风险平价'),
  maximizeSharpe('最大化夏普比率'),
  minimizeVolatility('最小化波动率');

  const OptimizationGoal(this.name);
  final String name;
}

/// 投资组合模拟结果
class PortfolioSimulation {
  final String portfolioId;
  final double initialInvestment;
  final int months;
  final int simulations;
  final double finalValue; // 中位数最终价值
  final double meanValue; // 平均最终价值
  final double percentile5; // 5%分位数
  final double percentile95; // 95%分位数
  final double var95; // 95%置信度VaR
  final double averageMaxDrawdown; // 平均最大回撤
  final DateTime simulatedAt; // 模拟时间

  PortfolioSimulation({
    required this.portfolioId,
    required this.initialInvestment,
    required this.months,
    required this.simulations,
    required this.finalValue,
    required this.meanValue,
    required this.percentile5,
    required this.percentile95,
    required this.var95,
    required this.averageMaxDrawdown,
    required this.simulatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'portfolioId': portfolioId,
      'initialInvestment': initialInvestment,
      'months': months,
      'simulations': simulations,
      'finalValue': finalValue,
      'meanValue': meanValue,
      'percentile5': percentile5,
      'percentile95': percentile95,
      'var95': var95,
      'averageMaxDrawdown': averageMaxDrawdown,
      'simulatedAt': simulatedAt.toIso8601String(),
    };
  }

  factory PortfolioSimulation.fromJson(Map<String, dynamic> json) {
    return PortfolioSimulation(
      portfolioId: json['portfolioId'],
      initialInvestment: (json['initialInvestment'] ?? 0).toDouble(),
      months: json['months'] ?? 0,
      simulations: json['simulations'] ?? 0,
      finalValue: (json['finalValue'] ?? 0).toDouble(),
      meanValue: (json['meanValue'] ?? 0).toDouble(),
      percentile5: (json['percentile5'] ?? 0).toDouble(),
      percentile95: (json['percentile95'] ?? 0).toDouble(),
      var95: (json['var95'] ?? 0).toDouble(),
      averageMaxDrawdown: (json['averageMaxDrawdown'] ?? 0).toDouble(),
      simulatedAt: DateTime.parse(json['simulatedAt']),
    );
  }
}

/// 简单的矩阵类
class Matrix {
  final int rows;
  final int cols;
  final List<List<double>> data;

  Matrix(this.rows, this.cols)
      : data = List.generate(rows, (_) => List.filled(cols, 0.0));

  double operator [](int index) => data[index][index];
  void operator []=(int index, double value) => data[index][index] = value;
}

/// Box-Muller 变换生成正态分布随机数
double _nextGaussian(math.Random random) {
  // Marsaglia polar method
  double s = 0.0;
  double u = 0.0;
  double v = 0.0;

  do {
    u = 2.0 * random.nextDouble() - 1.0;
    v = 2.0 * random.nextDouble() - 1.0;
    s = u * u + v * v;
  } while (s >= 1.0 || s == 0.0);

  final factor = math.sqrt(-2.0 * math.log(s) / s);
  return u * factor;
}
