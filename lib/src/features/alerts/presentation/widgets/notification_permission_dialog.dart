import 'package:flutter/material.dart';

/// 通知权限请求对话框
///
/// 基于掘金文章的最佳实践设计
/// 提供友好的权限说明界面，提高用户授权率
class NotificationPermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGranted;
  final VoidCallback onDenied;
  final VoidCallback? onLater;
  final bool showLaterButton;

  const NotificationPermissionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onGranted,
    required this.onDenied,
    this.onLater,
    this.showLaterButton = false,
  });

  /// 显示标准的通知权限请求对话框
  static Future<bool> showStandardNotificationPermissionDialog(
    BuildContext context, {
    VoidCallback? onCustomAction,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 防止用户点击外部关闭
          builder: (context) => NotificationPermissionDialog(
            title: '开启通知权限',
            message: _buildStandardMessage(),
            onGranted: () => Navigator.pop(context, true),
            onDenied: () => Navigator.pop(context, false),
            onLater: onCustomAction != null
                ? () {
                    Navigator.pop(context, false);
                    onCustomAction();
                  }
                : () => Navigator.pop(context, false),
            showLaterButton: true,
          ),
        ) ??
        false;
  }

  /// 显示权限被永久拒绝后的引导对话框
  static Future<bool> showPermanentlyDeniedDialog(
    BuildContext context, {
    VoidCallback? openSettings,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.settings, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text('需要手动开启通知权限'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '检测到通知权限已被永久拒绝。',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '为了不错过重要的投资信息，请手动开启通知权限：',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingSteps(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '暂不开启',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                  openSettings?.call();
                },
                icon: const Icon(Icons.settings),
                label: const Text('去设置'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 显示权限被拒绝后的说明对话框
  static Future<bool> showPermissionDeniedDialog(
    BuildContext context, {
    VoidCallback? retryRequest,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text('通知权限说明'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '理解您对通知的谨慎态度。',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '基速基金分析承诺：\n'
                  '• 只发送与投资相关的重要通知\n'
                  '• 绝不发送垃圾信息或广告\n'
                  '• 您可以随时在设置中关闭通知',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '不再提醒',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  retryRequest?.call();
                },
                child: const Text('重新请求'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题区域
            _buildHeader(),
            const SizedBox(height: 20),

            // 内容区域
            _buildContent(),
            const SizedBox(height: 24),

            // 按钮区域
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.notifications_active,
            color: Colors.blue[700],
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 消息内容
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // 功能特性展示
        _buildFeatureList(),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': '📈', 'title': '基金价格变动提醒'},
      {'icon': '🎯', 'title': '重要买入/卖出信号'},
      {'icon': '📊', 'title': '市场重要变化通知'},
      {'icon': '💡', 'title': '个性化投资建议'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '开启通知权限后，您可以收到：',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ...features
              .map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          feature['icon']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (showLaterButton) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onLater,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '稍后再说',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: showLaterButton ? 1 : 2,
          child: ElevatedButton(
            onPressed: onGranted,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications, size: 18),
                const SizedBox(width: 8),
                Text(
                  '立即开启',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建标准消息内容
  static String _buildStandardMessage() {
    return '''
基速基金分析需要通知权限来及时为您推送重要的投资信息。

我们承诺只发送与投资相关的高价值内容，帮助您：
• 第一时间获取基金价格变动
• 及时收到重要的交易信号
• 掌握市场最新动态

您随时可以在设置中管理通知偏好或关闭通知。
''';
  }

  /// 构建设置步骤
  static Widget _buildSettingSteps() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 6),
              Text(
                '开启步骤：',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            '1. 打开手机"设置"',
            '2. 找到"应用管理"或"应用通知"',
            '3. 选择"基速基金分析"',
            '4. 开启"通知权限"',
          ]
              .map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 22),
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}

/// 简化版权限请求对话框
class SimpleNotificationPermissionDialog extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SimpleNotificationPermissionDialog({
    super.key,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('权限请求'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
