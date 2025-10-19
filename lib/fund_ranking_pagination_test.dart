import 'package:flutter/material.dart';
import '../src/core/network/fund_api_client.dart';
import '../src/core/utils/logger.dart';

void main() {
  runApp(const FundRankingPaginationApp());
}

class FundRankingPaginationApp extends StatelessWidget {
  const FundRankingPaginationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金排行翻页测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FundRankingPaginationPage(),
    );
  }
}

class FundRankingPaginationPage extends StatefulWidget {
  const FundRankingPaginationPage({super.key});

  @override
  State<FundRankingPaginationPage> createState() =>
      _FundRankingPaginationPageState();
}

class _FundRankingPaginationPageState extends State<FundRankingPaginationPage> {
  final FundApiClient _apiClient = FundApiClient();
  final TextEditingController _symbolController =
      TextEditingController(text: '全部');

  List<dynamic> _funds = [];
  List<dynamic> _currentPageFunds = [];
  bool _isLoading = false;
  String _error = '';

  // 分页参数
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalFunds = 0;
  int _totalPages = 0;

  // 测试参数
  bool _useForceRefresh = false;
  int _timeoutSeconds = 60;

  /// 加载基金数据
  Future<void> _loadFunds() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _funds = [];
      _currentPageFunds = [];
      _currentPage = 1;
    });

    try {
      AppLogger.info('🔄 开始加载基金数据...');
      AppLogger.info(
          '📋 参数: symbol="${_symbolController.text}", forceRefresh=$_useForceRefresh');

      final funds = await _apiClient
          .getFundRankings(
            symbol: _symbolController.text,
            forceRefresh: _useForceRefresh,
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      setState(() {
        _funds = funds;
        _totalFunds = funds.length;
        _totalPages = (_totalFunds / _pageSize).ceil();
        _updateCurrentPageFunds();
      });

      AppLogger.info('✅ 数据加载成功: $_totalFunds条记录');
    } catch (e) {
      AppLogger.error('❌ 数据加载失败', e.toString());
      setState(() {
        _error = '加载失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 更新当前页显示的基金数据
  void _updateCurrentPageFunds() {
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;

    setState(() {
      if (startIndex < _funds.length) {
        _currentPageFunds = _funds.sublist(
            startIndex, endIndex > _funds.length ? _funds.length : endIndex);
      } else {
        _currentPageFunds = [];
      }
    });
  }

  /// 跳转到指定页
  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _updateCurrentPageFunds();
      });
    }
  }

  /// 刷新当前页数据
  Future<void> _refreshCurrentPage() async {
    setState(() {
      _useForceRefresh = true;
    });
    await _loadFunds();
    setState(() {
      _useForceRefresh = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('基金排行翻页测试'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refreshCurrentPage,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: Column(
        children: [
          // 控制面板
          _buildControlPanel(),

          // 数据统计信息
          _buildStatsPanel(),

          // 错误信息
          if (_error.isNotEmpty) _buildErrorPanel(),

          // 基金列表
          Expanded(
            child: _buildFundList(),
          ),

          // 分页控制
          _buildPaginationControl(),
        ],
      ),
    );
  }

  /// 构建控制面板
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _symbolController,
                  decoration: const InputDecoration(
                    labelText: '基金类型',
                    hintText: '输入基金类型，如：全部、股票型、债券型等',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadFunds,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? '加载中...' : '加载'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '强制刷新: ${_useForceRefresh ? "是" : "否"}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Switch(
                value: _useForceRefresh,
                onChanged: (value) {
                  setState(() {
                    _useForceRefresh = value;
                  });
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  '超时时间: ${_timeoutSeconds}秒',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DropdownButton<int>(
                value: _timeoutSeconds,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _timeoutSeconds = value;
                    });
                  }
                },
                items: [30, 60, 120].map((seconds) {
                  return DropdownMenuItem(
                    value: seconds,
                    child: Text('$seconds秒'),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计面板
  Widget _buildStatsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总记录', '$_totalFunds', Colors.blue),
          _buildStatItem('总页数', '$_totalPages', Colors.green),
          _buildStatItem('当前页', '$_currentPage/$_totalPages', Colors.orange),
          _buildStatItem('每页', '$_pageSize', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 构建错误面板
  Widget _buildErrorPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _error = '';
              });
            },
            icon: const Icon(Icons.close),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  /// 构建基金列表
  Widget _buildFundList() {
    if (_isLoading && _funds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载基金数据...'),
          ],
        ),
      );
    }

    if (_funds.isEmpty && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无数据',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text('请输入基金类型并点击加载'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _currentPageFunds.length,
      itemBuilder: (context, index) {
        final fund = _currentPageFunds[index];
        final itemNumber = (_currentPage - 1) * _pageSize + index + 1;

        return _buildFundCard(fund, itemNumber);
      },
    );
  }

  /// 构建基金卡片
  Widget _buildFundCard(dynamic fund, int itemNumber) {
    // 安全地提取基金信息，添加异常处理
    String code = '未知';
    String name = '未知';
    String type = '未知';
    String company = '未知';
    double? unitNav;
    double? accumulatedNav;
    double? dailyReturn;
    double? return1W;
    double? return1M;
    double? return3M;
    double? return6M;
    double? return1Y;
    double? returnYTD;
    double? returnSinceInception;
    String date = '';
    String? customReturn;
    String? fee;

    try {
      if (fund is Map<String, dynamic>) {
        // 基础信息 - 使用API返回的中文字段名
        code = fund['基金代码']?.toString() ?? fund['code']?.toString() ?? '未知';
        name = fund['基金简称']?.toString() ?? fund['name']?.toString() ?? '未知';
        type = fund['type']?.toString() ?? '未知';
        company = fund['company']?.toString() ?? '未知';
        date = fund['日期']?.toString() ?? '';

        // 净值信息
        unitNav = _parseDouble(fund['单位净值']);
        accumulatedNav = _parseDouble(fund['累计净值']);

        // 收益率信息
        dailyReturn = _parseDouble(fund['日增长率']);
        return1W = _parseDouble(fund['近1周']);
        return1M = _parseDouble(fund['近1月']);
        return3M = _parseDouble(fund['近3月']);
        return6M = _parseDouble(fund['近6月']);
        return1Y = _parseDouble(fund['近1年']);
        returnYTD = _parseDouble(fund['今年来']);
        returnSinceInception = _parseDouble(fund['成立来']);

        // 其他信息
        customReturn = fund['自定义']?.toString();
        fee = fund['手续费']?.toString();

        AppLogger.debug('解析基金数据 $itemNumber: $code - $name');
      }
    } catch (e) {
      AppLogger.warn('解析基金数据失败 (项目 $itemNumber)', e.toString());
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            '$itemNumber',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('代码: $code',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('名称: $name'),
            if (fee != null && fee!.isNotEmpty)
              Text('手续费: $fee',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (date.isNotEmpty)
              Text('日期: $date',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 单位净值
            Text(
              unitNav != null ? unitNav!.toStringAsFixed(4) : 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
            // 累计净值
            if (accumulatedNav != null)
              Text(
                accumulatedNav!.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                ),
              ),
            // 日增长率
            Text(
              dailyReturn != null
                  ? '${dailyReturn!.toStringAsFixed(2)}%'
                  : 'N/A',
              style: TextStyle(
                fontSize: 11,
                color: (dailyReturn ?? 0) >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            // 近1年收益率
            Text(
              return1Y != null ? '年${return1Y!.toStringAsFixed(2)}%' : 'N/A',
              style: TextStyle(
                fontSize: 10,
                color: (return1Y ?? 0) >= 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            // 今年来收益率
            if (returnYTD != null)
              Text(
                '今${returnYTD!.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 9,
                  color: (returnYTD ?? 0) >= 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建分页控制
  Widget _buildPaginationControl() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 上一页按钮
              IconButton(
                onPressed:
                    _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: '上一页',
              ),

              // 页码显示
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  '第 $_currentPage 页，共 $_totalPages 页',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),

              // 下一页按钮
              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: '下一页',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 快速跳转
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('快速跳转: '),
              const SizedBox(width: 8),
              ...List.generate(_totalPages.clamp(1, 10), (index) {
                final pageNum = index + 1;
                final isCurrentPage = pageNum == _currentPage;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: () => _goToPage(pageNum),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCurrentPage ? Colors.blue : Colors.white,
                      foregroundColor:
                          isCurrentPage ? Colors.white : Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size(0, 32),
                    ),
                    child: Text('$pageNum'),
                  ),
                );
              }),
              if (_totalPages > 10) ...[
                const Text(' ... '),
                ElevatedButton(
                  onPressed: () => _goToPage(_totalPages),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 32),
                  ),
                  child: Text('$_totalPages'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 解析double值
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return null;
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
