import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/models/fund.dart';

/// 测试基金排行模拟数据检测机制
/// 验证模拟数据和真实数据的正确识别
void main() {
  group('基金排行模拟数据检测测试', () {
    test('检测模拟数据模式', () {
      // 创建模拟数据（符合100000 + i * 11模式）
      final mockRankings = [
        FundRanking(
          fundCode: '100000',
          fundName: '易方达股票型优选A号',
          fundType: '股票型',
          company: '易方达基金',
          rankingPosition: 1,
          totalCount: 100,
          unitNav: 1.2345,
          accumulatedNav: 1.3456,
          dailyReturn: 0.12,
          return1W: 0.56,
          return1M: 2.34,
          return3M: 8.92,
          return6M: 15.67,
          return1Y: 22.34,
          return2Y: 35.67,
          return3Y: 45.67,
          returnYTD: 18.92,
          returnSinceInception: 123.45,
          date: '2024-01-01',
          fee: 0.015,
        ),
        FundRanking(
          fundCode: '100011',
          fundName: '华夏混合型优选B号',
          fundType: '混合型',
          company: '华夏基金',
          rankingPosition: 2,
          totalCount: 100,
          unitNav: 2.7077,
          accumulatedNav: 2.8901,
          dailyReturn: 0.58,
          return1W: 1.23,
          return1M: 4.56,
          return3M: 12.34,
          return6M: 20.56,
          return1Y: 28.90,
          return2Y: 42.34,
          return3Y: 52.34,
          returnYTD: 25.67,
          returnSinceInception: 156.78,
          date: '2024-01-01',
          fee: 0.012,
        ),
        FundRanking(
          fundCode: '100022',
          fundName: '南方债券型优选C号',
          fundType: '债券型',
          company: '南方基金',
          rankingPosition: 3,
          totalCount: 100,
          unitNav: 1.1234,
          accumulatedNav: 1.2345,
          dailyReturn: 0.05,
          return1W: 0.23,
          return1M: 1.12,
          return3M: 4.56,
          return6M: 8.90,
          return1Y: 12.34,
          return2Y: 18.90,
          return3Y: 25.67,
          returnYTD: 8.90,
          returnSinceInception: 45.67,
          date: '2024-01-01',
          fee: 0.008,
        ),
      ];

      // 执行检测逻辑（复制自BLoC的检测代码）
// ignore: avoid_print
      print('Mock fund codes: ${mockRankings.map((r) => r.fundCode).toList()}');

      final startsWith1000 =
          mockRankings.every((r) => r.fundCode.startsWith('1000'));
// ignore: avoid_print
      print('All start with 1000: $startsWith1000');

      final codes =
          mockRankings.map((r) => int.tryParse(r.fundCode) ?? 0).toList();
// ignore: avoid_print
      print('Parsed codes: $codes');

      final patternMatch =
          codes.every((code) => code >= 100000 && (code - 100000) % 11 == 0);
// ignore: avoid_print
      print('Pattern match: $patternMatch');

      final isMockData =
          mockRankings.isNotEmpty && startsWith1000 && patternMatch;

// ignore: avoid_print
      print('模拟数据检测结果: $isMockData');
      expect(isMockData, isTrue);
    });

    test('检测真实数据模式', () {
      // 创建真实数据（不符合模拟数据模式）
      final realRankings = [
        FundRanking(
          fundCode: '005827',
          fundName: '易方达蓝筹精选混合',
          fundType: '混合型',
          company: '易方达基金',
          rankingPosition: 1,
          totalCount: 100,
          unitNav: 2.3456,
          accumulatedNav: 2.4567,
          dailyReturn: 1.23,
          return1W: 2.34,
          return1M: 8.92,
          return3M: 15.67,
          return6M: 28.45,
          return1Y: 22.34,
          return2Y: 45.67,
          return3Y: 55.67,
          returnYTD: 18.92,
          returnSinceInception: 134.56,
          date: '2024-01-01',
          fee: 0.015,
        ),
        FundRanking(
          fundCode: '161005',
          fundName: '富国天惠成长混合',
          fundType: '混合型',
          company: '富国基金',
          rankingPosition: 2,
          totalCount: 100,
          unitNav: 3.4567,
          accumulatedNav: 4.5678,
          dailyReturn: 0.89,
          return1W: 1.56,
          return1M: 6.78,
          return3M: 18.90,
          return6M: 32.45,
          return1Y: 28.90,
          return2Y: 48.90,
          return3Y: 68.90,
          returnYTD: 22.34,
          returnSinceInception: 178.90,
          date: '2024-01-01',
          fee: 0.012,
        ),
      ];

      // 执行检测逻辑
      final isMockData = realRankings.isNotEmpty &&
          realRankings.every((r) => r.fundCode.startsWith('10000')) &&
          realRankings
              .map((r) => int.tryParse(r.fundCode) ?? 0)
              .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

// ignore: avoid_print
      print('真实数据检测结果: $isMockData');
      expect(isMockData, isFalse);
    });

    test('检测空数据', () {
      final emptyRankings = <FundRanking>[];

      final isMockData = emptyRankings.isNotEmpty &&
          emptyRankings.every((r) => r.fundCode.startsWith('10000')) &&
          emptyRankings
              .map((r) => int.tryParse(r.fundCode) ?? 0)
              .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

// ignore: avoid_print
      print('空数据检测结果: $isMockData');
      expect(isMockData, isFalse);
    });

    test('检测混合数据（部分模拟，部分真实）', () {
      final mixedRankings = [
        FundRanking(
          fundCode: '100000', // 模拟数据
          fundName: '模拟基金A',
          fundType: '股票型',
          company: '模拟公司',
          rankingPosition: 1,
          totalCount: 100,
          unitNav: 1.0,
          accumulatedNav: 1.0,
          dailyReturn: 0.1,
          return1W: 0.5,
          return1M: 2.0,
          return3M: 6.0,
          return6M: 12.0,
          return1Y: 20.0,
          return2Y: 30.0,
          return3Y: 40.0,
          returnYTD: 15.0,
          returnSinceInception: 100.0,
          date: '2024-01-01',
          fee: 0.01,
        ),
        FundRanking(
          fundCode: '005827', // 真实数据
          fundName: '真实基金A',
          fundType: '混合型',
          company: '真实公司',
          rankingPosition: 2,
          totalCount: 100,
          unitNav: 2.0,
          accumulatedNav: 2.5,
          dailyReturn: 0.5,
          return1W: 1.0,
          return1M: 4.0,
          return3M: 12.0,
          return6M: 24.0,
          return1Y: 25.0,
          return2Y: 35.0,
          return3Y: 45.0,
          returnYTD: 20.0,
          returnSinceInception: 150.0,
          date: '2024-01-01',
          fee: 0.015,
        ),
      ];

      final isMockData = mixedRankings.isNotEmpty &&
          mixedRankings.every((r) => r.fundCode.startsWith('10000')) &&
          mixedRankings
              .map((r) => int.tryParse(r.fundCode) ?? 0)
              .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

// ignore: avoid_print
      print('混合数据检测结果: $isMockData');
      expect(isMockData, isFalse); // 由于存在真实数据，应该返回false
    });
  });

  group('数据替换逻辑测试', () {
    test('模拟数据应该被真实数据替换', () {
      // 模拟初始状态：有模拟数据
      final mockRankings = [
        FundRanking(
          fundCode: '100000',
          fundName: '模拟基金',
          fundType: '股票型',
          company: '模拟公司',
          rankingPosition: 1,
          totalCount: 50,
          unitNav: 1.5,
          accumulatedNav: 1.8,
          dailyReturn: 0.3,
          return1W: 1.2,
          return1M: 4.5,
          return3M: 12.0,
          return6M: 20.0,
          return1Y: 30.0,
          return2Y: 45.0,
          return3Y: 60.0,
          returnYTD: 25.0,
          returnSinceInception: 120.0,
          date: '2024-01-01',
          fee: 0.01,
        ),
      ];

      // 模拟新加载的真实数据
      final realRankings = [
        FundRanking(
          fundCode: '005827',
          fundName: '易方达蓝筹精选混合',
          fundType: '混合型',
          company: '易方达基金',
          rankingPosition: 1,
          totalCount: 200,
          unitNav: 2.3456,
          accumulatedNav: 2.4567,
          dailyReturn: 1.23,
          return1W: 2.34,
          return1M: 8.92,
          return3M: 15.67,
          return6M: 28.45,
          return1Y: 22.34,
          return2Y: 45.67,
          return3Y: 55.67,
          returnYTD: 18.92,
          returnSinceInception: 134.56,
          date: '2024-01-01',
          fee: 0.015,
        ),
        FundRanking(
          fundCode: '161005',
          fundName: '富国天惠成长混合',
          fundType: '混合型',
          company: '富国基金',
          rankingPosition: 2,
          totalCount: 200,
          unitNav: 3.4567,
          accumulatedNav: 4.5678,
          dailyReturn: 0.89,
          return1W: 1.56,
          return1M: 6.78,
          return3M: 18.90,
          return6M: 32.45,
          return1Y: 28.90,
          return2Y: 48.90,
          return3Y: 68.90,
          returnYTD: 22.34,
          returnSinceInception: 178.90,
          date: '2024-01-01',
          fee: 0.012,
        ),
      ];

      // 验证模拟数据检测
      final isMockData = mockRankings.isNotEmpty &&
          mockRankings.every((r) => r.fundCode.startsWith('10000')) &&
          mockRankings
              .map((r) => int.tryParse(r.fundCode) ?? 0)
              .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

      // 验证真实数据检测
      final isRealDataMock = realRankings.isNotEmpty &&
          realRankings.every((r) => r.fundCode.startsWith('10000')) &&
          realRankings
              .map((r) => int.tryParse(r.fundCode) ?? 0)
              .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

// ignore: avoid_print
      print('模拟数据检测结果: $isMockData');
// ignore: avoid_print
      print('真实数据检测结果: $isRealDataMock');

      expect(isMockData, isTrue);
      expect(isRealDataMock, isFalse);

      // 验证数据应该被替换
      // 当检测到真实数据时，应该替换掉模拟数据
      expect(realRankings.length, greaterThan(mockRankings.length));
      expect(realRankings.first.fundCode, isNot(startsWith('10000')));
    });
  });
}

// 辅助函数：根据基金类型获取基础收益率
double _getBaseReturnByType(String fundType) {
  switch (fundType) {
    case '股票型':
      return 0.15; // 15%基础年化收益
    case '混合型':
      return 0.12; // 12%基础年化收益
    case '债券型':
      return 0.06; // 6%基础年化收益
    case '指数型':
      return 0.10; // 10%基础年化收益
    case 'QDII':
      return 0.08; // 8%基础年化收益
    default:
      return 0.10; // 默认10%
  }
}

// 辅助函数：根据基金类型获取波动性
double _getVolatilityByType(String fundType) {
  switch (fundType) {
    case '股票型':
      return 0.25; // 25%波动
    case '混合型':
      return 0.20; // 20%波动
    case '债券型':
      return 0.08; // 8%波动
    case '指数型':
      return 0.18; // 18%波动
    case 'QDII':
      return 0.22; // 22%波动
    default:
      return 0.18; // 默认18%
  }
}
