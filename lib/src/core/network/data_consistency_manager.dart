import 'dart:convert';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'multi_source_api_config.dart';

/// 数据一致性管理器
class DataConsistencyManager {
  // 移除Logger依赖，使用debugPrint

  final Map<String, DataConsistencyRule> _consistencyRules = {};
  final Map<String, ConsistencyMetadata> _consistencyCache = {};
  final Queue<ConsistencyViolation> _violationLog = Queue();

  /// 最大违规记录数
  static int maxViolationLogSize = 1000;

  DataConsistencyManager() {
    _initializeDefaultRules();
  }

  /// 初始化默认一致性规则
  void _initializeDefaultRules() {
    // 基金基本信息一致性规则
    _consistencyRules['fund_basic'] = DataConsistencyRule(
      name: 'fund_basic',
      version: '1.0.0',
      checksumFields: ['fund_code', 'fund_name', 'fund_type', 'establish_date'],
      allowedVariance: 0.02, // 允许2%的差异
      validationWindow: const Duration(minutes: 15),
      fallbackStrategy: FallbackStrategy.useMostRecent,
    );

    // 基金净值一致性规则
    _consistencyRules['fund_nav'] = DataConsistencyRule(
      name: 'fund_nav',
      version: '1.0.0',
      checksumFields: ['nav_date', 'unit_nav', 'accumulated_nav'],
      allowedVariance: 0.001, // 允许0.1%的差异（净值精度要求高）
      validationWindow: const Duration(minutes: 5),
      fallbackStrategy: FallbackStrategy.useAverage,
    );

    // 基金排行一致性规则
    _consistencyRules['fund_ranking'] = DataConsistencyRule(
      name: 'fund_ranking',
      version: '1.0.0',
      checksumFields: ['ranking_date', 'fund_code', 'return_1y'],
      allowedVariance: 0.05, // 允许5%的差异
      validationWindow: const Duration(minutes: 30),
      fallbackStrategy: FallbackStrategy.useMedian,
    );

    // 基金持仓一致性规则
    _consistencyRules['fund_holding'] = DataConsistencyRule(
      name: 'fund_holding',
      version: '1.0.0',
      checksumFields: ['stock_code', 'stock_name', 'holding_ratio'],
      allowedVariance: 0.03, // 允许3%的差异
      validationWindow: const Duration(days: 1),
      fallbackStrategy: FallbackStrategy.useMostRecent,
    );
  }

  /// 验证数据一致性
  Future<ConsistencyResult> validateConsistency(
    String dataType,
    List<Map<String, dynamic>> data,
    ApiSource source,
  ) async {
    final rule = _consistencyRules[dataType];
    if (rule == null) {
      debugPrint('⚠️ 未找到数据类型 $dataType 的一致性规则');
      return ConsistencyResult(
        isValid: true,
        confidence: 1.0,
        message: '无一致性规则，跳过验证',
      );
    }

    try {
      // 计算数据校验和
      final checksum = _calculateChecksum(data, rule.checksumFields);

      // 获取历史一致性元数据
      final metadata = _getConsistencyMetadata(dataType);

      // 验证数据一致性
      final validation = _performConsistencyValidation(
        dataType: dataType,
        currentChecksum: checksum,
        currentData: data,
        metadata: metadata,
        rule: rule,
        source: source,
      );

      // 更新一致性元数据
      _updateConsistencyMetadata(
        dataType: dataType,
        checksum: checksum,
        data: data,
        source: source,
        isValid: validation.isValid,
      );

      // 记录违规情况
      if (!validation.isValid) {
        _recordViolation(ConsistencyViolation(
          dataType: dataType,
          timestamp: DateTime.now(),
          expectedChecksum: metadata.lastValidChecksum,
          actualChecksum: checksum,
          source: source,
          message: validation.message,
          severity: validation.severity,
        ));
      }

      return validation;
    } catch (e) {
      debugPrint('❌ 一致性验证失败 - $dataType: $e');
      return ConsistencyResult(
        isValid: false,
        confidence: 0.0,
        message: '一致性验证过程失败: $e',
        severity: ConsistencySeverity.error,
      );
    }
  }

  /// 执行一致性验证
  ConsistencyResult _performConsistencyValidation({
    required String dataType,
    required String currentChecksum,
    required List<Map<String, dynamic>> currentData,
    required ConsistencyMetadata metadata,
    required DataConsistencyRule rule,
    required ApiSource source,
  }) {
    // 如果是首次验证，直接通过
    if (metadata.lastValidChecksum == null) {
      return ConsistencyResult(
        isValid: true,
        confidence: 1.0,
        message: '首次数据验证通过',
      );
    }

    // 检查时间窗口
    final timeSinceLastValid =
        DateTime.now().difference(metadata.lastValidTimestamp);
    if (timeSinceLastValid > rule.validationWindow) {
      return ConsistencyResult(
        isValid: true,
        confidence: 0.8,
        message: '超过验证窗口，重新建立基准',
      );
    }

    // 计算校验和差异
    final checksumDifference = _calculateChecksumDifference(
      metadata.lastValidChecksum!,
      currentChecksum,
    );

    // 检查差异是否在允许范围内
    if (checksumDifference <= rule.allowedVariance) {
      return ConsistencyResult(
        isValid: true,
        confidence: 1.0 - (checksumDifference / rule.allowedVariance) * 0.2,
        message: '数据一致性验证通过',
        details: {
          'checksum_difference': checksumDifference,
          'allowed_variance': rule.allowedVariance,
        },
      );
    }

    // 超出允许差异范围
    debugPrint(
        '⚠️ 数据一致性检查失败 - $dataType: 差异 $checksumDifference > 允许 ${rule.allowedVariance}');

    return ConsistencyResult(
      isValid: false,
      confidence: 0.3,
      message: '数据一致性验证失败：校验和差异过大',
      severity: ConsistencySeverity.warning,
      details: {
        'checksum_difference': checksumDifference,
        'allowed_variance': rule.allowedVariance,
        'last_valid_checksum': metadata.lastValidChecksum,
        'current_checksum': currentChecksum,
      },
    );
  }

  /// 计算校验和
  String _calculateChecksum(
    List<Map<String, dynamic>> data,
    List<String> fields,
  ) {
    final normalizedData = data.map((item) {
      final filteredItem = <String, dynamic>{};
      for (final field in fields) {
        filteredItem[field] = item[field]?.toString() ?? '';
      }
      return filteredItem;
    }).toList();

    // 排序以确保一致性
    normalizedData.sort((a, b) => a.toString().compareTo(b.toString()));

    final jsonString = jsonEncode(normalizedData);
    final bytes = utf8.encode(jsonString);

    // 简单的校验和计算替代sha256
    int hash = 0;
    for (final byte in bytes) {
      hash = ((hash << 5) - hash + byte) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// 计算校验和差异
  double _calculateChecksumDifference(String checksum1, String checksum2) {
    if (checksum1 == checksum2) return 0.0;

    // 简单的差异计算（实际应用中可以使用更复杂的算法）
    final bytes1 = checksum1.codeUnits;
    final bytes2 = checksum2.codeUnits;

    int differences = 0;
    final maxLength = math.max(bytes1.length, bytes2.length);

    for (int i = 0; i < maxLength; i++) {
      final byte1 = i < bytes1.length ? bytes1[i] : 0;
      final byte2 = i < bytes2.length ? bytes2[i] : 0;
      if (byte1 != byte2) differences++;
    }

    return differences.toDouble() / maxLength.toDouble();
  }

  /// 获取一致性元数据
  ConsistencyMetadata _getConsistencyMetadata(String dataType) {
    return _consistencyCache[dataType] ??
        ConsistencyMetadata(
          dataType: dataType,
          lastValidTimestamp:
              DateTime.now().subtract(const Duration(days: 365)),
          lastValidChecksum: null,
          lastValidSource: null,
          lastInvalidTimestamp: null,
          validationCount: 0,
          validCount: 0,
          invalidCount: 0,
        );
  }

  /// 更新一致性元数据
  void _updateConsistencyMetadata({
    required String dataType,
    required String checksum,
    required List<Map<String, dynamic>> data,
    required ApiSource source,
    required bool isValid,
  }) {
    final existing = _consistencyCache[dataType] ??
        ConsistencyMetadata(
          dataType: dataType,
          lastValidTimestamp:
              DateTime.now().subtract(const Duration(days: 365)),
        );

    if (isValid) {
      _consistencyCache[dataType] = existing.copyWith(
        lastValidChecksum: checksum,
        lastValidTimestamp: DateTime.now(),
        lastValidSource: source,
        validationCount: existing.validationCount + 1,
        validCount: existing.validCount + 1,
      );
    } else {
      _consistencyCache[dataType] = existing.copyWith(
        validationCount: existing.validationCount + 1,
        invalidCount: existing.invalidCount + 1,
        lastInvalidTimestamp: DateTime.now(),
      );
    }
  }

  /// 记录违规情况
  void _recordViolation(ConsistencyViolation violation) {
    _violationLog.add(violation);

    // 保持日志大小限制
    while (_violationLog.length > maxViolationLogSize) {
      _violationLog.removeFirst();
    }

    debugPrint('⚠️ 数据一致性违规记录: ${violation.dataType} - ${violation.message}');
  }

  /// 获取一致性统计报告
  ConsistencyReport getConsistencyReport() {
    final totalValidations = _consistencyCache.values
        .fold(0, (sum, metadata) => sum + metadata.validationCount);
    final totalValid = _consistencyCache.values
        .fold(0, (sum, metadata) => sum + metadata.validCount);
    final totalInvalid = _consistencyCache.values
        .fold(0, (sum, metadata) => sum + metadata.invalidCount);

    final recentViolations = _violationLog
        .where((v) => DateTime.now().difference(v.timestamp).inHours <= 24)
        .toList();

    final successRate =
        totalValidations > 0 ? totalValid / totalValidations : 1.0;

    return ConsistencyReport(
      totalValidations: totalValidations,
      totalValid: totalValid,
      totalInvalid: totalInvalid,
      successRate: successRate,
      recentViolations: recentViolations,
      metadataSnapshot: Map.from(_consistencyCache),
      generatedAt: DateTime.now(),
    );
  }

  /// 清理过期元数据
  void cleanupExpiredMetadata() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _consistencyCache.forEach((key, metadata) {
      if (now.difference(metadata.lastValidTimestamp).inDays > 7) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _consistencyCache.remove(key);
    }

    debugPrint('🧹 清理了 ${expiredKeys.length} 个过期元数据项');
  }

  /// 重置一致性状态
  void resetConsistencyState(String? dataType) {
    if (dataType != null) {
      _consistencyCache.remove(dataType);
      debugPrint('🔄 重置数据类型 $dataType 的一致性状态');
    } else {
      _consistencyCache.clear();
      _violationLog.clear();
      debugPrint('🔄 重置所有数据类型的一致性状态');
    }
  }
}

/// 数据一致性规则
class DataConsistencyRule {
  final String name;
  final String version;
  final List<String> checksumFields;
  final double allowedVariance;
  final Duration validationWindow;
  final FallbackStrategy fallbackStrategy;

  DataConsistencyRule({
    required this.name,
    required this.version,
    required this.checksumFields,
    required this.allowedVariance,
    required this.validationWindow,
    required this.fallbackStrategy,
  });
}

/// 回退策略
enum FallbackStrategy {
  useMostRecent, // 使用最新数据
  useAverage, // 使用平均值
  useMedian, // 使用中位数
  usePrimarySource, // 使用主数据源
  useWeightedAverage, // 使用加权平均
}

/// 一致性元数据
class ConsistencyMetadata {
  final String dataType;
  String? lastValidChecksum;
  DateTime lastValidTimestamp;
  ApiSource? lastValidSource;
  DateTime? lastInvalidTimestamp;
  int validationCount;
  int validCount;
  int invalidCount;

  ConsistencyMetadata({
    required this.dataType,
    this.lastValidChecksum,
    required this.lastValidTimestamp,
    this.lastValidSource,
    this.lastInvalidTimestamp,
    this.validationCount = 0,
    this.validCount = 0,
    this.invalidCount = 0,
  });

  ConsistencyMetadata copyWith({
    String? lastValidChecksum,
    DateTime? lastValidTimestamp,
    ApiSource? lastValidSource,
    DateTime? lastInvalidTimestamp,
    int? validationCount,
    int? validCount,
    int? invalidCount,
  }) {
    return ConsistencyMetadata(
      dataType: dataType,
      lastValidChecksum: lastValidChecksum ?? this.lastValidChecksum,
      lastValidTimestamp: lastValidTimestamp ?? this.lastValidTimestamp,
      lastValidSource: lastValidSource ?? this.lastValidSource,
      lastInvalidTimestamp: lastInvalidTimestamp ?? this.lastInvalidTimestamp,
      validationCount: validationCount ?? this.validationCount,
      validCount: validCount ?? this.validCount,
      invalidCount: invalidCount ?? this.invalidCount,
    );
  }
}

/// 一致性验证结果
class ConsistencyResult {
  final bool isValid;
  final double confidence;
  final String message;
  final ConsistencySeverity severity;
  final Map<String, dynamic>? details;

  ConsistencyResult({
    required this.isValid,
    required this.confidence,
    required this.message,
    this.severity = ConsistencySeverity.info,
    this.details,
  });

  @override
  String toString() =>
      'ConsistencyResult(valid: $isValid, confidence: ${confidence.toStringAsFixed(2)}, message: $message)';
}

/// 一致性违规记录
class ConsistencyViolation {
  final String dataType;
  final DateTime timestamp;
  final String? expectedChecksum;
  final String actualChecksum;
  final ApiSource source;
  final String message;
  final ConsistencySeverity severity;

  ConsistencyViolation({
    required this.dataType,
    required this.timestamp,
    this.expectedChecksum,
    required this.actualChecksum,
    required this.source,
    required this.message,
    required this.severity,
  });
}

/// 一致性严重程度
enum ConsistencySeverity {
  info, // 信息
  warning, // 警告
  error, // 错误
  critical, // 严重
}

/// 一致性报告
class ConsistencyReport {
  final int totalValidations;
  final int totalValid;
  final int totalInvalid;
  final double successRate;
  final List<ConsistencyViolation> recentViolations;
  final Map<String, ConsistencyMetadata> metadataSnapshot;
  final DateTime generatedAt;

  ConsistencyReport({
    required this.totalValidations,
    required this.totalValid,
    required this.totalInvalid,
    required this.successRate,
    required this.recentViolations,
    required this.metadataSnapshot,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalValidations': totalValidations,
      'totalValid': totalValid,
      'totalInvalid': totalInvalid,
      'successRate': successRate,
      'recentViolations': recentViolations
          .map((v) => {
                'dataType': v.dataType,
                'timestamp': v.timestamp.toIso8601String(),
                'source': v.source.name,
                'message': v.message,
                'severity': v.severity.toString(),
              })
          .toList(),
      'metadataSnapshot': metadataSnapshot.map((k, v) => MapEntry(k, {
            'dataType': v.dataType,
            'lastValidTimestamp': v.lastValidTimestamp.toIso8601String(),
            'validationCount': v.validationCount,
            'validCount': v.validCount,
            'invalidCount': v.invalidCount,
          })),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
