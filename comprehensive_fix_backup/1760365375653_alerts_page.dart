import 'package:flutter/material.dart';

/// 行情预警页面
///
/// 提供价格提醒设置和管理功能：
/// - 价格预警设置
/// - 涨跌幅度提醒
/// - 成交量预警
/// - 预警历史记录
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('行情预警'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Center(
        child: Text('行情预警功能开发中...'),
      ),
    );
  }
}
