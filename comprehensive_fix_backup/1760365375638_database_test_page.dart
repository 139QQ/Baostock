import 'package:flutter/material.dart';

import 'database_test_tool.dart';
import 'sql_server_config.dart';
import 'sql_server_manager.dart';

/// 数据库连接测试页面
///
/// 用于测试和验证SQL Server数据库连接功能
class DatabaseTestPage extends StatefulWidget {
  const DatabaseTestPage({super.key});

  @override
  State<DatabaseTestPage> createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  final DatabaseTestTool _testTool = DatabaseTestTool();
  Map<String, dynamic>? _testResults;
  bool _isTesting = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  /// 检查数据库连接状态
  Future<void> _checkConnection() async {
    try {
      final config = SqlServerConfig.development();
      final isConnected = await DatabaseTestTool.quickTest(config);

      if (mounted) {
        setState(() {
          _connectionStatus = isConnected ? '已连接' : '未连接';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = '连接错误: $e';
        });
      }
    }
  }

  /// 运行完整测试
  Future<void> _runFullTest() async {
    if (!mounted) return;

    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      final results = await _testTool.runFullTest();

      if (mounted) {
        setState(() {
          _testResults = results;
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResults = {
            'overall_status': 'error',
            'error': e.toString(),
          };
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库连接测试'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 连接状态显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '数据库连接状态',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _connectionStatus == '已连接'
                              ? Icons.check_circle
                              : _connectionStatus?.contains('错误') == true
                                  ? Icons.error
                                  : Icons.warning,
                          color: _connectionStatus == '已连接'
                              ? Colors.green
                              : _connectionStatus?.contains('错误') == true
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(_connectionStatus ?? '检测中...'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 连接配置信息
                    const Text(
                      '连接配置:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('服务器: 154.44.25.92:1433'),
                    const Text('数据库: JiSuDB'),
                    const Text('用户名: SA'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 测试按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _runFullTest,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isTesting ? '测试中...' : '运行完整测试'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 测试结果
            if (_testResults != null) ...[
              const Text(
                '测试结果:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 总体状态
                        Row(
                          children: [
                            Icon(
                              _testResults!['overall_status'] == 'success'
                                  ? Icons.check_circle
                                  : Icons.error,
                              color:
                                  _testResults!['overall_status'] == 'success'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '总体状态: ${_testResults!['overall_status']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_testResults!['test_duration'] != null)
                          Text('测试耗时: ${_testResults!['test_duration']}ms'),

                        const SizedBox(height: 16),

                        // 详细测试结果
                        const Text(
                          '详细测试结果:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        _buildTestResultItem('连接测试', 'connection_test'),
                        _buildTestResultItem('数据库信息', 'database_info_test'),
                        _buildTestResultItem('查询测试', 'query_test'),
                        _buildTestResultItem('插入测试', 'insert_test'),
                        _buildTestResultItem('事务测试', 'transaction_test'),
                        _buildTestResultItem('存储过程测试', 'procedure_test'),

                        if (_testResults!['error'] != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            '错误信息:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            _testResults!['error'],
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建测试结果项
  Widget _buildTestResultItem(String title, String testKey) {
    if (!_testResults!.containsKey(testKey)) {
      return const SizedBox.shrink();
    }

    final result = _testResults![testKey];
    final status = result['status'] ?? 'unknown';
    final message = result['message'] ?? '';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $message',
              style: TextStyle(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 清理测试数据
    _testTool.cleanupTestData();
    super.dispose();
  }
}

/// 数据库测试工具类
class DatabaseTestHelper {
  /// 快速测试数据库连接
  static Future<Map<String, dynamic>> quickTest() async {
    try {
      final config = SqlServerConfig.development();
      final isConnected = await DatabaseTestTool.quickTest(config);

      return {
        'connected': isConnected,
        'config': {
          'host': config.host,
          'port': config.port,
          'database': config.database,
          'username': config.username,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 获取数据库状态信息
  static Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      final manager = SqlServerManager.instance;
      final stats = manager.getConnectionStats();

      return {
        'connection_status': stats,
        'is_connected': manager.isConnected,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
