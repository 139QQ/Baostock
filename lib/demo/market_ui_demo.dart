import 'dart:async';
import 'package:flutter/material.dart';
import '../src/core/services/market_real_service.dart';
import '../src/core/services/market_real_service_enhanced.dart';
import '../src/core/services/market_data_models.dart';
import '../src/core/utils/logger.dart';

/// 市场数据UI演示
class MarketUIDemo extends StatefulWidget {
  const MarketUIDemo({Key? key}) : super(key: key);

  @override
  State<MarketUIDemo> createState() => _MarketUIDemoState();
}

class _MarketUIDemoState extends State<MarketUIDemo> {
  late MarketRealService _marketService;

  // 数据状态 - 使用项目定义的数据模型
  MarketIndicesData? _realtimeData;
  List<IndexHistoryData> _historyData = [];
  List<IndexIntradayData> _intradayData = [];

  // 控制变量
  String _selectedSymbol = '000001';
  String _selectedDataSource = 'eastmoney';
  String _selectedPeriod = '5';
  bool _isLoading = false;
  String _errorMessage = '';

  // 定时刷新 - 分离不同数据的刷新频率
  Timer? _realtimeTimer; // 实时数据：5秒
  Timer? _historyTimer; // 历史数据：30秒
  Timer? _intradayTimer; // 分时数据：5秒

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadData();
    _startAutoRefresh();
  }

  /// 初始化市场数据服务
  void _initializeService() {
    // 使用原始版本的服务，确保东方财富历史数据API日期格式正确
    _marketService = MarketRealServiceFactory.create(useEnhanced: false);
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _historyTimer?.cancel();
    _intradayTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // 实时数据：每5秒刷新
    _realtimeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadRealtimeData();
      }
    });

    // 历史数据：每30秒刷新
    _historyTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadHistoryData();
      }
    });

    // 分时数据：每5秒刷新
    _intradayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadIntradayData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _loadRealtimeData(),
        _loadHistoryData(),
        _loadIntradayData(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = '加载数据失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRealtimeData() async {
    try {
      // 使用项目中的真实服务获取实时数据
      final data = await _marketService.getRealTimeIndices();
      if (mounted) {
        setState(() {
          _realtimeData = data;
        });
        AppLogger.info('✅ 实时数据加载成功: ${data.indices.length}条');
      }
    } catch (e) {
      AppLogger.error('❌ 实时数据获取失败: $e', e);
      // 实时数据获取失败是正常的（非交易时间），不设置错误信息
    }
  }

  Future<void> _loadHistoryData() async {
    try {
      // 只使用东方财富历史数据API
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day); // 今天作为结束日期
      final startDate =
          endDate.subtract(const Duration(days: 90)); // 90天历史数据，确保有足够的数据

      // 创建历史数据查询参数
      final params = HistoryQueryParams(
        symbol: _selectedSymbol,
        startDate: startDate,
        endDate: endDate,
      );

      // 只使用东方财富历史数据
      final historyData = await _marketService.getIndexHistory(params);

      if (mounted) {
        setState(() {
          _historyData = historyData;
        });
        AppLogger.info('✅ 东方财富历史数据加载成功: ${historyData.length}条记录');
      }
    } catch (e) {
      AppLogger.error('❌ 东方财富历史数据获取失败: $e', e);
      if (mounted) {
        setState(() {
          _errorMessage = '东方财富历史数据获取失败: $e';
        });
      }
    }
  }

  Future<void> _loadIntradayData() async {
    try {
      // 使用当前交易时间段（分时数据通常使用当日数据）
      final now = DateTime.now();
      final startDate =
          DateTime(now.year, now.month, now.day, 9, 30, 0); // 当日09:30
      final endDate =
          DateTime(now.year, now.month, now.day, 15, 0, 0); // 当日15:00

      // 创建分时数据查询参数
      final params = HistoryQueryParams(
        symbol: _selectedSymbol,
        period: _selectedPeriod, // 使用选择的周期：1,5,15,30,60分钟
        startDate: startDate,
        endDate: endDate,
      );

      // 使用项目中的真实服务获取分时数据
      final intradayData = await _marketService.getIndexIntradayData(params);

      if (mounted) {
        setState(() {
          _intradayData = intradayData;
        });
        AppLogger.info(
            '✅ 分时数据加载成功: ${intradayData.length}条记录 (周期: ${_selectedPeriod}分钟)');
      }
    } catch (e) {
      AppLogger.error('❌ 分时数据获取失败: $e', e);
      // 分时数据获取失败是正常的（非交易时间或无数据），不设置错误信息
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基速基金 - 市场数据演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('市场数据实时演示'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: '刷新数据',
            ),
          ],
        ),
        body: Column(
          children: [
            // 控制面板
            _buildControlPanel(),

            // 错误信息
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage)),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                    ),
                  ],
                ),
              ),

            // 状态指示器
            _buildStatusIndicator(),

            // 主内容区域
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text(''),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    automaticallyImplyLeading: false,
                    bottom: const TabBar(
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.trending_up),
                          text: '实时数据',
                        ),
                        Tab(
                          icon: const Icon(Icons.history),
                          text: '历史数据',
                        ),
                        Tab(
                          icon: const Icon(Icons.timeline),
                          text: '分时数据',
                        ),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      _buildRealtimeTab(),
                      _buildHistoryTab(),
                      _buildIntradayTab(),
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

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        children: [
          // 第一行：指数选择和数据源标识
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedSymbol,
                  decoration: const InputDecoration(
                    labelText: '选择指数',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: '000001', child: Text('上证指数')),
                    DropdownMenuItem(value: '399001', child: Text('深证成指')),
                    DropdownMenuItem(value: '399006', child: Text('创业板指')),
                    DropdownMenuItem(value: '000300', child: Text('沪深300')),
                    DropdownMenuItem(value: '000688', child: Text('科创50')),
                    DropdownMenuItem(value: '399005', child: Text('中小板指')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSymbol = value;
                      });
                      _loadData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.blue.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.data_array,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '东方财富数据源',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 第二行：周期选择
          DropdownButtonFormField<String>(
            value: _selectedPeriod,
            decoration: const InputDecoration(
              labelText: '分时周期',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: '1', child: Text('1分钟')),
              DropdownMenuItem(value: '5', child: Text('5分钟')),
              DropdownMenuItem(value: '15', child: Text('15分钟')),
              DropdownMenuItem(value: '30', child: Text('30分钟')),
              DropdownMenuItem(value: '60', child: Text('60分钟')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPeriod = value;
                });
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: _isTradingTimeNow() ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            _getTradingStatus(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isTradingTimeNow() ? Colors.green : Colors.red,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '数据更新: ${DateTime.now().toString().substring(11, 19)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                '刷新间隔: 实时5s | 历史30s | 分时5s',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载实时数据...'),
          ],
        ),
      );
    }

    if (_realtimeData == null || _realtimeData!.indices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无实时数据',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isTradingTimeNow() ? '正在获取数据...' : 'A股市场休市中，请等待交易时间',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _realtimeData!.indices.length,
      itemBuilder: (context, index) {
        final item = _realtimeData!.indices[index];
        final isPositive = item.changePercent >= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPositive ? Colors.green : Colors.red,
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(item.symbol),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.latestPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无历史数据',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 统计信息
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('数据量', '${_historyData.length}条'),
              _buildStatCard(
                  '最新价',
                  _historyData.isNotEmpty
                      ? _historyData.last.close.toStringAsFixed(2)
                      : '0.00'),
              _buildStatCard('期间涨跌', _calculateHistoryChange()),
            ],
          ),
        ),

        // 历史数据列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _historyData.length > 20
                ? 20
                : _historyData.length, // 限制显示数量以提高性能
            itemBuilder: (context, index) {
              final item = _historyData[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text(
                    item.date.toString().split('T')[0],
                  ),
                  subtitle: Text(
                    '开盘: ${item.open.toStringAsFixed(2)} | 收盘: ${item.close.toStringAsFixed(2)} | 成交量: ${item.volume}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    '${item.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color:
                          item.changePercent >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIntradayTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_intradayData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无分时数据',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _isTradingTimeNow() ? '正在获取分时数据...' : '当前不是交易时间，无分时数据',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _intradayData.length,
      itemBuilder: (context, index) {
        final item = _intradayData[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            leading: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            title: Text(
              item.time.toString().split('.')[0],
            ),
            subtitle: Text(
              '开盘: ${item.open.toStringAsFixed(2)} | 收盘: ${item.close.toStringAsFixed(2)} | 成交量: ${item.volume}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Text(
              item.avgPrice.toStringAsFixed(2),
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  String _getTradingStatus() {
    final now = DateTime.now();
    final isWorkday = now.weekday >= 1 && now.weekday <= 5;

    if (!isWorkday) {
      return '🔴 周末休市';
    }

    final hour = now.hour;
    final minute = now.minute;

    if (hour < 9) {
      return '🔴 未开盘';
    } else if (hour == 9 && minute < 30) {
      return '🔴 未开盘';
    } else if ((hour == 9 && minute >= 30) ||
        (hour == 10) ||
        (hour == 11 && minute <= 30)) {
      return '🟢 早盘交易中';
    } else if ((hour == 11 && minute > 30) ||
        (hour == 12) ||
        (hour == 13 && minute == 0)) {
      return '🟡 午间休市';
    } else if ((hour > 13) || (hour == 13 && minute > 0) || (hour < 15)) {
      return '🟢 尾盘交易中';
    } else {
      return '🔴 已收盘';
    }
  }

  bool _isTradingTimeNow() {
    final now = DateTime.now();
    if (now.weekday < 1 || now.weekday > 5) return false; // 周末

    final hour = now.hour;
    final minute = now.minute;

    // 早盘: 9:30-11:30
    if ((hour == 9 && minute >= 30) ||
        (hour == 10) ||
        (hour == 11 && minute <= 30)) {
      return true;
    }

    // 尾盘: 13:00-15:00
    if ((hour == 13 && minute > 0) ||
        (hour == 14) ||
        (hour == 15 && minute == 0)) {
      return true;
    }

    return false;
  }

  String _calculateHistoryChange() {
    if (_historyData.length < 2) return '0.00%';

    final firstPrice = _historyData.first.close;
    final lastPrice = _historyData.last.close;

    if (firstPrice == 0) return '0.00%';

    final changePercent = ((lastPrice - firstPrice) / firstPrice) * 100;
    return '${changePercent.toStringAsFixed(2)}%';
  }
}

void main() {
  runApp(const MarketUIDemoApp());
}

class MarketUIDemoApp extends StatelessWidget {
  const MarketUIDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基速基金 - 市场数据演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const MarketUIDemo(),
    );
  }
}
