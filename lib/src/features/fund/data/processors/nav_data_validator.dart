import 'package:decimal/decimal.dart';

import '../../models/fund_nav_data.dart';
import '../../../../core/utils/logger.dart';

/// 净值数据验证器
///
/// 提供多层次的数据验证机制，确保基金净值数据的准确性和完整性
/// 支持基础验证、业务规则验证和多源数据交叉验证
class NavDataValidator {
  /// 基金净值合理范围 (最小值)
  static final Decimal _minNav = Decimal.parse('0.001'); // 0.001

  /// 基金净值合理范围 (最大值)
  static final Decimal _maxNav = Decimal.parse('1000'); // 1000.0

  /// 单日变化率合理范围 (-30% 到 +30%)
  static final Decimal _maxChangeRate = Decimal.parse('0.3'); // 0.3

  /// 基金代码长度限制
  static const int _minFundCodeLength = 4;
  static const int _maxFundCodeLength = 10;

  /// 数据时间差限制 (不能超过未来7天)
  static const Duration _maxFutureTime = Duration(days: 7);

  /// 数据时间差限制 (不能早于1年前)
  static const Duration _maxPastTime = Duration(days: 365);

  /// 验证配置
  final NavValidationConfig config;

  /// 历史数据缓存 (用于交叉验证)
  final Map<String, List<FundNavData>> _historicalData = {};

  /// 创建净值数据验证器
  NavDataValidator({
    this.config = const NavValidationConfig(),
  });

  /// 验证净值数据
  Future<NavValidationResult> validateNavData(FundNavData navData) async {
    final errors = <String>[];
    final warnings = <String>[];
    double confidenceScore = 100.0;

    try {
      // 1. 基础数据完整性验证
      _validateBasicIntegrity(navData, errors, warnings, confidenceScore);

      // 2. 数值合理性验证
      _validateNumericRanges(navData, errors, warnings, confidenceScore);

      // 3. 业务逻辑验证
      _validateBusinessRules(navData, errors, warnings, confidenceScore);

      // 4. 时间一致性验证
      _validateTimeConsistency(navData, errors, warnings, confidenceScore);

      // 5. 数据质量评估
      _assessDataQuality(navData, errors, warnings, confidenceScore);

      // 6. 历史数据交叉验证 (如果有历史数据)
      if (config.enableCrossValidation) {
        await _performCrossValidation(
            navData, errors, warnings, confidenceScore);
      }

      // 7. 异常检测
      _detectAnomalies(navData, errors, warnings, confidenceScore);

      // 计算最终置信度
      confidenceScore =
          _calculateFinalConfidence(errors, warnings, confidenceScore);

      final isValid =
          errors.isEmpty && confidenceScore >= config.minConfidenceScore;

      AppLogger.debug(
          'NAV validation completed for ${navData.fundCode}: valid=$isValid, confidence=${confidenceScore.toStringAsFixed(1)}%, errors=${errors.length}, warnings=${warnings.length}');

      return NavValidationResult(
        isValid: isValid,
        confidenceScore: confidenceScore,
        errors: errors,
        warnings: warnings,
        validationTime: DateTime.now(),
        navData: navData,
      );
    } catch (e) {
      AppLogger.error('NAV validation error', e);
      return NavValidationResult(
        isValid: false,
        confidenceScore: 0.0,
        errors: ['验证过程中发生错误: $e'],
        warnings: [],
        validationTime: DateTime.now(),
        navData: navData,
      );
    }
  }

  /// 验证基础数据完整性
  void _validateBasicIntegrity(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 基金代码验证
    if (navData.fundCode.isEmpty) {
      errors.add('基金代码不能为空');
      confidenceScore -= 30.0;
    } else if (navData.fundCode.length < _minFundCodeLength) {
      errors.add('基金代码长度不足 (最少${_minFundCodeLength}位)');
      confidenceScore -= 20.0;
    } else if (navData.fundCode.length > _maxFundCodeLength) {
      errors.add('基金代码长度超限 (最多${_maxFundCodeLength}位)');
      confidenceScore -= 15.0;
    } else if (!_isValidFundCodeFormat(navData.fundCode)) {
      warnings.add('基金代码格式可能不正确');
      confidenceScore -= 5.0;
    }

    // 净值日期验证
    if (navData.navDate.isAfter(DateTime.now().add(_maxFutureTime))) {
      errors.add('净值日期不能超过未来${_maxFutureTime.inDays}天');
      confidenceScore -= 25.0;
    } else if (navData.navDate
        .isBefore(DateTime.now().subtract(_maxPastTime))) {
      errors.add('净值日期不能早于${_maxPastTime.inDays}天前');
      confidenceScore -= 20.0;
    }

    // 数据时间戳验证
    if (navData.timestamp
        .isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      warnings.add('数据时间戳略超过当前时间，可能存在时钟偏差');
      confidenceScore -= 5.0;
    }

    // 数据源验证
    if (navData.dataSource == null || navData.dataSource!.isEmpty) {
      warnings.add('缺少数据源信息');
      confidenceScore -= 5.0;
    }
  }

  /// 验证数值范围
  void _validateNumericRanges(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 单位净值验证
    if (navData.nav <= _minNav) {
      errors.add('单位净值过低 (${navData.nav} < ${_minNav})');
      confidenceScore -= 40.0;
    } else if (navData.nav > _maxNav) {
      errors.add('单位净值过高 (${navData.nav} > ${_maxNav})');
      confidenceScore -= 30.0;
    } else if (navData.nav < Decimal.parse('0.01')) {
      // < 0.01
      warnings.add('单位净值异常偏低');
      confidenceScore -= 10.0;
    }

    // 累计净值验证
    if (navData.accumulatedNav <= Decimal.zero) {
      errors.add('累计净值必须大于零');
      confidenceScore -= 35.0;
    } else if (navData.accumulatedNav < navData.nav) {
      warnings.add('累计净值小于单位净值，可能是新基金');
      confidenceScore -= 5.0;
    } else if (navData.accumulatedNav > Decimal.fromInt(100)) {
      // > 100
      warnings.add('累计净值较高，请确认是否正确');
      confidenceScore -= 3.0;
    }

    // 变化率验证
    if (navData.changeRate.abs() > _maxChangeRate) {
      errors.add(
          '单日变化率异常 (${(navData.changeRate * Decimal.fromInt(100)).toStringAsFixed(2)}%)');
      confidenceScore -= 45.0;
    } else if (navData.changeRate.abs() > Decimal.parse('0.1')) {
      // > 10%
      warnings.add('单日变化率较大，请确认数据准确性');
      confidenceScore -= 15.0;
    }

    // 数值一致性验证
    final calculatedChangeRate = _calculateChangeRate(navData);
    if (calculatedChangeRate != null) {
      final difference = (navData.changeRate - calculatedChangeRate).abs();
      final tolerance = Decimal.parse('0.001'); // 0.1%

      if (difference > tolerance) {
        warnings.add('变化率与前后净值不匹配，可能存在计算错误');
        confidenceScore -= 20.0;
      }
    }
  }

  /// 验证业务规则
  void _validateBusinessRules(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 基金类型特定验证
    if (navData.fundCode.startsWith('00')) {
      // 货币基金
      _validateMoneyMarketFund(navData, errors, warnings, confidenceScore);
    } else if (navData.fundCode.startsWith('51') ||
        navData.fundCode.startsWith('50')) {
      // ETF
      _validateETF(navData, errors, warnings, confidenceScore);
    } else {
      // 普通基金
      _validateOrdinaryFund(navData, errors, warnings, confidenceScore);
    }

    // 交易状态验证
    if (!navData.isTradingDay && navData.changeRate != Decimal.zero) {
      warnings.add('非交易日但净值有变化，请确认交易状态');
      confidenceScore -= 10.0;
    }

    // 基金状态验证
    if (navData.fundStatus != FundStatus.normal &&
        navData.changeRate != Decimal.zero) {
      warnings.add('基金状态异常但净值有变化，请确认状态信息');
      confidenceScore -= 8.0;
    }
  }

  /// 验证货币基金
  void _validateMoneyMarketFund(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 货币基金净值通常在1.0附近
    if (navData.nav < Decimal.parse('0.99') ||
        navData.nav > Decimal.parse('1.01')) {
      warnings.add('货币基金净值异常 (应在1.0附近)');
      confidenceScore -= 15.0;
    }

    // 货币基金变化率通常很小
    if (navData.changeRate.abs() > Decimal.parse('0.01')) {
      // > 1%
      warnings.add('货币基金日变化率过大');
      confidenceScore -= 20.0;
    }
  }

  /// 验证ETF
  void _validateETF(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // ETF净值与市场价格差异通常不大
    if (navData.nav < Decimal.parse('0.1') ||
        navData.nav > Decimal.fromInt(100)) {
      warnings.add('ETF净值可能异常');
      confidenceScore -= 10.0;
    }
  }

  /// 验证普通基金
  void _validateOrdinaryFund(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 普通基金的累计净值应该合理增长
    if (navData.accumulatedNav < Decimal.one) {
      warnings.add('新基金累计净值较低');
      confidenceScore -= 3.0;
    }
  }

  /// 验证时间一致性
  void _validateTimeConsistency(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    final now = DateTime.now();
    final navDate = navData.navDate;
    final timestamp = navData.timestamp;

    // 净值日期通常是交易日 (周一到周五)
    if (navDate.weekday >= DateTime.saturday) {
      warnings.add('净值日期为周末，可能非交易日');
      confidenceScore -= 5.0;
    }

    // 数据时间戳应该接近净值日期
    final timeDifference = timestamp.difference(navDate);
    if (timeDifference.inDays > 7) {
      warnings.add('数据时间戳与净值日期差距过大');
      confidenceScore -= 10.0;
    }

    // 净值更新时间通常在交易结束后
    if (navDate.year == now.year &&
        navDate.month == now.month &&
        navDate.day == now.day) {
      if (timestamp.hour < 15) {
        // 当天净值在下午3点前更新
        warnings.add('净值更新时间过早，可能非最终净值');
        confidenceScore -= 5.0;
      }
    }
  }

  /// 评估数据质量
  void _assessDataQuality(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 数据新鲜度评估
    final age = DateTime.now().difference(navData.timestamp);
    if (age.inHours > 24) {
      warnings.add('数据过时 (${age.inHours}小时前)');
      confidenceScore -= age.inHours * 0.5;
    }

    // 数据完整性评估
    if (navData.qualityScore != null) {
      if (navData.qualityScore! < 50.0) {
        warnings.add('数据源质量评分较低 (${navData.qualityScore!.toStringAsFixed(1)})');
        confidenceScore -= (50.0 - navData.qualityScore!) * 0.5;
      }
    }

    // 扩展数据验证
    if (navData.extensions.isNotEmpty) {
      // 检查是否有异常的扩展数据
      for (final entry in navData.extensions.entries) {
        if (entry.value == null || entry.value.toString().isEmpty) {
          warnings.add('扩展数据字段 "${entry.key}" 值为空');
          confidenceScore -= 2.0;
        }
      }
    }
  }

  /// 执行交叉验证
  Future<void> _performCrossValidation(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) async {
    try {
      final history = _historicalData[navData.fundCode] ?? [];
      if (history.isEmpty) {
        // 添加到历史缓存
        _addToHistory(navData);
        return;
      }

      // 获取最近的历史数据
      final recentData = history.take(5).toList();
      if (recentData.isEmpty) {
        _addToHistory(navData);
        return;
      }

      final lastNav = recentData.first;

      // 1. 连续性验证 (净值日期应该连续)
      _validateContinuity(navData, lastNav, errors, warnings, confidenceScore);

      // 2. 变化合理性验证
      _validateChangeReasonableness(
          navData, lastNav, recentData, errors, warnings, confidenceScore);

      // 3. 趋势一致性验证
      _validateTrendConsistency(
          navData, recentData, errors, warnings, confidenceScore);

      // 添加到历史缓存
      _addToHistory(navData);
    } catch (e) {
      AppLogger.warn('Cross validation failed', e);
      warnings.add('交叉验证失败');
      confidenceScore -= 10.0;
    }
  }

  /// 验证数据连续性
  void _validateContinuity(
    FundNavData navData,
    FundNavData lastNav,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    final dateGap = navData.navDate.difference(lastNav.navDate).inDays;

    if (dateGap < 0) {
      errors.add('净值日期倒退 (${navData.navDate} < ${lastNav.navDate})');
      confidenceScore -= 50.0;
    } else if (dateGap > 7) {
      warnings.add('净值数据间隔过大 (${dateGap}天)');
      confidenceScore -= dateGap * 2.0;
    } else if (dateGap > 3) {
      warnings.add('净值数据间隔较长 (${dateGap}天)');
      confidenceScore -= dateGap;
    }
  }

  /// 验证变化合理性
  void _validateChangeReasonableness(
    FundNavData navData,
    FundNavData lastNav,
    List<FundNavData> recentData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 计算最近变化的统计信息
    final recentChanges =
        recentData.take(4).map((data) => data.changeRate.abs()).toList();

    if (recentChanges.isEmpty) return;

    // 转换为double进行计算，避免Decimal类型问题
    final sumDouble =
        recentChanges.map((d) => d.toDouble()).reduce((a, b) => a + b);
    final avgRecentChangeDouble = sumDouble / recentChanges.length;
    final avgRecentChange = Decimal.parse(avgRecentChangeDouble.toString());
    final currentChange = navData.changeRate.abs();

    // 当前变化是否远超近期平均变化
    // 转换为double进行比较以避免Decimal类型问题
    if (avgRecentChange != Decimal.zero) {
      final currentChangeDouble = currentChange.toDouble();
      final avgRecentChangeDouble = avgRecentChange.toDouble();

      if (currentChangeDouble > avgRecentChangeDouble * 5.0) {
        warnings.add('当前变化幅度远超近期平均水平');
        confidenceScore -= 25.0;
      } else if (currentChangeDouble > avgRecentChangeDouble * 3.0) {
        warnings.add('当前变化幅度较大');
        confidenceScore -= 15.0;
      }
    }
  }

  /// 验证趋势一致性
  void _validateTrendConsistency(
    FundNavData navData,
    List<FundNavData> recentData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    if (recentData.length < 3) return;

    // 计算近期趋势
    int positiveChanges = 0;
    int negativeChanges = 0;

    for (int i = 1; i < recentData.length; i++) {
      if (recentData[i].changeRate > Decimal.zero) {
        positiveChanges++;
      } else if (recentData[i].changeRate < Decimal.zero) {
        negativeChanges++;
      }
    }

    // 检查当前变化是否与趋势一致
    final currentChange = navData.changeRate;
    if (currentChange > Decimal.zero && negativeChanges > positiveChanges * 2) {
      warnings.add('当前上涨与近期下跌趋势不一致');
      confidenceScore -= 10.0;
    } else if (currentChange < Decimal.zero &&
        positiveChanges > negativeChanges * 2) {
      warnings.add('当前下跌与近期上涨趋势不一致');
      confidenceScore -= 10.0;
    }
  }

  /// 检测异常
  void _detectAnomalies(
    FundNavData navData,
    List<String> errors,
    List<String> warnings,
    double confidenceScore,
  ) {
    // 异常值检测
    if (navData.changeRate.abs() > Decimal.parse('0.2')) {
      // > 20%
      warnings.add('检测到异常变化，请确认数据准确性');
      confidenceScore -= 30.0;
    }

    // 重复数据检测
    final history = _historicalData[navData.fundCode] ?? [];
    for (final historical in history.take(5)) {
      if (historical.navDate == navData.navDate &&
          historical.nav == navData.nav) {
        warnings.add('检测到重复的净值数据');
        confidenceScore -= 20.0;
        break;
      }
    }

    // 数据格式异常检测
    if (navData.nav.toString().length > 10) {
      warnings.add('净值数据精度异常');
      confidenceScore -= 5.0;
    }
  }

  /// 计算最终置信度
  double _calculateFinalConfidence(
    List<String> errors,
    List<String> warnings,
    double currentScore,
  ) {
    // 基础分数
    var score = currentScore;

    // 错误扣分
    score -= errors.length * 20.0;

    // 警告扣分
    score -= warnings.length * 5.0;

    // 确保分数在0-100范围内
    return score.clamp(0.0, 100.0);
  }

  /// 计算变化率
  Decimal? _calculateChangeRate(FundNavData navData) {
    final history = _historicalData[navData.fundCode] ?? [];
    if (history.isEmpty) return null;

    final lastNav = history.first;
    if (lastNav.nav == Decimal.zero) return null;

    // 转换为double计算变化率，避免Decimal类型转换问题
    final changeRateDouble = (navData.nav.toDouble() - lastNav.nav.toDouble()) /
        lastNav.nav.toDouble();
    return Decimal.parse(changeRateDouble.toString());
  }

  /// 验证基金代码格式
  bool _isValidFundCodeFormat(String fundCode) {
    // 基金代码通常是6位数字
    if (fundCode.length == 6) {
      return RegExp(r'^\d{6}$').hasMatch(fundCode);
    }

    // 或者包含字母数字组合 (如ETF代码)
    return RegExp(r'^[A-Za-z0-9]{4,10}$').hasMatch(fundCode);
  }

  /// 添加到历史缓存
  void _addToHistory(FundNavData navData) {
    if (!_historicalData.containsKey(navData.fundCode)) {
      _historicalData[navData.fundCode] = [];
    }

    final history = _historicalData[navData.fundCode]!;
    history.insert(0, navData);

    // 保持历史数据在合理范围内
    while (history.length > 30) {
      history.removeLast();
    }
  }

  /// 清理历史缓存
  void clearHistory() {
    _historicalData.clear();
  }

  /// 清理指定基金的历史缓存
  void clearHistoryForFund(String fundCode) {
    _historicalData.remove(fundCode);
  }

  /// 获取历史缓存大小
  int getHistorySize() {
    return _historicalData.values.fold(0, (sum, list) => sum + list.length);
  }
}

/// 验证配置
class NavValidationConfig {
  /// 启用交叉验证
  final bool enableCrossValidation;

  /// 最小置信度分数
  final double minConfidenceScore;

  /// 启用严格模式
  final bool strictMode;

  /// 启用异常检测
  final bool enableAnomalyDetection;

  /// 历史数据窗口大小
  final int historyWindowSize;

  const NavValidationConfig({
    this.enableCrossValidation = true,
    this.minConfidenceScore = 60.0,
    this.strictMode = false,
    this.enableAnomalyDetection = true,
    this.historyWindowSize = 30,
  });
}

/// 验证结果
class NavValidationResult {
  /// 是否有效
  final bool isValid;

  /// 置信度分数 (0-100)
  final double confidenceScore;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 验证时间
  final DateTime validationTime;

  /// 被验证的净值数据
  final FundNavData navData;

  const NavValidationResult({
    required this.isValid,
    required this.confidenceScore,
    required this.errors,
    required this.warnings,
    required this.validationTime,
    required this.navData,
  });

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 验证级别
  ValidationLevel get level {
    if (confidenceScore >= 90.0) return ValidationLevel.excellent;
    if (confidenceScore >= 75.0) return ValidationLevel.good;
    if (confidenceScore >= 60.0) return ValidationLevel.fair;
    if (confidenceScore >= 40.0) return ValidationLevel.poor;
    return ValidationLevel.invalid;
  }

  @override
  String toString() {
    return 'NavValidationResult(valid: $isValid, confidence: ${confidenceScore.toStringAsFixed(1)}%, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}

/// 验证级别
enum ValidationLevel {
  excellent('优秀'),
  good('良好'),
  fair('一般'),
  poor('较差'),
  invalid('无效');

  const ValidationLevel(this.description);
  final String description;
}
