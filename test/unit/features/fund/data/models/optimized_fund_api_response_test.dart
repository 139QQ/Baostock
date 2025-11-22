import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/data/models/optimized_fund_api_response.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';

void main() {
  group('OptimizedFundApiResponse Tests', () {
    late List<Map<String, dynamic>> mockApiData;
    late List<Map<String, dynamic>> emptyApiData;
    late List<Map<String, dynamic>> invalidApiData;

    setUp(() {
      // 模拟真实API数据
      mockApiData = [
        {
          '基金代码': '009209',
          '基金简称': '易方达优质精选混合',
          '基金类型': '混合型',
          '基金公司': '易方达基金管理有限公司',
          '单位净值': '1.2345',
          '累计净值': '2.5678',
          '日增长率': '2.34%',
          '近1周': '1.23%',
          '近1月': '3.45%',
          '近3月': '5.67%',
          '近6月': '8.90%',
          '近1年': '12.34%',
          '近2年': '23.45%',
          '近3年': '34.56%',
          '今年来': '15.67%',
          '成立来': '134.56%',
          '手续费': '1.50%',
          '序号': 1,
          '日期': '2024-01-15',
          '拼音缩写': 'YFDJYJXHH',
          '拼音全称': 'YiFangDaYouZhiJingXuanHunHe',
        },
        {
          '基金代码': '110022',
          '基金简称': '易方达消费行业股票',
          '基金类型': '股票型',
          '单位净值': '2.3456',
          '累计净值': '3.6789',
          '日增长率': '-1.23%',
          '近1周': '2.34%',
          '近1月': '-0.45%',
          '近3月': '6.78%',
          '近6月': '9.01%',
          '近1年': '18.90%',
          '序号': 2,
          '日期': '2024-01-15',
        },
      ];

      emptyApiData = [];

      invalidApiData = [
        {'invalid': 'data'},
        {'基金代码': '', '基金简称': ''},
        {'基金代码': null, '基金简称': 'test'},
      ];
    });

    group('fromRankingApi', () {
      test('应该正确转换有效的API数据', () {
        final funds = OptimizedFundApiResponse.fromRankingApi(mockApiData);

        expect(funds.length, 2);

        final firstFund = funds.first;
        expect(firstFund.code, '009209');
        expect(firstFund.name, '易方达优质精选混合');
        expect(firstFund.type, '混合型');
        expect(firstFund.company, '易方达');
        expect(firstFund.unitNav, 1.2345);
        expect(firstFund.accumulatedNav, 2.5678);
        expect(
            firstFund.dailyReturn, closeTo(0.0234, 0.0001)); // 2.34% -> 0.0234
        expect(firstFund.return1Y, closeTo(0.1234, 0.0001)); // 12.34% -> 0.1234
        expect(firstFund.fee, 1.50); // 1.50% -> 1.50
        expect(firstFund.rankingPosition, 1);
      });

      test('应该正确处理负数收益率', () {
        final funds = OptimizedFundApiResponse.fromRankingApi(mockApiData);
        final secondFund = funds.last;

        expect(secondFund.dailyReturn,
            closeTo(-0.0123, 0.0001)); // -1.23% -> -0.0123
        expect(secondFund.return1M,
            closeTo(-0.45, 0.0001)); // -0.45% -> -0.45 (当前逻辑)
      });

      test('应该处理空数据列表', () {
        final funds = OptimizedFundApiResponse.fromRankingApi(emptyApiData);
        expect(funds, isEmpty);
      });

      test('应该过滤无效数据', () {
        final funds = OptimizedFundApiResponse.fromRankingApi(invalidApiData);
        expect(funds, isEmpty);
      });

      test('应该正确识别基金类型', () {
        final funds = OptimizedFundApiResponse.fromRankingApi(mockApiData);

        expect(funds[0].type, '混合型');
        expect(funds[1].type, '股票型');
      });

      test('应该正确提取公司名称', () {
        final funds = OptimizedFundApiResponse.fromRankingApi(mockApiData);

        expect(funds[0].company, '易方达');
        expect(funds[1].company, '易方达');
      });
    });

    group('fromRankingApiCompute', () {
      test('应该异步处理大数据量', () async {
        final future =
            OptimizedFundApiResponse.fromRankingApiCompute(mockApiData);
        expect(future, isA<Future<List<Fund>>>());

        final funds = await future;
        expect(funds.length, 2);
        expect(funds.first.code, '009209');
      });
    });

    group('性能分析', () {
      test('字段使用率分析应该正常工作', () {
        // 测试分析功能不会抛出异常
        expect(() {
          OptimizedFundApiResponse.analyzeFieldUsage(mockApiData);
        }, returnsNormally);
      });

      test('高频字段应该正确定义', () {
        final highFreqFields = OptimizedFundApiResponse.highFrequencyFields;
        expect(highFreqFields, contains('基金代码'));
        expect(highFreqFields, contains('基金简称'));
        expect(highFreqFields, contains('单位净值'));
        expect(highFreqFields, contains('累计净值'));
        expect(highFreqFields, contains('日增长率'));
      });

      test('字段映射应该正确定义', () {
        final fieldMappings = OptimizedFundApiResponse.fieldMappings;
        expect(fieldMappings['基金代码'], 'code');
        expect(fieldMappings['基金简称'], 'name');
        expect(fieldMappings['单位净值'], 'unitNav');
        expect(fieldMappings['累计净值'], 'accumulatedNav');
      });
    });

    group('错误处理', () {
      test('应该优雅处理数据转换错误', () {
        final malformedData = [
          {
            '基金代码': '009209',
            '基金简称': '测试基金',
            '单位净值': 'invalid_number',
            '日增长率': 'invalid_percentage',
          }
        ];

        final funds = OptimizedFundApiResponse.fromRankingApi(malformedData);
        expect(funds.length, 1);

        final fund = funds.first;
        expect(fund.code, '009209');
        expect(fund.unitNav, 0.0); // 解析失败时的默认值
        expect(fund.dailyReturn, 0.0); // 解析失败时的默认值
      });

      test('应该处理完全无效的数据结构', () {
        final invalidData = [
          null,
          'invalid_string',
          123,
          [],
        ];

        final funds = OptimizedFundApiResponse.fromRankingApi(
            invalidData.cast<Map<String, dynamic>>());
        expect(funds, isEmpty);
      });
    });

    group('性能优化验证', () {
      test('转换性能应该满足要求', () {
        final stopwatch = Stopwatch()..start();

        // 转换1000条记录
        final largeDataSet = List.generate(
            1000,
            (index) => {
                  '基金代码': (100000 + index).toString().padLeft(6, '0'),
                  '基金简称': '测试基金$index',
                  '基金类型': '混合型',
                  '单位净值': (1.0 + index % 100 * 0.01).toStringAsFixed(4),
                  '累计净值': (1.5 + index % 100 * 0.01).toStringAsFixed(4),
                  '日增长率': '${(index % 50 - 25) * 0.1}%',
                });

        final funds = OptimizedFundApiResponse.fromRankingApi(largeDataSet);

        stopwatch.stop();

        expect(funds.length, 1000);
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 应该在100ms内完成
      });
    });
  });
}
