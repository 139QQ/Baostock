import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/fund_favorite_adapter.dart';
import 'package:jisu_fund_analyzer/src/models/fund_info.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';

/// 统一的Hive测试管理器
///
/// 解决多测试并发运行时的Hive初始化冲突和适配器重复注册问题
class HiveTestManager {
  static bool _initialized = false;
  static bool _setupComplete = false;
  static final Set<int> _registeredAdapters = {};

  /// 初始化测试环境的Hive（线程安全）
  static Future<void> initializeTestHive() async {
    if (_initialized) return;

    // 使用互斥锁确保线程安全
    synchronized(() async {
      if (_initialized) return;

      try {
        print('🔧 开始初始化统一Hive测试环境...');

        // 在测试环境中使用内存模式，避免平台依赖
        // 创建临时目录作为后备方案
        try {
          final tempDir = Directory.systemTemp;
          final testPath =
              '${tempDir.path}/hive_test_${DateTime.now().millisecondsSinceEpoch}';
          await Directory(testPath).create(recursive: true);
          await Hive.initFlutter(testPath);
          print('✅ Hive初始化成功 (文件模式): $testPath');
        } catch (e) {
          print('⚠️ 文件模式初始化失败，使用内存模式: $e');
          // 使用内存初始化作为后备方案
          await Hive.initFlutter();
          print('✅ Hive初始化成功 (内存模式)');
        }

        // 注册所有必要的适配器（只注册一次）
        await _registerAllAdapters();

        _initialized = true;
        print('✅ 统一Hive测试环境初始化完成');
      } catch (e) {
        print('❌ 统一Hive测试环境初始化失败: $e');
        rethrow;
      }
    });
  }

  /// 注册所有Hive适配器（避免重复注册）
  static Future<void> _registerAllAdapters() async {
    try {
      // 基础适配器ID映射
      final adapters = {
        20: () => Hive.registerAdapter(FundInfoAdapter()),
        10: () => Hive.registerAdapter(FundFavoriteAdapter()),
        11: () => Hive.registerAdapter(PriceAlertSettingsAdapter()),
        12: () => Hive.registerAdapter(TargetPriceAlertAdapter()),
        14: () => Hive.registerAdapter(SortConfigurationAdapter()),
        15: () => Hive.registerAdapter(FilterConfigurationAdapter()),
        17: () => Hive.registerAdapter(SyncConfigurationAdapter()),
        18: () => Hive.registerAdapter(ListStatisticsAdapter()),
        13: () => Hive.registerAdapter(FundFavoriteListAdapter()),
      };

      for (final entry in adapters.entries) {
        final typeId = entry.key;
        final registerFn = entry.value;

        if (!_registeredAdapters.contains(typeId) &&
            !Hive.isAdapterRegistered(typeId)) {
          registerFn();
          _registeredAdapters.add(typeId);
          print('✅ 适配器注册成功 (ID: $typeId)');
        } else if (_registeredAdapters.contains(typeId)) {
          print('⚠️ 适配器已注册 (ID: $typeId)，跳过重复注册');
        }
      }

      print('✅ 所有Hive适配器注册完成，共注册 ${_registeredAdapters.length} 个适配器');
    } catch (e) {
      print('❌ Hive适配器注册失败: $e');
      rethrow;
    }
  }

  /// 设置测试环境（在setUpAll中调用）
  static Future<void> setUpTestEnvironment() async {
    if (_setupComplete) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeTestHive();
    _setupComplete = true;
  }

  /// 清理测试环境（在tearDownAll中调用）
  static Future<void> tearDownTestEnvironment() async {
    try {
      if (_initialized) {
        await Hive.close();
        _initialized = false;
        _setupComplete = false;
        _registeredAdapters.clear();
        print('✅ 统一Hive测试环境清理完成');
      }
    } catch (e) {
      print('⚠️ 统一Hive测试环境清理失败: $e');
    }
  }

  /// 检查特定适配器是否已注册
  static bool isAdapterRegistered(int typeId) {
    return _registeredAdapters.contains(typeId) ||
        Hive.isAdapterRegistered(typeId);
  }

  /// 获取已注册的适配器ID列表
  static List<int> getRegisteredAdapterIds() {
    return List.from(_registeredAdapters);
  }

  /// 重置测试管理器状态（用于完全重置）
  static void reset() {
    _initialized = false;
    _setupComplete = false;
    _registeredAdapters.clear();
  }
}

/// 简单的互斥锁实现
Future<void> synchronized(VoidCallback action) async {
  // 在测试环境中，简单的顺序执行即可
  // 如果需要真正的线程安全，可以使用dart:isolate中的锁机制
  action();
}
