import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../network/fund_api_client.dart';
import '../network/api_service.dart';
import '../navigation/navigation_manager.dart';
// 统一缓存系统导入
import '../cache/interfaces/i_unified_cache_service.dart';
import '../cache/interfaces/cache_service.dart';
import '../cache/unified_hive_cache_manager.dart';
import '../cache/adapters/cache_service_adapter.dart';
import '../cache/adapters/unified_cache_adapter.dart';
import '../cache/smart_cache_invalidation_manager.dart';
import '../cache/cache_key_manager.dart';
import '../cache/cache_performance_monitor.dart';
import '../cache/cache_preheating_manager.dart';
import '../config/cache_system_config.dart';
import '../../services/optimized_cache_manager_v3.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../../features/fund/data/datasources/fund_remote_data_source.dart';
import '../../features/fund/data/datasources/fund_local_data_source.dart';
import '../../features/fund/domain/repositories/fund_repository.dart';
import '../../features/fund/domain/repositories/fund_repository_impl.dart';
import '../../features/fund/domain/usecases/get_fund_list.dart';
import '../../features/fund/domain/usecases/get_fund_rankings.dart';
import '../../features/fund/domain/usecases/fund_search_usecase.dart';
import '../../features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../../features/fund/shared/services/fund_data_service.dart';
import '../../features/fund/shared/services/search_service.dart';
import '../../features/fund/shared/services/data_validation_service.dart';
import '../../features/fund/shared/services/money_fund_service.dart';
// 统一搜索服务导入
import '../../services/unified_search_service/i_unified_search_service.dart';
import '../../services/unified_search_service/unified_search_service.dart';
// 基金对比相关导入
import '../../features/fund/data/services/fund_comparison_service.dart';
import '../../features/fund/domain/repositories/fund_comparison_repository.dart';
import '../../features/fund/data/repositories/fund_comparison_repository_impl.dart';
import '../../features/fund/presentation/cubit/fund_comparison_cubit.dart';
import '../../features/fund/presentation/cubit/comparison_cache_cubit.dart';
// 认证相关导入
import '../../features/auth/data/datasources/auth_api.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_with_phone.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/send_verification_code.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
// 组合分析相关导入
import '../../features/portfolio/domain/repositories/portfolio_profit_repository.dart';
import '../../features/portfolio/data/repositories/portfolio_profit_repository_impl.dart';
import '../../features/portfolio/data/services/portfolio_profit_api_service.dart';
import '../../features/portfolio/data/services/portfolio_profit_cache_service.dart';
import '../../features/portfolio/data/services/portfolio_data_service.dart';
import '../../features/portfolio/domain/services/portfolio_profit_calculation_engine.dart';
import '../../features/portfolio/data/adapters/portfolio_holding_adapter.dart';
import '../../features/portfolio/data/adapters/fund_corporate_action_adapter.dart';
import '../../features/portfolio/data/adapters/fund_split_detail_adapter.dart';
// 导入所有适配器类
import '../../features/portfolio/data/adapters/fund_favorite_adapter.dart'
    as favorite_adapters;
import '../../features/portfolio/data/services/fund_favorite_service.dart';
import '../../features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../../features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:hive/hive.dart';
// Week 6 服务导入
import '../../services/fund_analysis_service.dart';
import '../../services/portfolio_analysis_service.dart';
import '../../services/high_performance_fund_service.dart';
import '../../services/smart_recommendation_service.dart';
import '../../bloc/fund_search_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // debugPrint('初始化依赖注入...');

  // ===== 核心缓存服务 =====

  // 统一缓存系统 - 主要缓存服务
  if (!sl.isRegistered<UnifiedHiveCacheManager>()) {
    sl.registerLazySingleton<UnifiedHiveCacheManager>(() {
      final cacheManager = UnifiedHiveCacheManager.instance;
      // 异步初始化，不阻塞依赖注入过程
      cacheManager.initialize().catchError((e) {
        AppLogger.debug('Unified Hive cache manager initialization failed: $e');
      });
      return cacheManager;
    });
  }

  // 统一缓存服务接口 - 直接注册适配器实例避免循环依赖
  if (!sl.isRegistered<IUnifiedCacheService>()) {
    sl.registerLazySingleton<IUnifiedCacheService>(() {
      final unifiedManager = sl<UnifiedHiveCacheManager>();
      return UnifiedCacheAdapter(unifiedManager);
    });
  }

  // 基础缓存服务（向后兼容）
  if (!sl.isRegistered<CacheService>()) {
    sl.registerLazySingleton<CacheService>(() => CacheServiceAdapter(
          sl<IUnifiedCacheService>(),
        ));
  }

  // 缓存键管理器
  if (!sl.isRegistered<CacheKeyManager>()) {
    sl.registerLazySingleton<CacheKeyManager>(() => CacheKeyManager.instance);
  }

  // 智能缓存失效管理器
  if (!sl.isRegistered<SmartCacheInvalidationManager>()) {
    sl.registerLazySingleton<SmartCacheInvalidationManager>(() {
      final invalidationManager = SmartCacheInvalidationManager.instance;
      // 异步初始化，不阻塞依赖注入过程
      invalidationManager.initialize().catchError((e) {
        AppLogger.debug(
            'Smart cache invalidation manager initialization failed: $e');
      });
      return invalidationManager;
    });
  }

  // 缓存性能监控器
  if (!sl.isRegistered<CachePerformanceMonitor>()) {
    sl.registerLazySingleton<CachePerformanceMonitor>(() {
      final performanceMonitor = CachePerformanceMonitor.instance;
      // 异步初始化，不阻塞依赖注入过程
      performanceMonitor.initialize().catchError((e) {
        AppLogger.debug('Cache performance monitor initialization failed: $e');
      });
      return performanceMonitor;
    });
  }

  // 缓存预热管理器
  if (!sl.isRegistered<CachePreheatingManager>()) {
    sl.registerLazySingleton<CachePreheatingManager>(() {
      final preheatingManager = CachePreheatingManager.instance;
      // 异步初始化，不阻塞依赖注入过程
      preheatingManager.initialize().catchError((e) {
        AppLogger.debug('Cache preheating manager initialization failed: $e');
      });
      return preheatingManager;
    });
  }

  // ===== 统一缓存系统 =====
  // 使用统一缓存管理器替代所有重复的缓存实现
  AppLogger.debug('DependencyInjection: Using unified cache system');

  // 注册优化的缓存管理器V3作为单例，确保整个应用使用同一个实例
  // 临时保留用于兼容性，将来需要迁移到统一缓存系统
  if (!sl.isRegistered<OptimizedCacheManagerV3>()) {
    sl.registerLazySingleton<OptimizedCacheManagerV3>(() {
      final cacheManager = OptimizedCacheManagerV3.createNewInstance();
      // 异步初始化，不阻塞依赖注入过程
      cacheManager.initialize().catchError((e) {
        AppLogger.debug('Optimized cache manager initialization failed: $e');
      });
      return cacheManager;
    });
  }

  // 导航管理器 - 使用单例模式
  sl.registerLazySingleton<NavigationManager>(() => NavigationManager.instance);

  // API客户端
  sl.registerLazySingleton(() => FundApiClient());

  // API服务 - 配置120秒超时时间
  sl.registerLazySingleton(() => ApiService(Dio(BaseOptions(
        baseUrl: 'http://154.44.25.92:8080',
        connectTimeout: const Duration(seconds: 30), // 连接超时：30秒
        receiveTimeout: const Duration(seconds: 120), // 接收超时：120秒
        sendTimeout: const Duration(seconds: 30), // 发送超时：30秒
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ))));

  // 数据源
  sl.registerLazySingleton<FundRemoteDataSource>(
    () => FundRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingletonAsync<FundLocalDataSource>(
    () async {
      // 使用统一缓存管理器进行本地数据源配置
      // 将在未来的版本中重构为使用UnifiedHiveCacheManager
      final box = await Hive.openBox('fund_cache_local');
      return FundLocalDataSourceImpl(box);
    },
  );

  // 仓库
  sl.registerLazySingleton<FundRepository>(
    () => FundRepositoryImpl(
      sl<FundRemoteDataSource>(),
      sl<FundLocalDataSource>(),
      filterUseCase: null,
    ),
  );

  // 用例
  sl.registerLazySingleton(() => GetFundList(sl()));
  sl.registerLazySingleton(() => GetFundRankings(sl()));
  sl.registerLazySingleton(() => FundSearchUseCase(sl()));

  // 基金数据服务
  sl.registerLazySingleton<FundDataService>(() => FundDataService(
        cacheService: sl(),
      ));

  // 数据验证服务（在FundDataService之后注册，避免循环依赖）
  sl.registerLazySingleton<DataValidationService>(() => DataValidationService(
        cacheService: sl(),
        fundDataService: sl(),
      ));

  // 搜索服务
  sl.registerLazySingleton<SearchService>(() => SearchService());

  // 统一搜索服务 (Story 1.1)
  sl.registerLazySingleton<IUnifiedSearchService>(() {
    final service = UnifiedSearchService();
    // 异步初始化，不阻塞依赖注入
    service.initialize().catchError((e) {
      AppLogger.debug('UnifiedSearchService initialization failed: $e');
    });
    return service;
  });

  // 货币基金服务
  sl.registerLazySingleton<MoneyFundService>(() => MoneyFundService());

  // 统一的基金探索Cubit
  sl.registerLazySingleton<FundExplorationCubit>(() => FundExplorationCubit(
        fundDataService: sl(),
        searchService: sl(),
        moneyFundService: sl(),
      ));

  // 基金搜索BLoC
  sl.registerLazySingleton<FundSearchBloc>(() => FundSearchBloc(
        fundService: sl(),
        analysisService: sl(),
      ));

  // ===== Week 6 相关依赖 =====

  // 高性能基金服务
  sl.registerLazySingleton<HighPerformanceFundService>(
      () => HighPerformanceFundService());

  // 基金分析服务
  sl.registerLazySingleton<FundAnalysisService>(() => FundAnalysisService());

  // 投资组合分析服务
  sl.registerLazySingleton<PortfolioAnalysisService>(
      () => PortfolioAnalysisService());

  // 智能推荐服务 (Story 1.4)
  sl.registerLazySingleton<SmartRecommendationService>(
      () => SmartRecommendationService(
            fundDataService: sl(),
            cacheManager: sl(),
          ));

  // ===== 基金对比相关依赖 =====

  // 基金对比服务
  sl.registerLazySingleton(() => FundComparisonService());

  // 基金对比仓库
  sl.registerLazySingleton<FundComparisonRepository>(
      () => FundComparisonRepositoryImpl(
            fundRepository: sl(),
            comparisonService: sl(),
            cacheService: sl(),
          ));

  // 基金对比Cubit
  sl.registerFactory(() => FundComparisonCubit(
        repository: sl(),
      ));

  // 基金对比缓存管理器
  sl.registerLazySingleton(() => ComparisonCacheCubit());

  // ===== 认证相关依赖 =====

  // 安全存储服务
  sl.registerLazySingleton(() => SecureStorageService());

  // 认证API
  sl.registerLazySingleton(() => AuthApi());

  // 认证仓库
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        api: sl(),
        storage: sl(),
      ));

  // 认证用例
  sl.registerLazySingleton(() => LoginWithPhone(sl()));
  sl.registerLazySingleton(() => LoginWithEmail(sl()));
  sl.registerLazySingleton(() => SendVerificationCode(sl()));

  // 认证BLoC
  sl.registerFactory(() => AuthBloc(
        repository: sl(),
        loginWithPhone: sl(),
        loginWithEmail: sl(),
        sendVerificationCode: sl(),
      ));

  // 认证服务
  sl.registerLazySingleton(() => AuthService.instance);

  // ===== 组合分析相关依赖 =====

  // 组合收益API服务
  sl.registerLazySingleton(() => PortfolioProfitApiService());

  // 初始化Hive适配器 - 在注册服务之前
  try {
    // 注册组合分析相关的Hive适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PortfolioHoldingAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FundCorporateActionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FundSplitDetailAdapter());
    }

    // 注册自选基金相关的Hive适配器
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(favorite_adapters.FundFavoriteAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(favorite_adapters.PriceAlertSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(favorite_adapters.TargetPriceAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(favorite_adapters.FundFavoriteListAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(favorite_adapters.SortConfigurationAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(favorite_adapters.FilterConfigurationAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(favorite_adapters.SyncConfigurationAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(favorite_adapters.ListStatisticsAdapter());
    }
  } catch (e) {
    AppLogger.debug('Failed to register Hive adapters: $e');
  }

  // 组合收益缓存服务
  sl.registerLazySingleton<PortfolioProfitCacheService>(() {
    final service = PortfolioProfitCacheService(
      cacheService: sl(),
    );
    // 异步初始化，不阻塞依赖注入
    service.initialize().catchError((e) {
      AppLogger.debug('PortfolioProfitCacheService initialization failed: $e');
    });
    return service;
  });

  // 组合收益计算引擎
  sl.registerLazySingleton(() => PortfolioProfitCalculationEngine());

  // 持仓数据服务
  sl.registerLazySingleton(() => PortfolioDataService());

  // 组合收益仓库
  sl.registerLazySingleton<PortfolioProfitRepository>(
    () => PortfolioProfitRepositoryImpl(
      apiService: sl(),
      cacheService: sl(),
      calculationEngine: sl(),
    ),
  );

  // 组合分析Cubit - 改为单例模式避免重复初始化
  sl.registerLazySingleton(() => PortfolioAnalysisCubit(
        repository: sl(),
        dataService: sl(),
      ));

  // ===== 自选基金相关依赖 =====

  // 自选基金服务
  sl.registerLazySingleton<FundFavoriteService>(() {
    final service = FundFavoriteService();
    // 异步初始化，不阻塞依赖注入
    service.initialize().catchError((e) {
      AppLogger.debug('Fund favorite service initialization failed: $e');
    });
    return service;
  });

  // 自选基金管理Cubit
  sl.registerLazySingleton(() => FundFavoriteCubit(sl()));

  // ===== Week 5 数据源层核心组件 =====
  // 注意：Week 5 组件具有复杂的依赖关系，暂时不直接集成到主DI容器中
  // 组件已正确实现并可通过测试验证功能
  // 如需集成，请参考测试文件中的组件初始化方式

  // debugPrint('依赖注入初始化完成');
}
