import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../cubits/push_notification_cubit.dart';
import '../../data/models/push_history_record.dart';
import '../../data/managers/push_history_manager.dart';
import '../../../../core/di/di_initializer.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/notifications/real_flutter_notification_service.dart';
import '../../../../core/notifications/windows_desktop_notification_service.dart';

// 推送优先级枚举
enum NotificationPriority {
  critical,
  high,
  medium,
  low,
}

// 推送类型枚举
enum NotificationType {
  marketAlert,
  fundUpdate,
  systemAnnouncement,
  portfolioSuggestion,
}

/// 通知功能测试组件
/// 用于测试和验证推送通知的实际显示功能
class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  late PushHistoryManager _pushManager;
  final List<PushHistoryRecord> _createdNotifications = [];
  bool _isCreatingNotification = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    try {
      _pushManager = sl<PushHistoryManager>();
    } catch (e) {
      // 如果PushHistoryManager未注册，则创建实例
      _pushManager = PushHistoryManager.instance;
    }
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      final status = await Permission.notification.status;
      if (mounted) {
        setState(() {
          _testResult = '🔔 通知权限状态: ${_getPermissionStatusText(status)}\n'
              '点击下方按钮测试通知功能';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '❌ 权限检查失败: $e';
        });
      }
    }
  }

  String _getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '✅ 已授权';
      case PermissionStatus.denied:
        return '❌ 已拒绝';
      case PermissionStatus.restricted:
        return '⚠️ 受限制';
      case PermissionStatus.limited:
        return '🔄 部分授权';
      case PermissionStatus.permanentlyDenied:
        return '🚫 永久拒绝';
      case PermissionStatus.provisional:
        return '📋 临时授权';
    }
  }

  /// 测试本地通知显示
  Future<void> _testLocalNotification() async {
    if (mounted) {
      setState(() {
        _isCreatingNotification = true;
        _testResult = '🔄 正在创建本地通知...';
      });
    }

    try {
      // 检查权限
      final hasPermission = await Permission.notification.request().isGranted;

      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _testResult = '❌ 通知权限被拒绝，无法显示通知';
            _isCreatingNotification = false;
          });
        }
        return;
      }

      // 创建推送记录
      final notification = PushHistoryRecord(
        id: 'local_test_${DateTime.now().millisecondsSinceEpoch}',
        pushType: NotificationType.systemAnnouncement.name,
        priority: NotificationPriority.medium.name,
        title: '🧪 本地通知测试',
        content:
            '这是一条测试通知，用于验证通知显示功能。\n时间: ${DateTime.now().toString().substring(11, 19)}',
        timestamp: DateTime.now(),
        isRead: false,
        isClicked: false,
        deliverySuccess: true,
        relatedEventIds: [],
        relatedFundCodes: [],
        relatedIndexCodes: [],
        channel: 'notification',
        personalizationScore: 0.8,
        effectivenessScore: 0.0,
        processingTimeMs: 50,
        networkStatus: 'wifi',
        userActivityState: 'active',
        deviceInfo: {'platform': 'android'},
        metadata: {'test': true},
      );

      // 保存到历史记录 - 使用正确的方法签名
      await _pushManager.recordPushFailure(
        id: notification.id,
        pushType: notification.pushType,
        priority: notification.priority,
        title: notification.title,
        content: notification.content,
        failureReason: 'TEST_SUCCESS', // 测试成功标记
        channel: notification.channel,
        processingTimeMs: notification.processingTimeMs,
        metadata: notification.metadata,
      );

      // 显示系统通知 (简化版本)
      await _showSystemNotification(notification);

      if (mounted) {
        setState(() {
          _createdNotifications.add(notification);
          _testResult = '✅ 通知创建成功！\n'
              '标题: ${notification.title}\n'
              '内容: ${notification.content.length > 50 ? notification.content.substring(0, 50) : notification.content}\n'
              '请检查系统通知栏';
          _isCreatingNotification = false;
        });
      }
    } catch (e) {
      AppLogger.error('创建通知失败', e);
      if (mounted) {
        setState(() {
          _testResult = '❌ 创建通知失败: $e';
          _isCreatingNotification = false;
        });
      }
    }
  }

  /// 显示系统通知
  Future<void> _showSystemNotification(PushHistoryRecord record) async {
    try {
      AppLogger.info('📱 发送系统通知: ${record.title}');

      // 根据平台选择合适的通知服务
      if (Platform.isWindows) {
        // 使用Windows桌面通知服务
        final windowsService = WindowsDesktopNotificationService.instance;

        // 转换通知类型
        _convertPriority(record.priority);

        switch (record.pushType) {
          case 'systemAnnouncement':
            await windowsService.sendTestNotification();
            break;
          case 'marketAlert':
            await windowsService.sendMarketNews(
              title: record.title,
              content: record.content,
            );
            break;
          case 'fundUpdate':
            await windowsService.sendFundPriceAlert(
              fundCode: '000001',
              fundName: '华夏成长混合',
              currentPrice: 2.3456,
              priceChange: 0.0123,
              changePercent: 0.52,
            );
            break;
          default:
            await windowsService.sendTestNotification();
        }

        _showSuccessSnackBar(record, 'Windows桌面通知');
      } else {
        // 移动平台使用Flutter通知服务
        final notificationService = RealFlutterNotificationService.instance;

        // 根据通知类型发送不同的系统通知
        switch (record.pushType) {
          case 'systemAnnouncement':
            await notificationService.sendTestNotification();
            break;
          case 'marketAlert':
            // 模拟市场异动通知
            await notificationService.sendMarketNews(
              title: record.title,
              content: record.content,
            );
            break;
          case 'fundUpdate':
            // 模拟基金价格提醒
            await notificationService.sendFundPriceAlert(
              fundCode: '000001',
              fundName: '华夏成长混合',
              currentPrice: 2.3456,
              priceChange: 0.0123,
              changePercent: 0.52,
            );
            break;
          default:
            // 默认发送测试通知
            await notificationService.sendTestNotification();
        }

        _showSuccessSnackBar(record, '移动系统通知');
      }

      AppLogger.info('✅ 系统通知发送成功', 'Notification: ${record.title}');
    } catch (e) {
      AppLogger.error('显示系统通知失败', e);

      // 降级到SnackBar显示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 通知发送失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 显示成功提示SnackBar
  void _showSuccessSnackBar(PushHistoryRecord record, String platformType) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ $platformType已发送: ${record.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  '内容: ${record.content.length > 50 ? '${record.content.substring(0, 50)}...' : record.content}',
                  style: const TextStyle(fontSize: 12)),
              Text('请检查系统通知栏',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
              Text('平台: ${Platform.operatingSystem}',
                  style: TextStyle(fontSize: 10, color: Colors.white60)),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: _getPriorityColor(record.priority),
          action: SnackBarAction(
            label: '标记已读',
            onPressed: () => _markAsRead(record.id),
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  /// 转换通知优先级
  NotificationPriority _convertPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return NotificationPriority.critical;
      case 'high':
        return NotificationPriority.high;
      case 'medium':
      case 'normal':
        return NotificationPriority.medium;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.medium;
    }
  }

  /// 标记通知为已读
  Future<void> _markAsRead(String notificationId) async {
    try {
      await _pushManager.markAsRead(notificationId);

      // 检查组件是否仍然挂载
      if (mounted) {
        setState(() {
          // 移除或更新已读的通知
          _createdNotifications.removeWhere((n) => n.id == notificationId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 通知已标记为已读')),
        );
      }
    } catch (e) {
      AppLogger.error('标记通知已读失败', e);
      // 即使出错也只在组件挂载时显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 标记已读失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 测试不同优先级的通知
  Future<void> _testPriorityNotifications() async {
    final priorities = [
      NotificationPriority.critical,
      NotificationPriority.high,
      NotificationPriority.medium,
      NotificationPriority.low,
    ];

    for (int i = 0; i < priorities.length; i++) {
      final priority = priorities[i];
      final notification = PushHistoryRecord(
        id: 'priority_test_${i}_${DateTime.now().millisecondsSinceEpoch}',
        pushType: NotificationType.marketAlert.name,
        priority: priority.name,
        title: '🔔 ${priority.name.toUpperCase()} 优先级通知',
        content: '这是${priority.name}优先级的测试通知 #${i + 1}',
        timestamp: DateTime.now(),
        isRead: false,
        isClicked: false,
        deliverySuccess: true,
        relatedEventIds: [],
        relatedFundCodes: [],
        relatedIndexCodes: [],
        channel: 'notification',
        personalizationScore: 0.8,
        effectivenessScore: 0.0,
        processingTimeMs: 50,
        networkStatus: 'wifi',
        userActivityState: 'active',
        deviceInfo: {'platform': 'android'},
        metadata: {'test': true, 'priority_test': true},
      );

      await _pushManager.recordPushFailure(
        id: notification.id,
        pushType: notification.pushType,
        priority: notification.priority,
        title: notification.title,
        content: notification.content,
        failureReason: 'TEST_PRIORITY',
        channel: notification.channel,
        processingTimeMs: notification.processingTimeMs,
        metadata: notification.metadata,
      );
      await _showSystemNotification(notification);

      // 等待2秒再显示下一个
      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      setState(() {
        _testResult = '✅ 已发送4个不同优先级的测试通知！\n'
            '检查通知栏查看效果差异';
      });
    }
  }

  /// 测试市场异动通知
  Future<void> _testMarketAlertNotification() async {
    final notification = PushHistoryRecord(
      id: 'market_test_${DateTime.now().millisecondsSinceEpoch}',
      pushType: NotificationType.marketAlert.name,
      priority: NotificationPriority.high.name,
      title: '📈 市场异动提醒',
      content: '上证指数突破3500点，涨幅2.5%！成交量放大至2800亿。\n建议：关注大盘蓝筹股机会',
      timestamp: DateTime.now(),
      isRead: false,
      isClicked: false,
      deliverySuccess: true,
      relatedEventIds: ['market_001'],
      relatedFundCodes: [],
      relatedIndexCodes: ['SH000001'],
      channel: 'notification',
      personalizationScore: 0.9,
      effectivenessScore: 0.0,
      processingTimeMs: 75,
      networkStatus: 'wifi',
      userActivityState: 'active',
      deviceInfo: {'platform': 'android'},
      metadata: {'test': true, 'market_alert': true},
    );

    await _pushManager.recordPushFailure(
      id: notification.id,
      pushType: notification.pushType,
      priority: notification.priority,
      title: notification.title,
      content: notification.content,
      failureReason: 'TEST_MARKET_ALERT',
      channel: notification.channel,
      processingTimeMs: notification.processingTimeMs,
      metadata: notification.metadata,
    );
    await _showSystemNotification(notification);

    if (mounted) {
      setState(() {
        _testResult = '✅ 市场异动通知发送成功！\n'
            '这是高优先级的市场提醒通知';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 通知测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) {
          try {
            return sl<PushNotificationCubit>();
          } catch (e) {
            // 如果PushNotificationCubit未注册，创建临时实例
            AppLogger.warn('PushNotificationCubit未注册，创建临时实例', e);
            return PushNotificationCubit();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 状态卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '通知状态',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isCreatingNotification) ...[
                            const SizedBox(width: 16),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _testResult.isEmpty ? '准备测试通知功能...' : _testResult,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 测试按钮
              const Text(
                '🧪 测试操作',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isCreatingNotification ? null : _testLocalNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('测试通知'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCreatingNotification
                        ? null
                        : _testPriorityNotifications,
                    icon: const Icon(Icons.priority_high),
                    label: const Text('优先级测试'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCreatingNotification
                        ? null
                        : _testMarketAlertNotification,
                    icon: const Icon(Icons.trending_up),
                    label: const Text('市场提醒'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _checkNotificationPermissions,
                    icon: const Icon(Icons.security),
                    label: const Text('检查权限'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 通知历史
              if (_createdNotifications.isNotEmpty) ...[
                const Text(
                  '📋 最近创建的通知',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _createdNotifications.length,
                    itemBuilder: (context, index) {
                      final record = _createdNotifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getPriorityColor(record.priority),
                            child: Icon(
                              _getPriorityIcon(record.priority),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            record.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.content.length > 50
                                    ? '${record.content.substring(0, 50)}...'
                                    : record.content,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                record.ageDescription,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                record.priority.toUpperCase(),
                                style: TextStyle(
                                  color: _getPriorityColor(record.priority),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon:
                                    const Icon(Icons.mark_email_read, size: 16),
                                onPressed: () => _markAsRead(record.id),
                                tooltip: '标记已读',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无通知记录',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击上方按钮开始测试通知功能',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Icons.priority_high;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 通知功能说明'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('功能特性：'),
            SizedBox(height: 8),
            Text('• 本地通知模拟显示'),
            Text('• 不同优先级通知效果'),
            Text('• 市场异动提醒通知'),
            Text('• 通知历史记录管理'),
            Text('• 权限状态检查'),
            SizedBox(height: 12),
            Text('测试说明：'),
            SizedBox(height: 8),
            Text('• "测试通知" - 基础通知功能'),
            Text('• "优先级测试" - 4个不同优先级'),
            Text('• "市场提醒" - 模拟市场异动通知'),
            SizedBox(height: 12),
            Text('注意：Windows平台使用SnackBar模拟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
