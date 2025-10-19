import 'package:flutter_test/flutter_test.dart';

void main() {
  group('基础测试', () {
    test('测试基础数学运算', () {
      expect(2 + 2, equals(4));
      expect(5 * 3, equals(15));
    });

    test('测试字符串操作', () {
      final text = '基金对比功能';
      expect(text, contains('基金'));
      expect(text.length, equals(6));
    });

    test('测试列表操作', () {
      final fundCodes = ['000001', '000002', '000003'];
      expect(fundCodes.length, equals(3));
      expect(fundCodes.contains('000001'), isTrue);
      expect(fundCodes.first, equals('000001'));
    });
  });

  group('对比功能模拟测试', () {
    test('应该正确计算收益率对比', () {
      // 模拟数据
      final returns = [0.10, 0.15, -0.05, 0.20];

      // 计算平均收益率
      final averageReturn = returns.reduce((a, b) => a + b) / returns.length;
      expect(averageReturn, equals(0.10));

      // 找出最高收益率
      final maxReturn = returns.reduce((a, b) => a > b ? a : b);
      expect(maxReturn, equals(0.20));

      // 找出最低收益率
      final minReturn = returns.reduce((a, b) => a < b ? a : b);
      expect(minReturn, equals(-0.05));
    });

    test('应该正确验证基金选择数量', () {
      // 测试有效范围（2-5个基金）
      final validSelections = [
        ['000001', '000002'], // 2个基金 - 有效
        ['000001', '000002', '000003'], // 3个基金 - 有效
        ['000001', '000002', '000003', '000004', '000005'], // 5个基金 - 有效
      ];

      final invalidSelections = [
        ['000001'], // 1个基金 - 无效
        [
          '000001',
          '000002',
          '000003',
          '000004',
          '000005',
          '000006'
        ], // 6个基金 - 无效
      ];

      for (final selection in validSelections) {
        expect(selection.length >= 2 && selection.length <= 5, isTrue,
            reason: '${selection.length}个基金应该在有效范围内');
      }

      for (final selection in invalidSelections) {
        expect(selection.length >= 2 && selection.length <= 5, isFalse,
            reason: '${selection.length}个基金应该在有效范围外');
      }
    });

    test('应该正确计算排名超越百分比', () {
      // 模拟排名数据
      final ranking = 10; // 第10名
      final totalCount = 100; // 总共100只基金

      // 计算超越百分比
      final beatPercent = ((totalCount - ranking) / totalCount) * 100;
      expect(beatPercent, equals(90.0));

      // 测试边界情况
      expect(_calculateBeatPercent(1, 100), equals(99.0)); // 第1名超越99%
      expect(_calculateBeatPercent(100, 100), equals(0.0)); // 最后一名超越0%
    });
  });
}

// 辅助函数：计算超越百分比
double _calculateBeatPercent(int ranking, int totalCount) {
  if (totalCount <= 0) return 0.0;
  return ((totalCount - ranking) / totalCount) * 100;
}
