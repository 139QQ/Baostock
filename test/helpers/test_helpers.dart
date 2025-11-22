import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

/// 测试辅助工具
class TestHelpers {
  /// 创建测试用的临时目录路径
  static String get tempDir => 'test_temp';

  /// 清理测试资源
  static Future<void> cleanup() async {
    // 测试清理逻辑
  }
}

/// 测试用的模拟数据
class MockData {
  static Map<String, dynamic> get fundInfo => {
        'code': '000001',
        'name': '测试基金',
        'type': '股票型',
        'nav': '1.2345',
        'changeRate': '0.05',
        'changeAmount': '0.0006',
      };

  static Map<String, dynamic> get marketEvent => {
        'id': 'test-event-1',
        'type': 'market_change',
        'entityId': '000001',
        'entityName': '测试基金',
        'changeRate': 0.05,
        'currentValue': '1.2345',
        'previousValue': '1.2339',
        'timestamp': DateTime.now().toIso8601String(),
      };
}
