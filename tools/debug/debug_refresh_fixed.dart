import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';

/// 简化的基金排行状态
@immutable
class SimpleFundState {
  final bool isLoading;
  final List<dynamic> funds;
  final String error;
  final DateTime lastUpdated;

  const SimpleFundState({
    this.isLoading = false,
    this.funds = const [],
    this.error = '',
    required this.lastUpdated,
  });

  SimpleFundState copyWith({
    bool? isLoading,
    List<dynamic>? funds,
    String? error,
    DateTime? lastUpdated,
  }) {
    return SimpleFundState(
      isLoading: isLoading ?? this.isLoading,
      funds: funds ?? this.funds,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 简化的基金排行Cubit
class SimpleFundCubit extends Cubit<SimpleFundState> {
  SimpleFundCubit() : super(SimpleFundState(lastUpdated: DateTime.now()));

  /// 直接调用API刷新数据
  Future<void> refreshData() async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, error: ''));

    AppLogger.debug('🔄 开始刷新基金数据');

    try {
      const baseUrl = 'http://154.44.25.92:8080';
      const symbol = '全部';

      final uri = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em')
          .replace(queryParameters: {'symbol': symbol});

      AppLogger.debug('📡 请求URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'User-Agent': 'SimpleFundCubit/1.0.0',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 90));

      AppLogger.debug('📊 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.debug('✅ 数据加载成功: ${data.length}条记录');

        emit(state.copyWith(
          isLoading: false,
          funds: data,
          lastUpdated: DateTime.now(),
        ));
      } else {
        final errorMsg =
            'API错误: ${response.statusCode} ${response.reasonPhrase}';
        AppLogger.debug('❌ $errorMsg');
        emit(state.copyWith(
          isLoading: false,
          error: errorMsg,
        ));
      }
    } catch (e) {
      final errorMsg = '刷新失败: $e';
      AppLogger.debug('❌ $errorMsg');
      emit(state.copyWith(
        isLoading: false,
        error: errorMsg,
      ));
    }
  }

  /// 强制重载（清除缓存）
  Future<void> forceReload() async {
    AppLogger.debug('🔄 强制重载数据');
    await refreshData();
  }

  /// 清除错误
  void clearError() {
    if (state.error.isNotEmpty) {
      emit(state.copyWith(error: ''));
    }
  }
}

/// 修复版刷新调试应用
void main() {
  runApp(const RefreshDebugFixedApp());
}

class RefreshDebugFixedApp extends StatelessWidget {
  const RefreshDebugFixedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '刷新按钮调试（修复版）',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => SimpleFundCubit(),
        child: const RefreshDebugFixedPage(),
      ),
    );
  }
}

class RefreshDebugFixedPage extends StatefulWidget {
  const RefreshDebugFixedPage({super.key});

  @override
  State<RefreshDebugFixedPage> createState() => _RefreshDebugFixedPageState();
}

class _RefreshDebugFixedPageState extends State<RefreshDebugFixedPage> {
  String _log = '等待操作...\n';

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _log += '[$timestamp] $message\n';
    });
  }

  @override
  void initState() {
    super.initState();
    AppLogger.debug('🔧 初始化修复版调试页面');
    _addLog('✅ 修复版调试页面初始化完成');
  }

  void _testRefresh() {
    _addLog('🔄 调用 refreshData()');
    context.read<SimpleFundCubit>().refreshData();
  }

  void _testForceReload() {
    _addLog('🔄 调用 forceReload()');
    context.read<SimpleFundCubit>().forceReload();
  }

  void _testClearError() {
    _addLog('🔄 调用 clearError()');
    context.read<SimpleFundCubit>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('刷新按钮调试（修复版）'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 状态显示
            BlocBuilder<SimpleFundCubit, SimpleFundState>(
              builder: (context, state) {
                return Card(
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
                              'Cubit状态',
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
                                color: state.isLoading
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                state.isLoading ? '加载中' : '就绪',
                                style: TextStyle(
                                  color: state.isLoading
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
                          '基金数据: ${state.funds.length}条',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          '最后更新: ${state.lastUpdated.toString().substring(11, 19)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (state.error.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              state.error,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
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
                        BlocBuilder<SimpleFundCubit, SimpleFundState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: state.isLoading ? null : _testRefresh,
                              child: const Text('刷新数据'),
                            );
                          },
                        ),
                        BlocBuilder<SimpleFundCubit, SimpleFundState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed:
                                  state.isLoading ? null : _testForceReload,
                              child: const Text('强制重载'),
                            );
                          },
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

            // 基金数据预览
            BlocBuilder<SimpleFundCubit, SimpleFundState>(
              builder: (context, state) {
                if (state.funds.isNotEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '基金数据预览（前5条）',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: math.min(5, state.funds.length),
                              itemBuilder: (context, index) {
                                final fund = state.funds[index];
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
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
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
