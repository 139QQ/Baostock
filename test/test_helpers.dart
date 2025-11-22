import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/fund_favorite_adapter.dart';

/// 测试设置助手类
class TestSetupHelper {
  static bool _isInitialized = false;
  static String? _testPath;

  /// 设置测试环境
  static Future<void> setUpTestEnvironment() async {
    if (_isInitialized) return;

    try {
      // 在测试环境中强制使用内存存储
      await Hive.initFlutter();

      // 注册必要的适配器
      _registerAdapters();

      _isInitialized = true;
      print('✅ 测试环境初始化成功');
    } catch (e) {
      print('❌ 测试环境初始化失败: $e');
      rethrow;
    }
  }

  /// 清理测试环境
  static Future<void> tearDownTestEnvironment() async {
    try {
      // 关闭所有打开的Hive boxes
      await Hive.close();

      // 删除测试目录
      if (_testPath != null && await Directory(_testPath!).exists()) {
        await Directory(_testPath!).delete(recursive: true);
        print('✅ 测试环境清理完成');
      }

      _isInitialized = false;
      _testPath = null;
    } catch (e) {
      print('❌ 测试环境清理失败: $e');
    }
  }

  /// 注册Hive适配器
  static void _registerAdapters() {
    try {
      // 注册FundFavorite适配器
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(FundFavoriteAdapter());
      }

      print('✅ Hive适配器注册完成');
    } catch (e) {
      print('❌ Hive适配器注册失败: $e');
    }
  }

  /// 检查测试环境是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 获取测试路径
  static String? get testPath => _testPath;
}

/// 模拟数据助手
class MockDataHelper {
  /// 创建测试用的自选基金数据
  static Map<String, dynamic> createTestFundData({
    String fundCode = '000001',
    String fundName = '测试基金',
    String fundType = '混合型',
    String fundManager = '测试公司',
  }) {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'fundType': fundType,
      'fundManager': fundManager,
      'addedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'currentNav': 1.2345,
      'dailyChange': 2.34,
      'previousNav': 1.2067,
      'notes': '测试备注',
    };
  }

  /// 创建测试用的基金列表数据
  static List<Map<String, dynamic>> createTestFundListData() {
    return [
      createTestFundData(fundCode: '000001', fundName: '华夏成长混合'),
      createTestFundData(fundCode: '110022', fundName: '易方达消费行业'),
      createTestFundData(fundCode: '161725', fundName: '招商中证白酒'),
    ];
  }
}

/// 测试断言助手
class TestAssertHelper {
  /// 断言基金数据包含必要字段
  static void assertValidFundData(Map<String, dynamic> data) {
    expect(data.containsKey('fundCode'), isTrue, reason: '缺少fundCode字段');
    expect(data.containsKey('fundName'), isTrue, reason: '缺少fundName字段');
    expect(data.containsKey('fundType'), isTrue, reason: '缺少fundType字段');
    expect(data.containsKey('addedAt'), isTrue, reason: '缺少addedAt字段');
    expect(data.containsKey('updatedAt'), isTrue, reason: '缺少updatedAt字段');
  }

  /// 断言两个基金数据相等
  static void assertFundDataEquals(
    Map<String, dynamic> expected,
    Map<String, dynamic> actual,
  ) {
    expect(actual['fundCode'], equals(expected['fundCode']));
    expect(actual['fundName'], equals(expected['fundName']));
    expect(actual['fundType'], equals(expected['fundType']));
    expect(actual['fundManager'], equals(expected['fundManager']));
  }
}
