import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../core/theme/app_theme.dart';
import '../auth/domain/entities/user.dart';
import '../navigation/presentation/pages/navigation_shell.dart';

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

    return MaterialApp(
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
    );
  }
}
