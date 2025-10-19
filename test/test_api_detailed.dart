import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DetailedApiTestApp());
}

class DetailedApiTestApp extends StatelessWidget {
  const DetailedApiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '详细API调试',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const DetailedApiTestPage(),
    );
  }
}

class DetailedApiTestPage extends StatefulWidget {
  const DetailedApiTestPage({super.key});

  @override
  State<DetailedApiTestPage> createState() => _DetailedApiTestPageState();
}

class _DetailedApiTestPageState extends State<DetailedApiTestPage> {
  String _detailedLog = '等待测试...\n';
  bool _isLoading = false;

  void _addToLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _detailedLog += '[$timestamp] $message\n';
    });
    debugPrint(message);
  }

  Future<void> _testDetailedApi(String symbol) async {
    setState(() {
      _isLoading = true;
      _detailedLog = '=== 开始测试 $symbol ===\n';
    });

    try {
      _addToLog('🔤 准备编码参数: "$symbol"');

      // 测试不同的编码方式
      final encodedSymbol = Uri.encodeComponent(symbol);
      _addToLog('✅ URL编码结果: "$encodedSymbol"');

      final uri = Uri.parse(
              'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em')
          .replace(queryParameters: {'symbol': symbol}); // 不要手动编码，让Uri自动处理

      _addToLog('📡 完整请求URL: $uri');
      _addToLog('🌐 开始HTTP请求...');

      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'User-Agent': 'DetailedApiTest/1.0.0',
          'Origin': '*',
          'Access-Control-Request-Method': 'GET',
        },
      ).timeout(const Duration(seconds: 120));

      stopwatch.stop();

      _addToLog('⏱️ 请求耗时: ${stopwatch.elapsed.inSeconds}秒');
      _addToLog('📊 HTTP状态码: ${response.statusCode}');
      _addToLog('📊 响应头: ${response.headers}');
      _addToLog('📊 响应大小: ${response.body.length} 字符');
      _addToLog(
          '📊 Content-Type: ${response.headers['content-type'] ?? '未指定'}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        _addToLog('✅ 请求成功!');

        if (responseBody.isNotEmpty) {
          _addToLog('📄 响应数据前100字符: ${responseBody.substring(0, 100)}...');

          if (responseBody.startsWith('[')) {
            final fundCount = responseBody.split('},{').length;
            _addToLog('📈 数据解析成功: 约$fundCount条基金记录');
          } else {
            _addToLog('⚠️ 数据格式异常: 不是JSON数组格式');
          }
        } else {
          _addToLog('⚠️ 响应数据为空');
        }
      } else {
        _addToLog('❌ HTTP错误: ${response.statusCode} ${response.reasonPhrase}');
        _addToLog('📄 错误响应: ${response.body}');
      }
    } catch (e) {
      _addToLog('💥 异常类型: ${e.runtimeType}');
      _addToLog('💥 异常信息: $e');

      if (e.toString().contains('TimeoutException')) {
        _addToLog('⏰ 请求超时: 尝试增加超时时间');
      } else if (e.toString().contains('SocketException')) {
        _addToLog('🔌 网络连接问题: 检查网络连接');
      } else if (e.toString().contains('404')) {
        _addToLog('🔍 404错误: API端点不存在');
      } else if (e.toString().contains('403')) {
        _addToLog('🚫 403错误: 访问被拒绝');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _addToLog('=== 测试完成 ===\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('详细API调试'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 测试按钮
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API测试',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _testDetailedApi('全部'),
                            child: const Text('测试全部'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _testDetailedApi('股票型'),
                            child: const Text('测试股票型'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _testDetailedApi('混合型'),
                            child: const Text('测试混合型'),
                          ),
                        ),
                      ],
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('正在测试中，请耐心等待...'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 详细日志
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
                            '详细日志',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _detailedLog = '日志已清空\n';
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
                              _detailedLog,
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
