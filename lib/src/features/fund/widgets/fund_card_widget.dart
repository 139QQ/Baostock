import 'package:flutter/material.dart';
import '../../../models/fund_info.dart';
import '../../../services/improved_fund_api_service.dart';

/// 基金卡片组件
class FundCardWidget extends StatelessWidget {
  final FundInfo fund;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavorite;
  final bool isFavorite;

  const FundCardWidget({
    super.key,
    required this.fund,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：基金名称和收藏按钮
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 基金名称
                        Text(
                          fund.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 基金代码
                        Text(
                          fund.code,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (onFavorite != null)
                    IconButton(
                      onPressed: () => onFavorite!(!isFavorite),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[400],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 基金类型标签
              _buildFundTypeChip(context),

              const SizedBox(height: 12),

              // 基金信息
              Row(
                children: [
                  // 类型
                  _buildInfoItem(
                    context,
                    '类型',
                    fund.simplifiedType,
                    Icons.category,
                  ),
                  const SizedBox(width: 16),
                  // 拼音缩写
                  _buildInfoItem(
                    context,
                    '拼音',
                    fund.pinyinAbbr.isEmpty ? '无' : fund.pinyinAbbr,
                    Icons.translate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFundTypeChip(BuildContext context) {
    Color chipColor;
    switch (fund.simplifiedType) {
      case '股票型':
        chipColor = Colors.red;
        break;
      case '混合型':
        chipColor = Colors.blue;
        break;
      case '债券型':
        chipColor = Colors.green;
        break;
      case '货币型':
        chipColor = Colors.orange;
        break;
      case '指数型':
        chipColor = Colors.purple;
        break;
      case 'QDII':
        chipColor = Colors.teal;
        break;
      case 'FOF':
        chipColor = Colors.indigo;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        fund.simplifiedType,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 基金详情卡片（用于基金详情页面的顶部展示）
class FundDetailCardWidget extends StatelessWidget {
  final FundInfo fund;
  final FundRankingData? rankingData;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const FundDetailCardWidget({
    super.key,
    required this.fund,
    this.rankingData,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：基金名称和收藏按钮
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基金名称
                      Text(
                        fund.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      // 基金代码和类型
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              fund.code,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFundTypeChip(context),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onFavoriteToggle != null)
                  IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey[400],
                      size: 28,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // 排行榜信息
            if (rankingData != null) _buildRankingInfo(context),

            const SizedBox(height: 16),

            // 基金详细信息
            _buildFundDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFundTypeChip(BuildContext context) {
    Color chipColor;
    switch (fund.simplifiedType) {
      case '股票型':
        chipColor = Colors.red;
        break;
      case '混合型':
        chipColor = Colors.blue;
        break;
      case '债券型':
        chipColor = Colors.green;
        break;
      case '货币型':
        chipColor = Colors.orange;
        break;
      case '指数型':
        chipColor = Colors.purple;
        break;
      case 'QDII':
        chipColor = Colors.teal;
        break;
      case 'FOF':
        chipColor = Colors.indigo;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        fund.simplifiedType,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRankingInfo(BuildContext context) {
    if (rankingData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '排行信息',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRankingItem(
                context,
                '排名',
                '#${rankingData!.rankingPosition}',
                Icons.leaderboard,
              ),
              _buildRankingItem(
                context,
                '单位净值',
                rankingData!.unitNav.toStringAsFixed(4),
                Icons.attach_money,
              ),
              _buildRankingItem(
                context,
                '日涨跌',
                '${rankingData!.dailyReturn.toStringAsFixed(2)}%',
                rankingData!.dailyReturn >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                rankingData!.dailyReturn >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildFundDetails(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                context,
                '基金公司',
                _extractFundCompany(fund.name),
                Icons.business,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                context,
                '拼音缩写',
                fund.pinyinAbbr.isEmpty ? '无' : fund.pinyinAbbr,
                Icons.translate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _extractFundCompany(String fundName) {
    // 常见基金公司名称提取
    final companies = [
      '易方达',
      '华夏',
      '南方',
      '嘉实',
      '博时',
      '广发',
      '汇添富',
      '富国',
      '招商',
      '中银',
      '工银瑞信',
      '建信',
      '银华',
      '交银施罗德',
      '华安',
      '国泰',
      '鹏华',
      '兴全',
      '中欧',
      '上投摩根',
      '华宝',
      '景顺长城'
    ];

    for (final company in companies) {
      if (fundName.contains(company)) {
        return company;
      }
    }

    return '其他公司';
  }
}
