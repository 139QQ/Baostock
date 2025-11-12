import 'package:decimal/decimal.dart';

import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';

/// 指数数据验证器
///
/// 负责验证市场指数数据的准确性、完整性和合理性
class IndexDataValidator {
  /// 验证参数
  final IndexValidationParameters _parameters;

  /// 构造函数
  IndexDataValidator({
    IndexValidationParameters? parameters,
  }) : _parameters = parameters ?? IndexValidationParameters();

  /// 验证指数数据
  ValidationResult validate(MarketIndexData data) {
    final issues = <ValidationIssue>[];

    // 1. 基本字段验证
    issues.addAll(_validateBasicFields(data));

    // 2. 数值合理性验证
    issues.addAll(_validateNumericReasonableness(data));

    // 3. 逻辑一致性验证
    issues.addAll(_validateLogicalConsistency(data));

    // 4. 时间有效性验证
    issues.addAll(_validateTimeliness(data));

    // 5. 数据质量评估
    final qualityLevel = _assessDataQuality(data, issues);

    final result = ValidationResult(
      isValid:
          issues.every((issue) => issue.severity != ValidationSeverity.error),
      qualityLevel: qualityLevel,
      issues: issues,
      timestamp: DateTime.now(),
    );

    // 记录验证结果
    if (!result.isValid) {
      final errorIssues =
          issues.where((i) => i.severity == ValidationSeverity.error);
      AppLogger.warn(
          'Index data validation failed for ${data.code}: ${errorIssues.map((i) => i.message).join(', ')}');
    }

    return result;
  }

  /// 验证基本字段
  List<ValidationIssue> _validateBasicFields(MarketIndexData data) {
    final issues = <ValidationIssue>[];

    // 验证指数代码
    if (data.code.isEmpty) {
      issues.add(ValidationIssue(
        field: 'code',
        message: '指数代码不能为空',
        severity: ValidationSeverity.error,
      ));
    } else if (!_isValidIndexCode(data.code)) {
      issues.add(ValidationIssue(
        field: 'code',
        message: '指数代码格式无效: ${data.code}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证指数名称
    if (data.name.isEmpty) {
      issues.add(ValidationIssue(
        field: 'name',
        message: '指数名称不能为空',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证更新时间
    if (data.updateTime.isAfter(DateTime.now().add(Duration(minutes: 5)))) {
      issues.add(ValidationIssue(
        field: 'updateTime',
        message: '更新时间不能是未来时间',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证数据来源
    if (data.dataSource.isEmpty) {
      issues.add(ValidationIssue(
        field: 'dataSource',
        message: '数据来源不能为空',
        severity: ValidationSeverity.warning,
      ));
    }

    return issues;
  }

  /// 验证指数代码格式
  bool _isValidIndexCode(String code) {
    // 基本格式验证
    if (code.length < 6 || code.length > 10) return false;

    // 检查是否包含字母和数字
    final hasLetter = code.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = code.contains(RegExp(r'[0-9]'));

    return hasLetter && hasNumber;
  }

  /// 验证数值合理性
  List<ValidationIssue> _validateNumericReasonableness(MarketIndexData data) {
    final issues = <ValidationIssue>[];

    // 验证当前值
    if (data.currentValue <= Decimal.zero) {
      issues.add(ValidationIssue(
        field: 'currentValue',
        message: '当前值必须大于零: ${data.currentValue}',
        severity: ValidationSeverity.error,
      ));
    } else if (data.currentValue > _parameters.maxIndexValue) {
      issues.add(ValidationIssue(
        field: 'currentValue',
        message: '当前值超出合理范围: ${data.currentValue}',
        severity: ValidationSeverity.warning,
      ));
    } else if (data.currentValue < _parameters.minIndexValue) {
      issues.add(ValidationIssue(
        field: 'currentValue',
        message: '当前值低于合理范围: ${data.currentValue}',
        severity: ValidationSeverity.warning,
      ));
    }

    // 验证前收盘价
    if (data.previousClose <= Decimal.zero) {
      issues.add(ValidationIssue(
        field: 'previousClose',
        message: '前收盘价必须大于零: ${data.previousClose}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证开盘价
    if (data.openPrice <= Decimal.zero) {
      issues.add(ValidationIssue(
        field: 'openPrice',
        message: '开盘价必须大于零: ${data.openPrice}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证最高价
    if (data.highPrice <= Decimal.zero) {
      issues.add(ValidationIssue(
        field: 'highPrice',
        message: '最高价必须大于零: ${data.highPrice}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证最低价
    if (data.lowPrice <= Decimal.zero) {
      issues.add(ValidationIssue(
        field: 'lowPrice',
        message: '最低价必须大于零: ${data.lowPrice}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证成交量
    if (data.volume < 0) {
      issues.add(ValidationIssue(
        field: 'volume',
        message: '成交量不能为负数: ${data.volume}',
        severity: ValidationSeverity.error,
      ));
    } else if (data.volume > _parameters.maxVolume) {
      issues.add(ValidationIssue(
        field: 'volume',
        message: '成交量超出合理范围: ${data.volume}',
        severity: ValidationSeverity.warning,
      ));
    }

    // 验证成交额
    if (data.turnover < Decimal.zero) {
      issues.add(ValidationIssue(
        field: 'turnover',
        message: '成交额不能为负数: ${data.turnover}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证涨跌幅
    if (data.changePercentage.abs() > _parameters.maxChangePercentage) {
      issues.add(ValidationIssue(
        field: 'changePercentage',
        message: '涨跌幅超出合理范围: ${data.changePercentage}%',
        severity: ValidationSeverity.warning,
      ));
    }

    return issues;
  }

  /// 验证逻辑一致性
  List<ValidationIssue> _validateLogicalConsistency(MarketIndexData data) {
    final issues = <ValidationIssue>[];

    // 验证价格关系：最高价 >= 当前价 >= 最低价
    if (data.highPrice < data.currentValue) {
      issues.add(ValidationIssue(
        field: 'highPrice',
        message: '最高价不能低于当前价: ${data.highPrice} < ${data.currentValue}',
        severity: ValidationSeverity.error,
      ));
    }

    if (data.lowPrice > data.currentValue) {
      issues.add(ValidationIssue(
        field: 'lowPrice',
        message: '最低价不能高于当前价: ${data.lowPrice} > ${data.currentValue}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证最高价 >= 最低价
    if (data.highPrice < data.lowPrice) {
      issues.add(ValidationIssue(
        field: 'highPrice',
        message: '最高价不能低于最低价: ${data.highPrice} < ${data.lowPrice}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证涨跌点数计算
    final expectedChangeAmount = data.currentValue - data.previousClose;
    if ((expectedChangeAmount - data.changeAmount).abs() >
        Decimal.parse('0.01')) {
      issues.add(ValidationIssue(
        field: 'changeAmount',
        message:
            '涨跌点数计算错误: 期望 ${expectedChangeAmount}, 实际 ${data.changeAmount}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证涨跌幅计算
    if (data.previousClose != Decimal.zero) {
      final Decimal expectedChangePercentage = Decimal.parse(
        ((expectedChangeAmount * Decimal.fromInt(100)) / data.previousClose)
            .toString(),
      );
      if ((expectedChangePercentage - data.changePercentage).abs() >
          Decimal.parse('0.01')) {
        issues.add(ValidationIssue(
          field: 'changePercentage',
          message:
              '涨跌幅计算错误: 期望 ${expectedChangePercentage}%, 实际 ${data.changePercentage}%',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // 验证开盘价与当日高低价关系
    if (data.openPrice > data.highPrice) {
      issues.add(ValidationIssue(
        field: 'openPrice',
        message: '开盘价不能高于最高价: ${data.openPrice} > ${data.highPrice}',
        severity: ValidationSeverity.error,
      ));
    }

    if (data.openPrice < data.lowPrice) {
      issues.add(ValidationIssue(
        field: 'openPrice',
        message: '开盘价不能低于最低价: ${data.openPrice} < ${data.lowPrice}',
        severity: ValidationSeverity.error,
      ));
    }

    // 验证成交额与成交量的合理性
    if (data.volume > 0) {
      final Decimal averagePrice = Decimal.parse(
          (data.turnover / Decimal.fromInt(data.volume)).toString());
      if (averagePrice < Decimal.one ||
          averagePrice > data.currentValue * Decimal.fromInt(2)) {
        issues.add(ValidationIssue(
          field: 'turnover',
          message: '成交额与成交量不合理，平均价格异常: ${averagePrice}',
          severity: ValidationSeverity.warning,
        ));
      }
    }

    return issues;
  }

  /// 验证时间有效性
  List<ValidationIssue> _validateTimeliness(MarketIndexData data) {
    final issues = <ValidationIssue>[];

    final now = DateTime.now();
    final dataAge = now.difference(data.updateTime);

    // 检查数据是否过期
    if (dataAge > _parameters.maxDataAge) {
      issues.add(ValidationIssue(
        field: 'updateTime',
        message: '数据过期，更新时间: ${data.updateTime}, 当前时间: $now',
        severity: ValidationSeverity.warning,
      ));
    }

    // 检查更新时间的合理性
    if (dataAge < Duration.zero) {
      issues.add(ValidationIssue(
        field: 'updateTime',
        message: '更新时间在未来: ${data.updateTime}',
        severity: ValidationSeverity.error,
      ));
    }

    // 检查是否在交易时间之外有大幅更新
    if (!_isTradingTime(data.updateTime) &&
        data.changePercentage.abs() > Decimal.fromInt(1)) {
      issues.add(ValidationIssue(
        field: 'updateTime',
        message: '非交易时间出现大幅价格变化: ${data.changePercentage}%',
        severity: ValidationSeverity.info,
      ));
    }

    return issues;
  }

  /// 检查是否为交易时间
  bool _isTradingTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final weekday = time.weekday;

    // 周末不是交易日
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return false;
    }

    // 上午交易时间 9:30-11:30
    if ((hour == 9 && minute >= 30) ||
        (hour == 10) ||
        (hour == 11 && minute <= 30)) {
      return true;
    }

    // 下午交易时间 13:00-15:00
    if (hour >= 13 && hour < 15) {
      return true;
    }

    return false;
  }

  /// 评估数据质量
  DataQualityLevel _assessDataQuality(
      MarketIndexData data, List<ValidationIssue> issues) {
    // 统计不同严重程度的issue数量
    final errorCount =
        issues.where((i) => i.severity == ValidationSeverity.error).length;
    final warningCount =
        issues.where((i) => i.severity == ValidationSeverity.warning).length;
    final infoCount =
        issues.where((i) => i.severity == ValidationSeverity.info).length;

    // 有错误则质量为差
    if (errorCount > 0) {
      return DataQualityLevel.poor;
    }

    // 多个警告则质量为一般
    if (warningCount >= 3) {
      return DataQualityLevel.fair;
    }

    // 有少量警告则质量为良好
    if (warningCount > 0 || infoCount >= 2) {
      return DataQualityLevel.good;
    }

    // 无问题则质量为优秀
    return DataQualityLevel.excellent;
  }

  /// 批量验证多个指数数据
  List<ValidationResult> validateBatch(List<MarketIndexData> dataList) {
    return dataList.map((data) => validate(data)).toList();
  }

  /// 获取验证统计信息
  ValidationStatistics getValidationStatistics(List<ValidationResult> results) {
    int validCount = 0;
    int invalidCount = 0;
    final qualityCounts = <DataQualityLevel, int>{};

    for (final result in results) {
      if (result.isValid) {
        validCount++;
      } else {
        invalidCount++;
      }

      qualityCounts[result.qualityLevel] =
          (qualityCounts[result.qualityLevel] ?? 0) + 1;
    }

    return ValidationStatistics(
      total: results.length,
      valid: validCount,
      invalid: invalidCount,
      qualityDistribution: qualityCounts,
      timestamp: DateTime.now(),
    );
  }
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final DataQualityLevel qualityLevel;
  final List<ValidationIssue> issues;
  final DateTime timestamp;

  const ValidationResult({
    required this.isValid,
    required this.qualityLevel,
    required this.issues,
    required this.timestamp,
  });

  /// 获取错误信息
  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == ValidationSeverity.error).toList();

  /// 获取警告信息
  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == ValidationSeverity.warning).toList();

  /// 获取信息提示
  List<ValidationIssue> get infos =>
      issues.where((i) => i.severity == ValidationSeverity.info).toList();

  /// 是否有任何问题
  bool get hasIssues => issues.isNotEmpty;

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, quality: $qualityLevel, issues: ${issues.length})';
  }
}

/// 验证问题
class ValidationIssue {
  final String field;
  final String message;
  final ValidationSeverity severity;
  final DateTime timestamp;

  ValidationIssue({
    required this.field,
    required this.message,
    required this.severity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'ValidationIssue(field: $field, severity: $severity, message: $message)';
  }
}

/// 验证严重程度
enum ValidationSeverity {
  /// 错误 - 数据不可用
  error,

  /// 警告 - 数据可用但有问题
  warning,

  /// 信息 - 提示性信息
  info;

  String get description {
    switch (this) {
      case ValidationSeverity.error:
        return '错误';
      case ValidationSeverity.warning:
        return '警告';
      case ValidationSeverity.info:
        return '信息';
    }
  }
}

/// 验证参数
class IndexValidationParameters {
  /// 最小指数值
  final Decimal minIndexValue;

  /// 最大指数值
  final Decimal maxIndexValue;

  /// 最大成交量
  final int maxVolume;

  /// 最大涨跌幅百分比
  final Decimal maxChangePercentage;

  /// 最大数据年龄
  final Duration maxDataAge;

  IndexValidationParameters({
    Decimal? minIndexValue,
    Decimal? maxIndexValue,
    this.maxVolume = 10000000000, // 100亿手
    Decimal? maxChangePercentage,
    this.maxDataAge = const Duration(minutes: 15),
  })  : minIndexValue = minIndexValue ?? Decimal.parse('1'),
        maxIndexValue = maxIndexValue ?? Decimal.parse('100000'),
        maxChangePercentage = maxChangePercentage ?? Decimal.parse('20');
}

/// 验证统计信息
class ValidationStatistics {
  final int total;
  final int valid;
  final int invalid;
  final Map<DataQualityLevel, int> qualityDistribution;
  final DateTime timestamp;

  const ValidationStatistics({
    required this.total,
    required this.valid,
    required this.invalid,
    required this.qualityDistribution,
    required this.timestamp,
  });

  /// 验证通过率
  double get passRate => total > 0 ? valid / total : 0.0;

  @override
  String toString() {
    return 'ValidationStatistics(total: $total, valid: $valid, invalid: $invalid, passRate: ${(passRate * 100).toStringAsFixed(1)}%)';
  }
}
