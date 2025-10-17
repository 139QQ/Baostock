import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// 手机号注册表单组件
class PhoneRegisterForm extends StatefulWidget {
  const PhoneRegisterForm({super.key});

  @override
  State<PhoneRegisterForm> createState() => _PhoneRegisterFormState();
}

class _PhoneRegisterFormState extends State<PhoneRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  /// 发送验证码
  void _sendVerificationCode() {
    if (_formKey.currentState?.validate() ?? false) {
      // 验证手机号格式
      if (!_isPhoneValid(_phoneController.text.trim())) {
        return;
      }

      context.read<AuthBloc>().add(
            SendPhoneVerificationCodeRequested(
              phoneNumber: _phoneController.text.trim(),
            ),
          );
      setState(() {
        _codeSent = true;
        _startCountdown();
      });
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  /// 执行注册
  void _register() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            RegisterWithPhoneRequested(
              phoneNumber: _phoneController.text.trim(),
              verificationCode: _codeController.text.trim(),
              password: _passwordController.text.trim(),
              displayName: _displayNameController.text.trim().isEmpty
                  ? '新用户'
                  : _displayNameController.text.trim(),
            ),
          );
    }
  }

  /// 重新发送验证码
  void _resendCode() {
    _sendVerificationCode();
  }

  /// 验证手机号格式
  bool _isPhoneValid(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(cleanPhone);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = state is AuthLoading;
        });

        if (state is VerificationCodeSent) {
          setState(() {
            _codeSent = true;
            _countdown = state.cooldownSeconds ?? 60;
          });
          _startCountdown();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // 手机号输入框
              _buildPhoneField(),
              const SizedBox(height: 16),
              // 验证码输入框
              _buildVerificationCodeField(),
              const SizedBox(height: 16),
              // 显示名称输入框
              _buildDisplayNameField(),
              const SizedBox(height: 16),
              // 密码输入框
              _buildPasswordField(),
              const SizedBox(height: 16),
              // 确认密码输入框
              _buildConfirmPasswordField(),
              const SizedBox(height: 32),
              // 发送验证码/注册按钮
              if (!_codeSent)
                _buildSendCodeButton()
              else
                _buildRegisterButton(),
              const SizedBox(height: 16),
              // 重新发送验证码
              if (_codeSent) _buildResendCodeSection(),
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

  /// 构建手机号输入框
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      enabled: !_isLoading,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: '手机号码',
        hintText: '请输入手机号码',
        prefixIcon: const Icon(Icons.phone_android),
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
          return '请输入手机号码';
        }

        final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
        if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(cleanPhone)) {
          return '请输入正确的手机号码';
        }

        return null;
      },
      inputFormatters: [
        // 手机号格式化
        _PhoneNumberFormatter(),
      ],
    );
  }

  /// 构建验证码输入框
  Widget _buildVerificationCodeField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _codeSent ? null : 0,
      child: _codeSent
          ? TextFormField(
              controller: _codeController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '验证码',
                hintText: '请输入6位验证码',
                prefixIcon: const Icon(Icons.sms),
                counterText: '',
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
                  return '请输入验证码';
                }

                final cleanCode = value.replaceAll(RegExp(r'[^\d]'), '');
                if (!RegExp(r'^\d{4,6}$').hasMatch(cleanCode)) {
                  return '请输入正确的验证码';
                }

                return null;
              },
            )
          : null,
    );
  }

  /// 构建显示名称输入框
  Widget _buildDisplayNameField() {
    return TextFormField(
      controller: _displayNameController,
      enabled: !_isLoading,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: '显示名称（可选）',
        hintText: '请输入显示名称',
        prefixIcon: const Icon(Icons.person),
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
        // 显示名称是可选的
        return null;
      },
    );
  }

  /// 构建密码输入框
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      enabled: !_isLoading,
      obscureText: !_passwordVisible,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '请输入密码（至少6位）',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
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
        if (value == null || value.trim().isEmpty) {
          return '请输入密码';
        }
        if (value.trim().length < 6) {
          return '密码至少需要6位字符';
        }
        return null;
      },
    );
  }

  /// 构建确认密码输入框
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      enabled: !_isLoading,
      obscureText: !_confirmPasswordVisible,
      decoration: InputDecoration(
        labelText: '确认密码',
        hintText: '请再次输入密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _confirmPasswordVisible = !_confirmPasswordVisible;
            });
          },
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
        if (value == null || value.trim().isEmpty) {
          return '请确认密码';
        }
        if (value.trim() != _passwordController.text.trim()) {
          return '两次输入的密码不一致';
        }
        return null;
      },
    );
  }

  /// 构建发送验证码按钮
  Widget _buildSendCodeButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _sendVerificationCode,
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
              '发送验证码',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  /// 构建注册按钮
  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
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
              '注册',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  /// 构建重新发送验证码部分
  Widget _buildResendCodeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '没有收到验证码？',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        TextButton(
          onPressed: _countdown > 0 || _isLoading ? null : _resendCode,
          child: Text(
            _countdown > 0 ? '$_countdown秒后重试' : '重新发送',
            style: TextStyle(
              color: _countdown > 0
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                  : Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
                '注册即表示同意《用户协议》和《隐私政策》',
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
        const SizedBox(height: 16),
        // 已有账户登录
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '已有账户？',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: Text(
                '立即登录',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 手机号格式化器
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 只保留数字
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // 限制长度为11位
    if (text.length > 11) {
      return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
