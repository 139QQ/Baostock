import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/services/android_permission_service.dart';
import '../../../../core/utils/logger.dart';

/// 权限请求对话框
class PermissionRequestDialog extends StatelessWidget {
  const PermissionRequestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('推送通知权限'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '为了及时向您推送重要的市场变化和基金更新信息，需要您授权以下权限：',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          _PermissionItem(
            icon: Icons.notifications,
            title: '通知权限',
            description: '接收推送通知，包括市场变化提醒和基金更新通知',
            required: true,
          ),
          SizedBox(height: 12),
          _PermissionItem(
            icon: Icons.battery_alert,
            title: '电池优化白名单',
            description: '确保应用在后台正常运行，不错过重要推送',
            required: true,
          ),
          SizedBox(height: 12),
          _PermissionItem(
            icon: Icons.watch_later,
            title: '精确闹钟权限',
            description: '提供更准确的推送时间，确保及时送达',
            required: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('暂不授权'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('立即授权'),
        ),
      ],
    );
  }
}

/// 权限项显示组件
class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.required,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: required
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: required
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (required) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '必需',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 权限设置建议对话框
class PermissionSettingsDialog extends StatelessWidget {
  const PermissionSettingsDialog({super.key, required this.missingPermissions});

  final List<Permission> missingPermissions;

  @override
  Widget build(BuildContext context) {
    final permissionService = AndroidPermissionService.instance;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('权限设置'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '以下权限需要您手动开启，请点击设置按钮前往系统设置：',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...missingPermissions.map((permission) => _MissingPermissionItem(
                icon: _getPermissionIcon(permission),
                title:
                    permissionService.getPermissionUserFriendlyName(permission),
                description:
                    permissionService.getPermissionDescription(permission),
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '开启这些权限可以为您提供更好的推送体验',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop(true);
            // 打开系统设置
            try {
              await permissionService.openAppSettings();
            } catch (e) {
              AppLogger.error('打开应用设置失败', e);
            }
          },
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('打开设置'),
        ),
      ],
    );
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return Icons.notifications;
      case Permission.ignoreBatteryOptimizations:
        return Icons.battery_alert;
      case Permission.systemAlertWindow:
        return Icons.picture_in_picture;
      case Permission.scheduleExactAlarm:
        return Icons.watch_later;
      default:
        return Icons.security;
    }
  }
}

/// 缺失权限项组件
class _MissingPermissionItem extends StatelessWidget {
  const _MissingPermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
