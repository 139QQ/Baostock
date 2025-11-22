import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';

/// Alerts模块测试专用的Hive管理器
class AlertsHiveTestHelper {
  static bool _isInitialized = false;
  static String? _currentTestPath;

  /// 为测试初始化独立的Hive环境
  static Future<void> setUpForTest(String testName) async {
    if (_isInitialized) {
      await tearDown();
    }

    try {
      // 为每个测试创建独立的Hive路径
      _currentTestPath =
          'test_alerts_${testName}_${DateTime.now().millisecondsSinceEpoch}';

      // 尝试使用Flutter初始化
      try {
        await Hive.initFlutter(_currentTestPath!);
      } catch (e) {
        // 降级到普通初始化
        Hive.init(_currentTestPath!);
      }

      _isInitialized = true;
      AppLogger.debug('✅ AlertsHiveTestHelper: 初始化成功 - $_currentTestPath');
    } catch (e) {
      AppLogger.error('❌ AlertsHiveTestHelper: 初始化失败', e);
      rethrow;
    }
  }

  /// 清理测试环境
  static Future<void> tearDown() async {
    if (!_isInitialized) return;

    try {
      await Hive.close();

      // 删除测试目录
      if (_currentTestPath != null &&
          await Directory(_currentTestPath!).exists()) {
        await Directory(_currentTestPath!).delete(recursive: true);
      }

      _isInitialized = false;
      _currentTestPath = null;
      AppLogger.debug('✅ AlertsHiveTestHelper: 清理完成');
    } catch (e) {
      AppLogger.error('❌ AlertsHiveTestHelper: 清理失败', e);
      // 即使清理失败也不抛出异常，避免影响其他测试
    }
  }

  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 获取当前测试路径
  static String? get currentTestPath => _currentTestPath;
}
