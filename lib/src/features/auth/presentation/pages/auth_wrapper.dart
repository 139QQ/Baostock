import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';
import '../../../../core/services/auth_service.dart';
import '../../../navigation/presentation/pages/navigation_shell.dart';

/// 认证包装器
///
/// 管理应用的认证状态，根据用户登录状态显示相应页面
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late AuthBloc _authBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _initializeAuth();
  }

  @override
  void dispose() {
    // AuthBloc 由依赖注入管理，不在这里销毁
    super.dispose();
  }

  /// 初始化认证服务
  Future<void> _initializeAuth() async {
    try {
      // 初始化AuthService
      await AuthService.instance.initialize(
        repository: sl(),
        authBloc: _authBloc,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('认证服务初始化失败: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // 处理认证状态变化
          if (state is AuthFailure) {
            _showErrorMessage(context, state.userMessage);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial) {
              return _buildLoadingScreen();
            } else if (state is AuthLoading) {
              return _buildLoadingScreen(message: state.message);
            } else if (state is AuthAuthenticated) {
              return NavigationShell(
                user: state.user,
                onLogout: () => _handleLogout(context),
              );
            } else if (state is AuthUnauthenticated) {
              return const LoginPage();
            } else if (state is AuthFailure) {
              return const LoginPage();
            } else if (state is VerificationCodeSent) {
              return const LoginPage();
            } else if (state is UserInfoUpdated) {
              return NavigationShell(
                user: state.updatedUser,
                onLogout: () => _handleLogout(context),
              );
            } else if (state is PasswordStrengthChecked) {
              return const LoginPage();
            } else {
              // 默认情况，返回登录页面
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }

  /// 构建加载屏幕
  Widget _buildLoadingScreen({String? message}) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '基速基金',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '专业的基金分析工具',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 显示错误消息
  void _showErrorMessage(BuildContext context, String message) {
    if (message.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '确定',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 处理登出
  void _handleLogout(BuildContext context) {
    _authBloc.add(const Logout());
  }
}
