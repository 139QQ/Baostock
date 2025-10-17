import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/phone_register_form.dart';
import '../widgets/email_register_form.dart';

/// 注册页面
///
/// 提供手机号注册和邮箱注册两种方式
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // 注册成功，导航到主页
              Navigator.of(context).pushReplacementNamed('/home');
            } else if (state is AuthFailure) {
              // 显示错误信息
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.userMessage),
                  backgroundColor: Colors.red,
                  action: state.isRetryable
                      ? SnackBarAction(
                          label: '重试',
                          textColor: Colors.white,
                          onPressed: () {
                            // 清除错误状态
                            context
                                .read<AuthBloc>()
                                .add(const ClearAuthError());
                          },
                        )
                      : null,
                ),
              );
            } else if (state is VerificationCodeSent) {
              // 验证码发送成功提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // 返回按钮
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              // Logo和标题
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '基速基金',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                      Text(
                        '专业的基金分析工具',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 32),
          // 欢迎标题
          Text(
            '创建新账户',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请选择注册方式以开始使用',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          // Tab栏
          _buildTabBar(context),
        ],
      ),
    );
  }

  /// 构建Tab栏
  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            text: '手机号注册',
            icon: Icon(Icons.phone_android),
          ),
          Tab(
            text: '邮箱注册',
            icon: Icon(Icons.email),
          ),
        ],
      ),
    );
  }

  /// 构建Tab内容视图
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: const [
        // 手机号注册表单
        PhoneRegisterForm(),
        // 邮箱注册表单
        EmailRegisterForm(),
      ],
    );
  }
}
