import 'dart:math' as math;

import '../models/market_change_event.dart';
import '../models/change_category.dart';
import '../models/change_severity.dart';
import 'change_impact_assessor.dart';

/// 智能解读生成器
///
/// 负责分析市场变化并生成智能解读和投资建议
class IntelligentInsightGenerator {
  /// 解读生成参数
  final InsightGenerationParameters _parameters;

  /// 投资建议模板
  final List<InvestmentSuggestionTemplate> _suggestionTemplates;

  /// 构造函数
  IntelligentInsightGenerator({
    InsightGenerationParameters? parameters,
    List<InvestmentSuggestionTemplate>? suggestionTemplates,
  })  : _parameters = parameters ?? InsightGenerationParameters(),
        _suggestionTemplates =
            suggestionTemplates ?? _createDefaultSuggestionTemplates();

  /// 生成智能解读
  Future<MarketInsight> generateInsight({
    required MarketChangeEvent event,
    required ChangeImpact impact,
    Map<String, dynamic>? marketContext,
    Map<String, dynamic>? userPortfolio,
  }) async {
    // 分析市场背景
    final marketAnalysis = _analyzeMarketContext(event, marketContext);

    // 生成趋势解读
    final trendAnalysis = _generateTrendAnalysis(event, marketContext);

    // 生成风险评估
    final riskAssessment = _generateRiskAssessment(event, impact);

    // 生成投资建议
    final investmentSuggestions = _generateInvestmentSuggestions(
      event,
      impact,
      userPortfolio,
    );

    // 生成心理影响分析
    final psychologicalImpact = _analyzePsychologicalImpact(event, impact);

    // 生成策略建议
    final strategyRecommendations = _generateStrategyRecommendations(
      event,
      impact,
      userPortfolio,
    );

    return MarketInsight(
      eventId: event.id,
      summary: _generateSummary(event, impact),
      marketAnalysis: marketAnalysis,
      trendAnalysis: trendAnalysis,
      riskAssessment: riskAssessment,
      investmentSuggestions: investmentSuggestions,
      psychologicalImpact: psychologicalImpact,
      strategyRecommendations: strategyRecommendations,
      timeHorizon: _estimateTimeHorizon(event),
      confidenceLevel: _calculateInsightConfidence(event, impact),
      generatedAt: DateTime.now(),
    );
  }

  /// 分析市场背景
  MarketContextAnalysis _analyzeMarketContext(
    MarketChangeEvent event,
    Map<String, dynamic>? marketContext,
  ) {
    var volatilityLevel = VolatilityLevel.low;
    var marketCondition = MarketCondition.normal;
    var sectorInfluence = SectorInfluence.moderate;

    // 基于事件类型判断市场背景
    if (marketContext != null) {
      // 分析波动性
      final volatility = marketContext['volatility'] as double?;
      if (volatility != null) {
        if (volatility > 0.25) {
          volatilityLevel = VolatilityLevel.high;
        } else if (volatility > 0.15) {
          volatilityLevel = VolatilityLevel.medium;
        }
      }

      // 分析市场状况
      final marketTrend = marketContext['market_trend'] as String?;
      if (marketTrend != null) {
        switch (marketTrend.toLowerCase()) {
          case 'bull':
            marketCondition = MarketCondition.bullish;
            break;
          case 'bear':
            marketCondition = MarketCondition.bearish;
            break;
          case 'volatile':
            marketCondition = MarketCondition.volatile;
            break;
          default:
            marketCondition = MarketCondition.normal;
        }
      }

      // 分析行业影响力
      final sectorImpact = marketContext['sector_impact'] as double?;
      if (sectorImpact != null) {
        if (sectorImpact > 0.7) {
          sectorInfluence = SectorInfluence.high;
        } else if (sectorImpact > 0.4) {
          sectorInfluence = SectorInfluence.moderate;
        } else {
          sectorInfluence = SectorInfluence.low;
        }
      }
    }

    return MarketContextAnalysis(
      volatilityLevel: volatilityLevel,
      marketCondition: marketCondition,
      sectorInfluence: sectorInfluence,
      relatedMarkets: _identifyRelatedMarkets(event),
      sentiment: _determineMarketSentiment(event),
    );
  }

  /// 生成趋势分析
  TrendAnalysis _generateTrendAnalysis(
    MarketChangeEvent event,
    Map<String, dynamic>? marketContext,
  ) {
    var trendDirection = TrendDirection.sideways;
    var trendStrength = TrendStrength.weak;
    var trendDuration = TrendDuration.short_term;

    // 基于变化率判断趋势方向
    if (event.changeRate > 1.0) {
      trendDirection = TrendDirection.upward;
    } else if (event.changeRate < -1.0) {
      trendDirection = TrendDirection.downward;
    }

    // 基于变化幅度判断趋势强度
    final changeMagnitude = event.changeRate.abs();
    if (changeMagnitude > 5.0) {
      trendStrength = TrendStrength.strong;
    } else if (changeMagnitude > 2.0) {
      trendStrength = TrendStrength.moderate;
    }

    // 基于变化类型判断趋势持续时间
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        trendDuration = TrendDuration.uncertain;
        break;
      case ChangeCategory.trendChange:
        trendDuration = TrendDuration.long_term;
        break;
      case ChangeCategory.priceChange:
        trendDuration = TrendDuration.short_term;
        break;
    }

    return TrendAnalysis(
      direction: trendDirection,
      strength: trendStrength,
      duration: trendDuration,
      supportLevels: _calculateSupportLevels(event, marketContext),
      resistanceLevels: _calculateResistanceLevels(event, marketContext),
      momentum: _calculateMomentum(event),
    );
  }

  /// 生成风险评估
  RiskAssessment _generateRiskAssessment(
    MarketChangeEvent event,
    ChangeImpact impact,
  ) {
    var riskLevel = RiskLevel.low;
    var riskType = RiskType.market;
    var riskProbability = RiskProbability.medium;

    // 基于影响级别判断风险等级
    switch (impact.impactLevel) {
      case ImpactLevel.critical:
        riskLevel = RiskLevel.high;
        riskProbability = RiskProbability.high;
        break;
      case ImpactLevel.significant:
        riskLevel = RiskLevel.medium;
        riskProbability = RiskProbability.medium;
        break;
      case ImpactLevel.moderate:
        riskLevel = RiskLevel.low;
        riskProbability = RiskProbability.medium;
        break;
      case ImpactLevel.minor:
        riskLevel = RiskLevel.low;
        riskProbability = RiskProbability.low;
        break;
    }

    // 基于变化类别判断风险类型
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        riskType = RiskType.systemic;
        break;
      case ChangeCategory.trendChange:
        riskType = RiskType.strategic;
        break;
      case ChangeCategory.priceChange:
        riskType = RiskType.market;
        break;
    }

    return RiskAssessment(
      level: riskLevel,
      type: riskType,
      probability: riskProbability,
      factors: _identifyRiskFactors(event),
      mitigation: _suggestRiskMitigation(event, impact),
      timeToRecovery: _estimateRecoveryTime(event),
    );
  }

  /// 生成投资建议
  List<InvestmentSuggestion> _generateInvestmentSuggestions(
    MarketChangeEvent event,
    ChangeImpact impact,
    Map<String, dynamic>? userPortfolio,
  ) {
    final suggestions = <InvestmentSuggestion>[];
    final userProfile = _determineUserProfile(userPortfolio);

    for (final template in _suggestionTemplates) {
      if (_isTemplateApplicable(template, event, impact, userProfile)) {
        final suggestion = _applyTemplate(template, event, impact, userProfile);
        suggestions.add(suggestion);
      }
    }

    // 按优先级排序
    suggestions.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // 限制建议数量
    return suggestions.take(_parameters.maxSuggestions).toList();
  }

  /// 分析心理影响
  PsychologicalImpact _analyzePsychologicalImpact(
    MarketChangeEvent event,
    ChangeImpact impact,
  ) {
    var emotionalReaction = EmotionalReaction.neutral;
    var behaviorBias = BehaviorBias.none;
    var recommendedAction = PsychologicalAction.stay_calm;

    // 基于事件严重程度判断情绪反应
    switch (event.severity) {
      case ChangeSeverity.high:
        emotionalReaction = EmotionalReaction.fear_or_greed;
        behaviorBias = BehaviorBias.overreaction;
        recommendedAction = PsychologicalAction.pause_and_reflect;
        break;
      case ChangeSeverity.medium:
        emotionalReaction = EmotionalReaction.caution;
        behaviorBias = BehaviorBias.confirmation_bias;
        recommendedAction = PsychologicalAction.seek_diverse_opinions;
        break;
      case ChangeSeverity.low:
        emotionalReaction = EmotionalReaction.neutral;
        behaviorBias = BehaviorBias.none;
        recommendedAction = PsychologicalAction.stay_calm;
        break;
    }

    return PsychologicalImpact(
      expectedReaction: emotionalReaction,
      commonBiases: [behaviorBias],
      recommendedAction: recommendedAction,
      mindsetAdvice: _generateMindsetAdvice(event),
    );
  }

  /// 生成策略建议
  List<StrategyRecommendation> _generateStrategyRecommendations(
    MarketChangeEvent event,
    ChangeImpact impact,
    Map<String, dynamic>? userPortfolio,
  ) {
    final recommendations = <StrategyRecommendation>[];

    // 基于影响级别的策略建议
    switch (impact.impactLevel) {
      case ImpactLevel.critical:
        recommendations.add(StrategyRecommendation(
          type: StrategyType.portfolio_rebalance,
          description: '考虑重新平衡投资组合以应对重大市场变化',
          priority: Priority.high,
          timeframe: '1-2周',
          expectedOutcome: '降低风险敞口，保持投资组合稳定性',
        ));
        break;
      case ImpactLevel.significant:
        recommendations.add(StrategyRecommendation(
          type: StrategyType.sector_rotation,
          description: '考虑进行行业轮转以适应市场变化',
          priority: Priority.medium,
          timeframe: '2-4周',
          expectedOutcome: '优化行业配置，抓住新机会',
        ));
        break;
      case ImpactLevel.moderate:
        recommendations.add(StrategyRecommendation(
          type: StrategyType.watch_and_wait,
          description: '保持观察，无需立即采取行动',
          priority: Priority.low,
          timeframe: '1-2个月',
          expectedOutcome: '避免过度反应，保持既定策略',
        ));
        break;
      case ImpactLevel.minor:
        recommendations.add(StrategyRecommendation(
          type: StrategyType.maintain_course,
          description: '维持当前投资策略，无需调整',
          priority: Priority.low,
          timeframe: '长期',
          expectedOutcome: '保持投资策略的一致性',
        ));
        break;
    }

    return recommendations;
  }

  /// 生成总结
  String _generateSummary(MarketChangeEvent event, ChangeImpact impact) {
    final buffer = StringBuffer();

    buffer.write('${event.entityName} ${_generateChangeDescription(event)}，');

    switch (impact.impactLevel) {
      case ImpactLevel.critical:
        buffer.write('可能对您的投资组合产生重大影响，建议立即关注并考虑调整策略。');
        break;
      case ImpactLevel.significant:
        buffer.write('值得关注，可能影响您的投资决策。');
        break;
      case ImpactLevel.moderate:
        buffer.write('属于正常市场波动，建议保持观察。');
        break;
      case ImpactLevel.minor:
        buffer.write('影响有限，无需过度关注。');
        break;
    }

    return buffer.toString();
  }

  /// 生成变化描述
  String _generateChangeDescription(MarketChangeEvent event) {
    var description = '';

    switch (event.category) {
      case ChangeCategory.priceChange:
        description =
            '价格${event.changeRate > 0 ? '上涨' : '下跌'}${event.changeRate.abs().toStringAsFixed(2)}%';
        break;
      case ChangeCategory.trendChange:
        description = '趋势发生重要变化';
        break;
      case ChangeCategory.abnormalEvent:
        description = '出现异常市场事件';
        break;
    }

    return description;
  }

  /// 估算时间范围
  InvestmentHorizon _estimateTimeHorizon(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return InvestmentHorizon.medium_term;
      case ChangeCategory.trendChange:
        return InvestmentHorizon.long_term;
      case ChangeCategory.priceChange:
        return InvestmentHorizon.short_term;
    }
  }

  /// 计算解读置信度
  double _calculateInsightConfidence(
      MarketChangeEvent event, ChangeImpact impact) {
    var confidence = 0.7; // 基础置信度

    // 基于影响分数调整
    if (impact.impactScore > 80) {
      confidence += 0.15;
    } else if (impact.impactScore > 60) {
      confidence += 0.1;
    }

    // 基于市场影响置信度调整
    confidence *= impact.marketImpact.confidenceLevel;

    return math.min(1.0, math.max(0.0, confidence));
  }

  /// 识别相关市场
  List<String> _identifyRelatedMarkets(MarketChangeEvent event) {
    final markets = <String>['A股市场'];

    if (event.type == MarketChangeType.fundNav) {
      markets.addAll(['债券市场', '货币市场']);
    }

    if (event.changeRate.abs() > 3.0) {
      markets.addAll(['港股市场', '美股市场']);
    }

    return markets;
  }

  /// 确定市场情绪
  MarketSentiment _determineMarketSentiment(MarketChangeEvent event) {
    if (event.changeRate > 2.0) {
      return MarketSentiment.optimistic;
    } else if (event.changeRate < -2.0) {
      return MarketSentiment.pessimistic;
    }
    return MarketSentiment.neutral;
  }

  /// 计算支撑位
  List<double> _calculateSupportLevels(
    MarketChangeEvent event,
    Map<String, dynamic>? marketContext,
  ) {
    // 简化实现，实际应该基于技术分析
    final currentValue = double.tryParse(event.currentValue) ?? 0.0;
    return [currentValue * 0.95, currentValue * 0.90];
  }

  /// 计算阻力位
  List<double> _calculateResistanceLevels(
    MarketChangeEvent event,
    Map<String, dynamic>? marketContext,
  ) {
    // 简化实现，实际应该基于技术分析
    final currentValue = double.tryParse(event.currentValue) ?? 0.0;
    return [currentValue * 1.05, currentValue * 1.10];
  }

  /// 计算动量
  double _calculateMomentum(MarketChangeEvent event) {
    return event.changeRate * event.importance;
  }

  /// 识别风险因素
  List<String> _identifyRiskFactors(MarketChangeEvent event) {
    final factors = <String>[];

    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        factors.add('政策不确定性');
        factors.add('市场情绪波动');
        break;
      case ChangeCategory.trendChange:
        factors.add('趋势反转风险');
        factors.add('流动性风险');
        break;
      case ChangeCategory.priceChange:
        factors.add('价格波动风险');
        break;
    }

    return factors;
  }

  /// 建议风险缓解措施
  List<String> _suggestRiskMitigation(
      MarketChangeEvent event, ChangeImpact impact) {
    final mitigations = <String>[];

    if (impact.impactLevel.index >= ImpactLevel.significant.index) {
      mitigations.add('分散投资降低集中度风险');
      mitigations.add('设置止损点控制下行风险');
      mitigations.add('增加现金储备保持灵活性');
    }

    return mitigations;
  }

  /// 估算恢复时间
  Duration _estimateRecoveryTime(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return const Duration(days: 30);
      case ChangeCategory.trendChange:
        return const Duration(days: 60);
      case ChangeCategory.priceChange:
        return const Duration(days: 7);
    }
  }

  /// 确定用户画像
  UserProfile _determineUserProfile(Map<String, dynamic>? userPortfolio) {
    if (userPortfolio == null) {
      return UserProfile.conservative; // 默认保守型
    }

    final riskTolerance = userPortfolio['risk_tolerance'] as String?;
    switch (riskTolerance?.toLowerCase()) {
      case 'aggressive':
        return UserProfile.aggressive;
      case 'moderate':
        return UserProfile.moderate;
      case 'conservative':
        return UserProfile.conservative;
      default:
        return UserProfile.conservative;
    }
  }

  /// 判断模板是否适用
  bool _isTemplateApplicable(
    InvestmentSuggestionTemplate template,
    MarketChangeEvent event,
    ChangeImpact impact,
    UserProfile userProfile,
  ) {
    // 检查影响级别匹配
    if (!template.applicableImpactLevels.contains(impact.impactLevel)) {
      return false;
    }

    // 检查用户画像匹配
    if (!template.applicableUserProfiles.contains(userProfile)) {
      return false;
    }

    // 检查变化类别匹配
    if (!template.applicableCategories.contains(event.category)) {
      return false;
    }

    return true;
  }

  /// 应用模板生成建议
  InvestmentSuggestion _applyTemplate(
    InvestmentSuggestionTemplate template,
    MarketChangeEvent event,
    ChangeImpact impact,
    UserProfile userProfile,
  ) {
    return InvestmentSuggestion(
      type: template.type,
      title: _customizeTitle(template.title, event),
      description: _customizeDescription(template.description, event, impact),
      priority: template.defaultPriority,
      expectedReturn: template.expectedReturn,
      riskLevel: template.riskLevel,
      timeframe: template.timeframe,
      actionItems: template.actionItems,
    );
  }

  /// 自定义标题
  String _customizeTitle(String template, MarketChangeEvent event) {
    return template.replaceAll('{entity}', event.entityName);
  }

  /// 自定义描述
  String _customizeDescription(
    String template,
    MarketChangeEvent event,
    ChangeImpact impact,
  ) {
    return template
        .replaceAll('{entity}', event.entityName)
        .replaceAll('{change}', event.changeDescription)
        .replaceAll('{impact}', impact.impactLevel.name);
  }

  /// 生成心态建议
  String _generateMindsetAdvice(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return '保持冷静，避免情绪化决策，关注长期投资目标';
      case ChangeCategory.trendChange:
        return '客观分析趋势变化，不要盲目跟风，坚持价值投资理念';
      case ChangeCategory.priceChange:
        return '价格波动是正常现象，避免频繁交易，保持投资纪律';
    }
  }

  /// 创建默认建议模板
  static List<InvestmentSuggestionTemplate>
      _createDefaultSuggestionTemplates() {
    return [
      InvestmentSuggestionTemplate(
        type: SuggestionType.buy,
        title: '考虑增持{entity}',
        description: '{entity}出现{change}机会，建议关注并考虑适当增持',
        applicableImpactLevels: [ImpactLevel.moderate, ImpactLevel.significant],
        applicableUserProfiles: [UserProfile.aggressive, UserProfile.moderate],
        applicableCategories: [ChangeCategory.priceChange],
        defaultPriority: Priority.medium,
        expectedReturn: '5-10%',
        riskLevel: RiskLevel.low,
        timeframe: '1-3个月',
        actionItems: ['分析基本面', '评估风险敞口', '制定买入计划'],
      ),
      InvestmentSuggestionTemplate(
        type: SuggestionType.sell,
        title: '考虑减持{entity}',
        description: '{entity}出现{change}风险，建议适当降低仓位控制风险',
        applicableImpactLevels: [ImpactLevel.significant, ImpactLevel.critical],
        applicableUserProfiles: UserProfile.values,
        applicableCategories: [
          ChangeCategory.priceChange,
          ChangeCategory.trendChange
        ],
        defaultPriority: Priority.high,
        expectedReturn: '避免损失',
        riskLevel: RiskLevel.low,
        timeframe: '立即',
        actionItems: ['评估持仓成本', '设置止损点', '分批减持'],
      ),
      InvestmentSuggestionTemplate(
        type: SuggestionType.hold,
        title: '建议持有观察',
        description: '{entity}的{impact}影响有限，建议维持现有仓位观察',
        applicableImpactLevels: [ImpactLevel.minor, ImpactLevel.moderate],
        applicableUserProfiles: UserProfile.values,
        applicableCategories: ChangeCategory.values,
        defaultPriority: Priority.low,
        expectedReturn: '0-3%',
        riskLevel: RiskLevel.low,
        timeframe: '3-6个月',
        actionItems: ['定期评估', '跟踪变化', '保持仓位'],
      ),
      InvestmentSuggestionTemplate(
        type: SuggestionType.rebalance,
        title: '建议重新平衡',
        description: '市场{change}建议重新平衡投资组合以降低风险',
        applicableImpactLevels: [ImpactLevel.critical],
        applicableUserProfiles: UserProfile.values,
        applicableCategories: [
          ChangeCategory.abnormalEvent,
          ChangeCategory.trendChange
        ],
        defaultPriority: Priority.high,
        expectedReturn: '风险控制',
        riskLevel: RiskLevel.low,
        timeframe: '1-2周',
        actionItems: ['评估整体组合', '调整资产配置', '分散投资'],
      ),
    ];
  }
}

/// 解读生成参数
class InsightGenerationParameters {
  /// 最大建议数量
  final int maxSuggestions;

  /// 置信度阈值
  final double confidenceThreshold;

  const InsightGenerationParameters({
    this.maxSuggestions = 3,
    this.confidenceThreshold = 0.6,
  });
}

/// 市场洞察
class MarketInsight {
  /// 事件ID
  final String eventId;

  /// 总结
  final String summary;

  /// 市场背景分析
  final MarketContextAnalysis marketAnalysis;

  /// 趋势分析
  final TrendAnalysis trendAnalysis;

  /// 风险评估
  final RiskAssessment riskAssessment;

  /// 投资建议
  final List<InvestmentSuggestion> investmentSuggestions;

  /// 心理影响分析
  final PsychologicalImpact psychologicalImpact;

  /// 策略建议
  final List<StrategyRecommendation> strategyRecommendations;

  /// 投资时间范围
  final InvestmentHorizon timeHorizon;

  /// 置信度水平
  final double confidenceLevel;

  /// 生成时间
  final DateTime generatedAt;

  const MarketInsight({
    required this.eventId,
    required this.summary,
    required this.marketAnalysis,
    required this.trendAnalysis,
    required this.riskAssessment,
    required this.investmentSuggestions,
    required this.psychologicalImpact,
    required this.strategyRecommendations,
    required this.timeHorizon,
    required this.confidenceLevel,
    required this.generatedAt,
  });
}

/// 市场背景分析
class MarketContextAnalysis {
  /// 波动性水平
  final VolatilityLevel volatilityLevel;

  /// 市场状况
  final MarketCondition marketCondition;

  /// 行业影响力
  final SectorInfluence sectorInfluence;

  /// 相关市场
  final List<String> relatedMarkets;

  /// 市场情绪
  final MarketSentiment sentiment;

  const MarketContextAnalysis({
    required this.volatilityLevel,
    required this.marketCondition,
    required this.sectorInfluence,
    required this.relatedMarkets,
    required this.sentiment,
  });
}

/// 趋势分析
class TrendAnalysis {
  /// 趋势方向
  final TrendDirection direction;

  /// 趋势强度
  final TrendStrength strength;

  /// 趋势持续时间
  final TrendDuration duration;

  /// 支撑位
  final List<double> supportLevels;

  /// 阻力位
  final List<double> resistanceLevels;

  /// 动量
  final double momentum;

  const TrendAnalysis({
    required this.direction,
    required this.strength,
    required this.duration,
    required this.supportLevels,
    required this.resistanceLevels,
    required this.momentum,
  });
}

/// 风险评估
class RiskAssessment {
  /// 风险等级
  final RiskLevel level;

  /// 风险类型
  final RiskType type;

  /// 风险概率
  final RiskProbability probability;

  /// 风险因素
  final List<String> factors;

  /// 缓解措施
  final List<String> mitigation;

  /// 恢复时间
  final Duration timeToRecovery;

  const RiskAssessment({
    required this.level,
    required this.type,
    required this.probability,
    required this.factors,
    required this.mitigation,
    required this.timeToRecovery,
  });
}

/// 投资建议
class InvestmentSuggestion {
  /// 建议类型
  final SuggestionType type;

  /// 标题
  final String title;

  /// 描述
  final String description;

  /// 优先级
  final Priority priority;

  /// 预期收益
  final String expectedReturn;

  /// 风险等级
  final RiskLevel riskLevel;

  /// 时间范围
  final String timeframe;

  /// 行动项目
  final List<String> actionItems;

  const InvestmentSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.expectedReturn,
    required this.riskLevel,
    required this.timeframe,
    required this.actionItems,
  });
}

/// 心理影响分析
class PsychologicalImpact {
  /// 预期情绪反应
  final EmotionalReaction expectedReaction;

  /// 常见行为偏差
  final List<BehaviorBias> commonBiases;

  /// 推荐行动
  final PsychologicalAction recommendedAction;

  /// 心态建议
  final String mindsetAdvice;

  const PsychologicalImpact({
    required this.expectedReaction,
    required this.commonBiases,
    required this.recommendedAction,
    required this.mindsetAdvice,
  });
}

/// 策略建议
class StrategyRecommendation {
  /// 策略类型
  final StrategyType type;

  /// 描述
  final String description;

  /// 优先级
  final Priority priority;

  /// 时间框架
  final String timeframe;

  /// 预期结果
  final String expectedOutcome;

  const StrategyRecommendation({
    required this.type,
    required this.description,
    required this.priority,
    required this.timeframe,
    required this.expectedOutcome,
  });
}

/// 投资建议模板
class InvestmentSuggestionTemplate {
  /// 建议类型
  final SuggestionType type;

  /// 标题模板
  final String title;

  /// 描述模板
  final String description;

  /// 适用影响级别
  final List<ImpactLevel> applicableImpactLevels;

  /// 适用用户画像
  final List<UserProfile> applicableUserProfiles;

  /// 适用变化类别
  final List<ChangeCategory> applicableCategories;

  /// 默认优先级
  final Priority defaultPriority;

  /// 预期收益
  final String expectedReturn;

  /// 风险等级
  final RiskLevel riskLevel;

  /// 时间范围
  final String timeframe;

  /// 行动项目
  final List<String> actionItems;

  const InvestmentSuggestionTemplate({
    required this.type,
    required this.title,
    required this.description,
    required this.applicableImpactLevels,
    required this.applicableUserProfiles,
    required this.applicableCategories,
    required this.defaultPriority,
    required this.expectedReturn,
    required this.riskLevel,
    required this.timeframe,
    required this.actionItems,
  });
}

// 枚举定义
enum VolatilityLevel { low, medium, high }

enum MarketCondition { normal, bullish, bearish, volatile }

enum SectorInfluence { low, moderate, high }

enum MarketSentiment { optimistic, neutral, pessimistic }

enum TrendDirection { upward, downward, sideways }

enum TrendStrength { weak, moderate, strong }

enum TrendDuration { short_term, medium_term, long_term, uncertain }

enum RiskLevel { low, medium, high }

enum RiskType { market, credit, liquidity, systemic, strategic }

enum RiskProbability { low, medium, high }

enum SuggestionType { buy, sell, hold, rebalance, diversify }

enum Priority { low, medium, high }

enum InvestmentHorizon { short_term, medium_term, long_term }

enum UserProfile { conservative, moderate, aggressive }

enum EmotionalReaction {
  fear,
  greed,
  optimism,
  pessimism,
  neutral,
  fear_or_greed,
  caution
}

enum BehaviorBias {
  none,
  overreaction,
  confirmation_bias,
  loss_aversion,
  herd_behavior
}

enum PsychologicalAction {
  stay_calm,
  seek_advice,
  pause_and_reflect,
  seek_diverse_opinions
}

enum StrategyType {
  portfolio_rebalance,
  sector_rotation,
  watch_and_wait,
  maintain_course
}
