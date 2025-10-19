import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// 简化的刷新功能测试应用
void main() {
  runApp(const RefreshTestApp());
}

class RefreshTestApp extends StatelessWidget {
  const RefreshTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '刷新功能测试',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RefreshTestPage(),
    );
  }
}

class RefreshTestPage extends StatefulWidget {
  const RefreshTestPage({super.key});

  @override
  State<RefreshTestPage> createState() => _RefreshTestPageState();
}

class _RefreshTestPageState extends State<RefreshTestPage> {
  String _log = '等待操作...\n';
  bool _isLoading = false;
  List<dynamic> _funds = [];

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _log += '[$timestamp] $message\n';
    });
  }

  /// 直接调用API测试刷新功能
  Future<void> _testDirectApiCall() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });
    _addLog('🔄 开始API调用测试');

    try {
      _addLog('📡 构建请求URL');
      const baseUrl = 'http://154.44.25.92:8080';
      const symbol = '全部';

      // 重要：不要手动编码中文，让Uri自动处理
      final uri = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em')
          .replace(queryParameters: {'symbol': symbol});

      _addLog('📡 请求URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'User-Agent': 'RefreshTestApp/1.0.0',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 90));

      _addLog('📊 响应状态: ${response.statusCode}');
      _addLog('📊 响应大小: ${response.body.length} 字符');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _funds = data.take(10).toList(); // 只显示前10条
        });
        _addLog('✅ API调用成功: 获取${data.length}条数据');
        _addLog('📊 前3条数据:');
        for (int i = 0; i < math.min(3, data.length); i++) {
          final fund = data[i];
          _addLog('  - ${fund['基金简称']} (${fund['基金代码']})');
        }
      } else {
        _addLog('❌ API错误: ${response.statusCode} ${response.reasonPhrase}');
        _addLog(
            '❌ 响应内容: ${response.body.substring(0, math.min(200, response.body.length))}...');
      }
    } catch (e) {
      _addLog('❌ API调用异常: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试多次快速刷新
  Future<void> _testMultipleRefresh() async {
    _addLog('🔄 开始多次刷新测试');

    for (int i = 1; i <= 3; i++) {
      _addLog('--- 第${i}次刷新 ---');
      await _testDirectApiCall();
      await Future.delayed(const Duration(seconds: 1)); // 间隔1秒
    }

    _addLog('✅ 多次刷新测试完成');
  }

  /// 测试缓存控制
  Future<void> _testCacheControl() async {
    _addLog('🔄 开始缓存控制测试');

    // 第一次调用（应该使用缓存）
    _addLog('--- 第一次调用（无缓存控制） ---');
    await _testDirectApiCall();

    await Future.delayed(const Duration(seconds: 2));

    // 第二次调用（禁用缓存）
    _addLog('--- 第二次调用（禁用缓存） ---');
    await _testDirectApiCall();

    _addLog('✅ 缓存控制测试完成');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('刷新功能测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 状态显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'API状态',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isLoading ? '加载中' : '就绪',
                            style: TextStyle(
                              color: _isLoading
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '基金数据: ${_funds.length}条',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 操作按钮
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '测试操作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testDirectApiCall,
                          child: const Text('单次API调用'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testMultipleRefresh,
                          child: const Text('多次刷新测试'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testCacheControl,
                          child: const Text('缓存控制测试'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 基金数据预览
            if (_funds.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '基金数据预览',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _funds.length,
                          itemBuilder: (context, index) {
                            final fund = _funds[index];
                            return ListTile(
                              title: Text(fund['基金简称'] ?? '未知'),
                              subtitle:
                                  Text('${fund['基金代码']} · ${fund['基金类型']}'),
                              trailing: Text(
                                '${fund['日增长率']}%',
                                style: TextStyle(
                                  color: (fund['日增长率'] ?? '')
                                          .toString()
                                          .contains('-')
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 日志输出
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '调试日志',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _log = '日志已清空\n';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            tooltip: '清空日志',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _log,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
