import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/design_tokens/app_colors.dart';
import '../../../../core/theme/widgets/gradient_container.dart';
import '../../../../core/theme/widgets/modern_ui_components.dart';

/// 现代化系统设置页面
///
/// 提供应用设置和个性化配置功能，包含：
/// - 现代化设置选项界面
/// - 个性化主题配置
/// - 用户偏好管理
/// - 应用信息显示
/// - 数据和隐私设置
/// - 响应式交互设计
class ModernSettingsPage extends StatefulWidget {
  /// 创建现代化设置页面
  const ModernSettingsPage({super.key});

  @override
  State<ModernSettingsPage> createState() => _ModernSettingsPageState();
}

class _ModernSettingsPageState extends State<ModernSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 设置状态
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoRefresh = true;
  bool _biometricAuth = false;
  bool _dataSync = true;
  String _selectedLanguage = '简体中文';
  String _selectedTheme = '默认蓝色';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSettings();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    // 这里加载用户设置
    // 加载保存的设置
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF233997).withOpacity(0.95),
              const Color(0xFF5E7CFF).withOpacity(0.85),
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              Expanded(child: _buildSettingsList()),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建现代化AppBar
  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      '系统设置',
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0xFFE8F4FF)],
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '个性化配置您的投资体验',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建设置列表
  Widget _buildSettingsList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSettingsSection('界面设置', _buildUISettings()),
                  const SizedBox(height: 24),
                  _buildSettingsSection('通知设置', _buildNotificationSettings()),
                  const SizedBox(height: 24),
                  _buildSettingsSection('数据与隐私', _buildPrivacySettings()),
                  const SizedBox(height: 24),
                  _buildSettingsSection('高级设置', _buildAdvancedSettings()),
                  const SizedBox(height: 24),
                  _buildAppInfoSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建设置分区
  Widget _buildSettingsSection(String title, List<Widget> children) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  /// 构建界面设置
  List<Widget> _buildUISettings() {
    return [
      _buildSettingTile(
        '主题模式',
        _selectedTheme,
        Icons.palette_outlined,
        () => _showThemeDialog(),
      ),
      _buildSettingTile(
        '深色模式',
        _darkMode ? '已开启' : '已关闭',
        Icons.dark_mode_outlined,
        () => setState(() => _darkMode = !_darkMode),
        trailing: Switch(
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
          activeColor: const Color(0xFF233997),
        ),
      ),
      _buildSettingTile(
        '语言设置',
        _selectedLanguage,
        Icons.language,
        () => _showLanguageDialog(),
      ),
    ];
  }

  /// 构建通知设置
  List<Widget> _buildNotificationSettings() {
    return [
      _buildSettingTile(
        '推送通知',
        _notifications ? '已开启' : '已关闭',
        Icons.notifications_outlined,
        () => setState(() => _notifications = !_notifications),
        trailing: Switch(
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
          activeColor: const Color(0xFF233997),
        ),
      ),
      _buildSettingTile(
        '自动刷新',
        _autoRefresh ? '已开启' : '已关闭',
        Icons.refresh,
        () => setState(() => _autoRefresh = !_autoRefresh),
        trailing: Switch(
          value: _autoRefresh,
          onChanged: (value) => setState(() => _autoRefresh = value),
          activeColor: const Color(0xFF233997),
        ),
      ),
      _buildSettingTile(
        '生物识别',
        _biometricAuth ? '已开启' : '已关闭',
        Icons.fingerprint,
        () => _showBiometricSetup(),
        trailing: Switch(
          value: _biometricAuth,
          onChanged: (value) => setState(() => _biometricAuth = value),
          activeColor: const Color(0xFF233997),
        ),
      ),
    ];
  }

  /// 构建数据与隐私设置
  List<Widget> _buildPrivacySettings() {
    return [
      _buildSettingTile(
        '数据同步',
        _dataSync ? '已开启' : '已关闭',
        Icons.sync,
        () => setState(() => _dataSync = !_dataSync),
        trailing: Switch(
          value: _dataSync,
          onChanged: (value) => setState(() => _dataSync = value),
          activeColor: const Color(0xFF233997),
        ),
      ),
      _buildSettingTile(
        '清除缓存',
        '清理临时数据',
        Icons.cleaning_services,
        () => _showClearCacheDialog(),
      ),
      _buildSettingTile(
        '导出数据',
        '备份应用数据',
        Icons.file_download,
        () => _showExportDataDialog(),
      ),
    ];
  }

  /// 构建高级设置
  List<Widget> _buildAdvancedSettings() {
    return [
      _buildSettingTile(
        '开发者模式',
        '调试功能',
        Icons.code,
        () => _showDeveloperModeDialog(),
      ),
      _buildSettingTile(
        '性能优化',
        '应用加速设置',
        Icons.speed,
        () => _showPerformanceDialog(),
      ),
      _buildSettingTile(
        '重置设置',
        '恢复默认配置',
        Icons.restore,
        () => _showResetSettingsDialog(),
      ),
    ];
  }

  /// 构建应用信息部分
  Widget _buildAppInfoSection() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: FinancialGradients.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '关于基速基金',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '专业基金分析平台',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('版本号', '1.0.0'),
            _buildInfoRow('构建号', '20251116.1'),
            _buildInfoRow('开发者', '基速团队'),
            _buildInfoRow('技术栈', 'Flutter + Dart'),
            _buildInfoRow('许可协议', 'MIT License'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: '检查更新',
                    gradient: FinancialGradients.primaryGradient,
                    onPressed: () => _checkForUpdates(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernButton(
                    text: '联系我们',
                    gradient: FinancialGradients.successGradient,
                    onPressed: () => _contactSupport(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  /// 构建设置项
  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF233997).withOpacity(0.1),
              const Color(0xFF5E7CFF).withOpacity(0.1),
            ],
          ),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF233997),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示主题对话框
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择主题'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                title: const Text('默认蓝色'),
                value: '默认蓝色',
                groupValue: _selectedTheme,
                onChanged: (String? value) {
                  setState(() => _selectedTheme = value ?? '');
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('科技绿'),
                value: '科技绿',
                groupValue: _selectedTheme,
                onChanged: (String? value) {
                  setState(() => _selectedTheme = value ?? '');
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('温暖橙'),
                value: '温暖橙',
                groupValue: _selectedTheme,
                onChanged: (String? value) {
                  setState(() => _selectedTheme = value ?? '');
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('优雅紫'),
                value: '优雅紫',
                groupValue: _selectedTheme,
                onChanged: (String? value) {
                  setState(() => _selectedTheme = value ?? '');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  /// 显示语言对话框
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择语言'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<String>(
                title: const Text('简体中文'),
                value: '简体中文',
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() => _selectedLanguage = value ?? '');
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('繁體中文'),
                value: '繁體中文',
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() => _selectedLanguage = value ?? '');
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() => _selectedLanguage = value ?? '');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  /// 显示生物识别设置
  void _showBiometricSetup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('生物识别设置功能开发中'),
        backgroundColor: Color(0xFF233997),
      ),
    );
  }

  /// 显示清除缓存对话框
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('清除缓存'),
          content: const Text('确定要清除所有缓存数据吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('缓存已清除'),
                    backgroundColor: Color(0xFF233997),
                  ),
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 显示导出数据对话框
  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('导出数据'),
          content: const Text('确定要导出应用数据吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('数据导出功能开发中'),
                    backgroundColor: Color(0xFF233997),
                  ),
                );
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 显示开发者模式对话框
  void _showDeveloperModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('开发者模式'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('开发者模式包含调试功能和实验性功能'),
              SizedBox(height: 16),
              Text('⚠️ 警告：这些功能可能影响应用稳定性'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // 启用开发者模式逻辑
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('启用'),
            ),
          ],
        );
      },
    );
  }

  /// 显示性能优化对话框
  void _showPerformanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('性能优化'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('优化应用性能以获得更好的使用体验'),
              const SizedBox(height: 16),
              ModernButton(
                text: '立即优化',
                gradient: FinancialGradients.techGradient,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('性能优化已完成'),
                      backgroundColor: Color(0xFF233997),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  /// 显示重置设置对话框
  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重置设置'),
          content: const Text('确定要重置所有设置到默认状态吗？此操作不可撤销。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetAllSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('设置已重置'),
                    backgroundColor: Color(0xFF233997),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('重置'),
            ),
          ],
        );
      },
    );
  }

  /// 重置所有设置
  void _resetAllSettings() {
    setState(() {
      _darkMode = false;
      _notifications = true;
      _autoRefresh = true;
      _biometricAuth = false;
      _dataSync = true;
      _selectedLanguage = '简体中文';
      _selectedTheme = '默认蓝色';
    });
  }

  /// 检查更新
  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('当前已是最新版本'),
        backgroundColor: Color(0xFF233997),
      ),
    );
  }

  /// 联系支持
  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('联系支持：support@jisufund.com'),
        backgroundColor: Color(0xFF233997),
      ),
    );
  }
}
