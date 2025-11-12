import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/permissions/android_13_notification_permission_manager.dart';
import '../../../../core/notifications/notification_channel_manager.dart';
import '../../../../core/notifications/real_flutter_notification_service.dart';
import '../widgets/notification_permission_dialog.dart';

/// 增强版通知权限测试页面
///
/// 基于掘金文章的最佳实践实现
/// 全面测试Android 13+通知权限和通知渠道功能
class EnhancedNotificationPermissionTestPage extends StatefulWidget {
  /// 创建增强版通知权限测试页面
  const EnhancedNotificationPermissionTestPage({super.key});

  @override
  State<EnhancedNotificationPermissionTestPage> createState() =>
      _EnhancedNotificationPermissionTestPageState();
}

class _EnhancedNotificationPermissionTestPageState
    extends State<EnhancedNotificationPermissionTestPage> {
  final Android13NotificationPermissionManager _permissionManager =
      Android13NotificationPermissionManager.instance;
  final NotificationChannelManager _channelManager =
      NotificationChannelManager.instance;
  final RealFlutterNotificationService _realNotificationService =
      RealFlutterNotificationService.instance;

  bool _isLoading = false;
  String _testResult = '';
  Map<String, dynamic> _deviceInfo = {};
  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.unknown;
  List<NotificationChannelInfo> _availableChannels = [];

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _checkPermissionStatus();
    _loadAvailableChannels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增强版通知权限测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildDeviceInfoCard(),
            const SizedBox(height: 16),
            _buildPermissionStatusCard(),
            const SizedBox(height: 16),
            _buildChannelInfoCard(),
            const SizedBox(height: 16),
            _buildTestActionsCard(),
            const SizedBox(height: 16),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active,
              size: 32,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Android 13+ 通知权限测试',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    '基于掘金文章最佳实践实现的完整测试',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '设备信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_deviceInfo.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  _buildInfoRow('设备型号', _deviceInfo['model']),
                  _buildInfoRow('Android版本', _deviceInfo['version']),
                  _buildInfoRow('SDK版本', _deviceInfo['sdkInt']),
                  _buildInfoRow('是否Android 13+', _deviceInfo['isAndroid13']),
                  _buildInfoRow('是否支持POST_NOTIFICATIONS',
                      _deviceInfo['supportsPostNotifications']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '未知',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_permissionStatus) {
      case NotificationPermissionStatus.granted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '已授权';
        break;
      case NotificationPermissionStatus.denied:
        statusColor = Colors.orange;
        statusIcon = Icons.error;
        statusText = '被拒绝';
        break;
      case NotificationPermissionStatus.permanentlyDenied:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        statusText = '永久拒绝';
        break;
      case NotificationPermissionStatus.limited:
        statusColor = Colors.yellow;
        statusIcon = Icons.warning;
        statusText = '受限';
        break;
      case NotificationPermissionStatus.restricted:
        statusColor = Colors.red[400]!;
        statusIcon = Icons.security;
        statusText = '限制';
        break;
      case NotificationPermissionStatus.provisional:
        statusColor = Colors.cyan;
        statusIcon = Icons.pending;
        statusText = '临时';
        break;
      case NotificationPermissionStatus.unknown:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = '未知';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '通知权限状态',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _checkPermissionStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('检查'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _requestNotificationPermission,
                  icon: const Icon(Icons.notifications),
                  label: const Text('请求权限'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('打开设置'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '通知渠道',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_availableChannels.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: _availableChannels
                    .map((channel) => _buildChannelItem(channel))
                    .toList(),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _initializeChannels,
              icon: const Icon(Icons.add_circle),
              label: const Text('初始化所有渠道'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelItem(NotificationChannelInfo channel) {
    Color importanceColor;
    String importanceText;

    switch (channel.importance.toString()) {
      case 'NotificationImportance.high':
        importanceColor = Colors.red;
        importanceText = '高';
        break;
      case 'NotificationImportance.default':
        importanceColor = Colors.blue;
        importanceText = '默认';
        break;
      case 'NotificationImportance.low':
        importanceColor = Colors.grey;
        importanceText = '低';
        break;
      case 'NotificationImportance.min':
        importanceColor = Colors.grey[400]!;
        importanceText = '最小';
        break;
      default:
        importanceColor = Colors.blue;
        importanceText = '默认';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  channel.channelName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: importanceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  importanceText,
                  style: TextStyle(
                    fontSize: 10,
                    color: importanceColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            channel.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '渠道ID: ${channel.channelId}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (channel.enableVibration) ...[
                const SizedBox(width: 8),
                Icon(Icons.vibration, size: 12, color: Colors.grey[600]),
              ],
              if (channel.enableLights) ...[
                const SizedBox(width: 4),
                Icon(Icons.lightbulb_outline,
                    size: 12, color: Colors.grey[600]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '功能测试',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  '🔔 真实通知测试',
                  Icons.notifications_active,
                  Colors.deepPurple,
                  _testRealNotification,
                ),
                _buildTestButton(
                  '基础通知测试',
                  Icons.notifications,
                  Colors.blue,
                  _testBasicNotification,
                ),
                _buildTestButton(
                  '基金提醒测试',
                  Icons.trending_up,
                  Colors.green,
                  _testFundAlertNotification,
                ),
                _buildTestButton(
                  '交易信号测试',
                  Icons.show_chart,
                  Colors.orange,
                  _testTradeSignalNotification,
                ),
                _buildTestButton(
                  '市场新闻测试',
                  Icons.newspaper,
                  Colors.indigo,
                  _testMarketNewsNotification,
                ),
                _buildTestButton(
                  '权限对话框测试',
                  Icons.contact_support,
                  Colors.purple,
                  _testPermissionDialog,
                ),
                _buildTestButton(
                  '永久拒绝处理测试',
                  Icons.block,
                  Colors.red,
                  _testPermanentlyDeniedFlow,
                ),
                _buildTestButton(
                  '权限统计测试',
                  Icons.analytics,
                  Colors.teal,
                  _testPermissionStats,
                ),
                _buildTestButton(
                  '取消所有通知',
                  Icons.clear_all,
                  Colors.grey,
                  _cancelAllNotifications,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_testResult.isEmpty) {
      return Card(
        color: Colors.grey[100],
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('点击上方按钮开始测试'),
          ),
        ),
      );
    }

    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '测试结果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _testResult = ''),
                  tooltip: '清空结果',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _testResult,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final isAndroid13Plus = androidInfo.version.sdkInt >= 33;

      setState(() {
        _deviceInfo = {
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt.toString(),
          'isAndroid13': isAndroid13Plus ? '是' : '否',
          'supportsPostNotifications': isAndroid13Plus ? '是' : '否(默认授权)',
        };
      });
    } catch (e) {
      AppLogger.error('获取设备信息失败', e);
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final status =
          await _permissionManager.checkNotificationPermissionStatus();
      setState(() {
        _permissionStatus = status;
      });
    } catch (e) {
      AppLogger.error('检查权限状态失败', e);
    }
  }

  Future<void> _loadAvailableChannels() async {
    try {
      final channels = _channelManager.getAllChannels();
      setState(() {
        _availableChannels = channels;
      });
    } catch (e) {
      AppLogger.error('加载通知渠道失败', e);
    }
  }

  Future<void> _refreshAll() async {
    await _loadDeviceInfo();
    await _checkPermissionStatus();
    await _loadAvailableChannels();
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    try {
      _appendResult('🔔 开始请求通知权限...');

      final result = await _permissionManager.requestNotificationPermission();

      _appendResult('请求结果: ${result.status}');
      _appendResult('消息: ${result.message ?? '无'}');
      _appendResult('是否需要打开设置: ${result.shouldShowSettings ? '是' : '否'}');

      await _checkPermissionStatus();
    } catch (e) {
      _appendResult('❌ 请求权限失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openAppSettings() async {
    try {
      _appendResult('📱 尝试打开应用设置...');

      final success = await _permissionManager.openAppSettings();

      if (success) {
        _appendResult('✅ 成功打开应用设置');
      } else {
        _appendResult('❌ 无法打开应用设置');
      }
    } catch (e) {
      _appendResult('❌ 打开设置失败: $e');
    }
  }

  Future<void> _initializeChannels() async {
    setState(() => _isLoading = true);

    try {
      _appendResult('📂 开始初始化通知渠道...');

      await _channelManager.initializeChannels();

      _appendResult('✅ 通知渠道初始化完成');
      await _loadAvailableChannels();
    } catch (e) {
      _appendResult('❌ 初始化渠道失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBasicNotification() async {
    setState(() => _isLoading = true);

    try {
      _appendResult('🧪 开始基础通知测试...');

      await _realNotificationService.sendTestNotification();

      _appendResult('✅ 基础通知测试完成');
    } catch (e) {
      _appendResult('❌ 基础通知测试失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testFundAlertNotification() async {
    setState(() => _isLoading = true);

    try {
      _appendResult('📈 开始基金提醒通知测试...');

      await _realNotificationService.sendFundPriceAlert(
        fundCode: '000001',
        fundName: '华夏成长混合',
        currentPrice: 2.3456,
        priceChange: 0.0234,
        changePercent: 1.02,
      );

      _appendResult('✅ 基金提醒通知测试完成');
    } catch (e) {
      _appendResult('❌ 基金提醒通知测试失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testTradeSignalNotification() async {
    setState(() => _isLoading = true);

    try {
      _appendResult('📊 开始交易信号通知测试...');

      await _realNotificationService.sendTradeSignal(
        fundCode: '110022',
        fundName: '易方达消费行业',
        signalType: 'buy',
        reason: '技术指标突破买入点',
        targetPrice: 2.5000,
        currentPrice: 2.3456,
      );

      _appendResult('✅ 交易信号通知测试完成');
    } catch (e) {
      _appendResult('❌ 交易信号通知测试失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPermissionDialog() async {
    try {
      _appendResult('💬 开始权限对话框测试...');

      final result = await NotificationPermissionDialog
          .showStandardNotificationPermissionDialog(
        context,
      );

      _appendResult('对话框结果: ${result ? '用户同意' : '用户拒绝/取消'}');
      _appendResult('✅ 权限对话框测试完成');
    } catch (e) {
      _appendResult('❌ 权限对话框测试失败: $e');
    }
  }

  Future<void> _testPermanentlyDeniedFlow() async {
    try {
      _appendResult('🚫 开始永久拒绝流程测试...');

      final result =
          await NotificationPermissionDialog.showPermanentlyDeniedDialog(
        context,
        openSettings: () => _appendResult('用户选择打开设置'),
      );

      _appendResult('对话框结果: ${result ? '用户打开设置' : '用户取消'}');
      _appendResult('✅ 永久拒绝流程测试完成');
    } catch (e) {
      _appendResult('❌ 永久拒绝流程测试失败: $e');
    }
  }

  Future<void> _testRealNotification() async {
    setState(() => _isLoading = true);

    try {
      _appendResult('🔔 开始真实通知测试...');

      await _realNotificationService.sendTestNotification();

      _appendResult('✅ 真实通知测试完成');
    } catch (e) {
      _appendResult('❌ 真实通知测试失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMarketNewsNotification() async {
    setState(() => _isLoading = true);

    try {
      _appendResult('📰 开始市场新闻通知测试...');

      await _realNotificationService.sendMarketNews(
        title: '📈 市场快讯',
        content: 'A股三大指数集体收涨，科技板块表现强势。分析师建议关注优质成长股的投资机会。',
      );

      _appendResult('✅ 市场新闻通知测试完成');
    } catch (e) {
      _appendResult('❌ 市场新闻通知测试失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPermissionStats() async {
    try {
      _appendResult('📊 开始权限统计测试...');

      final stats = await _permissionManager.getPermissionStats();

      _appendResult('权限统计信息:');
      _appendResult('  总请求数: ${stats.totalRequests}');
      _appendResult('  授权数量: ${stats.grantedCount}');
      _appendResult('  拒绝数量: ${stats.deniedCount}');
      _appendResult('  永久拒绝数量: ${stats.permanentlyDeniedCount}');
      _appendResult('  授权率: ${(stats.grantRate * 100).toStringAsFixed(1)}%');

      _appendResult('✅ 权限统计测试完成');
    } catch (e) {
      _appendResult('❌ 权限统计测试失败: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      _appendResult('🗑️ 开始取消所有通知...');

      await _realNotificationService.cancelAllNotifications();

      _appendResult('✅ 所有通知已取消');
    } catch (e) {
      _appendResult('❌ 取消通知失败: $e');
    }
  }

  void _appendResult(String text) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _testResult += '[$timestamp] $text\n';
    });
    print(text); // 同时输出到控制台
  }
}
