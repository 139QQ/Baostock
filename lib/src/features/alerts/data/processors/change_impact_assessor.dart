import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../models/market_change_event.dart';
import '../models/change_severity.dart';
import '../models/change_category.dart';
import '../../domain/entities/impact_level.dart';
import '../../domain/entities/impact_scope.dart';

/// 变化影响评估器
///
/// 负责评估市场变化的重要性和影响范围
class ChangeImpactAssessor {
  /// 影响评估参数
  final ImpactAssessmentParameters _parameters;

  /// 构造函数
  ChangeImpactAssessor({
    ImpactAssessmentParameters? parameters,
  }) : _parameters = parameters ?? ImpactAssessmentParameters();

  /// 评估变化事件的影响
  Future<ChangeImpact> assessImpact(
    MarketChangeEvent event, {
    List<String>? relatedFunds,
    String? userPortfolioExposure,
  }) async {
    // 计算影响级别
    final impactLevel = _calculateImpactLevel(
      event: event,
      relatedFunds: relatedFunds,
      userPortfolioExposure: userPortfolioExposure,
    );

    // 计算影响范围
    final impactScope = _calculateImpactScope(
      event: event,
      relatedFunds: relatedFunds,
    );

    // 计算影响分数
    final impactScore = _calculateImpactScore(
      event: event,
      impactLevel: impactLevel,
      impactScope: impactScope,
      userPortfolioExposure: userPortfolioExposure,
    );

    // 生成影响分析
    final analysis = _generateImpactAnalysis(
      event: event,
      impactLevel: impactLevel,
      impactScope: impactScope,
      impactScore: impactScore,
    );

    return ChangeImpact(
      eventId: event.id,
      impactLevel: impactLevel,
      impactScope: impactScope,
      impactScore: impactScore,
      affectedFunds: relatedFunds ?? [],
      userImpact: _calculateUserImpact(
        event: event,
        userPortfolioExposure: userPortfolioExposure,
      ),
      marketImpact: _calculateMarketImpact(event),
      analysis: analysis,
      assessmentTime: DateTime.now(),
    );
  }

  /// 计算影响级别
  ImpactLevel _calculateImpactLevel({
    required MarketChangeEvent event,
    List<String>? relatedFunds,
    String? userPortfolioExposure,
  }) {
    var levelScore = 0.0;

    // 基于变化严重程度
    switch (event.severity) {
      case ChangeSeverity.high:
        levelScore += 40.0;
        break;
      case ChangeSeverity.medium:
        levelScore += 25.0;
        break;
      case ChangeSeverity.low:
        levelScore += 10.0;
        break;
    }

    // 基于变化类别
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        levelScore += 30.0;
        break;
      case ChangeCategory.trendChange:
        levelScore += 20.0;
        break;
      case ChangeCategory.priceChange:
        levelScore += 10.0;
        break;
    }

    // 基于变化幅度
    final magnitudeScore = math.min(30.0, event.changeRate.abs() * 2);
    levelScore += magnitudeScore;

    // 基于相关基金数量
    if (relatedFunds != null && relatedFunds.isNotEmpty) {
      final fundScore = math.min(20.0, relatedFunds.length * 2.0);
      levelScore += fundScore;
    }

    // 基于用户投资组合暴露程度
    if (userPortfolioExposure != null) {
      final exposure = Decimal.tryParse(userPortfolioExposure) ?? Decimal.zero;
      final exposureScore = math.min(20.0, exposure.toDouble() * 0.1);
      levelScore += exposureScore;
    }

    // 根据总分确定影响级别
    if (levelScore >= _parameters.highImpactThreshold) {
      return ImpactLevel.critical;
    } else if (levelScore >= _parameters.mediumImpactThreshold) {
      return ImpactLevel.significant;
    } else if (levelScore >= _parameters.lowImpactThreshold) {
      return ImpactLevel.moderate;
    } else {
      return ImpactLevel.minor;
    }
  }

  /// 计算影响范围
  ImpactScope _calculateImpactScope({
    required MarketChangeEvent event,
    List<String>? relatedFunds,
  }) {
    var scopeScore = 0;

    // 基于变化类型
    if (event.type == MarketChangeType.marketIndex) {
      scopeScore += 3; // 市场指数影响范围较大
    } else {
      scopeScore += 1; // 单个基金影响范围较小
    }

    // 基于相关基金数量
    if (relatedFunds != null) {
      if (relatedFunds.length >= 20) {
        scopeScore += 3; // 广泛影响
      } else if (relatedFunds.length >= 10) {
        scopeScore += 2; // 中等影响
      } else if (relatedFunds.length >= 5) {
        scopeScore += 1; // 有限影响
      }
    }

    // 基于变化严重程度
    switch (event.severity) {
      case ChangeSeverity.high:
        scopeScore += 2;
        break;
      case ChangeSeverity.medium:
        scopeScore += 1;
        break;
      case ChangeSeverity.low:
        scopeScore += 0;
        break;
    }

    // 根据总分确定影响范围
    if (scopeScore >= 6) {
      return ImpactScope.market;
    } else if (scopeScore >= 4) {
      return ImpactScope.sector;
    } else if (scopeScore >= 2) {
      return ImpactScope.specific;
    } else {
      return ImpactScope.limited;
    }
  }

  /// 计算影响分数
  double _calculateImpactScore({
    required MarketChangeEvent event,
    required ImpactLevel impactLevel,
    required ImpactScope impactScope,
    String? userPortfolioExposure,
  }) {
    var score = event.importance; // 基础重要性分数

    // 根据影响级别调整
    switch (impactLevel) {
      case ImpactLevel.critical:
        score *= 1.5;
        break;
      case ImpactLevel.significant:
        score *= 1.2;
        break;
      case ImpactLevel.moderate:
        score *= 1.0;
        break;
      case ImpactLevel.minor:
        score *= 0.8;
        break;
    }

    // 根据影响范围调整
    switch (impactScope) {
      case ImpactScope.market:
        score *= 1.3;
        break;
      case ImpactScope.sector:
        score *= 1.1;
        break;
      case ImpactScope.specific:
        score *= 1.0;
        break;
      case ImpactScope.limited:
        score *= 0.9;
        break;
    }

    // 根据用户投资组合暴露程度调整
    if (userPortfolioExposure != null) {
      final exposure = Decimal.tryParse(userPortfolioExposure) ?? Decimal.zero;
      if (exposure > Decimal.fromInt(10)) {
        // 10%以上
        score *= 1.2;
      } else if (exposure > Decimal.fromInt(5)) {
        // 5%以上
        score *= 1.1;
      }
    }

    // 确保分数在0-100之间
    return math.min(100.0, math.max(0.0, score));
  }

  /// 计算用户影响
  UserImpact _calculateUserImpact({
    required MarketChangeEvent event,
    String? userPortfolioExposure,
  }) {
    if (userPortfolioExposure == null) {
      return UserImpact(
        affectedAmount: '0',
        affectedPercentage: 0.0,
        impactDescription: '无法评估用户影响 - 缺少投资组合信息',
        riskLevel: ImpactRiskLevel.unknown,
      );
    }

    final exposure = Decimal.tryParse(userPortfolioExposure) ?? Decimal.zero;
    final affectedAmount = _calculateAffectedAmount(event, exposure);

    // 计算风险级别
    ImpactRiskLevel riskLevel;
    String impactDescription;

    if (exposure > Decimal.fromInt(20)) {
      riskLevel = ImpactRiskLevel.high;
      impactDescription = '高风险：该变化可能对您的投资组合产生重大影响';
    } else if (exposure > Decimal.fromInt(10)) {
      riskLevel = ImpactRiskLevel.medium;
      impactDescription = '中等风险：该变化可能对您的投资组合产生一定影响';
    } else if (exposure > Decimal.fromInt(5)) {
      riskLevel = ImpactRiskLevel.low;
      impactDescription = '低风险：该变化对您的投资组合影响较小';
    } else {
      riskLevel = ImpactRiskLevel.minimal;
      impactDescription = '极低风险：该变化对您的投资组合影响极小';
    }

    return UserImpact(
      affectedAmount: affectedAmount,
      affectedPercentage: exposure.toDouble(),
      impactDescription: impactDescription,
      riskLevel: riskLevel,
    );
  }

  /// 计算市场影响
  MarketImpact _calculateMarketImpact(MarketChangeEvent event) {
    var marketSentiment = MarketSentiment.neutral;
    var volatilityImpact = VolatilityImpact.low;

    // 根据变化率判断市场情绪
    if (event.changeRate > 2.0) {
      marketSentiment = MarketSentiment.bullish;
    } else if (event.changeRate < -2.0) {
      marketSentiment = MarketSentiment.bearish;
    }

    // 根据变化类别判断波动性影响
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        volatilityImpact = VolatilityImpact.high;
        break;
      case ChangeCategory.trendChange:
        volatilityImpact = VolatilityImpact.medium;
        break;
      case ChangeCategory.priceChange:
        volatilityImpact = VolatilityImpact.low;
        break;
    }

    return MarketImpact(
      sentiment: marketSentiment,
      volatilityImpact: volatilityImpact,
      expectedDuration: _estimateImpactDuration(event),
      confidenceLevel: _calculateConfidenceLevel(event),
    );
  }

  /// 生成影响分析
  String _generateImpactAnalysis({
    required MarketChangeEvent event,
    required ImpactLevel impactLevel,
    required ImpactScope impactScope,
    required double impactScore,
  }) {
    final buffer = StringBuffer();

    // 基础分析
    buffer.writeln(
        '${event.entityName} 发生 ${event.categoryDescription}，变化幅度 ${event.changeDescription}');

    // 影响级别分析
    switch (impactLevel) {
      case ImpactLevel.critical:
        buffer.writeln('• 影响级别：重大 - 该变化可能对市场产生深远影响');
        break;
      case ImpactLevel.significant:
        buffer.writeln('• 影响级别：显著 - 该变化值得关注，可能影响投资决策');
        break;
      case ImpactLevel.moderate:
        buffer.writeln('• 影响级别：中等 - 该变化属于正常市场波动');
        break;
      case ImpactLevel.minor:
        buffer.writeln('• 影响级别：轻微 - 该变化影响有限');
        break;
    }

    // 影响范围分析
    switch (impactScope) {
      case ImpactScope.market:
        buffer.writeln('• 影响范围：市场级别 - 可能影响整个市场和相关投资品种');
        break;
      case ImpactScope.sector:
        buffer.writeln('• 影响范围：行业级别 - 主要影响相关行业板块');
        break;
      case ImpactScope.specific:
        buffer.writeln('• 影响范围：特定品种 - 主要影响相关基金和投资品种');
        break;
      case ImpactScope.limited:
        buffer.writeln('• 影响范围：有限 - 影响范围较小');
        break;
    }

    // 建议措施
    buffer.writeln('• 建议措施：${_generateRecommendations(event, impactLevel)}');

    return buffer.toString();
  }

  /// 计算受影响金额
  String _calculateAffectedAmount(MarketChangeEvent event, Decimal exposure) {
    // 这里应该根据用户的实际投资金额计算
    // 暂时返回估算值
    final estimatedAmount = exposure * Decimal.fromInt(100000); // 假设总投资10万
    return estimatedAmount.toStringAsFixed(2);
  }

  /// 估算影响持续时间
  Duration _estimateImpactDuration(MarketChangeEvent event) {
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        return const Duration(days: 7); // 异常事件影响时间较长
      case ChangeCategory.trendChange:
        return const Duration(days: 30); // 趋势变化影响时间更长
      case ChangeCategory.priceChange:
        return const Duration(days: 3); // 价格变化影响时间较短
    }
  }

  /// 计算置信度
  double _calculateConfidenceLevel(MarketChangeEvent event) {
    var confidence = 0.7; // 基础置信度

    // 根据变化幅度调整置信度
    if (event.changeRate.abs() > 5.0) {
      confidence += 0.2; // 大幅度变化置信度更高
    }

    // 根据变化类别调整置信度
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        confidence -= 0.1; // 异常事件预测难度大
        break;
      case ChangeCategory.trendChange:
        confidence += 0.1; // 趋势变化相对可预测
        break;
      case ChangeCategory.priceChange:
        confidence += 0.0; // 价格变化置信度保持基础水平
        break;
    }

    return math.min(1.0, math.max(0.0, confidence));
  }

  /// 生成建议措施
  String _generateRecommendations(
      MarketChangeEvent event, ImpactLevel impactLevel) {
    switch (impactLevel) {
      case ImpactLevel.critical:
        return '建议立即关注，考虑调整投资策略，必要时咨询专业投资顾问';
      case ImpactLevel.significant:
        return '建议密切关注，评估对投资组合的影响，适时调整持仓';
      case ImpactLevel.moderate:
        return '建议保持观察，无需过度反应，继续执行既定投资策略';
      case ImpactLevel.minor:
        return '建议正常关注，无需特别调整投资策略';
    }
  }
}

/// 影响评估参数
class ImpactAssessmentParameters {
  /// 高影响阈值
  final double highImpactThreshold;

  /// 中等影响阈值
  final double mediumImpactThreshold;

  /// 低影响阈值
  final double lowImpactThreshold;

  const ImpactAssessmentParameters({
    this.highImpactThreshold = 80.0,
    this.mediumImpactThreshold = 60.0,
    this.lowImpactThreshold = 40.0,
  });
}

/// 变化影响结果
class ChangeImpact {
  /// 事件ID
  final String eventId;

  /// 影响级别
  final ImpactLevel impactLevel;

  /// 影响范围
  final ImpactScope impactScope;

  /// 影响分数 (0-100)
  final double impactScore;

  /// 受影响的基金列表
  final List<String> affectedFunds;

  /// 用户影响
  final UserImpact userImpact;

  /// 市场影响
  final MarketImpact marketImpact;

  /// 影响分析
  final String analysis;

  /// 评估时间
  final DateTime assessmentTime;

  const ChangeImpact({
    required this.eventId,
    required this.impactLevel,
    required this.impactScope,
    required this.impactScore,
    required this.affectedFunds,
    required this.userImpact,
    required this.marketImpact,
    required this.analysis,
    required this.assessmentTime,
  });
}

/// 影响级别
enum ImpactLevel {
  minor, // 轻微
  moderate, // 中等
  significant, // 显著
  critical, // 重大
}

/// 影响范围
enum ImpactScope {
  limited, // 有限
  specific, // 特定
  sector, // 行业
  market, // 市场
}

/// 用户影响
class UserImpact {
  /// 受影响金额
  final String affectedAmount;

  /// 受影响百分比
  final double affectedPercentage;

  /// 影响描述
  final String impactDescription;

  /// 风险级别
  final ImpactRiskLevel riskLevel;

  const UserImpact({
    required this.affectedAmount,
    required this.affectedPercentage,
    required this.impactDescription,
    required this.riskLevel,
  });
}

/// 影响风险级别
enum ImpactRiskLevel {
  minimal, // 极低
  low, // 低
  medium, // 中等
  high, // 高
  unknown, // 未知
}

/// 市场影响
class MarketImpact {
  /// 市场情绪
  final MarketSentiment sentiment;

  /// 波动性影响
  final VolatilityImpact volatilityImpact;

  /// 预期持续时间
  final Duration expectedDuration;

  /// 置信度水平
  final double confidenceLevel;

  const MarketImpact({
    required this.sentiment,
    required this.volatilityImpact,
    required this.expectedDuration,
    required this.confidenceLevel,
  });
}

/// 市场情绪
enum MarketSentiment {
  bullish, // 看涨
  bearish, // 看跌
  neutral, // 中性
}

/// 波动性影响
enum VolatilityImpact {
  low, // 低波动
  medium, // 中等波动
  high, // 高波动
}
