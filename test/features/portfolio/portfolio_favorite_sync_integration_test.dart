import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/portfolio_favorite_sync_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';

void main() {
  group('Portfolio Favorite Sync Integration Tests', () {
    late PortfolioFavoriteSyncService syncService;
    late List<FundFavorite> mockFavorites;
    late List<PortfolioHolding> mockHoldings;

    setUp(() {
      syncService = PortfolioFavoriteSyncService();

      // 创建模拟自选基金数据
      mockFavorites = [
        FundFavorite(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '华夏基金',
          addedAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          currentNav: 2.3456,
          dailyChange: 1.23,
          previousNav: 2.3171,
        ),
        FundFavorite(
          fundCode: '000002',
          fundName: '易方达平稳增长',
          fundType: '债券型',
          fundManager: '易方达基金',
          addedAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
          currentNav: 1.1234,
          dailyChange: 0.15,
          previousNav: 1.1217,
        ),
        FundFavorite(
          fundCode: '000003',
          fundName: '嘉实沪深300',
          fundType: '指数型',
          fundManager: '嘉实基金',
          addedAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
          currentNav: 1.5678,
          dailyChange: -0.5,
          previousNav: 1.5756,
        ),
      ];

      // 创建模拟持仓数据
      mockHoldings = [
        PortfolioHolding(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 2.2000,
          costValue: 2200.0,
          marketValue: 2345.60,
          currentNav: 2.3456,
          accumulatedNav: 2.5000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 25)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false,
          status: HoldingStatus.active,
        ),
        PortfolioHolding(
          fundCode: '000004',
          fundName: '南方价值优选',
          fundType: '股票型',
          holdingAmount: 500.0,
          costNav: 3.1000,
          costValue: 1550.0,
          marketValue: 1650.0,
          currentNav: 3.3000,
          accumulatedNav: 3.5000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 15)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false,
          status: HoldingStatus.active,
        ),
      ];
    });

    group('数据一致性检查', () {
      test('应该正确检测数据一致性', () {
        // Act
        final report =
            syncService.checkConsistency(mockFavorites, mockHoldings);

        // Assert
        expect(report.totalFavorites, equals(3));
        expect(report.totalHoldings, equals(2));
        expect(report.commonCount, equals(1)); // 只有000001是共同的
        expect(report.onlyInFavorites, contains('000002'));
        expect(report.onlyInFavorites, contains('000003'));
        expect(report.onlyInHoldings, contains('000004'));
        expect(report.isConsistent, isFalse); // 因为有数据差异
      });

      test('应该检测基本信息不匹配', () {
        // Arrange
        final holdingsWithMismatch = [
          PortfolioHolding(
            fundCode: '000001',
            fundName: '华夏成长混合(旧名称)', // 名称不匹配
            fundType: '混合型',
            holdingAmount: 1000.0,
            costNav: 2.2000,
            costValue: 2200.0,
            marketValue: 2345.60,
            currentNav: 2.3456,
            accumulatedNav: 2.5000,
            holdingStartDate: DateTime.now().subtract(const Duration(days: 25)),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: false,
            status: HoldingStatus.active,
          ),
        ];

        // Act
        final report = syncService.checkConsistency(
            mockFavorites.take(1).toList(), holdingsWithMismatch);

        // Assert
        expect(report.inconsistencies, isNotEmpty);
        expect(report.inconsistencies.first.type,
            equals(InconsistencyType.basicInfoMismatch));
      });

      test('应该检测净值数据差异', () {
        // Arrange
        final holdingsWithNavDiff = [
          PortfolioHolding(
            fundCode: '000001',
            fundName: '华夏成长混合',
            fundType: '混合型',
            holdingAmount: 1000.0,
            costNav: 2.2000,
            costValue: 2200.0,
            marketValue: 2345.60,
            currentNav: 2.2000, // 与自选基金的2.3456差异超过1%
            accumulatedNav: 2.5000,
            holdingStartDate: DateTime.now().subtract(const Duration(days: 25)),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: false,
            status: HoldingStatus.active,
          ),
        ];

        // Act
        final report = syncService.checkConsistency(
            mockFavorites.take(1).toList(), holdingsWithNavDiff);

        // Assert
        expect(report.inconsistencies, isNotEmpty);
        expect(report.inconsistencies.first.type,
            equals(InconsistencyType.navValueMismatch));
      });

      test('应该处理完全一致的数据', () {
        // Arrange
        final identicalHoldings = [
          PortfolioHolding(
            fundCode: '000001',
            fundName: '华夏成长混合',
            fundType: '混合型',
            holdingAmount: 1000.0,
            costNav: 2.3456,
            costValue: 2345.60,
            marketValue: 2345.60,
            currentNav: 2.3456,
            accumulatedNav: 2.5000,
            holdingStartDate: DateTime.now().subtract(const Duration(days: 25)),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: false,
            status: HoldingStatus.active,
          ),
        ];

        // Act
        final report = syncService.checkConsistency(
            mockFavorites.take(1).toList(), identicalHoldings);

        // Assert
        expect(report.isConsistent, isTrue);
        expect(report.inconsistencies, isEmpty);
      });
    });

    group('同步操作验证', () {
      test('应该验证有效的同步操作', () {
        // Arrange
        final options = SyncOptions(
          defaultAmount: 1000.0,
          useCurrentNavAsCost: true,
          keepExistingHoldings: true,
        );

        // Act
        final validation = syncService.validateSyncOperation(
            mockFavorites, mockHoldings, options);

        // Assert
        expect(validation.isValid, isTrue);
        expect(validation.canProceed, isTrue);
        expect(validation.issues, isEmpty);
      });

      test('应该检测无效的同步选项', () {
        // Arrange
        final invalidOptions = SyncOptions(
          defaultAmount: -100.0, // 无效的负数
          useCurrentNavAsCost: true,
          keepExistingHoldings: true,
        );

        // Act
        final validation = syncService.validateSyncOperation(
            mockFavorites, mockHoldings, invalidOptions);

        // Assert
        expect(validation.isValid, isFalse);
        expect(validation.canProceed, isFalse);
        expect(validation.issues, isNotEmpty);
        expect(validation.issues.first.type,
            equals(ValidationIssueType.invalidAmount));
      });

      test('应该检测不完整的基金数据', () {
        // Arrange
        final incompleteFavorites = [
          FundFavorite(
            fundCode: '', // 空代码
            fundName: '测试基金',
            fundType: '混合型',
            fundManager: '测试基金公司',
            addedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final options = SyncOptions();

        // Act
        final validation = syncService.validateSyncOperation(
            incompleteFavorites, mockHoldings, options);

        // Assert
        expect(validation.isValid, isFalse);
        expect(
            validation.issues.any(
                (issue) => issue.type == ValidationIssueType.incompleteData),
            isTrue);
      });

      test('应该检测重复的基金代码', () {
        // Arrange
        final duplicateFavorites = [
          mockFavorites[0],
          mockFavorites[0].copyWith(), // 重复
        ];

        final options = SyncOptions();

        // Act
        final validation =
            syncService.validateSyncOperation(duplicateFavorites, [], options);

        // Assert
        expect(validation.isValid, isFalse);
        expect(
            validation.issues.any(
                (issue) => issue.type == ValidationIssueType.duplicateData),
            isTrue);
      });
    });

    group('完整同步流程', () {
      test('应该成功执行完整的同步流程', () async {
        // Arrange
        final options = SyncOptions(
          defaultAmount: 1500.0,
          useCurrentNavAsCost: true,
          keepExistingHoldings: true,
        );

        // Act
        final result = await syncService.syncFavoritesToHoldings(
            mockFavorites, mockHoldings, options);

        // Assert
        expect(result.success, isTrue);
        expect(result.addedCount, equals(2)); // 000002, 000003 需要添加
        expect(result.updatedCount, equals(1)); // 000001 可能需要更新
        expect(result.totalCount, equals(3)); // 最终持仓总数
        expect(result.operations.length, equals(3)); // 2个添加 + 1个更新
        expect(result.updatedHoldings.length, equals(3));
      });

      test('应该只添加新的基金', () async {
        // Arrange
        final newFavorites = [
          mockFavorites[1],
          mockFavorites[2]
        ]; // 只有000002, 000003
        final options = SyncOptions(
          defaultAmount: 1000.0,
          useCurrentNavAsCost: false,
          keepExistingHoldings: false, // 不保留现有持仓
        );

        // Act
        final result = await syncService.syncFavoritesToHoldings(
            newFavorites, mockHoldings, options);

        // Assert
        expect(result.success, isTrue);
        expect(result.addedCount, equals(2));
        expect(result.updatedCount, equals(0));
        expect(result.removedCount, equals(2)); // 移除现有持仓
        expect(result.totalCount, equals(2));
      });

      test('应该处理同步失败的情况', () async {
        // Arrange
        final invalidFavorites = <FundFavorite>[]; // 空列表会导致验证失败
        final options = SyncOptions();

        // Act
        final result = await syncService.syncFavoritesToHoldings(
            invalidFavorites, mockHoldings, options);

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(result.operations, isEmpty);
      });

      test('应该正确生成同步摘要', () async {
        // Arrange
        final options = SyncOptions(defaultAmount: 2000.0);

        // Act
        final result = await syncService.syncFavoritesToHoldings(
            mockFavorites, [], options);

        // Assert
        expect(result.summary, contains('同步成功'));
        expect(result.summary, contains('添加 3'));
        expect(result.summary, contains('更新 0'));
        expect(result.summary, contains('移除 0'));
        expect(result.summary, contains('总计 3'));
      });
    });

    group('边界情况测试', () {
      test('应该处理空的自选基金列表', () async {
        // Arrange
        final options = SyncOptions();

        // Act
        final result =
            await syncService.syncFavoritesToHoldings([], [], options);

        // Assert
        expect(result.success, isTrue);
        expect(result.totalCount, equals(0));
        expect(result.operations, isEmpty);
      });

      test('应该处理空的持仓列表', () async {
        // Arrange
        final options = SyncOptions(defaultAmount: 1000.0);

        // Act
        final result = await syncService.syncFavoritesToHoldings(
            mockFavorites, [], options);

        // Assert
        expect(result.success, isTrue);
        expect(result.addedCount, equals(3));
        expect(result.totalCount, equals(3));
      });

      test('应该处理大量数据', () async {
        // Arrange
        final largeFavorites = List.generate(
            100,
            (index) => mockFavorites[0].copyWith(
                  fundCode: '${(index + 1).toString().padLeft(6, '0')}',
                  fundName: '测试基金${index + 1}',
                ));

        final options = SyncOptions(defaultAmount: 1000.0);

        // Act
        final result = await syncService.syncFavoritesToHoldings(
            largeFavorites, [], options);

        // Assert
        expect(result.success, isTrue);
        expect(result.addedCount, equals(100));
        expect(result.totalCount, equals(100));
      });
    });
  });
}
