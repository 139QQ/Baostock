import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('Hive Plugin Tests', () {
    setUpAll(() async {
      // 初始化Hive用于测试
      try {
        Hive.init('./test_hive');
      } catch (e) {
        print('Hive initialization failed: $e');
      }
    });

    tearDownAll(() async {
      // 清理测试环境
      try {
        await Hive.close();
      } catch (e) {
        print('Hive cleanup failed: $e');
      }
    });

    test('should initialize Hive without path_provider', () async {
      // 基本的Hive功能测试，不依赖path_provider
      final box = await Hive.openBox('test');
      expect(box, isNotNull);
    });

    test('should handle basic operations', () async {
      final box = await Hive.openBox('test2');
      box.put('test_key', 'test_value');
      expect(box.get('test_key'), equals('test_value'));
      await box.deleteFromDisk();
    });
  });
}
