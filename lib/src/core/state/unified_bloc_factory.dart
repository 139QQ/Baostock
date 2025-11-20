/// 统一BLoC工厂
///
/// 负责创建和管理应用中所有BLoC实例的生命周期
/// 提供统一的依赖注入和生命周期管理
library unified_bloc_factory;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:equatable/equatable.dart';

import '../di/injection_container.dart' as di;
import 'feature_toggle_service.dart';
// 简化的BLoC导入 - 为了避免编译错误，使用基础类型
// import '../../../bloc/fund_search_bloc.dart';
// import '../../../bloc/portfolio_bloc.dart';
// import '../../../bloc/fund_detail_bloc.dart';
// import '../../../features/auth/presentation/bloc/auth_bloc.dart';
// import '../../../features/fund/presentation/bloc/filter_bloc.dart';
// import '../../../features/fund/presentation/bloc/search_bloc.dart';
// import '../../../core/presentation/bloc/cache_bloc.dart';
// import '../../../features/fund/presentation/bloc/fund_bloc.dart';

// 导入真实的BLoC类
import '../../bloc/fund_search_bloc.dart';
import '../../bloc/fund_detail_bloc.dart';

// 临时的空状态类，用于未实现的BLoC
class EmptyState extends Equatable {
  const EmptyState();

  @override
  List<Object> get props => [];
}

// 临时的BLoC类定义，用于未实现的功能模块
class PortfolioBloc extends BlocBase {
  PortfolioBloc() : super(const EmptyState());
}

class AuthBloc extends BlocBase {
  AuthBloc() : super(const EmptyState());
}

class FilterBloc extends BlocBase {
  FilterBloc() : super(const EmptyState());
}

class SearchBloc extends BlocBase {
  SearchBloc() : super(const EmptyState());
}

class CacheBloc extends BlocBase {
  CacheBloc() : super(const EmptyState());
}

class FundBloc extends BlocBase {
  FundBloc() : super(const EmptyState());
}

/// BLoC类型枚举
enum BlocType {
  /// 基金搜索BLoC
  fundSearch,

  /// 投资组合BLoC
  portfolio,

  /// 基金详情BLoC
  fundDetail,

  /// 认证BLoC
  auth,

  /// 过滤BLoC
  filter,

  /// 搜索BLoC
  search,

  /// 缓存BLoC
  cache,

  /// 基金BLoC
  fund,
}

/// BLoC创建配置
class BlocCreationConfig {
  final BlocType type;
  final Map<String, dynamic> parameters;
  final bool singleton;
  final String? customName;

  const BlocCreationConfig({
    required this.type,
    this.parameters = const {},
    this.singleton = true,
    this.customName,
  });
}

/// BLoC工厂接口
abstract class BlocFactory<T extends BlocBase> {
  T create(BlocCreationConfig config);
  String get blocName;
  BlocType get blocType;
}

/// BLoC工厂注册表
class BlocFactoryRegistry {
  static final Map<BlocType, BlocFactory> _factories = {};

  /// 注册BLoC工厂
  static void registerFactory<T extends BlocBase>(
    BlocType type,
    BlocFactory<T> factory,
  ) {
    _factories[type] = factory;
    debugPrint('✅ BlocFactoryRegistry: 已注册 ${factory.blocName} 工厂');
  }

  /// 获取BLoC工厂
  static BlocFactory? getFactory(BlocType type) {
    return _factories[type];
  }

  /// 获取所有已注册的工厂
  static Map<BlocType, BlocFactory> getAllFactories() {
    return Map.unmodifiable(_factories);
  }

  /// 清除所有工厂（主要用于测试）
  static void clearAll() {
    _factories.clear();
    debugPrint('🗑️ BlocFactoryRegistry: 已清除所有工厂');
  }
}

/// 统一BLoC工厂
class UnifiedBlocFactory {
  static UnifiedBlocFactory? _instance;
  static UnifiedBlocFactory get instance =>
      _instance ??= UnifiedBlocFactory._();

  UnifiedBlocFactory._();

  final Map<String, BlocBase> _singletonInstances = {};
  final Map<String, int> _instanceCounts = {};

  /// 获取或创建BLoC实例
  T getBloc<T extends BlocBase>(
    BlocType type, {
    Map<String, dynamic> parameters = const {},
    bool forceNewInstance = false,
    String? customName,
  }) {
    final featureToggle = FeatureToggleService.instance;
    final moduleName = _getModuleNameFromBlocType(type);

    // 检查特性开关，如果未启用BLoC模式，返回null或抛出异常
    if (!featureToggle.useBlocMode(moduleName)) {
      throw StateError(
          '模块 $moduleName 的BLoC模式未启用。当前模式: ${featureToggle.config.currentMode}');
    }

    final config = BlocCreationConfig(
      type: type,
      parameters: parameters,
      customName: customName,
    );

    final instanceName = customName ?? type.name;

    // 如果是单例且不强制创建新实例，返回现有实例
    if (!forceNewInstance && _singletonInstances.containsKey(instanceName)) {
      _instanceCounts[instanceName] = (_instanceCounts[instanceName] ?? 0) + 1;
      debugPrint(
          '🔄 UnifiedBlocFactory: 返回现有实例 $instanceName (引用计数: ${_instanceCounts[instanceName]})');
      return _singletonInstances[instanceName] as T;
    }

    // 创建新实例
    final factory = BlocFactoryRegistry.getFactory(type);
    if (factory == null) {
      throw StateError('未找到类型 $type 的BLoC工厂');
    }

    final bloc = factory.create(config);
    _singletonInstances[instanceName] = bloc;
    _instanceCounts[instanceName] = 1;

    debugPrint(
        '✅ UnifiedBlocFactory: 创建新实例 $instanceName (${bloc.runtimeType})');

    return bloc as T;
  }

  /// 释放BLoC实例
  Future<void> releaseBloc(String instanceName) async {
    if (!_singletonInstances.containsKey(instanceName)) {
      debugPrint('⚠️ UnifiedBlocFactory: 实例 $instanceName 不存在');
      return;
    }

    final instance = _singletonInstances[instanceName]!;
    final currentCount = _instanceCounts[instanceName] ?? 0;

    if (currentCount <= 1) {
      // 最后一个引用，关闭并移除实例
      if (instance is BlocBase) {
        await instance.close();
      }
      _singletonInstances.remove(instanceName);
      _instanceCounts.remove(instanceName);
      debugPrint('🗑️ UnifiedBlocFactory: 已释放实例 $instanceName');
    } else {
      // 减少引用计数
      _instanceCounts[instanceName] = currentCount - 1;
      debugPrint(
          '🔄 UnifiedBlocFactory: 减少实例 $instanceName 引用计数 (当前: ${_instanceCounts[instanceName]})');
    }
  }

  /// 释放所有BLoC实例
  Future<void> releaseAll() async {
    debugPrint('🗑️ UnifiedBlocFactory: 开始释放所有BLoC实例...');

    final futures = _singletonInstances.entries.map((entry) async {
      try {
        await entry.value.close();
        debugPrint('✅ 已释放 ${entry.key}');
      } catch (e) {
        debugPrint('❌ 释放 ${entry.key} 时出错: $e');
      }
    });

    await Future.wait(futures);

    _singletonInstances.clear();
    _instanceCounts.clear();

    debugPrint('✅ UnifiedBlocFactory: 所有BLoC实例已释放');
  }

  /// 获取实例统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'totalInstances': _singletonInstances.length,
      'instanceCounts': Map.from(_instanceCounts),
      'instanceTypes': _singletonInstances
          .map((key, value) => MapEntry(key, value.runtimeType.toString())),
    };
  }

  /// 检查实例是否存在
  bool hasInstance(String instanceName) {
    return _singletonInstances.containsKey(instanceName);
  }

  /// 获取实例（不创建新实例）
  T? getInstance<T extends BlocBase>(String instanceName) {
    final instance = _singletonInstances[instanceName];
    return instance as T?;
  }

  /// 从BLoC类型获取模块名称
  String _getModuleNameFromBlocType(BlocType type) {
    switch (type) {
      case BlocType.fundSearch:
      case BlocType.fund:
      case BlocType.search:
      case BlocType.filter:
      case BlocType.fundDetail:
        return 'fund';
      case BlocType.portfolio:
        return 'portfolio';
      case BlocType.auth:
        return 'auth';
      case BlocType.cache:
        return 'alerts'; // 缓存BLoC主要用于alerts模块
    }
  }

  /// 打印当前状态
  void printCurrentState() {
    debugPrint('📊 UnifiedBlocFactory 当前状态:');
    debugPrint('  活跃实例数: ${_singletonInstances.length}');
    debugPrint('  实例详情:');
    _singletonInstances.forEach((name, bloc) {
      final count = _instanceCounts[name] ?? 0;
      debugPrint('    $name: ${bloc.runtimeType} (引用: $count)');
    });
  }
}

/// BLoC工厂基类
abstract class BaseBlocFactory<T extends BlocBase> implements BlocFactory<T> {
  @override
  String get blocName => T.toString();

  /// 获取依赖注入容器
  final GetIt getIt = di.sl;

  /// 创建通用参数
  Map<String, dynamic> createParameters(BlocCreationConfig config) {
    return Map<String, dynamic>.from(config.parameters);
  }
}

/// 基金搜索BLoC工厂
class FundSearchBlocFactory extends BaseBlocFactory<FundSearchBloc> {
  @override
  BlocType get blocType => BlocType.fundSearch;

  @override
  FundSearchBloc create(BlocCreationConfig config) {
    // 从依赖注入容器获取服务或创建新实例
    // 使用必需的参数创建
    return FundSearchBloc(
      fundService: getIt(),
      analysisService: getIt(),
    );
  }
}

/// 投资组合BLoC工厂
class PortfolioBlocFactory extends BaseBlocFactory<PortfolioBloc> {
  @override
  BlocType get blocType => BlocType.portfolio;

  @override
  PortfolioBloc create(BlocCreationConfig config) {
    return PortfolioBloc();
  }
}

/// 基金详情BLoC工厂
class FundDetailBlocFactory extends BaseBlocFactory<FundDetailBloc> {
  @override
  BlocType get blocType => BlocType.fundDetail;

  @override
  FundDetailBloc create(BlocCreationConfig config) {
    return FundDetailBloc(
      analysisService: getIt(),
    );
  }
}

/// 认证BLoC工厂
class AuthBlocFactory extends BaseBlocFactory<AuthBloc> {
  @override
  BlocType get blocType => BlocType.auth;

  @override
  AuthBloc create(BlocCreationConfig config) {
    return AuthBloc();
  }
}

/// 过滤BLoC工厂
class FilterBlocFactory extends BaseBlocFactory<FilterBloc> {
  @override
  BlocType get blocType => BlocType.filter;

  @override
  FilterBloc create(BlocCreationConfig config) {
    return FilterBloc();
  }
}

/// 搜索BLoC工厂
class SearchBlocFactory extends BaseBlocFactory<SearchBloc> {
  @override
  BlocType get blocType => BlocType.search;

  @override
  SearchBloc create(BlocCreationConfig config) {
    return SearchBloc();
  }
}

/// 缓存BLoC工厂
class CacheBlocFactory extends BaseBlocFactory<CacheBloc> {
  @override
  BlocType get blocType => BlocType.cache;

  @override
  CacheBloc create(BlocCreationConfig config) {
    return CacheBloc();
  }
}

/// 基金BLoC工厂
class FundBlocFactory extends BaseBlocFactory<FundBloc> {
  @override
  BlocType get blocType => BlocType.fund;

  @override
  FundBloc create(BlocCreationConfig config) {
    return FundBloc();
  }
}
