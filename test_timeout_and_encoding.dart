import 'dart:io';
import 'lib/src/services/improved_fund_api_service.dart';

/// 测试超时配置和UTF-8编码
void main() async {
  print('========================================');
  print('测试超时配置和UTF-8编码');
  print('========================================');
  print('');

  // 测试改进版API服务
  await testImprovedApiService();

  print('\n测试完成！');
}

/// 测试改进版API服务
Future<void> testImprovedApiService() async {
  print('🚀 测试改进版API服务');
  print('-' * 30);

  try {
    final stopwatch = Stopwatch()..start();

    final funds = await ImprovedFundApiService.getFundRanking(symbol: '全部');

    stopwatch.stop();

    print('✅ 请求成功！');
    print('⏱️ 耗时: ${stopwatch.elapsedMilliseconds}ms');
    print('📊 获取数据条数: ${funds.length}');

    if (funds.isNotEmpty) {
      print('\n📋 前3条数据示例:');
      for (int i = 0; i < 3 && i < funds.length; i++) {
        final fund = funds[i];
        print('  ${i + 1}. ${fund.fundName} (${fund.fundCode})');
        print('     类型: ${fund.fundType} | 公司: ${fund.company}');
        print('     单位净值: ${fund.unitNav} | 日增长率: ${fund.dailyReturn}%');
        print('     日期: ${fund.date}');
        print('');
      }
    }

    // 验证中文字符显示
    final hasChineseNames = funds.any((fund) =>
        fund.fundName.contains(RegExp(r'[\u4e00-\u9fa5]')) ||
        fund.company.contains(RegExp(r'[\u4e00-\u9fa5]')));

    print('🔤 UTF-8编码验证: ${hasChineseNames ? '✅ 通过' : '❌ 失败'}');

    if (hasChineseNames && funds.isNotEmpty) {
      print('   示例: ${funds.first.fundName} - ${funds.first.company}');
    }

    // 测试是否在60秒内完成
    if (stopwatch.elapsedMilliseconds < 60000) {
      print('⏰ 超时配置验证: ✅ 通过 (${stopwatch.elapsedMilliseconds}ms < 60秒)');
    } else {
      print('⏰ 超时配置验证: ⚠️ 警告 (${stopwatch.elapsedMilliseconds}ms >= 60秒)');
    }
  } catch (e) {
    print('❌ 测试失败: $e');

    if (e.toString().contains('timeout') ||
        e.toString().contains('TimeoutException')) {
      print('⚠️ 检测到超时错误，请检查超时配置');
    }
  }
}
