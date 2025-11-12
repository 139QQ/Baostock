import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../models/market_change_event.dart';
import '../models/change_category.dart';
import '../models/change_severity.dart';
import '../processors/change_impact_assessor.dart';
import '../services/market_context_analyzer.dart';

/// 影响评估模型
///
/// 量化市场变化的影响程度，提供多维度的评估模型
class ImpactAssessmentModel {
  /// 模型参数
  final ImpactAssessmentParameters _parameters;

  /// 权重配置
  final ImpactWeights _weights;

  /// 历史影响数据（用于模型校准）
  // final List<ImpactHistoryRecord> _historicalData;

  /// 构造函数
  ImpactAssessmentModel({
    ImpactAssessmentParameters? parameters,
    ImpactWeights? weights,
    // List<ImpactHistoryRecord>? historicalData,
  })  : _parameters = parameters ?? ImpactAssessmentParameters(),
        _weights = weights ?? ImpactWeights();
  // _historicalData = historicalData ?? [];

  /// 评估影响程度
  Future<ComprehensiveImpactAssessment> assessImpact({
    required MarketChangeEvent event,
    required ChangeImpact basicImpact,
    MarketBackgroundContext? marketContext,
    Map<String, dynamic>? userProfile,
    Map<String, dynamic>? portfolioData,
  }) async {
    // 计算定量影响评分
    final quantitativeScore = _calculateQuantitativeImpact(
      event,
      basicImpact,
      marketContext,
    );

    // 计算定性影响分析
    final qualitativeAnalysis = _calculateQualitativeImpact(
      event,
      basicImpact,
      marketContext,
      userProfile,
    );

    // 计算投资组合特定影响
    final portfolioImpact = _calculatePortfolioImpact(
      event,
      basicImpact,
      portfolioData,
    );

    // 计算时间维度影响
    final temporalImpact = _calculateTemporalImpact(event, marketContext);

    // 计算风险暴露程度
    final riskExposure = _calculateRiskExposure(
      event,
      basicImpact,
      marketContext,
    );

    // 生成综合影响评分
    final comprehensiveScore = _calculateComprehensiveScore(
      quantitativeScore,
      qualitativeAnalysis,
      portfolioImpact,
      temporalImpact,
      riskExposure,
    );

    // 确定影响级别和置信度
    final impactLevel = _determineImpactLevel(comprehensiveScore);
    final confidence = _calculateAssessmentConfidence(
      quantitativeScore,
      qualitativeAnalysis,
      marketContext,
    );

    // 生成影响建议
    final recommendations = _generateImpactRecommendations(
      event,
      impactLevel,
      portfolioImpact,
      riskExposure,
    );

    return ComprehensiveImpactAssessment(
      eventId: event.id,
      quantitativeScore: quantitativeScore,
      qualitativeAnalysis: qualitativeAnalysis,
      portfolioImpact: portfolioImpact,
      temporalImpact: temporalImpact,
      riskExposure: riskExposure,
      comprehensiveScore: comprehensiveScore,
      impactLevel: impactLevel,
      confidence: confidence,
      recommendations: recommendations,
      assessmentTimestamp: DateTime.now(),
      modelVersion: '1.0.0',
    );
  }

  /// 计算定量影响评分
  QuantitativeImpactScore _calculateQuantitativeImpact(
    MarketChangeEvent event,
    ChangeImpact basicImpact,
    MarketBackgroundContext? marketContext,
  ) {
    // 基础变化幅度评分 (0-30分)
    final magnitudeScore = math.min(30.0, event.changeRate.abs() * 3);

    // 影响范围评分 (0-25分)
    final scopeScore = _calculateScopeScore(basicImpact.impactScope);

    // 市场影响评分 (0-25分)
    final marketScore = _calculateMarketImpactScore(
      event,
      basicImpact.marketImpact,
      marketContext,
    );

    // 用户影响评分 (0-20分)
    final userScore = _calculateUserImpactScore(basicImpact.userImpact);

    // 综合定量评分 (0-100)
    final totalScore = (magnitudeScore + scopeScore + marketScore + userScore)
        .clamp(0.0, 100.0);

    return QuantitativeImpactScore(
      totalScore: totalScore,
      magnitudeScore: magnitudeScore,
      scopeScore: scopeScore,
      marketScore: marketScore,
      userScore: userScore,
      breakdown: ImpactScoreBreakdown(
        magnitudeContribution: magnitudeScore / totalScore,
        scopeContribution: scopeScore / totalScore,
        marketContribution: marketScore / totalScore,
        userContribution: userScore / totalScore,
      ),
    );
  }

  /// 计算定性影响分析
  QualitativeImpactAnalysis _calculateQualitativeImpact(
    MarketChangeEvent event,
    ChangeImpact basicImpact,
    MarketBackgroundContext? marketContext,
    Map<String, dynamic>? userProfile,
  ) {
    // 市场情绪影响
    final sentimentImpact = _assessSentimentImpact(event, marketContext);

    // 行业影响力
    final sectorInfluence = _assessSectorInfluence(event, marketContext);

    // 心理影响
    final psychologicalImpact = _assessPsychologicalImpact(event, userProfile);

    // 战略影响
    final strategicImpact = _assessStrategicImpact(event, basicImpact);

    return QualitativeImpactAnalysis(
      sentimentImpact: sentimentImpact,
      sectorInfluence: sectorInfluence,
      psychologicalImpact: psychologicalImpact,
      strategicImpact: strategicImpact,
      overallQualitativeScore: _calculateQualitativeScore(
        sentimentImpact,
        sectorInfluence,
        psychologicalImpact,
        strategicImpact,
      ),
    );
  }

  /// 计算投资组合特定影响
  PortfolioImpactAssessment _calculatePortfolioImpact(
    MarketChangeEvent event,
    ChangeImpact basicImpact,
    Map<String, dynamic>? portfolioData,
  ) {
    if (portfolioData == null) {
      return PortfolioImpactAssessment(
        totalExposure: 0.0,
        directExposure: 0.0,
        indirectExposure: 0.0,
        affectedHoldings: const [],
        portfolioRiskLevel: PortfolioRiskLevel.low,
        rebalancingRecommendation: RebalancingRecommendation.none,
      );
    }

    // 计算总风险敞口
    final totalExposure = _calculateTotalExposure(event, portfolioData);

    // 计算直接风险敞口
    final directExposure = _calculateDirectExposure(event, portfolioData);

    // 计算间接风险敞口
    final indirectExposure = totalExposure - directExposure;

    // 识别受影响的持仓
    final affectedHoldings = _identifyAffectedHoldings(event, portfolioData);

    // 评估投资组合风险等级
    final portfolioRiskLevel = _assessPortfolioRiskLevel(
      totalExposure,
      directExposure,
      event.severity,
    );

    // 生成再平衡建议
    final rebalancingRecommendation = _generateRebalancingRecommendation(
      portfolioRiskLevel,
      event.category,
      totalExposure,
    );

    return PortfolioImpactAssessment(
      totalExposure: totalExposure,
      directExposure: directExposure,
      indirectExposure: indirectExposure,
      affectedHoldings: affectedHoldings,
      portfolioRiskLevel: portfolioRiskLevel,
      rebalancingRecommendation: rebalancingRecommendation,
    );
  }

  /// 计算时间维度影响
  TemporalImpactAnalysis _calculateTemporalImpact(
    MarketChangeEvent event,
    MarketBackgroundContext? marketContext,
  ) {
    // 短期影响 (1-7天)
    final shortTermImpact = _estimateShortTermImpact(event, marketContext);

    // 中期影响 (1-3个月)
    final mediumTermImpact = _estimateMediumTermImpact(event, marketContext);

    // 长期影响 (3个月以上)
    final longTermImpact = _estimateLongTermImpact(event);

    // 影响持续时间
    final impactDuration = _estimateImpactDuration(event);

    // 影响衰减速度
    final decaySpeed = _calculateImpactDecaySpeed(event);

    return TemporalImpactAnalysis(
      shortTermImpact: shortTermImpact,
      mediumTermImpact: mediumTermImpact,
      longTermImpact: longTermImpact,
      impactDuration: impactDuration,
      decaySpeed: decaySpeed,
      peakImpactTime: _estimatePeakImpactTime(event),
    );
  }

  /// 计算风险暴露程度
  RiskExposureAssessment _calculateRiskExposure(
    MarketChangeEvent event,
    ChangeImpact basicImpact,
    MarketBackgroundContext? marketContext,
  ) {
    // 市场风险暴露
    final marketRiskExposure =
        _calculateMarketRiskExposure(event, marketContext);

    // 流动性风险暴露
    final liquidityRiskExposure =
        _calculateLiquidityRiskExposure(event, marketContext);

    // 信用风险暴露
    final creditRiskExposure =
        _calculateCreditRiskExposure(event, marketContext);

    // 操作风险暴露
    final operationalRiskExposure = _calculateOperationalRiskExposure(event);

    // 综合风险暴露评分
    final overallRiskScore = _calculateOverallRiskScore(
      marketRiskExposure,
      liquidityRiskExposure,
      creditRiskExposure,
      operationalRiskExposure,
    );

    return RiskExposureAssessment(
      marketRiskExposure: marketRiskExposure,
      liquidityRiskExposure: liquidityRiskExposure,
      creditRiskExposure: creditRiskExposure,
      operationalRiskExposure: operationalRiskExposure,
      overallRiskScore: overallRiskScore,
      riskLevel: _determineRiskLevel(overallRiskScore),
    );
  }

  /// 计算综合评分
  double _calculateComprehensiveScore(
    QuantitativeImpactScore quantitative,
    QualitativeImpactAnalysis qualitative,
    PortfolioImpactAssessment portfolio,
    TemporalImpactAnalysis temporal,
    RiskExposureAssessment risk,
  ) {
    // 加权计算综合评分
    var score = 0.0;

    // 定量评分权重 40%
    score += quantitative.totalScore * _weights.quantitativeWeight;

    // 定性分析权重 25%
    score += qualitative.overallQualitativeScore * _weights.qualitativeWeight;

    // 投资组合影响权重 20%
    score += (portfolio.totalExposure * 100) * _weights.portfolioWeight;

    // 时间维度影响权重 10%
    score += temporal.shortTermImpact * _weights.temporalWeight;

    // 风险暴露权重 5%
    score += risk.overallRiskScore * _weights.riskWeight;

    return score.clamp(0.0, 100.0);
  }

  /// 计算影响范围评分
  double _calculateScopeScore(ImpactScope scope) {
    switch (scope) {
      case ImpactScope.market:
        return 25.0;
      case ImpactScope.sector:
        return 18.0;
      case ImpactScope.specific:
        return 10.0;
      case ImpactScope.limited:
        return 5.0;
    }
  }

  /// 计算市场影响评分
  double _calculateMarketImpactScore(
    MarketChangeEvent event,
    MarketImpact marketImpact,
    MarketBackgroundContext? marketContext,
  ) {
    var score = 0.0;

    // 基于市场情绪
    switch (marketImpact.sentiment) {
      case MarketSentiment.bullish:
        score += 8.0;
        break;
      case MarketSentiment.bearish:
        score += 12.0;
        break;
      case MarketSentiment.neutral:
        score += 5.0;
        break;
    }

    // 基于波动性影响
    switch (marketImpact.volatilityImpact) {
      case VolatilityImpact.high:
        score += 10.0;
        break;
      case VolatilityImpact.medium:
        score += 6.0;
        break;
      case VolatilityImpact.low:
        score += 3.0;
        break;
    }

    // 基于置信度
    score += marketImpact.confidenceLevel * 5.0;

    // 基于市场背景
    if (marketContext != null) {
      if (marketContext.marketPerformance.overallScore.abs() > 50) {
        score += 2.0; // 极端市场情况加重影响
      }
    }

    return score.clamp(0.0, 25.0);
  }

  /// 计算用户影响评分
  double _calculateUserImpactScore(UserImpact userImpact) {
    var score = 0.0;

    // 基于风险级别
    switch (userImpact.riskLevel) {
      case ImpactRiskLevel.high:
        score += 15.0;
        break;
      case ImpactRiskLevel.medium:
        score += 10.0;
        break;
      case ImpactRiskLevel.low:
        score += 5.0;
        break;
      case ImpactRiskLevel.minimal:
        score += 2.0;
        break;
      case ImpactRiskLevel.unknown:
        score += 0.0;
        break;
    }

    // 基于影响百分比
    score += math.min(5.0, userImpact.affectedPercentage * 0.5);

    return score.clamp(0.0, 20.0);
  }

  /// 评估情绪影响
  SentimentImpact _assessSentimentImpact(
    MarketChangeEvent event,
    MarketBackgroundContext? marketContext,
  ) {
    if (marketContext == null) {
      return SentimentImpact(
        impact: SentimentImpactLevel.neutral,
        confidence: 0.0,
        factors: const [],
      );
    }

    var impactLevel = SentimentImpactLevel.neutral;
    final factors = <SentimentFactor>[];
    var impactScore = 0.0;

    final sentiment = marketContext.marketSentiment;

    // 基于市场情绪
    if (sentiment.sentiment == MarketSentiment.bearish &&
        event.changeRate < 0) {
      impactScore += 20;
      factors.add(SentimentFactor(
        type: SentimentFactorType.marketSentimentAlignment,
        weight: 0.6,
        description: '负面变化与悲观市场情绪一致',
      ));
    } else if (sentiment.sentiment == MarketSentiment.bullish &&
        event.changeRate > 0) {
      impactScore += 15;
      factors.add(SentimentFactor(
        type: SentimentFactorType.marketSentimentAlignment,
        weight: 0.5,
        description: '正面变化与乐观市场情绪一致',
      ));
    }

    // 基于市场强度
    if (sentiment.marketStrength == MarketStrength.strong) {
      impactScore += 10;
      factors.add(SentimentFactor(
        type: SentimentFactorType.marketStrength,
        weight: 0.3,
        description: '强市场趋势放大情绪影响',
      ));
    }

    // 确定影响级别
    if (impactScore > 25) {
      impactLevel = SentimentImpactLevel.high;
    } else if (impactScore > 15) {
      impactLevel = SentimentImpactLevel.medium;
    } else if (impactScore > 5) {
      impactLevel = SentimentImpactLevel.low;
    }

    return SentimentImpact(
      impact: impactLevel,
      confidence: sentiment.confidence,
      factors: factors,
    );
  }

  /// 评估行业影响力
  SectorInfluenceAssessment _assessSectorInfluence(
    MarketChangeEvent event,
    MarketBackgroundContext? marketContext,
  ) {
    var influenceLevel = SectorInfluenceLevel.low;
    var influenceScore = 0.0;
    final affectedSectors = <String>[];

    if (event.type == MarketChangeType.fundNav) {
      // 基于基金类型判断行业影响
      if (event.entityName.contains('科技') || event.entityName.contains('TMT')) {
        influenceScore += 20;
        affectedSectors.add('科技');
      } else if (event.entityName.contains('金融') ||
          event.entityName.contains('银行')) {
        influenceScore += 15;
        affectedSectors.add('金融');
      } else if (event.entityName.contains('消费') ||
          event.entityName.contains('零售')) {
        influenceScore += 10;
        affectedSectors.add('消费');
      }
    } else if (event.type == MarketChangeType.marketIndex) {
      influenceScore += 25; // 指数变化通常影响多个行业
      affectedSectors.addAll(['科技', '金融', '消费', '医药']);
    }

    // 基于变化严重程度调整
    switch (event.severity) {
      case ChangeSeverity.high:
        influenceScore *= 1.5;
        break;
      case ChangeSeverity.medium:
        influenceScore *= 1.2;
        break;
      case ChangeSeverity.low:
        influenceScore *= 1.0;
        break;
    }

    // 确定影响级别
    if (influenceScore > 30) {
      influenceLevel = SectorInfluenceLevel.high;
    } else if (influenceScore > 20) {
      influenceLevel = SectorInfluenceLevel.medium;
    } else if (influenceScore > 10) {
      influenceLevel = SectorInfluenceLevel.low;
    }

    return SectorInfluenceAssessment(
      influence: influenceLevel,
      score: influenceScore,
      affectedSectors: affectedSectors,
      crossSectorEffects: _identifyCrossSectorEffects(affectedSectors),
    );
  }

  /// 评估心理影响
  PsychologicalImpactAssessment _assessPsychologicalImpact(
    MarketChangeEvent event,
    Map<String, dynamic>? userProfile,
  ) {
    var riskTolerance = RiskToleranceLevel.moderate;
    var experience = ExperienceLevel.intermediate;

    // 解析用户画像
    if (userProfile != null) {
      final tolerance = userProfile['risk_tolerance'] as String?;
      if (tolerance != null) {
        switch (tolerance.toLowerCase()) {
          case 'conservative':
            riskTolerance = RiskToleranceLevel.low;
            break;
          case 'moderate':
            riskTolerance = RiskToleranceLevel.moderate;
            break;
          case 'aggressive':
            riskTolerance = RiskToleranceLevel.high;
            break;
        }
      }

      final exp = userProfile['experience'] as String?;
      if (exp != null) {
        switch (exp.toLowerCase()) {
          case 'beginner':
            experience = ExperienceLevel.novice;
            break;
          case 'intermediate':
            experience = ExperienceLevel.intermediate;
            break;
          case 'expert':
            experience = ExperienceLevel.expert;
            break;
        }
      }
    }

    // 计算心理影响程度
    var psychologicalImpact = 0.0;

    // 基于事件严重程度
    switch (event.severity) {
      case ChangeSeverity.high:
        psychologicalImpact += 30;
        break;
      case ChangeSeverity.medium:
        psychologicalImpact += 20;
        break;
      case ChangeSeverity.low:
        psychologicalImpact += 10;
        break;
    }

    // 基于用户风险承受能力调整
    switch (riskTolerance) {
      case RiskToleranceLevel.low:
        psychologicalImpact *= 1.5;
        break;
      case RiskToleranceLevel.moderate:
        psychologicalImpact *= 1.2;
        break;
      case RiskToleranceLevel.high:
        psychologicalImpact *= 0.8;
        break;
    }

    // 基于投资经验调整
    switch (experience) {
      case ExperienceLevel.novice:
        psychologicalImpact *= 1.3;
        break;
      case ExperienceLevel.intermediate:
        psychologicalImpact *= 1.0;
        break;
      case ExperienceLevel.expert:
        psychologicalImpact *= 0.7;
        break;
    }

    // 确定心理影响级别
    PsychologicalImpactLevel impactLevel;
    if (psychologicalImpact > 35) {
      impactLevel = PsychologicalImpactLevel.high;
    } else if (psychologicalImpact > 25) {
      impactLevel = PsychologicalImpactLevel.medium;
    } else if (psychologicalImpact > 15) {
      impactLevel = PsychologicalImpactLevel.low;
    } else {
      impactLevel = PsychologicalImpactLevel.minimal;
    }

    return PsychologicalImpactAssessment(
      impactLevel: impactLevel,
      stressScore: psychologicalImpact,
      decisionMakingBias: _assessDecisionMakingBias(event, riskTolerance),
      recommendedActions: _generatePsychologicalRecommendations(
        impactLevel,
        riskTolerance,
        experience,
      ),
    );
  }

  /// 评估战略影响
  StrategicImpactAssessment _assessStrategicImpact(
    MarketChangeEvent event,
    ChangeImpact basicImpact,
  ) {
    var strategicLevel = StrategicImpactLevel.tactical;
    var impactScore = 0.0;

    // 基于变化类别判断战略重要性
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        impactScore += 40;
        strategicLevel = StrategicImpactLevel.strategic;
        break;
      case ChangeCategory.trendChange:
        impactScore += 25;
        strategicLevel = StrategicImpactLevel.operational;
        break;
      case ChangeCategory.priceChange:
        impactScore += 10;
        strategicLevel = StrategicImpactLevel.tactical;
        break;
    }

    // 基于影响范围调整
    switch (basicImpact.impactScope) {
      case ImpactScope.market:
        impactScore += 20;
        break;
      case ImpactScope.sector:
        impactScore += 15;
        break;
      case ImpactScope.specific:
        impactScore += 8;
        break;
      case ImpactScope.limited:
        impactScore += 3;
        break;
    }

    // 确定战略调整需求
    var adjustmentNeed = StrategicAdjustmentNeed.none;
    if (impactScore > 50) {
      adjustmentNeed = StrategicAdjustmentNeed.major;
    } else if (impactScore > 30) {
      adjustmentNeed = StrategicAdjustmentNeed.minor;
    }

    return StrategicImpactAssessment(
      impactLevel: strategicLevel,
      score: impactScore,
      timeHorizon: _determineStrategicTimeHorizon(event),
      adjustmentNeed: adjustmentNeed,
      strategicOptions: _generateStrategicOptions(event, strategicLevel),
    );
  }

  /// 计算定性评分
  double _calculateQualitativeScore(
    SentimentImpact sentiment,
    SectorInfluenceAssessment sector,
    PsychologicalImpactAssessment psychological,
    StrategicImpactAssessment strategic,
  ) {
    var score = 0.0;

    // 情绪影响 (25%)
    score += _sentimentImpactToDouble(sentiment.impact) * 0.25;

    // 行业影响 (30%)
    score += (sector.score / 50.0) * 100.0 * 0.30;

    // 心理影响 (25%)
    score += _psychologicalImpactToScore(psychological.impactLevel) * 0.25;

    // 战略影响 (20%)
    score += (strategic.score / 60.0) * 100.0 * 0.20;

    return score.clamp(0.0, 100.0);
  }

  // 辅助方法实现...
  double _sentimentImpactToDouble(SentimentImpactLevel impact) {
    switch (impact) {
      case SentimentImpactLevel.high:
        return 80.0;
      case SentimentImpactLevel.medium:
        return 60.0;
      case SentimentImpactLevel.low:
        return 40.0;
      case SentimentImpactLevel.neutral:
        return 20.0;
    }
  }

  double _psychologicalImpactToScore(PsychologicalImpactLevel impact) {
    switch (impact) {
      case PsychologicalImpactLevel.high:
        return 80.0;
      case PsychologicalImpactLevel.medium:
        return 60.0;
      case PsychologicalImpactLevel.low:
        return 40.0;
      case PsychologicalImpactLevel.minimal:
        return 20.0;
    }
  }

  // 更多辅助方法的实现可以继续添加...

  /// 识别跨行业效应
  List<String> _identifyCrossSectorEffects(List<String> affectedSectors) {
    final effects = <String>[];

    if (affectedSectors.contains('科技') && affectedSectors.contains('金融')) {
      effects.add('金融科技联动效应');
    }
    if (affectedSectors.contains('消费') && affectedSectors.contains('医药')) {
      effects.add('健康消费升级效应');
    }

    return effects;
  }

  /// 估算短期影响
  double _estimateShortTermImpact(
      MarketChangeEvent event, MarketBackgroundContext? marketContext) {
    var impact = event.changeRate.abs() * 10; // 基础影响

    if (marketContext != null) {
      if (marketContext.marketSentiment.sentiment == MarketSentiment.bearish) {
        impact *= 1.5; // 悲观情绪放大短期影响
      }
    }

    return impact.clamp(0.0, 100.0);
  }

  /// 估算中期影响
  double _estimateMediumTermImpact(
      MarketChangeEvent event, MarketBackgroundContext? marketContext) {
    var impact = event.changeRate.abs() * 8; // 中期影响通常小于短期

    if (event.category == ChangeCategory.trendChange) {
      impact *= 1.8; // 趋势变化的中期影响更大
    }

    return impact.clamp(0.0, 100.0);
  }

  /// 估算长期影响
  double _estimateLongTermImpact(MarketChangeEvent event) {
    var impact = event.changeRate.abs() * 5; // 长期影响逐渐减弱

    if (event.category == ChangeCategory.abnormalEvent) {
      impact *= 0.5; // 异常事件长期影响通常较小
    }

    return impact.clamp(0.0, 100.0);
  }

  /// 估算影响持续时间
  Duration _estimateImpactDuration(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return const Duration(days: 7);
      case ChangeCategory.trendChange:
        return const Duration(days: 30);
      case ChangeCategory.priceChange:
        return const Duration(days: 3);
    }
  }

  /// 计算影响衰减速度
  double _calculateImpactDecaySpeed(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return 0.8; // 快速衰减
      case ChangeCategory.trendChange:
        return 0.3; // 缓慢衰减
      case ChangeCategory.priceChange:
        return 0.6; // 中等衰减
    }
  }

  /// 估算峰值影响时间
  Duration _estimatePeakImpactTime(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return const Duration(hours: 24);
      case ChangeCategory.trendChange:
        return const Duration(days: 7);
      case ChangeCategory.priceChange:
        return const Duration(hours: 12);
    }
  }

  /// 计算市场风险暴露
  double _calculateMarketRiskExposure(
      MarketChangeEvent event, MarketBackgroundContext? marketContext) {
    var exposure = event.changeRate.abs();

    if (marketContext != null) {
      exposure *=
          (1.0 + marketContext.volatilityAnalysis.volatilityScore / 10.0);
    }

    return exposure.clamp(0.0, 100.0);
  }

  /// 计算流动性风险暴露
  double _calculateLiquidityRiskExposure(
      MarketChangeEvent event, MarketBackgroundContext? marketContext) {
    var exposure = event.changeRate.abs() * 0.5; // 流动性风险通常较小

    if (event.severity == ChangeSeverity.high) {
      exposure *= 2.0; // 严重事件可能影响流动性
    }

    return exposure.clamp(0.0, 100.0);
  }

  /// 计算信用风险暴露
  double _calculateCreditRiskExposure(
      MarketChangeEvent event, MarketBackgroundContext? marketContext) {
    var exposure = event.changeRate.abs() * 0.3; // 信用风险通常最小

    if (event.entityName.contains('金融') || event.entityName.contains('银行')) {
      exposure *= 3.0; // 金融相关事件的信用风险更大
    }

    return exposure.clamp(0.0, 100.0);
  }

  /// 计算操作风险暴露
  double _calculateOperationalRiskExposure(MarketChangeEvent event) {
    return event.severity == ChangeSeverity.high ? 20.0 : 5.0;
  }

  /// 评估决策制定偏差
  DecisionMakingBias _assessDecisionMakingBias(
      MarketChangeEvent event, RiskToleranceLevel riskTolerance) {
    switch (riskTolerance) {
      case RiskToleranceLevel.low:
        return DecisionMakingBias.lossAversion;
      case RiskToleranceLevel.moderate:
        return DecisionMakingBias.rational;
      case RiskToleranceLevel.high:
        return DecisionMakingBias.overconfidence;
    }
  }

  /// 生成心理建议
  List<String> _generatePsychologicalRecommendations(
    PsychologicalImpactLevel impactLevel,
    RiskToleranceLevel riskTolerance,
    ExperienceLevel experience,
  ) {
    final recommendations = <String>[];

    if (impactLevel == PsychologicalImpactLevel.high) {
      recommendations.add('保持冷静，避免情绪化交易决策');
      recommendations.add('考虑暂停交易，重新评估投资策略');
    }

    if (riskTolerance == RiskToleranceLevel.low) {
      recommendations.add('您的风险承受能力较低，建议保守操作');
    }

    if (experience == ExperienceLevel.novice) {
      recommendations.add('作为新手投资者，建议咨询专业顾问');
    }

    return recommendations;
  }

  /// 确定战略时间范围
  StrategicTimeHorizon _determineStrategicTimeHorizon(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return StrategicTimeHorizon.short;
      case ChangeCategory.trendChange:
        return StrategicTimeHorizon.long;
      case ChangeCategory.priceChange:
        return StrategicTimeHorizon.medium;
    }
  }

  /// 生成战略选项
  List<StrategicOption> _generateStrategicOptions(
      MarketChangeEvent event, StrategicImpactLevel level) {
    final options = <StrategicOption>[];

    if (level == StrategicImpactLevel.strategic) {
      options.add(StrategicOption(
        type: StrategicOptionType.rebalance,
        description: '重新平衡投资组合配置',
        timeframe: '1-3个月',
        expectedOutcome: '降低风险敞口',
      ));
    }

    return options;
  }

  /// 投资组合影响计算方法
  double _calculateTotalExposure(
    MarketChangeEvent event,
    Map<String, dynamic>? portfolioData,
  ) {
    // 简化实现 - 基于事件变化率和投资组合数据
    if (portfolioData == null) return 0.0;

    final portfolioValue = portfolioData['total_value'] as double? ?? 0.0;
    return portfolioValue * (event.changeRate.abs() / 100.0);
  }

  double _calculateDirectExposure(
    MarketChangeEvent event,
    Map<String, dynamic>? portfolioData,
  ) {
    // 简化实现 - 直接相关的风险敞口
    if (portfolioData == null) return 0.0;

    final holdings = portfolioData['holdings'] as List? ?? [];
    var directExposure = 0.0;

    for (final holding in holdings) {
      if (holding['code'] == event.entityId) {
        directExposure += (holding['value'] as double? ?? 0.0) *
            (event.changeRate.abs() / 100.0);
      }
    }

    return directExposure;
  }

  List<String> _identifyAffectedHoldings(
    MarketChangeEvent event,
    Map<String, dynamic>? portfolioData,
  ) {
    if (portfolioData == null) return [];

    final holdings = portfolioData['holdings'] as List? ?? [];
    return holdings
        .where((h) => h['code'] == event.entityId)
        .map((h) => h['code'] as String)
        .toList();
  }

  PortfolioRiskLevel _assessPortfolioRiskLevel(
    double totalExposure,
    double directExposure,
    ChangeSeverity severity,
  ) {
    // 基于风险敞口和事件严重程度评估风险等级
    var riskScore = totalExposure;

    switch (severity) {
      case ChangeSeverity.high:
        riskScore *= 2.0;
        break;
      case ChangeSeverity.medium:
        riskScore *= 1.5;
        break;
      case ChangeSeverity.low:
        riskScore *= 1.2;
        break;
    }

    if (riskScore > 20.0) return PortfolioRiskLevel.critical;
    if (riskScore > 10.0) return PortfolioRiskLevel.high;
    if (riskScore > 5.0) return PortfolioRiskLevel.medium;
    return PortfolioRiskLevel.low;
  }

  RebalancingRecommendation _generateRebalancingRecommendation(
    PortfolioRiskLevel riskLevel,
    ChangeCategory category,
    double totalExposure,
  ) {
    // 基于风险等级和变化类型生成再平衡建议
    if (riskLevel == PortfolioRiskLevel.critical) {
      return RebalancingRecommendation.aggressive;
    } else if (riskLevel == PortfolioRiskLevel.high) {
      return RebalancingRecommendation.moderate;
    }
    return RebalancingRecommendation.none;
  }

  RiskLevel _determineRiskLevel(double overallRiskScore) {
    if (overallRiskScore > 80.0) {
      return RiskLevel.high;
    } else if (overallRiskScore > 60.0) {
      return RiskLevel.medium;
    }
    return RiskLevel.low;
  }

  double _calculateOverallRiskScore(
    double marketRiskExposure,
    double liquidityRiskExposure,
    double creditRiskExposure,
    double operationalRiskExposure,
  ) {
    return (marketRiskExposure +
            liquidityRiskExposure +
            creditRiskExposure +
            operationalRiskExposure) /
        4.0;
  }

  // 缺失的辅助方法
  ImpactLevel _determineImpactLevel(double score) {
    if (score >= 80.0) {
      return ImpactLevel.critical;
    } else if (score >= 60.0) {
      return ImpactLevel.significant;
    } else if (score >= 40.0) {
      return ImpactLevel.moderate;
    } else {
      return ImpactLevel.minor;
    }
  }

  double _calculateAssessmentConfidence(
    QuantitativeImpactScore quantitative,
    QualitativeImpactAnalysis qualitative,
    MarketBackgroundContext? marketContext,
  ) {
    var confidence = 0.7; // 基础置信度

    // 基于定量评分调整
    confidence += (quantitative.totalScore / 100.0) * 0.2;

    // 基于定性分析调整
    confidence += (qualitative.overallQualitativeScore / 100.0) * 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  List<ImpactRecommendation> _generateImpactRecommendations(
    MarketChangeEvent event,
    ImpactLevel impactLevel,
    PortfolioImpactAssessment portfolioImpact,
    RiskExposureAssessment riskExposure,
  ) {
    final recommendations = <ImpactRecommendation>[];

    if (impactLevel == ImpactLevel.critical) {
      recommendations.add(ImpactRecommendation(
        type: RecommendationType.immediate,
        description: '立即评估并调整投资组合',
        priority: 'high',
        timeframe: '1-3天',
      ));
    }

    return recommendations;
  }
}

/// 影响评估参数
class ImpactAssessmentParameters {
  /// 置信度阈值
  final double confidenceThreshold;

  /// 历史数据权重
  final double historicalDataWeight;

  /// 实时数据权重
  final double realtimeDataWeight;

  const ImpactAssessmentParameters({
    this.confidenceThreshold = 0.7,
    this.historicalDataWeight = 0.3,
    this.realtimeDataWeight = 0.7,
  });
}

/// 影响权重配置
class ImpactWeights {
  /// 定量评分权重
  final double quantitativeWeight;

  /// 定性分析权重
  final double qualitativeWeight;

  /// 投资组合影响权重
  final double portfolioWeight;

  /// 时间维度影响权重
  final double temporalWeight;

  /// 风险暴露权重
  final double riskWeight;

  const ImpactWeights({
    this.quantitativeWeight = 0.4,
    this.qualitativeWeight = 0.25,
    this.portfolioWeight = 0.2,
    this.temporalWeight = 0.1,
    this.riskWeight = 0.05,
  });
}

/// 投资组合影响评估
class PortfolioImpactAssessment {
  /// 总风险敞口
  final double totalExposure;

  /// 直接风险敞口
  final double directExposure;

  /// 间接风险敞口
  final double indirectExposure;

  /// 受影响的持仓
  final List<String> affectedHoldings;

  /// 投资组合风险等级
  final PortfolioRiskLevel portfolioRiskLevel;

  /// 再平衡建议
  final RebalancingRecommendation rebalancingRecommendation;

  const PortfolioImpactAssessment({
    required this.totalExposure,
    required this.directExposure,
    required this.indirectExposure,
    required this.affectedHoldings,
    required this.portfolioRiskLevel,
    required this.rebalancingRecommendation,
  });
}

/// 风险暴露评估
class RiskExposureAssessment {
  /// 市场风险暴露
  final double marketRiskExposure;

  /// 流动性风险暴露
  final double liquidityRiskExposure;

  /// 信用风险暴露
  final double creditRiskExposure;

  /// 操作风险暴露
  final double operationalRiskExposure;

  /// 综合风险评分
  final double overallRiskScore;

  /// 风险等级
  final RiskLevel riskLevel;

  const RiskExposureAssessment({
    required this.marketRiskExposure,
    required this.liquidityRiskExposure,
    required this.creditRiskExposure,
    required this.operationalRiskExposure,
    required this.overallRiskScore,
    required this.riskLevel,
  });
}

/// 综合影响评估结果
class ComprehensiveImpactAssessment {
  /// 事件ID
  final String eventId;

  /// 定量影响评分
  final QuantitativeImpactScore quantitativeScore;

  /// 定性影响分析
  final QualitativeImpactAnalysis qualitativeAnalysis;

  /// 投资组合影响
  final PortfolioImpactAssessment portfolioImpact;

  /// 时间维度影响
  final TemporalImpactAnalysis temporalImpact;

  /// 风险暴露评估
  final RiskExposureAssessment riskExposure;

  /// 综合评分
  final double comprehensiveScore;

  /// 影响级别
  final ImpactLevel impactLevel;

  /// 置信度
  final double confidence;

  /// 建议
  final List<ImpactRecommendation> recommendations;

  /// 评估时间戳
  final DateTime assessmentTimestamp;

  /// 模型版本
  final String modelVersion;

  const ComprehensiveImpactAssessment({
    required this.eventId,
    required this.quantitativeScore,
    required this.qualitativeAnalysis,
    required this.portfolioImpact,
    required this.temporalImpact,
    required this.riskExposure,
    required this.comprehensiveScore,
    required this.impactLevel,
    required this.confidence,
    required this.recommendations,
    required this.assessmentTimestamp,
    required this.modelVersion,
  });
}

/// 定量影响评分
class QuantitativeImpactScore {
  /// 总评分
  final double totalScore;

  /// 变化幅度评分
  final double magnitudeScore;

  /// 影响范围评分
  final double scopeScore;

  /// 市场影响评分
  final double marketScore;

  /// 用户影响评分
  final double userScore;

  /// 评分分解
  final ImpactScoreBreakdown breakdown;

  const QuantitativeImpactScore({
    required this.totalScore,
    required this.magnitudeScore,
    required this.scopeScore,
    required this.marketScore,
    required this.userScore,
    required this.breakdown,
  });
}

/// 评分分解
class ImpactScoreBreakdown {
  /// 幅度贡献度
  final double magnitudeContribution;

  /// 范围贡献度
  final double scopeContribution;

  /// 市场贡献度
  final double marketContribution;

  /// 用户贡献度
  final double userContribution;

  const ImpactScoreBreakdown({
    required this.magnitudeContribution,
    required this.scopeContribution,
    required this.marketContribution,
    required this.userContribution,
  });
}

/// 定性影响分析
class QualitativeImpactAnalysis {
  /// 情绪影响
  final SentimentImpact sentimentImpact;

  /// 行业影响力
  final SectorInfluenceAssessment sectorInfluence;

  /// 心理影响
  final PsychologicalImpactAssessment psychologicalImpact;

  /// 战略影响
  final StrategicImpactAssessment strategicImpact;

  /// 综合定性评分
  final double overallQualitativeScore;

  const QualitativeImpactAnalysis({
    required this.sentimentImpact,
    required this.sectorInfluence,
    required this.psychologicalImpact,
    required this.strategicImpact,
    required this.overallQualitativeScore,
  });
}

// 更多模型类定义...
class SentimentImpact {
  final SentimentImpactLevel impact;
  final double confidence;
  final List<SentimentFactor> factors;

  const SentimentImpact({
    required this.impact,
    required this.confidence,
    required this.factors,
  });
}

class SentimentFactor {
  final SentimentFactorType type;
  final double weight;
  final String description;

  const SentimentFactor({
    required this.type,
    required this.weight,
    required this.description,
  });
}

// 枚举定义
enum SentimentImpactLevel { high, medium, low, neutral }

enum SentimentFactorType {
  marketSentimentAlignment,
  marketStrength,
  eventSeverity
}

enum SectorInfluenceLevel { high, medium, low }

enum RiskToleranceLevel { low, moderate, high }

enum ExperienceLevel { novice, intermediate, expert }

enum PsychologicalImpactLevel { high, medium, low, minimal }

enum StrategicImpactLevel { strategic, operational, tactical }

enum StrategicAdjustmentNeed { major, minor, none }

enum PortfolioRiskLevel { low, medium, high, critical }

enum RebalancingRecommendation { aggressive, moderate, conservative, none }

/// 影响建议
class ImpactRecommendation {
  /// 建议类型
  final RecommendationType type;

  /// 描述
  final String description;

  /// 优先级
  final String priority;

  /// 时间范围
  final String timeframe;

  const ImpactRecommendation({
    required this.type,
    required this.description,
    required this.priority,
    required this.timeframe,
  });
}

enum RecommendationType { immediate, shortTerm, longTerm }

/// 风险级别
enum RiskLevel { low, medium, high }

/// 决策制定偏差
enum DecisionMakingBias {
  lossAversion, // 损失厌恶
  rational, // 理性
  overconfidence, // 过度自信
}

/// 战略时间范围
enum StrategicTimeHorizon {
  short, // 短期 (1-3个月)
  medium, // 中期 (3-12个月)
  long, // 长期 (1年以上)
}

/// 战略选项类型
enum StrategicOptionType {
  rebalance, // 重新平衡
  diversify, // 分散投资
  hedge, // 对冲
  reduce, // 减少持仓
  increase, // 增加持仓
}

/// 战略选项
class StrategicOption {
  /// 选项类型
  final StrategicOptionType type;

  /// 描述
  final String description;

  /// 时间框架
  final String timeframe;

  /// 预期结果
  final String expectedOutcome;

  const StrategicOption({
    required this.type,
    required this.description,
    required this.timeframe,
    required this.expectedOutcome,
  });
}

/// 行业影响力评估
class SectorInfluenceAssessment {
  /// 影响级别
  final SectorInfluenceLevel influence;

  /// 影响评分
  final double score;

  /// 受影响的行业
  final List<String> affectedSectors;

  /// 跨行业效应
  final List<String> crossSectorEffects;

  const SectorInfluenceAssessment({
    required this.influence,
    required this.score,
    required this.affectedSectors,
    required this.crossSectorEffects,
  });
}

/// 心理影响评估
class PsychologicalImpactAssessment {
  /// 影响级别
  final PsychologicalImpactLevel impactLevel;

  /// 压力评分
  final double stressScore;

  /// 决策制定偏差
  final DecisionMakingBias decisionMakingBias;

  /// 推荐行动
  final List<String> recommendedActions;

  const PsychologicalImpactAssessment({
    required this.impactLevel,
    required this.stressScore,
    required this.decisionMakingBias,
    required this.recommendedActions,
  });
}

/// 战略影响评估
class StrategicImpactAssessment {
  /// 影响级别
  final StrategicImpactLevel impactLevel;

  /// 评分
  final double score;

  /// 时间范围
  final StrategicTimeHorizon timeHorizon;

  /// 调整需求
  final StrategicAdjustmentNeed adjustmentNeed;

  /// 战略选项
  final List<StrategicOption> strategicOptions;

  const StrategicImpactAssessment({
    required this.impactLevel,
    required this.score,
    required this.timeHorizon,
    required this.adjustmentNeed,
    required this.strategicOptions,
  });
}

/// 时间维度影响分析
class TemporalImpactAnalysis {
  /// 短期影响
  final double shortTermImpact;

  /// 中期影响
  final double mediumTermImpact;

  /// 长期影响
  final double longTermImpact;

  /// 影响持续时间
  final Duration impactDuration;

  /// 衰减速度
  final double decaySpeed;

  /// 峰值影响时间
  final Duration peakImpactTime;

  const TemporalImpactAnalysis({
    required this.shortTermImpact,
    required this.mediumTermImpact,
    required this.longTermImpact,
    required this.impactDuration,
    required this.decaySpeed,
    required this.peakImpactTime,
  });
}
