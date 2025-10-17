import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/data/services/fund_service.dart';

/// 测试基金排行降级机制
/// 验证当API返回500错误时，是否能正确降级到模拟数据
void main() {
  group('基金排行降级机制测试', () {
    late FundService fundService;

    setUp(() {
      fundService = FundService();
    });

    test('测试API 500错误时的降级机制', () async {
// ignore: avoid_print
      print('🔄 开始测试基金排行降级机制...');

      try {
        // 调用基金排行接口（当前API会返回500错误）
        final rankings = await fundService.getFundRankings(
          symbol: '全部',
          pageSize: 20,
          timeout: const Duration(seconds: 30),
        );

// ignore: avoid_print
        print('✅ 基金排行数据获取成功！');
// ignore: avoid_print
        print('📊 获取到 ${rankings.length} 条基金排行数据');

        // 验证返回的数据不为空
        expect(rankings.isNotEmpty, isTrue);

        // 验证数据格式正确
        if (rankings.isNotEmpty) {
          final firstRanking = rankings.first;
// ignore: avoid_print
          print('🔍 第一条数据样本:');
// ignore: avoid_print
          print('  基金代码: ${firstRanking.fundCode}');
// ignore: avoid_print
          print('  基金简称: ${firstRanking.fundName}');
// ignore: avoid_print
          print('  基金类型: ${firstRanking.fundType}');
// ignore: avoid_print
          print('  单位净值: ${firstRanking.unitNav}');
// ignore: avoid_print
          print('  日增长率: ${firstRanking.dailyReturn}%');

          // 验证关键字段不为空
          expect(firstRanking.fundCode.isNotEmpty, isTrue);
          expect(firstRanking.fundName.isNotEmpty, isTrue);
          expect(firstRanking.fundType.isNotEmpty, isTrue);
        }

// ignore: avoid_print
        print('✅ 降级机制测试通过！');
      } catch (e) {
// ignore: avoid_print
        print('❌ 测试失败: $e');
        fail('降级机制应该生效，不应该抛出异常: $e');
      }
    });

    test('测试不同基金类型的降级数据', () async {
// ignore: avoid_print
      print('🔄 测试不同基金类型的降级数据...');

      final fundTypes = ['全部', '股票型', '混合型', '债券型', '指数型'];

      for (final fundType in fundTypes) {
// ignore: avoid_print
        print('📋 测试基金类型: $fundType');

        try {
          final rankings = await fundService.getFundRankings(
            symbol: fundType,
            pageSize: 10,
            timeout: const Duration(seconds: 20),
          );

// ignore: avoid_print
          print('✅ $fundType 类型获取成功，共 ${rankings.length} 条数据');
          expect(rankings.isNotEmpty, isTrue);

          // 验证数据类型匹配
          for (final ranking in rankings.take(3)) {
            if (fundType != '全部') {
              expect(ranking.fundType, contains(fundType));
            }
          }
        } catch (e) {
          fail('$fundType 类型测试失败: $e');
        }
      }

// ignore: avoid_print
      print('✅ 所有基金类型降级测试通过！');
    });

    test('测试分页加载降级机制', () async {
// ignore: avoid_print
      print('🔄 测试分页加载降级机制...');

      try {
        // 测试第1页
        final page1 = await fundService.getFundRankings(
          symbol: '全部',
          pageSize: 20,
          timeout: const Duration(seconds: 20),
        );

// ignore: avoid_print
        print('✅ 第1页获取成功，共 ${page1.length} 条数据');
        expect(page1.length, greaterThanOrEqualTo(1));

        // 测试第2页（注意：当前API不支持分页，所以会返回相同的数据）
        final page2 = await fundService.getFundRankings(
          symbol: '全部',
          pageSize: 20,
          timeout: const Duration(seconds: 20),
        );

// ignore: avoid_print
        print('✅ 第2页获取成功，共 ${page2.length} 条数据');
        expect(page2.length, greaterThanOrEqualTo(1));

// ignore: avoid_print
        print('✅ 分页加载降级测试通过！');
      } catch (e) {
        fail('分页加载测试失败: $e');
      }
    });
  });
}
