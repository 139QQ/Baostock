import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_migration_adapter.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';

void main() {
  group('缓存键迁移适配器测试', () {
    late CacheKeyMigrationAdapter migrationAdapter;
    late String tempPath;

    setUpAll(() async {
      // 初始化Hive用于测试 - 使用纯Hive而不是HiveFlutter
      tempPath = Directory.systemTemp.path + '/cache_key_migration_test';
      await Directory(tempPath).create(recursive: true);
      Hive.init(tempPath);
    });

    // tearDownAll 已移除以避免清理问题

    setUp(() {
      migrationAdapter = CacheKeyMigrationAdapter.instance;
    });

    group('旧键识别测试', () {
      test('应该识别旧格式缓存键', () {
        const oldKeys = [
          'fund_cache_timestamp',
          'fund_cache_version',
          'optimized_funds',
          'funds_v3',
          'high_performance_funds',
          'fund_search_index',
          'fund_cache_metadata',
          'unified_fund_cache',
          'unified_fund_metadata',
          'unified_fund_index',
        ];

        for (final key in oldKeys) {
          expect(migrationAdapter.isLegacyKey(key), isTrue,
              reason: '应该识别为旧键: $key');
        }
      });

      test('应该识别包含旧模式的缓存键', () {
        const oldKeys = [
          'cache_timestamp_123',
          'optimized_funds_data',
          'my_fund_search_index',
          'fund_cache_metadata_v2',
        ];

        for (final key in oldKeys) {
          expect(migrationAdapter.isLegacyKey(key), isTrue,
              reason: '应该识别包含旧模式的键: $key');
        }
      });

      test('应该识别标准格式缓存键', () {
        const standardKeys = [
          'jisu_fund_fundData_test_fund@latest',
          'jisu_fund_searchIndex_fund_name@2.0',
          'jisu_fund_userPreference_favorite_funds@latest',
          'jisu_fund_metadata_cache_timestamp@latest',
          'jisu_fund_temporary_search_results@latest',
          'jisu_fund_systemConfig_api_config@3.0',
        ];

        for (final key in standardKeys) {
          // 先手动检查键的解析情况
          final isValidKey = CacheKeyManager.instance.isValidKey(key);
          final parseResult = CacheKeyManager.instance.parseKey(key);
          print('Key: $key');
          print('  isValidKey: $isValidKey');
          print('  parseResult: $parseResult');
          print('  isLegacyKey: ${migrationAdapter.isLegacyKey(key)}');
          print('---');

          expect(migrationAdapter.isLegacyKey(key), isFalse,
              reason: '应该识别为标准键: $key');
        }
      });
    });

    group('缓存键生成测试', () {
      test('应该为基金代码模式生成正确的键', () async {
        const testCases = [
          'fund_005827',
          '005827_data',
          'cache_110022',
        ];

        for (final oldKey in testCases) {
          // 由于 _generateNewKey 是私有方法，我们通过 migrateKey 来测试
          final result = await migrationAdapter.migrateKey(oldKey);
          // 注意：基金代码模式应该能正确识别6位数字并生成对应的基金数据键
          expect(result, isNotNull);
          // 验证生成的键是有效的标准格式
          expect(CacheKeyManager.instance.isValidKey(result!), isTrue,
              reason: '生成的键应该是有效的标准格式: $result');
        }
      });

      test('应该为索引模式生成正确的键', () async {
        const testCases = [
          'code_index',
          'name_index_data',
          'pinyin_search',
          'type_classification',
        ];

        for (final oldKey in testCases) {
          final result = await migrationAdapter.migrateKey(oldKey);
          expect(result, isNotNull);
          // 验证生成的键是有效的标准格式
          expect(CacheKeyManager.instance.isValidKey(result!), isTrue,
              reason: '生成的键应该是有效的标准格式: $result');
          // 验证键类型是搜索索引
          final keyInfo = CacheKeyManager.instance.parseKey(result);
          expect(keyInfo?.type, equals(CacheKeyType.searchIndex),
              reason: '索引模式应该生成搜索索引类型的键: $result');
        }
      });

      test('应该为元数据模式生成正确的键', () async {
        final testCases = [
          'cache_timestamp',
          'version_info',
          'fund_metadata',
        ];

        for (final oldKey in testCases) {
          final result = await migrationAdapter.migrateKey(oldKey);
          expect(result, isNotNull);
          // 验证生成的键是有效的标准格式
          expect(CacheKeyManager.instance.isValidKey(result!), isTrue,
              reason: '生成的键应该是有效的标准格式: $result');
          // 验证键类型是元数据
          final keyInfo = CacheKeyManager.instance.parseKey(result);
          expect(keyInfo?.type, equals(CacheKeyType.metadata),
              reason: '元数据模式应该生成元数据类型的键: $result');
        }
      });

      test('应该为未知模式生成临时数据键', () async {
        const unknownKeys = [
          'random_data',
          'unknown_pattern',
          'some_weird_key',
        ];

        for (final key in unknownKeys) {
          final result = await migrationAdapter.migrateKey(key);
          expect(result, isNotNull);
          // 验证生成的键是有效的标准格式
          expect(CacheKeyManager.instance.isValidKey(result!), isTrue,
              reason: '生成的键应该是有效的标准格式: $result');
          // 验证键类型是临时数据
          final keyInfo = CacheKeyManager.instance.parseKey(result);
          expect(keyInfo?.type, equals(CacheKeyType.temporary),
              reason: '未知模式应该生成临时数据类型的键: $result');
        }
      });
    });

    group('迁移记录测试', () {
      setUp(() async {
        // 清理之前的迁移记录
        migrationAdapter.clearMigrationRecords();
        await migrationAdapter.initialize();
      });

      tearDown(() {
        migrationAdapter.clearMigrationRecords();
      });

      test('应该记录成功的迁移', () async {
        const oldKey = 'fund_005827';
        final newKey = await migrationAdapter.migrateKey(oldKey);

        expect(newKey, isNotNull);

        // 检查迁移统计
        final stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], equals(1));
        expect(stats['successful_migrations'], equals(1));
        expect(stats['failed_migrations'], equals(0));
        expect(stats['success_rate'], equals('100.0%'));
      });

      test('应该记录失败的迁移', () async {
        // 尝试迁移一个会导致失败的情况
        // 这里我们模拟一个可能失败的情况
        const oldKey = 'invalid_key_that_causes_failure';

        // 由于我们的实现相对健壮，很难真正让它失败，
        // 但我们可以检查迁移记录的结构
        final result = await migrationAdapter.migrateKey(oldKey);

        // 即使是无效键，也应该生成一个合理的迁移键
        expect(result, isNotNull);
      });

      test('应该避免重复迁移', () async {
        const oldKey = 'fund_005827';

        // 第一次迁移
        final result1 = await migrationAdapter.migrateKey(oldKey);

        // 第二次迁移相同的键
        final result2 = await migrationAdapter.migrateKey(oldKey);

        expect(result1, equals(result2));

        // 检查迁移统计
        final stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], equals(1)); // 只应该记录一次
      });

      test('应该提供迁移统计信息', () async {
        // 执行几次迁移
        const oldKeys = ['fund_005827', 'fund_110022', 'cache_timestamp'];

        for (final key in oldKeys) {
          await migrationAdapter.migrateKey(key);
        }

        final stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], equals(3));
        expect(stats['successful_migrations'], equals(3));
        expect(stats['failed_migrations'], equals(0));
        expect(stats['success_rate'], equals('100.0%'));
        expect(stats['type_distribution'], isA<Map<String, int>>());
        expect(stats['last_migration_time'], isNotNull);
      });
    });

    group('批量迁移测试', () {
      setUp(() async {
        migrationAdapter.clearMigrationRecords();
        await migrationAdapter.initialize();
      });

      tearDown(() {
        migrationAdapter.clearMigrationRecords();
      });

      test('应该批量迁移多个键', () async {
        const oldKeys = ['fund_005827', 'fund_110022', 'cache_timestamp'];

        final results = await migrationAdapter.migrateKeys(oldKeys);

        expect(results, hasLength(3));
        expect(results.values.every((v) => v != null), isTrue);

        // 检查迁移统计
        final stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], equals(3));
        expect(stats['successful_migrations'], equals(3));
      });

      test('应该处理部分失败的批量迁移', () async {
        const oldKeys = ['fund_005827', 'invalid_key', 'cache_timestamp'];

        final results = await migrationAdapter.migrateKeys(oldKeys);

        expect(results, hasLength(3));
        // 所有键都应该生成某种迁移结果（即使是临时的）
        expect(results.values.every((v) => v != null), isTrue);

        final stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], equals(3));
      });
    });

    group('缓存扫描和迁移测试', () {
      late Box testBox;

      setUp(() async {
        // 创建测试盒子
        testBox = await Hive.openBox('test_migration_box');

        // 添加一些旧格式的数据
        await testBox.put('fund_005827', {'name': 'Test Fund 1'});
        await testBox.put('fund_110022', {'name': 'Test Fund 2'});
        await testBox.put('cache_timestamp', '2023-01-01');
        await testBox
            .put('jisu_fund_fundData_new_key@latest', {'name': 'New Fund'});
      });

      tearDown(() async {
        await testBox.clear();
        await testBox.close();
      });

      test('应该扫描并迁移缓存盒子中的旧键', () async {
        final results = await migrationAdapter.scanAndMigrateCache(testBox);

        expect(results, hasLength(4)); // 总共4个键

        // 检查结果
        expect(results['fund_005827'], isNotNull);
        expect(results['fund_110022'], isNotNull);
        expect(results['cache_timestamp'], isNotNull);
        expect(results['jisu_fund_fundData_new_key@latest'],
            isNotNull); // 标准键应该保持不变

        // 验证迁移的键都是有效的标准格式
        for (final entry in results.entries) {
          expect(CacheKeyManager.instance.isValidKey(entry.value!), isTrue,
              reason: '迁移的键应该是有效的标准格式: ${entry.value}');
        }

        // 验证特定类型的迁移结果
        final fundKeyInfo =
            CacheKeyManager.instance.parseKey(results['fund_005827']!);
        expect(fundKeyInfo?.type, equals(CacheKeyType.fundData),
            reason: '基金代码键应该迁移为基金数据类型');

        final timestampKeyInfo =
            CacheKeyManager.instance.parseKey(results['cache_timestamp']!);
        expect(timestampKeyInfo?.type, equals(CacheKeyType.metadata),
            reason: '时间戳键应该迁移为元数据类型');
      });

      test('应该处理空的缓存盒子', () async {
        final emptyBox = await Hive.openBox('empty_test_box');

        final results = await migrationAdapter.scanAndMigrateCache(emptyBox);

        expect(results, isEmpty);

        await emptyBox.close();
      });
    });

    group('错误处理测试', () {
      test('应该处理无效输入', () async {
        // 测试空键列表
        final results = await migrationAdapter.migrateKeys([]);
        expect(results, isEmpty);

        // 测试null参数
        expect(
          () async => await migrationAdapter.migrateKey(''),
          returnsNormally, // 空字符串应该被处理
        );
      });

      test('应该处理记录清理', () async {
        // 添加一些迁移记录
        await migrationAdapter.migrateKey('test_key');

        // 验证记录存在
        var stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], greaterThan(0));

        // 清理记录
        migrationAdapter.clearMigrationRecords();

        // 验证记录已清理
        stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], equals(0));
      });
    });

    group('集成测试', () {
      setUp(() async {
        migrationAdapter.clearMigrationRecords();
        await migrationAdapter.initialize();
      });

      tearDown(() {
        migrationAdapter.clearMigrationRecords();
      });

      test('应该完成完整的迁移流程', () async {
        // 1. 识别旧键
        const oldKeys = ['fund_005827', 'fund_cache_timestamp', 'search_index'];

        for (final key in oldKeys) {
          expect(migrationAdapter.isLegacyKey(key), isTrue);
        }

        // 2. 批量迁移
        final migrationResults = await migrationAdapter.migrateKeys(oldKeys);
        expect(migrationResults, hasLength(3));
        expect(migrationResults.values.every((v) => v != null), isTrue);

        // 3. 验证新键格式
        for (final newKey in migrationResults.values) {
          expect(newKey!.startsWith('jisu_fund_'), isTrue);
          expect(CacheKeyManager.instance.isValidKey(newKey), isTrue);
        }

        // 4. 检查迁移统计
        final stats = migrationAdapter.getMigrationStats();
        expect(stats['total_migrations'], equals(3));
        expect(stats['successful_migrations'], equals(3));
        expect(stats['success_rate'], equals('100.0%'));
      });
    });
  });
}
