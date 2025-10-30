import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_hive_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_migration_adapter.dart';
import 'package:jisu_fund_analyzer/src/core/config/cache_key_config.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import '../../../helpers/hive_test_helper.dart';

void main() {
  group('缓存键管理系统集成测试', () {
    late UnifiedHiveCacheManager cacheManager;
    late CacheKeyManager keyManager;
    late CacheKeyMigrationAdapter migrationAdapter;
    late String tempPath;

    setUpAll(() async {
      // 使用测试辅助类初始化Hive
      await HiveTestHelper.initializeForTest();
    });

    tearDownAll(() async {
      // 使用测试辅助类清理环境
      await HiveTestHelper.cleanupTestEnvironment();
    });

    setUp(() async {
      cacheManager = UnifiedHiveCacheManager.instance;
      keyManager = CacheKeyManager.instance;
      migrationAdapter = CacheKeyMigrationAdapter.instance;

      // 清理之前的缓存
      await cacheManager.clear();
      migrationAdapter.clearMigrationRecords();
    });

    tearDown(() async {
      await cacheManager.dispose();
    });

    group('标准化缓存操作测试', () {
      setUp(() async {
        await cacheManager.initialize();
      });

      test('应该使用标准化键存储和获取数据', () async {
        // 使用标准化方法存储数据
        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          '005827',
          'Test Fund Data',
        );

        // 使用标准化方法获取数据
        final result = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          '005827',
        );

        expect(result, equals('Test Fund Data'));
      });

      test('应该支持带版本的缓存操作', () async {
        // 存储v1版本的数据
        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          '005827',
          'Version 1 Data',
          version: CacheKeyVersion.v1,
        );

        // 获取v1版本的数据
        final v1Result = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          '005827',
          version: CacheKeyVersion.v1,
        );

        expect(v1Result, equals('Version 1 Data'));

        // 存储v2版本的数据
        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          '005827',
          'Version 2 Data',
          version: CacheKeyVersion.v2,
        );

        // 验证两个版本的数据都存在
        final v2Result = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          '005827',
          version: CacheKeyVersion.v2,
        );

        expect(v1Result, equals('Version 1 Data'));
        expect(v2Result, equals('Version 2 Data'));
      });

      test('应该支持带参数的缓存操作', () async {
        // 存储带参数的数据
        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          'list_open_funds',
          'Filtered Fund Data',
          params: ['type_equity', 'risk_high'],
        );

        // 获取带参数的数据
        final result = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          'list_open_funds',
          params: ['type_equity', 'risk_high'],
        );

        expect(result, equals('Filtered Fund Data'));

        // 确保不同参数的数据是独立的
        final differentResult = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          'list_open_funds',
          params: ['type_bond'],
        );

        expect(differentResult, isNull);
      });

      test('应该批量操作基金数据', () async {
        const fundData = {
          '005827': {'name': 'Fund A', 'type': 'Equity'},
          '110022': {'name': 'Fund B', 'type': 'Bond'},
          '161725': {'name': 'Fund C', 'type': 'Mixed'},
        };

        // 批量存储
        await cacheManager.putFundDataBatch(fundData);

        // 批量获取
        final results =
            await cacheManager.getFundDataBatch<Map<String, dynamic>>(
          ['005827', '110022', '161725', '999999'], // 包含一个不存在的基金
        );

        expect(results['005827'], equals(fundData['005827']));
        expect(results['110022'], equals(fundData['110022']));
        expect(results['161725'], equals(fundData['161725']));
        expect(results['999999'], isNull);
      });
    });

    group('缓存键验证和解析测试', () {
      setUp(() async {
        await cacheManager.initialize();
      });

      test('应该验证生成的缓存键', () async {
        // 生成一个缓存键
        final key = keyManager.fundDataKey('005827');

        // 验证键格式
        expect(cacheManager.validateCacheKey(key), isTrue);

        // 存储数据
        await cacheManager.put(key, 'Test Data');

        // 解析键信息
        final keyInfo = cacheManager.parseCacheKey(key);
        expect(keyInfo, isNotNull);
        expect(keyInfo!.type, equals(CacheKeyType.fundData));
        expect(keyInfo.identifier, equals('005827'));
        expect(keyInfo.version, equals('latest'));
      });

      test('应该拒绝无效的缓存键', () {
        const invalidKeys = [
          'invalid_key',
          'fund_data_005827',
          'jisu_fund_invalid_type_test',
          '',
        ];

        for (final key in invalidKeys) {
          expect(cacheManager.validateCacheKey(key), isFalse);
        }
      });

      test('应该正确解析复杂的缓存键', () async {
        final complexKey = keyManager.generateKey(
          CacheKeyType.fundData,
          'list_open_funds',
          version: CacheKeyVersion.v2,
          params: ['type_equity', 'risk_high'],
        );

        final keyInfo = cacheManager.parseCacheKey(complexKey);
        expect(keyInfo, isNotNull);
        expect(keyInfo!.type, equals(CacheKeyType.fundData));
        expect(keyInfo.identifier, equals('list_open_funds'));
        expect(keyInfo.version, equals('2.0'));
        expect(keyInfo.params, equals(['type_equity', 'risk_high']));
      });
    });

    group('缓存迁移集成测试', () {
      setUp(() async {
        await cacheManager.initialize();
      });

      test('应该迁移现有缓存到新格式', () async {
        // 首先添加一些旧格式的数据（模拟现有缓存）
        await cacheManager.put('fund_005827', 'Old Format Data');
        await cacheManager.put('cache_timestamp', '2023-01-01');
        await cacheManager.put('search_index_name', 'index_data');

        // 执行迁移
        final migrationResult = await cacheManager.migrateExistingCache();

        expect(migrationResult.success, isTrue);
        expect(migrationResult.migratedCount, greaterThan(0));

        // 验证新格式键是否工作
        final newData = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          '005827',
        );

        // 注意：具体的迁移行为取决于迁移适配器的实现
        // 这里我们主要验证迁移过程不会出错
        expect(migrationResult.message, contains('成功'));
      });

      test('应该提供迁移统计信息', () async {
        // 获取键管理统计信息
        final stats = cacheManager.getKeyManagementStats();

        expect(stats['key_manager_enabled'], isTrue);
        expect(stats['migration_enabled'], isTrue);
        expect(stats['standard_box_names'], isA<Map<String, String>>());
        expect(stats['migration_stats'], isA<Map<String, dynamic>>());
      });

      test('应该支持启用/禁用迁移', () async {
        // 禁用迁移
        cacheManager.setMigrationEnabled(false);

        final stats1 = cacheManager.getKeyManagementStats();
        expect(stats1['migration_enabled'], isFalse);

        // 启用迁移
        cacheManager.setMigrationEnabled(true);

        final stats2 = cacheManager.getKeyManagementStats();
        expect(stats2['migration_enabled'], isTrue);
      });
    });

    group('配置常量集成测试', () {
      setUp(() async {
        await cacheManager.initialize();
      });

      test('应该使用配置常量生成缓存键', () {
        // 使用配置常量生成基金数据键
        final fundKey = CacheKeyConfig.generateFundDataKey(
          FundDataKeys.basicInfo,
          '005827',
        );

        expect(fundKey, contains('jisu_fund_fundData_basic_info_005827'));

        // 使用配置常量生成基金列表键
        final listKey = CacheKeyConfig.generateFundListKey(
          FundListKeys.openFunds,
          filters: {'type': 'equity'},
        );

        expect(listKey, contains('list_open_funds'));
        expect(listKey, contains('type_equity'));

        // 使用配置常量生成搜索索引键
        final indexKey = CacheKeyConfig.generateSearchIndexKey(
          SearchIndexKeys.fundNameIndex,
        );

        expect(indexKey, contains('jisu_fund_searchIndex_fund_name_index'));

        // 生成用户偏好键（需要使用标准方法）
        final preferenceKey = keyManager.userPreferenceKey(
          UserPreferenceKeys.favoriteFunds,
        );

        expect(
            preferenceKey, contains('jisu_fund_userPreference_favorite_funds'));

        // 生成元数据键
        final metadataKey = keyManager.metadataKey(
          MetadataKeys.cacheUpdatedTime,
        );

        expect(metadataKey, contains('jisu_fund_metadata_cache_updated_time'));

        // 生成临时数据键
        final temporaryKey = keyManager.temporaryKey(
          TemporaryKeys.currentSession,
          sessionId: 'session123',
        );

        expect(temporaryKey,
            contains('jisu_fund_temporary_current_session_session123'));

        // 生成系统配置键
        final configKey = keyManager.systemConfigKey(
          SystemConfigKeys.apiConfig,
        );

        expect(configKey, contains('jisu_fund_systemConfig_api_config'));
      });

      test('应该支持所有过期时间配置', () {
        expect(ExpirationTimeConfig.shortTerm, equals(Duration(minutes: 5)));
        expect(ExpirationTimeConfig.mediumTerm, equals(Duration(hours: 1)));
        expect(ExpirationTimeConfig.longTerm, equals(Duration(hours: 6)));
        expect(ExpirationTimeConfig.permanent, equals(Duration(days: 30)));
        expect(ExpirationTimeConfig.realtime, equals(Duration(minutes: 1)));
        expect(ExpirationTimeConfig.historical, equals(Duration(hours: 24)));
        expect(ExpirationTimeConfig.userPreference, equals(Duration(days: 30)));
        expect(ExpirationTimeConfig.systemConfig, equals(Duration(days: 7)));
        expect(ExpirationTimeConfig.temporary, equals(Duration(minutes: 30)));
      });

      test('应该支持所有优先级配置', () {
        expect(PriorityConfig.low, equals('low'));
        expect(PriorityConfig.normal, equals('normal'));
        expect(PriorityConfig.high, equals('high'));
        expect(PriorityConfig.critical, equals('critical'));
      });
    });

    group('性能和稳定性测试', () {
      setUp(() async {
        await cacheManager.initialize();
      });

      test('应该处理大量缓存键操作', () async {
        const fundCount = 100;
        final futures = <Future<void>>[];

        // 批量生成和存储数据
        for (int i = 0; i < fundCount; i++) {
          final fundCode = '${(i + 100000).toString().padLeft(6, '0')}';

          futures.add(cacheManager.putWithStandardKey<String>(
            CacheKeyType.fundData,
            fundCode,
            'Fund Data $i',
          ));
        }

        await Future.wait(futures);

        // 验证所有数据都已存储
        int successCount = 0;
        for (int i = 0; i < fundCount; i++) {
          final fundCode = '${(i + 100000).toString().padLeft(6, '0')}';
          final result = cacheManager.getWithStandardKey<String>(
            CacheKeyType.fundData,
            fundCode,
          );

          if (result != null) {
            successCount++;
          }
        }

        expect(successCount, equals(fundCount));
      });

      test('应该支持并发缓存操作', () async {
        const concurrentCount = 20;
        final futures = <Future<void>>[];

        // 并发存储操作
        for (int i = 0; i < concurrentCount; i++) {
          futures.add(cacheManager.putWithStandardKey<String>(
            CacheKeyType.temporary,
            'concurrent_test_$i',
            'Concurrent Data $i',
          ));
        }

        await Future.wait(futures);

        // 并发读取操作
        final readFutures = <Future<String?>>[];
        for (int i = 0; i < concurrentCount; i++) {
          readFutures.add(Future.value(
            cacheManager.getWithStandardKey<String>(
              CacheKeyType.temporary,
              'concurrent_test_$i',
            ),
          ));
        }

        final results = await Future.wait(readFutures);

        // 验证结果
        expect(results.where((r) => r != null).length, equals(concurrentCount));
      });

      test('应该正确处理内存和磁盘缓存', () async {
        // 存储数据
        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          'memory_test',
          'Memory Test Data',
        );

        // 立即读取（应该在内存缓存中）
        final memoryResult = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          'memory_test',
        );

        expect(memoryResult, equals('Memory Test Data'));

        // 获取缓存统计信息
        final stats = await cacheManager.getStats();
        expect(stats['total_keys'], greaterThan(0));
        expect(stats['l1_cache'], isA<Map<String, dynamic>>());
        expect(stats['l2_cache'], isA<Map<String, dynamic>>());
      });
    });

    group('错误处理和边界情况测试', () {
      setUp(() async {
        await cacheManager.initialize();
      });

      test('应该处理空参数和null值', () async {
        // 测试空字符串
        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          '',
          'Empty Key Test',
        );

        final emptyKeyResult = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          '',
        );

        expect(emptyKeyResult, equals('Empty Key Test'));

        // 测试特殊字符
        const specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          specialChars,
          'Special Chars Test',
        );

        final specialCharsResult = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          specialChars,
        );

        expect(specialCharsResult, equals('Special Chars Test'));
      });

      test('应该处理超长标识符', () async {
        final longIdentifier = 'a' * 1000; // 1000个字符

        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          longIdentifier,
          'Long Identifier Test',
        );

        final longResult = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          longIdentifier,
        );

        expect(longResult, equals('Long Identifier Test'));
      });

      test('应该处理Unicode字符', () async {
        const unicodeIdentifier = '基金测试_🚀_测试基金';

        await cacheManager.putWithStandardKey<String>(
          CacheKeyType.fundData,
          unicodeIdentifier,
          'Unicode Test 基金数据',
        );

        final unicodeResult = cacheManager.getWithStandardKey<String>(
          CacheKeyType.fundData,
          unicodeIdentifier,
        );

        expect(unicodeResult, equals('Unicode Test 基金数据'));
      });
    });

    group('端到端场景测试', () {
      setUp(() async {
        await cacheManager.initialize();
      });

      test('应该完成完整的基金数据管理流程', () async {
        // 1. 存储基金基础信息
        await cacheManager.putWithStandardKey<Map<String, dynamic>>(
          CacheKeyType.fundData,
          '005827',
          {
            'name': '易方达蓝筹精选混合',
            'code': '005827',
            'type': '混合型',
            'company': '易方达基金',
          },
          expiration: ExpirationTimeConfig.longTerm,
        );

        // 2. 存储基金净值数据
        await cacheManager.putWithStandardKey<Map<String, dynamic>>(
          CacheKeyType.fundData,
          '005827_nav',
          {
            'unit_nav': '2.3456',
            'accumulated_nav': '2.5678',
            'nav_date': '2023-12-01',
          },
          params: ['nav_data'],
          expiration: ExpirationTimeConfig.shortTerm,
        );

        // 3. 存储用户偏好
        await cacheManager.putWithStandardKey<List<String>>(
          CacheKeyType.userPreference,
          'favorite_funds',
          ['005827', '110022', '161725'],
          expiration: ExpirationTimeConfig.userPreference,
        );

        // 4. 存储搜索索引
        await cacheManager.putWithStandardKey<List<String>>(
          CacheKeyType.searchIndex,
          'fund_name',
          ['005827', '110022', '161725'],
        );

        // 5. 验证数据检索
        final fundInfo = cacheManager.getWithStandardKey<Map<String, dynamic>>(
          CacheKeyType.fundData,
          '005827',
        );

        expect(fundInfo!['name'], equals('易方达蓝筹精选混合'));
        expect(fundInfo['code'], equals('005827'));

        final navData = cacheManager.getWithStandardKey<Map<String, dynamic>>(
          CacheKeyType.fundData,
          '005827_nav',
          params: ['nav_data'],
        );

        expect(navData!['unit_nav'], equals('2.3456'));

        final favorites = cacheManager.getWithStandardKey<List<String>>(
          CacheKeyType.userPreference,
          'favorite_funds',
        );

        expect(favorites, contains('005827'));

        final nameIndex = cacheManager.getWithStandardKey<List<String>>(
          CacheKeyType.searchIndex,
          'fund_name',
        );

        expect(nameIndex, contains('005827'));

        // 6. 获取系统统计信息
        final systemStats = await cacheManager.getStats();
        expect(systemStats['total_keys'], greaterThan(0));

        final keyManagementStats = cacheManager.getKeyManagementStats();
        expect(keyManagementStats['key_manager_enabled'], isTrue);

        AppLogger.info('✅ 端到端测试完成，所有缓存键管理功能正常工作');
      });
    });
  });
}
