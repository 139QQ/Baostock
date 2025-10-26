import 'package:flutter/material.dart';
import '../../domain/entities/fund.dart';

/// 基金关联推荐组件
///
/// 提供智能关联推荐功能，包括：
/// - 同基金经理基金推荐
/// - 同类型基金推荐
/// - 同基金公司推荐
/// - 高收益同类基金推荐
class FundRecommendation extends StatefulWidget {
  final Fund currentFund;
  final Function(Fund) onFundSelected;

  const FundRecommendation({
    super.key,
    required this.currentFund,
    required this.onFundSelected,
  });

  @override
  State<FundRecommendation> createState() => _FundRecommendationState();
}

class _FundRecommendationState extends State<FundRecommendation> {
  bool _isLoading = false;
  List<Fund> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '关联推荐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              if (!_isLoading)
                TextButton.icon(
                  onPressed: _refreshRecommendations,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('刷新'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 推荐内容
          if (_isLoading)
            _buildLoadingState()
          else if (_recommendations.isEmpty)
            _buildEmptyState()
          else
            _buildRecommendationsList(),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            '正在分析关联基金...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.recommend_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            '暂无关联推荐',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '该基金的同类产品较少',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建推荐列表
  Widget _buildRecommendationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 推荐说明
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '基于"${widget.currentFund.name}"为您推荐以下相关基金',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 推荐基金列表
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recommendations.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final fund = _recommendations[index];
            return _buildRecommendationCard(fund, index);
          },
        ),

        // 查看更多按钮
        if (_recommendations.length > 5)
          Center(
            child: TextButton.icon(
              onPressed: _showMoreRecommendations,
              icon: const Icon(Icons.expand_more, size: 16),
              label: const Text('查看更多推荐'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建推荐卡片
  Widget _buildRecommendationCard(Fund fund, int index) {
    String reason = _getRecommendationReason(fund);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onFundSelected(fund),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 基金代码和类型
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fund.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getFundTypeColor(fund.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fund.type,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getFundTypeColor(fund.type),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // 基金信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fund.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 收益率信息
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${fund.return1Y.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: fund.return1Y >= 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    '近1年',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取推荐原因
  String _getRecommendationReason(Fund fund) {
    // 同基金经理
    if (fund.manager == widget.currentFund.manager && fund.manager.isNotEmpty) {
      return '同基金经理：${fund.manager}';
    }

    // 同基金公司
    if (fund.company == widget.currentFund.company) {
      return '同基金公司：${fund.company}';
    }

    // 同类型高收益
    if (fund.type == widget.currentFund.type &&
        fund.return1Y > widget.currentFund.return1Y) {
      return '同类型，收益率更高';
    }

    // 同类型推荐
    if (fund.type == widget.currentFund.type) {
      return '同类型推荐';
    }

    return '智能推荐';
  }

  /// 获取基金类型颜色
  Color _getFundTypeColor(String fundType) {
    switch (fundType) {
      case '股票型':
        return Colors.red;
      case '债券型':
        return Colors.blue;
      case '混合型':
        return Colors.orange;
      case '货币型':
        return Colors.green;
      case '指数型':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// 加载推荐数据
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟加载推荐数据
      await Future.delayed(const Duration(seconds: 1));

      final mockRecommendations = _generateMockRecommendations();

      setState(() {
        _recommendations = mockRecommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 生成模拟推荐数据
  List<Fund> _generateMockRecommendations() {
    // 这里应该调用实际的推荐算法
    // 现在返回一些模拟数据
    return [
      Fund(
        code: '000001',
        name: '华夏成长混合',
        type: widget.currentFund.type,
        company: widget.currentFund.company,
        manager: widget.currentFund.manager,
        unitNav: 1.2345,
        accumulatedNav: 2.3456,
        return1Y: 15.67,
        return3Y: 45.32,
        return2Y: 67.89,
        scale: 1234567890.12,
        status: 'active',
        lastUpdate: DateTime.now(),
      ),
      Fund(
        code: '110022',
        name: '易方达消费行业股票',
        type: widget.currentFund.type,
        company: '易方达基金管理有限公司',
        manager: '萧楠',
        unitNav: 2.1234,
        accumulatedNav: 3.4567,
        return1Y: 22.34,
        return3Y: 67.89,
        return2Y: 89.12,
        scale: 2345678901.23,
        status: 'active',
        lastUpdate: DateTime.now(),
      ),
      Fund(
        code: '161725',
        name: '招商中证白酒指数分级',
        type: '指数型',
        company: '招商基金管理有限公司',
        manager: '侯昊',
        unitNav: 0.9876,
        accumulatedNav: 1.8765,
        return1Y: -5.43,
        return3Y: 78.90,
        return2Y: 134.56,
        scale: 3456789012.34,
        status: 'active',
        lastUpdate: DateTime.now(),
      ),
    ];
  }

  /// 刷新推荐
  void _refreshRecommendations() {
    _loadRecommendations();
  }

  /// 显示更多推荐
  void _showMoreRecommendations() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.recommend,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '更多关联推荐',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final fund = _recommendations[index];
                    return ListTile(
                      title: Text(fund.name),
                      subtitle: Text('${fund.code} - ${fund.type}'),
                      trailing: Text(
                        '${fund.return1Y.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: fund.return1Y >= 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onFundSelected(fund);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
