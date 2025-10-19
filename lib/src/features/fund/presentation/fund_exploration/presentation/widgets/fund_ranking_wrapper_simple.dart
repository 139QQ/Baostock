import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fund_ranking_cubit.dart';
import '../../../bloc/fund_ranking_bloc.dart';
import '../../../../domain/entities/fund_ranking.dart';

/// 简化版基金排行包装器
///
/// 使用全局的FundRankingCubit 进行状态管理
/// 避免重复初始化，实现组件级状态缓存
/// 按需加载，避免全局刷新
class FundRankingWrapperSimple extends StatefulWidget {
  const FundRankingWrapperSimple({super.key});

  @override
  State<FundRankingWrapperSimple> createState() =>
      _FundRankingWrapperSimpleState();
}

class _FundRankingWrapperSimpleState extends State<FundRankingWrapperSimple>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _hasInitialized = false;
  bool _isInitializing = false; // 新增：防止重复初始化
  FundRankingCubit? _cubit; // 缓存Provider引用
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 初始化加载动画控制器
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    ));

    // 启动动画
    _loadingAnimationController.repeat(reverse: true);

    // 不在initState中初始化，在build方法中通过Builder和addPostFrameCallback初始化
  }

  /// 初始化数据加载 - 需要在BlocProvider创建后调用
  Future<void> _initializeData(BuildContext context) async {
    if (_hasInitialized || _isInitializing) return;

    _isInitializing = true;
    debugPrint('🔄 FundRankingWrapperSimple: 开始初始化数据加载');

    try {
      // 直接通过context.read获取BlocProvider创建的cubit实例
      _cubit = context.read<FundRankingCubit>();

      // 确保Provider可用后再初始化
      await Future.delayed(const Duration(milliseconds: 10));
      if (mounted && _cubit != null) {
        _cubit!.initialize();
        _hasInitialized = true;
        debugPrint('✅ FundRankingWrapperSimple 初始化成功');
      }
    } catch (e) {
      debugPrint('❌ FundRankingWrapperSimple 初始化失败: $e');
      // 如果Provider仍然不可用，再重试一次
      if (mounted && e.toString().contains('ProviderNotFoundException')) {
        await Future.delayed(const Duration(milliseconds: 10));
        try {
          if (!mounted) return;
          _cubit = context.read<FundRankingCubit>();
          if (mounted && _cubit != null) {
            _cubit!.initialize();
            _hasInitialized = true;
            debugPrint('✅ FundRankingWrapperSimple 重试初始化成功');
          }
        } catch (retryError) {
          debugPrint('❌ FundRankingWrapperSimple 重试初始化失败: $retryError');
          _cubit = null;
        }
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    super.dispose();
  }

  /// 手动重新加载数据
  Future<void> _reloadData() async {
    debugPrint('🔄 FundRankingWrapperSimple: 用户手动重新加载数据');

    // 如果还未初始化，先尝试初始化
    if (!_hasInitialized && _cubit == null) {
      debugPrint('🔄 FundRankingWrapperSimple: 未初始化，先尝试初始化');
      await _initializeData(context);
    }

    if (_cubit != null) {
      // 使用缓存的Provider引用
      try {
        _cubit!.forceReload();
        debugPrint('✅ FundRankingWrapperSimple 重载成功（使用缓存引用）');
      } catch (e) {
        debugPrint('❌ FundRankingWrapperSimple 重载失败（缓存引用）: $e');
        // 重新获取Provider引用
        await _reloadWithFallback();
      }
    } else {
      // 缓存引用为空，重新获取
      await _reloadWithFallback();
    }
  }

  /// 重新获取Provider并重载
  Future<void> _reloadWithFallback() async {
    debugPrint('🔄 FundRankingWrapperSimple: 重新获取Provider并重载');
    try {
      _cubit = context.read<FundRankingCubit>();
      _cubit!.forceReload();
      debugPrint('✅ FundRankingWrapperSimple 重新获取Provider并重载成功');
    } catch (e) {
      debugPrint('❌ FundRankingWrapperSimple 重新获取Provider失败: $e');
      // 等待后再重试
      await Future.delayed(const Duration(milliseconds: 10));
      try {
        if (mounted) {
          _cubit = context.read<FundRankingCubit>();
          _cubit!.forceReload();
          debugPrint('✅ FundRankingWrapperSimple 延迟重试重载成功');
        }
      } catch (retryError) {
        debugPrint('❌ FundRankingWrapperSimple 延迟重试重载失败: $retryError');
        _cubit = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 激活AutomaticKeepAliveClientMixin

    // 直接使用父级提供的FundRankingCubit
    return _buildContent(context);
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context) {
    return BlocBuilder<FundRankingCubit, FundRankingState>(
      builder: (context, state) {
        // 不再自动初始化，等待用户交互

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 350, // 最大高度限制
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16), // 减少内边距
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题区域
                    _buildHeader(context, state),

                    const SizedBox(height: 16), // 减少间距

                    // 内容区域
                    _buildContentWithState(context, state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题区域
  Widget _buildHeader(BuildContext context, FundRankingState state) {
    return Row(
      children: [
        const Icon(
          Icons.emoji_events,
          color: Color(0xFFF59E0B),
          size: 20, // 减小图标尺寸
        ),
        const SizedBox(width: 6), // 减少间距
        const Expanded(
          child: Text(
            '基金排行榜',
            style: TextStyle(
              fontSize: 18, // 减小字体
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 重新加载按钮 - 只有在初始化完成且不在加载中时才显示
        if (_hasInitialized && _cubit != null && !state.isLoading)
          IconButton(
            icon: const Icon(Icons.refresh, size: 18), // 减小图标
            onPressed: _reloadData,
            tooltip: '重新加载',
            constraints: const BoxConstraints(
              minWidth: 32, // 减小按钮尺寸
              minHeight: 32,
            ),
          ),

        // 加载指示器或初始化中状态
        if (state.isLoading || _isInitializing)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

        // 如果还未初始化完成，显示占位空间
        if (!_hasInitialized && !_isInitializing && !state.isLoading)
          const SizedBox(
            width: 32,
            height: 32,
          ),
      ],
    );
  }

  /// 构建内容区域（带状态）
  Widget _buildContentWithState(BuildContext context, FundRankingState state) {
    // 初始状态 - 未初始化，显示点击加载按钮
    if (!_hasInitialized && !_isInitializing && state.isInitial) {
      return _buildInitialWidget();
    }

    if (state.isLoading && state.isInitial) {
      // 纯加载状态
      return _buildLoadingWidget();
    } else if (state.isFailure) {
      // 错误状态且无数据
      return _buildErrorWidget(context, state);
    } else if (state.isSuccess) {
      // 有数据状态
      final successData = state.successData;
      if (successData != null && successData.rankings.isNotEmpty) {
        return _buildDataDisplay(context, successData.rankings);
      } else {
        return _buildEmptyWidget(context);
      }
    } else {
      // 空状态或其他状态
      return _buildEmptyWidget(context);
    }
  }

  /// 构建数据显示
  Widget _buildDataDisplay(BuildContext context, List<FundRanking> rankings) {
    // 显示简单数据统计信息
    final displayRankings = rankings.take(5); // 只显示前5条

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '基金排行榜数据',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '共 ${rankings.length} 条',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...displayRankings.map((ranking) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${ranking.rankingPosition}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ranking.fundName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              ranking.fundCode,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${ranking.return1Y.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: ranking.return1Y >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '近1年',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // 触发刷新
                  _cubit?.refreshRankings();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('刷新数据'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建初始状态（等待用户点击）
  Widget _buildInitialWidget() {
    return Container(
      height: 200, // 减少高度
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          const Text(
            '点击加载基金排行榜',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '查看最新的基金排行数据',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _initializeData(context),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('加载排行榜'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingWidget() {
    return Container(
      height: 280, // 增加高度以容纳更多内容
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 增强的加载动画
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 外圈旋转动画
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    backgroundColor: const Color(0xFFF59E0B).withOpacity(0.2),
                  ),
                ),
                // 内圈小图标
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '正在加载基金排行数据...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请稍候，数据正在获取中...',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
          ),
          // 添加脉冲动画提示
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: const Color(0xFFE5E7EB),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 200 * _loadingAnimation.value,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorWidget(BuildContext context, FundRankingState state) {
    final failureData = state.failureData;
    return Container(
      height: 200, // 减少高度
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48, // 减小图标
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16, // 减小字体
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            failureData?.error ?? '未知错误',
            style: const TextStyle(
              fontSize: 12, // 减小字体
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _reloadData,
            icon: const Icon(Icons.refresh, size: 16), // 减小图标
            label: const Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyWidget(BuildContext context) {
    return Container(
      height: 200, // 减少高度
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48, // 减小图标
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            '暂无基金排行数据',
            style: TextStyle(
              fontSize: 16, // 减小字体
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '请稍后重试',
            style: TextStyle(
              fontSize: 12, // 减小字体
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
