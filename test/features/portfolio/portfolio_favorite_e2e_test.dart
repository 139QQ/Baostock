import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/favorite_to_holding_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/portfolio_favorite_sync_service.dart';
import 'test_data_generator.dart';

/// 自选基金与持仓分析端到端测试
///
/// 测试完整的用户操作流程：
/// 1. 用户添加自选基金
/// 2. 用户执行单个建仓操作
/// 3. 用户执行批量导入操作
/// 4. 系统执行数据同步
/// 5. 用户查看同步结果
void main() {
  group('Portfolio Favorite E2E Tests', () {
    late FavoriteToHoldingService converter;
    late PortfolioFavoriteSyncService syncService;
    // TestDataGenerator 只包含静态方法，无需实例

    setUp(() {
      converter = FavoriteToHoldingService();
      syncService = PortfolioFavoriteSyncService();
    });

    group('完整用户流程测试', () {
      test('场景1: 用户从零开始建立完整投资组合', () async {
        // Arrange: 准备测试数据
        final testFavorites = TestDataGenerator.generateFavorites(5);
        const syncOptions = SyncOptions(
          defaultAmount: 1000.0,
          useCurrentNavAsCost: true,
          keepExistingHoldings: true,
        );

        // Act & Assert: 步骤1 - 用户添加自选基金
        _logStep('步骤1: 用户添加5只自选基金');
        expect(testFavorites.length, equals(5));
        expect(testFavorites.every((f) => f.fundCode.isNotEmpty), isTrue);
        expect(testFavorites.every((f) => f.fundName.isNotEmpty), isTrue);
        _logSuccess('✅ 自选基金添加成功');

        // Act & Assert: 步骤2 - 用户执行单个建仓
        _logStep('步骤2: 用户对第一只基金执行单个建仓');
        final firstFavorite = testFavorites.first;
        final singleHolding = converter.convertFavoriteToHolding(
          firstFavorite,
          defaultAmount: 1500.0,
          estimateCost: true,
        );

        expect(singleHolding.fundCode, equals(firstFavorite.fundCode));
        expect(singleHolding.fundName, equals(firstFavorite.fundName));
        expect(singleHolding.holdingAmount, equals(1500.0));
        expect(singleHolding.costNav, equals(firstFavorite.currentNav));
        _logSuccess('✅ 单个建仓操作成功');

        // Act & Assert: 步骤3 - 用户执行批量导入
        _logStep('步骤3: 用户批量导入剩余自选基金');
        final remainingFavorites = testFavorites.skip(1).toList();
        final initialHoldings = [singleHolding];

        final syncResult = await syncService.syncFavoritesToHoldings(
          remainingFavorites,
          initialHoldings,
          syncOptions,
        );

        expect(syncResult.success, isTrue);
        expect(syncResult.addedCount, equals(4)); // 剩余4只基金
        expect(syncResult.updatedCount, equals(1)); // 第一只基金可能更新
        expect(syncResult.totalCount, equals(5)); // 总计5只持仓
        _logSuccess('✅ 批量导入操作成功');

        // Act & Assert: 步骤4 - 验证数据一致性
        _logStep('步骤4: 验证数据一致性');
        final finalHoldings = syncResult.updatedHoldings;
        final consistencyReport =
            syncService.checkConsistency(testFavorites, finalHoldings);

        expect(consistencyReport.commonCount, equals(5)); // 所有5只基金都应该同步
        expect(consistencyReport.onlyInFavorites, isEmpty); // 自选中没有遗漏
        expect(consistencyReport.inconsistencies, isEmpty); // 数据一致
        _logSuccess('✅ 数据一致性验证通过');

        // Act & Assert: 步骤5 - 验证业务逻辑
        _logStep('步骤5: 验证业务逻辑正确性');
        final totalCostValue =
            finalHoldings.fold<double>(0, (sum, h) => sum + h.costValue);
        final totalMarketValue =
            finalHoldings.fold<double>(0, (sum, h) => sum + h.marketValue);

        expect(totalCostValue, greaterThan(0));
        expect(totalMarketValue, greaterThan(0));

        // 计算总收益
        final totalProfit = totalMarketValue - totalCostValue;
        final profitRate = (totalProfit / totalCostValue) * 100;

        expect(totalProfit, isA<double>()); // 可能盈利也可能亏损
        _logSuccess(
            '✅ 业务逻辑验证完成，总收益: ${totalProfit.toStringAsFixed(2)} (${profitRate.toStringAsFixed(2)}%)');

        _logStep('完整流程测试通过');
      });

      test('场景2: 用户处理数据冲突和不一致', () async {
        // Arrange: 创建有数据冲突的测试场景
        final baseFavorites = TestDataGenerator.generateFavorites(3);
        final conflictingHoldings = baseFavorites
            .map((f) => PortfolioHolding(
                  fundCode: f.fundCode,
                  fundName: '${f.fundName}(旧版本)', // 名称不匹配
                  fundType: f.fundType,
                  holdingAmount: 1000.0,
                  costNav: f.currentNav! * 0.95, // 成本净值不匹配
                  costValue: 950.0,
                  marketValue: 1000.0,
                  currentNav: f.currentNav! * 1.05, // 当前净值不匹配
                  accumulatedNav: f.currentNav! * 1.10,
                  holdingStartDate:
                      DateTime.now().subtract(const Duration(days: 30)),
                  lastUpdatedDate: DateTime.now(),
                  dividendReinvestment: false,
                  status: HoldingStatus.active,
                ))
            .toList();

        // Act & Assert: 步骤1 - 检测数据不一致
        _logStep('步骤1: 检测数据不一致');
        final initialReport =
            syncService.checkConsistency(baseFavorites, conflictingHoldings);

        expect(initialReport.isConsistent, isFalse);
        expect(initialReport.inconsistencies.length, equals(3)); // 3只基金都有不一致
        expect(
            initialReport.inconsistencies
                .any((i) => i.type == InconsistencyType.basicInfoMismatch),
            isTrue);
        expect(
            initialReport.inconsistencies
                .any((i) => i.type == InconsistencyType.navValueMismatch),
            isTrue);
        _logSuccess('✅ 成功检测到数据不一致');

        // Act & Assert: 步骤2 - 执行同步操作
        _logStep('步骤2: 执行同步操作修复不一致');
        const syncOptions = SyncOptions(
          defaultAmount: 1000.0,
          useCurrentNavAsCost: true,
          keepExistingHoldings: true,
          updateBasicInfo: true,
          updateNavData: true,
        );

        final syncResult = await syncService.syncFavoritesToHoldings(
          baseFavorites,
          conflictingHoldings,
          syncOptions,
        );

        expect(syncResult.success, isTrue);
        expect(syncResult.updatedCount, equals(3)); // 3只基金都更新
        _logSuccess('✅ 同步操作成功修复不一致');

        // Act & Assert: 步骤3 - 验证修复结果
        _logStep('步骤3: 验证修复结果');
        final finalReport = syncService.checkConsistency(
            baseFavorites, syncResult.updatedHoldings);

        expect(finalReport.isConsistent, isTrue);
        expect(finalReport.inconsistencies, isEmpty);
        _logSuccess('✅ 数据不一致已完全修复');

        _logStep('数据冲突处理流程测试通过');
      });

      test('场景3: 大规模数据同步性能测试', () async {
        // Arrange: 生成大量测试数据
        _logStep('步骤1: 生成大规模测试数据');
        final largeFavorites = TestDataGenerator.generateFavorites(100);
        final largeHoldings = TestDataGenerator.generateHoldings(50);

        expect(largeFavorites.length, equals(100));
        expect(largeHoldings.length, equals(50));
        _logSuccess('✅ 大规模数据生成完成');

        // Act & Assert: 步骤2 - 执行性能测试
        _logStep('步骤2: 执行大规模数据同步');
        final startTime = DateTime.now();

        const syncOptions = SyncOptions(
          defaultAmount: 1000.0,
          useCurrentNavAsCost: true,
          keepExistingHoldings: true,
        );

        final syncResult = await syncService.syncFavoritesToHoldings(
          largeFavorites,
          largeHoldings,
          syncOptions,
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(syncResult.success, isTrue);
        expect(syncResult.addedCount, equals(50)); // 50只新基金
        expect(syncResult.updatedCount, equals(0)); // 0只更新
        expect(syncResult.totalCount, equals(150)); // 总计150只持仓
        expect(duration.inMilliseconds, lessThan(5000)); // 应该在5秒内完成
        _logSuccess('✅ 大规模同步完成，耗时: ${duration.inMilliseconds}ms');

        // Act & Assert: 步骤3 - 验证数据完整性
        _logStep('步骤3: 验证大规模数据完整性');
        final consistencyReport = syncService.checkConsistency(
            largeFavorites, syncResult.updatedHoldings);

        expect(consistencyReport.commonCount, equals(50)); // 50只共同基金
        expect(
            consistencyReport.onlyInFavorites.length, equals(50)); // 50只仅在自选中
        expect(consistencyReport.onlyInHoldings, isEmpty); // 没有仅在持仓中的基金
        _logSuccess('✅ 大规模数据完整性验证通过');

        _logStep('大规模性能测试通过');
      });

      test('场景4: 边界条件和异常处理', () async {
        _logStep('边界条件和异常处理测试');

        // 测试空数据处理
        _logStep('测试1: 处理空数据');
        const emptySyncOptions = SyncOptions();
        final emptyResult =
            await syncService.syncFavoritesToHoldings([], [], emptySyncOptions);

        expect(emptyResult.success, isTrue);
        expect(emptyResult.totalCount, equals(0));
        _logSuccess('✅ 空数据处理正确');

        // 测试单条数据处理
        _logStep('测试2: 处理单条数据');
        final singleFavorite = TestDataGenerator.generateFavorites(1);
        final singleResult = await syncService.syncFavoritesToHoldings(
          singleFavorite,
          [],
          emptySyncOptions,
        );

        expect(singleResult.success, isTrue);
        expect(singleResult.addedCount, equals(1));
        expect(singleResult.totalCount, equals(1));
        _logSuccess('✅ 单条数据处理正确');

        // 测试无效数据处理
        _logStep('测试3: 处理无效数据');
        const invalidOptions = SyncOptions(defaultAmount: -100.0);
        final validationResult = syncService.validateSyncOperation(
          singleFavorite,
          [],
          invalidOptions,
        );

        expect(validationResult.isValid, isFalse);
        expect(validationResult.canProceed, isFalse);
        expect(
            validationResult.issues
                .any((i) => i.type == ValidationIssueType.invalidAmount),
            isTrue);
        _logSuccess('✅ 无效数据验证正确');

        // 测试数据重复处理
        _logStep('测试4: 处理重复数据');
        final duplicateFavorites = [
          TestDataGenerator.generateFavorite(fundCode: '000001'),
          TestDataGenerator.generateFavorite(fundCode: '000001'), // 重复代码
        ];

        final duplicateValidation = syncService.validateSyncOperation(
          duplicateFavorites,
          [],
          const SyncOptions(),
        );

        expect(duplicateValidation.isValid, isFalse);
        expect(
            duplicateValidation.issues
                .any((i) => i.type == ValidationIssueType.duplicateData),
            isTrue);
        _logSuccess('✅ 重复数据检测正确');

        _logStep('边界条件和异常处理测试通过');
      });

      test('场景5: 用户体验流程完整性测试', () async {
        _logStep('用户体验流程完整性测试');

        // 模拟完整的用户体验流程
        final userJourneySteps = <String>[];

        // 步骤1: 用户浏览并添加自选基金
        userJourneySteps.add('用户浏览基金列表');
        final userFavorites = TestDataGenerator.generateFavorites(8);
        userJourneySteps.add('用户添加了${userFavorites.length}只基金到自选');

        // 步骤2: 用户设置默认参数
        userJourneySteps.add('用户设置默认持有份额为2000份');
        userJourneySteps.add('用户选择使用当前净值作为成本');

        // 步骤3: 用户选择部分基金进行建仓
        userJourneySteps.add('用户选择5只基金进行建仓');
        final selectedFavorites = userFavorites.take(5).toList();
        const userOptions = SyncOptions(
          defaultAmount: 2000.0,
          useCurrentNavAsCost: true,
          keepExistingHoldings: true,
        );

        // 步骤4: 用户执行建仓操作
        userJourneySteps.add('用户点击批量建仓按钮');
        final buildResult = await syncService.syncFavoritesToHoldings(
          selectedFavorites,
          [],
          userOptions,
        );

        userJourneySteps.add('系统成功建仓${buildResult.addedCount}只基金');

        // 步骤5: 用户查看建仓结果
        userJourneySteps.add('用户查看建仓结果');
        expect(buildResult.success, isTrue);
        expect(buildResult.addedCount, equals(5));

        // 步骤6: 用户验证数据
        userJourneySteps.add('用户验证数据一致性');
        final consistencyCheck = syncService.checkConsistency(
            selectedFavorites, buildResult.updatedHoldings);
        expect(consistencyCheck.isConsistent, isTrue);

        // 步骤7: 用户查看投资组合概览
        userJourneySteps.add('用户查看投资组合概览');
        final totalInvestment = buildResult.updatedHoldings
            .fold<double>(0, (sum, h) => sum + h.costValue);
        final totalValue = buildResult.updatedHoldings
            .fold<double>(0, (sum, h) => sum + h.marketValue);
        final profit = totalValue - totalInvestment;

        userJourneySteps.add('总投资: ¥${totalInvestment.toStringAsFixed(2)}');
        userJourneySteps.add('当前市值: ¥${totalValue.toStringAsFixed(2)}');
        userJourneySteps.add('浮动盈亏: ¥${profit.toStringAsFixed(2)}');

        // 验证用户体验流程的完整性
        expect(userJourneySteps.length, equals(11));
        expect(userJourneySteps.any((step) => step.contains('成功')), isTrue);

        // 输出用户体验流程报告
        _logStep('用户体验流程完整性验证');
        for (int i = 0; i < userJourneySteps.length; i++) {
          _logInfo('  ${i + 1}. ${userJourneySteps[i]}');
        }
        _logSuccess('✅ 用户体验流程完整性测试通过');

        _logStep('用户体验流程测试完成');
      });
    });

    group('回归测试场景', () {
      test('回归1: 核心功能回归测试', () async {
        _logStep('核心功能回归测试');

        // 测试数据转换核心功能
        final favorite = TestDataGenerator.generateFavorite();
        final holding = converter.convertFavoriteToHolding(favorite);

        expect(holding.fundCode, equals(favorite.fundCode));
        expect(holding.fundName, equals(favorite.fundName));
        expect(holding.holdingAmount, equals(1000.0)); // 默认值
        _logSuccess('✅ 数据转换功能正常');

        // 测试同步核心功能
        final syncResult = await syncService.syncFavoritesToHoldings(
          [favorite],
          [],
          const SyncOptions(),
        );

        expect(syncResult.success, isTrue);
        expect(syncResult.addedCount, equals(1));
        _logSuccess('✅ 数据同步功能正常');

        // 测试一致性检查核心功能
        final report = syncService.checkConsistency([favorite], [holding]);
        expect(report.commonCount, equals(1));
        _logSuccess('✅ 一致性检查功能正常');

        _logStep('核心功能回归测试通过');
      });

      test('回归2: 性能回归测试', () async {
        _logStep('性能回归测试');

        // 测试小规模数据性能
        final smallFavorites = TestDataGenerator.generateFavorites(10);
        final smallStart = DateTime.now();

        final smallResult = await syncService.syncFavoritesToHoldings(
          smallFavorites,
          [],
          const SyncOptions(),
        );

        final smallDuration = DateTime.now().difference(smallStart);
        expect(smallDuration.inMilliseconds, lessThan(1000));
        expect(smallResult.success, isTrue);

        // 测试中等规模数据性能
        final mediumFavorites = TestDataGenerator.generateFavorites(50);
        final mediumStart = DateTime.now();

        final mediumResult = await syncService.syncFavoritesToHoldings(
          mediumFavorites,
          [],
          const SyncOptions(),
        );

        final mediumDuration = DateTime.now().difference(mediumStart);
        expect(mediumDuration.inMilliseconds, lessThan(3000));
        expect(mediumResult.success, isTrue);

        _logSuccess('✅ 性能回归测试通过');
        _logInfo('  小规模(10): ${smallDuration.inMilliseconds}ms');
        _logInfo('  中规模(50): ${mediumDuration.inMilliseconds}ms');

        _logStep('性能回归测试通过');
      });
    });
  });
}

// 辅助日志方法
void _logStep(String message) {
  print('📋 $message');
}

void _logSuccess(String message) {
  print('✅ $message');
}

void _logInfo(String message) {
  print('ℹ️  $message');
}
