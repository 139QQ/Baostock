import 'package:flutter/material.dart';
import '../../domain/models/fund.dart';

/// 基金卡片组件
///
/// 展示基金的基本信息和关键指标，支持：
/// - 基金基本信息展示
/// - 收益表现显示
/// - 快速操作按钮
/// - 对比模式支持
class FundCard extends StatelessWidget {
  final Fund fund;
  final bool showComparisonCheckbox;
  final bool showQuickActions;
  final bool isSelected;
  final bool compactMode;
  final VoidCallback? onTap;
  final Function(bool)? onSelectionChanged;
  final VoidCallback? onAddToWatchlist;
  final VoidCallback? onCompare;
  final VoidCallback? onShare;

  const FundCard({
    super.key,
    required this.fund,
    this.showComparisonCheckbox = false,
    this.showQuickActions = true,
    this.isSelected = false,
    this.compactMode = false,
    this.onTap,
    this.onSelectionChanged,
    this.onAddToWatchlist,
    this.onCompare,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    if (compactMode) {
      return _buildCompactCard(context);
    }
    return _buildStandardCard(context);
  }

  /// 构建标准卡片
  Widget _buildStandardCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14), // 减少内边距
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 使用最小尺寸
            children: [
              // 头部信息
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (showComparisonCheckbox) ...[
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  if (onSelectionChanged != null) {
                                    onSelectionChanged!(value ?? false);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                fund.name,
                                style: TextStyle(
                                  fontSize: 15, // 减小字体
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Fund.getFundTypeColor(fund.type)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fund.type,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Fund.getFundTypeColor(fund.type),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fund.code,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 收益率显示
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${fund.return1Y > 0 ? '+' : ''}${fund.return1Y.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 18, // 减小字体
                          fontWeight: FontWeight.bold,
                          color: Fund.getReturnColor(fund.return1Y),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '近1年收益',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10), // 减少间距

              // 基金经理和规模
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14, // 减小图标
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      fund.manager,
                      style: TextStyle(
                        fontSize: 13, // 减小字体
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${fund.scale.toStringAsFixed(1)}亿',
                    style: TextStyle(
                      fontSize: 13, // 减小字体
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10), // 减少间距

              // 快速操作按钮
              if (showQuickActions) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddToWatchlist,
                        icon: Icon(
                          Icons.favorite_border,
                          size: 16,
                        ),
                        label: Text('自选'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6), // 减少垂直内边距
                          minimumSize: Size(0, 32), // 设置最小高度
                          side: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCompare,
                        icon: Icon(
                          Icons.compare_arrows,
                          size: 16,
                        ),
                        label: Text('对比'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6), // 减少垂直内边距
                          minimumSize: Size(0, 32), // 设置最小高度
                          side: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: Icon(
                          Icons.share,
                          size: 16,
                        ),
                        label: Text('分享'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6), // 减少垂直内边距
                          minimumSize: Size(0, 32), // 设置最小高度
                          side: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建紧凑卡片
  Widget _buildCompactCard(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: showComparisonCheckbox
            ? Checkbox(
                value: isSelected,
                onChanged: (value) {
                  if (onSelectionChanged != null) {
                    onSelectionChanged!(value ?? false);
                  }
                },
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                fund.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Fund.getFundTypeColor(fund.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                fund.type,
                style: TextStyle(
                  fontSize: 11,
                  color: Fund.getFundTypeColor(fund.type),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              fund.code,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              fund.manager,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              '${fund.return1Y > 0 ? '+' : ''}${fund.return1Y.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Fund.getReturnColor(fund.return1Y),
              ),
            ),
          ],
        ),
        trailing: showQuickActions
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'watchlist':
                      onAddToWatchlist?.call();
                      break;
                    case 'compare':
                      onCompare?.call();
                      break;
                    case 'share':
                      onShare?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'watchlist',
                    child: Text('添加自选'),
                  ),
                  const PopupMenuItem(
                    value: 'compare',
                    child: Text('加入对比'),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Text('分享'),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
