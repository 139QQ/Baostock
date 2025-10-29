/// 缓存键映射器测试
library key_mapper_test;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';

/// 键映射结果类
class KeyMappingResult {
  final String originalKey;
  final String? mappedKey;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const KeyMappingResult({
    required this.originalKey,
    this.mappedKey,
    required this.success,
    this.errorMessage,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'KeyMappingResult(original: $originalKey, mapped: $mappedKey, success: $success)';
  }
}

/// 键映射规则类
class KeyMappingRule {
  final String pattern;
  final String replacement;
  final bool isRegex;
  final Map<String, String> parameters;

  const KeyMappingRule({
    required this.pattern,
    required this.replacement,
    this.isRegex = false,
    this.parameters = const {},
  });

  /// 应用映射规则
  KeyMappingResult apply(String key) {
    try {
      String mappedKey;

      if (isRegex) {
        final regex = RegExp(pattern);
        mappedKey = key.replaceAll(regex, replacement);
      } else {
        mappedKey = key.replaceAll(pattern, replacement);
      }

      return KeyMappingResult(
        originalKey: key,
        mappedKey: mappedKey,
        success: true,
        metadata: {
          'rule_applied': pattern,
          'is_regex': isRegex,
          'parameters': parameters,
        },
      );
    } catch (e) {
      return KeyMappingResult(
        originalKey: key,
        success: false,
        errorMessage: '映射规则应用失败: $e',
      );
    }
  }

  @override
  String toString() {
    return 'KeyMappingRule(pattern: $pattern, replacement: $replacement, isRegex: $isRegex)';
  }
}

/// 键映射器实现
class CacheKeyMapper {
  final CacheKeyManager _keyManager = CacheKeyManager.instance;
  final List<KeyMappingRule> _rules = [];
  final Map<String, KeyMappingResult> _mappingCache = {};

  /// 添加映射规则
  void addRule(KeyMappingRule rule) {
    _rules.add(rule);
    _clearCache();
  }

  /// 添加多个映射规则
  void addRules(List<KeyMappingRule> rules) {
    _rules.addAll(rules);
    _clearCache();
  }

  /// 清除所有规则
  void clearRules() {
    _rules.clear();
    _clearCache();
  }

  /// 清除缓存
  void _clearCache() {
    _mappingCache.clear();
  }

  /// 映射单个键
  KeyMappingResult mapKey(String key, {bool useCache = true}) {
    // 检查缓存
    if (useCache && _mappingCache.containsKey(key)) {
      return _mappingCache[key]!;
    }

    // 检查是否已经是标准格式
    if (_keyManager.isValidKey(key)) {
      final result = KeyMappingResult(
        originalKey: key,
        mappedKey: key,
        success: true,
        metadata: {'already_standard': true},
      );

      if (useCache) {
        _mappingCache[key] = result;
      }

      return result;
    }

    // 应用映射规则
    for (final rule in _rules) {
      final result = rule.apply(key);

      if (result.success && result.mappedKey != key) {
        // 验证映射后的键
        if (_keyManager.isValidKey(result.mappedKey!)) {
          final finalResult = KeyMappingResult(
            originalKey: key,
            mappedKey: result.mappedKey,
            success: true,
            metadata: {
              ...result.metadata,
              'validation_passed': true,
            },
          );

          if (useCache) {
            _mappingCache[key] = finalResult;
          }

          return finalResult;
        }
      }
    }

    // 无法映射
    final result = KeyMappingResult(
      originalKey: key,
      success: false,
      errorMessage: '无法映射键: $key',
      metadata: {'no_suitable_rule': true},
    );

    if (useCache) {
      _mappingCache[key] = result;
    }

    return result;
  }

  /// 批量映射键
  Map<String, KeyMappingResult> mapKeys(List<String> keys,
      {bool useCache = true}) {
    final results = <String, KeyMappingResult>{};

    for (final key in keys) {
      results[key] = mapKey(key, useCache: useCache);
    }

    return results;
  }

  /// 智能映射（基于键模式分析）
  KeyMappingResult mapKeyIntelligently(String key) {
    // 分析键模式
    final analysis = _analyzeKeyPattern(key);

    if (analysis['type'] == 'unknown') {
      return KeyMappingResult(
        originalKey: key,
        success: false,
        errorMessage: '无法识别键模式: $key',
      );
    }

    // 基于分析结果生成映射
    final mappedKey = _generateKeyFromAnalysis(analysis);

    return KeyMappingResult(
      originalKey: key,
      mappedKey: mappedKey,
      success: true,
      metadata: {
        'analysis_result': analysis,
        'intelligent_mapping': true,
      },
    );
  }

  /// 分析键模式
  Map<String, String> _analyzeKeyPattern(String key) {
    final analysis = <String, String>{};

    // 基金数据模式
    if (key.contains('fund') && key.contains(RegExp(r'\d{6}'))) {
      final match = RegExp(r'(\d{6})').firstMatch(key);
      if (match != null) {
        analysis['type'] = 'fundData';
        analysis['fund_code'] = match.group(1)!;
        analysis['identifier'] = match.group(1)!;
      }
    }

    // 搜索索引模式
    else if (key.contains('search') || key.contains('index')) {
      analysis['type'] = 'searchIndex';
      analysis['index_type'] = key.contains('name') ? 'fund_name' : 'fund_code';
      analysis['identifier'] = analysis['index_type']!;
    }

    // 用户偏好模式
    else if (key.contains('user') ||
        key.contains('preference') ||
        key.contains('setting')) {
      analysis['type'] = 'userPreference';
      analysis['preference_type'] = key.contains('theme') ? 'theme' : 'general';
      analysis['identifier'] = analysis['preference_type']!;
    }

    // 元数据模式
    else if (key.contains('meta') ||
        key.contains('cache') ||
        key.contains('version')) {
      analysis['type'] = 'metadata';
      analysis['metadata_type'] = 'cache_version';
      analysis['identifier'] = analysis['metadata_type']!;
    }

    // 系统配置模式
    else if (key.contains('config') ||
        key.contains('api') ||
        key.contains('system')) {
      analysis['type'] = 'systemConfig';
      analysis['config_type'] =
          key.contains('api') ? 'api_config' : 'system_config';
      analysis['identifier'] = analysis['config_type']!;
    }

    // 临时数据模式
    else if (key.contains('temp') || key.contains('session')) {
      analysis['type'] = 'temporary';
      analysis['temp_type'] =
          key.contains('session') ? 'session_data' : 'temp_data';
      analysis['identifier'] = analysis['temp_type']!;
    } else {
      analysis['type'] = 'unknown';
    }

    return analysis;
  }

  /// 基于分析结果生成标准键
  String _generateKeyFromAnalysis(Map<String, String> analysis) {
    final type = analysis['type']!;
    final identifier = analysis['identifier']!;

    switch (type) {
      case 'fundData':
        return _keyManager.fundDataKey(identifier);
      case 'searchIndex':
        return _keyManager.searchIndexKey(identifier);
      case 'userPreference':
        return _keyManager.userPreferenceKey(identifier);
      case 'metadata':
        return _keyManager.metadataKey(identifier);
      case 'systemConfig':
        return _keyManager.systemConfigKey(identifier);
      case 'temporary':
        return _keyManager.temporaryKey(identifier);
      default:
        throw ArgumentError('未知的键类型: $type');
    }
  }

  /// 获取映射统计信息
  Map<String, dynamic> getMappingStatistics() {
    return {
      'total_rules': _rules.length,
      'cache_size': _mappingCache.length,
      'supported_patterns': [
        'fund_data_with_code',
        'search_index',
        'user_preference',
        'metadata',
        'system_config',
        'temporary_data',
      ],
    };
  }

  /// 验证映射结果
  bool validateMapping(String originalKey, String mappedKey) {
    // 验证原键和映射键的关系
    if (originalKey == mappedKey) {
      return _keyManager.isValidKey(mappedKey);
    }

    // 验证映射键是否有效
    if (!_keyManager.isValidKey(mappedKey)) {
      return false;
    }

    // 验证映射的逻辑性
    final originalInfo = _analyzeKeyPattern(originalKey);
    final mappedInfo = _keyManager.parseKey(mappedKey);

    if (originalInfo['type'] != 'unknown' && mappedInfo != null) {
      // 检查类型是否匹配
      final expectedType = _stringToCacheKeyType(originalInfo['type']!);
      return mappedInfo.type == expectedType;
    }

    return true;
  }

  /// 将字符串转换为CacheKeyType
  CacheKeyType _stringToCacheKeyType(String type) {
    switch (type) {
      case 'fundData':
        return CacheKeyType.fundData;
      case 'searchIndex':
        return CacheKeyType.searchIndex;
      case 'userPreference':
        return CacheKeyType.userPreference;
      case 'metadata':
        return CacheKeyType.metadata;
      case 'systemConfig':
        return CacheKeyType.systemConfig;
      case 'temporary':
        return CacheKeyType.temporary;
      default:
        throw ArgumentError('未知的缓存键类型: $type');
    }
  }
}

void main() {
  group('缓存键映射器基础功能测试', () {
    late CacheKeyMapper mapper;

    setUp(() {
      mapper = CacheKeyMapper();
    });

    test('应该正确添加和管理映射规则', () {
      final rule1 = KeyMappingRule(pattern: 'old_', replacement: 'new_');
      final rule2 = KeyMappingRule(
          pattern: r'fund_(\d+)', replacement: r'fund_code_\1', isRegex: true);

      mapper.addRule(rule1);
      expect(mapper.getMappingStatistics()['total_rules'], equals(1));

      mapper.addRule(rule2);
      expect(mapper.getMappingStatistics()['total_rules'], equals(2));

      mapper.clearRules();
      expect(mapper.getMappingStatistics()['total_rules'], equals(0));
    });

    test('应该正确应用简单的字符串替换规则', () {
      mapper.addRule(KeyMappingRule(
          pattern: 'old_fund_', replacement: 'jisu_fund_fundData_'));

      final result = mapper.mapKey('old_fund_161725');

      expect(result.success, isTrue);
      expect(result.mappedKey, equals('jisu_fund_fundData_161725'));
      expect(result.metadata['rule_applied'], equals('old_fund_'));
    });

    test('应该正确应用正则表达式规则', () {
      mapper.addRule(KeyMappingRule(
        pattern: r'fund_(\d{6})',
        replacement: r'jisu_fund_fundData_\1@latest',
        isRegex: true,
      ));

      final result = mapper.mapKey('fund_161725');

      expect(result.success, isTrue);
      expect(result.mappedKey, equals('jisu_fund_fundData_161725@latest'));
      expect(result.metadata['is_regex'], isTrue);
    });

    test('应该识别已经是标准格式的键', () {
      final standardKey = 'jisu_fund_fundData_161725@latest';

      final result = mapper.mapKey(standardKey);

      expect(result.success, isTrue);
      expect(result.mappedKey, equals(standardKey));
      expect(result.metadata['already_standard'], isTrue);
    });

    test('应该处理无法映射的键', () {
      final unmappableKey = 'completely_unknown_key_format';

      final result = mapper.mapKey(unmappableKey);

      expect(result.success, isFalse);
      expect(result.mappedKey, isNull);
      expect(result.errorMessage, contains('无法映射键'));
      expect(result.metadata['no_suitable_rule'], isTrue);
    });
  });

  group('缓存键映射器智能映射测试', () {
    late CacheKeyMapper mapper;

    setUp(() {
      mapper = CacheKeyMapper();
    });

    test('应该智能识别基金数据模式', () {
      final testCases = [
        {
          'input': 'fund_161725_data',
          'expectedType': 'fundData',
          'expectedIdentifier': '161725',
        },
        {
          'input': 'fund_code_000001_info',
          'expectedType': 'fundData',
          'expectedIdentifier': '000001',
        },
        {
          'input': 'fund_data_110022_details',
          'expectedType': 'fundData',
          'expectedIdentifier': '110022',
        },
      ];

      for (final testCase in testCases) {
        final result = mapper.mapKeyIntelligently(testCase['input'] as String);

        expect(result.success, isTrue, reason: '应该能智能映射: ${testCase['input']}');
        expect(result.mappedKey,
            contains(testCase['expectedIdentifier'] as String));
        expect(result.metadata['intelligent_mapping'], isTrue);

        final analysis =
            result.metadata['analysis_result'] as Map<String, String>;
        expect(analysis['type'], equals(testCase['expectedType']));
        expect(analysis['fund_code'], equals(testCase['expectedIdentifier']));
      }
    });

    test('应该智能识别搜索索引模式', () {
      final testCases = [
        {
          'input': 'search_fund_name_index',
          'expectedType': 'searchIndex',
          'expectedIdentifier': 'fund_name',
        },
        {
          'input': 'index_fund_code_structure',
          'expectedType': 'searchIndex',
          'expectedIdentifier': 'fund_code',
        },
        {
          'input': 'fund_search_index_by_name',
          'expectedType': 'searchIndex',
          'expectedIdentifier': 'fund_name',
        },
      ];

      for (final testCase in testCases) {
        final result = mapper.mapKeyIntelligently(testCase['input'] as String);

        expect(result.success, isTrue, reason: '应该能智能映射: ${testCase['input']}');
        expect(result.metadata['intelligent_mapping'], isTrue);

        final analysis =
            result.metadata['analysis_result'] as Map<String, String>;
        expect(analysis['type'], equals(testCase['expectedType']));
        expect(analysis['identifier'], equals(testCase['expectedIdentifier']));
      }
    });

    test('应该智能识别用户偏好模式', () {
      final testCases = [
        {
          'input': 'user_theme_preference',
          'expectedType': 'userPreference',
          'expectedIdentifier': 'theme',
        },
        {
          'input': 'preference_setting_display',
          'expectedType': 'userPreference',
          'expectedIdentifier': 'general',
        },
        {
          'input': 'user_interface_settings',
          'expectedType': 'userPreference',
          'expectedIdentifier': 'general',
        },
      ];

      for (final testCase in testCases) {
        final result = mapper.mapKeyIntelligently(testCase['input'] as String);

        expect(result.success, isTrue, reason: '应该能智能映射: ${testCase['input']}');
        expect(result.metadata['intelligent_mapping'], isTrue);

        final analysis =
            result.metadata['analysis_result'] as Map<String, String>;
        expect(analysis['type'], equals(testCase['expectedType']));
      }
    });

    test('应该智能识别元数据模式', () {
      final testCases = [
        {
          'input': 'metadata_cache_version_info',
          'expectedType': 'metadata',
          'expectedIdentifier': 'cache_version',
        },
        {
          'input': 'cache_version_metadata',
          'expectedType': 'metadata',
          'expectedIdentifier': 'cache_version',
        },
        {
          'input': 'system_metadata_version',
          'expectedType': 'metadata',
          'expectedIdentifier': 'cache_version',
        },
      ];

      for (final testCase in testCases) {
        final result = mapper.mapKeyIntelligently(testCase['input'] as String);

        expect(result.success, isTrue, reason: '应该能智能映射: ${testCase['input']}');
        expect(result.metadata['intelligent_mapping'], isTrue);

        final analysis =
            result.metadata['analysis_result'] as Map<String, String>;
        expect(analysis['type'], equals(testCase['expectedType']));
      }
    });

    test('应该处理无法识别的模式', () {
      final unknownPatterns = [
        'completely_unknown_format',
        'xyz_abc_123',
        'random_string_of_text',
        'just_something_else',
      ];

      for (final pattern in unknownPatterns) {
        final result = mapper.mapKeyIntelligently(pattern);

        expect(result.success, isFalse, reason: '无法识别的模式应该失败: $pattern');
        expect(result.errorMessage, contains('无法识别键模式'));
      }
    });
  });

  group('缓存键映射器批量操作测试', () {
    late CacheKeyMapper mapper;

    setUp(() {
      mapper = CacheKeyMapper();
      mapper.addRule(
          KeyMappingRule(pattern: 'old_', replacement: 'jisu_fund_fundData_'));
    });

    test('应该支持批量键映射', () {
      final keys = [
        'old_fund_161725',
        'old_fund_000001',
        'old_fund_110022',
        'jisu_fund_fundData__already_standard@latest',
        'unknown_key_format',
      ];

      final results = mapper.mapKeys(keys);

      expect(results, hasLength(5));
      expect(results.containsKey('old_fund_161725'), isTrue);
      expect(results.containsKey('old_fund_000001'), isTrue);
      expect(results.containsKey('old_fund_110022'), isTrue);
      expect(results.containsKey('jisu_fund_fundData__already_standard@latest'),
          isTrue);
      expect(results.containsKey('unknown_key_format'), isTrue);

      // 检查映射结果
      expect(results['old_fund_161725']!.success, isTrue);
      expect(results['old_fund_161725']!.mappedKey,
          equals('jisu_fund_fundData_fund_161725'));

      expect(results['jisu_fund_fundData_already_standard@latest']!.success,
          isTrue);
      expect(
          results['jisu_fund_fundData_already_standard@latest']!
              .metadata['already_standard'],
          isTrue);

      expect(results['unknown_key_format']!.success, isFalse);
    });

    test('应该支持缓存机制', () {
      final key = 'old_fund_161725';

      // 第一次映射
      final result1 = mapper.mapKey(key, useCache: true);
      expect(result1.success, isTrue);

      // 第二次映射应该使用缓存
      final result2 = mapper.mapKey(key, useCache: true);
      expect(result2.success, isTrue);
      expect(identical(result1, result2), isTrue, reason: '应该返回相同的缓存结果');

      // 清除缓存后应该重新计算
      mapper._clearCache();
      final result3 = mapper.mapKey(key, useCache: true);
      expect(result3.success, isTrue);
      expect(identical(result1, result3), isFalse, reason: '清除缓存后应该重新计算');
    });

    test('应该正确处理批量映射中的混合情况', () {
      final keys = [
        'old_fund_161725', // 可以映射
        'jisu_fund_fundData_already@latest', // 已经是标准格式
        'invalid_format', // 无法映射
        '', // 空键
      ];

      final results = mapper.mapKeys(keys);

      final successful = results.values.where((r) => r.success).toList();
      final failed = results.values.where((r) => !r.success).toList();

      expect(successful, hasLength(2)); // old_fund_* 和已标准格式
      expect(failed, hasLength(2)); // invalid_format 和空键
    });
  });

  group('缓存键映射器验证功能测试', () {
    late CacheKeyMapper mapper;

    setUp(() {
      mapper = CacheKeyMapper();
    });

    test('应该验证正确的映射', () {
      final validMappings = [
        {
          'original': 'fund_161725_data',
          'mapped': 'jisu_fund_fundData_161725@latest',
        },
        {
          'original': 'search_fund_name_index',
          'mapped': 'jisu_fund_searchIndex_fund_name@latest',
        },
        {
          'original': 'jisu_fund_fundData_already@latest',
          'mapped': 'jisu_fund_fundData_already@latest',
        },
      ];

      for (final mapping in validMappings) {
        final isValid = mapper.validateMapping(
          mapping['original'] as String,
          mapping['mapped'] as String,
        );

        expect(isValid, isTrue,
            reason: '映射应该是有效的: ${mapping['original']} -> ${mapping['mapped']}');
      }
    });

    test('应该拒绝无效的映射', () {
      final invalidMappings = [
        {
          'original': 'fund_161725_data',
          'mapped': 'invalid_mapped_key_format',
        },
        {
          'original': 'search_fund_name_index',
          'mapped': '',
        },
        {
          'original': 'fund_data_info',
          'mapped': 'jisu_fund_userPreference_wrong_type@latest',
        },
      ];

      for (final mapping in invalidMappings) {
        final isValid = mapper.validateMapping(
          mapping['original'] as String,
          mapping['mapped'] as String,
        );

        expect(isValid, isFalse,
            reason: '映射应该是无效的: ${mapping['original']} -> ${mapping['mapped']}');
      }
    });
  });

  group('缓存键映射器性能测试', () {
    late CacheKeyMapper mapper;

    setUp(() {
      mapper = CacheKeyMapper();
      mapper.addRule(
          KeyMappingRule(pattern: 'old_', replacement: 'jisu_fund_fundData_'));
    });

    test('应该高效处理大量键映射', () async {
      final keys = <String>[];

      // 生成1000个测试键
      for (int i = 0; i < 1000; i++) {
        keys.add('old_fund_${i.toString().padLeft(6, '0')}');
      }

      final stopwatch = Stopwatch()..start();
      final results = mapper.mapKeys(keys);
      stopwatch.stop();

      expect(results, hasLength(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '1000个键映射应该在1秒内完成');

      final successful = results.values.where((r) => r.success).toList();
      expect(successful, hasLength(1000));
    });

    test('缓存应该提高性能', () async {
      final key = 'old_fund_161725';
      final iterations = 1000;

      // 不使用缓存
      mapper._clearCache();
      final stopwatch1 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        mapper.mapKey(key, useCache: false);
      }
      stopwatch1.stop();

      // 使用缓存
      mapper._clearCache();
      final stopwatch2 = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        mapper.mapKey(key, useCache: true);
      }
      stopwatch2.stop();

      // 缓存版本应该更快
      expect(stopwatch2.elapsedMicroseconds,
          lessThan(stopwatch1.elapsedMicroseconds),
          reason: '使用缓存应该更快');
    });
  });

  group('缓存键映射器统计信息测试', () {
    late CacheKeyMapper mapper;

    setUp(() {
      mapper = CacheKeyMapper();
    });

    test('应该提供正确的统计信息', () {
      // 初始状态
      var stats = mapper.getMappingStatistics();
      expect(stats['total_rules'], equals(0));
      expect(stats['cache_size'], equals(0));
      expect(stats['supported_patterns'], isA<List>());

      // 添加规则后
      mapper.addRule(KeyMappingRule(pattern: 'test', replacement: 'mapped'));
      stats = mapper.getMappingStatistics();
      expect(stats['total_rules'], equals(1));

      // 映射键后
      mapper.mapKey('test_key');
      stats = mapper.getMappingStatistics();
      expect(stats['cache_size'], equals(1));
    });

    test('应该支持统计信息中的模式列表', () {
      final stats = mapper.getMappingStatistics();
      final patterns = stats['supported_patterns'] as List;

      expect(patterns, contains('fund_data_with_code'));
      expect(patterns, contains('search_index'));
      expect(patterns, contains('user_preference'));
      expect(patterns, contains('metadata'));
      expect(patterns, contains('system_config'));
      expect(patterns, contains('temporary_data'));
    });
  });

  group('KeyMappingResult对象测试', () {
    test('应该正确格式化toString', () {
      final result = KeyMappingResult(
        originalKey: 'old_key',
        mappedKey: 'new_key',
        success: true,
      );

      final resultString = result.toString();
      expect(resultString, contains('old_key'));
      expect(resultString, contains('new_key'));
      expect(resultString, contains('true'));
    });

    test('应该正确处理失败结果', () {
      final result = KeyMappingResult(
        originalKey: 'invalid_key',
        success: false,
        errorMessage: '映射失败',
      );

      expect(result.success, isFalse);
      expect(result.mappedKey, isNull);
      expect(result.errorMessage, equals('映射失败'));
      expect(result.metadata, isEmpty);
    });

    test('应该正确处理元数据', () {
      final metadata = {
        'rule_applied': 'test_rule',
        'is_regex': true,
        'validation_passed': true,
      };

      final result = KeyMappingResult(
        originalKey: 'test_key',
        mappedKey: 'mapped_key',
        success: true,
        metadata: metadata,
      );

      expect(result.metadata, equals(metadata));
      expect(result.metadata['rule_applied'], equals('test_rule'));
      expect(result.metadata['is_regex'], isTrue);
      expect(result.metadata['validation_passed'], isTrue);
    });
  });

  group('KeyMappingRule对象测试', () {
    test('应该正确应用简单替换规则', () {
      final rule = KeyMappingRule(pattern: 'old', replacement: 'new');
      final result = rule.apply('old_key');

      expect(result.success, isTrue);
      expect(result.mappedKey, equals('new_key'));
      expect(result.metadata['rule_applied'], equals('old'));
      expect(result.metadata['is_regex'], isFalse);
    });

    test('应该正确应用正则表达式规则', () {
      final rule = KeyMappingRule(
        pattern: r'(\d{6})',
        replacement: r'fund_\1',
        isRegex: true,
      );
      final result = rule.apply('code_161725');

      expect(result.success, isTrue);
      expect(result.mappedKey, equals('code_fund_161725'));
      expect(result.metadata['is_regex'], isTrue);
    });

    test('应该正确处理规则应用失败', () {
      final rule = KeyMappingRule(
        pattern: r'[invalid_regex(',
        replacement: 'replacement',
        isRegex: true,
      );
      final result = rule.apply('test_key');

      expect(result.success, isFalse);
      expect(result.mappedKey, isNull);
      expect(result.errorMessage, contains('映射规则应用失败'));
    });

    test('应该正确格式化toString', () {
      final rule = KeyMappingRule(
        pattern: 'test_pattern',
        replacement: 'test_replacement',
        isRegex: true,
      );

      final ruleString = rule.toString();
      expect(ruleString, contains('test_pattern'));
      expect(ruleString, contains('test_replacement'));
      expect(ruleString, contains('true'));
    });
  });
}
