import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/domain/services/fund_user_preferences.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/fund_card_components.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/fund_card_theme.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_ranking.dart';

/// 基金用户偏好功能演示
///
/// 展示完整的用户偏好管理功能，包括收藏、显示设置、搜索历史等
class FundUserPreferencesDemo extends StatefulWidget {
  const FundUserPreferencesDemo({super.key});

  @override
  State<FundUserPreferencesDemo> createState() =>
      _FundUserPreferencesDemoState();
}

class _FundUserPreferencesDemoState extends State<FundUserPreferencesDemo>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  // 演示数据
  List<FundRanking> _demoFunds = [];
  Set<String> _favoriteFunds = {};
  FundDisplayPreferences _displayPreferences =
      FundDisplayPreferences.defaultPreferences();
  List<String> _searchHistory = [];
  List<String> _recentlyViewed = [];

  bool _isLoading = false;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _animationController = AnimationController(
      duration: FundCardAnimationConfig.mediumDuration,
      vsync: this,
    );

    _initializeDemo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化演示
  Future<void> _initializeDemo() async {
    setState(() => _isLoading = true);

    try {
      // 初始化用户偏好服务
      await FundUserPreferences.initialize();

      // 生成演示数据
      await _generateDemoFunds();

      // 加载用户偏好数据
      await _loadUserPreferences();

      _animationController.forward();
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 生成演示基金数据
  Future<void> _generateDemoFunds() async {
    final random = Random();
    final fundNames = [
      '易方达蓝筹精选混合',
      '富国天惠成长混合',
      '兴全合润混合',
      '汇添富价值精选',
      '华夏回报混合',
      '嘉实优质企业混合',
      '南方绩优成长混合',
      '博时主题行业',
      '广发稳健增长混合',
      '上投摩根中国优势',
      '工银瑞信核心价值',
      '华安宝利配置',
      '交银施罗德成长混合',
      '建信优化配置混合',
      '中银中国精选混合',
      '国泰金鹰增长',
      '银华富裕主题混合',
      '招商安泰平衡混合',
      '长城久泰沪深300',
      '华宝兴业收益增长',
      '光大保德信量化核心',
      '华商领先企业混合',
      '诺安股票混合',
      '景顺长城鼎益混合',
    ];

    final companies = [
      '易方达基金',
      '富国基金',
      '兴全基金',
      '汇添富基金',
      '华夏基金',
      '嘉实基金',
      '南方基金',
      '博时基金',
      '广发基金',
      '上投摩根基金',
      '工银瑞信基金',
      '华安基金',
      '交银施罗德基金',
      '建信基金',
      '中银基金',
      '国泰基金',
      '银华基金',
      '招商基金',
    ];

    final fundTypes = ['股票型', '混合型', '债券型', '指数型', 'QDII', 'FOF'];

    _demoFunds = List.generate(25, (index) {
      final position = index + 1;
      final dailyReturn = (random.nextDouble() - 0.5) * 10; // -5% 到 +5%
      final return1M = (random.nextDouble() - 0.3) * 20; // -10% 到 +10%
      final return1Y = (random.nextDouble() - 0.2) * 50; // -20% 到 +30%

      return FundRanking(
        fundCode: '${random.nextInt(9000) + 1000}${random.nextInt(90) + 10}',
        fundName: fundNames[index % fundNames.length],
        company: companies[index % companies.length],
        fundType: fundTypes[index % fundTypes.length],
        rankingPosition: position,
        totalCount: 2000,
        unitNav: double.parse((random.nextDouble() * 5 + 1).toStringAsFixed(4)),
        accumulatedNav: double.parse((random.nextDouble() * 8 + 1).toStringAsFixed(4)),
        dailyReturn: double.parse(dailyReturn.toStringAsFixed(2)),
        return1W: double.parse(((random.nextDouble() - 0.4) * 15).toStringAsFixed(2)),
        return1M: double.parse(return1M.toStringAsFixed(2)),
        return3M: double.parse(((random.nextDouble() - 0.3) * 25).toStringAsFixed(2)),
        return6M: double.parse(((random.nextDouble() - 0.25) * 35).toStringAsFixed(2)),
        return1Y: double.parse(return1Y.toStringAsFixed(2)),
        return2Y: double.parse(((random.nextDouble() - 0.2) * 60).toStringAsFixed(2)),
        return3Y: double.parse(((random.nextDouble() - 0.15) * 80).toStringAsFixed(2)),
        returnYTD: double.parse(((random.nextDouble() - 0.3) * 40).toStringAsFixed(2)),
        returnSinceInception: double.parse(((random.nextDouble() * 100).toStringAsFixed(2))),
        rankingDate: DateTime.now(),
        rankingType: RankingType.overall,
        rankingPeriod: RankingPeriod.daily,
      );
    });
  }

  /// 加载用户偏好数据
  Future<void> _loadUserPreferences() async {
    _favoriteFunds = await FundUserPreferences.getFavoriteFunds();
    _displayPreferences = await FundUserPreferences.getDisplayPreferences();
    _searchHistory = await FundUserPreferences.getSearchHistory();
    _recentlyViewed = await FundUserPreferences.getRecentlyViewedFunds();
    setState(() {});
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(String fundCode) async {
    final success = await FundUserPreferences.toggleFavoriteFund(fundCode);
    if (success) {
      await _loadUserPreferences();
      _showMessage('收藏状态已更新');
    } else {
      _showMessage('更新收藏状态失败', isError: true);
    }
  }

  /// 添加搜索历史
  Future<void> _addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final success = await FundUserPreferences.addSearchHistory(query);
    if (success) {
      await _loadUserPreferences();
    }
  }

  /// 添加最近查看
  Future<void> _addRecentlyViewed(String fundCode) async {
    final success = await FundUserPreferences.addRecentlyViewedFund(fundCode);
    if (success) {
      await _loadUserPreferences();
    }
  }

  /// 更新显示偏好
  Future<void> _updateDisplayPreferences(
      FundDisplayPreferences preferences) async {
    final success =
        await FundUserPreferences.saveDisplayPreferences(preferences);
    if (success) {
      await _loadUserPreferences();
      _showMessage('显示偏好已保存');
    } else {
      _showMessage('保存显示偏好失败', isError: true);
    }
  }

  /// 导出用户数据
  Future<void> _exportUserData() async {
    try {
      await FundUserPreferences.exportUserData();

      // 这里可以实现保存到文件或分享功能
      _showMessage('用户数据导出成功\n共${_favoriteFunds.length}个收藏基金');
    } catch (e) {
      _showMessage('导出失败: ${e.toString()}', isError: true);
    }
  }

  /// 清空所有数据
  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmDialog('确定要清空所有用户数据吗？此操作不可恢复。');
    if (!confirmed) return;

    try {
      final success = await FundUserPreferences.clearAllUserData();
      if (success) {
        await _loadUserPreferences();
        _showMessage('所有数据已清空');
      } else {
        _showMessage('清空数据失败', isError: true);
      }
    } catch (e) {
      _showMessage('操作失败: ${e.toString()}', isError: true);
    }
  }

  /// 显示消息
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金用户偏好管理'),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.favorite), text: '收藏'),
            Tab(icon: Icon(Icons.palette), text: '显示设置'),
            Tab(icon: Icon(Icons.history), text: '历史记录'),
            Tab(icon: Icon(Icons.analytics), text: '统计分析'),
            Tab(icon: Icon(Icons.settings), text: '数据管理'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _exportUserData,
            icon: const Icon(Icons.file_download),
            tooltip: '导出数据',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesTab(),
          _buildDisplaySettingsTab(),
          _buildHistoryTab(),
          _buildStatisticsTab(),
          _buildDataManagementTab(),
        ],
      ),
    );
  }

  /// 构建收藏标签页
  Widget _buildFavoritesTab() {
    return Column(
      children: [
        // 收藏统计
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red[400]!, Colors.pink[400]!],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '我的收藏',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '共收藏 ${_favoriteFunds.length} 只基金',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // 收藏列表
        Expanded(
          child: _favoriteFunds.isEmpty
              ? _buildEmptyFavorites()
              : _buildFavoriteList(),
        ),
      ],
    );
  }

  /// 构建空收藏状态
  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏基金',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击基金卡片的爱心图标添加收藏',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建收藏列表
  Widget _buildFavoriteList() {
    final favoriteFundsData = _demoFunds
        .where((fund) => _favoriteFunds.contains(fund.fundCode))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: favoriteFundsData.length,
      itemBuilder: (context, index) {
        final fund = favoriteFundsData[index];
        final position = _demoFunds.indexOf(fund) + 1;

        return Dismissible(
          key: Key(fund.fundCode),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            await _toggleFavorite(fund.fundCode);
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: FundCardHeader(
              fund: fund,
              position: position,
              isFavorite: true,
              cardSize: FundCardSize.compact,
              onTap: () => _addRecentlyViewed(fund.fundCode),
              onFavorite: (favorite) => _toggleFavorite(fund.fundCode),
            ),
          ),
        );
      },
    );
  }

  /// 构建显示设置标签页
  Widget _buildDisplaySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片尺寸设置
          _buildSettingsSection(
            '卡片尺寸',
            Icons.aspect_ratio,
            [
              RadioListTile<FundCardSize>(
                title: const Text('紧凑模式'),
                subtitle: const Text('显示较少信息，节省空间'),
                value: FundCardSize.compact,
                groupValue: _displayPreferences.cardSize,
                onChanged: (value) {
                  if (value != null) {
                    _updateDisplayPreferences(
                      _displayPreferences.copyWith(cardSize: value),
                    );
                  }
                },
              ),
              RadioListTile<FundCardSize>(
                title: const Text('标准模式'),
                subtitle: const Text('均衡的信息显示'),
                value: FundCardSize.normal,
                groupValue: _displayPreferences.cardSize,
                onChanged: (value) {
                  if (value != null) {
                    _updateDisplayPreferences(
                      _displayPreferences.copyWith(cardSize: value),
                    );
                  }
                },
              ),
              RadioListTile<FundCardSize>(
                title: const Text('扩展模式'),
                subtitle: const Text('显示完整信息'),
                value: FundCardSize.expanded,
                groupValue: _displayPreferences.cardSize,
                onChanged: (value) {
                  if (value != null) {
                    _updateDisplayPreferences(
                      _displayPreferences.copyWith(cardSize: value),
                    );
                  }
                },
              ),
            ],
          ),

          // 显示选项
          _buildSettingsSection(
            '显示选项',
            Icons.visibility,
            [
              SwitchListTile(
                title: const Text('显示排名徽章'),
                subtitle: const Text('在卡片左上角显示排名'),
                value: _displayPreferences.showRankingBadge,
                onChanged: (value) {
                  _updateDisplayPreferences(
                    _displayPreferences.copyWith(showRankingBadge: value),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('显示公司信息'),
                subtitle: const Text('显示基金公司名称'),
                value: _displayPreferences.showCompanyInfo,
                onChanged: (value) {
                  _updateDisplayPreferences(
                    _displayPreferences.copyWith(showCompanyInfo: value),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('显示基金类型'),
                subtitle: const Text('显示基金类型标签'),
                value: _displayPreferences.showFundType,
                onChanged: (value) {
                  _updateDisplayPreferences(
                    _displayPreferences.copyWith(showFundType: value),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('显示收益率'),
                subtitle: const Text('显示各时间段收益率'),
                value: _displayPreferences.showReturnRates,
                onChanged: (value) {
                  _updateDisplayPreferences(
                    _displayPreferences.copyWith(showReturnRates: value),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('显示趋势指标'),
                subtitle: const Text('显示涨跌箭头和颜色'),
                value: _displayPreferences.showTrendIndicators,
                onChanged: (value) {
                  _updateDisplayPreferences(
                    _displayPreferences.copyWith(showTrendIndicators: value),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('启用动画效果'),
                subtitle: const Text('卡片加载和交互动画'),
                value: _displayPreferences.enableAnimations,
                onChanged: (value) {
                  _updateDisplayPreferences(
                    _displayPreferences.copyWith(enableAnimations: value),
                  );
                },
              ),
            ],
          ),

          // 排序设置
          _buildSettingsSection(
            '排序设置',
            Icons.sort,
            [
              ListTile(
                title: const Text('默认排序方式'),
                subtitle: Text(
                    _getSortByDisplayName(_displayPreferences.defaultSortBy)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showSortByDialog,
              ),
              ListTile(
                title: const Text('排序顺序'),
                subtitle: Text(_displayPreferences.defaultSortOrder == 'desc'
                    ? '降序'
                    : '升序'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showSortOrderDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建设置分组
  Widget _buildSettingsSection(
      String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  /// 获取排序方式显示名称
  String _getSortByDisplayName(String sortBy) {
    switch (sortBy) {
      case 'return1D':
        return '日收益率';
      case 'return1M':
        return '近1月收益率';
      case 'return1Y':
        return '近1年收益率';
      case 'fundScale':
        return '基金规模';
      case 'ranking':
        return '排名';
      default:
        return '默认排序';
    }
  }

  /// 显示排序方式选择对话框
  Future<void> _showSortByDialog() async {
    final options = [
      {'value': 'return1D', 'label': '日收益率'},
      {'value': 'return1M', 'label': '近1月收益率'},
      {'value': 'return1Y', 'label': '近1年收益率'},
      {'value': 'fundScale', 'label': '基金规模'},
      {'value': 'ranking', 'label': '排名'},
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择排序方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return RadioListTile<String>(
              title: Text(option['label']!),
              value: option['value']!,
              groupValue: _displayPreferences.defaultSortBy,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      _updateDisplayPreferences(
        _displayPreferences.copyWith(defaultSortBy: selected),
      );
    }
  }

  /// 显示排序顺序选择对话框
  Future<void> _showSortOrderDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择排序顺序'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('降序（从高到低）'),
              value: 'desc',
              groupValue: _displayPreferences.defaultSortOrder,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('升序（从低到高）'),
              value: 'asc',
              groupValue: _displayPreferences.defaultSortOrder,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      _updateDisplayPreferences(
        _displayPreferences.copyWith(defaultSortOrder: selected),
      );
    }
  }

  /// 构建历史记录标签页
  Widget _buildHistoryTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: '搜索历史'),
              Tab(icon: Icon(Icons.visibility), text: '浏览历史'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSearchHistory(),
                _buildRecentlyViewed(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索历史
  Widget _buildSearchHistory() {
    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索基金名称或代码...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  FundUserPreferences.clearSearchHistory().then((_) {
                    _loadUserPreferences();
                    _showMessage('搜索历史已清空');
                  });
                },
                icon: const Icon(Icons.clear_all),
                tooltip: '清空历史',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onSubmitted: (value) {
              _addSearchHistory(value);
              _showMessage('已添加到搜索历史: $value');
            },
          ),
        ),

        // 搜索历史列表
        Expanded(
          child: _searchHistory.isEmpty
              ? _buildEmptySearchHistory()
              : _buildSearchHistoryList(),
        ),
      ],
    );
  }

  /// 构建空搜索历史状态
  Widget _buildEmptySearchHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无搜索历史',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在上方搜索框中搜索基金',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索历史列表
  Widget _buildSearchHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final query = _searchHistory[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(query),
          trailing: IconButton(
            onPressed: () async {
              await FundUserPreferences.addSearchHistory(query);
              _loadUserPreferences();
            },
            icon: const Icon(Icons.trending_up),
            tooltip: '重新搜索',
          ),
          onTap: () {
            _showMessage('重新搜索: $query');
          },
        );
      },
    );
  }

  /// 构建浏览历史
  Widget _buildRecentlyViewed() {
    return Column(
      children: [
        if (_recentlyViewed.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await FundUserPreferences.clearRecentlyViewedFunds();
                _loadUserPreferences();
                _showMessage('浏览历史已清空');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('清空浏览历史'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        Expanded(
          child: _recentlyViewed.isEmpty
              ? _buildEmptyRecentlyViewed()
              : _buildRecentlyViewedList(),
        ),
      ],
    );
  }

  /// 构建空浏览历史状态
  Widget _buildEmptyRecentlyViewed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无浏览历史',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击基金卡片查看详情',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建浏览历史列表
  Widget _buildRecentlyViewedList() {
    final viewedFundsData = _demoFunds
        .where((fund) => _recentlyViewed.contains(fund.fundCode))
        .toList();

    // 按浏览时间排序
    _recentlyViewed.sort((a, b) =>
        _recentlyViewed.indexOf(a).compareTo(_recentlyViewed.indexOf(b)));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _recentlyViewed.length,
      itemBuilder: (context, index) {
        final fundCode = _recentlyViewed[index];
        final fund = viewedFundsData.firstWhere(
          (f) => f.fundCode == fundCode,
          orElse: () => _demoFunds.first,
        );
        final position = _demoFunds.indexOf(fund) + 1;
        final isFavorite = _favoriteFunds.contains(fundCode);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                FundCardTheme.rankingBadgeColors[position] ?? Colors.grey,
            child: Text(
              position.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(fund.fundName),
          subtitle: Text('${fund.fundCode} • ${fund.company}'),
          trailing: IconButton(
            onPressed: () => _toggleFavorite(fundCode),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
          ),
          onTap: () => _addRecentlyViewed(fundCode),
        );
      },
    );
  }

  /// 构建统计分析标签页
  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: FundUserPreferences.getUserStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('无法加载统计数据'));
        }

        final stats = snapshot.data!;
        final favoriteCount = stats['favoriteCount'] as int;
        final viewedCount = stats['viewedCount'] as int;
        final searchCount = stats['searchCount'] as int;
        final totalActions = stats['totalActionCount'] as int;
        final lastActivity = stats['lastActivity'] as DateTime?;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 总览卡片
              _buildOverviewCard(
                  favoriteCount, viewedCount, searchCount, totalActions),

              const SizedBox(height: 16),

              // 活动统计
              _buildActivityCard(lastActivity, totalActions),

              const SizedBox(height: 16),

              // 收藏分析
              _buildFavoriteAnalysis(),

              const SizedBox(height: 16),

              // 使用建议
              _buildUsageTips(),
            ],
          ),
        );
      },
    );
  }

  /// 构建总览卡片
  Widget _buildOverviewCard(
      int favoriteCount, int viewedCount, int searchCount, int totalActions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '使用总览',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '收藏基金',
                    favoriteCount,
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '浏览基金',
                    viewedCount,
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '搜索次数',
                    searchCount,
                    Icons.search,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '总操作数',
                    totalActions,
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建活动统计卡片
  Widget _buildActivityCard(DateTime? lastActivity, int totalActions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '活动统计',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('最后活动时间'),
              subtitle: Text(lastActivity != null
                  ? _formatDateTime(lastActivity)
                  : '暂无记录'),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('活跃度'),
              subtitle: Text(_getActivityLevel(totalActions)),
              trailing: _buildActivityIndicator(totalActions),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建收藏分析卡片
  Widget _buildFavoriteAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '收藏分析',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_favoriteFunds.isEmpty)
              const Text('暂无收藏数据')
            else
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.pie_chart),
                    title: const Text('收藏分布'),
                    subtitle: Text('共${_favoriteFunds.length}只基金'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('基金类型'),
                    subtitle: Text(_analyzeFavoriteTypes()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('基金公司'),
                    subtitle: Text(_analyzeFavoriteCompanies()),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 构建使用建议卡片
  Widget _buildUsageTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '使用建议',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._generateUsageTips().map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 分析收藏基金类型
  String _analyzeFavoriteTypes() {
    final favoriteFundsData = _demoFunds
        .where((fund) => _favoriteFunds.contains(fund.fundCode))
        .toList();

    if (favoriteFundsData.isEmpty) return '暂无数据';

    final typeCount = <String, int>{};
    for (final fund in favoriteFundsData) {
      typeCount[fund.fundType] = (typeCount[fund.fundType] ?? 0) + 1;
    }

    final sortedTypes = typeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTypes.take(3).map((e) => '${e.key}(${e.value})').join('、');
  }

  /// 分析收藏基金公司
  String _analyzeFavoriteCompanies() {
    final favoriteFundsData = _demoFunds
        .where((fund) => _favoriteFunds.contains(fund.fundCode))
        .toList();

    if (favoriteFundsData.isEmpty) return '暂无数据';

    final companyCount = <String, int>{};
    for (final fund in favoriteFundsData) {
      companyCount[fund.company] = (companyCount[fund.company] ?? 0) + 1;
    }

    final sortedCompanies = companyCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCompanies.take(3).map((e) => '${e.key}(${e.value})').join('、');
  }

  /// 生成使用建议
  List<String> _generateUsageTips() {
    final tips = <String>[];

    if (_favoriteFunds.isEmpty) {
      tips.add('建议收藏一些感兴趣的基金，方便后续查看');
    } else if (_favoriteFunds.length < 5) {
      tips.add('可以多收藏几只基金进行对比分析');
    } else if (_favoriteFunds.length > 20) {
      tips.add('收藏的基金较多，建议定期清理不关注的基金');
    }

    if (_searchHistory.isEmpty) {
      tips.add('使用搜索功能可以快速找到目标基金');
    }

    if (_recentlyViewed.length < 10) {
      tips.add('多浏览不同的基金，了解市场动态');
    }

    tips.add('定期查看基金表现，调整投资策略');
    tips.add('关注基金公告和季报，了解基金经理操作思路');

    return tips;
  }

  /// 获取活跃度等级
  String _getActivityLevel(int totalActions) {
    if (totalActions < 10) return '偶尔使用';
    if (totalActions < 50) return '一般使用';
    if (totalActions < 100) return '经常使用';
    return '重度使用';
  }

  /// 构建活跃度指示器
  Widget _buildActivityIndicator(int totalActions) {
    Color color;
    double value;

    if (totalActions < 10) {
      color = Colors.red;
      value = 0.25;
    } else if (totalActions < 50) {
      color = Colors.orange;
      value = 0.5;
    } else if (totalActions < 100) {
      color = Colors.blue;
      value = 0.75;
    } else {
      color = Colors.green;
      value = 1.0;
    }

    return SizedBox(
      width: 60,
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 构建数据管理标签页
  Widget _buildDataManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 数据备份
          _buildDataSection(
            '数据备份',
            Icons.backup,
            [
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('导出用户数据'),
                subtitle: const Text('将偏好设置导出为JSON文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportUserData,
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('导入用户数据'),
                subtitle: const Text('从JSON文件恢复偏好设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMessage('导入功能开发中'),
              ),
            ],
          ),

          // 数据清理
          _buildDataSection(
            '数据清理',
            Icons.cleaning_services,
            [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('清空收藏基金'),
                subtitle: const Text('删除所有收藏的基金'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final confirmed = await _showConfirmDialog('确定要清空所有收藏基金吗？');
                  if (confirmed) {
                    await FundUserPreferences.clearAllFavorites();
                    _loadUserPreferences();
                    _showMessage('收藏基金已清空');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('清空历史记录'),
                subtitle: const Text('删除搜索和浏览历史'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final confirmed = await _showConfirmDialog('确定要清空所有历史记录吗？');
                  if (confirmed) {
                    await FundUserPreferences.clearSearchHistory();
                    await FundUserPreferences.clearRecentlyViewedFunds();
                    _loadUserPreferences();
                    _showMessage('历史记录已清空');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('重置显示设置'),
                subtitle: const Text('恢复默认显示偏好'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final confirmed = await _showConfirmDialog('确定要重置显示设置吗？');
                  if (confirmed) {
                    await FundUserPreferences.resetToDefaults();
                    _loadUserPreferences();
                    _showMessage('显示设置已重置');
                  }
                },
              ),
            ],
          ),

          // 危险操作
          _buildDataSection(
            '危险操作',
            Icons.warning,
            [
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red[600]),
                title: Text(
                  '清空所有数据',
                  style: TextStyle(color: Colors.red[600]),
                ),
                subtitle: Text(
                  '删除所有用户数据，此操作不可恢复',
                  style: TextStyle(color: Colors.red[600]),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _clearAllData,
              ),
            ],
          ),

          // 存储信息
          _buildStorageInfo(),
        ],
      ),
    );
  }

  /// 构建数据分组
  Widget _buildDataSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  /// 构建存储信息
  Widget _buildStorageInfo() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final prefs = snapshot.data!;
        final keys = prefs.getKeys();
        final dataSize = _calculateDataSize(prefs);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '存储信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('存储键数量'),
                  subtitle: Text('${keys.length} 个键'),
                ),
                ListTile(
                  leading: const Icon(Icons.data_usage),
                  title: const Text('数据大小'),
                  subtitle: Text('${dataSize.toStringAsFixed(2)} KB'),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('存储位置'),
                  subtitle: const Text('应用本地存储'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 计算数据大小
  double _calculateDataSize(SharedPreferences prefs) {
    final keys = prefs.getKeys();
    int totalSize = 0;

    for (final key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        totalSize += value.toString().length;
      }
    }

    return totalSize / 1024; // 转换为KB
  }
}

/// 显示偏好设置扩展方法
extension FundDisplayPreferencesExtension on FundDisplayPreferences {
  /// 复制并更新字段
  FundDisplayPreferences copyWithField(String key, dynamic value) {
    switch (key) {
      case 'showRankingBadge':
        return copyWith(showRankingBadge: value as bool?);
      case 'showCompanyInfo':
        return copyWith(showCompanyInfo: value as bool?);
      case 'showFundType':
        return copyWith(showFundType: value as bool?);
      case 'showReturnRates':
        return copyWith(showReturnRates: value as bool?);
      case 'showNavInfo':
        return copyWith(showNavInfo: value as bool?);
      case 'defaultSortBy':
        return copyWith(defaultSortBy: value as String?);
      case 'defaultSortOrder':
        return copyWith(defaultSortOrder: value as String?);
      case 'itemsPerPage':
        return copyWith(itemsPerPage: value as int?);
      case 'cardSize':
        return copyWith(cardSize: value as FundCardSize?);
      case 'enableAnimations':
        return copyWith(enableAnimations: value as bool?);
      case 'showTrendIndicators':
        return copyWith(showTrendIndicators: value as bool?);
      case 'enableAutoRefresh':
        return copyWith(enableAutoRefresh: value as bool?);
      case 'autoRefreshInterval':
        return copyWith(autoRefreshInterval: value as Duration?);
      default:
        return this;
    }
  }
}

/// 演示应用入口
void main() {
  runApp(const FundUserPreferencesDemoApp());
}

/// 演示应用
class FundUserPreferencesDemoApp extends StatelessWidget {
  const FundUserPreferencesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金用户偏好管理演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FundUserPreferencesDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}
