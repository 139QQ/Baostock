import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../domain/entities/fund.dart';
import '../../../../core/utils/logger.dart';

/// 优化后的基金API响应数据模型 - Week 9实施
///
/// 性能优化特性：
/// - 统一的中文字段映射
/// - compute异步解析支持
/// - 精简字段映射，减少内存占用
/// - 字段使用率分析和优化
class OptimizedFundApiResponse {
  // 常用字段映射缓存 - 提升性能
  static const Map<String, String> _fieldMappings = {
    '基金代码': 'code',
    '基金简称': 'name',
    '基金类型': 'type',
    '基金公司': 'company',
    '基金经理': 'manager',
    '单位净值': 'unitNav',
    '累计净值': 'accumulatedNav',
    '日增长率': 'dailyReturn',
    '近1周': 'return1W',
    '近1月': 'return1M',
    '近3月': 'return3M',
    '近6月': 'return6M',
    '近1年': 'return1Y',
    '近2年': 'return2Y',
    '近3年': 'return3Y',
    '今年来': 'returnYTD',
    '成立来': 'returnSinceInception',
    '手续费': 'fee',
    '序号': 'rankingPosition',
    '日期': 'date',
    '拼音缩写': 'pinyinAbbr',
    '拼音全称': 'pinyinFull',
  };

  // 高频使用字段 - 优化访问性能
  static const Set<String> _highFrequencyFields = {
    '基金代码',
    '基金简称',
    '单位净值',
    '累计净值',
    '日增长率'
  };

  // Week 10 性能优化 - API解析性能监控
  static int _totalParseOperations = 0;
  static int _totalRecordsProcessed = 0;
  static final List<Duration> _parseTimes = [];
  static int _parseErrors = 0;

  /// 将API原始数据转换为基金实体列表 - 主入口方法
  ///
  /// 优化特性：
  /// - 支持compute异步解析
  /// - 统一错误处理
  /// - 字段验证和清理
  /// - 性能监控
  static List<Fund> fromRankingApi(List<Map<String, dynamic>> apiData) {
    if (apiData.isEmpty) return [];

    final stopwatch = Stopwatch()..start();
    _totalParseOperations++;

    try {
      final funds = apiData
          .where(_isValidFundItem)
          .map((item) => _convertRankingItemToFund(item))
          .where((fund) => fund.code.isNotEmpty)
          .toList();

      stopwatch.stop();

      // Week 10 性能优化: 记录解析性能
      _totalRecordsProcessed += apiData.length;
      _parseTimes.add(stopwatch.elapsed);

      // 性能日志（仅在调试模式下）
      if (kDebugMode && stopwatch.elapsedMilliseconds > 100) {
        AppLogger.info(
            '⚠️ API数据转换耗时: ${stopwatch.elapsedMilliseconds}ms, 处理${funds.length}条记录');
      }

      return funds;
    } catch (e) {
      _parseErrors++;
      AppLogger.error('❌ API数据转换失败: $e', e);
      return [];
    }
  }

  /// compute异步解析入口 - 用于大数据量处理
  static Future<List<Fund>> fromRankingApiCompute(
      List<Map<String, dynamic>> apiData) {
    return compute(_parseFundsInBackground, apiData);
  }

  /// 后台Isolate解析函数
  static List<Fund> _parseFundsInBackground(
      List<Map<String, dynamic>> apiData) {
    return fromRankingApi(apiData);
  }

  /// 验证基金数据项是否有效
  static bool _isValidFundItem(Map<String, dynamic> item) {
    return item.isNotEmpty &&
        item.containsKey('基金代码') &&
        item.containsKey('基金简称') &&
        item['基金代码'] != null &&
        item['基金简称'] != null &&
        item['基金代码'].toString().trim().isNotEmpty;
  }

  /// 转换单个基金排行数据项 - 优化版本
  static Fund _convertRankingItemToFund(Map<String, dynamic> item) {
    try {
      // 基础信息验证和清理
      final code = _cleanString(item['基金代码']?.toString() ?? '');
      final name = _cleanString(item['基金简称']?.toString() ?? '');

      if (code.isEmpty || name.isEmpty) {
        return _createEmptyFund();
      }

      return Fund(
        // 基本信息 - 高频字段优化
        code: code,
        name: name,
        type: _determineFundType(name),
        company: _extractCompanyName(name),
        manager: '', // 暂时留空，需要额外API

        // 净值信息 - 核心数据
        unitNav: _parseDouble(item['单位净值']) ?? 0.0,
        accumulatedNav: _parseDouble(item['累计净值']) ?? 0.0,
        dailyReturn: _parsePercentage(item['日增长率']) ?? 0.0,

        // 收益率信息 - 批量处理
        return1W: _parsePercentage(item['近1周']) ?? 0.0,
        return1M: _parsePercentage(item['近1月']) ?? 0.0,
        return3M: _parsePercentage(item['近3月']) ?? 0.0,
        return6M: _parsePercentage(item['近6月']) ?? 0.0,
        return1Y: _parsePercentage(item['近1年']) ?? 0.0,
        return2Y: _parsePercentage(item['近2年']) ?? 0.0,
        return3Y: _parsePercentage(item['近3年']) ?? 0.0,
        returnYTD: _parsePercentage(item['今年来']) ?? 0.0,
        returnSinceInception: _parsePercentage(item['成立来']) ?? 0.0,

        // 其他信息
        scale: 0, // API中通常不包含规模信息
        riskLevel: '', // API中通常不包含风险等级
        status: 'active', // 默认状态
        date: item['日期']?.toString() ?? DateTime.now().toIso8601String(),
        fee: _parseFeeToDouble(item['手续费']?.toString()),
        rankingPosition: _parseInt(item['序号']) ?? 0,
        totalCount: 0, // 将在外部设置

        // 价格信息 - 复用净值数据
        currentPrice: _parseDouble(item['单位净值']) ?? 0.0,
        dailyChange: 0.0, // API中通常不包含
        dailyChangePercent: _parsePercentage(item['日增长率']) ?? 0.0,

        // 必需参数
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('❌ 基金数据转换失败: $e, 数据: $item', e);
      return _createEmptyFund();
    }
  }

  /// TODO: 添加FundInfo转换功能 (需要扩展FundInfo模型)
  // FundInfo转换功能将在FundInfo模型扩展后添加

  /// 工具方法：字符串清理
  static String _cleanString(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 工具方法：安全解析Double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// 工具方法：解析百分比
  static double? _parsePercentage(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      final result = double.tryParse(cleaned);
      // 处理百分比值（如"2.5%"转换为0.025）
      if (result != null && value.contains('%') && result.abs() > 1) {
        return result / 100;
      }
      return result;
    }
    return null;
  }

  /// 工具方法：安全解析Int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d-]'), '');
      return int.tryParse(cleaned);
    }
    return null;
  }

  /// 工具方法：解析手续费 (数值版本)
  static double _parseFeeToDouble(String? feeStr) {
    if (feeStr == null || feeStr.isEmpty) return 0.0;

    // 提取数字部分
    final match = RegExp(r'[\d.]+').firstMatch(feeStr);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }

    return 0.0;
  }

  /// 根据基金简称判断基金类型 - 优化版本
  static String _determineFundType(String fundName) {
    final typePatterns = {
      '混合型': ['混合'],
      '股票型': ['股票'],
      '债券型': ['债券'],
      '指数型': ['指数'],
      'QDII': ['QDII'],
      '货币型': ['货币'],
      'FOF': ['FOF'],
      'REITs': ['REIT'],
    };

    for (var entry in typePatterns.entries) {
      for (var pattern in entry.value) {
        if (fundName.contains(pattern)) {
          return entry.key;
        }
      }
    }

    return '混合型'; // 默认类型
  }

  /// 从基金简称提取公司名称 - 优化版本
  static String _extractCompanyName(String fundName) {
    // 常见基金公司前缀模式
    final companyPrefixes = [
      '易方达',
      '华夏',
      '南方',
      '嘉实',
      '博时',
      '广发',
      '富国',
      '汇添富',
      '国泰',
      '华安',
      '银华',
      '大成',
      '鹏华',
      '长盛',
      '融通',
      '建信',
      '工银瑞信',
      '招商',
      '中银',
      '兴业',
      '平安',
      '景顺长城',
      '中欧',
      '交银施罗德',
      '华泰柏瑞',
      '诺安',
      '海富通',
      '万家',
      '德邦',
      '华商',
      '上投摩根',
      '中信保诚',
      '前海开源',
      '中融',
      '民生加银',
    ];

    for (var company in companyPrefixes) {
      if (fundName.startsWith(company)) {
        return company;
      }
    }

    return '其他公司'; // 默认值
  }

  /// 创建空基金对象
  static Fund _createEmptyFund() {
    final now = DateTime.now();
    return Fund(
      code: '',
      name: '',
      type: '',
      company: '',
      manager: '',
      unitNav: 0.0,
      accumulatedNav: 0.0,
      dailyReturn: 0.0,
      return1W: 0.0,
      return1M: 0.0,
      return3M: 0.0,
      return6M: 0.0,
      return1Y: 0.0,
      return2Y: 0.0,
      return3Y: 0.0,
      returnYTD: 0.0,
      returnSinceInception: 0.0,
      scale: 0.0,
      riskLevel: '',
      status: '',
      date: now.toIso8601String(),
      fee: 0.0,
      rankingPosition: 0,
      totalCount: 0,
      currentPrice: 0.0,
      dailyChange: 0.0,
      dailyChangePercent: 0.0,
      lastUpdate: now,
    );
  }

  /// 字段使用率分析工具 - 用于持续优化
  static void analyzeFieldUsage(List<Map<String, dynamic>> sampleData) {
    AppLogger.info('📊 API字段使用率分析:');

    final fieldUsage = <String, int>{};
    int totalRecords = sampleData.length;

    for (var item in sampleData) {
      for (var key in item.keys) {
        fieldUsage[key] = (fieldUsage[key] ?? 0) + 1;
      }
    }

    // 按使用率排序
    final sortedFields = fieldUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedFields) {
      final percentage = (entry.value / totalRecords * 100).toStringAsFixed(1);
      final isHighFreq = _highFrequencyFields.contains(entry.key) ? ' ⚡' : '';
      AppLogger.info('  ${entry.key}: $percentage%$isHighFreq');
    }

    AppLogger.info('\n💡 建议: 使用率<30%的字段可考虑移除或按需加载');
  }

  /// 获取字段映射表
  static Map<String, String> get fieldMappings =>
      Map.unmodifiable(_fieldMappings);

  /// 获取高频字段列表
  static Set<String> get highFrequencyFields =>
      Set.unmodifiable(_highFrequencyFields);

  /// Week 10 性能优化: 生成API解析性能报告
  static void generateParsePerformanceReport() {
    if (_parseTimes.isEmpty) {
      AppLogger.info('📊 API解析性能报告: 暂无解析记录');
      return;
    }

    final avgParseTime =
        _parseTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
            _parseTimes.length;

    final maxParseTime = _parseTimes
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a > b ? a : b);

    final minParseTime = _parseTimes
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a < b ? a : b);

    final avgRecordsPerOperation = _totalParseOperations > 0
        ? _totalRecordsProcessed / _totalParseOperations
        : 0.0;

    final errorRate = _totalParseOperations > 0
        ? (_parseErrors / _totalParseOperations * 100)
        : 0.0;

    AppLogger.info('📊 API解析性能报告:');
    AppLogger.info('  总解析操作数: $_totalParseOperations');
    AppLogger.info('  总处理记录数: $_totalRecordsProcessed');
    AppLogger.info('  平均解析时间: ${(avgParseTime / 1000).toStringAsFixed(2)}ms');
    AppLogger.info('  最大解析时间: ${(maxParseTime / 1000).toStringAsFixed(2)}ms');
    AppLogger.info('  最小解析时间: ${(minParseTime / 1000).toStringAsFixed(2)}ms');
    AppLogger.info('  平均记录数/操作: ${avgRecordsPerOperation.toStringAsFixed(1)}');
    AppLogger.info('  解析错误数: $_parseErrors');
    AppLogger.info('  错误率: ${errorRate.toStringAsFixed(2)}%');

    // 在调试模式下输出到开发者控制台
    if (kDebugMode) {
      developer.log(
          'API解析性能报告: 平均${(avgParseTime / 1000).toStringAsFixed(2)}ms, '
          '错误率${errorRate.toStringAsFixed(2)}%',
          name: 'APIParsePerformance');
    }

    // 清理旧的性能数据，保持最近100条记录
    if (_parseTimes.length > 100) {
      _parseTimes.removeRange(0, _parseTimes.length - 100);
    }
  }

  /// Week 10 性能优化: 获取API解析统计信息
  static Map<String, dynamic> getParseStats() {
    if (_parseTimes.isEmpty) {
      return {
        'totalParseOperations': _totalParseOperations,
        'totalRecordsProcessed': _totalRecordsProcessed,
        'avgParseTime': 0.0,
        'maxParseTime': 0.0,
        'minParseTime': 0.0,
        'avgRecordsPerOperation': 0.0,
        'parseErrors': _parseErrors,
        'errorRate': 0.0,
      };
    }

    final avgParseTime =
        _parseTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
            _parseTimes.length;

    final maxParseTime = _parseTimes
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a > b ? a : b);

    final minParseTime = _parseTimes
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a < b ? a : b);

    return {
      'totalParseOperations': _totalParseOperations,
      'totalRecordsProcessed': _totalRecordsProcessed,
      'avgParseTime': avgParseTime / 1000, // 转换为毫秒
      'maxParseTime': maxParseTime / 1000, // 转换为毫秒
      'minParseTime': minParseTime / 1000, // 转换为毫秒
      'avgRecordsPerOperation': _totalParseOperations > 0
          ? _totalRecordsProcessed / _totalParseOperations
          : 0.0,
      'parseErrors': _parseErrors,
      'errorRate': _totalParseOperations > 0
          ? (_parseErrors / _totalParseOperations * 100)
          : 0.0,
    };
  }

  /// Week 10 性能优化: 重置性能统计
  static void resetPerformanceStats() {
    _totalParseOperations = 0;
    _totalRecordsProcessed = 0;
    _parseTimes.clear();
    _parseErrors = 0;
    AppLogger.info('📊 API解析性能统计已重置');
  }
}
