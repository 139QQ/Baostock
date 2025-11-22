import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/widgets/portfolio_manager.dart';
import 'package:jisu_fund_analyzer/src/services/optimized_cache_manager_v3.dart';
import 'package:jisu_fund_analyzer/src/core/di/di_initializer.dart';
import 'package:jisu_fund_analyzer/src/models/fund_info.dart' as models;
import 'package:jisu_fund_analyzer/src/services/fund_api_analyzer.dart';

/// 自选基金页面
///
/// 用于展示和管理用户自选基金列表的页面，提供以下功能：
/// - 展示自选基金列表
/// - 添加/删除自选基金
/// - 实时更新基金数据
/// - 自选基金分组管理
/// - 排序和筛选功能
class WatchlistPage extends StatefulWidget {
  /// 构造函数
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final TextEditingController _searchController = TextEditingController();
  FundFavoriteSortType _currentSortType = FundFavoriteSortType.addTime;
  final FundFavoriteSortDirection _currentSortDirection =
      FundFavoriteSortDirection.descending;

  // 智能搜索相关状态 - 使用共享的缓存管理器实例
  bool _isSearching = false;
  // List<models.FundInfo> _searchSuggestions = []; // 暂时未使用，注释保留
  List<String> _searchHistory = [];
  List<String> _popularSearches = [];
  List<models.FundInfo> _searchResults = [];
  Timer? _searchDebounce;
  final FocusNode _searchFocusNode = FocusNode();

  // 使用依赖注入的缓存管理器实例，确保整个应用使用同一个实例
  late OptimizedCacheManagerV3 _sharedCacheManager;

  // 基金API分析器实例
  final FundApiAnalyzer _fundApiAnalyzer = FundApiAnalyzer();

  // 标记回调是否已添加，避免重复添加或移除未添加的回调
  bool _callbackAdded = false;

  @override
  void initState() {
    super.initState();

    // 从依赖注入容器获取共享的缓存管理器实例
    _sharedCacheManager = sl<OptimizedCacheManagerV3>();

    // 完全异步初始化，确保不阻塞UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSmartSearch();
      _loadPopularSearches();
      // 初始化自选基金Cubit
      _initializeFundFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();

    // 移除缓存同步回调（只有已添加的情况下才移除）
    if (_callbackAdded) {
      try {
        _sharedCacheManager.removeSyncCallback(_onCacheChanged);
        _callbackAdded = false;
        debugPrint('✅ 缓存同步回调已安全移除');
      } catch (e) {
        debugPrint('⚠️ 移除缓存同步回调时出错: $e');
      }
    }
    super.dispose();
  }

  /// 缓存状态变更回调
  void _onCacheChanged() {
    if (mounted) {
      setState(() {
        // 这里可以更新UI状态，比如显示缓存已刷新的提示
      });
    }
  }

  /// 初始化自选基金功能
  Future<void> _initializeFundFavorites() async {
    try {
      print('🔄 开始初始化自选基金功能');

      // 确保FundFavoriteService已初始化
      final fundFavoriteService = sl<FundFavoriteService>();
      await fundFavoriteService.initialize();
      print('✅ FundFavoriteService 初始化成功');

      // 初始化FundFavoriteCubit
      if (mounted) {
        context.read<FundFavoriteCubit>().initialize();
        print('✅ FundFavoriteCubit 初始化成功');
      }
    } catch (e) {
      print('❌ 初始化自选基金功能失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('自选功能初始化失败: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// 初始化智能搜索功能 - 使用共享的三步走缓存策略V3
  Future<void> _initializeSmartSearch() async {
    try {
      // 使用共享的缓存管理器实例，避免重复初始化
      if (!_sharedCacheManager.getCacheStats()['isInitialized']) {
        await _sharedCacheManager.initialize();
        debugPrint('✅ 共享缓存管理器V3初始化完成');
      } else {
        debugPrint('✅ 共享缓存管理器V3已初始化，跳过重复初始化');
      }

      // 注册缓存状态变更回调
      if (!_callbackAdded) {
        _sharedCacheManager.addSyncCallback(_onCacheChanged);
        _callbackAdded = true;
        debugPrint('✅ 缓存同步回调已添加');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ 初始化共享缓存管理器失败: $e');
    }
  }

  /// 加载热门搜索词
  Future<void> _loadPopularSearches() async {
    try {
      // 延迟加载，避免阻塞UI，并等待初始化完成
      await Future.delayed(const Duration(milliseconds: 200));

      // 使用共享的缓存管理器实例
      final suggestions = _sharedCacheManager.getSearchSuggestions('');
      if (mounted) {
        setState(() {
          _popularSearches = suggestions.take(8).toList();
        });
        debugPrint('✅ 热门搜索词加载完成: ${_popularSearches.length} 个');

        // 如果没有从缓存获取到数据，使用默认热门搜索
        if (_popularSearches.isEmpty) {
          _setDefaultPopularSearches();
        }
      }
    } catch (e) {
      debugPrint('❌ 加载热门搜索失败: $e');
      _setDefaultPopularSearches();
    }
  }

  /// 设置默认热门搜索词
  void _setDefaultPopularSearches() {
    if (mounted) {
      setState(() {
        _popularSearches = [
          '新能源',
          '医疗健康',
          '消费升级',
          '科技创新',
          '大盘蓝筹',
          '债券基金',
          '货币基金',
          'QDII基金',
        ];
      });
      debugPrint('✅ 使用默认热门搜索词: ${_popularSearches.length} 个');
    }
  }

  /// 执行智能搜索
  Future<void> _performSmartSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // 使用共享的缓存管理器实例进行搜索，限制结果数量防止UI阻塞
      final results = _sharedCacheManager.searchFunds(query, limit: 30);

      if (mounted) {
        setState(() {
          _searchResults = results
              .map((fund) => models.FundInfo(
                    code: fund.code,
                    name: fund.name,
                    type: fund.type,
                    pinyinAbbr: fund.pinyinAbbr,
                    pinyinFull: fund.pinyinFull,
                  ))
              .toList();
          _isSearching = false;
        });

        // 记录搜索历史
        _addToSearchHistory(query);
      }
    } catch (e) {
      debugPrint('智能搜索失败: $e');
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
    }
  }

  /// 添加到搜索历史
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
    });
  }

  //  /// 清空搜索历史 - 暂时未使用，注释保留
//  void _clearSearchHistory() {
//    setState(() {
//      _searchHistory.clear();
//    });
//  }

  /// 显示添加基金对话框
  void _showAddFundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddFundDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '自选基金',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFundDialog,
            tooltip: '添加基金',
          ),
          PopupMenuButton<FundFavoriteSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (sortType) {
              setState(() {
                _currentSortType = sortType;
              });
              // 触发排序
              context
                  .read<FundFavoriteCubit>()
                  .sortFavorites(sortType, _currentSortDirection);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FundFavoriteSortType.addTime,
                child: Text(_getSortTypeLabel(FundFavoriteSortType.addTime)),
              ),
              PopupMenuItem(
                value: FundFavoriteSortType.fundCode,
                child: Text(_getSortTypeLabel(FundFavoriteSortType.fundCode)),
              ),
              PopupMenuItem(
                value: FundFavoriteSortType.fundName,
                child: Text(_getSortTypeLabel(FundFavoriteSortType.fundName)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 智能搜索区域
          _buildSmartSearchSection(),

          // 自选基金列表
          Expanded(
            child: BlocBuilder<FundFavoriteCubit, FundFavoriteState>(
              builder: (context, state) {
                if (state is FundFavoriteLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is FundFavoriteLoaded) {
                  final favorites = state.favorites;

                  if (favorites.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<FundFavoriteCubit>().loadAllFavorites();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = favorites[index];
                        return FundFavoriteCard(
                          favorite: favorite,
                          onTap: () async {
                            try {
                              // 使用 WidgetsBinding.instance 确保不阻塞当前帧
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) async {
                                if (!mounted) return;

                                // 延迟导航，给UI时间响应
                                await Future.delayed(
                                    const Duration(milliseconds: 10));

                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider<
                                          PortfolioAnalysisCubit>.value(
                                        value: sl<PortfolioAnalysisCubit>(),
                                        child: const PortfolioManager(),
                                      ),
                                    ),
                                  );
                                }
                              });
                            } catch (e) {
                              debugPrint('导航失败: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('导航失败: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          onRemove: () {
                            _showRemoveConfirmDialog(favorite);
                          },
                        );
                      },
                    ),
                  );
                } else if (state is FundFavoriteError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '加载失败',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<FundFavoriteCubit>()
                                .loadAllFavorites();
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return _buildEmptyState();
                }
              },
            ),
          ),
        ],
      ),
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFundDialog,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Stack(
          children: [
            Icon(Icons.add),
            // 如果需要可以添加加载指示器
          ],
        ),
      ),
    );
  }

  /// 构建智能搜索区域
  Widget _buildSmartSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 搜索输入框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '搜索基金代码、名称或基金经理...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  _performSmartSearch(value);
                });
              },
              onSubmitted: _performSmartSearch,
            ),
          ),

          // 搜索结果和历史
          if (_searchController.text.isNotEmpty || _searchResults.isNotEmpty)
            _buildSearchResults(),
        ],
      ),
    );
  }

  /// 构建搜索结果区域
  Widget _buildSearchResults() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: _isSearching
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _searchResults.isEmpty
              ? _buildNoResults()
              : _buildSearchResultsList(),
    );
  }

  /// 构建无结果提示
  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            '未找到相关基金',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果列表
  Widget _buildSearchResultsList() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final fund = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              fund.code.substring(0, 2),
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            fund.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${fund.code} | ${fund.type}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: const Text(
            '----',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            // 添加到自选
            _addFundToWatchlist(fund);
          },
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有自选基金',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角 + 按钮添加您关注的基金',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddFundDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加基金'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取排序类型标签
  String _getSortTypeLabel(FundFavoriteSortType sortType) {
    switch (sortType) {
      case FundFavoriteSortType.addTime:
        return '添加时间';
      case FundFavoriteSortType.fundCode:
        return '基金代码';
      case FundFavoriteSortType.fundName:
        return '基金名称';
      case FundFavoriteSortType.currentNav:
        return '当前净值';
      case FundFavoriteSortType.dailyChange:
        return '日涨跌幅';
      case FundFavoriteSortType.fundScale:
        return '基金规模';
      case FundFavoriteSortType.custom:
        return '自定义排序';
    }
  }

  /// 显示删除确认对话框
  void _showRemoveConfirmDialog(FundFavorite favorite) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除自选基金 "${favorite.fundName}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context
                    .read<FundFavoriteCubit>()
                    .removeFavorite(favorite.fundCode);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  /// 添加基金到自选列表
  void _addFundToWatchlist(models.FundInfo fund) {
    try {
      print('🔄 开始添加基金到自选列表: ${fund.code} - ${fund.name}');

      final favorite = FundFavorite(
        fundCode: fund.code,
        fundName: fund.name,
        fundType: fund.type,
        fundManager: '未知经理', // FundInfo没有manager属性，使用默认值
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('✅ 创建FundFavorite对象成功');
      context.read<FundFavoriteCubit>().addFavorite(favorite);
      print('✅ 调用addFavorite成功');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加 "${fund.name}" 到自选'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ 添加基金到自选列表失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // 清空搜索
    _searchController.clear();
    setState(() {
      _searchResults.clear();
    });
  }
}

/// 基金自选卡片组件
class FundFavoriteCard extends StatefulWidget {
  final FundFavorite favorite;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const FundFavoriteCard({
    super.key,
    required this.favorite,
    this.onTap,
    this.onRemove,
  });

  @override
  State<FundFavoriteCard> createState() => _FundFavoriteCardState();
}

class _FundFavoriteCardState extends State<FundFavoriteCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isProcessing
            ? null
            : () {
                if (_isProcessing) return;

                setState(() {
                  _isProcessing = true;
                });

                // 异步处理点击，避免阻塞UI
                Future.microtask(() async {
                  try {
                    widget.onTap?.call();
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                  }
                });
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 基金信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.favorite.fundName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.favorite.fundCode} | ${widget.favorite.fundType}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (widget.favorite.fundManager.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '基金经理: ${widget.favorite.fundManager}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '添加时间: ${_formatDate(widget.favorite.addedAt)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // 操作按钮
              Column(
                children: [
                  // 显示处理状态或查看详情按钮
                  _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: Colors.red[400],
                          ),
                          onPressed: () {
                            // 查看详情
                          },
                          tooltip: '查看详情',
                        ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.grey[600],
                    ),
                    onPressed: widget.onRemove,
                    tooltip: '删除',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 添加基金对话框
class AddFundDialog extends StatefulWidget {
  const AddFundDialog({super.key});

  @override
  State<AddFundDialog> createState() => _AddFundDialogState();
}

class _AddFundDialogState extends State<AddFundDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fundCodeController = TextEditingController();
  final TextEditingController _fundNameController = TextEditingController();
  final TextEditingController _fundManagerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  // 基金API分析器实例
  final FundApiAnalyzer _fundApiAnalyzer = FundApiAnalyzer();

  // 共享缓存管理器实例
  final OptimizedCacheManagerV3 _sharedCacheManager =
      sl<OptimizedCacheManagerV3>();

  @override
  void dispose() {
    _fundCodeController.dispose();
    _fundNameController.dispose();
    _fundManagerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  '添加自选基金',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 表单
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 基金代码
                      TextFormField(
                        controller: _fundCodeController,
                        decoration: InputDecoration(
                          labelText: '基金代码 *',
                          hintText: '请输入6位基金代码',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.code),
                        ),
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入基金代码';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                            return '基金代码必须是6位数字';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 基金名称
                      TextFormField(
                        controller: _fundNameController,
                        decoration: InputDecoration(
                          labelText: '基金名称',
                          hintText: '基金名称将自动查询',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        readOnly: true,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // 基金经理
                      TextFormField(
                        controller: _fundManagerController,
                        decoration: InputDecoration(
                          labelText: '基金经理',
                          hintText: '基金经理将自动查询',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        readOnly: true,
                      ),

                      const SizedBox(height: 16),

                      // 备注
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: '备注',
                          hintText: '添加备注信息（可选）',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addFund,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 添加基金
  Future<void> _addFund() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fundCode = _fundCodeController.text.trim();

      // 这里应该调用API查询基金信息
      // 暂时使用模拟数据
      final mockFundInfo = await _queryFundInfo(fundCode);

      if (mockFundInfo == null) {
        _showError('未找到该基金信息，请检查基金代码是否正确');
        return;
      }

      final favorite = FundFavorite(
        fundCode: mockFundInfo['fund_code']!,
        fundName: mockFundInfo['fund_name']!,
        fundType: mockFundInfo['fund_type'] ?? '未知类型',
        fundManager: mockFundInfo['manager'] ?? '未知经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (!mounted) return;

      context.read<FundFavoriteCubit>().addFavorite(favorite);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加 "${mockFundInfo['fund_name']}" 到自选'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('添加失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 查询基金信息（优先使用缓存，缓存中没有时才调用API）
  Future<Map<String, String>?> _queryFundInfo(String fundCode) async {
    try {
      debugPrint('正在查询基金信息: $fundCode');

      // 第1步：优先从缓存中获取基金信息
      final cachedFund = await _sharedCacheManager.getFundByCode(fundCode);
      if (cachedFund != null) {
        final result = <String, String>{
          'fund_code': cachedFund.code,
          'fund_name': cachedFund.name,
          'fund_type': cachedFund.type,
          'manager': '未知经理', // 缓存中没有经理信息，使用默认值
        };

        debugPrint('✅ 从缓存找到基金信息: ${result['fund_name']}');
        return result;
      }

      debugPrint('⚠️ 缓存中未找到基金信息，尝试从API获取...');

      // 第2步：缓存中没有时，使用API获取
      final fundInfo = await _fundApiAnalyzer.getFundBasicInfo(fundCode);

      if (fundInfo != null) {
        final result = <String, String>{
          'fund_code': fundInfo['fund_code'] ?? '',
          'fund_name': fundInfo['fund_name'] ?? '',
          'fund_type': fundInfo['fund_type'] ?? '未知类型',
          'manager': fundInfo['fund_manager'] ?? '未知经理',
        };

        debugPrint('✅ 从API找到基金信息: ${result['fund_name']}');
        return result;
      }

      debugPrint('❌ 未找到基金信息: $fundCode');
      return null;
    } catch (e) {
      debugPrint('❌ 查询基金信息失败: $e');
      return null;
    }
  }

  //  /// 从基金名称中提取基金类型 - 暂时未使用，注释保留
//  String _extractFundTypeFromName(String fundName) {
//    if (fundName.contains('股票')) {
//      return '股票型';
//    } else if (fundName.contains('债券')) {
//      return '债券型';
//    } else if (fundName.contains('混合')) {
//      return '混合型';
//    } else if (fundName.contains('指数')) {
//      return '指数型';
//    } else if (fundName.contains('QDII')) {
//      return 'QDII';
//    } else if (fundName.contains('FOF')) {
//      return 'FOF';
//    } else if (fundName.contains('货币')) {
//      return '货币型';
//    } else {
//      return '其他类型';
//    }
//  }

  /// 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
