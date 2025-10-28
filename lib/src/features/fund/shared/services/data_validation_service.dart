import 'dart:async';
import 'dart:convert';

import '../../../../core/utils/logger.dart';
import '../../../../core/cache/interfaces/cache_service.dart';
import '../models/fund_ranking.dart';
import '../services/fund_data_service.dart';

/// 数据验证结果
class DataValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final DateTime validationTime;

  const DataValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.validationTime,
  });

  factory DataValidationResult.success() {
    return DataValidationResult(
      isValid: true,
      errors: [],
      warnings: [],
      validationTime: DateTime.now(),
    );
  }

  factory DataValidationResult.failure(List<String> errors,
      {List<String> warnings = const []}) {
    return DataValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      validationTime: DateTime.now(),
    );
  }

  factory DataValidationResult.warning(List<String> warnings) {
    return DataValidationResult(
      isValid: true,
      errors: [],
      warnings: warnings,
      validationTime: DateTime.now(),
    );
  }

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;

  /// 获取严重程度描述
  String get severityDescription {
    if (hasErrors) return '数据验证失败';
    if (hasWarnings) return '数据存在警告';
    return '数据验证通过';
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('DataValidationResult(');
    buffer.writeln('  isValid: $isValid,');
    buffer.writeln('  hasErrors: $hasErrors,');
    buffer.writeln('  hasWarnings: $hasWarnings,');
    if (hasErrors) {
      buffer.writeln('  errors: $errors,');
    }
    if (hasWarnings) {
      buffer.writeln('  warnings: $warnings,');
    }
    buffer.writeln('  validationTime: $validationTime');
    buffer.writeln(')');
    return buffer.toString();
  }
}

/// 数据一致性检查策略
enum ConsistencyCheckStrategy {
  /// 快速检查：仅检查基本数据结构
  quick,

  /// 标准检查：检查数据完整性和业务逻辑
  standard,

  /// 深度检查：全面的验证包括数据关联性
  deep,
}

/// 数据验证和一致性检查服务
///
/// 职责：
/// - 验证缓存数据的完整性和一致性
/// - 检测数据损坏或异常情况
/// - 提供数据恢复策略
/// - 监控数据质量变化趋势
class DataValidationService {
  final CacheService _cacheService;
  final FundDataService _fundDataService;

  // 验证配置
  static const Duration _maxCacheAge = Duration(hours: 12); // 最大缓存有效期
  static const int _minDataCount = 100; // 最少数据条数
  static const double _maxReturnRate = 2.0; // 最大收益率（过滤异常值）
  static const double _minFundSize = 0.1; // 最小基金规模
  static const double _maxFundSize = 10000.0; // 最大基金规模

  // 验证历史记录
  final List<DataValidationResult> _validationHistory = [];

  /// 构造函数
  DataValidationService({
    required CacheService cacheService,
    required FundDataService fundDataService,
  })  : _cacheService = cacheService,
        _fundDataService = fundDataService;

  /// 验证基金排行数据的一致性
  ///
  /// [data] 要验证的数据
  /// [strategy] 验证策略
  /// [cacheKey] 缓存键（用于缓存验证）
  Future<DataValidationResult> validateFundRankings(
    List<FundRanking> data, {
    ConsistencyCheckStrategy strategy = ConsistencyCheckStrategy.standard,
    String? cacheKey,
  }) async {
    AppLogger.debug(
        '🔍 DataValidationService: 开始验证基金数据一致性 (策略: $strategy, 数据量: ${data.length})');

    final errors = <String>[];
    final warnings = <String>[];
    final validationTime = DateTime.now();

    try {
      // 第一步：基础结构验证
      await _validateBasicStructure(data, errors, warnings);

      // 第二步：业务逻辑验证
      if (strategy != ConsistencyCheckStrategy.quick) {
        await _validateBusinessLogic(data, errors, warnings);
      }

      // 第三步：数据质量验证（深度检查）
      if (strategy == ConsistencyCheckStrategy.deep) {
        await _validateDataQuality(data, errors, warnings);
      }

      // 第四步：缓存一致性验证
      if (cacheKey != null) {
        await _validateCacheConsistency(cacheKey, data, errors, warnings);
      }

      // 创建验证结果
      final result = errors.isEmpty
          ? (warnings.isNotEmpty
              ? DataValidationResult.warning(warnings)
              : DataValidationResult.success())
          : DataValidationResult.failure(errors, warnings: warnings);

      // 记录验证历史
      _recordValidation(result);

      AppLogger.debug(
          '✅ DataValidationService: 验证完成 - ${result.severityDescription}');
      return result;
    } catch (e) {
      AppLogger.error('❌ DataValidationService: 验证过程中发生异常', e);
      final errorResult = DataValidationResult.failure(['验证过程异常: $e']);
      _recordValidation(errorResult);
      return errorResult;
    }
  }

  /// 验证基础数据结构
  Future<void> _validateBasicStructure(
    List<FundRanking> data,
    List<String> errors,
    List<String> warnings,
  ) async {
    AppLogger.debug('🔍 DataValidationService: 验证基础数据结构');

    // 检查数据量
    if (data.isEmpty) {
      errors.add('数据为空');
      return;
    }

    if (data.length < _minDataCount) {
      warnings.add('数据量过少 (${data.length} < $_minDataCount)，可能不完整');
    }

    // 检查必填字段
    for (int i = 0; i < data.length; i++) {
      final fund = data[i];

      if (fund.fundCode.isEmpty) {
        errors.add('基金[$i] 基金代码为空');
      }

      if (fund.fundName.isEmpty) {
        errors.add('基金[${fund.fundCode}] 基金名称为空');
      }

      if (fund.fundType.isEmpty) {
        warnings.add('基金[${fund.fundCode}] 基金类型为空');
      }

      if (fund.rank <= 0) {
        warnings.add('基金[${fund.fundCode}] 排名异常: ${fund.rank}');
      }

      if (fund.nav <= 0) {
        errors.add('基金[${fund.fundCode}] 净值异常: ${fund.nav}');
      }

      if (fund.updateDate == null) {
        warnings.add('基金[${fund.fundCode}] 更新日期为空');
      } else if (fund.updateDate!
          .isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        warnings.add('基金[${fund.fundCode}] 数据可能过期 (${fund.updateDate})');
      }
    }

    // 检查基金代码唯一性
    final fundCodes = data.map((f) => f.fundCode).toList();
    final uniqueCodes = fundCodes.toSet();
    if (fundCodes.length != uniqueCodes.length) {
      final duplicates = fundCodes
          .where((code) => fundCodes.where((c) => c == code).length > 1)
          .toSet();
      errors.add('发现重复的基金代码: ${duplicates.join(', ')}');
    }
  }

  /// 验证业务逻辑
  Future<void> _validateBusinessLogic(
    List<FundRanking> data,
    List<String> errors,
    List<String> warnings,
  ) async {
    AppLogger.debug('🔍 DataValidationService: 验证业务逻辑');

    for (final fund in data) {
      // 检查收益率范围
      if (fund.dailyReturn.abs() > _maxReturnRate) {
        warnings.add(
            '基金[${fund.fundCode}] 日收益率异常: ${fund.formatReturn(fund.dailyReturn)}');
      }

      if (fund.oneYearReturn.abs() > _maxReturnRate) {
        warnings.add(
            '基金[${fund.fundCode}] 年收益率异常: ${fund.formatReturn(fund.oneYearReturn)}');
      }

      if (fund.threeYearReturn.abs() > _maxReturnRate * 3) {
        warnings.add(
            '基金[${fund.fundCode}] 三年收益率异常: ${fund.formatReturn(fund.threeYearReturn)}');
      }

      // 检查基金规模
      if (fund.fundSize < _minFundSize) {
        warnings.add('基金[${fund.fundCode}] 基金规模过小: ${fund.formatFundSize()}');
      }

      if (fund.fundSize > _maxFundSize) {
        warnings.add('基金[${fund.fundCode}] 基金规模过大: ${fund.formatFundSize()}');
      }

      // 检查排名连续性
      if (fund.rank <= 0 || fund.rank > data.length) {
        warnings.add(
            '基金[${fund.fundCode}] 排名超出范围: ${fund.rank} (1-${data.length})');
      }
    }

    // 检查排名唯一性
    final ranks = data.map((f) => f.rank).where((r) => r > 0).toList();
    final uniqueRanks = ranks.toSet();
    if (ranks.length != uniqueRanks.length) {
      final duplicateRanks = ranks
          .where((rank) => ranks.where((r) => r == rank).length > 1)
          .toSet();
      warnings.add('发现重复的排名: ${duplicateRanks.join(', ')}');
    }
  }

  /// 验证数据质量
  Future<void> _validateDataQuality(
    List<FundRanking> data,
    List<String> errors,
    List<String> warnings,
  ) async {
    AppLogger.debug('🔍 DataValidationService: 验证数据质量');

    // 检查数据分布
    final returns = data.map((f) => f.oneYearReturn).toList();
    returns.sort();

    final medianReturn = returns[returns.length ~/ 2];
    final q1Return = returns[returns.length ~/ 4];
    final q3Return = returns[(returns.length * 3) ~/ 4];

    // 检查异常值
    final iqr = q3Return - q1Return;
    final lowerBound = q1Return - 1.5 * iqr;
    final upperBound = q3Return + 1.5 * iqr;

    final outliers = data
        .where(
            (f) => f.oneYearReturn < lowerBound || f.oneYearReturn > upperBound)
        .toList();
    if (outliers.length > data.length * 0.1) {
      // 超过10%的数据是异常值
      warnings.add('收益率异常值过多 (${outliers.length}/${data.length})，可能数据质量有问题');
    }

    // 检查基金类型分布
    final typeDistribution = <String, int>{};
    for (final fund in data) {
      final type = fund.shortType;
      typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
    }

    // 检查是否有单一类型占比过高
    final maxTypeCount = typeDistribution.values
        .fold(0, (max, count) => count > max ? count : max);
    if (maxTypeCount > data.length * 0.8) {
      warnings.add('基金类型分布不均，某一类型占比过高');
    }

    AppLogger.debug(
        '🔍 DataValidationService: 数据质量分析完成，中位数收益率: ${medianReturn.toStringAsFixed(2)}%');
  }

  /// 验证缓存一致性
  Future<void> _validateCacheConsistency(
    String cacheKey,
    List<FundRanking> data,
    List<String> errors,
    List<String> warnings,
  ) async {
    AppLogger.debug('🔍 DataValidationService: 验证缓存一致性');

    try {
      // 检查缓存是否存在
      if (!await _cacheService.containsKey(cacheKey)) {
        warnings.add('缓存键不存在: $cacheKey');
        return;
      }

      // 获取缓存数据
      final cachedData = await _cacheService.get<String>(cacheKey);
      if (cachedData == null) {
        errors.add('缓存数据为空: $cacheKey');
        return;
      }

      // 解析缓存数据
      final jsonData = jsonDecode(cachedData);
      final List<dynamic> cachedRankings = jsonData['rankings'] ?? [];
      final String? timestamp = jsonData['timestamp'];

      // 检查缓存时间戳
      if (timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        final age = DateTime.now().difference(cacheTime);

        if (age > _maxCacheAge) {
          warnings.add('缓存数据过期 (${age.inHours}小时 > ${_maxCacheAge.inHours}小时)');
        }
      }

      // 检查数据量一致性
      if (cachedRankings.length != data.length) {
        warnings
            .add('缓存数据量不一致 (缓存:${cachedRankings.length} vs 当前:${data.length})');
      }

      // 检查数据内容一致性（抽样检查）
      final sampleSize = (data.length * 0.1).clamp(1, 10).toInt();
      for (int i = 0; i < sampleSize; i++) {
        final index = (i * data.length ~/ sampleSize).clamp(0, data.length - 1);
        final currentFund = data[index];

        if (index < cachedRankings.length) {
          final cachedFund = FundRanking.fromJson(
            Map<String, dynamic>.from(cachedRankings[index]),
            index + 1,
          );

          if (currentFund.fundCode != cachedFund.fundCode ||
              currentFund.fundName != cachedFund.fundName) {
            warnings.add(
                '缓存数据内容不一致 (索引:$index, 代码:${currentFund.fundCode} vs ${cachedFund.fundCode})');
            break; // 发现不一致就停止抽样
          }
        }
      }
    } catch (e) {
      warnings.add('缓存一致性检查失败: $e');
    }
  }

  /// 尝试修复损坏的数据
  Future<List<FundRanking>?> repairCorruptedData(
    List<FundRanking> corruptedData, {
    String? cacheKey,
    bool forceRefetch = false,
  }) async {
    AppLogger.debug(
        '🔧 DataValidationService: 尝试修复损坏的数据 (数据量: ${corruptedData.length})');

    try {
      // 策略1：如果缓存键存在，尝试从缓存恢复
      if (cacheKey != null && !forceRefetch) {
        final cachedData = await _recoverFromCache(cacheKey);
        if (cachedData != null) {
          AppLogger.info(
              '✅ DataValidationService: 从缓存恢复数据成功 (${cachedData.length}条)');
          return cachedData;
        }
      }

      // 策略2：尝试从API重新获取数据
      AppLogger.info('🌐 DataValidationService: 尝试从API重新获取数据');
      final result = await _fundDataService.getFundRankings(forceRefresh: true);

      if (result.isSuccess && result.data!.isNotEmpty) {
        AppLogger.info(
            '✅ DataValidationService: 从API恢复数据成功 (${result.data!.length}条)');
        return result.data;
      }

      // 策略3：尝试修复现有数据
      AppLogger.info('🔧 DataValidationService: 尝试修复现有数据');
      final repairedData = _attemptDataRepair(corruptedData);
      if (repairedData.isNotEmpty) {
        AppLogger.info(
            '✅ DataValidationService: 数据修复成功 (${repairedData.length}条)');
        return repairedData;
      }

      AppLogger.warn('❌ DataValidationService: 所有数据恢复策略都失败了');
      return null;
    } catch (e) {
      AppLogger.error('❌ DataValidationService: 数据修复过程中发生异常', e);
      return null;
    }
  }

  /// 从缓存恢复数据
  Future<List<FundRanking>?> _recoverFromCache(String cacheKey) async {
    try {
      final cachedData = await _cacheService.get<String>(cacheKey);
      if (cachedData == null) return null;

      final jsonData = jsonDecode(cachedData);
      final List<dynamic> cachedRankings = jsonData['rankings'] ?? [];

      final rankings = cachedRankings.map((item) {
        return FundRanking.fromJson(
          Map<String, dynamic>.from(item),
          cachedRankings.indexOf(item) + 1,
        );
      }).toList();

      return rankings;
    } catch (e) {
      AppLogger.warn('⚠️ DataValidationService: 从缓存恢复数据失败', e);
      return null;
    }
  }

  /// 尝试修复现有数据
  List<FundRanking> _attemptDataRepair(List<FundRanking> corruptedData) {
    final repairedData = <FundRanking>[];

    for (int i = 0; i < corruptedData.length; i++) {
      final fund = corruptedData[i];

      try {
        // 修复基金代码
        final fundCode = fund.fundCode.isNotEmpty
            ? fund.fundCode
            : 'UNKNOWN_${i.toString().padLeft(6, '0')}';

        // 修复基金名称
        final fundName = fund.fundName.isNotEmpty ? fund.fundName : '未知基金';

        // 修复基金类型
        final fundType = fund.fundType.isNotEmpty ? fund.fundType : '未知类型';

        // 修复净值
        final nav = fund.nav > 0 ? fund.nav : 1.0;

        // 修复收益率（限制在合理范围内）
        final dailyReturn =
            fund.dailyReturn.abs() > _maxReturnRate ? 0.0 : fund.dailyReturn;
        final oneYearReturn = fund.oneYearReturn.abs() > _maxReturnRate
            ? 0.0
            : fund.oneYearReturn;
        final threeYearReturn =
            fund.threeYearReturn.abs() > (_maxReturnRate * 3)
                ? 0.0
                : fund.threeYearReturn;

        // 修复基金规模
        final fundSize = fund.fundSize.clamp(_minFundSize, _maxFundSize);

        // 修复更新日期
        final updateDate = fund.updateDate ?? DateTime.now();

        // 创建修复后的基金对象
        final repairedFund = FundRanking(
          fundCode: fundCode,
          fundName: fundName,
          fundType: fundType,
          rank: i + 1,
          nav: nav,
          dailyReturn: dailyReturn,
          oneYearReturn: oneYearReturn,
          threeYearReturn: threeYearReturn,
          fundSize: fundSize,
          updateDate: updateDate,
          fundCompany: fund.fundCompany.isNotEmpty ? fund.fundCompany : '未知公司',
          fundManager: fund.fundManager.isNotEmpty ? fund.fundManager : '未知经理',
        );

        repairedData.add(repairedFund);
      } catch (e) {
        AppLogger.warn('⚠️ DataValidationService: 跳过无法修复的基金数据 [$i]: $e');
        // 继续处理其他数据
      }
    }

    return repairedData;
  }

  /// 清理损坏的缓存
  Future<void> cleanupCorruptedCache(String cacheKey) async {
    try {
      if (await _cacheService.containsKey(cacheKey)) {
        await _cacheService.remove(cacheKey);
        AppLogger.info('🗑️ DataValidationService: 已清理损坏的缓存: $cacheKey');
      }
    } catch (e) {
      AppLogger.error('❌ DataValidationService: 清理缓存失败', e);
    }
  }

  /// 获取验证历史记录
  List<DataValidationResult> getValidationHistory({int limit = 10}) {
    return _validationHistory.reversed.take(limit).toList();
  }

  /// 获取最近验证结果
  DataValidationResult? getLastValidationResult() {
    return _validationHistory.isNotEmpty ? _validationHistory.last : null;
  }

  /// 清空验证历史记录
  void clearValidationHistory() {
    _validationHistory.clear();
    AppLogger.debug('🗑️ DataValidationService: 已清空验证历史记录');
  }

  /// 记录验证结果
  void _recordValidation(DataValidationResult result) {
    _validationHistory.add(result);

    // 限制历史记录数量
    if (_validationHistory.length > 100) {
      _validationHistory.removeRange(0, _validationHistory.length - 100);
    }
  }

  /// 获取数据质量统计
  Map<String, dynamic> getDataQualityStatistics() {
    if (_validationHistory.isEmpty) {
      return {
        'totalValidations': 0,
        'successRate': 0.0,
        'averageErrors': 0.0,
        'averageWarnings': 0.0,
        'lastValidationTime': null,
      };
    }

    final totalValidations = _validationHistory.length;
    final successfulValidations =
        _validationHistory.where((r) => r.isValid).length;
    final totalErrors =
        _validationHistory.fold(0, (sum, r) => sum + r.errors.length);
    final totalWarnings =
        _validationHistory.fold(0, (sum, r) => sum + r.warnings.length);
    final lastValidationTime = _validationHistory.last.validationTime;

    return {
      'totalValidations': totalValidations,
      'successRate': successfulValidations / totalValidations,
      'averageErrors': totalErrors / totalValidations,
      'averageWarnings': totalWarnings / totalValidations,
      'lastValidationTime': lastValidationTime.toIso8601String(),
    };
  }
}
