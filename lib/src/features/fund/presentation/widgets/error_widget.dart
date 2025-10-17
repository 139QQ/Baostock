import 'package:flutter/material.dart';

/// 排行榜错误组件
///
/// 显示排行榜加载错误的各种状态
class RankingErrorWidget extends StatelessWidget {
  /// 错误信息
  final String error;

  /// 是否为网络错误
  final bool isNetworkError;

  /// 是否为数据错误
  final bool isDataError;

  /// 重试次数
  final int retryCount;

  /// 重试回调
  final VoidCallback onRetry;

  /// 自定义错误图标
  final IconData? errorIcon;

  /// 自定义错误颜色
  final Color? errorColor;

  const RankingErrorWidget({
    super.key,
    required this.error,
    this.isNetworkError = false,
    this.isDataError = false,
    this.retryCount = 0,
    required this.onRetry,
    this.errorIcon,
    this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 错误图标
            _buildErrorIcon(context),

            const SizedBox(height: 16),

            // 错误标题
            _buildErrorTitle(context),

            const SizedBox(height: 8),

            // 错误描述
            _buildErrorMessage(context),

            const SizedBox(height: 16),

            // 错误详情
            if (retryCount > 0) _buildRetryInfo(context),

            const SizedBox(height: 24),

            // 操作按钮
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// 构建错误图标
  Widget _buildErrorIcon(BuildContext context) {
    final icon = errorIcon ?? _getErrorIcon();
    final color = errorColor ?? _getErrorColor(context);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  /// 构建错误标题
  Widget _buildErrorTitle(BuildContext context) {
    final title = _getErrorTitle();

    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _getErrorColor(context),
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 构建错误描述
  Widget _buildErrorMessage(BuildContext context) {
    final message = _getErrorMessage();

    return Column(
      children: [
        Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          error,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 构建重试信息
  Widget _buildRetryInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '已重试 $retryCount 次',
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange[700],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // 主要操作按钮
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('重新加载'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 辅助操作按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () {
                // 返回上一页
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('返回'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // 查看错误详情
                _showErrorDetails(context);
              },
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('详情'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 获取错误图标
  IconData _getErrorIcon() {
    if (isNetworkError) {
      return Icons.wifi_off;
    } else if (isDataError) {
      return Icons.data_array;
    } else {
      return Icons.error_outline;
    }
  }

  /// 获取错误颜色
  Color _getErrorColor(BuildContext context) {
    if (isNetworkError) {
      return Colors.orange;
    } else if (isDataError) {
      return Colors.red;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  /// 获取错误标题
  String _getErrorTitle() {
    if (isNetworkError) {
      return '网络连接失败';
    } else if (isDataError) {
      return '数据解析错误';
    } else {
      return '加载失败';
    }
  }

  /// 获取错误描述
  String _getErrorMessage() {
    if (isNetworkError) {
      return '请检查网络连接或稍后重试';
    } else if (isDataError) {
      return '数据格式异常，正在修复中';
    } else {
      return '发生未知错误，请重试';
    }
  }

  /// 显示错误详情
  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('错误类型: ${_getErrorTypeName()}'),
            const SizedBox(height: 8),
            Text('重试次数: $retryCount'),
            const SizedBox(height: 8),
            const Text('错误信息:'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 获取错误类型名称
  String _getErrorTypeName() {
    if (isNetworkError) {
      return '网络错误';
    } else if (isDataError) {
      return '数据错误';
    } else {
      return '未知错误';
    }
  }
}

/// 空状态错误组件
class EmptyStateErrorWidget extends StatelessWidget {
  /// 标题
  final String title;

  /// 描述
  final String description;

  /// 操作按钮文本
  final String? actionText;

  /// 操作回调
  final VoidCallback? onAction;

  /// 图标
  final IconData? icon;

  const EmptyStateErrorWidget({
    super.key,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 网络错误组件
class NetworkErrorWidget extends StatelessWidget {
  /// 错误信息
  final String error;

  /// 重试回调
  final VoidCallback onRetry;

  const NetworkErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return RankingErrorWidget(
      error: error,
      isNetworkError: true,
      onRetry: onRetry,
    );
  }
}

/// 数据错误组件
class DataErrorWidget extends StatelessWidget {
  /// 错误信息
  final String error;

  /// 重试回调
  final VoidCallback onRetry;

  const DataErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return RankingErrorWidget(
      error: error,
      isDataError: true,
      onRetry: onRetry,
    );
  }
}
