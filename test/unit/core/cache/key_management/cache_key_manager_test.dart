import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';

void main() {
  group('缓存键管理器测试', () {
    late CacheKeyManager keyManager;

    setUp(() {
      keyManager = CacheKeyManager.instance;
    });

    group('基础键生成测试', () {
      test('应该生成正确的基础缓存键', () {
        final key = keyManager.generateKey(
          CacheKeyType.fundData,
          'test_fund',
        );

        expect(key, equals('jisu_fund_fundData_test_fund@latest'));
      });

      test('应该生成带版本的缓存键', () {
        final key = keyManager.generateKey(
          CacheKeyType.fundData,
          'test_fund',
          version: CacheKeyVersion.v2,
        );

        expect(key, equals('jisu_fund_fundData_test_fund@2.0'));
      });

      test('应该生成带参数的缓存键', () {
        final key = keyManager.generateKey(
          CacheKeyType.fundData,
          'test_fund',
          params: ['param1', 'param2'],
        );

        expect(
            key, equals('jisu_fund_fundData_test_fund@latest_param1_param2'));
      });

      test('应该生成带版本和参数的缓存键', () {
        final key = keyManager.generateKey(
          CacheKeyType.fundData,
          'test_fund',
          version: CacheKeyVersion.v3,
          params: ['param1'],
        );

        expect(key, equals('jisu_fund_fundData_test_fund@3.0_param1'));
      });
    });

    group('便捷方法测试', () {
      test('应该生成正确的基金数据缓存键', () {
        final key = keyManager.fundDataKey('005827');

        expect(key, equals('jisu_fund_fundData_005827@latest'));
      });

      test('应该生成带版本的基金数据缓存键', () {
        final key =
            keyManager.fundDataKey('005827', version: CacheKeyVersion.v1);

        expect(key, equals('jisu_fund_fundData_005827@1.0'));
      });

      test('应该生成基金列表缓存键', () {
        final key = keyManager.fundListKey('open_funds');

        expect(key, equals('jisu_fund_fundData_list_open_funds@latest'));
      });

      test('应该生成带筛选器的基金列表缓存键', () {
        final key = keyManager.fundListKey('open_funds',
            filters: {'type': 'equity', 'risk': 'high'});

        expect(
            key,
            equals(
                'jisu_fund_fundData_list_open_funds@latest_type_equity_risk_high'));
      });

      test('应该生成搜索索引缓存键', () {
        final key = keyManager.searchIndexKey('fund_name');

        expect(key, equals('jisu_fund_searchIndex_fund_name@latest'));
      });

      test('应该生成用户偏好缓存键', () {
        final key = keyManager.userPreferenceKey('favorite_funds');

        expect(key, equals('jisu_fund_userPreference_favorite_funds@latest'));
      });

      test('应该生成元数据缓存键', () {
        final key = keyManager.metadataKey('cache_timestamp');

        expect(key, equals('jisu_fund_metadata_cache_timestamp@latest'));
      });

      test('应该生成带ID的元数据缓存键', () {
        final key =
            keyManager.metadataKey('cache_timestamp', specificId: 'user123');

        expect(
            key, equals('jisu_fund_metadata_cache_timestamp_user123@latest'));
      });

      test('应该生成临时数据缓存键', () {
        final key = keyManager.temporaryKey('search_results');

        expect(key, equals('jisu_fund_temporary_search_results@latest'));
      });

      test('应该生成带会话的临时数据缓存键', () {
        final key =
            keyManager.temporaryKey('search_results', sessionId: 'session456');

        expect(key,
            equals('jisu_fund_temporary_search_results_session456@latest'));
      });

      test('应该生成系统配置缓存键', () {
        final key = keyManager.systemConfigKey('api_config');

        expect(key, equals('jisu_fund_systemConfig_api_config@latest'));
      });
    });

    group('键解析测试', () {
      test('应该正确解析基础缓存键', () {
        final key = 'jisu_fund_fundData_test_fund@latest';
        final info = keyManager.parseKey(key);

        expect(info, isNotNull);
        expect(info!.type, equals(CacheKeyType.fundData));
        expect(info.identifier, equals('test_fund'));
        expect(info.version, equals('latest'));
        expect(info.params, isEmpty);
      });

      test('应该正确解析带版本的缓存键', () {
        final key = 'jisu_fund_fundData_test_fund@2.0';
        final info = keyManager.parseKey(key);

        expect(info, isNotNull);
        expect(info!.type, equals(CacheKeyType.fundData));
        expect(info.identifier, equals('test_fund'));
        expect(info.version, equals('2.0'));
      });

      test('应该正确解析带参数的缓存键', () {
        final key =
            'jisu_fund_fundData_list_open_funds@latest_type_equity_risk_high';
        final info = keyManager.parseKey(key);

        expect(info, isNotNull);
        expect(info!.type, equals(CacheKeyType.fundData));
        expect(info.identifier, equals('list_open_funds'));
        expect(info.version, equals('latest'));
        expect(info.params, equals(['type', 'equity', 'risk', 'high']));
      });

      test('应该正确解析复杂缓存键', () {
        final key =
            'jisu_fund_metadata_cache_timestamp_user123@3.0_param1_param2';
        final info = keyManager.parseKey(key);

        expect(info, isNotNull);
        expect(info!.type, equals(CacheKeyType.metadata));
        expect(info.identifier, equals('cache_timestamp_user123'));
        expect(info.version, equals('3.0'));
        expect(info.params, equals(['param1', 'param2']));
      });

      test('应该拒绝无效的缓存键', () {
        const invalidKeys = [
          'invalid_key',
          'jisu_fund',
          'jisu_fund_invalidType_test',
          'some_other_prefix_fundData_test@latest',
          '',
        ];

        for (final key in invalidKeys) {
          final info = keyManager.parseKey(key);
          expect(info, isNull, reason: '应该拒绝无效键: $key');
        }
      });
    });

    group('键验证测试', () {
      test('应该验证有效的缓存键', () {
        const validKeys = [
          'jisu_fund_fundData_test_fund@latest',
          'jisu_fund_searchIndex_fund_name@2.0',
          'jisu_fund_userPreference_favorite_funds@latest_param1',
          'jisu_fund_metadata_cache_timestamp@latest',
          'jisu_fund_temporary_search_results_session123@latest',
          'jisu_fund_systemConfig_api_config@3.0',
        ];

        for (final key in validKeys) {
          expect(keyManager.isValidKey(key), isTrue, reason: '应该验证有效键: $key');
        }
      });

      test('应该拒绝无效的缓存键', () {
        const invalidKeys = [
          'invalid_key',
          'fundData_test_fund',
          'jisu_fund_invalidType_test',
          '',
          'jisu_fund_',
          'jisu_fund_fundData_', // 缺少标识符
          'jisu_fund_fundData_test@', // 缺少版本
        ];

        for (final key in invalidKeys) {
          expect(keyManager.isValidKey(key), isFalse, reason: '应该拒绝无效键: $key');
        }
      });
    });

    group('批量键生成测试', () {
      test('应该批量生成缓存键', () {
        const identifiers = ['fund1', 'fund2', 'fund3'];
        final keys = keyManager.generateBatchKeys(
          CacheKeyType.fundData,
          identifiers,
        );

        expect(keys, hasLength(3));
        expect(keys[0], equals('jisu_fund_fundData_fund1@latest'));
        expect(keys[1], equals('jisu_fund_fundData_fund2@latest'));
        expect(keys[2], equals('jisu_fund_fundData_fund3@latest'));
      });

      test('应该批量生成带版本的缓存键', () {
        const identifiers = ['fund1', 'fund2'];
        final keys = keyManager.generateBatchKeys(
          CacheKeyType.fundData,
          identifiers,
          version: CacheKeyVersion.v2,
        );

        expect(keys, hasLength(2));
        expect(keys[0], equals('jisu_fund_fundData_fund1@2.0'));
        expect(keys[1], equals('jisu_fund_fundData_fund2@2.0'));
      });
    });

    group('缓存键信息测试', () {
      test('应该正确显示缓存键信息', () {
        final info = CacheKeyInfo(
          type: CacheKeyType.fundData,
          identifier: 'test_fund',
          version: 'latest',
          params: ['param1', 'param2'],
          originalKey: 'jisu_fund_fundData_test_fund@latest_param1_param2',
        );

        expect(info.toString(), contains('CacheKeyInfo'));
        expect(info.toString(), contains('fundData'));
        expect(info.toString(), contains('test_fund'));
        expect(info.toString(), contains('latest'));
        expect(info.toString(), contains('param1, param2'));
      });

      test('应该正确生成缓存键描述', () {
        final info = CacheKeyInfo(
          type: CacheKeyType.fundData,
          identifier: 'test_fund',
          version: 'latest',
          params: ['param1', 'param2'],
          originalKey: 'jisu_fund_fundData_test_fund@latest_param1_param2',
        );

        final description = info.description;
        expect(description,
            equals('[fundData] test_fund@latest (param1, param2)'));
      });

      test('应该正确生成无参数的缓存键描述', () {
        final info = CacheKeyInfo(
          type: CacheKeyType.searchIndex,
          identifier: 'fund_name',
          version: '2.0',
          params: [],
          originalKey: 'jisu_fund_searchIndex_fund_name@2.0',
        );

        final description = info.description;
        expect(description, equals('[searchIndex] fund_name@2.0'));
      });
    });

    group('错误处理测试', () {
      test('应该拒绝空标识符', () {
        expect(
          () => keyManager.generateKey(CacheKeyType.fundData, ''),
          throwsArgumentError,
        );

        expect(
          () => keyManager.generateKey(CacheKeyType.fundData, '   '),
          returnsNormally,
        ); // 空白字符应该是有效的
      });

      test('应该处理空参数列表', () {
        final key = keyManager.generateKey(
          CacheKeyType.fundData,
          'test_fund',
          params: [],
        );

        expect(key, equals('jisu_fund_fundData_test_fund@latest'));
      });

      test('应该处理null参数列表', () {
        final key = keyManager.generateKey(
          CacheKeyType.fundData,
          'test_fund',
          params: null,
        );

        expect(key, equals('jisu_fund_fundData_test_fund@latest'));
      });
    });

    group('标准盒子名称测试', () {
      test('应该返回所有标准盒子名称', () {
        final boxNames = keyManager.getStandardBoxNames();

        expect(boxNames, hasLength(6));
        expect(boxNames, contains('jisu_fund_fundData'));
        expect(boxNames, contains('jisu_fund_searchIndex'));
        expect(boxNames, contains('jisu_fund_userPreference'));
        expect(boxNames, contains('jisu_fund_metadata'));
        expect(boxNames, contains('jisu_fund_temporary'));
        expect(boxNames, contains('jisu_fund_systemConfig'));
      });
    });

    group('缓存键迁移测试', () {
      test('应该正确迁移旧键到新键', () {
        const oldKey = 'fund_005827';
        final newKey = keyManager.migrateKey(
          oldKey,
          CacheKeyType.fundData,
          '005827',
        );

        expect(newKey, equals('jisu_fund_fundData_005827@latest'));
      });
    });
  });

  group('缓存键构建器测试', () {
    test('应该使用构建器创建简单缓存键', () {
      final key = CacheKeyBuilder()
          .setType(CacheKeyType.fundData)
          .setIdentifier('test_fund')
          .build();

      expect(key, equals('jisu_fund_fundData_test_fund@latest'));
    });

    test('应该使用构建器创建复杂缓存键', () {
      final key = CacheKeyBuilder()
          .setType(CacheKeyType.fundData)
          .setIdentifier('list_open_funds')
          .setVersion(CacheKeyVersion.v2)
          .addParam('type_equity')
          .addParam('risk_high')
          .build();

      expect(
          key,
          equals(
              'jisu_fund_fundData_list_open_funds@2.0_type_equity_risk_high'));
    });

    test('应该使用构建器批量添加参数', () {
      final key = CacheKeyBuilder()
          .setType(CacheKeyType.fundData)
          .setIdentifier('test_fund')
          .addParams(['param1', 'param2', 'param3']).build();

      expect(key,
          equals('jisu_fund_fundData_test_fund@latest_param1_param2_param3'));
    });

    test('应该拒绝不完整的构建', () {
      expect(
        () => CacheKeyBuilder().setIdentifier('test_fund').build(),
        throwsStateError,
      );

      expect(
        () => CacheKeyBuilder().setType(CacheKeyType.fundData).build(),
        throwsStateError,
      );
    });
  });

  group('扩展方法测试', () {
    test('应该使用扩展方法生成基金数据键', () {
      final key = '005827'.toFundDataKey();

      expect(key, equals('jisu_fund_fundData_005827@latest'));
    });

    test('应该使用扩展方法生成带版本的基金数据键', () {
      final key = '005827'.toFundDataKey(version: CacheKeyVersion.v3);

      expect(key, equals('jisu_fund_fundData_005827@3.0'));
    });

    test('应该使用扩展方法生成搜索索引键', () {
      final key = 'fund_name'.toSearchIndexKey();

      expect(key, equals('jisu_fund_searchIndex_fund_name@latest'));
    });

    test('应该使用扩展方法生成用户偏好键', () {
      final key = 'favorite_funds'.toUserPreferenceKey();

      expect(key, equals('jisu_fund_userPreference_favorite_funds@latest'));
    });

    test('应该使用扩展方法生成元数据键', () {
      final key = 'cache_timestamp'.toMetadataKey();

      expect(key, equals('jisu_fund_metadata_cache_timestamp@latest'));
    });

    test('应该使用扩展方法生成带ID的元数据键', () {
      final key = 'cache_timestamp'.toMetadataKey(specificId: 'user123');

      expect(key, equals('jisu_fund_metadata_cache_timestamp_user123@latest'));
    });
  });
}
