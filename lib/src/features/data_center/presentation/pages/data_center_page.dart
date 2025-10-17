import 'package:flutter/material.dart';

/// 数据中心页面
///
/// 提供深度市场数据和基金分析：
/// - 实时行情数据
/// - 历史数据查询
/// - 基金评级数据
/// - 市场指数数据
class DataCenterPage extends StatelessWidget {
  const DataCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据中心'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: const Center(
        child: Text('数据中心功能开发中...'),
      ),
    );
  }
}
