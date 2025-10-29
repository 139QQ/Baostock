/// 缓存键解析器测试
library key_parser_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';

void main() {
  group('缓存键解析基础功能测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    test('应该解析基本格式的缓存键', () {
      final testCases = [
        {
          'input': 'jisu_fund_fundData_161725@latest',
          'expected': CacheKeyInfo(
            type: CacheKeyType.fundData,
            identifier: '161725',
            version: 'latest',
            params: [],
            originalKey: 'jisu_fund_fundData_161725@latest',
          ),
        },
        {
          'input': 'jisu_fund_searchIndex_fund_name@v1',
          'expected': CacheKeyInfo(
            type: CacheKeyType.searchIndex,
            identifier: 'fund_name',
            version: 'v1',
            params: [],
            originalKey: 'jisu_fund_searchIndex_fund_name@v1',
          ),
        },
        {
          'input': 'jisu_fund_userPreference_theme@v2',
          'expected': CacheKeyInfo(
            type: CacheKeyType.userPreference,
            identifier: 'theme',
            version: 'v2',
            params: [],
            originalKey: 'jisu_fund_userPreference_theme@v2',
          ),
        },
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as String;
        final expected = testCase['expected'] as CacheKeyInfo;

        final result = keyManager.parseKey(input);

        expect(result, isNotNull, reason: '缓存键 "$input" 应该能够解析');
        expect(result!.type, equals(expected.type),
            reason: '缓存键 "$input" 的类型应该正确');
        expect(result.identifier, equals(expected.identifier),
            reason: '缓存键 "$input" 的标识符应该正确');
        expect(result.version, equals(expected.version),
            reason: '缓存键 "$input" 的版本应该正确');
        expect(result.params, equals(expected.params),
            reason: '缓存键 "$input" 的参数应该正确');
        expect(result.originalKey, equals(expected.originalKey),
            reason: '缓存键 "$input" 的原始键应该正确');
      }
    });

    test('应该解析带参数的缓存键', () {
      final testCases = [
        {
          'input': 'jisu_fund_fundData_list_equity@v2_type_equity_size_100',
          'expected': CacheKeyInfo(
            type: CacheKeyType.fundData,
            identifier: 'list_equity',
            version: 'v2',
            params: ['type', 'equity', 'size', '100'],
            originalKey:
                'jisu_fund_fundData_list_equity@v2_type_equity_size_100',
          ),
        },
        {
          'input':
              'jisu_fund_searchIndex_fund_pinyin@latest_pinyin_sort_priority',
          'expected': CacheKeyInfo(
            type: CacheKeyType.searchIndex,
            identifier: 'fund_pinyin',
            version: 'latest',
            params: ['pinyin', 'sort', 'priority'],
            originalKey:
                'jisu_fund_searchIndex_fund_pinyin@latest_pinyin_sort_priority',
          ),
        },
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as String;
        final expected = testCase['expected'] as CacheKeyInfo;

        final result = keyManager.parseKey(input);

        expect(result, isNotNull, reason: '带参数的缓存键 "$input" 应该能够解析');
        expect(result!.type, equals(expected.type),
            reason: '缓存键 "$input" 的类型应该正确');
        expect(result.identifier, equals(expected.identifier),
            reason: '缓存键 "$input" 的标识符应该正确');
        expect(result.version, equals(expected.version),
            reason: '缓存键 "$input" 的版本应该正确');
        expect(result.params, equals(expected.params),
            reason: '缓存键 "$input" 的参数应该正确');
      }
    });

    test('应该正确处理包含多个下划线的标识符', () {
      final testCases = [
        {
          'input': 'jisu_fund_fundData_list_equity_funds@latest',
          'expectedIdentifier': 'list_equity_funds',
        },
        {
          'input': 'jisu_fund_searchIndex_fund_company_name_index@v1',
          'expectedIdentifier': 'fund_company_name_index',
        },
        {
          'input': 'jisu_fund_metadata_cache_version_info@latest',
          'expectedIdentifier': 'cache_version_info',
        },
        {
          'input': 'jisu_fund_userPreference_filter_display_settings_theme@v2',
          'expectedIdentifier': 'filter_display_settings_theme',
        },
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as String;
        final expectedIdentifier = testCase['expectedIdentifier'] as String;

        final result = keyManager.parseKey(input);

        expect(result, isNotNull, reason: '缓存键 "$input" 应该能够解析');
        expect(result!.identifier, equals(expectedIdentifier),
            reason: '缓存键 "$input" 的标识符应该正确处理多个下划线');
      }
    });

    test('应该解析复杂参数组合', () {
      final complexKey =
          'jisu_fund_fundData_batch_import_operation@v3_source_akshare_date_20241029_type_full_validation_true_retry_count_3';
      final result = keyManager.parseKey(complexKey);

      expect(result, isNotNull);
      expect(result!.type, equals(CacheKeyType.fundData));
      expect(result.identifier, equals('batch_import_operation'));
      expect(result.version, equals('v3'));
      expect(
          result.params,
          equals([
            'source',
            'akshare',
            'date',
            '20241029',
            'type',
            'full',
            'validation',
            'true',
            'retry',
            'count',
            '3'
          ]));
    });
  });

  group('缓存键解析错误处理测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    test('应该返回null对于无效格式的缓存键', () {
      final invalidKeys = [
        '', // 空字符串
        'invalid_format', // 完全错误格式
        'jisu_fund', // 缺少类型和标识符
        'jisu_fund_fundData', // 缺少版本分隔符
        'jisu_fund_fundData@test', // 缺少标识符
        'jisu_fund@latest', // 缺少类型和标识符
        'jisu_fund_fundData@', // 空版本
        'jisu_fund_@latest', // 空类型
        'other_prefix_fundData_test@latest', // 错误前缀
        'jisu_fund_invalidType_test@latest', // 无效类型
        'jisu_fund_fundData_test', // 缺少版本信息
      ];

      for (final invalidKey in invalidKeys) {
        final result = keyManager.parseKey(invalidKey);
        expect(result, isNull, reason: '无效缓存键 "$invalidKey" 应该返回null');
      }
    });

    test('应该处理版本分隔符缺失的情况', () {
      final keysWithoutVersion = [
        'jisu_fund_fundData_161725',
        'jisu_fund_searchIndex_fund_name',
        'jisu_fund_userPreference_theme',
        'jisu_fund_fundData_list_equity',
      ];

      for (final key in keysWithoutVersion) {
        final result = keyManager.parseKey(key);
        expect(result, isNull, reason: '缺少版本分隔符的缓存键 "$key" 应该返回null');
      }
    });

    test('应该处理前缀不匹配的情况', () {
      final wrongPrefixKeys = [
        'akshare_fund_fundData_161725@latest',
        'cache_fund_searchIndex_fund_name@v1',
        'test_fund_userPreference_theme@v2',
        'other_fund_metadata_cache_version@latest',
      ];

      for (final key in wrongPrefixKeys) {
        final result = keyManager.parseKey(key);
        expect(result, isNull, reason: '前缀不匹配的缓存键 "$key" 应该返回null');
      }
    });

    test('应该处理无效类型名称的情况', () {
      final invalidTypeKeys = [
        'jisu_fund_invalidType_test@latest',
        'jisu_fund_wrongType_test@v1',
        'jisu_fund_unknownType_test@v2',
        'jisu_fund_fakeType_test@latest',
      ];

      for (final key in invalidTypeKeys) {
        final result = keyManager.parseKey(key);
        expect(result, isNull, reason: '无效类型的缓存键 "$key" 应该返回null');
      }
    });

    test('应该处理组件不完整的情况', () {
      final incompleteKeys = [
        'jisu_fund@latest', // 缺少类型和标识符
        'jisu_fund_fundData@latest', // 缺少标识符
        'jisu_fund_@latest', // 缺少类型和标识符
        '@latest', // 只有版本
      ];

      for (final key in incompleteKeys) {
        final result = keyManager.parseKey(key);
        expect(result, isNull, reason: '组件不完整的缓存键 "$key" 应该返回null');
      }
    });
  });

  group('缓存键解析边界情况测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    test('应该处理极长的缓存键', () {
      final longIdentifier = 'a' * 1000;
      final longKey =
          keyManager.generateKey(CacheKeyType.fundData, longIdentifier);

      final result = keyManager.parseKey(longKey);

      expect(result, isNotNull);
      expect(result!.identifier, equals(longIdentifier));
      expect(result.type, equals(CacheKeyType.fundData));
      expect(result.version, equals('latest'));
    });

    test('应该处理包含特殊字符的缓存键', () {
      final specialCases = [
        {
          'identifier': 'fund-161725.code',
          'key': 'jisu_fund_fundData_fund-161725.code@latest',
        },
        {
          'identifier': '货币基金_2024年',
          'key': 'jisu_fund_fundData_货币基金_2024年@latest',
        },
        {
          'identifier': 'test@fund#company.123',
          'key': 'jisu_fund_fundData_test@fund#company.123@latest',
        },
      ];

      for (final testCase in specialCases) {
        final result = keyManager.parseKey(testCase['key'] as String);

        expect(result, isNotNull,
            reason: '包含特殊字符的缓存键 "${testCase['key']}" 应该能够解析');
        expect(result!.identifier, equals(testCase['identifier']),
            reason: '特殊字符标识符应该正确解析');
      }
    });

    test('应该处理空版本的情况', () {
      final emptyVersionKey = 'jisu_fund_fundData_test@';
      final result = keyManager.parseKey(emptyVersionKey);

      // 空版本应该能解析，但版本值为空字符串
      expect(result, isNotNull);
      expect(result!.version, isEmpty);
    });

    test('应该处理只有版本没有参数的情况', () {
      final versionOnlyKeys = [
        'jisu_fund_fundData_test@v1',
        'jisu_fund_searchIndex_name@v2',
        'jisu_fund_userPreference_theme@latest',
      ];

      for (final key in versionOnlyKeys) {
        final result = keyManager.parseKey(key);

        expect(result, isNotNull);
        expect(result!.params, isEmpty, reason: '只有版本的缓存键 "$key" 的参数列表应该为空');
      }
    });

    test('应该处理参数中包含特殊字符的情况', () {
      final keyWithSpecialParams =
          'jisu_fund_fundData_search@latest_query_基金名称_filter_type-股票_sort_by-收益率_desc';
      final result = keyManager.parseKey(keyWithSpecialParams);

      expect(result, isNotNull);
      expect(
          result!.params,
          equals([
            'query',
            '基金名称',
            'filter',
            'type-股票',
            'sort',
            'by-收益率',
            'desc'
          ]));
    });
  });

  group('缓存键解析性能测试', () {
    late CacheKeyManager keyManager;
    late List<String> testKeys;

    setUp(() {
      keyManager = CacheKeyManager.instance;

      // 生成测试键集合
      testKeys = [
        'jisu_fund_fundData_161725@latest',
        'jisu_fund_fundData_list_equity@v2_type_equity_size_100',
        'jisu_fund_searchIndex_fund_name@latest_pinyin_sort',
        'jisu_fund_userPreference_theme@v1_dark_mode_true',
        'jisu_fund_metadata_cache_version@latest',
        'jisu_fund_temporary_session_12345@latest',
        'jisu_fund_systemConfig_api_config@v3_timeout_30',
        'jisu_fund_fundData_batch_operation@v1_source_akshare_date_20241029_type_full_validation_true',
      ];
    });

    test('应该能高效解析大量缓存键', () async {
      final stopwatch = Stopwatch()..start();

      // 解析1000次
      for (int i = 0; i < 1000; i++) {
        for (final key in testKeys) {
          keyManager.parseKey(key);
        }
      }

      stopwatch.stop();

      // 8000次解析应该在合理时间内完成（比如1秒内）
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '解析8000个缓存键应该在1秒内完成');
    });

    test('应该保持解析结果的一致性', () {
      final key =
          'jisu_fund_fundData_test_fund@latest_param1_value1_param2_value2';

      // 多次解析同一个键应该返回相同结果
      final results = List.generate(10, (_) => keyManager.parseKey(key));

      for (int i = 1; i < results.length; i++) {
        expect(results[i], equals(results[0]), reason: '多次解析同一个缓存键应该返回相同结果');
      }
    });
  });

  group('缓存键信息对象测试', () {
    test('CacheKeyInfo应该正确格式化toString', () {
      final info = CacheKeyInfo(
        type: CacheKeyType.fundData,
        identifier: '161725',
        version: 'latest',
        params: ['type', 'equity'],
        originalKey: 'jisu_fund_fundData_161725@latest_type_equity',
      );

      final toString = info.toString();
      expect(toString, contains('CacheKeyInfo'));
      expect(toString, contains('fundData'));
      expect(toString, contains('161725'));
      expect(toString, contains('latest'));
      expect(toString, contains('type'));
      expect(toString, contains('equity'));
    });

    test('CacheKeyInfo应该正确生成description', () {
      final infoWithoutParams = CacheKeyInfo(
        type: CacheKeyType.fundData,
        identifier: '161725',
        version: 'latest',
        params: [],
        originalKey: 'jisu_fund_fundData_161725@latest',
      );

      expect(infoWithoutParams.description, equals('[fundData] 161725@latest'));

      final infoWithParams = CacheKeyInfo(
        type: CacheKeyType.searchIndex,
        identifier: 'fund_name',
        version: 'v1',
        params: ['pinyin', 'sort'],
        originalKey: 'jisu_fund_searchIndex_fund_name@v1_pinyin_sort',
      );

      expect(infoWithParams.description,
          equals('[searchIndex] fund_name@v1 (pinyin, sort)'));
    });

    test('CacheKeyInfo应该正确处理空参数列表', () {
      final info = CacheKeyInfo(
        type: CacheKeyType.userPreference,
        identifier: 'theme',
        version: 'latest',
        params: [],
        originalKey: 'jisu_fund_userPreference_theme@latest',
      );

      expect(info.description, equals('[userPreference] theme@latest'));
      expect(info.params, isEmpty);
    });
  });
}
