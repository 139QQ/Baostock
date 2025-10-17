import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:jisu_fund_analyzer/src/core/di/injection_container.dart';
import 'package:jisu_fund_analyzer/src/core/di/hive_injection_container.dart';

/// 测试环境依赖注入配置
class TestHelpers {
  static final GetIt _testSl = GetIt.instance;

  /// 在测试前初始化所有依赖
  static Future<void> setUpTestDependencies() async {
    // 确保Flutter测试绑定已初始化
    TestWidgetsFlutterBinding.ensureInitialized();

    // 确保依赖容器是干净的
    await _testSl.reset();

    // 初始化Hive缓存相关依赖
    await HiveInjectionContainer.init();

    // 初始化主要依赖
    await initDependencies();
  }

  /// 在测试后清理依赖
  static Future<void> tearDownTestDependencies() async {
    await HiveInjectionContainer.dispose();
    await _testSl.reset();
  }

  /// 为单个测试设置依赖
  static Future<void> setUpTest() async {
    try {
      await setUpTestDependencies();
    } catch (e) {
      // 如果初始化失败，尝试重置
      await _testSl.reset();
      rethrow;
    }
  }

  /// 清理单个测试
  static Future<void> tearDownTest() async {
    try {
      await tearDownTestDependencies();
    } catch (e) {
      // 忽略清理时的错误
      print('清理测试依赖时出错: $e');
    }
  }
}

/// 测试组辅助函数
void groupWithSetup(String description, void Function() body) {
  group(description, () {
    setUpAll(() async {
      await TestHelpers.setUpTestDependencies();
    });

    tearDownAll(() async {
      await TestHelpers.tearDownTestDependencies();
    });

    body();
  });
}
