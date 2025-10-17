import 'package:get_it/get_it.dart';
import '../network/fund_api_client.dart';
import '../cache/hive_cache_manager.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';
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
// 认证相关导入
import '../../features/auth/data/datasources/auth_api.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_with_phone.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/send_verification_code.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // debugPrint('初始化依赖注入...');

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

  // debugPrint('依赖注入初始化完成');
}
