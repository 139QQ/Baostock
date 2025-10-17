/// 图表组件独立测试应用
///
/// 用于测试真实基金数据图表功能的独立应用
library chart_test_app;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 导入我们的图表组件
import 'lib/src/shared/widgets/charts/examples/real_fund_chart_example.dart';
import 'lib/src/shared/widgets/charts/chart_di_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化图表依赖注入
  await ChartDIContainer.initialize();

  runApp(const ChartTestApp());
}

class ChartTestApp extends StatelessWidget {
  const ChartTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '真实基金数据图表测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChartTestHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChartTestHomePage extends StatelessWidget {
  const ChartTestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图表组件测试'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '图表组件测试应用',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '此应用用于测试真实基金数据图表功能',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFeatureCard(
              context,
              title: '真实基金数据图表',
              description: '展示单只基金的净值走势图',
              icon: Icons.show_chart,
              color: Colors.blue,
              onTap: () =>
                  _navigateToChart(context, const RealFundChartExample()),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              title: '功能特性',
              description:
                  '• 连接到真实API (154.44.25.92:8080)\n• 支持多种基金类型和指标\n• 交互式图表控制面板\n• 错误处理和降级机制',
              icon: Icons.info_outline,
              color: Colors.green,
              onTap: () => _showFeatureInfo(context),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              title: '数据源说明',
              description:
                  '• 基金基本信息API\n• 基金净值历史API\n• 基金排行榜API\n• 支持股票型、混合型、债券型等',
              icon: Icons.api,
              color: Colors.orange,
              onTap: () => _showApiInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToChart(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showFeatureInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('功能特性'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅ 连接到真实API服务器'),
              SizedBox(height: 8),
              Text('✅ 支持多种基金类型选择'),
              SizedBox(height: 8),
              Text('✅ 支持多种指标类型（单位净值、累计净值）'),
              SizedBox(height: 8),
              Text('✅ 交互式控制面板'),
              SizedBox(height: 8),
              Text('✅ 实时数据刷新'),
              SizedBox(height: 8),
              Text('✅ 错误处理和重试机制'),
              SizedBox(height: 8),
              Text('✅ 响应式设计'),
              SizedBox(height: 8),
              Text('✅ 数据统计信息展示'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showApiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API数据源'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🌐 API服务器: http://154.44.25.92:8080'),
              SizedBox(height: 12),
              Text('📊 支持的API端点:'),
              SizedBox(height: 8),
              Text('• /api/public/fund_name_em - 基金基本信息'),
              SizedBox(height: 4),
              Text('• /api/public/fund_open_fund_info_em - 基金净值信息'),
              SizedBox(height: 4),
              Text('• /api/public/fund_open_fund_rank_em - 基金排行榜'),
              SizedBox(height: 4),
              Text('• /api/public/fund_open_fund_daily_em - 基金实时行情'),
              SizedBox(height: 12),
              Text('🏷️ 支持的基金类型:'),
              SizedBox(height: 8),
              Text('• 全部、股票型、混合型、债券型'),
              SizedBox(height: 4),
              Text('• 指数型、QDII、ETF'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
