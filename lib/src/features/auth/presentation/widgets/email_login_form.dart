import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// 密码强度枚举
enum PasswordStrength {
  weak('弱', '#FF4444'),
  medium('中', '#FFA726'),
  strong('强', '#66BB6A'),
  veryStrong('很强', '#26A69A');

  const PasswordStrength(this.description, this.color);

  final String description;
  final String color;
}

/// 邮箱登录表单组件
class EmailLoginForm extends StatefulWidget {
  const EmailLoginForm({super.key});

  @override
  State<EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<EmailLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 执行登录
  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginWithEmailRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  /// 切换密码可见性
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  /// 检查密码强度
  void _checkPasswordStrength(String password) {
    // 这里简化处理，实际应该使用LoginWithEmail中的密码强度检查逻辑
    int score = 0;

    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++; // 小写字母
    if (password.contains(RegExp(r'[A-Z]'))) score++; // 大写字母
    if (password.contains(RegExp(r'[0-9]'))) score++; // 数字
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++; // 特殊字符

    PasswordStrength strength;
    if (score >= 5) {
      strength = PasswordStrength.veryStrong;
    } else if (score >= 4) {
      strength = PasswordStrength.strong;
    } else if (score >= 3) {
      strength = PasswordStrength.medium;
    } else if (score >= 2) {
      strength = PasswordStrength.medium;
    } else {
      strength = PasswordStrength.weak;
    }

    if (_passwordStrength != strength) {
      setState(() {
        _passwordStrength = strength;
      });
    }
  }

  /// 忘记密码
  void _forgotPassword() {
    // TODO: 实现忘记密码功能
    _showForgotPasswordDialog();
  }

  /// 显示忘记密码对话框
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('忘记密码'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请输入您的邮箱地址，我们将发送重置密码的链接给您。'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '邮箱地址',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('重置链接已发送到您的邮箱'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = state is AuthLoading;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // 邮箱输入框
              _buildEmailField(),
              const SizedBox(height: 16),
              // 密码输入框
              _buildPasswordField(),
              const SizedBox(height: 8),
              // 密码强度指示器
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 24),
              // 登录按钮
              _buildLoginButton(),
              const SizedBox(height: 16),
              // 忘记密码
              _buildForgotPasswordLink(),
              const Spacer(),
              // 其他选项
              _buildOtherOptions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建邮箱输入框
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      enabled: !_isLoading,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: '邮箱地址',
        hintText: '请输入邮箱地址',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入邮箱地址';
        }

        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );

        if (!emailRegex.hasMatch(value.trim())) {
          return '请输入正确的邮箱地址';
        }

        if (value.length > 254) {
          return '邮箱地址过长';
        }

        return null;
      },
    );
  }

  /// 构建密码输入框
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      enabled: !_isLoading,
      obscureText: _obscurePassword,
      onChanged: _checkPasswordStrength,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '请输入密码',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: _togglePasswordVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入密码';
        }

        if (value.length < 6) {
          return '密码至少需要6个字符';
        }

        if (value.trim().isEmpty) {
          return '密码不能只包含空格';
        }

        return null;
      },
    );
  }

  /// 构建密码强度指示器
  Widget _buildPasswordStrengthIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _passwordController.text.isNotEmpty ? 40 : 0,
      child: _passwordController.text.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '密码强度：',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _passwordStrength.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Color(
                              int.parse(_passwordStrength.color.substring(1)),
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _getPasswordStrengthValue(),
                  backgroundColor:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(
                      int.parse(_passwordStrength.color.substring(1)),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  /// 获取密码强度数值
  double _getPasswordStrengthValue() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 0.2;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  /// 构建登录按钮
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              '登录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  /// 构建忘记密码链接
  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _forgotPassword,
        child: Text(
          '忘记密码？',
          style: TextStyle(
            color: _isLoading
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                : Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 构建其他选项
  Widget _buildOtherOptions() {
    return Column(
      children: [
        // 分割线
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '其他',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        // 注册链接
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '还没有账户？',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pushNamed('/register');
                    },
              child: Text(
                '立即注册',
                style: TextStyle(
                  color: _isLoading
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                      : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 使用协议
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '登录即表示同意《用户协议》和《隐私政策》',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
