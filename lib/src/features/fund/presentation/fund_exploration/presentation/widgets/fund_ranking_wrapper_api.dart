import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/fund_ranking_cubit_simple.dart';
import '../../../../../../core/state/global_cubit_manager.dart';

/// API直连版基金排行包装器
///
/// 使用SimpleFundRankingCubit进行状态管理
/// 直接API调用，无缓存依赖
/// 使用应用顶层的BlocProvider确保状态持久化
class FundRankingWrapperAPI extends StatefulWidget {
  const FundRankingWrapperAPI({super.key});

  /// 提供固定Key以确保Widget在页面切换时保持状态
  static const pageKey = ValueKey('fund_ranking_wrapper_api');

  @override
  State<FundRankingWrapperAPI> createState() => _FundRankingWrapperAPIState();
}

class _FundRankingWrapperAPIState extends State<FundRankingWrapperAPI>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _hasInitialized = false;
  SimpleFundRankingCubit? _cubit;
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 FundRankingWrapperAPI: 初始化Widget - 使用应用顶层BlocProvider');

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

    _loadingAnimationController.repeat(reverse: true);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    super.dispose();
  }

  /// 手动重新加载数据
  Future<void> _reloadData() async {
    debugPrint('🔄 FundRankingWrapperAPI: 用户手动重新加载数据');
    debugPrint(
        '📊 FundRankingWrapperAPI: 当前Cubit状态 - ${_cubit != null ? "存在" : "为空"}');

    // 确保获取最新的Cubit实例
    if (_cubit == null || _cubit!.isClosed) {
      debugPrint('🔄 FundRankingWrapperAPI: Cubit为空或已关闭，重新获取');
      _cubit = GlobalCubitManager.instance.getFundRankingCubit();
      debugPrint(
          '📊 FundRankingWrapperAPI: 重新获取的Cubit状态 - ${GlobalCubitManager.instance.getFundRankingStatusInfo()}');
    }

    if (_cubit != null && !_cubit!.isClosed) {
      try {
        debugPrint('🔄 FundRankingWrapperAPI: 调用forceReload方法');
        _cubit!.forceReload();
        debugPrint('✅ FundRankingWrapperAPI 强制重载调用成功');
      } catch (e) {
        debugPrint('❌ FundRankingWrapperAPI 强制重载失败: $e');
        // 尝试重新获取Cubit
        if (mounted) {
          debugPrint('🔄 FundRankingWrapperAPI: 尝试从context重新获取Cubit');
          _cubit = context.read<SimpleFundRankingCubit>();
          _cubit!.forceReload();
          debugPrint('✅ FundRankingWrapperAPI 重新获取Cubit后重载成功');
        }
      }
    } else {
      debugPrint('❌ FundRankingWrapperAPI Cubit为空或已关闭，无法重载');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 直接使用应用顶层的BlocProvider，确保状态持久化
    _cubit = context.read<SimpleFundRankingCubit>();
    debugPrint('🔄 FundRankingWrapperAPI: 使用应用顶层BlocProvider实例');
    debugPrint(
        '📊 FundRankingWrapperAPI: Cubit状态 - ${GlobalCubitManager.instance.getFundRankingStatusInfo()}');

    return BlocBuilder<SimpleFundRankingCubit, FundRankingState>(
      builder: (context, state) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 300,
              maxHeight: 500,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E40AF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.leaderboard,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '基金排行榜（API直连）',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 重新加载按钮
                      if (!state.isLoading)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: state.isLoading ? null : _reloadData,
                          tooltip: '刷新数据',
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(4),
                            minimumSize: const Size(32, 32),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 状态信息和统计数据
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          '总数量',
                          '${state.totalCount}',
                          Icons.analytics,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          '显示数量',
                          '${state.rankings.length}',
                          Icons.visibility,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          '更新时间',
                          state.lastUpdateTime != null
                              ? '${state.lastUpdateTime!.hour.toString().padLeft(2, '0')}:${state.lastUpdateTime!.minute.toString().padLeft(2, '0')}'
                              : '--:--',
                          Icons.access_time,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // 内容区域 - 使用Flexible而不是Expanded
                Flexible(
                  child: _buildContent(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, FundRankingState state) {
    if (state.isLoading && state.rankings.isEmpty) {
      return _buildLoadingWidget();
    }

    if (state.error.isNotEmpty) {
      return _buildErrorWidget(state.error);
    }

    if (state.rankings.isEmpty) {
      return _buildEmptyWidget();
    }

    return _buildRankingList(state);
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_loadingAnimation.value * 0.4),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue
                        .withOpacity(0.7 + (_loadingAnimation.value * 0.3)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            '正在加载基金数据...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '首次加载可能需要几秒钟',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reloadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无基金数据',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试刷新数据',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(FundRankingState state) {
    return Column(
      children: [
        // 列表头部
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(
                  width: 30,
                  child: Text('排名',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
              const SizedBox(width: 8),
              const Expanded(
                  flex: 3,
                  child: Text('基金名称',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 10))),
              const SizedBox(
                  width: 50,
                  child: Text('单位净值',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                      textAlign: TextAlign.right)),
              const SizedBox(
                  width: 50,
                  child: Text('日收益',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                      textAlign: TextAlign.right)),
              const SizedBox(
                  width: 50,
                  child: Text('近1年',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                      textAlign: TextAlign.right)),
            ],
          ),
        ),

        // 基金列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: state.rankings.length + (state.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.rankings.length && state.hasMoreData) {
                return _buildLoadMoreButton(state);
              }

              final fund = state.rankings[index];
              final rank = index + 1;
              return _buildFundCard(fund, rank);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFundCard(FundRanking fund, int rank) {
    Color dailyReturnColor = fund.dailyReturn >= 0 ? Colors.green : Colors.red;
    Color yearlyReturnColor =
        fund.oneYearReturn >= 0 ? Colors.blue : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          // 可以添加点击事件
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // 排名
              SizedBox(
                width: 30,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: rank <= 3 ? Colors.orange : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),

              // 基金名称
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fund.fundName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      fund.fundCode,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 单位净值
              SizedBox(
                width: 50,
                child: Text(
                  fund.nav.toStringAsFixed(3),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              // 日收益
              SizedBox(
                width: 50,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: dailyReturnColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${fund.dailyReturn.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: dailyReturnColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // 近1年收益
              SizedBox(
                width: 50,
                child: Text(
                  '${fund.oneYearReturn.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: yearlyReturnColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(FundRankingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          _cubit?.loadMoreRankings();
        },
        icon: const Icon(Icons.keyboard_arrow_down),
        label: const Text('加载更多'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
