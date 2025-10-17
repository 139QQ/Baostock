import 'package:flutter/material.dart';
import 'lib/src/services/improved_fund_api_service.dart';

/// 服务集成测试应用
void main() {
  runApp(const ServiceIntegrationTestApp());
}

class ServiceIntegrationTestApp extends StatelessWidget {
  const ServiceIntegrationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '服务集成测试',
      home: const ServiceTestPage(),
    );
  }
}

class ServiceTestPage extends StatefulWidget {
  const ServiceTestPage({super.key});

  @override
  State<ServiceTestPage> createState() => _ServiceTestPageState();
}

class _ServiceTestPageState extends State<ServiceTestPage> {
  List<Map<String, dynamic>> _testResults = [];
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金服务集成测试'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 测试按钮
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _runTests,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isTesting ? '测试中...' : '开始测试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // 测试结果
            Expanded(
              child: _testResults.isEmpty
                  ? const Center(
                      child: Text(
                        '点击"开始测试"来验证基金服务集成',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      result['success'] == true
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color: result['success'] == true
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        result['testName'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  result['message'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (result['details'] != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      result['details'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    try {
      // 测试1: 改进版API服务基础功能
      await _testImprovedApiService();

      // 测试2: 不同基金类型请求
      await _testDifferentFundTypes();

      // 测试3: UTF-8编码验证
      await _testEncoding();
    } catch (e) {
      _addTestResult(
        testName: '测试异常',
        success: false,
        message: '测试过程中发生异常: $e',
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testImprovedApiService() async {
    try {
      final stopwatch = Stopwatch()..start();

      final funds = await ImprovedFundApiService.getFundRanking(symbol: '全部');

      stopwatch.stop();

      _addTestResult(
        testName: '改进版API服务基础功能',
        success: true,
        message:
            '成功获取 ${funds.length} 条基金数据，耗时: ${stopwatch.elapsedMilliseconds}ms',
        details: '第一条数据: ${funds.isNotEmpty ? funds.first.fundName : "无数据"}',
      );
    } catch (e) {
      _addTestResult(
        testName: '改进版API服务基础功能',
        success: false,
        message: '请求失败: $e',
      );
    }
  }

  Future<void> _testDifferentFundTypes() async {
    final types = ['股票型', '混合型', '债券型'];

    for (final type in types) {
      try {
        final stopwatch = Stopwatch()..start();

        final funds = await ImprovedFundApiService.getFundRanking(symbol: type);

        stopwatch.stop();

        _addTestResult(
          testName: '基金类型测试 - $type',
          success: true,
          message:
              '成功获取 $type 基金 ${funds.length} 条，耗时: ${stopwatch.elapsedMilliseconds}ms',
        );
      } catch (e) {
        _addTestResult(
          testName: '基金类型测试 - $type',
          success: false,
          message: '请求失败: $e',
        );
      }
    }
  }

  Future<void> _testEncoding() async {
    try {
      final funds = await ImprovedFundApiService.getFundRanking(symbol: '全部');

      // 检查中文显示
      final hasChineseNames = funds.any((fund) =>
          fund.fundName.contains(RegExp(r'[\u4e00-\u9fa5]')) ||
          fund.company.contains(RegExp(r'[\u4e00-\u9fa5]')));

      _addTestResult(
        testName: 'UTF-8编码验证',
        success: hasChineseNames,
        message:
            hasChineseNames ? '✅ UTF-8编码正常，中文字符显示正确' : '⚠️ 未检测到中文字符，可能存在编码问题',
        details: hasChineseNames && funds.isNotEmpty
            ? '示例: ${funds.first.fundName} - ${funds.first.company}'
            : null,
      );
    } catch (e) {
      _addTestResult(
        testName: 'UTF-8编码验证',
        success: false,
        message: '编码测试失败: $e',
      );
    }
  }

  void _addTestResult({
    required String testName,
    required bool success,
    required String message,
    String? details,
  }) {
    setState(() {
      _testResults.add({
        'testName': testName,
        'success': success,
        'message': message,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }
}
