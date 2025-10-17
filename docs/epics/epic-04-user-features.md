# Epic 4: 用户相关功能

## 史诗概述
开发完整的用户相关功能模块，包括用户认证系统、投资组合管理、个性化设置和通知提醒功能。这些功能将为用户提供个性化的基金分析体验，提升用户粘性和应用价值。

## 史诗目标
- 构建安全可靠的统一身份认证系统，支持多种登录方式
- 实现功能完善的投资组合管理系统，支持自定义组合创建和管理
- 开发个性化设置功能，允许用户自定义界面和功能偏好
- 建立智能通知提醒系统，及时推送重要信息和用户关注内容
- 确保用户数据安全和隐私保护，符合相关法规要求

## 功能范围

### 1. 用户认证系统
**认证方式支持:**
- 手机号+验证码登录
- 邮箱+密码登录
- 第三方登录（微信、QQ、Apple ID）
- 生物识别认证（指纹、面容识别）

**技术架构:**
```dart
// 认证状态管理
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final UserRepository _userRepository;

  AuthBloc({
    required AuthService authService,
    required UserRepository userRepository,
  }) : _authService = authService,
       _userRepository = userRepository,
       super(AuthState.unauthenticated()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginWithPhone>(_onLoginWithPhone);
    on<LoginWithEmail>(_onLoginWithEmail);
    on<LoginWithThirdParty>(_onLoginWithThirdParty);
    on<Logout>(_onLogout);
  }

  Future<void> _onLoginWithPhone(
    LoginWithPhone event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // 1. 验证手机号格式
      if (!_validatePhoneNumber(event.phoneNumber)) {
        throw AuthException('手机号格式不正确');
      }

      // 2. 发送验证码
      await _authService.sendVerificationCode(event.phoneNumber);

      // 3. 验证验证码
      final user = await _authService.verifyPhoneCode(
        phoneNumber: event.phoneNumber,
        verificationCode: event.verificationCode,
      );

      // 4. 保存用户信息
      await _userRepository.saveUser(user);

      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      ));
    }
  }
}
```

**登录页面设计:**
```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo和标题
              SizedBox(height: 60),
              Icon(
                Icons.account_balance,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 16),
              Text(
                '基速基金',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '专业的基金分析平台',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 60),

              // 登录选项卡
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: '手机号登录'),
                        Tab(text: '邮箱登录'),
                      ],
                    ),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        children: [
                          PhoneLoginForm(),
                          EmailLoginForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // 第三方登录
              Text(
                '其他登录方式',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.wechat, color: Colors.green, size: 32),
                    onPressed: () => _loginWithWeChat(context),
                  ),
                  SizedBox(width: 24),
                  IconButton(
                    icon: Icon(Icons.chat_bubble, color: Colors.blue, size: 32),
                    onPressed: () => _loginWithQQ(context),
                  ),
                  if (Platform.isIOS) ...[
                    SizedBox(width: 24),
                    IconButton(
                      icon: Icon(Icons.apple, size: 32),
                      onPressed: () => _loginWithApple(context),
                    ),
                  ],
                ],
              ),

              Spacer(),

              // 用户协议
              Text(
                '登录即表示同意《用户协议》和《隐私政策》',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 手机号登录表单
class PhoneLoginForm extends StatefulWidget {
  @override
  _PhoneLoginFormState createState() => _PhoneLoginFormState();
}

class _PhoneLoginFormState extends State<PhoneLoginForm> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCountingDown = false;
  int _countdown = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24),

          // 手机号输入
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: '手机号',
              prefixText: '+86 ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return '请输入手机号';
              }
              if (!_isValidPhoneNumber(value!)) {
                return '手机号格式不正确';
              }
              return null;
            },
          ),

          SizedBox(height: 16),

          // 验证码输入
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: '验证码',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.security),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return '请输入验证码';
                    }
                    if (value!.length != 6) {
                      return '验证码为6位数字';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: _isCountingDown ? null : _sendVerificationCode,
                  child: Text(_isCountingDown ? '$_countdown秒' : '获取验证码'),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // 登录按钮
          ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('登录'),
          ),
        ],
      ),
    );
  }

  void _sendVerificationCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      final phoneNumber = _phoneController.text;

      // 发送验证码
      context.read<AuthBloc>().add(SendVerificationCode(phoneNumber));

      // 开始倒计时
      setState(() => _isCountingDown = true);
      _startCountdown();
    }
  }

  void _startCountdown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
          _countdown = 60;
        });
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      final phoneNumber = _phoneController.text;
      final verificationCode = _codeController.text;

      context.read<AuthBloc>().add(
        LoginWithPhone(
          phoneNumber: phoneNumber,
          verificationCode: verificationCode,
        ),
      );
    }
  }
}
```

### 2. 投资组合管理
**组合管理功能:**
```dart
// 投资组合页面
class PortfolioPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortfolioBloc(
        getUserPortfolios: context.read<GetUserPortfolios>(),
        createPortfolio: context.read<CreatePortfolio>(),
        updatePortfolio: context.read<UpdatePortfolio>(),
        deletePortfolio: context.read<DeletePortfolio>(),
      )..add(LoadUserPortfolios()),
      child: PortfolioView(),
    );
  }
}

// 组合视图
class PortfolioView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的组合'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreatePortfolioDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.loading:
              return Center(child: CircularProgressIndicator());

            case LoadStatus.success:
              if (state.portfolios.isEmpty) {
                return EmptyPortfolioWidget();
              }
              return ListView.builder(
                itemCount: state.portfolios.length,
                itemBuilder: (context, index) {
                  final portfolio = state.portfolios[index];
                  return PortfolioCard(portfolio: portfolio);
                },
              );

            case LoadStatus.error:
              return ErrorWidget(
                message: state.error ?? '加载失败',
                onRetry: () => context.read<PortfolioBloc>().add(LoadUserPortfolios()),
              );

            default:
              return SizedBox.shrink();
          }
        },
      ),
    );
  }
}

// 组合卡片
class PortfolioCard extends StatelessWidget {
  final Portfolio portfolio;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToPortfolioDetail(context, portfolio.id),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 组合名称和收益
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (portfolio.description != null) ...[
                          SizedBox(height: 4),
                          Text(
                            portfolio.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 收益信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${portfolio.totalReturn.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getReturnColor(portfolio.totalReturn),
                        ),
                      ),
                      Text(
                        '累计收益',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16),

              // 统计信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('基金数', '${portfolio.fundCount}'),
                  _buildStatItem('总资产', '${portfolio.totalAssets.toStringAsFixed(2)}万'),
                  _buildStatItem('日收益', '${portfolio.dailyReturn.toStringAsFixed(2)}%'),
                ],
              ),

              SizedBox(height: 16),

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('编辑'),
                      onPressed: () => _editPortfolio(context, portfolio),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.share, size: 16),
                      label: Text('分享'),
                      onPressed: () => _sharePortfolio(context, portfolio),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.delete, size: 16),
                      label: Text('删除'),
                      onPressed: () => _deletePortfolio(context, portfolio.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**组合详情和编辑:**
```dart
// 组合详情页面
class PortfolioDetailPage extends StatelessWidget {
  final String portfolioId;

  const PortfolioDetailPage({required this.portfolioId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortfolioDetailBloc(
        getPortfolioDetail: context.read<GetPortfolioDetail>(),
        addFundToPortfolio: context.read<AddFundToPortfolio>(),
        removeFundFromPortfolio: context.read<RemoveFundFromPortfolio>(),
        updateFundWeight: context.read<UpdateFundWeight>(),
      )..add(LoadPortfolioDetail(portfolioId)),
      child: PortfolioDetailView(),
    );
  }
}

// 组合编辑功能
class PortfolioEditor extends StatefulWidget {
  final Portfolio? portfolio;

  @override
  _PortfolioEditorState createState() => _PortfolioEditorState();
}

class _PortfolioEditorState extends State<PortfolioEditor> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<PortfolioFund> _funds = [];

  @override
  void initState() {
    super.initState();
    if (widget.portfolio != null) {
      _nameController.text = widget.portfolio!.name;
      _descriptionController.text = widget.portfolio!.description ?? '';
      _funds = List.from(widget.portfolio!.funds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.portfolio == null ? '创建组合' : '编辑组合'),
        actions: [
          TextButton(
            onPressed: _savePortfolio,
            child: Text('保存'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 基本信息
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '组合名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: '组合描述',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          // 基金列表
          Expanded(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    title: Text('基金配置'),
                    trailing: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addFund,
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView(
                      onReorder: _onReorderFunds,
                      children: _funds.map((fund) => ListTile(
                        key: Key(fund.fundCode),
                        leading: Icon(Icons.drag_handle),
                        title: Text(fund.fundName),
                        subtitle: Text(fund.fundCode),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 权重输入
                            SizedBox(
                              width: 60,
                              child: TextField(
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(
                                  text: fund.weight.toStringAsFixed(1),
                                ),
                                onSubmitted: (value) {
                                  final weight = double.tryParse(value) ?? 0;
                                  _updateFundWeight(fund.fundCode, weight);
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFund(fund.fundCode),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 权重统计
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('总权重'),
                  Text(
                    '${_funds.fold(0.0, (sum, fund) => sum + fund.weight).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTotalWeight() == 100 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. 个性化设置
**设置页面设计:**
```dart
// 设置页面
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: BlocProvider(
        create: (context) => SettingsBloc(
          getUserSettings: context.read<GetUserSettings>(),
          updateUserSettings: context.read<UpdateUserSettings>(),
        )..add(LoadUserSettings()),
        child: SettingsView(),
      ),
    );
  }
}

// 设置视图
class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return ListView(
          children: [
            // 用户账户
            _buildSectionHeader('账户设置'),
            _buildAccountSettings(context, state),

            // 界面设置
            _buildSectionHeader('界面设置'),
            _buildInterfaceSettings(context, state),

            // 通知设置
            _buildSectionHeader('通知设置'),
            _buildNotificationSettings(context, state),

            // 数据设置
            _buildSectionHeader('数据设置'),
            _buildDataSettings(context, state),

            // 隐私设置
            _buildSectionHeader('隐私设置'),
            _buildPrivacySettings(context, state),

            // 关于
            _buildSectionHeader('关于'),
            _buildAboutSettings(context, state),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, SettingsState state) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.person),
          title: Text('个人信息'),
          subtitle: Text('管理您的个人资料'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _navigateToProfile(context),
        ),
        ListTile(
          leading: Icon(Icons.security),
          title: Text('账户安全'),
          subtitle: Text('修改密码、绑定手机等'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _navigateToSecurity(context),
        ),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text('退出登录', style: TextStyle(color: Colors.red)),
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildInterfaceSettings(BuildContext context, SettingsState state) {
    return Column(
      children: [
        // 主题设置
        ListTile(
          leading: Icon(Icons.palette),
          title: Text('主题模式'),
          subtitle: Text(_getThemeModeText(state.themeMode)),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showThemeModeDialog(context, state),
        ),

        // 字体大小
        ListTile(
          leading: Icon(Icons.text_fields),
          title: Text('字体大小'),
          subtitle: Text(_getFontSizeText(state.fontSize)),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showFontSizeDialog(context, state),
        ),

        // 语言设置
        ListTile(
          leading: Icon(Icons.language),
          title: Text('语言'),
          subtitle: Text(_getLanguageText(state.language)),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showLanguageDialog(context, state),
        ),

        // 首页布局
        ListTile(
          leading: Icon(Icons.dashboard),
          title: Text('首页布局'),
          subtitle: Text(_getLayoutText(state.homeLayout)),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showLayoutDialog(context, state),
        ),
      ],
    );
  }
}
```

**主题和个性化:**
```dart
// 主题管理
class ThemeManager {
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.robotoTextTheme(),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
      ),
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  static ThemeData getCustomTheme(CustomThemeSettings settings) {
    return ThemeData(
      useMaterial3: true,
      brightness: settings.isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: settings.primaryColor,
        brightness: settings.isDark ? Brightness.dark : Brightness.light,
      ),
      textTheme: _getTextTheme(settings.fontSize),
    );
  }

  static TextTheme _getTextTheme(double scaleFactor) {
    final baseTextTheme = GoogleFonts.robotoTextTheme();

    return TextTheme(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: baseTextTheme.displayLarge!.fontSize! * scaleFactor,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: baseTextTheme.displayMedium!.fontSize! * scaleFactor,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: baseTextTheme.displaySmall!.fontSize! * scaleFactor,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: baseTextTheme.headlineLarge!.fontSize! * scaleFactor,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: baseTextTheme.headlineMedium!.fontSize! * scaleFactor,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: baseTextTheme.headlineSmall!.fontSize! * scaleFactor,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: baseTextTheme.titleLarge!.fontSize! * scaleFactor,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: baseTextTheme.titleMedium!.fontSize! * scaleFactor,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: baseTextTheme.titleSmall!.fontSize! * scaleFactor,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: baseTextTheme.bodyLarge!.fontSize! * scaleFactor,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: baseTextTheme.bodyMedium!.fontSize! * scaleFactor,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: baseTextTheme.bodySmall!.fontSize! * scaleFactor,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: baseTextTheme.labelLarge!.fontSize! * scaleFactor,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: baseTextTheme.labelMedium!.fontSize! * scaleFactor,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: baseTextTheme.labelSmall!.fontSize! * scaleFactor,
      ),
    );
  }
}
```

### 4. 通知提醒系统
**通知管理:**
```dart
// 通知服务
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fund_channel_id',
      '基金通知',
      channelDescription: '基金相关通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fund_channel_id',
          '基金通知',
          channelDescription: '基金相关通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

// 通知设置
class NotificationSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('通知设置')),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return ListView(
            children: [
              // 价格提醒
              SwitchListTile(
                title: Text('价格提醒'),
                subtitle: Text('关注的基金价格变动提醒'),
                value: state.priceAlertEnabled,
                onChanged: (value) {
                  context.read<NotificationBloc>().add(
                    UpdateNotificationSetting(type: 'price_alert', enabled: value),
                  );
                },
              ),

              // 公告提醒
              SwitchListTile(
                title: Text('公告提醒'),
                subtitle: Text('基金相关公告通知'),
                value: state.announcementAlertEnabled,
                onChanged: (value) {
                  context.read<NotificationBloc>().add(
                    UpdateNotificationSetting(type: 'announcement', enabled: value),
                  );
                },
              ),

              // 组合收益提醒
              SwitchListTile(
                title: Text('组合收益提醒'),
                subtitle: Text('投资组合收益变动提醒'),
                value: state.portfolioAlertEnabled,
                onChanged: (value) {
                  context.read<NotificationBloc>().add(
                    UpdateNotificationSetting(type: 'portfolio', enabled: value),
                  );
                },
              ),

              Divider(),

              // 价格提醒设置
              if (state.priceAlertEnabled) ...[
                ListTile(
                  title: Text('价格提醒设置'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _navigateToPriceAlertSettings(context),
                ),
              ],

              // 提醒时间设置
              ListTile(
                title: Text('提醒时间'),
                subtitle: Text('${state.alertStartTime.format(context)} - ${state.alertEndTime.format(context)}'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => _showTimeRangeDialog(context, state),
              ),

              // 免打扰模式
              SwitchListTile(
                title: Text('免打扰模式'),
                subtitle: Text('在设定时间内不发送通知'),
                value: state.doNotDisturbEnabled,
                onChanged: (value) {
                  context.read<NotificationBloc>().add(
                    UpdateNotificationSetting(type: 'do_not_disturb', enabled: value),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
```

## 验收标准

### 功能验收
- [ ] 支持多种登录方式（手机、邮箱、第三方）
- [ ] 投资组合支持创建、编辑、删除、分享功能
- [ ] 个性化设置支持主题、字体、布局等自定义
- [ ] 通知系统支持多种提醒类型和时间设置
- [ ] 用户数据支持云端同步和备份

### 安全验收
- [ ] 用户认证使用JWT令牌，支持自动刷新
- [ ] 敏感数据传输使用HTTPS加密
- [ ] 本地存储的用户数据经过加密处理
- [ ] 支持生物识别认证

### 性能验收
- [ ] 登录响应时间 < 2秒
- [ ] 用户数据加载时间 < 1秒
- [ ] 设置保存即时生效
- [ ] 通知推送延迟 < 5秒

## 开发时间估算

### 工作量评估
- **用户认证系统**: 40小时
- **投资组合管理**: 48小时
- **个性化设置**: 24小时
- **通知提醒系统**: 32小时
- **数据同步和安全**: 24小时
- **测试和优化**: 24小时

**总计: 192小时（约24个工作日）**

## 依赖关系

### 前置依赖
- Epic 1: 基础架构搭建完成
- Epic 2: 数据层架构完成
- 用户认证服务接口确认
- 第三方登录SDK集成

### 后续影响
- 提供个性化用户体验
- 支持用户数据持久化
- 为后续社交功能奠定基础

## 风险评估

### 安全风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 用户认证漏洞 | 低 | 高 | 使用成熟的认证库，定期安全审计 |
| 数据泄露风险 | 低 | 高 | 数据加密存储，最小权限原则 |
| 第三方登录失败 | 中 | 中 | 提供多种登录方式，完善的错误处理 |

### 合规风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 隐私政策不合规 | 中 | 高 | 咨询法律顾问，制定合规政策 |
| 数据跨境传输问题 | 低 | 高 | 本地化数据存储，符合监管要求 |

## 资源需求

### 人员配置
- **后端开发工程师**: 2人
- **Flutter开发工程师**: 2人
- **安全工程师**: 1人（兼职）
- **UI/UX设计师**: 1人（兼职）

### 技术资源
- 短信验证码服务
- 第三方登录平台账号
- 推送通知服务
- 数据加密工具库

## 交付物

### 代码交付
- 完整的用户认证系统代码
- 投资组合管理功能实现
- 个性化设置功能代码
- 通知提醒系统实现

### 文档交付
- 用户认证API文档
- 投资组合使用指南
- 个性化功能说明
- 通知配置文档

### 测试交付
- 用户认证测试用例
- 安全测试报告
- 性能测试报告
- 兼容性测试报告

---

**史诗负责人:** 用户产品经理
**预计开始时间:** 2025-12-16
**预计完成时间:** 2026-01-25
**优先级:** P1（高）
**状态:** 待开始
**依赖史诗:** Epic 1, Epic 2, Epic 3