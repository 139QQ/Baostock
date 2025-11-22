import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// 集成测试环境设置
class TestIntegrationSetup {
  static bool _initialized = false;

  /// 初始化集成测试环境
  static Future<void> setUpIntegrationTests() async {
    if (_initialized) return;

    try {
      // 确保在测试环境中正确初始化Hive
      try {
        final testDir = Directory('./test_hive_integration');
        if (!await testDir.exists()) {
          await testDir.create(recursive: true);
        }
        Hive.init(testDir.path);
      } catch (e) {
        // 如果Hive已经初始化，忽略错误
        if (!e.toString().contains('already initialized')) {
          rethrow;
        }
      }

      // 注册必要的适配器
      _registerHiveAdapters();

      _initialized = true;
      print('✅ 集成测试环境初始化完成');
    } catch (e) {
      print('❌ 集成测试环境初始化失败: $e');
      rethrow;
    }
  }

  /// 清理集成测试环境
  static Future<void> tearDownIntegrationTests() async {
    try {
      await Hive.close();

      // 清理测试目录
      final testDir = Directory('./test_hive_integration');
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }

      _initialized = false;
      print('✅ 集成测试环境清理完成');
    } catch (e) {
      print('⚠️ 集成测试环境清理失败: $e');
    }
  }

  /// 注册Hive适配器
  static void _registerHiveAdapters() {
    // 这里注册所有必要的适配器
    // 由于测试环境可能没有完整的适配器定义，我们提供基本注册
    try {
      // 实际项目中这里会注册具体的适配器
      // Hive.registerAdapter(FundInfoAdapter());
      // Hive.registerAdapter(PortfolioHoldingAdapter());
      // 等等...
    } catch (e) {
      print('⚠️ Hive适配器注册失败（可能是正常的测试环境）: $e');
    }
  }

  /// 获取初始化状态
  bool get isInitialized => _initialized;
}
