import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../main.dart';
import '../../core/di/injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../auth/domain/entities/user.dart';
import '../navigation/presentation/pages/navigation_shell.dart';
import '../fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../portfolio/presentation/cubit/fund_favorite_cubit.dart';
import '../../core/state/global_cubit_manager.dart';

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
      ],
      child: MaterialApp(
        title: '基速基金分析器',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => AppLifecycleManager(
                child: NavigationShell(
                  user: mockUser,
                  onLogout: () {
                    // 模拟登出操作 - 这里可以什么都不做
                    debugPrint('登出功能已暂时禁用');
                  },
                ),
              ),
        },
        onUnknownRoute: (settings) {
          // 处理未定义的路由，返回一个简单的页面
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text('页面未找到'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '路由未定义: ${settings.name}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('返回'),
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
