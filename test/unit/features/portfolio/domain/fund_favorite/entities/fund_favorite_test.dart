import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';

void main() {
  group('FundFavorite Tests', () {
    final testFavorite = FundFavorite(
      fundCode: '000001',
      fundName: '华夏成长混合',
      fundType: '混合型',
      fundManager: '华夏基金管理有限公司',
      addedAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2023-12-01T00:00:00.000Z'),
      currentNav: 1.5,
      dailyChange: 2.5,
      previousNav: 1.4,
      fundScale: 50.8,
    );

    group('Constructor Tests', () {
      test('should create FundFavorite with required fields', () {
        // Act
        final favorite = FundFavorite(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          fundManager: '易方达基金管理有限公司',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(favorite.fundCode, '110022');
        expect(favorite.fundName, '易方达消费行业');
        expect(favorite.fundType, '股票型');
        expect(favorite.fundManager, '易方达基金管理有限公司');
        expect(favorite.sortWeight, 0.0); // 默认值
        expect(favorite.isSynced, isFalse); // 默认值
        expect(favorite.currentNav, isNull); // 可选字段
        expect(favorite.notes, isNull); // 可选字段
      });

      test('should create FundFavorite with all optional fields', () {
        // Act
        final favorite = FundFavorite(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          fundManager: '易方达基金管理有限公司',
          addedAt: DateTime.parse('2023-01-01'),
          updatedAt: DateTime.parse('2023-12-01'),
          sortWeight: 1.5,
          notes: '重点关注',
          currentNav: 2.1,
          dailyChange: 1.8,
          previousNav: 2.0,
          establishDate: DateTime.parse('2020-01-01'),
          fundScale: 80.5,
          isSynced: true,
          cloudId: 'cloud_001',
        );

        // Assert
        expect(favorite.sortWeight, 1.5);
        expect(favorite.notes, '重点关注');
        expect(favorite.currentNav, 2.1);
        expect(favorite.dailyChange, 1.8);
        expect(favorite.previousNav, 2.0);
        expect(favorite.establishDate, DateTime.parse('2020-01-01'));
        expect(favorite.fundScale, 80.5);
        expect(favorite.isSynced, isTrue);
        expect(favorite.cloudId, 'cloud_001');
      });
    });

    group('CopyWith Tests', () {
      test('should create copy with updated fields', () {
        // Act
        final updatedFavorite = testFavorite.copyWith(
          currentNav: 1.6,
          dailyChange: 3.0,
          notes: '更新备注',
        );

        // Assert
        expect(updatedFavorite.fundCode, testFavorite.fundCode); // 未更改
        expect(updatedFavorite.fundName, testFavorite.fundName); // 未更改
        expect(updatedFavorite.currentNav, 1.6); // 已更改
        expect(updatedFavorite.dailyChange, 3.0); // 已更改
        expect(updatedFavorite.notes, '更新备注'); // 已更改
        expect(updatedFavorite.updatedAt,
            isNot(equals(testFavorite.updatedAt))); // 自动更新
      });

      test('should handle all field updates', () {
        // Act
        final updatedFavorite = testFavorite.copyWith(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          fundManager: '易方达基金管理有限公司',
          sortWeight: 2.0,
          notes: '完全更新',
          currentNav: 2.1,
          dailyChange: 1.8,
          previousNav: 2.0,
          establishDate: DateTime.parse('2020-01-01'),
          fundScale: 80.5,
          isSynced: true,
          cloudId: 'cloud_001',
        );

        // Assert
        expect(updatedFavorite.fundCode, '110022');
        expect(updatedFavorite.fundName, '易方达消费行业');
        expect(updatedFavorite.fundType, '股票型');
        expect(updatedFavorite.fundManager, '易方达基金管理有限公司');
        expect(updatedFavorite.sortWeight, 2.0);
        expect(updatedFavorite.notes, '完全更新');
        expect(updatedFavorite.currentNav, 2.1);
        expect(updatedFavorite.dailyChange, 1.8);
        expect(updatedFavorite.previousNav, 2.0);
        expect(updatedFavorite.establishDate, DateTime.parse('2020-01-01'));
        expect(updatedFavorite.fundScale, 80.5);
        expect(updatedFavorite.isSynced, isTrue);
        expect(updatedFavorite.cloudId, 'cloud_001');
      });

      test('should create copy with null values', () {
        // Act
        final updatedFavorite = testFavorite.copyWith(
          notes: null,
          currentNav: null,
          dailyChange: null,
        );

        // Assert
        expect(updatedFavorite.notes, isNull);
        expect(updatedFavorite.currentNav, isNull);
        expect(updatedFavorite.dailyChange, isNull);
      });
    });

    group('Update Market Data Tests', () {
      test('should update market data correctly', () {
        // Act
        final updatedFavorite = testFavorite.updateMarketData(
          currentNav: 1.8,
          dailyChange: 4.2,
          previousNav: 1.6,
        );

        // Assert
        expect(updatedFavorite.currentNav, 1.8);
        expect(updatedFavorite.dailyChange, 4.2);
        expect(updatedFavorite.previousNav, 1.6);
        expect(
            updatedFavorite.updatedAt, isNot(equals(testFavorite.updatedAt)));
      });

      test('should update partial market data', () {
        // Act
        final updatedFavorite = testFavorite.updateMarketData(
          currentNav: 1.7,
          // dailyChange 为 null，不更新
          previousNav: 1.5,
        );

        // Assert
        expect(updatedFavorite.currentNav, 1.7);
        expect(updatedFavorite.dailyChange, testFavorite.dailyChange); // 保持原值
        expect(updatedFavorite.previousNav, 1.5);
      });

      test('should handle null market data updates', () {
        // Act
        final updatedFavorite = testFavorite.updateMarketData();

        // Assert
        expect(updatedFavorite.currentNav, testFavorite.currentNav); // 保持原值
        expect(updatedFavorite.dailyChange, testFavorite.dailyChange); // 保持原值
        expect(updatedFavorite.previousNav, testFavorite.previousNav); // 保持原值
      });
    });

    group('Update Sort Weight Tests', () {
      test('should update sort weight correctly', () {
        // Act
        final updatedFavorite = testFavorite.updateSortWeight(3.5);

        // Assert
        expect(updatedFavorite.sortWeight, 3.5);
        expect(
            updatedFavorite.updatedAt, isNot(equals(testFavorite.updatedAt)));
      });

      test('should handle zero sort weight', () {
        // Act
        final updatedFavorite = testFavorite.updateSortWeight(0.0);

        // Assert
        expect(updatedFavorite.sortWeight, 0.0);
      });

      test('should handle negative sort weight', () {
        // Act
        final updatedFavorite = testFavorite.updateSortWeight(-1.0);

        // Assert
        expect(updatedFavorite.sortWeight, -1.0);
      });
    });

    group('Price Alert Settings Tests', () {
      test('should set price alerts correctly', () {
        // Arrange
        final priceAlerts = PriceAlertSettings(
          enabled: true,
          riseThreshold: 5.0,
          fallThreshold: 3.0,
          targetPrices: [
            TargetPriceAlert(
              targetPrice: 2.0,
              type: TargetPriceType.reach,
              createdAt: DateTime.parse('2023-12-01T00:00:00.000Z'),
            ),
          ],
          alertMethods: [AlertMethod.push, AlertMethod.email],
        );

        // Act
        final updatedFavorite = testFavorite.setPriceAlerts(priceAlerts);

        // Assert
        expect(updatedFavorite.priceAlerts, equals(priceAlerts));
        expect(
            updatedFavorite.updatedAt, isNot(equals(testFavorite.updatedAt)));
      });
    });

    group('Sync Status Tests', () {
      test('should mark as synced correctly', () {
        // Act
        final updatedFavorite = testFavorite.markAsSynced('cloud_123');

        // Assert
        expect(updatedFavorite.isSynced, isTrue);
        expect(updatedFavorite.cloudId, 'cloud_123');
        expect(
            updatedFavorite.updatedAt, isNot(equals(testFavorite.updatedAt)));
      });

      test('should mark as need sync correctly', () {
        // Arrange
        final syncedFavorite = testFavorite.copyWith(
          isSynced: true,
          cloudId: 'cloud_123',
        );

        // Act
        final updatedFavorite = syncedFavorite.markAsNeedSync();

        // Assert
        expect(updatedFavorite.isSynced, isFalse);
        expect(updatedFavorite.cloudId, 'cloud_123'); // 保持原有 cloudId
        expect(
            updatedFavorite.updatedAt, isNot(equals(syncedFavorite.updatedAt)));
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        // Act
        final json = testFavorite.toJson();

        // Assert
        expect(json['fundCode'], '000001');
        expect(json['fundName'], '华夏成长混合');
        expect(json['fundType'], '混合型');
        expect(json['fundManager'], '华夏基金管理有限公司');
        expect(json['sortWeight'], 0.0);
        expect(json['isSynced'], isFalse);
        expect(json['currentNav'], 1.5);
        expect(json['dailyChange'], 2.5);
        expect(json['previousNav'], 1.4);
        expect(json['fundScale'], 50.8);
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'fundCode': '110022',
          'fundName': '易方达消费行业',
          'fundType': '股票型',
          'fundManager': '易方达基金管理有限公司',
          'addedAt': '2023-01-01T00:00:00.000Z',
          'updatedAt': '2023-12-01T00:00:00.000Z',
          'sortWeight': 1.5,
          'notes': '重点关注',
          'currentNav': 2.1,
          'dailyChange': 1.8,
          'previousNav': 2.0,
          'establishDate': '2020-01-01T00:00:00.000Z',
          'fundScale': 80.5,
          'isSynced': true,
          'cloudId': 'cloud_001',
        };

        // Act
        final favorite = FundFavorite.fromJson(json);

        // Assert
        expect(favorite.fundCode, '110022');
        expect(favorite.fundName, '易方达消费行业');
        expect(favorite.fundType, '股票型');
        expect(favorite.fundManager, '易方达基金管理有限公司');
        expect(favorite.sortWeight, 1.5);
        expect(favorite.notes, '重点关注');
        expect(favorite.currentNav, 2.1);
        expect(favorite.dailyChange, 1.8);
        expect(favorite.previousNav, 2.0);
        expect(favorite.establishDate, DateTime.parse('2020-01-01'));
        expect(favorite.fundScale, 80.5);
        expect(favorite.isSynced, isTrue);
        expect(favorite.cloudId, 'cloud_001');
      });

      test('should handle JSON with missing optional fields', () {
        // Arrange
        final json = {
          'fundCode': '110022',
          'fundName': '易方达消费行业',
          'fundType': '股票型',
          'fundManager': '易方达基金管理有限公司',
          'addedAt': '2023-01-01T00:00:00.000Z',
          'updatedAt': '2023-12-01T00:00:00.000Z',
        };

        // Act
        final favorite = FundFavorite.fromJson(json);

        // Assert
        expect(favorite.fundCode, '110022');
        expect(favorite.fundName, '易方达消费行业');
        expect(favorite.sortWeight, 0.0); // 默认值
        expect(favorite.notes, isNull);
        expect(favorite.currentNav, isNull);
        expect(favorite.isSynced, isFalse); // 默认值
      });
    });

    group('Equality Tests', () {
      test('should be equal when all properties match', () {
        // Arrange
        final favorite1 = testFavorite;
        final favorite2 = FundFavorite(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '华夏基金管理有限公司',
          addedAt: DateTime.parse('2023-01-01'),
          updatedAt: DateTime.parse('2023-12-01'),
          currentNav: 1.5,
          dailyChange: 2.5,
          previousNav: 1.4,
          fundScale: 50.8,
        );

        // Act & Assert
        expect(favorite1, equals(favorite2));
        expect(favorite1.hashCode, equals(favorite2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final favorite1 = testFavorite;
        final favorite2 = testFavorite.copyWith(currentNav: 1.6);

        // Act & Assert
        expect(favorite1, isNot(equals(favorite2)));
      });

      test('should not be equal when updatedAt differs', () {
        // Arrange
        final favorite1 = testFavorite;
        final favorite2 = testFavorite.copyWith(
          updatedAt: DateTime.now().add(const Duration(days: 1)),
        );

        // Act & Assert
        expect(favorite1, isNot(equals(favorite2)));
      });
    });

    group('ToString Tests', () {
      test('should generate meaningful string representation', () {
        // Act
        final result = testFavorite.toString();

        // Assert
        expect(result, contains('FundFavorite'));
        expect(result, contains('000001'));
        expect(result, contains('华夏成长混合'));
        expect(result, contains('混合型'));
      });
    });
  });

  group('PriceAlertSettings Tests', () {
    final testPriceAlerts = PriceAlertSettings(
      enabled: true,
      riseThreshold: 5.0,
      fallThreshold: 3.0,
      alertMethods: [AlertMethod.push, AlertMethod.email],
    );

    group('Constructor Tests', () {
      test('should create PriceAlertSettings with default values', () {
        // Act
        final priceAlerts = PriceAlertSettings();

        // Assert
        expect(priceAlerts.enabled, isFalse); // 默认值
        expect(priceAlerts.riseThreshold, isNull);
        expect(priceAlerts.fallThreshold, isNull);
        expect(priceAlerts.targetPrices, isEmpty); // 默认空列表
        expect(priceAlerts.lastAlertTime, isNull);
        expect(priceAlerts.alertMethods, [AlertMethod.push]); // 默认值
      });

      test('should create PriceAlertSettings with all fields', () {
        // Arrange & Assert
        final priceAlerts = PriceAlertSettings(
          enabled: true,
          riseThreshold: 5.0,
          fallThreshold: 3.0,
          targetPrices: [
            TargetPriceAlert(
              targetPrice: 2.0,
              type: TargetPriceType.reach,
              createdAt: DateTime.parse('2023-12-01T00:00:00.000Z'),
            ),
          ],
          lastAlertTime: DateTime.parse('2023-12-01T12:00:00.000Z'),
          alertMethods: [AlertMethod.push, AlertMethod.email, AlertMethod.sms],
        );

        expect(priceAlerts.enabled, isTrue);
        expect(priceAlerts.riseThreshold, 5.0);
        expect(priceAlerts.fallThreshold, 3.0);
        expect(priceAlerts.targetPrices, hasLength(1));
        expect(priceAlerts.lastAlertTime, isNotNull);
        expect(priceAlerts.alertMethods, hasLength(3));
      });
    });

    group('CopyWith Tests', () {
      test('should create copy with updated fields', () {
        // Act
        final updatedAlerts = testPriceAlerts.copyWith(
          enabled: false,
          riseThreshold: 8.0,
        );

        // Assert
        expect(updatedAlerts.enabled, isFalse);
        expect(updatedAlerts.riseThreshold, 8.0);
        expect(
            updatedAlerts.fallThreshold, testPriceAlerts.fallThreshold); // 保持原值
        expect(
            updatedAlerts.alertMethods, testPriceAlerts.alertMethods); // 保持原值
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        // Act
        final json = testPriceAlerts.toJson();

        // Assert
        expect(json['enabled'], isTrue);
        expect(json['riseThreshold'], 5.0);
        expect(json['fallThreshold'], 3.0);
        expect(json['alertMethods'], ['push', 'email']);
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'enabled': true,
          'riseThreshold': 5.0,
          'fallThreshold': 3.0,
          'targetPrices': [
            {
              'targetPrice': 2.0,
              'type': 'reach',
              'isActive': true,
              'createdAt': '2023-12-01T00:00:00.000Z',
            },
          ],
          'lastAlertTime': '2023-12-01T12:00:00.000Z',
          'alertMethods': ['push', 'email', 'sms'],
        };

        // Act
        final priceAlerts = PriceAlertSettings.fromJson(json);

        // Assert
        expect(priceAlerts.enabled, isTrue);
        expect(priceAlerts.riseThreshold, 5.0);
        expect(priceAlerts.fallThreshold, 3.0);
        expect(priceAlerts.targetPrices, hasLength(1));
        expect(priceAlerts.lastAlertTime, isNotNull);
        expect(priceAlerts.alertMethods, hasLength(3));
      });
    });
  });

  group('TargetPriceAlert Tests', () {
    final testTargetPrice = TargetPriceAlert(
      targetPrice: 2.0,
      type: TargetPriceType.reach,
      isActive: true,
      createdAt: DateTime.parse('2023-12-01T00:00:00.000Z'),
    );

    group('Constructor Tests', () {
      test('should create TargetPriceAlert with required fields', () {
        // Act & Assert
        expect(testTargetPrice.targetPrice, 2.0);
        expect(testTargetPrice.type, TargetPriceType.reach);
        expect(testTargetPrice.isActive, isTrue); // 默认值
        expect(testTargetPrice.createdAt, DateTime.parse('2023-12-01'));
      });

      test('should create inactive TargetPriceAlert', () {
        // Act
        final inactiveAlert = TargetPriceAlert(
          targetPrice: 1.8,
          type: TargetPriceType.below,
          isActive: false,
          createdAt: DateTime.parse('2023-12-01T00:00:00.000Z'),
        );

        // Assert
        expect(inactiveAlert.isActive, isFalse);
        expect(inactiveAlert.type, TargetPriceType.below);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        // Act
        final json = testTargetPrice.toJson();

        // Assert
        expect(json['targetPrice'], 2.0);
        expect(json['type'], 'reach');
        expect(json['isActive'], isTrue);
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'targetPrice': 2.5,
          'type': 'exceed',
          'isActive': false,
          'createdAt': '2023-12-01T00:00:00.000Z',
        };

        // Act
        final alert = TargetPriceAlert.fromJson(json);

        // Assert
        expect(alert.targetPrice, 2.5);
        expect(alert.type, TargetPriceType.exceed);
        expect(alert.isActive, isFalse);
      });
    });
  });

  group('Enum Tests', () {
    group('TargetPriceType Tests', () {
      test('should have correct enum values', () {
        expect(TargetPriceType.reach, isA<TargetPriceType>());
        expect(TargetPriceType.exceed, isA<TargetPriceType>());
        expect(TargetPriceType.below, isA<TargetPriceType>());
      });
    });

    group('AlertMethod Tests', () {
      test('should have correct enum values', () {
        expect(AlertMethod.push, isA<AlertMethod>());
        expect(AlertMethod.email, isA<AlertMethod>());
        expect(AlertMethod.sms, isA<AlertMethod>());
      });
    });

    group('FundFavoriteSortType Tests', () {
      test('should have correct sort types', () {
        expect(FundFavoriteSortType.addTime, isA<FundFavoriteSortType>());
        expect(FundFavoriteSortType.fundCode, isA<FundFavoriteSortType>());
        expect(FundFavoriteSortType.fundName, isA<FundFavoriteSortType>());
        expect(FundFavoriteSortType.currentNav, isA<FundFavoriteSortType>());
        expect(FundFavoriteSortType.dailyChange, isA<FundFavoriteSortType>());
        expect(FundFavoriteSortType.fundScale, isA<FundFavoriteSortType>());
        expect(FundFavoriteSortType.custom, isA<FundFavoriteSortType>());
      });
    });

    group('FundFavoriteSortDirection Tests', () {
      test('should have correct sort directions', () {
        expect(FundFavoriteSortDirection.ascending,
            isA<FundFavoriteSortDirection>());
        expect(FundFavoriteSortDirection.descending,
            isA<FundFavoriteSortDirection>());
      });
    });
  });
}
