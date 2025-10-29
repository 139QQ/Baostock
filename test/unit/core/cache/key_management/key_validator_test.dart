/// 缓存键验证器测试
library key_validator_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';

void main() {
  group('缓存键格式验证测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    test('应该验证有效的标准缓存键', () {
      // 基本有效格式
      final validKeys = [
        'jisu_fund_fundData_161725@latest',
        'jisu_fund_fundData_test_fund@v1',
        'jisu_fund_searchIndex_fund_code@latest',
        'jisu_fund_userPreference_theme@v2',
        'jisu_fund_metadata_cache_version@latest',
        'jisu_fund_temporary_session_12345@latest',
        'jisu_fund_systemConfig_api_config@v3',
      ];

      for (final key in validKeys) {
        final result = keyManager.isValidKey(key);
        expect(result, isTrue, reason: '缓存键 "$key" 应该是有效的');
      }
    });

    test('应该验证带参数的缓存键', () {
      final validKeysWithParams = [
        'jisu_fund_fundData_list_equity@v2_type_equity_size_100',
        'jisu_fund_searchIndex_fund_name@latest_pinyin_sort',
        'jisu_fund_fundData_batch_import@v1_source_akshare_date_20241029',
      ];

      for (final key in validKeysWithParams) {
        final result = keyManager.isValidKey(key);
        expect(result, isTrue, reason: '带参数的缓存键 "$key" 应该是有效的');
      }
    });

    test('应该拒绝无效的缓存键格式', () {
      final invalidKeys = [
        '', // 空字符串
        'invalid_format', // 无前缀
        'jisu_fund_fundData@test', // 缺少标识符
        'jisu_fund@latest', // 缺少类型和标识符
        'jisu_fund_invalidType_test@latest', // 无效类型
        'jisu_fund_fundData_test', // 缺少版本分隔符
        'jisu_fund_fundData_test@', // 空版本
        'other_prefix_fundData_test@latest', // 错误前缀
        'jisu_fund_fundData', // 缺少版本信息
      ];

      for (final key in invalidKeys) {
        final result = keyManager.isValidKey(key);
        expect(result, isFalse, reason: '缓存键 "$key" 应该是无效的');
      }
    });

    test('应该拒绝空标识符', () {
      final invalidKeysWithEmptyIdentifier = [
        'jisu_fund_fundData_@latest',
        'jisu_fund_searchIndex_@v1',
        'jisu_fund_userPreference_@latest',
      ];

      for (final key in invalidKeysWithEmptyIdentifier) {
        expect(
          () => keyManager.generateKey(CacheKeyType.fundData, ''),
          throwsA(isA<ArgumentError>()),
          reason: '空标识符应该抛出ArgumentError',
        );
      }
    });

    test('应该正确验证边界情况', () {
      // 极长的标识符
      final longIdentifier = 'a' * 1000;
      final longKey =
          keyManager.generateKey(CacheKeyType.fundData, longIdentifier);
      expect(keyManager.isValidKey(longKey), isTrue);

      // 特殊字符标识符
      final specialChars = 'test-fund_123.code';
      final specialKey =
          keyManager.generateKey(CacheKeyType.fundData, specialChars);
      expect(keyManager.isValidKey(specialKey), isTrue);

      // 数字标识符
      final numericIdentifier = '161725';
      final numericKey =
          keyManager.generateKey(CacheKeyType.fundData, numericIdentifier);
      expect(keyManager.isValidKey(numericKey), isTrue);
    });

    test('应该验证所有支持的缓存键类型', () {
      final testIdentifier = 'test_identifier';

      for (final type in CacheKeyType.values) {
        final key = keyManager.generateKey(type, testIdentifier);
        expect(keyManager.isValidKey(key), isTrue,
            reason: '类型 ${type.name} 生成的缓存键应该有效');
      }
    });

    test('应该验证所有支持的版本', () {
      final testIdentifier = 'test_identifier';

      for (final version in CacheKeyVersion.values) {
        final key = keyManager.generateKey(
            CacheKeyType.fundData, testIdentifier,
            version: version);
        expect(keyManager.isValidKey(key), isTrue,
            reason: '版本 ${version.version} 生成的缓存键应该有效');
      }
    });
  });

  group('缓存键组件验证测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    test('应该正确解析有效的缓存键组件', () {
      final testCases = [
        {
          'key': 'jisu_fund_fundData_161725@latest',
          'expectedType': CacheKeyType.fundData,
          'expectedIdentifier': '161725',
          'expectedVersion': 'latest',
          'expectedParams': <String>[],
        },
        {
          'key': 'jisu_fund_searchIndex_fund_name@v1_pinyin_sort',
          'expectedType': CacheKeyType.searchIndex,
          'expectedIdentifier': 'fund_name',
          'expectedVersion': 'v1',
          'expectedParams': ['pinyin', 'sort'],
        },
        {
          'key': 'jisu_fund_fundData_list_equity@v2_type_equity_size_100',
          'expectedType': CacheKeyType.fundData,
          'expectedIdentifier': 'list_equity',
          'expectedVersion': 'v2',
          'expectedParams': ['type', 'equity', 'size', '100'],
        },
      ];

      for (final testCase in testCases) {
        final info = keyManager.parseKey(testCase['key'] as String);

        expect(info, isNotNull, reason: '缓存键 "${testCase['key']}" 应该能够解析');
        expect(info!.type, equals(testCase['expectedType']),
            reason: '缓存键 "${testCase['key']}" 的类型应该正确');
        expect(info.identifier, equals(testCase['expectedIdentifier']),
            reason: '缓存键 "${testCase['key']}" 的标识符应该正确');
        expect(info.version, equals(testCase['expectedVersion']),
            reason: '缓存键 "${testCase['key']}" 的版本应该正确');
        expect(info.params, equals(testCase['expectedParams']),
            reason: '缓存键 "${testCase['key']}" 的参数应该正确');
      }
    });

    test('应该解析包含下划线的标识符', () {
      final testCases = [
        {
          'key': 'jisu_fund_fundData_list_equity_funds@latest',
          'expectedIdentifier': 'list_equity_funds',
        },
        {
          'key': 'jisu_fund_searchIndex_fund_company_index@v1',
          'expectedIdentifier': 'fund_company_index',
        },
        {
          'key': 'jisu_fund_userPreference_filter_preferences_theme@latest',
          'expectedIdentifier': 'filter_preferences_theme',
        },
      ];

      for (final testCase in testCases) {
        final info = keyManager.parseKey(testCase['key'] as String);

        expect(info, isNotNull, reason: '缓存键 "${testCase['key']}" 应该能够解析');
        expect(info!.identifier, equals(testCase['expectedIdentifier']),
            reason: '缓存键 "${testCase['key']}" 的标识符应该正确处理下划线');
      }
    });

    test('应该处理复杂参数组合', () {
      final complexKey =
          'jisu_fund_fundData_batch_operation@v3_source_akshare_date_20241029_type_full_validation_true';
      final info = keyManager.parseKey(complexKey);

      expect(info, isNotNull);
      expect(info!.type, equals(CacheKeyType.fundData));
      expect(info.identifier, equals('batch_operation'));
      expect(info.version, equals('v3'));
      expect(
          info.params,
          equals([
            'source',
            'akshare',
            'date',
            '20241029',
            'type',
            'full',
            'validation',
            'true'
          ]));
    });

    test('应该拒绝解析无效的缓存键', () {
      final invalidKeys = [
        'invalid_format',
        'jisu_fund@latest',
        'jisu_fund_invalidType_test@latest',
        'jisu_fund_fundData', // 缺少版本
      ];

      for (final key in invalidKeys) {
        final info = keyManager.parseKey(key);
        expect(info, isNull, reason: '无效缓存键 "$key" 应该返回null');
      }
    });
  });

  group('缓存键生成验证测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    test('生成的缓存键应该符合标准格式', () {
      final key = keyManager.generateKey(CacheKeyType.fundData, '161725');

      // 验证基本格式
      expect(key, startsWith('jisu_fund_fundData_'));
      expect(key, endsWith('@latest'));
      expect(key, contains('161725'));

      // 验证生成的键可以通过验证
      expect(keyManager.isValidKey(key), isTrue);

      // 验证生成的键可以正确解析
      final info = keyManager.parseKey(key);
      expect(info, isNotNull);
      expect(info!.type, equals(CacheKeyType.fundData));
      expect(info.identifier, equals('161725'));
      expect(info.version, equals('latest'));
    });

    test('生成的带参数缓存键应该符合标准格式', () {
      final params = ['type', 'equity', 'size', '100'];
      final key = keyManager.generateKey(CacheKeyType.fundData, 'list_equity',
          params: params);

      // 验证基本格式
      expect(key, startsWith('jisu_fund_fundData_list_equity@latest_'));
      expect(key, contains('type_equity_size_100'));

      // 验证生成的键可以通过验证
      expect(keyManager.isValidKey(key), isTrue);

      // 验证生成的键可以正确解析
      final info = keyManager.parseKey(key);
      expect(info, isNotNull);
      expect(info!.type, equals(CacheKeyType.fundData));
      expect(info.identifier, equals('list_equity'));
      expect(info.version, equals('latest'));
      expect(info.params, equals(params));
    });

    test('便捷方法应该生成正确的缓存键', () {
      // 测试基金数据键
      final fundKey = keyManager.fundDataKey('161725');
      expect(fundKey, equals('jisu_fund_fundData_161725@latest'));
      expect(keyManager.isValidKey(fundKey), isTrue);

      // 测试基金列表键
      final listKey = keyManager
          .fundListKey('equity', filters: {'type': 'stock', 'size': 'large'});
      expect(
          listKey,
          equals(
              'jisu_fund_fundData_list_equity@latest_type_stock_size_large'));
      expect(keyManager.isValidKey(listKey), isTrue);

      // 测试搜索索引键
      final searchKey = keyManager.searchIndexKey('fund_name');
      expect(searchKey, equals('jisu_fund_searchIndex_fund_name@latest'));
      expect(keyManager.isValidKey(searchKey), isTrue);

      // 测试用户偏好键
      final prefKey = keyManager.userPreferenceKey('theme');
      expect(prefKey, equals('jisu_fund_userPreference_theme@latest'));
      expect(keyManager.isValidKey(prefKey), isTrue);

      // 测试元数据键
      final metaKey = keyManager.metadataKey('cache_version');
      expect(metaKey, equals('jisu_fund_metadata_cache_version@latest'));
      expect(keyManager.isValidKey(metaKey), isTrue);

      // 测试临时数据键
      final tempKey = keyManager.temporaryKey('session_123');
      expect(tempKey, equals('jisu_fund_temporary_session_123@latest'));
      expect(keyManager.isValidKey(tempKey), isTrue);

      // 测试系统配置键
      final configKey = keyManager.systemConfigKey('api_config');
      expect(configKey, equals('jisu_fund_systemConfig_api_config@latest'));
      expect(keyManager.isValidKey(configKey), isTrue);
    });
  });

  group('边界和错误情况测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    test('应该处理极长的缓存键', () {
      final longIdentifier = 'a' * 10000; // 10k字符
      final key = keyManager.generateKey(CacheKeyType.fundData, longIdentifier);

      expect(keyManager.isValidKey(key), isTrue);

      final info = keyManager.parseKey(key);
      expect(info, isNotNull);
      expect(info!.identifier, equals(longIdentifier));
    });

    test('应该处理包含特殊字符的标识符', () {
      final specialIdentifiers = [
        'fund-161725',
        'test_fund.code',
        'fund_company#123',
        '货币基金-2024',
      ];

      for (final identifier in specialIdentifiers) {
        final key = keyManager.generateKey(CacheKeyType.fundData, identifier);
        expect(keyManager.isValidKey(key), isTrue,
            reason: '包含特殊字符的标识符 "$identifier" 应该有效');

        final info = keyManager.parseKey(key);
        expect(info, isNotNull);
        expect(info!.identifier, equals(identifier));
      }
    });

    test('应该正确处理空参数列表', () {
      final key = keyManager
          .generateKey(CacheKeyType.fundData, 'test_fund', params: []);

      expect(key, equals('jisu_fund_fundData_test_fund@latest'));
      expect(keyManager.isValidKey(key), isTrue);

      final info = keyManager.parseKey(key);
      expect(info, isNotNull);
      expect(info!.params, isEmpty);
    });

    test('应该正确处理null参数', () {
      final key = keyManager.generateKey(CacheKeyType.fundData, 'test_fund',
          params: null);

      expect(key, equals('jisu_fund_fundData_test_fund@latest'));
      expect(keyManager.isValidKey(key), isTrue);

      final info = keyManager.parseKey(key);
      expect(info, isNotNull);
      expect(info!.params, isEmpty);
    });
  });
}
