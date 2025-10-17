import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'lib/src/features/fund/presentation/fund_exploration/domain/data/models/fund_dto.dart';

/// 测试基金名称修复是否有效
void main() async {
  print('🔧 测试基金名称和公司修复效果...\n');

  // 模拟API返回的原始数据
  final mockApiData = [
    {
      '基金代码': '001234',
      '基金简称': '中欧数字经济混合发起A',
      '基金类型': '混合型',
      '基金公司': '中欧基金',
      '单位净值': '1.2345',
      '累计净值': '1.3456',
      '日增长率': '0.15',
      '近1周': '1.25',
      '近1月': '2.15',
      '近3月': '4.55',
      '近6月': '8.25',
      '近1年': '15.65',
      '近2年': '25.45',
      '近3年': '35.85',
      '今年来': '12.35',
      '成立来': '65.25',
      '日期': '2025-10-15',
      '手续费': '0.15'
    },
    {
      '基金代码': '002567',
      '基金简称': '易方达蓝筹精选混合',
      '基金类型': '混合型',
      '基金公司': '易方达基金',
      '单位净值': '2.5678',
      '累计净值': '2.7890',
      '日增长率': '-0.25',
      '近1周': '-0.75',
      '近1月': '1.25',
      '近3月': '6.35',
      '近6月': '12.55',
      '近1年': '28.75',
      '近2年': '45.25',
      '近3年': '72.35',
      '今年来': '18.65',
      '成立来': '156.85',
      '日期': '2025-10-15',
      '手续费': '0.15'
    },
    {
      '基金代码': '003890',
      '基金简称': '华夏科技创新混合A',
      '基金类型': '混合型',
      '基金公司': '华夏基金',
      '单位净值': '1.8901',
      '累计净值': '2.1234',
      '日增长率': '0.85',
      '近1周': '2.15',
      '近1月': '5.75',
      '近3月': '12.85',
      '近6月': '18.45',
      '近1年': '32.65',
      '近2年': '58.75',
      '近3年': '95.35',
      '今年来': '22.15',
      '成立来': '185.65',
      '日期': '2025-10-15',
      '手续费': '0.15'
    }
  ];

  print('📊 测试数据：${mockApiData.length} 条基金记录\n');

  // 测试解析
  bool allTestsPassed = true;

  for (int i = 0; i < mockApiData.length; i++) {
    final item = mockApiData[i];
    print('--- 测试记录 ${i + 1} ---');

    try {
      // 使用修复后的 fromJson 方法
      final fundRankingDto = FundRankingDto.fromJson(item);
      final domainModel = fundRankingDto.toDomainModel();

      // 验证基金名称
      final expectedName = item['基金简称']?.toString() ?? '';
      final actualName = domainModel.fundName;
      final nameTest = expectedName == actualName;

      // 验证公司名称
      final expectedCompany = item['基金公司']?.toString() ?? '';
      final actualCompany = domainModel.company;
      final companyTest = expectedCompany == actualCompany;

      // 验证基金类型
      final expectedType = item['基金类型']?.toString() ?? '';
      final actualType = domainModel.fundType;
      final typeTest = expectedType == actualType;

      print('基金代码: ${domainModel.fundCode}');
      print('基金名称: $actualName ${nameTest ? '✅' : '❌'}');
      print('基金公司: $actualCompany ${companyTest ? '✅' : '❌'}');
      print('基金类型: $actualType ${typeTest ? '✅' : '❌'}');
      print('日收益率: ${domainModel.dailyReturn.toStringAsFixed(2)}%');

      if (!nameTest) {
        print('❌ 名称错误：期望 "$expectedName"，实际 "$actualName"');
        allTestsPassed = false;
      }

      if (!companyTest) {
        print('❌ 公司错误：期望 "$expectedCompany"，实际 "$actualCompany"');
        allTestsPassed = false;
      }

      if (!typeTest) {
        print('❌ 类型错误：期望 "$expectedType"，实际 "$actualType"');
        allTestsPassed = false;
      }
    } catch (e) {
      print('❌ 解析失败: $e');
      allTestsPassed = false;
    }

    print('');
  }

  print('📋 测试结果总结:');
  if (allTestsPassed) {
    print('✅ 所有测试通过！基金名称和公司信息显示问题已修复。');
    print('✅ 基金类型解析正常。');
    print('✅ 数据转换功能正常。');
  } else {
    print('❌ 部分测试失败，需要进一步检查。');
  }

  // 测试边界情况
  print('\n🧪 测试边界情况:');

  // 测试缺少字段的情况
  final incompleteData = {
    '基金代码': '009999',
    '基金简称': '测试基金',
    // 故意缺少 '基金公司' 字段
  };

  try {
    final incompleteDto = FundRankingDto.fromJson(incompleteData);
    final incompleteDomain = incompleteDto.toDomainModel();

    print('缺少公司字段时的处理: ${incompleteDomain.company}');
    print('是否使用默认值 "未知公司": ${incompleteDomain.company == '未知公司' ? '✅' : '❌'}');
  } catch (e) {
    print('❌ 边界情况测试失败: $e');
  }

  print('\n🎯 修复验证完成！');
}
