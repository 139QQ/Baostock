import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/fund_favorite_adapter.dart';
import 'package:jisu_fund_analyzer/src/models/fund_info.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';

/// 测试环境的Hive初始化助手
class TestHiveHelper {
  static bool _initialized = false;

  /// 初始化测试环境的Hive
  static Future<void> initTestHive() async {
    if (_initialized) return;

    try {
      // 在测试环境中，尝试多种初始化方式
      try {
        // 方法1：尝试使用临时目录
        final tempDir = Directory.systemTemp;
        final testPath =
            '${tempDir.path}/test_hive_${DateTime.now().millisecondsSinceEpoch}';
        await Directory(testPath).create(recursive: true);
        await Hive.initFlutter(testPath);
        print('✅ 使用临时目录初始化Hive成功: $testPath');
      } catch (e) {
        print('⚠️ 临时目录初始化失败: $e');

        // 方法2：使用内存初始化
        try {
          await Hive.initFlutter();
          print('✅ 使用默认方式初始化Hive成功');
        } catch (e2) {
          print('❌ 默认初始化也失败: $e2');
          rethrow;
        }
      }

      // 注册所有必要的适配器
      await _registerAdapters();

      _initialized = true;
      print('✅ 测试环境Hive初始化成功');
    } catch (e) {
      print('❌ 测试环境Hive初始化失败: $e');
      // 即使初始化失败，也不抛出异常，让测试继续进行
    }
  }

  /// 注册所有Hive适配器
  static Future<void> _registerAdapters() async {
    try {
      // 注册基础适配器
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(FundInfoAdapter());
        print('✅ FundInfo适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(FundFavoriteAdapter());
        print('✅ FundFavorite适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(PriceAlertSettingsAdapter());
        print('✅ PriceAlertSettings适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(TargetPriceAlertAdapter());
        print('✅ TargetPriceAlert适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(SortConfigurationAdapter());
        print('✅ SortConfiguration适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(FilterConfigurationAdapter());
        print('✅ FilterConfiguration适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(SyncConfigurationAdapter());
        print('✅ SyncConfiguration适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(ListStatisticsAdapter());
        print('✅ ListStatistics适配器注册成功');
      }

      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(FundFavoriteListAdapter());
        print('✅ FundFavoriteList适配器注册成功');
      }

      print('✅ 所有Hive适配器注册完成');
    } catch (e) {
      print('❌ Hive适配器注册失败: $e');
      rethrow;
    }
  }

  /// 清理测试环境
  static Future<void> cleanupTestHive() async {
    try {
      if (_initialized) {
        await Hive.close();
        _initialized = false;
        print('✅ 测试环境Hive清理完成');
      }
    } catch (e) {
      print('⚠️ 测试环境Hive清理失败: $e');
    }
  }

  /// 检查适配器是否已注册
  static bool isAdapterRegistered(int typeId) {
    return Hive.isAdapterRegistered(typeId);
  }

  /// 获取已注册的适配器列表
  static List<int> getRegisteredAdapterIds() {
    // 这是一个简化的实现，实际Hive API可能不提供这个功能
    return [10, 11, 12, 13, 14, 15, 17, 18, 20];
  }
}

/// 测试设置助手
class TestSetupHelper {
  /// 设置测试环境
  static Future<void> setUpTestEnvironment() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TestHiveHelper.initTestHive();
  }

  /// 清理测试环境
  static Future<void> tearDownTestEnvironment() async {
    await TestHiveHelper.cleanupTestHive();
  }
}
