import 'package:flutter/material.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';

/// 刷新按钮调试应用
void main() {
  runApp(const RefreshDebugApp());
}

class RefreshDebugApp extends StatelessWidget {
  const RefreshDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '刷新按钮调试',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RefreshDebugPage(),
    );
  }
}

class RefreshDebugPage extends StatefulWidget {
  const RefreshDebugPage({super.key});

  @override
  State<RefreshDebugPage> createState() => _RefreshDebugPageState();
}

class _RefreshDebugPageState extends State<RefreshDebugPage> {
  String _log = '等待操作...\n';
  FundExplorationCubit? _cubit;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('🔧 初始化调试页面');
    _initializeCubit();
  }

  void _initializeCubit() {
    try {
      AppLogger.debug('🔄 创建FundExplorationCubit');
      // _cubit = FundExplorationCubit(); // 需要依赖注入，暂时注释

      // 监听状态变化 - 暂时注释，因为_cubit为null
      /*_cubit!.stream.listen((state) {
        AppLogger.debug('📊 Cubit状态变化: ${state.runtimeType}');
        _addLog('Cubit状态: ${state.runtimeType}');
      });*/

      _addLog('⚠️ FundExplorationCubit 需要依赖注入，暂时跳过创建');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 创建FundExplorationCubit失败', e.toString(), stackTrace);
      _addLog('❌ 创建失败: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _log += '[$timestamp] $message\n';
    });
  }

  void _testInitialize() {
    if (_cubit != null) {
      _addLog('🔄 调用 loadFundRankings()');
      _cubit!.loadFundRankings().then((_) {
        _addLog('✅ loadFundRankings() 完成');
      }).catchError((e) {
        _addLog('❌ loadFundRankings() 失败: $e');
      });
    } else {
      _addLog('❌ Cubit为空，无法初始化');
    }
  }

  void _testRefreshRankings() {
    if (_cubit != null) {
      _addLog('🔄 调用 refreshData()');
      _cubit!.refreshData();
      _addLog('✅ refreshData() 调用完成');
    } else {
      _addLog('❌ Cubit为空，无法刷新');
    }
  }

  void _testForceReload() {
    if (_cubit != null) {
      _addLog('🔄 调用 loadFundRankings(forceRefresh: true)');
      _cubit!.loadFundRankings(forceRefresh: true);
      _addLog('✅ loadFundRankings(forceRefresh: true) 调用完成');
    } else {
      _addLog('❌ Cubit为空，无法强制重载');
    }
  }

  void _testClearError() {
    if (_cubit != null) {
      _addLog('🔄 调用 clearError()');
      _cubit!.clearError();
      _addLog('✅ clearError() 调用完成');
    } else {
      _addLog('❌ Cubit为空，无法清除错误');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('刷新按钮调试'),
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
                        const Text(
                          'Cubit状态',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cubit != null
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _cubit != null ? '已初始化' : '未初始化',
                            style: TextStyle(
                              color: _cubit != null
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                          onPressed: _testInitialize,
                          child: const Text('初始化'),
                        ),
                        ElevatedButton(
                          onPressed: _testRefreshRankings,
                          child: const Text('刷新数据'),
                        ),
                        ElevatedButton(
                          onPressed: _testForceReload,
                          child: const Text('强制重载'),
                        ),
                        ElevatedButton(
                          onPressed: _testClearError,
                          child: const Text('清除错误'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

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
