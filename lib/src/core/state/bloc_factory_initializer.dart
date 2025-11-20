/// BLoC工厂初始化器
///
/// 负责初始化和注册所有BLoC工厂
library bloc_factory_initializer;

import 'package:flutter/foundation.dart';
import 'unified_bloc_factory.dart';

/// BLoC工厂初始化器
class BlocFactoryInitializer {
  /// 是否已初始化
  static bool _isInitialized = false;

  /// 初始化所有BLoC工厂
  static void initialize() {
    if (_isInitialized) {
      debugPrint('🔄 BlocFactoryInitializer: 工厂已经初始化');
      return;
    }

    debugPrint('🚀 BlocFactoryInitializer: 开始初始化BLoC工厂...');

    try {
      // 注册所有BLoC工厂
      _registerAllFactories();

      _isInitialized = true;
      debugPrint('✅ BlocFactoryInitializer: BLoC工厂初始化完成');
    } catch (e) {
      debugPrint('❌ BlocFactoryInitializer: 初始化失败: $e');
      rethrow;
    }
  }

  /// 注册所有BLoC工厂
  static void _registerAllFactories() {
    // 注册基金相关BLoC工厂
    BlocFactoryRegistry.registerFactory(
        BlocType.fundSearch, FundSearchBlocFactory());
    BlocFactoryRegistry.registerFactory(
        BlocType.fundDetail, FundDetailBlocFactory());
    BlocFactoryRegistry.registerFactory(BlocType.fund, FundBlocFactory());
    BlocFactoryRegistry.registerFactory(BlocType.search, SearchBlocFactory());
    BlocFactoryRegistry.registerFactory(BlocType.filter, FilterBlocFactory());

    // 注册认证相关BLoC工厂
    BlocFactoryRegistry.registerFactory(BlocType.auth, AuthBlocFactory());

    // 注册投资组合相关BLoC工厂
    BlocFactoryRegistry.registerFactory(
        BlocType.portfolio, PortfolioBlocFactory());

    // 注册缓存相关BLoC工厂
    BlocFactoryRegistry.registerFactory(BlocType.cache, CacheBlocFactory());

    debugPrint('✅ 已注册 ${BlocFactoryRegistry.getAllFactories().length} 个BLoC工厂');
  }

  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 重置初始化状态（主要用于测试）
  static void reset() {
    _isInitialized = false;
    BlocFactoryRegistry.clearAll();
    debugPrint('🔄 BlocFactoryInitializer: 已重置初始化状态');
  }
}
