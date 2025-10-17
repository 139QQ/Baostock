import 'dart:io';
import 'dart:math' as math;
import 'lib/src/services/improved_fund_api_service.dart';
import 'lib/src/services/fund_api_service.dart';

/// 测试改进版API服务
void main() async {
  print('========================================');
  print('基金API服务对比测试');
  print('========================================');
  print('');

  // 测试改进版API服务
  await testImprovedApiService();

  print('\n' + '=' * 40 + '\n');

  // 测试原版API服务
  await testOriginalApiService();

  print('\n测试完成！');
}

/// 测试改进版API服务
Future<void> testImprovedApiService() async {
  print('🚀 测试改进版API服务');
  print('-' * 30);

  try {
    final stopwatch = Stopwatch()..start();

    print('正在请求基金数据...');
    final funds = await ImprovedFundApiService.getFundRanking(
      symbol: '全部',
    );

    stopwatch.stop();

    print('✅ 请求成功！');
    print('⏱️ 耗时: ${stopwatch.elapsedMilliseconds}ms');
    print('📊 获取数据条数: ${funds.length}');

    if (funds.isNotEmpty) {
      print('\n📋 前3条数据示例:');
      for (int i = 0; i < math.min(3, funds.length); i++) {
        final fund = funds[i];
        print('  ${i + 1}. ${fund.fundName} (${fund.fundCode})');
        print('     类型: ${fund.fundType} | 公司: ${fund.company}');
        print('     单位净值: ${fund.unitNav} | 日增长率: ${fund.dailyReturn}%');
        print('     日期: ${fund.date}');
        print('');
      }
    }
  } catch (e) {
    print('❌ 改进版API测试失败: $e');
  }
}

/// 测试原版API服务
Future<void> testOriginalApiService() async {
  print('🔍 测试原版API服务');
  print('-' * 30);

  try {
    final stopwatch = Stopwatch()..start();

    print('正在请求基金数据...');
    final funds = await FundApiService.getFundRanking(
      symbol: '全部',
    );

    stopwatch.stop();

    print('✅ 请求成功！');
    print('⏱️ 耗时: ${stopwatch.elapsedMilliseconds}ms');
    print('📊 获取数据条数: ${funds.length}');

    if (funds.isNotEmpty) {
      print('\n📋 前3条数据示例:');
      for (int i = 0; i < math.min(3, funds.length); i++) {
        final fund = funds[i];
        print('  ${i + 1}. ${fund.fundName} (${fund.fundCode})');
        print('     类型: ${fund.fundType} | 公司: ${fund.company}');
        print('     单位净值: ${fund.unitNav} | 日增长率: ${fund.dailyReturn}%');
        print('     日期: ${fund.date}');
        print('');
      }
    }
  } catch (e) {
    print('❌ 原版API测试失败: $e');
  }
}
