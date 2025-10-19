import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'src/core/utils/logger.dart';

/// 基于主程序架构的测试应用
/// 解决缓存和刷新问题

void main() {
  runApp(const ArchitectureTestApp());
}

class ArchitectureTestApp extends StatelessWidget {
  const ArchitectureTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '架构测试 - 修复刷新问题',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => TestFundRankingCubit(),
        child: const ArchitectureTestPage(),
      ),
    );
  }
}

/// 测试用的基金排行状态
@immutable
class TestFundRankingState {
  final bool isLoading;
  final List<dynamic> funds;
  final String error;
  final DateTime lastUpdated;
  final bool isRefreshing;

  const TestFundRankingState({
    this.isLoading = false,
    this.funds = const [],
    this.error = '',
    required this.lastUpdated,
    this.isRefreshing = false,
  });

  TestFundRankingState copyWith({
    bool? isLoading,
    List<dynamic>? funds,
    String? error,
    DateTime? lastUpdated,
    bool? isRefreshing,
  }) {
    return TestFundRankingState(
      isLoading: isLoading ?? this.isLoading,
      funds: funds ?? this.funds,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// 模拟主程序架构的Cubit
class TestFundRankingCubit extends Cubit<TestFundRankingState> {
  TestFundRankingCubit()
      : super(TestFundRankingState(lastUpdated: DateTime.now()));

  /// 模拟主程序的加载逻辑
  Future<void> loadRankings({bool forceRefresh = false}) async {
    // 模拟缓存检查
    if (!forceRefresh && state.funds.isNotEmpty) {
      AppLogger.debug('🗄️ 使用缓存数据: ${state.funds.length}条');
      return;
    }

    if (forceRefresh) {
      AppLogger.debug('🔄 强制刷新：清除缓存');
      emit(state.copyWith(funds: [], isRefreshing: true));
    } else {
      emit(state.copyWith(isLoading: true, error: ''));
    }

    AppLogger.debug('🔄 开始从API获取基金数据 (forceRefresh: $forceRefresh)');

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
          'User-Agent': 'ArchitectureTestApp/1.0.0',
          if (forceRefresh) 'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 90));

      AppLogger.debug('📊 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 模拟主程序的分页逻辑 - 默认20条，但测试时显示更多
        const pageSize = 50; // 增加到50条以便看到变化
        final displayData = data.take(pageSize).toList();

        AppLogger.debug('✅ 数据加载成功: 总共${data.length}条，显示${displayData.length}条');

        emit(state.copyWith(
          isLoading: false,
          isRefreshing: false,
          funds: displayData,
          lastUpdated: DateTime.now(),
        ));
      } else {
        final errorMsg =
            'API错误: ${response.statusCode} ${response.reasonPhrase}';
        AppLogger.debug('❌ $errorMsg');
        emit(state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: errorMsg,
        ));
      }
    } catch (e) {
      final errorMsg = '加载失败: $e';
      AppLogger.debug('❌ $errorMsg');
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: errorMsg,
      ));
    }
  }

  /// 刷新数据 - 模拟主程序的refreshRankings
  void refreshRankings() {
    AppLogger.debug('🔄 用户点击刷新按钮');
    loadRankings(forceRefresh: true);
  }

  /// 强制重载 - 模拟主程序的forceReload
  void forceReload() {
    AppLogger.debug('🔄 用户点击强制重载');
    loadRankings(forceRefresh: true);
  }

  /// 清除错误
  void clearError() {
    if (state.error.isNotEmpty) {
      emit(state.copyWith(error: ''));
    }
  }

  /// 模拟分页加载更多
  Future<void> loadMore() async {
    if (state.isLoading || state.funds.isEmpty) return;

    AppLogger.debug('📄 加载更多数据');

    try {
      const baseUrl = 'http://154.44.25.92:8080';
      const symbol = '全部';

      final uri = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em')
          .replace(queryParameters: {'symbol': symbol});

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'User-Agent': 'ArchitectureTestApp/1.0.0',
        },
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentLength = state.funds.length;
        final moreData = data.skip(currentLength).take(20).toList();

        if (moreData.isNotEmpty) {
          final allFunds = [...state.funds, ...moreData];
          emit(state.copyWith(funds: allFunds));
          AppLogger.debug(
              '✅ 加载更多成功: 新增${moreData.length}条，总计${allFunds.length}条');
        } else {
          AppLogger.debug('📄 没有更多数据了');
        }
      }
    } catch (e) {
      AppLogger.debug('❌ 加载更多失败: $e');
    }
  }
}

class ArchitectureTestPage extends StatefulWidget {
  const ArchitectureTestPage({super.key});

  @override
  State<ArchitectureTestPage> createState() => _ArchitectureTestPageState();
}

class _ArchitectureTestPageState extends State<ArchitectureTestPage> {
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
    AppLogger.debug('🔧 初始化架构测试页面');
    _addLog('✅ 架构测试页面初始化完成');

    // 自动加载初始数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addLog('🔄 自动加载初始数据');
      context.read<TestFundRankingCubit>().loadRankings();
    });
  }

  void _testLoadFromCache() {
    _addLog('🔄 测试从缓存加载');
    context.read<TestFundRankingCubit>().loadRankings(forceRefresh: false);
  }

  void _testRefreshFromAPI() {
    _addLog('🔄 测试从API刷新');
    context.read<TestFundRankingCubit>().refreshRankings();
  }

  void _testForceReload() {
    _addLog('🔄 测试强制重载');
    context.read<TestFundRankingCubit>().forceReload();
  }

  void _testLoadMore() {
    _addLog('🔄 测试加载更多');
    context.read<TestFundRankingCubit>().loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('架构测试 - 修复刷新问题'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 状态显示
            BlocBuilder<TestFundRankingCubit, TestFundRankingState>(
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
                              '架构测试状态',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (state.isRefreshing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '刷新中',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (state.isLoading)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '加载中',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '就绪',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
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
                      '架构测试操作',
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
                        BlocBuilder<TestFundRankingCubit, TestFundRankingState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: (state.isLoading || state.isRefreshing)
                                  ? null
                                  : _testLoadFromCache,
                              child: const Text('从缓存加载'),
                            );
                          },
                        ),
                        BlocBuilder<TestFundRankingCubit, TestFundRankingState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: (state.isLoading || state.isRefreshing)
                                  ? null
                                  : _testRefreshFromAPI,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('从API刷新'),
                            );
                          },
                        ),
                        BlocBuilder<TestFundRankingCubit, TestFundRankingState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: (state.isLoading || state.isRefreshing)
                                  ? null
                                  : _testForceReload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('强制重载'),
                            );
                          },
                        ),
                        BlocBuilder<TestFundRankingCubit, TestFundRankingState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: (state.isLoading ||
                                      state.isRefreshing ||
                                      state.funds.isEmpty)
                                  ? null
                                  : _testLoadMore,
                              child: const Text('加载更多'),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 基金数据预览
            BlocBuilder<TestFundRankingCubit, TestFundRankingState>(
              builder: (context, state) {
                if (state.funds.isNotEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '基金数据预览（前${math.min(10, state.funds.length)}条）',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: math.min(10, state.funds.length),
                              itemBuilder: (context, index) {
                                final fund = state.funds[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                    backgroundColor: Colors.blue.shade100,
                                    foregroundColor: Colors.blue.shade700,
                                  ),
                                  title: Text(fund['基金简称'] ?? '未知'),
                                  subtitle:
                                      Text('${fund['基金代码']} · ${fund['基金类型']}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        fund['单位净值']?.toString() ?? '0.00',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${fund['日增长率']}%',
                                        style: TextStyle(
                                          color: (fund['日增长率'] ?? '')
                                                  .toString()
                                                  .contains('-')
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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
                      const Text(
                        '架构调试日志',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
