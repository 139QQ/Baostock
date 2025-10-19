import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/entities/fund_ranking.dart';
import '../fund_exploration/domain/data/services/high_performance_fund_service.dart';
import '../widgets/optimized_fund_ranking_list.dart';

// 导入RequestPriority枚举
import '../fund_exploration/domain/data/services/high_performance_fund_service.dart'
    as service;
import '../fund_exploration/domain/data/models/fund_dto.dart';
import '../fund_exploration/domain/models/fund.dart' as exploration_models;

/// 优化版基金排行榜页面
///
/// 展示如何使用优化后的组件和服务：
/// - 高性能数据请求
/// - 智能缓存策略
/// - 懒加载和分页
/// - 内存优化
class OptimizedFundRankingPage extends StatefulWidget {
  const OptimizedFundRankingPage({super.key});

  @override
  State<OptimizedFundRankingPage> createState() =>
      _OptimizedFundRankingPageState();
}

class _OptimizedFundRankingPageState extends State<OptimizedFundRankingPage>
    with AutomaticKeepAliveClientMixin {
  final FundRankingListController _listController = FundRankingListController();
  final HighPerformanceFundService _fundService = HighPerformanceFundService();
  final ScrollController _scrollController = ScrollController();

  String _selectedSymbol = '全部';
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    // 预热缓存
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _fundService.warmupCache();
    });

    // 加载初始数据
    await _loadInitialData();
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rankings = await _fundService.getFundRankings(
        symbol: _selectedSymbol,
        priority: service.RequestPriority.high,
        enableCache: true,
        pageSize: 20,
      );

      final fundRankings = _convertRankingsList(rankings);
      _listController.setInitialData(fundRankings);
    } catch (e) {
      setState(() {
        _error = '数据加载失败: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载更多数据
  Future<void> _loadMoreData() async {
    if (_listController.isLoading || !_listController.hasMore) return;

    _listController.setLoading(true);

    try {
      final rankings = await _fundService.getFundRankings(
        symbol: _selectedSymbol,
        priority: service.RequestPriority.normal,
        enableCache: true,
        pageSize: 20,
      );

      final fundRankings = _convertRankingsList(rankings);
      _listController.addMoreData(fundRankings);
    } catch (e) {
      setState(() {
        _error = '加载更多数据失败: ${e.toString()}';
      });
    } finally {
      _listController.setLoading(false);
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    _listController.reset();

    try {
      final rankings = await _fundService.getFundRankings(
        symbol: _selectedSymbol,
        priority: service.RequestPriority.critical,
        enableCache: false, // 强制刷新
        pageSize: 20,
      );

      final fundRankings = _convertRankingsList(rankings);
      _listController.setInitialData(fundRankings);
    } catch (e) {
      setState(() {
        _error = '刷新失败: ${e.toString()}';
      });
    }
  }

  /// 切换基金类型
  Future<void> _onSymbolChanged(String symbol) async {
    if (_selectedSymbol == symbol) return;

    setState(() {
      _selectedSymbol = symbol;
    });

    _listController.reset();
    await _loadInitialData();
  }

  /// 处理基金点击
  void _onFundTap(FundRanking ranking) {
    // 这里可以导航到基金详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('点击了基金: ${ranking.fundName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 处理收藏
  void _onFavorite(String fundCode, bool isFavorite) {
    _listController.toggleFavorite(fundCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '已添加到收藏' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 显示性能统计
  void _showPerformanceStats() {
    final stats = _fundService.getPerformanceStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('性能统计'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('总请求数: ${stats['requests']}'),
              const SizedBox(height: 4),
              Text('请求缓存命中: ${stats['cacheHits']['request']}'),
              const SizedBox(height: 4),
              Text('响应缓存命中: ${stats['cacheHits']['response']}'),
              const SizedBox(height: 4),
              Text(
                  '平均响应时间: ${stats['averageResponseTime']?.toStringAsFixed(2)}ms'),
              const SizedBox(height: 4),
              Text('错误率: ${(stats['errorRate'] * 100).toStringAsFixed(2)}%'),
              const SizedBox(height: 4),
              Text('活跃连接数: ${stats['activeConnections']}'),
              const SizedBox(height: 4),
              Text('队列请求数: ${stats['queuedRequests']}'),
              const SizedBox(height: 4),
              Text('缓存响应数: ${stats['cachedResponses']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              _fundService.clearAllCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清空')),
              );
            },
            child: const Text('清空缓存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('基金排行榜（优化版）'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showPerformanceStats,
            icon: const Icon(Icons.analytics),
            tooltip: '性能统计',
          ),
        ],
      ),
      body: Column(
        children: [
          // 基金类型选择器
          _buildSymbolSelector(),

          // 主内容区域
          Expanded(
            child: OptimizedFundRankingList(
              rankings: _listController.rankings,
              isLoading: _isLoading || _listController.isLoading,
              hasMore: _listController.hasMore,
              error: _error,
              onLoadMore: _loadMoreData,
              onRefresh: _refreshData,
              onFundTap: _onFundTap,
              onFavorite: _onFavorite,
              favoriteFunds: _listController.favoriteFunds,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建基金类型选择器
  Widget _buildSymbolSelector() {
    final symbols = ['全部', '股票型', '混合型', '债券型', '指数型'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          final isSelected = symbol == _selectedSymbol;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(symbol),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onSymbolChanged(symbol);
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  /// 转换探索模型FundRanking为实体模型FundRanking
  FundRanking _convertToEntityModel(
      exploration_models.FundRanking explorationRanking) {
    return FundRanking(
      fundCode: explorationRanking.fundCode,
      fundName: explorationRanking.fundName,
      fundType: explorationRanking.fundType,
      company: explorationRanking.company,
      rankingPosition: explorationRanking.rankingPosition,
      totalCount: explorationRanking.totalCount,
      unitNav: explorationRanking.unitNav,
      accumulatedNav: explorationRanking.accumulatedNav,
      dailyReturn: explorationRanking.dailyReturn,
      return1W: explorationRanking.return1W,
      return1M: explorationRanking.return1M,
      return3M: explorationRanking.return3M,
      return6M: explorationRanking.return6M,
      return1Y: explorationRanking.return1Y,
      return2Y: explorationRanking.return2Y,
      return3Y: explorationRanking.return3Y,
      returnYTD: explorationRanking.returnYTD,
      returnSinceInception: 0.0, // 使用默认值
      rankingDate: DateTime.now(),
      rankingPeriod: RankingPeriod.oneYear,
      rankingType: RankingType.overall,
    );
  }

  /// 转换基金排行榜列表
  List<FundRanking> _convertRankingsList(List<FundRankingDto> dtoList) {
    return dtoList.map((dto) {
      final explorationRanking = dto.toDomainModel();
      return _convertToEntityModel(explorationRanking);
    }).toList();
  }
}

/// 空安全处理方法
extension Unawaited on Future<void> {
  void unawaited() {
    // 用于不需要等待的异步操作
  }
}
