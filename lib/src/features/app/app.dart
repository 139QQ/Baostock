import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_lifecycle_manager.dart';
import '../auth/domain/entities/user.dart';
// import '../home/presentation/widgets/smart_navigation_wrapper.dart'; // 已删除，使用基础导航
import '../navigation/presentation/pages/navigation_shell.dart';
import '../fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../portfolio/presentation/cubit/fund_favorite_cubit.dart';
import '../../core/state/global_cubit_manager.dart';
import '../../bloc/fund_search_bloc.dart';
// Story 2.3 市场指数相关导入
import '../market/presentation/cubits/market_index_cubit.dart';
import '../market/presentation/cubits/index_trend_cubit.dart';

class JisuFundAnalyzerApp extends StatelessWidget {
  const JisuFundAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建一个模拟用户来跳过认证
    final mockUser = User(
      id: 'demo-user',
      phoneNumber: '13800138000',
      displayName: '演示用户',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      isPhoneVerified: true,
    );

    // 在应用顶层提供全局状态管理
    return MultiBlocProvider(
      providers: [
        // 基金探索Cubit
        BlocProvider<FundExplorationCubit>(
          create: (context) {
            debugPrint('🔄 JisuFundAnalyzerApp: 获取统一的FundExplorationCubit实例');
            return GlobalCubitManager.instance.getFundRankingCubit();
          },
        ),
        // 持仓分析Cubit
        BlocProvider<PortfolioAnalysisCubit>(
          create: (context) {
            debugPrint('🔄 JisuFundAnalyzerApp: 创建PortfolioAnalysisCubit实例');
            return sl<PortfolioAnalysisCubit>();
          },
        ),
        // 自选基金Cubit
        BlocProvider<FundFavoriteCubit>(
          create: (context) {
            debugPrint('🔄 JisuFundAnalyzerApp: 创建FundFavoriteCubit实例');
            final cubit = sl<FundFavoriteCubit>();
            // 初始化自选基金数据
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cubit.initialize();
            });
            return cubit;
          },
        ),
        // 基金搜索Bloc
        BlocProvider<FundSearchBloc>(
          create: (context) {
            debugPrint('🔄 JisuFundAnalyzerApp: 创建FundSearchBloc实例');
            return sl<FundSearchBloc>();
          },
        ),
        // 市场指数Cubit (Story 2.3)
        BlocProvider<MarketIndexCubit>(
          create: (context) {
            debugPrint('🔄 JisuFundAnalyzerApp: 获取MarketIndexCubit实例');
            return GlobalCubitManager.instance.getMarketIndexCubit();
          },
        ),
        // 指数趋势Cubit (Story 2.3)
        BlocProvider<IndexTrendCubit>(
          create: (context) {
            debugPrint('🔄 JisuFundAnalyzerApp: 创建IndexTrendCubit实例');
            return GlobalCubitManager.instance.getIndexTrendCubit();
          },
        ),
      ],
      child: MaterialApp(
        title: '基速基金分析器',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => AppLifecycleManager(
                child: NavigationShell(
                  user: User.testUser(), // 提供默认用户，实际应用中应该从认证状态获取
                  onLogout: () {
                    // 登出逻辑，实际应用中应该导航到登录页面
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ), // 使用基础导航外壳替代已删除的组件
              ),
        },
        onUnknownRoute: (settings) {
          // 处理未定义的路由，返回一个简单的页面
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('页面未找到'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      '路由未定义: ${settings.name}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('返回'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
