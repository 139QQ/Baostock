import 'dart:io';
import 'package:hive/hive.dart';

/// Hive测试辅助类
///
/// 解决测试环境中path_provider依赖问题
class HiveTestHelper {
  static const String _testTag = 'HiveTestHelper';

  /// 为测试环境初始化Hive
  ///
  /// 自动选择最佳的初始化方式，避免path_provider依赖
  static Future<void> initializeForTest({String? customPath}) async {
    try {
      if (customPath != null) {
        // 使用自定义路径
        await Directory(customPath).create(recursive: true);
        Hive.init(customPath);
        print('$_testTag: 使用自定义路径初始化Hive: $customPath');
        return;
      }

      // 策略1: 尝试使用系统临时目录
      final tempDir = Directory.systemTemp;
      final testPath =
          '${tempDir.path}/hive_test_${DateTime.now().millisecondsSinceEpoch}';

      await Directory(testPath).create(recursive: true);
      Hive.init(testPath);
      print('$_testTag: 使用系统临时目录初始化Hive: $testPath');
    } catch (e) {
      // 策略2: 降级到当前目录
      try {
        final currentPath = Directory.current.path;
        final testPath =
            '$currentPath/test_hive_${DateTime.now().millisecondsSinceEpoch}';

        await Directory(testPath).create(recursive: true);
        Hive.init(testPath);
        print('$_testTag: 降级到当前目录初始化Hive: $testPath');
      } catch (e2) {
        // 策略3: 纯内存模式（如果支持）
        try {
          // 尝试初始化到内存
          Hive.init(null);
          print('$_testTag: 使用纯内存模式初始化Hive');
        } catch (e3) {
          print('$_testTag: ❌ 所有Hive初始化方式都失败: $e3');
          throw Exception('无法在测试环境中初始化Hive: $e3');
        }
      }
    }
  }

  /// 清理测试环境
  static Future<void> cleanupTestEnvironment({String? customPath}) async {
    try {
      await Hive.close();

      // 尝试删除测试目录
      if (customPath != null) {
        final dir = Directory(customPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          print('$_testTag: 已清理自定义测试目录: $customPath');
        }
      }
    } catch (e) {
      print('$_testTag: 清理测试环境时出错（可忽略）: $e');
    }
  }

  /// 获取测试环境信息
  static Map<String, dynamic> getTestEnvironmentInfo() {
    return {
      'currentDirectory': Directory.current.path,
      'systemTemp': Directory.systemTemp.path,
      'platform': Platform.operatingSystem,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
