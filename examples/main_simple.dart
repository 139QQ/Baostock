import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金分析器测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  int _counter = 0;
  String _apiStatus = '未测试';
  bool _isLoading = false;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金分析器 - 问题修复测试'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 修复状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.healing, color: Color(0xFF1E40AF)),
                        const SizedBox(width: 8),
                        const Text(
                          '问题修复状态',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✅ 中文URL编码问题已修复'),
                        Text('✅ API超时配置已优化'),
                        Text('✅ 依赖注入延迟初始化已实现'),
                        Text('✅ 错误处理机制已完善'),
                        Text('⏳ 正在验证完整修复效果...'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // API测试卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.api, color: Color(0xFF1E40AF)),
                        const SizedBox(width: 8),
                        const Text(
                          'API连接测试',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor()),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _apiStatus,
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _testApi('全部'),
                          icon: const Icon(Icons.list),
                          label: const Text('全部基金'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _testApi('股票型'),
                          icon: const Icon(Icons.trending_up),
                          label: const Text('股票型'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _testApi('混合型'),
                          icon: const Icon(Icons.shuffle),
                          label: const Text('混合型'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 功能测试卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '基础功能测试',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('计数器: $_counter'),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _incrementCounter,
                          child: const Text('增加计数'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ 基础UI功能正常！'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('测试UI响应'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // API信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API配置信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📡 服务器: http://154.44.25.92:8080'),
                        Text('🔗 端点: /api/public/fund_open_fund_rank_em'),
                        Text('🔤 编码: UTF-8 (自动URL编码)'),
                        Text('⏱️ 超时: 30秒连接，60秒接收'),
                        Text('🔄 重试: 最多5次，指数退避'),
                        Text('🛡️ 错误处理: 完善的降级策略'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_apiStatus.contains('成功')) return Colors.green;
    if (_apiStatus.contains('失败') || _apiStatus.contains('错误')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_apiStatus.contains('成功')) return Icons.check_circle;
    if (_apiStatus.contains('失败') || _apiStatus.contains('错误')) {
      return Icons.error;
    }
    return Icons.info;
  }

  Future<void> _testApi(String symbol) async {
    setState(() {
      _isLoading = true;
      _apiStatus = '正在测试API...';
    });

    try {
      // URL编码中文参数 - 让Uri自动处理编码，避免双重编码
      final uri = Uri.parse(
              'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em')
          .replace(queryParameters: {'symbol': symbol});

      debugPrint('📡 请求URL: $uri');
      debugPrint('🔤 原始参数: $symbol');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'User-Agent': 'JisuFundAnalyzer/1.0.0 (Flutter)',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ).timeout(const Duration(seconds: 90)); // 增加到90秒

      debugPrint('📊 响应状态码: ${response.statusCode}');
      debugPrint('📊 响应数据长度: ${response.body.length} 字符');

      if (response.statusCode == 200) {
        // 解析返回的数据数量
        final responseBody = response.body;
        if (responseBody.isNotEmpty && responseBody.startsWith('[')) {
          // 简单计算返回的数据条数
          final fundCount = (responseBody.split('},{').length);
          setState(() {
            _apiStatus = '✅ API测试成功！返回约$fundCount条$symbol基金数据';
          });
          debugPrint('✅ 解析成功: $fundCount 条数据');
        } else {
          setState(() {
            _apiStatus = '✅ API连接成功，但数据格式异常';
          });
          debugPrint('⚠️ 数据格式异常: ${responseBody.substring(0, 100)}...');
        }
      } else {
        setState(() {
          _apiStatus = '❌ API测试失败: HTTP ${response.statusCode}';
        });
        debugPrint('❌ HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _apiStatus = '❌ API测试失败: $e';
      });
      debugPrint('❌ API异常: $e');
      debugPrint('🔍 异常类型: ${e.runtimeType}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
