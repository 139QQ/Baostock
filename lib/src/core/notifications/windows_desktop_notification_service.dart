import 'dart:io';

import '../utils/logger.dart';

/// Windows桌面通知服务
///
/// 为Windows平台提供原生的桌面通知功能
/// 使用Windows Toast Notification API
class WindowsDesktopNotificationService {
  // 私有构造函数，确保单例模式
  WindowsDesktopNotificationService._();

  /// 单例实例
  static final WindowsDesktopNotificationService _instance =
      WindowsDesktopNotificationService._();
  static WindowsDesktopNotificationService get instance => _instance;

  bool _isInitialized = false;

  /// 初始化Windows桌面通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!Platform.isWindows) {
        AppLogger.warn('⚠️ Windows桌面通知服务只能在Windows平台上使用');
        return;
      }

      AppLogger.info('🔔 初始化Windows桌面通知服务');

      // 在Windows上，我们使用系统Toast通知
      // 这里可以进行必要的初始化工作
      _isInitialized = true;
      AppLogger.info('✅ Windows桌面通知服务初始化完成');
    } catch (e) {
      AppLogger.error('❌ Windows桌面通知服务初始化失败', e);
      rethrow;
    }
  }

  /// 发送Windows桌面通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? iconPath,
    NotificationPriority priority = NotificationPriority.normal,
    String? type,
    Map<String, dynamic>? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      AppLogger.info('📱 发送Windows桌面通知: $title');

      // 检查是否在Windows上
      if (!Platform.isWindows) {
        AppLogger.warn('⚠️ 当前不是Windows平台，跳过桌面通知');
        return;
      }

      // 使用PowerShell命令发送Windows Toast通知
      await _sendWindowsToastNotification(
        title: title,
        body: body,
        iconPath: iconPath,
        priority: priority,
        type: type,
        payload: payload,
      );

      AppLogger.info('✅ Windows桌面通知发送成功: $title');
    } catch (e) {
      AppLogger.error('❌ 发送Windows桌面通知失败', e);
      rethrow;
    }
  }

  /// 发送测试通知
  Future<void> sendTestNotification() async {
    await showNotification(
      title: '🧪 Windows桌面通知测试',
      body:
          '这是一条来自基速基金分析平台的Windows桌面通知\n时间: ${DateTime.now().toString().substring(11, 19)}',
      priority: NotificationPriority.normal,
      type: 'test_notification',
      payload: {
        'platform': 'windows',
        'type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送基金价格提醒通知
  Future<void> sendFundPriceAlert({
    required String fundCode,
    required String fundName,
    required double currentPrice,
    required double priceChange,
    required double changePercent,
  }) async {
    final String changeEmoji = priceChange >= 0 ? '📈' : '📉';
    final String changeText = priceChange >= 0 ? '上涨' : '下跌';

    final String title = '$changeEmoji $fundName 价格提醒';
    final String body = '基金代码: $fundCode\n'
        '当前价格: ¥${currentPrice.toStringAsFixed(4)}\n'
        '变化: ¥${priceChange.abs().toStringAsFixed(4)} ($changeText ${changePercent.abs().toStringAsFixed(2)}%)';

    await showNotification(
      title: title,
      body: body,
      priority: priceChange >= 0
          ? NotificationPriority.high
          : NotificationPriority.normal,
      type: 'fund_price_alert',
      payload: {
        'fundCode': fundCode,
        'fundName': fundName,
        'currentPrice': currentPrice,
        'priceChange': priceChange,
        'changePercent': changePercent,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送市场新闻通知
  Future<void> sendMarketNews({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    await showNotification(
      title: title,
      body: content,
      priority: NotificationPriority.normal,
      type: 'market_news',
      payload: {
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送交易信号通知
  Future<void> sendTradeSignal({
    required String fundCode,
    required String fundName,
    required String signalType,
    required String reason,
    required double targetPrice,
    required double currentPrice,
  }) async {
    final String emoji = signalType == 'buy' ? '🟢' : '🔴';
    final String action = signalType == 'buy' ? '买入' : '卖出';

    final String title = '$emoji $fundName $action信号';
    final String body = '基金代码: $fundCode\n'
        '信号类型: $action\n'
        '当前价格: ¥${currentPrice.toStringAsFixed(4)}\n'
        '目标价格: ¥${targetPrice.toStringAsFixed(4)}\n'
        '触发原因: $reason';

    await showNotification(
      title: title,
      body: body,
      priority: NotificationPriority.high,
      type: 'trade_signal',
      payload: {
        'fundCode': fundCode,
        'fundName': fundName,
        'signalType': signalType,
        'reason': reason,
        'targetPrice': targetPrice,
        'currentPrice': currentPrice,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送投资组合建议通知
  Future<void> sendPortfolioSuggestion({
    required String suggestionType,
    required String description,
    required List<String> recommendedFunds,
  }) async {
    const String title = '💡 投资组合建议';
    final String body = '建议类型: $suggestionType\n'
        '描述: $description\n'
        '推荐基金: ${recommendedFunds.join(', ')}';

    await showNotification(
      title: title,
      body: body,
      priority: NotificationPriority.low,
      type: 'portfolio_suggestion',
      payload: {
        'suggestionType': suggestionType,
        'description': description,
        'recommendedFunds': recommendedFunds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 使用PowerShell发送Windows Toast通知
  Future<void> _sendWindowsToastNotification({
    required String title,
    required String body,
    String? iconPath,
    required NotificationPriority priority,
    String? type,
    Map<String, dynamic>? payload,
  }) async {
    try {
      // 构建更安全的PowerShell脚本，使用更兼容的方式
      final escapedTitle = _escapePowerShellString(title);
      final escapedBody = _escapePowerShellString(body);

      final script = '''
# 尝试多种通知方法
try {
    # 方法1: 尝试使用Windows Runtime API (Windows 10/11)
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null

        \$xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
        \$template = @"
<toast duration="short" scenario="default">
    <visual>
        <binding template="ToastGeneric">
            <text id="1">$escapedTitle</text>
            <text id="2">$escapedBody</text>
            <text placement="attribution">基速基金分析平台</text>
        </binding>
    </visual>
</toast>
"@

        \$xml.LoadXml(\$template)
        \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)

        # 尝试获取通知器
        try {
            \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("基速基金分析平台")
            \$notifier.Show(\$toast)
            Write-Host "Toast notification sent via Windows Runtime API"
            exit 0
        } catch {
            Write-Host "Failed to create toast notifier"
        }
    } catch {
        Write-Host "Windows Runtime API not available"
    }

    # 方法2: 使用BalloonTip作为备用方案
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        # 创建系统托盘图标
        \$notification = New-Object System.Windows.Forms.NotifyIcon
        \$notification.Icon = [System.Drawing.SystemIcons]::Information
        \$notification.BalloonTipTitle = "$escapedTitle"
        \$notification.BalloonTipText = "$escapedBody"
        \$notification.Visible = \$true

        # 显示通知
        \$notification.ShowBalloonTip(10000)

        # 等待用户交互
        Start-Sleep -Milliseconds 11000

        # 清理资源
        \$notification.Dispose()

        Write-Host "BalloonTip notification sent successfully"
        exit 0
    } catch {
        Write-Host "BalloonTip failed"
    }

    # 方法3: 最后的备用方案 - 使用消息框
    try {
        Add-Type -AssemblyName System.Windows.Forms

        [System.Windows.Forms.MessageBox]::Show(
            "$escapedBody",
            "$escapedTitle",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        Write-Host "MessageBox notification displayed"
        exit 0
    } catch {
        Write-Host "MessageBox failed"
        exit 1
    }

} catch {
    Write-Host "All notification methods failed"
    exit 1
}
''';

      // 执行PowerShell命令
      final result = await Process.run('powershell', [
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-Command',
        script
      ]);

      if (result.exitCode != 0) {
        AppLogger.warn('PowerShell执行返回非零退出代码: ${result.exitCode}');
        AppLogger.debug('PowerShell错误输出: ${result.stderr}');
        AppLogger.debug('PowerShell标准输出: ${result.stdout}');

        // 如果Toast通知失败，尝试使用简单的备用方案
        await _sendFallbackNotification(title, body);
      } else {
        AppLogger.debug('PowerShell通知发送成功');
        AppLogger.debug('PowerShell输出: ${result.stdout}');
      }
    } catch (e) {
      AppLogger.error('执行PowerShell命令失败', e);
      // 尝试备用通知方案
      await _sendFallbackNotification(title, body);
    }
  }

  /// 备用通知方案（使用系统消息框）
  Future<void> _sendFallbackNotification(String title, String body) async {
    try {
      AppLogger.info('🔄 使用备用通知方案');

      final fallbackScript = '''
Add-Type -AssemblyName System.Windows.Forms
\$form = New-Object System.Windows.Forms.Form
\$form.Text = "$title"
\$form.Size = New-Object System.Drawing.Size(400,200)
\$form.StartPosition = "CenterScreen"
\$form.TopMost = \$true

\$label = New-Object System.Windows.Forms.Label
\$label.Text = "$body"
\$label.AutoSize = \$false
\$label.Size = New-Object System.Drawing.Size(380,100)
\$label.Location = New-Object System.Drawing.Point(10,20)
\$label.TextAlign = "MiddleLeft"

\$button = New-Object System.Windows.Forms.Button
\$button.Text = "确定"
\$button.Size = New-Object System.Drawing.Size(80,30)
\$button.Location = New-Object System.Drawing.Point(160,130)
\$button.Add_Click({\$form.Close()})

\$form.Controls.Add(\$label)
\$form.Controls.Add(\$button)
\$form.ShowDialog()
''';

      await Process.run('powershell', [
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-Command',
        fallbackScript
      ]);

      AppLogger.info('✅ 备用通知已发送');
    } catch (e) {
      AppLogger.error('❌ 备用通知方案也失败', e);
      // 最后的备用方案：至少记录到日志
      AppLogger.info('🔔 ========== 通知详情 ==========');
      AppLogger.info('📰 标题: $title');
      AppLogger.info('📝 内容: $body');
      AppLogger.info('⏰ 时间: ${DateTime.now().toString().substring(0, 19)}');
      AppLogger.info('🔔 ===============================');
    }
  }

  /// 转义PowerShell字符串中的特殊字符
  String _escapePowerShellString(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('"', '`"') // 使用PowerShell的转义字符
        .replaceAll("'", r"''")
        .replaceAll('\$', '`\$')
        .replaceAll('`', '``')
        .replaceAll('\n', '`n')
        .replaceAll('\r', '`r')
        .replaceAll('\t', '`t')
        .replaceAll('#', '`#')
        .replaceAll('@', '`@')
        .replaceAll('(', '`(')
        .replaceAll(')', '`)')
        .replaceAll('{', '`{')
        .replaceAll('}', '`}')
        .replaceAll('[', '`[')
        .replaceAll(']', '`]')
        .replaceAll('|', '`|')
        .replaceAll('&', '`&')
        .replaceAll(';', '`;');
  }

  /// 获取Windows通知支持状态
  Future<bool> isWindowsNotificationSupported() async {
    if (!Platform.isWindows) return false;

    try {
      // 检查Windows版本是否支持Toast通知
      final result = await Process.run('powershell', [
        '-Command',
        '[System.Environment]::OSVersion.Version -ge 10.0.10240'
      ]);
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error('检查Windows通知支持失败', e);
      return false;
    }
  }

  /// 获取通知权限状态详情
  Future<Map<String, dynamic>> getNotificationPermissionDetails() async {
    try {
      final isSupported = await isWindowsNotificationSupported();

      return {
        'platform': 'Windows',
        'isSupported': isSupported,
        'isInitialized': _isInitialized,
        'osVersion': Platform.operatingSystemVersion,
        'isWindows': Platform.isWindows,
      };
    } catch (e) {
      AppLogger.error('获取Windows通知权限详情失败', e);
      return {
        'platform': 'Windows',
        'isSupported': false,
        'isInitialized': _isInitialized,
        'error': e.toString(),
      };
    }
  }
}

/// 通知优先级枚举
enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}
