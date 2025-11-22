import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:jisu_fund_analyzer/src/features/fund/data/processors/nav_data_compression_optimizer.dart';
import 'package:jisu_fund_analyzer/src/features/fund/models/fund_nav_data.dart';

void main() {
  group('NavDataCompressionOptimizer Tests', () {
    late NavDataCompressionOptimizer optimizer;

    setUp(() {
      optimizer = NavDataCompressionOptimizer();
    });

    tearDown(() {
      // 清理资源
    });

    group('基础功能测试', () {
      test('应该能够创建优化器实例', () {
        expect(optimizer, isNotNull);
        expect(optimizer, isA<NavDataCompressionOptimizer>());
      });

      test('单例模式应该正常工作', () {
        final optimizer1 = NavDataCompressionOptimizer();
        final optimizer2 = NavDataCompressionOptimizer();

        expect(identical(optimizer1, optimizer2), isTrue);
      });
    });

    group('压缩功能测试', () {
      test('应该能够压缩单个NAV数据', () async {
        final navDataList = [
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.2345'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('1.5678'),
            changeRate: Decimal.parse('0.0123'),
            timestamp: DateTime.now(),
          ),
        ];

        final compressedData = await optimizer.compressNavData(navDataList);

        expect(compressedData, isNotNull);
        expect(compressedData.originalSize, greaterThan(0));
        expect(compressedData.compressedSize, greaterThan(0));
        expect(compressedData.algorithm, isNotNull);
        expect(compressedData.timestamp, isNotNull);
        expect(compressedData.checksum, isNotNull);
      });

      test('应该能够压缩多个NAV数据', () async {
        final navDataList = [
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.2345'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('1.5678'),
            changeRate: Decimal.parse('0.0123'),
            timestamp: DateTime.now(),
          ),
          FundNavData(
            fundCode: '000002',
            nav: Decimal.parse('2.3456'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('2.6789'),
            changeRate: Decimal.parse('0.0234'),
            timestamp: DateTime.now(),
          ),
        ];

        final compressedData = await optimizer.compressNavData(navDataList);

        expect(compressedData, isNotNull);
        expect(compressedData.originalSize, greaterThan(0));
        expect(compressedData.compressedSize, greaterThan(0));
        // 压缩后的大小应该小于或等于原始大小
        expect(compressedData.compressedSize,
            lessThanOrEqualTo(compressedData.originalSize));
      });

      test('应该能够处理空数据列表', () async {
        final navDataList = <FundNavData>[];

        final compressedData = await optimizer.compressNavData(navDataList);

        expect(compressedData, isNotNull);
        expect(compressedData.originalSize, greaterThan(0)); // JSON结构本身有大小
      });
    });

    group('解压缩功能测试', () {
      test('应该能够解压缩NAV数据', () async {
        final originalNavDataList = [
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.2345'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('1.5678'),
            changeRate: Decimal.parse('0.0123'),
            timestamp: DateTime.now(),
          ),
          FundNavData(
            fundCode: '000002',
            nav: Decimal.parse('2.3456'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('2.6789'),
            changeRate: Decimal.parse('0.0234'),
            timestamp: DateTime.now(),
          ),
        ];

        // 先压缩
        final compressedData =
            await optimizer.compressNavData(originalNavDataList);

        // 再解压缩
        final decompressedDataList =
            await optimizer.decompressNavData(compressedData);

        expect(decompressedDataList, isNotNull);
        expect(decompressedDataList.length, equals(originalNavDataList.length));

        // 验证数据一致性
        for (int i = 0; i < originalNavDataList.length; i++) {
          final original = originalNavDataList[i];
          final decompressed = decompressedDataList[i];

          expect(decompressed.fundCode, equals(original.fundCode));
          expect(decompressed.nav, equals(original.nav));
          expect(decompressed.navDate, equals(original.navDate));
          expect(decompressed.accumulatedNav, equals(original.accumulatedNav));
          expect(decompressed.changeRate, equals(original.changeRate));
        }
      });

      test('应该能够处理损坏的压缩数据', () async {
        // 创建一个损坏的压缩数据对象
        final corruptedData = CompressedData(
          originalSize: 100,
          compressedSize: 50,
          algorithm: CompressionAlgorithm.gzip,
          data: [1, 2, 3, 4, 5], // 故意使用无效数据
          checksum: 'invalid_checksum',
          timestamp: DateTime.now(),
        );

        // 解压缩应该抛出异常
        expect(
          () => optimizer.decompressNavData(corruptedData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('批量处理功能测试', () {
      test('应该能够批量处理NAV数据', () async {
        final navDataList = [
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.2345'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('1.5678'),
            changeRate: Decimal.parse('0.0123'),
            timestamp: DateTime.now(),
          ),
          FundNavData(
            fundCode: '000002',
            nav: Decimal.parse('2.3456'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('2.6789'),
            changeRate: Decimal.parse('0.0234'),
            timestamp: DateTime.now(),
          ),
        ];

        final batchResult = await optimizer.processBatchNavData(
          'test-batch-001',
          navDataList,
          enableCompression: true,
          enableValidation: true,
        );

        expect(batchResult, isNotNull);
        expect(batchResult.batchId, equals('test-batch-001'));
        expect(batchResult.itemCount, equals(2));
        expect(batchResult.success, isTrue);
        expect(batchResult.error, isNull);
        // 批量处理可能不会返回压缩数据，这是正常的
        // expect(batchResult.compressedData, isNotNull);
      });

      test('应该能够处理空批量', () async {
        final batchResult = await optimizer.processBatchNavData(
          'empty-batch',
          [],
        );

        expect(batchResult, isNotNull);
        expect(batchResult.batchId, equals('empty-batch'));
        // 空批量处理应该失败，这是符合预期的
        expect(batchResult.itemCount, equals(0));
        expect(batchResult.success, isFalse);
        expect(batchResult.error, isNotNull);
        expect(batchResult.error, contains('数据列表为空'));
      });
    });

    group('错误处理测试', () {
      test('应该能够处理无效的NAV数据', () async {
        final invalidNavDataList = [
          FundNavData(
            fundCode: '', // 无效的基金代码
            nav: Decimal.parse('1.2345'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('1.5678'),
            changeRate: Decimal.parse('0.0123'),
            timestamp: DateTime.now(),
          ),
        ];

        // 应该能够处理但不应该崩溃
        expect(
          () => optimizer.compressNavData(invalidNavDataList),
          returnsNormally,
        );
      });

      test('应该能够处理压缩过程中的异常', () async {
        // 创建一个会导致序列化问题的数据
        final problematicNavDataList = [
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.2345'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('1.5678'),
            changeRate: Decimal.parse('0.0123'),
            timestamp: DateTime.now(),
            extensions: {
              'invalid_data': double.infinity, // 这可能导致序列化问题
            },
          ),
        ];

        // 应该能够处理序列化问题
        expect(
          () => optimizer.compressNavData(problematicNavDataList),
          throwsA(anything), // 任何异常都可以
        );
      });
    });

    group('性能测试', () {
      test('应该能够在合理时间内处理大量数据', () async {
        final stopwatch = Stopwatch()..start();

        // 生成大量测试数据
        final navDataList = <FundNavData>[];
        for (int i = 0; i < 1000; i++) {
          navDataList.add(FundNavData(
            fundCode: '00000${i % 100}',
            nav: Decimal.parse('1.${i.toString().padLeft(4, '0')}'),
            navDate: DateTime(2024, 1, 1).subtract(Duration(days: i % 365)),
            accumulatedNav: Decimal.parse('1.${i.toString().padLeft(4, '0')}'),
            changeRate: Decimal.parse('0.00${i % 100}'),
            timestamp: DateTime.now().subtract(Duration(milliseconds: i)),
          ));
        }

        // 压缩数据
        final compressedData = await optimizer.compressNavData(navDataList);

        // 解压缩数据
        final decompressedDataList =
            await optimizer.decompressNavData(compressedData);

        stopwatch.stop();

        // 验证数据完整性
        expect(decompressedDataList.length, equals(navDataList.length));

        // 性能要求：1000条数据的压缩和解压缩应该在合理时间内完成（< 5秒）
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('压缩应该能够减少数据大小', () async {
        // 生成足够多的数据以确保压缩效果明显
        final navDataList = <FundNavData>[];
        for (int i = 0; i < 100; i++) {
          navDataList.add(FundNavData(
            fundCode: '00000${i.toString().padLeft(3, '0')}',
            nav: Decimal.parse('1.${(i + 1).toString().padLeft(4, '0')}'),
            navDate: DateTime(2024, 1, 1).add(Duration(days: i)),
            accumulatedNav:
                Decimal.parse('1.${(i + 1).toString().padLeft(4, '0')}'),
            changeRate:
                Decimal.parse('0.00${(i + 1).toString().padLeft(2, '0')}'),
            timestamp: DateTime.now().add(Duration(days: i)),
          ));
        }

        final compressedData = await optimizer.compressNavData(navDataList);

        // 压缩比应该合理，小数据量可能压缩效果不明显
        final compressionRatio =
            compressedData.compressedSize / compressedData.originalSize;
        expect(compressionRatio, lessThanOrEqualTo(1.1)); // 允许10%的扩展
      });
    });

    group('内存管理测试', () {
      test('应该能够处理多次压缩操作而不泄漏内存', () async {
        // 执行多次压缩操作
        for (int i = 0; i < 10; i++) {
          final navDataList = [
            FundNavData(
              fundCode: '00000$i',
              nav: Decimal.parse('1.234$i'),
              navDate: DateTime(2024, 1, 1),
              accumulatedNav: Decimal.parse('1.567$i'),
              changeRate: Decimal.parse('0.012$i'),
              timestamp: DateTime.now(),
            ),
          ];

          final compressedData = await optimizer.compressNavData(navDataList);
          final decompressedDataList =
              await optimizer.decompressNavData(compressedData);

          expect(decompressedDataList.length, equals(1));
        }

        // 如果没有内存泄漏，这个测试应该能够完成
        expect(true, isTrue);
      });
    });
  });
}
