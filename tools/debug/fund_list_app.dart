import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const FundListApp());
}

class FundListApp extends StatelessWidget {
  const FundListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金排行榜',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: const FundListPage(),
    );
  }
}

class FundListPage extends StatefulWidget {
  const FundListPage({super.key});

  @override
  State<FundListPage> createState() => _FundListPageState();
}

class _FundListPageState extends State<FundListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _allFunds = [];
  List<dynamic> _displayFunds = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _selectedType = '全部';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFunds();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && _error.isEmpty) {
        _loadMoreFunds();
      }
    }
  }

  Future<void> _loadFunds({bool isRefresh = false}) async {
    if (_isLoading) return; // 防止重复加载

    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      debugPrint('🔄 开始加载基金数据: 类型=$_selectedType');

      final uri = Uri.parse(
              'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em')
          .replace(queryParameters: {'symbol': _selectedType});

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'User-Agent': 'FundListApp/1.0.0',
          'Cache-Control': isRefresh ? 'no-cache' : 'max-age=300',
        },
      ).timeout(const Duration(seconds: 90));

      debugPrint('📊 API响应状态: ${response.statusCode}');
      debugPrint('📊 响应数据大小: ${response.body.length} 字符');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _allFunds = data;
          _displayFunds = data.take(_pageSize).toList();
          _hasMore = data.length > _pageSize;
          _isLoading = false;
        });

        debugPrint('✅ 数据加载成功: ${data.length}条基金记录');

        // 如果有搜索条件，重新应用搜索
        if (_searchController.text.isNotEmpty) {
          _onSearchChanged(_searchController.text);
        }
      } else {
        setState(() {
          _error = 'API错误: ${response.statusCode} ${response.reasonPhrase}';
          _isLoading = false;
        });
        debugPrint('❌ API错误: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
      debugPrint('❌ 加载异常: $e');
    }
  }

  Future<void> _loadMoreFunds() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 模拟网络延迟，提升用户体验
    await Future.delayed(const Duration(milliseconds: 200));

    List<dynamic> nextPageData;

    if (_searchController.text.isEmpty) {
      // 无搜索状态，从全部数据中获取
      nextPageData =
          _allFunds.skip(_currentPage * _pageSize).take(_pageSize).toList();
    } else {
      // 有搜索状态，从筛选后的数据中获取
      final filtered = _allFunds.where((fund) {
        final name = fund['基金简称']?.toString().toLowerCase() ?? '';
        final code = fund['基金代码']?.toString().toLowerCase() ?? '';
        final fundType = fund['基金类型']?.toString().toLowerCase() ?? '';
        final query = _searchController.text.toLowerCase();
        return name.contains(query) ||
            code.contains(query) ||
            fundType.contains(query);
      }).toList();

      nextPageData =
          filtered.skip(_currentPage * _pageSize).take(_pageSize).toList();
    }

    setState(() {
      _displayFunds.addAll(nextPageData);
      _currentPage++;
      _hasMore = nextPageData.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  void _onSearchChanged(String query) {
    // 添加防抖机制，避免频繁搜索
    Future.delayed(const Duration(milliseconds: 300), () {
      if (query != _searchController.text) return; // 确保是最新的搜索词

      if (query.isEmpty) {
        setState(() {
          _displayFunds = _allFunds.take(_pageSize).toList();
          _currentPage = 1;
          _hasMore = _allFunds.length > _pageSize;
        });
      } else {
        final filtered = _allFunds.where((fund) {
          final name = fund['基金简称']?.toString().toLowerCase() ?? '';
          final code = fund['基金代码']?.toString().toLowerCase() ?? '';
          final fundType = fund['基金类型']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              code.contains(query.toLowerCase()) ||
              fundType.contains(query.toLowerCase());
        }).toList();

        setState(() {
          _displayFunds = filtered.take(_pageSize).toList();
          _currentPage = 1;
          _hasMore = filtered.length > _pageSize;
        });
      }
    });
  }

  void _onTypeChanged(String type) {
    if (_selectedType != type) {
      // 避免重复加载相同类型
      setState(() {
        _selectedType = type;
        _searchController.clear(); // 切换类型时清空搜索
      });
      _loadFunds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金排行榜'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _loadFunds(isRefresh: true),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选区域
          _buildSearchAndFilter(),

          // 错误提示
          if (_error.isNotEmpty) _buildErrorWidget(),

          // 数据展示区域
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _displayFunds.isEmpty
                    ? _buildEmptyWidget()
                    : _buildFundList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索基金名称或代码...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _onSearchChanged,
          ),

          const SizedBox(height: 12),

          // 类型筛选
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                '全部',
                '股票型',
                '混合型',
                '债券型',
                '指数型',
                'QDII',
              ].map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _onTypeChanged(type);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF1E40AF),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
          TextButton(
            onPressed: _loadFunds,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
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

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '暂无基金数据',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text('请尝试更换筛选条件或刷新'),
        ],
      ),
    );
  }

  Widget _buildFundList() {
    return RefreshIndicator(
      onRefresh: () => _loadFunds(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _displayFunds.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayFunds.length && _hasMore) {
            return _buildLoadingMoreWidget();
          }

          final fund = _displayFunds[index];
          return _buildFundCard(fund);
        },
      ),
    );
  }

  Widget _buildFundCard(Map<String, dynamic> fund) {
    final fundCode = fund['基金代码']?.toString() ?? '';
    final fundName = fund['基金简称']?.toString() ?? '';
    final fundType = fund['基金类型']?.toString() ?? '未知类型';
    // 注意：API返回的数据中没有基金公司字段，我们用其他字段代替
    final date = fund['日期']?.toString() ?? '';
    final company =
        date.isNotEmpty ? date.substring(0, 10) : '未知公司'; // 使用日期作为公司标识
    final unitNav = fund['单位净值']?.toString() ?? '0.00';
    final dailyReturn = fund['日增长率']?.toString() ?? '0.00';
    final return1Y = fund['近1年']?.toString() ?? '0.00';
    final return3Y = fund['近3年']?.toString() ?? '0.00';

    final dailyReturnNum =
        double.tryParse(dailyReturn.replaceAll('%', '')) ?? 0.0;
    final return1YNum = double.tryParse(return1Y.replaceAll('%', '')) ?? 0.0;
    final return3YNum = double.tryParse(return3Y.replaceAll('%', '')) ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fundName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fundCode · $fundType',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      unitNav,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dailyReturnNum >= 0
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$dailyReturn%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: dailyReturnNum >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildReturnChip('近1年', return1Y, return1YNum),
                const SizedBox(width: 8),
                _buildReturnChip('近3年', return3Y, return3YNum),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnChip(String label, String value, double numValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: numValue >= 0 ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: numValue >= 0 ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            '$value%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color:
                  numValue >= 0 ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreWidget() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('加载更多...'),
          ],
        ),
      ),
    );
  }
}
