import 'package:flutter/material.dart';

import 'lib/src/features/home/presentation/pages/dashboard_page.dart';
import 'lib/src/core/di/injection_container.dart' as di;

/// 演示应用入口
///
/// 展示修复后的 DashboardPage 功能，包括：
/// - 智能推荐轮播
/// - 市场指数展示
/// - 行情统计
/// - 热门板块
/// - 关注基金列表
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化依赖注入
  await di.initDependencies();

  runApp(const DashboardDemoApp());
}

class DashboardDemoApp extends StatelessWidget {
  const DashboardDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基速基金分析平台 - 演示',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: const DashboardDemoWrapper(),
    );
  }
}

class DashboardDemoWrapper extends StatefulWidget {
  const DashboardDemoWrapper({super.key});

  @override
  State<DashboardDemoWrapper> createState() => _DashboardDemoWrapperState();
}

class _DashboardDemoWrapperState extends State<DashboardDemoWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 应用标题栏
      appBar: AppBar(
        title: const Text(
          '基速基金量化分析平台',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 演示信息按钮
          IconButton(
            onPressed: _showDemoInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: '演示信息',
          ),
          const SizedBox(width: 8),
        ],
      ),

      // 主要内容区域
      body: const DashboardPage(),

      // 底部信息栏
      bottomNavigationBar: _buildDemoBottomBar(),
    );
  }

  /// 构建演示底部栏
  Widget _buildDemoBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 演示标识
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.desktop_windows,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '演示模式',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 功能说明
          Expanded(
            child: Text(
              '展示修复后的仪表板页面，包含智能推荐、市场指数、行情统计等功能',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 刷新按钮
          IconButton(
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('页面已刷新'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              Icons.refresh,
              size: 20,
              color: Colors.grey[600],
            ),
            tooltip: '刷新页面',
          ),
        ],
      ),
    );
  }

  /// 显示演示信息对话框
  void _showDemoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('演示信息'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection('修复内容', [
                '• 修复依赖注入方法错误 (getIt → sl)',
                '• 确保智能推荐服务正常工作',
                '• 所有分析警告已清除',
              ]),
              const SizedBox(height: 16),
              _buildInfoSection('功能特性', [
                '• 智能推荐轮播 (支持策略切换)',
                '• 市场指数实时展示',
                '• 今日行情统计分析',
                '• 热门板块动态展示',
                '• 关注基金水平滚动列表',
                '• 响应式布局适配',
              ]),
              const SizedBox(height: 16),
              _buildInfoSection('技术亮点', [
                '• Clean Architecture 架构',
                '• BLoC 状态管理模式',
                '• 依赖注入 (GetIt)',
                '• 统一缓存系统 (Hive)',
                '• 响应式UI设计',
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '所有修复已完成，代码可正常编译运行',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showFeatureHighlight();
            },
            child: const Text('功能导览'),
          ),
        ],
      ),
    );
  }

  /// 构建信息部分
  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 8),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
        )),
      ],
    );
  }

  /// 功能高亮导览
  void _showFeatureHighlight() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('功能导览：注意观察智能推荐轮播、市场指数卡片、响应式布局等特性'),
        duration: Duration(seconds: 5),
        backgroundColor: Colors.blue,
      ),
    );
  }
}