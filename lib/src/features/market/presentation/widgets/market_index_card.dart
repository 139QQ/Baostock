import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../models/market_index_data.dart';
import 'index_change_indicator.dart';

/// 市场指数卡片
///
/// 显示单个市场指数的信息，包括当前价格、变化情况和状态指示器
class MarketIndexCard extends StatelessWidget {
  const MarketIndexCard({
    super.key,
    required this.indexData,
    this.onTap,
    this.style = MarketIndexCardStyle.normal,
  });

  /// 指数数据
  final MarketIndexData indexData;

  /// 点击回调
  final VoidCallback? onTap;

  /// 卡片样式
  final MarketIndexCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: style == MarketIndexCardStyle.compact ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: style == MarketIndexCardStyle.compact
              ? const EdgeInsets.all(12)
              : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _buildGradient(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildPriceInfo(context),
              const SizedBox(height: 8),
              if (style != MarketIndexCardStyle.compact) ...[
                _buildAdditionalInfo(context),
                const SizedBox(height: 8),
              ],
              _buildStatusRow(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建渐变背景
  LinearGradient? _buildGradient() {
    if (style == MarketIndexCardStyle.normal) {
      if (indexData.isRising) {
        return LinearGradient(
          colors: [
            Colors.red.withOpacity(0.05),
            Colors.red.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (indexData.isFalling) {
        return LinearGradient(
          colors: [
            Colors.green.withOpacity(0.05),
            Colors.green.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
    return null;
  }

  /// 构建标题行
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // 指数图标
        CircleAvatar(
          radius: style == MarketIndexCardStyle.compact ? 16 : 20,
          backgroundColor: _getIconBackgroundColor(),
          child: Icon(
            _getIconData(),
            size: style == MarketIndexCardStyle.compact ? 16 : 20,
            color: _getIconColor(),
          ),
        ),
        const SizedBox(width: 12),
        // 指数名称和代码
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                indexData.name,
                style: style == MarketIndexCardStyle.compact
                    ? Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )
                    : Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                indexData.code,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        // 市场状态
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  /// 构建价格信息
  Widget _buildPriceInfo(BuildContext context) {
    return Row(
      children: [
        // 当前价格
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前值',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                _formatDecimal(indexData.currentValue),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getPriceColor(context),
                    ),
              ),
            ],
          ),
        ),
        // 变化指示器
        IndexChangeIndicator(
          indexData: indexData,
          style: style == MarketIndexCardStyle.compact
              ? IndexChangeIndicatorStyle.compact
              : IndexChangeIndicatorStyle.detailed,
        ),
      ],
    );
  }

  /// 构建附加信息
  Widget _buildAdditionalInfo(BuildContext context) {
    return Row(
      children: [
        // 开盘价
        Expanded(
          child: _buildInfoItem(
            context,
            '开盘',
            _formatDecimal(indexData.openPrice),
          ),
        ),
        // 最高价
        Expanded(
          child: _buildInfoItem(
            context,
            '最高',
            _formatDecimal(indexData.highPrice),
          ),
        ),
        // 最低价
        Expanded(
          child: _buildInfoItem(
            context,
            '最低',
            _formatDecimal(indexData.lowPrice),
          ),
        ),
        // 成交量
        Expanded(
          child: _buildInfoItem(
            context,
            '成交量',
            _formatVolume(indexData.volume),
          ),
        ),
      ],
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
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

  /// 构建状态行
  Widget _buildStatusRow(BuildContext context) {
    return Row(
      children: [
        // 更新时间
        Icon(
          Icons.update,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          _formatTime(indexData.updateTime),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const Spacer(),
        // 数据质量指示器
        if (indexData.qualityLevel != DataQualityLevel.good) ...[
          Icon(
            Icons.info_outline,
            size: 16,
            color: _getQualityColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getQualityText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getQualityColor(),
                ),
          ),
        ],
      ],
    );
  }

  /// 获取图标数据
  IconData _getIconData() {
    // 根据指数代码返回相应图标
    if (indexData.code.contains('SH') || indexData.code.contains('000')) {
      return Icons.trending_up; // 上证指数
    } else if (indexData.code.contains('SZ') ||
        indexData.code.contains('399')) {
      return Icons.show_chart; // 深证指数
    } else if (indexData.code.contains('HSI')) {
      return Icons.public; // 恒生指数
    } else if (indexData.code.contains('DJ') ||
        indexData.code.contains('IXIC')) {
      return Icons.language; // 美股指数
    }
    return Icons.analytics; // 默认图标
  }

  /// 获取图标背景色
  Color _getIconBackgroundColor() {
    if (indexData.isRising) {
      return Colors.red.withOpacity(0.1);
    } else if (indexData.isFalling) {
      return Colors.green.withOpacity(0.1);
    }
    return Colors.grey.withOpacity(0.1);
  }

  /// 获取图标颜色
  Color _getIconColor() {
    if (indexData.isRising) {
      return Colors.red;
    } else if (indexData.isFalling) {
      return Colors.green;
    }
    return Colors.grey;
  }

  /// 获取价格颜色
  Color _getPriceColor(BuildContext context) {
    if (indexData.isRising) {
      return Colors.red;
    } else if (indexData.isFalling) {
      return Colors.green;
    }
    return Theme.of(context).textTheme.headlineSmall?.color ?? Colors.black;
  }

  /// 获取状态文本
  String _getStatusText() {
    switch (indexData.marketStatus) {
      case MarketStatus.trading:
        return '交易中';
      case MarketStatus.preMarket:
        return '盘前';
      case MarketStatus.postMarket:
        return '盘后';
      case MarketStatus.closed:
        return '休市';
      case MarketStatus.holiday:
        return '节假日';
      case MarketStatus.unknown:
        return '未知';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor() {
    switch (indexData.marketStatus) {
      case MarketStatus.trading:
        return Colors.green;
      case MarketStatus.preMarket:
        return Colors.orange;
      case MarketStatus.postMarket:
        return Colors.purple;
      case MarketStatus.closed:
        return Colors.grey;
      case MarketStatus.holiday:
        return Colors.blue;
      case MarketStatus.unknown:
        return Colors.grey;
    }
  }

  /// 获取数据质量文本
  String _getQualityText() {
    switch (indexData.qualityLevel) {
      case DataQualityLevel.excellent:
        return '优秀';
      case DataQualityLevel.good:
        return '良好';
      case DataQualityLevel.fair:
        return '一般';
      case DataQualityLevel.poor:
        return '较差';
      case DataQualityLevel.unknown:
        return '未知';
    }
  }

  /// 获取数据质量颜色
  Color _getQualityColor() {
    switch (indexData.qualityLevel) {
      case DataQualityLevel.excellent:
        return Colors.green;
      case DataQualityLevel.good:
        return Colors.blue;
      case DataQualityLevel.fair:
        return Colors.orange;
      case DataQualityLevel.poor:
        return Colors.red;
      case DataQualityLevel.unknown:
        return Colors.grey;
    }
  }

  /// 格式化Decimal
  String _formatDecimal(Decimal value) {
    return value.toStringAsFixed(2);
  }

  /// 格式化成交量
  String _formatVolume(int volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(1)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(1)}万';
    }
    return volume.toString();
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}

/// 市场指数卡片样式
enum MarketIndexCardStyle {
  /// 普通样式
  normal,

  /// 紧凑样式
  compact,

  /// 详细样式
  detailed,
}
