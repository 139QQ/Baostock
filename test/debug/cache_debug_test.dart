import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/storage/cache_storage.dart';
import 'package:jisu_fund_analyzer/src/core/cache/strategies/cache_strategies.dart';
import 'package:jisu_fund_analyzer/src/core/cache/config/cache_config_manager.dart';

void main() {
  group('Cache Debug Tests', () {
    late IUnifiedCacheService cacheService;

    setUp(() async {
      final storage = CacheStorageFactory.createMemoryStorage();
      await storage.initialize();
      final strategy = CacheStrategyFactory.getStrategy('lru');
      final configManager = CacheConfigManager();

      cacheService = UnifiedCacheManager(
        storage: storage,
        strategy: strategy,
        configManager: configManager,
        config: UnifiedCacheConfig.testing(),
      );
    });

    test('Debug complex data serialization', () async {
      // Arrange
      const key = 'debug_complex';
      final complexData = {
        'string_field': 'test_string',
        'number_field': 42,
        'boolean_field': true,
        'list_field': ['item1', 'item2'],
      };

      // Act
      await cacheService.put(key, complexData);
      final retrieved = await cacheService.get<Map<String, dynamic>>(key);

      // Debug
      print('Original data: $complexData');
      print('Retrieved data: $retrieved');
      print('Is null: ${retrieved == null}');

      // Assert
      expect(retrieved, isNotNull, reason: 'Retrieved data should not be null');
      if (retrieved != null) {
        expect(retrieved['string_field'], equals('test_string'));
        expect(retrieved['number_field'], equals(42));
      }
    });
  });
}
