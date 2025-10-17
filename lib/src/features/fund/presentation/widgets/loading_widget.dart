import 'package:flutter/material.dart';

/// 加载组件
///
/// 提供多种加载状态的可视化效果
class LoadingWidget extends StatelessWidget {
  /// 加载消息
  final String? message;

  /// 是否显示背景遮罩
  final bool showOverlay;

  /// 加载指示器大小
  final double? size;

  /// 加载指示器颜色
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.showOverlay = false,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 加载指示器
        _buildLoadingIndicator(context),

        const SizedBox(height: 16),

        // 加载消息
        if (message != null)
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),

        // 加载提示
        const SizedBox(height: 8),
        const Text(
          '请稍候...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );

    if (showOverlay) {
      return Container(
        color: Colors.black.withOpacity(0.5),
        child: content,
      );
    }

    return content;
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator(BuildContext context) {
    return SizedBox(
      width: size ?? 40,
      height: size ?? 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// 排行榜骨架屏加载组件
///
/// 在数据加载时显示占位符，提升用户体验
class RankingSkeletonLoader extends StatelessWidget {
  /// 项目数量
  final int itemCount;

  /// 是否显示动画
  final bool animated;

  const RankingSkeletonLoader({
    super.key,
    this.itemCount = 10,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSkeletonCard(context, index),
        );
      },
    );
  }

  /// 构建骨架屏卡片
  Widget _buildSkeletonCard(BuildContext context, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 顶部行
            Row(
              children: [
                // 排名徽章骨架
                _buildSkeletonCircle(),
                const SizedBox(width: 12),

                // 基金信息骨架
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonLine(width: 120, height: 16),
                      const SizedBox(height: 4),
                      _buildSkeletonLine(width: 80, height: 12),
                    ],
                  ),
                ),

                // 操作按钮骨架
                _buildSkeletonCircle(),
              ],
            ),

            const SizedBox(height: 12),

            // 收益率信息骨架
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSkeletonLine(width: 40, height: 12),
                _buildSkeletonLine(width: 40, height: 12),
                _buildSkeletonLine(width: 40, height: 12),
              ],
            ),

            const SizedBox(height: 12),

            // 底部行骨架
            _buildSkeletonLine(width: 150, height: 12),
          ],
        ),
      ),
    );
  }

  /// 构建骨架屏圆形
  Widget _buildSkeletonCircle() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /// 构建骨架屏线条
  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 下拉刷新加载组件
class PullToRefreshLoading extends StatelessWidget {
  /// 刷新消息
  final String? message;

  const PullToRefreshLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? '正在刷新...',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// 加载更多指示器组件
class LoadMoreIndicator extends StatelessWidget {
  /// 是否正在加载
  final bool isLoading;

  /// 是否还有更多数据
  final bool hasMoreData;

  /// 加载消息
  final String? loadingMessage;

  /// 无更多数据消息
  final String? noMoreMessage;

  const LoadMoreIndicator({
    super.key,
    required this.isLoading,
    required this.hasMoreData,
    this.loadingMessage,
    this.noMoreMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              loadingMessage ?? '加载更多...',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (!hasMoreData) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 8),
            Text(
              noMoreMessage ?? '没有更多数据了',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 1,
              color: Colors.grey[300],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
