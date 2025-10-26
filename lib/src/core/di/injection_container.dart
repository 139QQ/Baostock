import 'package:get_it/get_it.dart';
import '../network/fund_api_client.dart';
import '../cache/hive_cache_manager.dart';
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
import '../../features/fund/presentation/bloc/fund_bloc.dart';
import '../../features/fund/presentation/bloc/fund_ranking_bloc.dart';
import '../../features/fund/presentation/bloc/search_bloc.dart';
import '../../features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../../features/fund/presentation/fund_exploration/presentation/cubit/fund_ranking_cubit.dart';
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
import '../../features/portfolio/data/adapters/fund_favorite_adapter.dart';
import '../../features/portfolio/data/services/fund_favorite_service.dart';
import '../../features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../../features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:hive/hive.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // debugPrint('初始化依赖注入...');

  // ===== 核心缓存服务 =====

  // 注册优化的缓存管理器V3作为单例，确保整个应用使用同一个实例
  sl.registerLazySingleton<OptimizedCacheManagerV3>(() {
    final cacheManager = OptimizedCacheManagerV3.createNewInstance();
    // 异步初始化，不阻塞依赖注入过程
    cacheManager.initialize().catchError((e) {
      AppLogger.debug('Optimized cache manager initialization failed: $e');
    });
    return cacheManager;
  });

  // API客户端
  sl.registerLazySingleton(() => FundApiClient());

  // 数据源
  sl.registerLazySingleton<FundRemoteDataSource>(
    () => FundRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<FundLocalDataSource>(
    () => FundLocalDataSourceImpl(HiveCacheManager.instance.cacheBox),
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

  // Bloc
  sl.registerFactory(() => FundBloc(
        getFundList: sl(),
        getFundRankings: sl(),
      ));

  // 排行榜BLoC
  sl.registerFactory(() => FundRankingBloc(
        getFundRankings: sl(),
        repository: sl(),
      ));

  // 搜索BLoC
  sl.registerFactory(() => SearchBloc(
        searchUseCase: sl(),
      ));

  // 基金探索Cubit
  sl.registerFactory(() => FundExplorationCubit(
        fundRankingBloc: sl(),
      ));

  // 基金排行Cubit
  sl.registerLazySingleton(() => FundRankingCubit());

  // ===== 基金对比相关依赖 =====

  // 基金对比服务
  sl.registerLazySingleton(() => FundComparisonService());

  // 基金对比仓库
  sl.registerLazySingleton<FundComparisonRepository>(
      () => FundComparisonRepositoryImpl(
            fundRepository: sl(),
            comparisonService: sl(),
            cacheManager: sl(),
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
      Hive.registerAdapter(FundFavoriteAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(PriceAlertSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(TargetPriceAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(FundFavoriteListAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(SortConfigurationAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(FilterConfigurationAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(SyncConfigurationAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(ListStatisticsAdapter());
    }
  } catch (e) {
    AppLogger.debug('Failed to register Hive adapters: $e');
  }

  // 组合收益缓存服务
  sl.registerLazySingleton<PortfolioProfitCacheService>(() {
    final service = PortfolioProfitCacheService();
    // 异步初始化，不阻塞依赖注入
    service.initialize().catchError((e) {
      AppLogger.debug('Cache service initialization failed: $e');
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

  // debugPrint('依赖注入初始化完成');
}
