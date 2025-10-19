import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../main.dart';
import '../../core/theme/app_theme.dart';
import '../auth/domain/entities/user.dart';
import '../navigation/presentation/pages/navigation_shell.dart';
import '../fund/presentation/fund_exploration/presentation/cubit/fund_ranking_cubit_simple.dart';
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
    return BlocProvider<SimpleFundRankingCubit>(
      create: (context) {
        debugPrint('🔄 JisuFundAnalyzerApp: 创建全局SimpleFundRankingCubit实例');
        return GlobalCubitManager.instance.getFundRankingCubit();
      },
      child: MaterialApp(
        title: '基速基金分析器',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: AppLifecycleManager(
          child: NavigationShell(
            user: mockUser,
            onLogout: () {
              // 模拟登出操作 - 这里可以什么都不做
              debugPrint('登出功能已暂时禁用');
            },
          ),
        ),
      ),
    );
  }
}
